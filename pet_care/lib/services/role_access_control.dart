import 'package:pet_care/firestore_service.dart';

/// Utility class to help with role-based access control
class RoleBasedAccessControl {
  /// Check if the current user has admin privileges
  static Future<bool> isCurrentUserAdmin() async {
    return await FirestoreService.isCurrentUserAdmin();
  }

  /// Get the current user's role
  static Future<String> getCurrentUserRole(String email) async {
    return await FirestoreService.getUserRole(email);
  }

  /// Check if a user has permission to perform admin actions
  static Future<bool> canPerformAdminActions(String email) async {
    String role = await FirestoreService.getUserRole(email);
    return role == 'admin';
  }

  /// Validate role change permissions (only admins can change roles)
  static Future<bool> canChangeUserRole(String adminEmail, String targetEmail) async {
    // Check if the admin has admin privileges
    bool isAdmin = await canPerformAdminActions(adminEmail);
    if (!isAdmin) return false;

    // Prevent admin from demoting themselves (optional security measure)
    if (adminEmail == targetEmail) return false;

    return true;
  }
}
