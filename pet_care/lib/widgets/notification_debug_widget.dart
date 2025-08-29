import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:pet_care/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationDebugWidget extends StatefulWidget {
  const NotificationDebugWidget({Key? key}) : super(key: key);

  @override
  State<NotificationDebugWidget> createState() => _NotificationDebugWidgetState();
}

class _NotificationDebugWidgetState extends State<NotificationDebugWidget> {
  String? _fcmToken;
  bool _isLoading = false;
  List<String> _debugLogs = [];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _addLog(String message) {
    setState(() {
      _debugLogs.insert(0, '[${DateTime.now().toLocal()}] $message');
      // Keep only last 20 logs
      if (_debugLogs.length > 20) {
        _debugLogs = _debugLogs.take(20).toList();
      }
    });
  }

  Future<void> _initializeNotifications() async {
    setState(() => _isLoading = true);
    _addLog('🚀 Initializing notification service...');
    
    try {
      // Initialize notification service
      await NotificationService.initialize();
      _addLog('✅ Notification service initialized');

      // Get FCM token
      final token = await NotificationService.getToken();
      setState(() => _fcmToken = token);
      
      if (token != null) {
        _addLog('🔑 FCM Token received: ${token.substring(0, 20)}...');
        
        // Save token to Firestore if user is logged in
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await NotificationService.saveTokenToFirestore(user.email!);
          _addLog('💾 Token saved to Firestore for ${user.email}');
        } else {
          _addLog('⚠️ No user logged in - token not saved to Firestore');
        }
      } else {
        _addLog('❌ Failed to get FCM token');
      }
    } catch (e) {
      _addLog('❌ Error initializing notifications: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testSubscriptionNotification() async {
    _addLog('📧 Testing subscription notification...');
    try {
      await NotificationService.notifyAdminOfSubscriptionRequest(
        userName: 'Test User',
        userEmail: 'test@example.com',
        subscriptionType: 'Premium Monthly',
        amount: '29.99',
      );
      _addLog('✅ Subscription notification sent');
    } catch (e) {
      _addLog('❌ Error sending subscription notification: $e');
    }
  }

  Future<void> _testApprovalNotification() async {
    _addLog('📧 Testing approval notification...');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _addLog('❌ No user logged in for approval test');
      return;
    }

    try {
      await NotificationService.notifyUserOfSubscriptionApproval(
        userEmail: user.email!,
        subscriptionType: 'Premium Monthly',
        validUntil: DateTime.now().add(Duration(days: 30)).toIso8601String(),
      );
      _addLog('✅ Approval notification sent');
    } catch (e) {
      _addLog('❌ Error sending approval notification: $e');
    }
  }

  Future<void> _testLocalNotification() async {
    _addLog('🧪 Testing local notification...');
    try {
      await NotificationService.testLocalNotification();
      _addLog('✅ Local test notification sent');
    } catch (e) {
      _addLog('❌ Error sending local test notification: $e');
    }
  }

  void _clearLogs() {
    setState(() {
      _debugLogs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Debug'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeNotifications,
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _fcmToken != null ? Icons.check_circle : Icons.error,
                        color: _fcmToken != null ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'FCM Token Status',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_fcmToken != null) ...[
                    Text('Token: ${_fcmToken!.substring(0, 30)}...'),
                    Text('Length: ${_fcmToken!.length} characters'),
                  ] else ...[
                    const Text('No FCM token available'),
                  ],
                  const SizedBox(height: 8),
                  Text('User: ${FirebaseAuth.instance.currentUser?.email ?? 'Not logged in'}'),
                ],
              ),
            ),
          ),

          // Test Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.notifications),
                    label: const Text('Test Subscription Request'),
                    onPressed: _isLoading ? null : _testSubscriptionNotification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Test Approval Notification'),
                    onPressed: _isLoading ? null : _testApprovalNotification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.phone_android),
                    label: const Text('Test Local Notification'),
                    onPressed: _isLoading ? null : _testLocalNotification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Debug Logs
          Expanded(
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Debug Logs (${_debugLogs.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Expanded(
                    child: _debugLogs.isEmpty
                        ? const Center(
                            child: Text('No logs yet...'),
                          )
                        : ListView.builder(
                            itemCount: _debugLogs.length,
                            itemBuilder: (context, index) {
                              final log = _debugLogs[index];
                              Color? textColor;
                              if (log.contains('❌')) {
                                textColor = Colors.red;
                              } else if (log.contains('✅')) {
                                textColor = Colors.green;
                              } else if (log.contains('⚠️')) {
                                textColor = Colors.orange;
                              }
                              
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                child: Text(
                                  log,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: textColor,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),

          // Loading indicator
          if (_isLoading)
             Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Lottie.asset(
                  'assets/Animations/AnimalcareLoading.json',
                  fit: BoxFit.contain,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
