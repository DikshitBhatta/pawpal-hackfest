import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:pet_care/CredentialsScreen/ForgotPassword.dart';
import 'package:pet_care/CredentialsScreen/SignUpPage.dart';
import 'package:pet_care/SplashScreen.dart';
import 'package:pet_care/CredentialsScreen/phoneAuthentication.dart';
import 'package:pet_care/firebase_options.dart';
import 'package:pet_care/services/notification_service.dart';
import 'package:pet_care/services/subscription_automation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize AwesomeNotifications (for local in-app notifications)
  await AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: "vitapaw_local",
        channelName: "Vitapaw Local",
        channelDescription: "Local notification channel for Vitapaw",
        defaultColor: Color(0xFF9D50DD),
        ledColor: Colors.white,
        importance: NotificationImportance.High,
        channelShowBadge: true,
      ),
    ],
    debug: true,
  );
  
  print("Firebase and AwesomeNotifications initialized");
  
  // Start the subscription automation service
  SubscriptionAutomationService.startAutomationService();
  print("Subscription automation service started");
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Global navigation key for notifications
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // Initialize NotificationService with navigation key
    NotificationService.initialize(navigatorKey);
    
    Map<String, dynamic> userData = {
      "Name": "Jerry",
      "Email": "fuzailraza161@gmail.com",
      "isVerified": false,
      // "PhoneNo": "+923014384681",
      "Pic": "assets/images/petPic.png"
    };
    return MaterialApp(
      navigatorKey: navigatorKey, // Add navigation key
      debugShowCheckedModeBanner: false,
      title: 'Pet Care',
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.black38,
            // background: Color.fromRGBO(10, 101, 10, 0.2),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: Colors.greenAccent),
            ),
            prefixStyle: const TextStyle(color: Colors.black),
            labelStyle: const TextStyle(color: Colors.black),
          ),
          textTheme: TextTheme(
              displayLarge: TextStyle(
            decorationStyle: TextDecorationStyle.solid,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          )),
          useMaterial3: true,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.teal,
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Colors.blue,
          ),
          dividerTheme: DividerThemeData(
              color: Colors.grey.shade500,
              thickness: BorderSide.strokeAlignOutside,
              space: CircularProgressIndicator.strokeAlignCenter,
              indent: 10,
              endIndent: 30)),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        'Forgot Screen': (context) => ResetPassword(),
        // 'PhoneAuthenticate': (context) => PhoneAuthentication(
        //       userData: userData,
        //     ),
        'Signup Page': (context) => SignUpForm(),
      },
      // home: const checkFiles(),
    );
  }
}
