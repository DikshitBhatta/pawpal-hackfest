import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet_care/ColorsScheme.dart';
import 'package:pet_care/DataBase.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountSettingsPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const AccountSettingsPage({Key? key, required this.userData}) : super(key: key);

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  late TextEditingController nameController;
  late TextEditingController cityController;
  late TextEditingController dobController;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.userData['Name'] ?? '');
    cityController = TextEditingController(text: widget.userData['City'] ?? '');
    dobController = TextEditingController(text: widget.userData['DOB'] ?? '');
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                final email = user?.email;
                final currentPassword = currentPasswordController.text.trim();
                final newPassword = newPasswordController.text.trim();
                final confirmPassword = confirmPasswordController.text.trim();
                if (newPassword != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New passwords do not match.')));
                  return;
                }
                if (user != null && email != null && currentPassword.isNotEmpty && newPassword.isNotEmpty) {
                  try {
                    final cred = EmailAuthProvider.credential(email: email, password: currentPassword);
                    await user.reauthenticateWithCredential(cred);
                    await user.updatePassword(newPassword);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully.')));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
                  }
                }
              },
              child: const Text('Change',style: TextStyle(color: Colors.white),),
              style: ElevatedButton.styleFrom(backgroundColor: buttonColor),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
  nameController.dispose();
  cityController.dispose();
  dobController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
      });
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context, false)),
          ElevatedButton(child: const Text('Delete',style: TextStyle(color: Colors.white),), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Delete user data from Firestore
          await DataBase.deleteUserData('UserData', user.email);
          // Optionally: delete user-related collections (pets, subscriptions, orders)
          await DataBase.deleteCollection(user.email);
          await DataBase.deleteCollection('subscriptions'); // If you want to delete all user subscriptions, filter by userId/email
          await DataBase.deleteCollection('orders'); // If you want to delete all user orders, filter by userId/email
          // Delete FirebaseAuth user
          await user.delete();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deleted successfully.')));
          Navigator.of(context).pop(); // Go back after deletion
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting account: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
              backgroundImage: _profileImage != null
                ? FileImage(_profileImage!)
                : (widget.userData['Pic'] != null && widget.userData['Pic'].toString().isNotEmpty)
                  ? (widget.userData['Pic'].toString().startsWith('http')
                    ? NetworkImage(widget.userData['Pic']) as ImageProvider
                    : AssetImage(widget.userData['Pic']))
                  : const AssetImage('assets/profile_placeholder.png'),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: buttonColor,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.edit, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.userData['Name'] ?? '',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.person, color: buttonColor),
                title: const Text('Edit Profile'),
                subtitle: const Text('Name, City, Date of Birth'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                onTap: () => _showEditProfileDialog(context),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.grey[100],
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.lock, color: buttonColor),
                title: const Text('Change Password'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                onTap: _showChangePasswordDialog,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.grey[100],
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Account'),
                onTap: _deleteAccount,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.grey[100],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_city),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dobController,
                  readOnly: true,
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      dobController.text = "${picked.day}/${picked.month}/${picked.year}";
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    prefixIcon: Icon(Icons.cake),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final updatedData = {
                    'Name': nameController.text,
                    'City': cityController.text,
                    'DOB': dobController.text,
                  };
                  final success = await DataBase.updateUserData('UserData', user.email, updatedData);
                  if (success) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully.')));
                    setState(() {
                      widget.userData['Name'] = nameController.text;
                      widget.userData['City'] = cityController.text;
                      widget.userData['DOB'] = dobController.text;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update profile.')));
                  }
                }
              },
              child: const Text('Save',style: TextStyle(color: Colors.white),),
              style: ElevatedButton.styleFrom(backgroundColor: buttonColor),
            ),
          ],
        );
      },
    );
  }
}
