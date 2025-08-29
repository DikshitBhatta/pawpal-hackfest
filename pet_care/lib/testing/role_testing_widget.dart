import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:pet_care/firestore_service.dart';

/// Testing utility widget for role-based access control
/// This can be used during development to test role functionality
class RoleTestingWidget extends StatefulWidget {
  const RoleTestingWidget({Key? key}) : super(key: key);

  @override
  State<RoleTestingWidget> createState() => _RoleTestingWidgetState();
}

class _RoleTestingWidgetState extends State<RoleTestingWidget> {
  String _currentUserRole = 'Loading...';
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserRole();
    _loadAllUsers();
  }

  Future<void> _loadCurrentUserRole() async {
    try {
      Map<String, dynamic> userData = await FirestoreService.getCurrentUserData();
      setState(() {
        _currentUserRole = userData['role'] ?? 'user';
      });
    } catch (e) {
      setState(() {
        _currentUserRole = 'Error: $e';
      });
    }
  }

  Future<void> _loadAllUsers() async {
    setState(() => _isLoading = true);
    try {
      List<Map<String, dynamic>> users = await FirestoreService.getAllUsers();
      setState(() {
        _allUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading users: $e')),
      );
    }
  }

  Future<void> _toggleUserRole(String email, String currentRole) async {
    String newRole = currentRole == 'admin' ? 'user' : 'admin';
    
    bool success = await FirestoreService.updateUserRole(email, newRole);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Role updated: $email -> $newRole')),
      );
      _loadAllUsers(); // Refresh the list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update role for $email')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Role Testing'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            onPressed: () {
              _loadCurrentUserRole();
              _loadAllUsers();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current User Role:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentUserRole,
                      style: TextStyle(
                        fontSize: 16,
                        color: _currentUserRole == 'admin' ? Colors.red : Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'All Users (${_allUsers.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ?  Center(
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Lottie.asset(
                          'assets/Animations/AnimalcareLoading.json',
                          fit: BoxFit.contain,
                        ),
                      ),
                    )
                  : _allUsers.isEmpty
                      ? const Center(child: Text('No users found'))
                      : ListView.builder(
                          itemCount: _allUsers.length,
                          itemBuilder: (context, index) {
                            final user = _allUsers[index];
                            final email = user['Email'] ?? 'Unknown';
                            final name = user['Name'] ?? 'Unknown';
                            final role = user['role'] ?? 'user';
                            final isVerified = user['isVerified'] ?? false;

                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      role == 'admin' ? Colors.red : Colors.blue,
                                  child: Icon(
                                    role == 'admin'
                                        ? Icons.admin_panel_settings
                                        : Icons.person,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(name),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(email),
                                    Text(
                                      'Role: ${role.toUpperCase()}',
                                      style: TextStyle(
                                        color: role == 'admin'
                                            ? Colors.red
                                            : Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isVerified)
                                      const Icon(Icons.verified, color: Colors.green),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => _toggleUserRole(email, role),
                                      child: Text(
                                        role == 'admin' ? 'Make User' : 'Make Admin',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
