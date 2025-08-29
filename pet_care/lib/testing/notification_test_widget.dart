import 'package:flutter/material.dart';
import 'package:pet_care/services/notification_service.dart';

/// Simple test widget to verify notification system functionality
class NotificationTestWidget extends StatefulWidget {
  const NotificationTestWidget({Key? key}) : super(key: key);

  @override
  State<NotificationTestWidget> createState() => _NotificationTestWidgetState();
}

class _NotificationTestWidgetState extends State<NotificationTestWidget> {
  String _status = 'Ready to test notifications';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification System Test'),
        backgroundColor: Color(0xFF8476AA),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notification System Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(_status),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testGetToken,
              child: Text('Test: Get FCM Token'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testSubscriptionNotification,
              child: Text('Test: Subscription Notification'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testDeliveryNotification,
              child: Text('Test: Delivery Notification'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testPromotionalNotification,
              child: Text('Test: Promotional Notification'),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _testGetToken() async {
    setState(() {
      _status = 'Getting FCM token...';
    });
    
    try {
      final token = await NotificationService.getToken();
      setState(() {
        _status = 'FCM Token received: ${token?.substring(0, 20)}...';
      });
    } catch (e) {
      setState(() {
        _status = 'Error getting token: $e';
      });
    }
  }
  
  Future<void> _testSubscriptionNotification() async {
    setState(() {
      _status = 'Testing subscription notification...';
    });
    
    try {
      // This would normally send to admin tokens
      // For testing, we'll just simulate the call
      await NotificationService.notifyAdminOfSubscriptionRequest(
        userName: 'Test User',
        userEmail: 'test@example.com',
        subscriptionType: 'Premium Plan',
        amount: '29.99',
      );
      
      setState(() {
        _status = 'Subscription notification test completed';
      });
    } catch (e) {
      setState(() {
        _status = 'Error testing subscription notification: $e';
      });
    }
  }
  
  Future<void> _testDeliveryNotification() async {
    setState(() {
      _status = 'Testing delivery notification...';
    });
    
    try {
      // This would normally send to user tokens
      // For testing, we'll just simulate the call
      await NotificationService.notifyUserOfDeliveryDispatch(
        userEmail: 'test@example.com',
        orderId: 'TEST-12345',
        estimatedDelivery: '2024-03-25',
        trackingNumber: 'TRK123456789',
      );
      
      setState(() {
        _status = 'Delivery notification test completed';
      });
    } catch (e) {
      setState(() {
        _status = 'Error testing delivery notification: $e';
      });
    }
  }
  
  Future<void> _testPromotionalNotification() async {
    setState(() {
      _status = 'Testing promotional notification...';
    });
    
    try {
      // This would send to all users
      await NotificationService.sendPromotionalNotification(
        title: '🎉 Test Promotion',
        body: 'This is a test promotional notification from VitaPaw!',
        data: {'type': 'promotional', 'test': 'true'},
      );
      
      setState(() {
        _status = 'Promotional notification test completed';
      });
    } catch (e) {
      setState(() {
        _status = 'Error testing promotional notification: $e';
      });
    }
  }
}
