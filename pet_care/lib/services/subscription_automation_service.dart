import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pet_care/services/subscription_order_service.dart';

class SubscriptionAutomationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static Timer? _automationTimer;
  static bool _isRunning = false;

  /// Start the automation service
  /// This should be called when the app starts
  static void startAutomationService() {
    if (_isRunning) return;
    
    _isRunning = true;
    print('Starting Subscription Automation Service...');
    
    // Run automation checks every 30 minutes
    _automationTimer = Timer.periodic(Duration(minutes: 30), (timer) {
      _runAutomationTasks();
    });
    
    // Run initial check
    _runAutomationTasks();
  }

  /// Stop the automation service
  static void stopAutomationService() {
    if (_automationTimer != null) {
      _automationTimer!.cancel();
      _automationTimer = null;
    }
    _isRunning = false;
    print('Subscription Automation Service stopped');
  }

  /// Run all automation tasks
  static Future<void> _runAutomationTasks() async {
    try {
      print('Running subscription automation tasks...');
      
      // 1. Update orders to critical priority
      await SubscriptionOrderService.updateOrdersToCritical();
      
      // 2. Create next orders for delivered meals
      await _createNextOrdersForDeliveredMeals();
      
      // 3. Clean up old completed orders (optional)
      await _cleanupOldOrders();
      
      print('Subscription automation tasks completed');
    } catch (e) {
      print('Error in subscription automation: $e');
    }
  }

  /// Create next orders when meals are delivered
  static Future<void> _createNextOrdersForDeliveredMeals() async {
    try {
      // Find recently delivered orders that haven't triggered next order creation
      QuerySnapshot deliveredOrders = await _firestore
          .collection('orders')
          .where('status', isEqualTo: 'delivered')
          .where('orderType', isEqualTo: 'subscription_meal')
          .where('nextOrderScheduled', isEqualTo: false)
          .get();

      WriteBatch batch = _firestore.batch();
      
      for (QueryDocumentSnapshot doc in deliveredOrders.docs) {
        Map<String, dynamic> orderData = doc.data() as Map<String, dynamic>;
        
        String subscriptionId = orderData['subscriptionId'] ?? '';
        if (subscriptionId.isEmpty) continue;
        
        // Check if subscription is still active
        DocumentSnapshot subscriptionDoc = await _firestore
            .collection('subscriptions')
            .doc(subscriptionId)
            .get();
        
        if (!subscriptionDoc.exists) continue;
        
        Map<String, dynamic> subscriptionData = subscriptionDoc.data() as Map<String, dynamic>;
        String subscriptionStatus = subscriptionData['status'] ?? '';
        
        if (subscriptionStatus != 'active' && subscriptionStatus != 'approved') {
          continue; // Skip if subscription is not active
        }
        
        // Get delivery timestamp
        String deliveredAtStr = orderData['deliveredAt'] ?? '';
        if (deliveredAtStr.isEmpty) continue;
        
        try {
          DateTime deliveredAt = DateTime.parse(deliveredAtStr);
          String frequency = orderData['frequency'] ?? '1x/week';
          int currentCycle = orderData['cycleNumber'] ?? 1;
          
          // Create next recurring order
          Map<String, dynamic> result = await SubscriptionOrderService.scheduleNextRecurringOrder(
            subscriptionId: subscriptionId,
            lastDeliveryTime: deliveredAt,
            frequency: frequency,
            currentCycle: currentCycle,
          );
          
          if (result['success']) {
            // Mark current order as having scheduled next order
            batch.update(doc.reference, {
              'nextOrderScheduled': true,
              'nextOrderId': result['orderId'],
              'nextOrderCreatedAt': DateTime.now().toIso8601String(),
            });
            
            print('Next order scheduled for subscription $subscriptionId: ${result['orderId']}');
          } else {
            print('Failed to schedule next order for subscription $subscriptionId: ${result['message']}');
          }
          
        } catch (e) {
          print('Error parsing delivery date for order ${doc.id}: $e');
        }
      }
      
      if (deliveredOrders.docs.isNotEmpty) {
        await batch.commit();
        print('Processed ${deliveredOrders.docs.length} delivered orders for next order creation');
      }
      
    } catch (e) {
      print('Error creating next orders for delivered meals: $e');
    }
  }

  /// Clean up old completed orders (keep last 50 per subscription)
  static Future<void> _cleanupOldOrders() async {
    try {
      // This is optional - only run if we want to limit database size
      // Get distinct subscription IDs
      QuerySnapshot allOrders = await _firestore
          .collection('orders')
          .where('orderType', isEqualTo: 'subscription_meal')
          .where('status', whereIn: ['delivered', 'cancelled'])
          .get();

      Map<String, List<QueryDocumentSnapshot>> ordersBySubscription = {};
      
      for (QueryDocumentSnapshot doc in allOrders.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String subscriptionId = data['subscriptionId'] ?? '';
        
        if (subscriptionId.isNotEmpty) {
          ordersBySubscription.putIfAbsent(subscriptionId, () => []);
          ordersBySubscription[subscriptionId]!.add(doc);
        }
      }
      
      WriteBatch batch = _firestore.batch();
      int deletedCount = 0;
      
      // For each subscription, keep only the latest 50 completed orders
      for (String subscriptionId in ordersBySubscription.keys) {
        List<QueryDocumentSnapshot> orders = ordersBySubscription[subscriptionId]!;
        
        // Sort by creation date (newest first)
        orders.sort((a, b) {
          Map<String, dynamic> aData = a.data() as Map<String, dynamic>;
          Map<String, dynamic> bData = b.data() as Map<String, dynamic>;
          String aDate = aData['createdAt'] ?? '';
          String bDate = bData['createdAt'] ?? '';
          return bDate.compareTo(aDate);
        });
        
        // Delete orders beyond the 50 most recent
        if (orders.length > 50) {
          for (int i = 50; i < orders.length; i++) {
            batch.delete(orders[i].reference);
            deletedCount++;
          }
        }
      }
      
      if (deletedCount > 0) {
        await batch.commit();
        print('Cleaned up $deletedCount old completed orders');
      }
      
    } catch (e) {
      print('Error cleaning up old orders: $e');
    }
  }

  /// Manual trigger for automation tasks (useful for testing)
  static Future<Map<String, dynamic>> runManualAutomation() async {
    try {
      await _runAutomationTasks();
      return {
        'success': true,
        'message': 'Manual automation completed successfully'
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Manual automation failed'
      };
    }
  }

  /// Get automation service status
  static Map<String, dynamic> getServiceStatus() {
    return {
      'isRunning': _isRunning,
      'hasTimer': _automationTimer != null,
      'nextRunIn': _isRunning && _automationTimer != null 
          ? '${30 - (DateTime.now().minute % 30)} minutes'
          : 'Not scheduled',
    };
  }

  /// Force create next order for a specific delivered order (manual override)
  static Future<Map<String, dynamic>> forceCreateNextOrder(String orderId) async {
    try {
      DocumentSnapshot orderDoc = await _firestore
          .collection('orders')
          .doc(orderId)
          .get();
      
      if (!orderDoc.exists) {
        return {
          'success': false,
          'message': 'Order not found'
        };
      }
      
      Map<String, dynamic> orderData = orderDoc.data() as Map<String, dynamic>;
      
      if (orderData['status'] != 'delivered') {
        return {
          'success': false,
          'message': 'Order must be delivered to create next order'
        };
      }
      
      if (orderData['nextOrderScheduled'] == true) {
        return {
          'success': false,
          'message': 'Next order already scheduled'
        };
      }
      
      String subscriptionId = orderData['subscriptionId'] ?? '';
      if (subscriptionId.isEmpty) {
        return {
          'success': false,
          'message': 'No subscription ID found'
        };
      }
      
      DateTime deliveredAt = DateTime.parse(orderData['deliveredAt']);
      String frequency = orderData['frequency'] ?? '1x/week';
      int currentCycle = orderData['cycleNumber'] ?? 1;
      
      // Create next recurring order
      Map<String, dynamic> result = await SubscriptionOrderService.scheduleNextRecurringOrder(
        subscriptionId: subscriptionId,
        lastDeliveryTime: deliveredAt,
        frequency: frequency,
        currentCycle: currentCycle,
      );
      
      if (result['success']) {
        // Mark current order as having scheduled next order
        await _firestore.collection('orders').doc(orderId).update({
          'nextOrderScheduled': true,
          'nextOrderId': result['orderId'],
          'nextOrderCreatedAt': DateTime.now().toIso8601String(),
        });
      }
      
      return result;
      
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to force create next order'
      };
    }
  }
}
