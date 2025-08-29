import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Creates a user document in Firestore with default role 'user'
  static Future<bool> createUserDocument(Map<String, dynamic> userData) async {
    try {
      // Add default role as 'user' for new signups
      userData['role'] = 'user';
      
      await _firestore
          .collection('UserData')
          .doc(userData['Email'])
          .set(userData, SetOptions(merge: false));
      
      print('User document created successfully with role: user');
      return true;
    } catch (e) {
      print('Error creating user document: $e');
      return false;
    }
  }

  /// Gets user role from Firestore
  static Future<String> getUserRole(String email) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('UserData')
          .doc(email)
          .get();
      
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['role'] ?? 'user'; // Default to 'user' if role not found
      }
      return 'user'; // Default role
    } catch (e) {
      print('Error getting user role: $e');
      return 'user'; // Default to 'user' on error
    }
  }

  /// Updates user role (only admins should call this)
  static Future<bool> updateUserRole(String email, String newRole) async {
    try {
      await _firestore
          .collection('UserData')
          .doc(email)
          .update({'role': newRole});
      
      print('User role updated successfully: $email -> $newRole');
      return true;
    } catch (e) {
      print('Error updating user role: $e');
      return false;
    }
  }

  /// Gets all users (for admin dashboard)
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('UserData')
          .get();
      
      List<Map<String, dynamic>> users = [];
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        userData['documentId'] = doc.id; // Add document ID for reference
        users.add(userData);
      }
      
      return users;
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  /// Checks if current user is admin
  static Future<bool> isCurrentUserAdmin() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return false;
      
      String role = await getUserRole(currentUser.email ?? '');
      return role == 'admin';
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  /// Gets current user data with role
  static Future<Map<String, dynamic>> getCurrentUserData() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {};
      }
      
      DocumentSnapshot doc = await _firestore
          .collection('UserData')
          .doc(currentUser.email)
          .get();
      
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        // Ensure role field exists
        userData['role'] = userData['role'] ?? 'user';
        return userData;
      }
      
      // Return default user data if document doesn't exist
      return {
        'Name': '',
        'Email': currentUser.email ?? '',
        'isVerified': false,
        'Pic': '',
        'role': 'user',
        'LAT': 31.5607552,
        'LONG': 74.378948
      };
    } catch (e) {
      print('Error getting current user data: $e');
      return {};
    }
  }

  /// Updates the FCM token for a user in Firestore
  static Future<void> updateUserFCMToken(String userEmail, String token) async {
    try {
      await _firestore.collection('UserData').doc(userEmail).update({
        'fcmToken': token,
      });
      print('FCM token updated for $userEmail');
    } catch (e) {
      print('Error updating FCM token for $userEmail: $e');
    }
  }

  /// Gets the FCM token for a user from Firestore
  static Future<String?> getUserFCMToken(String userEmail) async {
    try {
      final doc = await _firestore.collection('UserData').doc(userEmail).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return data['fcmToken'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting FCM token for $userEmail: $e');
      return null;
    }
  }

  /// Gets all admin FCM tokens from Firestore
  static Future<List<String>> getAdminFCMTokens() async {
    try {
      final query = await _firestore
          .collection('UserData')
          .where('role', isEqualTo: 'admin')
          .get();
      final tokens = <String>[];
      for (final doc in query.docs) {
        final data = doc.data();
        if (data['fcmToken'] != null && data['fcmToken'].toString().isNotEmpty) {
          tokens.add(data['fcmToken']);
        }
      }
      return tokens;
    } catch (e) {
      print('Error getting admin FCM tokens: $e');
      return [];
    }
  }
}
