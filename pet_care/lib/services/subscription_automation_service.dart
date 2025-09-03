import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pet_care/services/subscription_order_service.dart';

class SubscriptionAutomationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static Timer? _automationTimer;
  static bool _isRunning = false;
  static StreamSubscription<User?>? _authStateSubscription;

  /// Start the automation service
  /// This should be called when the app starts and user is authenticated
  static void startAutomationService() {
    if (_isRunning) return;
    
    // Listen to auth state changes
    _authStateSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // User is authenticated, start automation
        _startAutomation();
      } else {
        // User is not authenticated, stop automation
        _stopAutomation();
      }
    });
  }

  /// Internal method to start automation
  static void _startAutomation() {
    if (_isRunning) return;
    
    _isRunning = true;
    print('Starting Subscription Automation Service for authenticated user...');
    
    // Run automation checks every 30 minutes
    _automationTimer = Timer.periodic(Duration(minutes: 30), (timer) {
      _runAutomationTasks();
    });
    
    // Run initial check
    _runAutomationTasks();
  }

  /// Internal method to stop automation
  static void _stopAutomation() {
    if (_automationTimer != null) {
      _automationTimer!.cancel();
      _automationTimer = null;
    }
    _isRunning = false;
    print('Subscription Automation Service stopped');
  }

  /// Stop the automation service
  static void stopAutomationService() {
    _authStateSubscription?.cancel();
    _authStateSubscription = null;
    _stopAutomation();
  }

  /// Run all automation tasks
  static Future<void> _runAutomationTasks() async {
    try {
      // Check if user is still authenticated
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('No authenticated user, skipping automation tasks');
        return;
      }

      print('Running subscription automation tasks for user: ${currentUser.email}...');
      
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
      // Check if user is authenticated
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {
          'success': false,
          'error': 'No authenticated user',
          'message': 'User must be authenticated to run automation'
        };
      }

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
