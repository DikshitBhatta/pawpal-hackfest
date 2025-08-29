import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:pet_care/firestore_service.dart';
import 'fcm_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Global navigation key for handling navigation from notifications
  static GlobalKey<NavigatorState>? navigatorKey;

  // Debug flags
  static bool _debugMode = true;
  
  static void _debugPrint(String message) {
    if (_debugMode) {
      print('[NOTIFICATION DEBUG] $message');
    }
  }

  /// Initialize the notification service
  static Future<void> initialize([GlobalKey<NavigatorState>? navKey]) async {
    try {
      navigatorKey = navKey;
      _debugPrint('🚀 Starting notification service initialization...');
      
      // Request permission
      _debugPrint('📋 Requesting permissions...');
      await _requestPermission();
      
      // Initialize local notifications
      _debugPrint('📱 Initializing local notifications...');
      await _initializeLocalNotifications();
      
      // Setup message handlers
      _debugPrint('🔧 Setting up message handlers...');
      
      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Handle notification taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      
      // Get initial message (app opened from notification)
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _debugPrint('📨 App opened from notification: ${initialMessage.messageId}');
        _handleNotificationTap(initialMessage);
      }
      
      // Get and log token
      final token = await getToken();
      _debugPrint('🔑 FCM Token obtained: ${token?.substring(0, 20)}...');
      
      _debugPrint('✅ Notification service initialization complete!');
    } catch (e) {
      _debugPrint('❌ Error initializing notification service: $e');
      print('NOTIFICATION INIT ERROR: $e');
    }
  }

  /// Request notification permissions
  static Future<void> _requestPermission() async {
    try {
      // Request Firebase Messaging permissions
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      _debugPrint('🔐 Firebase Permission status: ${settings.authorizationStatus}');
      _debugPrint('🔔 Alert enabled: ${settings.alert}');
      _debugPrint('🔕 Sound enabled: ${settings.sound}');
      _debugPrint('🔶 Badge enabled: ${settings.badge}');
      
      // Request AwesomeNotifications permissions
      bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) {
        _debugPrint('🔐 Requesting AwesomeNotifications permissions...');
        isAllowed = await AwesomeNotifications().requestPermissionToSendNotifications();
      }
      _debugPrint('🔐 AwesomeNotifications permission: $isAllowed');
      
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _debugPrint('⚠️ Firebase notification permissions denied by user');
      }
      
      if (!isAllowed) {
        _debugPrint('⚠️ AwesomeNotifications permissions denied by user');
      }
    } catch (e) {
      _debugPrint('❌ Error requesting permission: $e');
      rethrow;
    }
  }

  /// Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      final initialized = await _localNotifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onLocalNotificationTap,
      );
      
      _debugPrint('📱 Local notifications initialized: $initialized');

      // Create notification channel for Android
      const channel = AndroidNotificationChannel(
        'pet_care_notifications',
        'Pet Care Notifications',
        description: 'Notifications for Pet Care App',
        importance: Importance.high,
      );

      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(channel);
        _debugPrint('📢 Android notification channel created');
      }
    } catch (e) {
      _debugPrint('❌ Error initializing local notifications: $e');
      rethrow;
    }
  }

  /// Get FCM token for current device
  static Future<String?> getToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      _debugPrint('🔑 FCM Token retrieved: ${token != null ? 'SUCCESS' : 'FAILED'}');
      if (token != null) {
        _debugPrint('🔑 Token length: ${token.length}');
        _debugPrint('🔑 Token preview: ${token.substring(0, 20)}...');
      }
      return token;
    } catch (e) {
      _debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Save FCM token to Firestore for the user
  static Future<void> saveTokenToFirestore(String userEmail) async {
    try {
      _debugPrint('💾 Saving FCM token to Firestore for user: $userEmail');
      final token = await getToken();
      if (token != null) {
        await FirestoreService.updateUserFCMToken(userEmail, token);
        _debugPrint('✅ FCM token saved successfully for $userEmail');
      } else {
        _debugPrint('❌ Failed to get FCM token for $userEmail');
      }
    } catch (e) {
      _debugPrint('❌ Error saving FCM token: $e');
    }
  }

  /// Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic $topic: $e');
    }
  }

  // Handle background messages
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    _debugPrint('🌙 Background message received: ${message.messageId}');
    _debugPrint('📋 Title: ${message.notification?.title}');
    _debugPrint('📋 Body: ${message.notification?.body}');
    _debugPrint('📋 Data: ${message.data}');
    await _showLocalNotification(message);
  }

  // Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _debugPrint('☀️ Foreground message received: ${message.messageId}');
    _debugPrint('📋 Title: ${message.notification?.title}');
    _debugPrint('📋 Body: ${message.notification?.body}');
    _debugPrint('📋 Data: ${message.data}');
    await _showLocalNotification(message);
  }

  // Show local notification using both systems for better compatibility
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      _debugPrint('📱 Preparing local notification...');
      
      if (message.notification == null) {
        _debugPrint('⚠️ Warning: Message has no notification payload');
        return;
      }

      final title = message.notification?.title ?? 'Pet Care';
      final body = message.notification?.body ?? 'You have a new notification';

      _debugPrint('📱 Showing notification: $title');
      _debugPrint('📱 Notification body: $body');

      // Method 1: Use AwesomeNotifications (more reliable on Android)
      try {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: message.hashCode,
            channelKey: 'vitapaw_local',
            title: title,
            body: body,
            wakeUpScreen: true,
            category: NotificationCategory.Message,
            notificationLayout: NotificationLayout.Default,
            payload: Map<String, String>.from(message.data),
          ),
        );
        _debugPrint('✅ AwesomeNotifications displayed successfully');
      } catch (e) {
        _debugPrint('❌ AwesomeNotifications error: $e');
      }

      // Method 2: Use flutter_local_notifications as fallback
      try {
        const androidDetails = AndroidNotificationDetails(
          'pet_care_notifications',
          'Pet Care Notifications',
          channelDescription: 'Notifications for Pet Care App',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF8476AA),
          enableVibration: true,
          playSound: true,
        );

        const iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        const details = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        await _localNotifications.show(
          message.hashCode,
          title,
          body,
          details,
          payload: message.data.toString(),
        );
        
        _debugPrint('✅ Flutter local notification displayed successfully');
      } catch (e) {
        _debugPrint('❌ Flutter local notifications error: $e');
      }
      
    } catch (e) {
      _debugPrint('❌ Error showing local notification: $e');
    }
  }

  // Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    _debugPrint('👆 Remote notification tapped');
    _debugPrint('👆 Message data: ${message.data}');
    _navigateBasedOnNotificationType(message.data);
  }

  // Handle local notification tap
  static void _onLocalNotificationTap(NotificationResponse response) {
    _debugPrint('👆 Local notification tapped');
    _debugPrint('👆 Payload: ${response.payload}');
    // Parse payload and navigate
    if (response.payload != null) {
      try {
        // Handle the payload data for navigation
        _debugPrint('👆 Processing notification tap navigation...');
      } catch (e) {
        _debugPrint('❌ Error processing notification tap: $e');
      }
    }
  }

  // Navigate based on notification type
  static void _navigateBasedOnNotificationType(Map<String, dynamic> data) {
    _debugPrint('🧭 Processing navigation for notification type');
    _debugPrint('🧭 Notification data: $data');
    
    if (navigatorKey?.currentContext == null) {
      _debugPrint('❌ No navigation context available');
      return;
    }
    
    final notificationType = data['type'];
    final context = navigatorKey!.currentContext!;
    
    _debugPrint('🧭 Notification type: $notificationType');
    
    switch (notificationType) {
      case 'subscription_request':
        _debugPrint('🧭 Navigating to admin subscription management');
        // Navigate to admin subscription management
        Navigator.pushNamed(context, '/admin/subscriptions');
        break;
      case 'subscription_approved':
        _debugPrint('🧭 Navigating to user subscription status');
        // Navigate to user subscription status
        Navigator.pushNamed(context, '/user/subscriptions');
        break;
      case 'delivery_dispatched':
        _debugPrint('🧭 Navigating to delivery tracking');
        // Navigate to delivery tracking
        Navigator.pushNamed(context, '/delivery/tracking');
        break;
      default:
        _debugPrint('🧭 No specific navigation, going to home');
        // Navigate to home or default screen
        Navigator.pushNamed(context, '/');
        break;
    }
  }

  // ============= BUSINESS LOGIC NOTIFICATION METHODS =============

  /// Test local notification display
  static Future<void> testLocalNotification() async {
    try {
      _debugPrint('🧪 Testing local notification...');
      
      // Test AwesomeNotifications
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'vitapaw_local',
          title: '🧪 Test Notification',
          body: 'This is a test notification from Vitapaw!',
          wakeUpScreen: true,
          category: NotificationCategory.Message,
          notificationLayout: NotificationLayout.Default,
        ),
      );
      
      _debugPrint('✅ Test notification sent successfully');
    } catch (e) {
      _debugPrint('❌ Error sending test notification: $e');
    }
  }

  /// Notify admin when user makes a subscription request
  static Future<void> notifyAdminOfSubscriptionRequest({
    required String userName,
    required String userEmail,
    required String subscriptionType,
    required String amount,
  }) async {
    try {
      _debugPrint('📧 Preparing admin notification for subscription request');
      _debugPrint('📧 User: $userName ($userEmail)');
      _debugPrint('📧 Subscription: $subscriptionType - $amount');
      
      // Get all admin tokens
      final adminTokens = await FirestoreService.getAdminFCMTokens();
      
      _debugPrint('📧 Found ${adminTokens.length} admin tokens');
      
      if (adminTokens.isNotEmpty) {
        await FCMv1Service.sendToMultipleTokens(
          tokens: adminTokens,
          title: '🔔 New Subscription Request',
          body: '$userName has requested a $subscriptionType subscription for ฿${amount}',
          data: {
            'type': 'subscription_request',
            'userEmail': userEmail,
            'userName': userName,
            'subscriptionType': subscriptionType,
            'amount': amount,
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        );
        _debugPrint('✅ Admin notification sent for subscription request from $userName');
      } else {
        _debugPrint('⚠️ No admin tokens found to send notification');
      }
    } catch (e) {
      _debugPrint('❌ Error notifying admin of subscription request: $e');
    }
  }

  /// Notify user when their subscription is approved
  static Future<void> notifyUserOfSubscriptionApproval({
    required String userEmail,
    required String subscriptionType,
    required String validUntil,
  }) async {
    try {
      _debugPrint('📧 Preparing user notification for subscription approval');
      _debugPrint('📧 User: $userEmail');
      _debugPrint('📧 Subscription: $subscriptionType');
      
      final userToken = await FirestoreService.getUserFCMToken(userEmail);
      
      if (userToken != null) {
        _debugPrint('📧 Found user token, sending notification...');
        await FCMv1Service.sendNotification(
          token: userToken,
          title: '✅ Subscription Approved!',
          body: 'Your $subscriptionType subscription has been approved and is now active.',
          data: {
            'type': 'subscription_approved',
            'subscriptionType': subscriptionType,
            'validUntil': validUntil,
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        );
        _debugPrint('✅ User notification sent for subscription approval to $userEmail');
      } else {
        _debugPrint('⚠️ No FCM token found for user: $userEmail');
      }
    } catch (e) {
      _debugPrint('❌ Error notifying user of subscription approval: $e');
    }
  }

  /// Notify user when their subscription is rejected
  static Future<void> notifyUserOfSubscriptionRejection({
    required String userEmail,
    required String subscriptionType,
    required String reason,
  }) async {
    try {
      final userToken = await FirestoreService.getUserFCMToken(userEmail);
      
      if (userToken != null) {
        await FCMv1Service.sendNotification(
          token: userToken,
          title: '❌ Subscription Request Declined',
          body: 'Your $subscriptionType subscription request has been declined. Reason: $reason',
          data: {
            'type': 'subscription_rejected',
            'subscriptionType': subscriptionType,
            'reason': reason,
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        );
        print('User notification sent for subscription rejection to $userEmail');
      } else {
        print('No FCM token found for user: $userEmail');
      }
    } catch (e) {
      print('Error notifying user of subscription rejection: $e');
    }
  }

  /// Notify user when their delivery is dispatched
  static Future<void> notifyUserOfDeliveryDispatch({
    required String userEmail,
    required String orderId,
    required String estimatedDelivery,
    String? trackingNumber,
  }) async {
    try {
      final userToken = await FirestoreService.getUserFCMToken(userEmail);
      
      if (userToken != null) {
        await FCMv1Service.sendNotification(
          token: userToken,
          title: '🚚 Order Dispatched!',
          body: 'Your order #$orderId has been dispatched. Estimated delivery: $estimatedDelivery',
          data: {
            'type': 'delivery_dispatched',
            'orderId': orderId,
            'estimatedDelivery': estimatedDelivery,
            'trackingNumber': trackingNumber ?? '',
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        );
        print('User notification sent for delivery dispatch to $userEmail');
      } else {
        print('No FCM token found for user: $userEmail');
      }
    } catch (e) {
      print('Error notifying user of delivery dispatch: $e');
    }
  }

  /// Notify user when their order is out for delivery
  static Future<void> notifyUserOfOrderOutForDelivery({
    required String userEmail,
    required String orderId,
    required String deliveryTime,
  }) async {
    try {
      final userToken = await FirestoreService.getUserFCMToken(userEmail);
      
      if (userToken != null) {
        await FCMv1Service.sendNotification(
          token: userToken,
          title: '🚛 Out for Delivery!',
          body: 'Your order #$orderId is out for delivery. Expected delivery: $deliveryTime',
          data: {
            'type': 'out_for_delivery',
            'orderId': orderId,
            'deliveryTime': deliveryTime,
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        );
        print('User notification sent for out for delivery to $userEmail');
      }
    } catch (e) {
      print('Error notifying user of out for delivery: $e');
    }
  }

  /// Notify user when their order is delivered
  static Future<void> notifyUserOfOrderDelivered({
    required String userEmail,
    required String orderId,
  }) async {
    try {
      final userToken = await FirestoreService.getUserFCMToken(userEmail);
      
      if (userToken != null) {
        await FCMv1Service.sendNotification(
          token: userToken,
          title: '✅ Order Delivered!',
          body: 'Your order #$orderId has been successfully delivered. Thank you for choosing VitaPaw!',
          data: {
            'type': 'order_delivered',
            'orderId': orderId,
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        );
        print('User notification sent for order delivered to $userEmail');
      }
    } catch (e) {
      print('Error notifying user of order delivered: $e');
    }
  }

  /// Send promotional notification to all users
  static Future<void> sendPromotionalNotification({
    required String title,
    required String body,
    String? imageUrl,
    Map<String, String>? data,
  }) async {
    try {
      await FCMv1Service.sendToTopic(
        topic: 'all_users',
        title: title,
        body: body,
        imageUrl: imageUrl,
        data: data ?? {},
      );
      print('Promotional notification sent to all users');
    } catch (e) {
      print('Error sending promotional notification: $e');
    }
  }

  /// Send notification to specific user role (admin, user)
  static Future<void> sendNotificationToRole({
    required String role,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      await FCMv1Service.sendToTopic(
        topic: '${role}_users',
        title: title,
        body: body,
        data: data ?? {},
      );
      print('Notification sent to $role users');
    } catch (e) {
      print('Error sending notification to $role users: $e');
    }
  }
}
