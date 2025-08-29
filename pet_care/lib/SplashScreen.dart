import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pet_care/ColorsScheme.dart';
import 'package:pet_care/CredentialsScreen/LoginPage.dart';
import 'package:pet_care/DataBase.dart';
import 'package:pet_care/HomePage/HomeScreen.dart';
import 'package:pet_care/Admin/AdminDashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pet_care/widgets/pet_background_pattern.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  String _loadingText = "Starting up...";

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _checkAuthAndProceed();
  }

  Future<void> _checkAuthAndProceed() async {
    // Wait a bit for Firebase to initialize
    await Future.delayed(Duration(milliseconds: 1000));
    
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      await _goToLogin();
    } else {
      final pref = await SharedPreferences.getInstance();
      
      if (!pref.containsKey('userEmail') || pref.getString("userEmail") != user.email) {
        if (user.email != null) {
          await pref.setString('userEmail', user.email!);
        }
      }
      
      await isUserSaved();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _prefetchSubscriptions(String userId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .get();

      final list = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      // Sort by createdAt manually (as String)
      list.sort((a, b) {
        final dateA = (a['createdAt'] ?? '') as String;
        final dateB = (b['createdAt'] ?? '') as String;
        return dateB.compareTo(dateA); // Desc
      });

      return list;
    } catch (e) {
      debugPrint('Error fetching subscriptions: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _prefetchOrders(String userId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['on_way', 'on_mid_way'])
          .limit(1)
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _prefetchPets(String userEmail) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection(userEmail)
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      debugPrint('Error fetching pets: $e');
      return [];
    }
  }

  Future<void> isUserSaved() async {
    final pref = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    // Start progress animation once
    _progressController.forward(from: 0.0);

    String? userEmail = pref.getString("userEmail");
    
    if ((userEmail == null || userEmail.isEmpty) && user?.email != null) {
      userEmail = user!.email!;
      await pref.setString('userEmail', userEmail);
    }

    if (userEmail != null && userEmail.isNotEmpty) {
      setState(() {
        _loadingText = "Loading user data...";
      });

      try {
        final userData = await DataBase.readData("UserData", userEmail);
        
        final String userId = userData['uid'] ?? userData['Email'] ?? '';

        setState(() {
          _loadingText = "Loading pets and subscriptions...";
        });

        // Fetch concurrently
        final results = await Future.wait([
          _prefetchSubscriptions(userId),
          _prefetchOrders(userId),
          _prefetchPets(userEmail),
        ]);

        final subscriptions = results[0];
        final orders = results[1];
        final pets = results[2];

        setState(() {
          _loadingText = "Almost ready...";
        });

        // Wait for animation to complete
        if (mounted && _progressController.value < 1.0) {
          await _progressController.forward();
        }

        final String userRole = userData["role"] ?? "user";

        // Small delay to show 100% completion
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        if (userRole == "admin") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminDashboard()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => petScreenDynamicDark(
                userData: userData,
                prefetchedSubscriptions: subscriptions,
                prefetchedOrders: orders,
                prefetchedPets: pets,
              ),
            ),
          );
        }
      } catch (e) {
        // If there's an error loading user data, sign out and go to login
        await FirebaseAuth.instance.signOut();
        await pref.remove('userEmail');
        await _goToLogin();
      }
    } else {
      // No user email available, sign out and go to login
      await FirebaseAuth.instance.signOut();
      await _goToLogin();
    }
  }

  Future<void> _goToLogin() async {
    setState(() {
      _loadingText = "Redirecting to login...";
    });
    
    // Wait for animation to complete if it hasn't already
    if (mounted && _progressController.value < 1.0) {
      await _progressController.forward();
    }
    
    // Small delay to show 100% completion
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Login()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background pattern fills the screen
          const PetBackgroundPattern(
            opacity: 0.06,
            symbolSize: 16.0,
            density: 0.6,
            usePositioned: true, // Use internal Positioned.fill
          ),

          // Foreground content with your brand + progress
          Container(
            color: appBarColor,
            child: SafeArea(
              child: Column(
                children: [
                  // Main content
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Brand Image
                        Container(
                          height: 200,
                          width: 200,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/images/petPic.png'),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Brand Name
                        Center(
                          child: Text(
                            "Vitapaw",
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              color: Colors.blueGrey.shade200,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Progress + status
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Loading text
                        Text(
                          _loadingText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blueGrey.shade300,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Progress bar container
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: Colors.blueGrey.shade700.withOpacity(0.3),
                          ),
                          child: AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, child) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  height: 6,
                                  width: MediaQuery.of(context).size.width * _progressAnimation.value,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.teal.shade400,
                                        Colors.blue.shade400,
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Progress percentage
                        AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return Text(
                              "${(_progressAnimation.value * 100).toInt()}%",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blueGrey.shade400,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

