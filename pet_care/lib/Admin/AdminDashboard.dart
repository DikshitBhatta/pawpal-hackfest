import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:pet_care/firestore_service.dart';
import 'package:pet_care/CredentialsScreen/LoginPage.dart';
import 'package:pet_care/utils/app_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'IngredientManagement.dart';
import 'Inventory.dart';
import 'AIRuleMapping.dart';
import 'DeliverySetup.dart';
import 'OrderReview.dart';
import 'SubscriptionManagement.dart';

class ColorsScheme {
  static const Color primaryBackgroundColor = Color(0xff2A2438);
  static const Color secondaryBackgroundColor = Color(0xff352F44);
  static const Color primaryTextColor = Color(0xffFFFFFF);
  static const Color secondaryTextColor = Color(0xffB0A0D6);
  static const Color primaryIconColor = Color(0xff8476AA);
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsScheme.primaryBackgroundColor,
      appBar: AppBar(
        backgroundColor: ColorsScheme.primaryBackgroundColor,
        title: Text(
          'Admin Dashboard',
          style: TextStyle(
            color: ColorsScheme.primaryTextColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: Icon(Icons.logout, color: ColorsScheme.primaryTextColor),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
          children: [
            _buildDashboardCard(
              context,
              'Ingredient Management',
              Icons.inventory_2,
              'Manage ingredients, nutrition data, and inventory',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const IngredientManagement()),
              ),
            ),
            _buildDashboardCard(
              context,
              'Inventory',
              Icons.inventory,
              'View and manage ingredient inventory',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Inventory()),
              ),
            ),
            _buildDashboardCard(
              context,
              'AI Rule Mapping',
              Icons.psychology,
              'Configure AI recommendation rules',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AIRuleMapping()),
              ),
            ),
            _buildDashboardCard(
              context,
              'Delivery Setup',
              Icons.local_shipping,
              'Manage delivery zones and schedules',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DeliverySetup()),
              ),
            ),
            _buildDashboardCard(
              context,
              'User Management',
              Icons.people,
              'Manage user roles and permissions',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserManagementScreen()),
              ),
            ),
            _buildDashboardCard(
              context,
              'Subscription Management',
              Icons.subscriptions,
              'Review and approve user subscriptions',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SubscriptionManagement()),
              ),
            ),
            _buildDashboardCard(
              context,
              'Order Review',
              Icons.receipt_long,
              'Review and manage customer orders',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OrderReview()),
              ),
            ),
            _buildDashboardCard(
              context,
              'Analytics',
              Icons.analytics,
              'View business metrics and insights',
              () => _showComingSoon(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to logout?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Logout'),
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog first
                
                try {
                  var pref = await SharedPreferences.getInstance();
                  await pref.remove('userEmail');
                  
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => Login()),
                    (route) => false,
                  );
                } catch (e) {
                  print('Error during logout: $e');
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    String description,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: ColorsScheme.secondaryBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 30,
              color: ColorsScheme.primaryIconColor,
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  color: ColorsScheme.primaryTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                description,
                style: TextStyle(
                  color: ColorsScheme.secondaryTextColor,
                  fontSize: 11, // Increased from 8 to 11
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorsScheme.secondaryBackgroundColor,
        title: Text(
          'Coming Soon',
          style: TextStyle(color: ColorsScheme.primaryTextColor),
        ),
        content: Text(
          'This feature is under development.',
          style: TextStyle(color: ColorsScheme.secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: ColorsScheme.primaryIconColor),
            ),
          ),
        ],
      ),
    );
  }
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
    try {
      List<Map<String, dynamic>> fetchedUsers = await FirestoreService.getAllUsers();
      setState(() {
        users = fetchedUsers;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateUserRole(String email, String newRole) async {
    try {
      bool success = await FirestoreService.updateUserRole(email, newRole);
      if (success) {
        _showSnackBar('User role updated successfully');
        _loadUsers(); // Reload users
      } else {
        _showSnackBar('Failed to update user role');
      }
    } catch (e) {
      print('Error updating user role: $e');
      _showSnackBar('Error updating user role');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showRoleChangeDialog(String email, String currentRole) {
    String newRole = currentRole == 'admin' ? 'user' : 'admin';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorsScheme.secondaryBackgroundColor,
        title: Text(
          'Change User Role',
          style: TextStyle(color: ColorsScheme.primaryTextColor),
        ),
        content: Text(
          'Change role from "$currentRole" to "$newRole" for $email?',
          style: TextStyle(color: ColorsScheme.secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: ColorsScheme.secondaryTextColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateUserRole(email, newRole);
            },
            child: Text(
              'Confirm',
              style: TextStyle(color: ColorsScheme.primaryIconColor),
            ),
          ),
        ],
      ),
    );
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: ColorsScheme.primaryTextColor),
        ),
        elevation: 0,
      ),
      body: isLoading
          ? Center(
              child: Lottie.asset(
                'assets/Animations/AnimalcareLoading.json',
                width: 80,
                height: 80,
                fit: BoxFit.contain,
              ),
            )
          : users.isEmpty
              ? Center(
                  child: Text(
                    'No users found',
                    style: TextStyle(
                      color: ColorsScheme.secondaryTextColor,
                      fontSize: 16,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final email = user['Email'] ?? 'Unknown';
                    final name = user['Name'] ?? 'Unknown';
                    final role = user['role'] ?? 'user';
                    final isVerified = user['isVerified'] ?? false;

                    return Card(
                      color: ColorsScheme.secondaryBackgroundColor,
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: role == 'admin' 
                              ? Colors.orange 
                              : ColorsScheme.primaryIconColor,
                          child: Icon(
                            role == 'admin' ? Icons.admin_panel_settings : Icons.person,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            color: ColorsScheme.primaryTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              email,
                              style: TextStyle(
                                color: ColorsScheme.secondaryTextColor,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Text(
                              'Role: ${role.toUpperCase()}',
                              style: TextStyle(
                                color: role == 'admin' ? Colors.orange : ColorsScheme.primaryIconColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        trailing: SizedBox(
                          width: 120,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isVerified)
                                Icon(
                                  Icons.verified,
                                  color: Colors.green,
                                  size: 16,
                                ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: TextButton(
                                  onPressed: () => _showRoleChangeDialog(email, role),
                                  child: Text(
                                    role == 'admin' ? 'Remove' : 'Make Admin',
                                    style: TextStyle(
                                      color: ColorsScheme.primaryIconColor,
                                      fontSize: 10,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadUsers,
        backgroundColor: ColorsScheme.primaryIconColor,
        child: Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}