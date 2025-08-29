import 'package:flutter/material.dart';
import 'package:pet_care/firestore_service.dart';
import 'package:pet_care/utils/image_utils.dart';

class ColorsScheme {
  static const Color primaryBackgroundColor = Color(0xff2A2438);
  static const Color secondaryBackgroundColor = Color(0xff352F44);
  static const Color primaryTextColor = Color(0xffFFFFFF);
  static const Color secondaryTextColor = Color(0xffB0A0D6);
  static const Color primaryIconColor = Color(0xff8476AA);
}

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      isLoading = true;
    });

    try {
      List<Map<String, dynamic>> fetchedUsers = await FirestoreService.getAllUsers();
      setState(() {
        users = fetchedUsers;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading users: $e')),
      );
    }
  }

  Future<void> _updateUserRole(String email, String newRole) async {
    try {
      bool success = await FirestoreService.updateUserRole(email, newRole);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User role updated successfully')),
        );
        _loadUsers(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update user role')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating user role: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsScheme.primaryBackgroundColor,
      appBar: AppBar(
        backgroundColor: ColorsScheme.primaryBackgroundColor,
        title: Text(
          'User Management',
          style: TextStyle(
            color: ColorsScheme.primaryTextColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: ColorsScheme.primaryTextColor),
        actions: [
          IconButton(
            onPressed: _loadUsers,
            icon: Icon(Icons.refresh, color: ColorsScheme.primaryTextColor),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: ColorsScheme.primaryIconColor,
              ),
            )
          : users.isEmpty
              ? Center(
                  child: Text(
                    'No users found',
                    style: TextStyle(
                      color: ColorsScheme.secondaryTextColor,
                      fontSize: 18,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _buildUserCard(user);
                  },
                ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    String name = user['Name'] ?? 'No Name';
    String email = user['Email'] ?? 'No Email';
    String role = user['role'] ?? 'user';
    String pic = user['Pic'] ?? '';
    bool isVerified = user['isVerified'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      color: ColorsScheme.secondaryBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Profile Picture
            ImageUtils.buildProfileAvatar(
              imagePath: pic.isNotEmpty ? pic : null,
              radius: 30,
              backgroundColor: ColorsScheme.primaryIconColor,
            ),
            const SizedBox(width: 16),
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: ColorsScheme.primaryTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      color: ColorsScheme.secondaryTextColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: role == 'admin'
                              ? Colors.orange.withOpacity(0.2)
                              : Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          role.toUpperCase(),
                          style: TextStyle(
                            color: role == 'admin' ? Colors.orange : Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'VERIFIED',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Role Toggle Button
            PopupMenuButton<String>(
              onSelected: (String newRole) {
                if (newRole != role) {
                  _showRoleChangeConfirmation(email, name, role, newRole);
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'user',
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Make User'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'admin',
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Make Admin'),
                    ],
                  ),
                ),
              ],
              icon: Icon(
                Icons.more_vert,
                color: ColorsScheme.primaryIconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRoleChangeConfirmation(
      String email, String name, String currentRole, String newRole) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ColorsScheme.secondaryBackgroundColor,
          title: Text(
            'Change User Role',
            style: TextStyle(color: ColorsScheme.primaryTextColor),
          ),
          content: Text(
            'Are you sure you want to change $name\'s role from $currentRole to $newRole?',
            style: TextStyle(color: ColorsScheme.secondaryTextColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: ColorsScheme.secondaryTextColor),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateUserRole(email, newRole);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsScheme.primaryIconColor,
              ),
              child: Text(
                'Confirm',
                style: TextStyle(color: ColorsScheme.primaryTextColor),
              ),
            ),
          ],
        );
      },
    );
  }
}
