import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class FCMv1Service {
  static const String _projectId = 'petpick-8250c'; // Your Firebase project ID
  static const String _scope = 'https://www.googleapis.com/auth/firebase.messaging';
  
  /// Gets OAuth2 access token for FCM v1 API
  static Future<String> _getAccessToken() async {
    try {
      // Load service account key from assets
      final serviceAccountJson = await rootBundle.loadString('assets/service-account-key.json');
      final serviceAccount = ServiceAccountCredentials.fromJson(json.decode(serviceAccountJson));
      
      // Get access token
      final client = http.Client();
      final credentials = await obtainAccessCredentialsViaServiceAccount(
        serviceAccount,
        [_scope],
        client,
      );
      
      client.close();
      return credentials.accessToken.data;
    } catch (e) {
      print('Error getting access token: $e');
      rethrow;
    }
  }

  /// Sends a notification to a single device token
  static Future<bool> sendNotification({
    required String token,
    required String title,
    required String body,
    Map<String, String>? data,
    String? imageUrl,
  }) async {
    try {
      final accessToken = await _getAccessToken();
      
      final url = 'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';
      
      final payload = {
        'message': {
          'token': token,
          'notification': {
            'title': title,
            'body': body,
            if (imageUrl != null) 'image': imageUrl,
          },
          'data': data ?? {},
          'android': {
            'priority': 'high',
            'notification': {
              'channel_id': 'pet_care_notifications',
              'icon': '@mipmap/ic_launcher',
              'color': '#8476AA',
              'sound': 'default',
            },
          },
          'apns': {
            'payload': {
              'aps': {
                'alert': {
                  'title': title,
                  'body': body,
                },
                'sound': 'default',
                'badge': 1,
                'category': 'pet_care_notification',
              },
            },
          },
        },
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully to token: ${token.substring(0, 20)}...');
        return true;
      } else {
        print('Failed to send notification: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending notification: $e');
      return false;
    }
  }

  /// Sends notifications to multiple device tokens
  static Future<Map<String, bool>> sendToMultipleTokens({
    required List<String> tokens,
    required String title,
    required String body,
    Map<String, String>? data,
    String? imageUrl,
  }) async {
    Map<String, bool> results = {};
    
    // Send notifications concurrently for better performance
    final futures = tokens.map((token) async {
      final success = await sendNotification(
        token: token,
        title: title,
        body: body,
        data: data,
        imageUrl: imageUrl,
      );
      return MapEntry(token, success);
    });
    
    final completedFutures = await Future.wait(futures);
    
    for (final entry in completedFutures) {
      results[entry.key] = entry.value;
    }
    
    final successCount = results.values.where((success) => success).length;
    print('Sent notifications to $successCount out of ${tokens.length} devices');
    
    return results;
  }

  /// Sends notification to topic
  static Future<bool> sendToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, String>? data,
    String? imageUrl,
  }) async {
    try {
      final accessToken = await _getAccessToken();
      
      final url = 'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';
      
      final payload = {
        'message': {
          'topic': topic,
          'notification': {
            'title': title,
            'body': body,
            if (imageUrl != null) 'image': imageUrl,
          },
          'data': data ?? {},
          'android': {
            'priority': 'high',
            'notification': {
              'channel_id': 'pet_care_notifications',
              'icon': '@mipmap/ic_launcher',
              'color': '#8476AA',
              'sound': 'default',
            },
          },
          'apns': {
            'payload': {
              'aps': {
                'alert': {
                  'title': title,
                  'body': body,
                },
                'sound': 'default',
              },
            },
          },
        },
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully to topic: $topic');
        return true;
      } else {
        print('Failed to send topic notification: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending topic notification: $e');
      return false;
    }
  }
}
