import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pet_care/firestore_service.dart';

class IOSAuthDebugScreen extends StatefulWidget {
  @override
  _IOSAuthDebugScreenState createState() => _IOSAuthDebugScreenState();
}

class _IOSAuthDebugScreenState extends State<IOSAuthDebugScreen> {
  String authStatus = "Checking...";
  String userInfo = "Loading...";
  String firestoreTest = "Testing...";
  
  @override
  void initState() {
    super.initState();
    _runDebugTests();
  }
  
  Future<void> _runDebugTests() async {
    // Test 1: Check Firebase Auth status
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      if (user != null) {
        authStatus = "✅ User authenticated: ${user.email}\n"
                   "UID: ${user.uid}\n"
                   "Email Verified: ${user.emailVerified}\n"
                   "Provider: ${user.providerData.map((p) => p.providerId).join(', ')}";
      } else {
        authStatus = "❌ No authenticated user";
      }
    });
    
    // Test 2: Get detailed user info
    if (user != null) {
      try {
        IdTokenResult tokenResult = await user.getIdTokenResult();
        setState(() {
          userInfo = "✅ Token Info:\n"
                   "Auth Time: ${tokenResult.authTime}\n"
                   "Issued At: ${tokenResult.issuedAtTime}\n"
                   "Expiration: ${tokenResult.expirationTime}\n"
                   "Sign In Provider: ${tokenResult.signInProvider}\n"
                   "Claims: ${tokenResult.claims}";
        });
      } catch (e) {
        setState(() {
          userInfo = "❌ Error getting token: $e";
        });
      }
    }
    
    // Test 3: Test Firestore access
    if (user != null) {
      try {
        // Test reading user's own document
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('UserData')
            .doc(user.email)
            .get();
        
        String userRole = "unknown";
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          userRole = userData['role'] ?? 'no role field';
        }
        
        // Test reading orders collection (should fail if permissions are wrong)
        QuerySnapshot ordersQuery = await FirebaseFirestore.instance
            .collection('orders')
            .limit(1)
            .get();
        
        setState(() {
          firestoreTest = "✅ Firestore Access:\n"
                       "User Document: ${userDoc.exists ? 'Found' : 'Not Found'}\n"
                       "User Role: $userRole\n"
                       "Orders Query: ${ordersQuery.docs.length} results\n"
                       "Can access orders: ✅";
        });
      } catch (e) {
        setState(() {
          firestoreTest = "❌ Firestore Error: $e";
        });
      }
    } else {
      setState(() {
        firestoreTest = "❌ Cannot test Firestore - no user";
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('iOS Auth Debug'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Firebase Auth Status:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(authStatus),
            SizedBox(height: 24),
            
            Text(
              'User Token Info:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(userInfo),
            SizedBox(height: 24),
            
            Text(
              'Firestore Access Test:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(firestoreTest),
            SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _runDebugTests,
              child: Text('Refresh Tests'),
            ),
            
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pop(context);
              },
              child: Text('Sign Out'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
