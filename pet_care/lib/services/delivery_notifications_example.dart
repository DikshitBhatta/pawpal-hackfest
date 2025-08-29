// This file demonstrates how to integrate the notification service 
// into your delivery and order management workflow

import 'package:pet_care/services/notification_service.dart';

class DeliveryNotificationExample {
  
  /// Call this when an order is dispatched for delivery
  static Future<void> onOrderDispatched({
    required String userEmail,
    required String orderId,
    required DateTime estimatedDeliveryDate,
    String? trackingNumber,
  }) async {
    try {
      // 1. Update order status in database to "dispatched"
      // ... your database update code ...
      
      // 2. Send notification to user about dispatch
      await NotificationService.notifyUserOfDeliveryDispatch(
        userEmail: userEmail,
        orderId: orderId,
        estimatedDelivery: estimatedDeliveryDate.toString().split(' ')[0], // Format: YYYY-MM-DD
        trackingNumber: trackingNumber,
      );
      
      print('Delivery dispatch notification sent to user: $userEmail for order: $orderId');
      
    } catch (e) {
      print('Error processing order dispatch notification: $e');
    }
  }
  
  /// Call this when an order is out for delivery
  static Future<void> onOrderOutForDelivery({
    required String userEmail,
    required String orderId,
    required String deliveryTime,
  }) async {
    try {
      // 1. Update order status in database to "out for delivery"
      // ... your database update code ...
      
      // 2. Send notification to user
      await NotificationService.notifyUserOfOrderOutForDelivery(
        userEmail: userEmail,
        orderId: orderId,
        deliveryTime: deliveryTime,
      );
      
      print('Out for delivery notification sent to user: $userEmail for order: $orderId');
      
    } catch (e) {
      print('Error processing out for delivery notification: $e');
    }
  }
  
  /// Call this when an order is successfully delivered
  static Future<void> onOrderDelivered({
    required String userEmail,
    required String orderId,
  }) async {
    try {
      // 1. Update order status in database to "delivered"
      // ... your database update code ...
      
      // 2. Send notification to user about successful delivery
      await NotificationService.notifyUserOfOrderDelivered(
        userEmail: userEmail,
        orderId: orderId,
      );
      
      print('Order delivered notification sent to user: $userEmail for order: $orderId');
      
    } catch (e) {
      print('Error processing order delivered notification: $e');
    }
  }
  
  /// Call this to send promotional notifications to all users
  static Future<void> sendPromotionalOffer({
    required String title,
    required String message,
    String? imageUrl,
    String? promoCode,
  }) async {
    try {
      Map<String, String> data = {};
      if (promoCode != null) {
        data['promo_code'] = promoCode;
        data['type'] = 'promotional';
      }
      
      await NotificationService.sendPromotionalNotification(
        title: title,
        body: message,
        imageUrl: imageUrl,
        data: data,
      );
      
      print('Promotional notification sent to all users');
      
    } catch (e) {
      print('Error sending promotional notification: $e');
    }
  }
}

// Example usage in your order management system:
/*

// When admin dispatches an order:
await DeliveryNotificationExample.onOrderDispatched(
  userEmail: "customer@example.com",
  orderId: "ORD-12345",
  estimatedDeliveryDate: DateTime.now().add(Duration(days: 3)),
  trackingNumber: "TRK123456789",
);

// When delivery partner picks up the order:
await DeliveryNotificationExample.onOrderOutForDelivery(
  userEmail: "customer@example.com",
  orderId: "ORD-12345",
  deliveryTime: "2-4 PM today",
);

// When order is successfully delivered:
await DeliveryNotificationExample.onOrderDelivered(
  userEmail: "customer@example.com",
  orderId: "ORD-12345",
);

// Send promotional offers:
await DeliveryNotificationExample.sendPromotionalOffer(
  title: "🎉 Special Offer!",
  message: "Get 20% off on your next order with code SAVE20",
  promoCode: "SAVE20",
);

*/
