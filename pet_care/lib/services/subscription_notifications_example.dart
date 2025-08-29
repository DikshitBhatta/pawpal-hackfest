// This file demonstrates how to integrate the notification service 
// into your payment and subscription workflow

import 'package:pet_care/services/notification_service.dart';

class SubscriptionNotificationExample {
  
  /// Call this when user completes payment and subscription request
  static Future<void> onSubscriptionPaymentCompleted({
    required String userEmail,
    required String userName,
    required String subscriptionType,
    required String amount,
  }) async {
    try {
      // 1. Process payment (your existing payment logic)
      // ... your payment processing code ...
      
      // 2. Create subscription request in database
      // ... your database update code ...
      
      // 3. Send notification to admin about new subscription request
      await NotificationService.notifyAdminOfSubscriptionRequest(
        userName: userName,
        userEmail: userEmail,
        subscriptionType: subscriptionType,
        amount: amount,
      );
      
      print('Subscription request notification sent to admin');
      
    } catch (e) {
      print('Error processing subscription payment: $e');
    }
  }
  
  /// Call this when admin approves a subscription
  static Future<void> onSubscriptionApproved({
    required String userEmail,
    required String subscriptionType,
    required DateTime validUntil,
  }) async {
    try {
      // 1. Update subscription status in database
      // ... your database update code ...
      
      // 2. Send notification to user about approval
      await NotificationService.notifyUserOfSubscriptionApproval(
        userEmail: userEmail,
        subscriptionType: subscriptionType,
        validUntil: validUntil.toString().split(' ')[0], // Format: YYYY-MM-DD
      );
      
      print('Subscription approval notification sent to user: $userEmail');
      
    } catch (e) {
      print('Error processing subscription approval: $e');
    }
  }
  
  /// Call this when admin rejects a subscription
  static Future<void> onSubscriptionRejected({
    required String userEmail,
    required String subscriptionType,
    required String reason,
  }) async {
    try {
      // 1. Update subscription status in database
      // ... your database update code ...
      
      // 2. Send notification to user about rejection
      await NotificationService.notifyUserOfSubscriptionRejection(
        userEmail: userEmail,
        subscriptionType: subscriptionType,
        reason: reason,
      );
      
      print('Subscription rejection notification sent to user: $userEmail');
      
    } catch (e) {
      print('Error processing subscription rejection: $e');
    }
  }
}

// Example usage in your payment form or subscription handling:
/*

// In your payment completion handler:
await SubscriptionNotificationExample.onSubscriptionPaymentCompleted(
  userEmail: "user@example.com",
  userName: "John Doe",
  subscriptionType: "Premium Plan",
  amount: "29.99",
);

// In your admin dashboard when approving subscription:
await SubscriptionNotificationExample.onSubscriptionApproved(
  userEmail: "user@example.com",
  subscriptionType: "Premium Plan",
  validUntil: DateTime.now().add(Duration(days: 30)),
);

// In your admin dashboard when rejecting subscription:
await SubscriptionNotificationExample.onSubscriptionRejected(
  userEmail: "user@example.com",
  subscriptionType: "Premium Plan",
  reason: "Payment verification failed",
);

*/
