import 'package:flutter/material.dart';
import 'package:pet_care/ColorsScheme.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:lottie/lottie.dart' as lottie;
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pet_care/services/notification_service.dart';
import 'package:pet_care/widgets/pet_background_pattern.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io';
import 'dart:convert';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> subscriptionData;
  
  const PaymentScreen({super.key, required this.subscriptionData});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool showSpinner = false;
  bool showQRCode = true; // Show QR code by default since QR is the default payment method
  String paymentMethod = 'qr'; // Default to QR since stripe is removed
  File? paymentScreenshot; // For QR payment screenshot
  bool screenshotUploaded = false;
  String resolvedAddress = ''; // For reverse geocoded address
  bool isLoadingAddress = false;
  
  // QR Payment data
  String qrCode = '';
  String transactionId = '';
  
  // Delivery location controllers
  TextEditingController deliveryAddressController = TextEditingController();
  TextEditingController deliveryCityController = TextEditingController();
  TextEditingController deliveryPostalCodeController = TextEditingController();
  bool isEditingDelivery = false;
  
  @override
  void initState() {
    super.initState();
    generatePaymentData();
    _initializeDeliveryLocation();
    _loadAddressFromCoordinates(); // Load reverse geocoded address
  }

  void _initializeDeliveryLocation() {
    // Pre-fill delivery location with pet's location from addPetFormDark
    if (widget.subscriptionData['LAT'] != null && widget.subscriptionData['LONG'] != null) {
      // Create a readable address format from coordinates
      double lat = widget.subscriptionData['LAT'];
      double lng = widget.subscriptionData['LONG'];
      String coordinateAddress = "Pet Location: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}";
      deliveryAddressController.text = widget.subscriptionData['deliveryAddress'] ?? coordinateAddress;
      
      // If no city/postal provided, prompt user to fill
      if (widget.subscriptionData['deliveryCity'] == null) {
        deliveryCityController.text = '';
      } else {
        deliveryCityController.text = widget.subscriptionData['deliveryCity'];
      }
      
      if (widget.subscriptionData['deliveryPostalCode'] == null) {
        deliveryPostalCodeController.text = '';
      } else {
        deliveryPostalCodeController.text = widget.subscriptionData['deliveryPostalCode'];
      }
    } else {
      deliveryAddressController.text = widget.subscriptionData['deliveryAddress'] ?? '';
      deliveryCityController.text = widget.subscriptionData['deliveryCity'] ?? '';
      deliveryPostalCodeController.text = widget.subscriptionData['deliveryPostalCode'] ?? '';
    }
  }

  // Load address from coordinates using reverse geocoding
  Future<void> _loadAddressFromCoordinates() async {
    if (widget.subscriptionData['LAT'] != null && widget.subscriptionData['LONG'] != null) {
      setState(() {
        isLoadingAddress = true;
      });
      
      try {
        double lat = widget.subscriptionData['LAT'];
        double lng = widget.subscriptionData['LONG'];
        
        List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
        
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String fullAddress = '';
          
          // Build a readable address
          if (place.street != null && place.street!.isNotEmpty) {
            fullAddress += place.street!;
          }
          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            if (fullAddress.isNotEmpty) fullAddress += ', ';
            fullAddress += place.subLocality!;
          }
          if (place.locality != null && place.locality!.isNotEmpty) {
            if (fullAddress.isNotEmpty) fullAddress += ', ';
            fullAddress += place.locality!;
          }
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
            if (fullAddress.isNotEmpty) fullAddress += ', ';
            fullAddress += place.administrativeArea!;
          }
          if (place.country != null && place.country!.isNotEmpty) {
            if (fullAddress.isNotEmpty) fullAddress += ', ';
            fullAddress += place.country!;
          }
          
          setState(() {
            resolvedAddress = fullAddress.isNotEmpty ? fullAddress : 'Address not found';
            // Update the address field if it's empty or has coordinates
            if (deliveryAddressController.text.isEmpty || 
                deliveryAddressController.text.contains('Pet Location:')) {
              deliveryAddressController.text = resolvedAddress;
            }
            // Update city and postal code
            if (deliveryCityController.text.isEmpty && place.locality != null) {
              deliveryCityController.text = place.locality!;
            }
            if (deliveryPostalCodeController.text.isEmpty && place.postalCode != null) {
              deliveryPostalCodeController.text = place.postalCode!;
            }
            isLoadingAddress = false;
          });
        }
      } catch (e) {
        print('Error in reverse geocoding: $e');
        setState(() {
          resolvedAddress = 'Unable to resolve address';
          isLoadingAddress = false;
        });
      }
    }
  }

  // Open Google Maps location picker
  Future<void> _openLocationPicker() async {
    double? lat = widget.subscriptionData['LAT']?.toDouble();
    double? lng = widget.subscriptionData['LONG']?.toDouble();
    
    // Default to Bangkok if no coordinates
    LatLng initialPosition = LatLng(lat ?? 13.7563, lng ?? 100.5018);
    
    try {
      LatLng? selectedLocation = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LocationPickerScreen(
            initialPosition: initialPosition,
            currentAddress: deliveryAddressController.text,
          ),
        ),
      );
      
      if (selectedLocation != null) {
        // Update coordinates in subscription data
        widget.subscriptionData['LAT'] = selectedLocation.latitude;
        widget.subscriptionData['LONG'] = selectedLocation.longitude;
        
        // Reverse geocode the new location
        try {
          setState(() {
            isLoadingAddress = true;
          });
          
          List<Placemark> placemarks = await placemarkFromCoordinates(
            selectedLocation.latitude, 
            selectedLocation.longitude
          );
          
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            String fullAddress = '';
            
            // Build address
            if (place.street != null && place.street!.isNotEmpty) {
              fullAddress += place.street!;
            }
            if (place.subLocality != null && place.subLocality!.isNotEmpty) {
              if (fullAddress.isNotEmpty) fullAddress += ', ';
              fullAddress += place.subLocality!;
            }
            if (place.locality != null && place.locality!.isNotEmpty) {
              if (fullAddress.isNotEmpty) fullAddress += ', ';
              fullAddress += place.locality!;
            }
            if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
              if (fullAddress.isNotEmpty) fullAddress += ', ';
              fullAddress += place.administrativeArea!;
            }
            
            setState(() {
              deliveryAddressController.text = fullAddress;
              if (place.locality != null) {
                deliveryCityController.text = place.locality!;
              }
              if (place.postalCode != null) {
                deliveryPostalCodeController.text = place.postalCode!;
              }
              resolvedAddress = fullAddress;
              isLoadingAddress = false;
            });
          }
        } catch (e) {
          print('Error updating address: $e');
          setState(() {
            isLoadingAddress = false;
          });
        }
      }
    } catch (e) {
      print('Error opening location picker: $e');
      // Show error message
      showErrorMessage('Unable to open location picker. Please edit address manually.');
    }
  }

  @override
  void dispose() {
    deliveryAddressController.dispose();
    deliveryCityController.dispose();
    deliveryPostalCodeController.dispose();
    super.dispose();
  }

  void generatePaymentData() {
    // Generate QR code data (simulated)
    transactionId = 'PET${DateTime.now().millisecondsSinceEpoch}';
    String mealPlan = widget.subscriptionData['selectedMealPlan']?.toString() ?? 'default';
    qrCode = 'petcare://pay?amount=${getTotalAmount()}&id=$transactionId&meal=$mealPlan';
  }

  double getTotalAmount() {
    // Base subscription price already includes all meal costs
    double basePrice = widget.subscriptionData['monthlyPrice'] ?? 0.0;
    return basePrice;
  }

  Future<void> processPayment() async {
    // Validate delivery address
    if (deliveryAddressController.text.trim().isEmpty) {
      showErrorMessage('📍 Please add a delivery address before proceeding with payment! 🏠');
      return;
    }
    
    if (paymentMethod == 'qr' && !screenshotUploaded) {
      showErrorMessage('📸 Please upload a payment screenshot first! We need to see your payment proof! 🔍');
      return;
    }

    setState(() {
      showSpinner = true;
    });

    try {

      // Simulate payment processing
      await Future.delayed(Duration(seconds: 2));

      // Convert screenshot to base64 if available
      String? screenshotBase64;
      if (paymentScreenshot != null) {
        final bytes = await paymentScreenshot!.readAsBytes();
        screenshotBase64 = "data:image/png;base64,${base64Encode(bytes)}";
      }

      // Create unique subscription ID
      String subscriptionId = 'SUB_${DateTime.now().millisecondsSinceEpoch}_${widget.subscriptionData['Email'].hashCode.abs()}';

      // Get the selected meal plan details from the recommendation screen
      Map<String, dynamic> selectedMealPlanDetails = {};
      String mealPlanName = '';
      
      if (widget.subscriptionData['selectedMealPlan'] is String) {
        mealPlanName = widget.subscriptionData['selectedMealPlan'];
        // Create a basic meal plan structure if only name is provided
        selectedMealPlanDetails = {
          'name': mealPlanName,
          'description': 'Custom AI-generated meal plan for ${widget.subscriptionData['Name']}',
          'image': '🍗',
          'price': widget.subscriptionData['mealPrice'] ?? 0.0,
          'calories': 350, // Default calories
        };
      } else if (widget.subscriptionData['selectedMealPlan'] is Map) {
        selectedMealPlanDetails = Map<String, dynamic>.from(widget.subscriptionData['selectedMealPlan']);
        mealPlanName = _cleanMealName(selectedMealPlanDetails['name'] ?? 'Custom Meal Plan');
      }

      // 🔥 Store the full AI-generated meal in the 'meals' collection
      var db = FirebaseFirestore.instance;
      Map<String, dynamic> mealData = {
        ...selectedMealPlanDetails,
        'createdAt': DateTime.now().toIso8601String(),
        'userId': widget.subscriptionData['userEmail'] ?? FirebaseAuth.instance.currentUser?.email,
        'petId': widget.subscriptionData['Email'],
        'petName': widget.subscriptionData['Name'],
        'subscriptionId': subscriptionId,
        'status': 'pending',
      };
      DocumentReference mealRef = await db.collection('meals').add(mealData);

      // Save subscription to new 'subscriptions' collection with pending status
      Map<String, dynamic> subscriptionRecord = {
        'subscriptionId': subscriptionId,
        'userId': widget.subscriptionData['userEmail'] ?? FirebaseAuth.instance.currentUser?.email,
        'petId': widget.subscriptionData['Email'], // Pet's unique ID
        'petName': widget.subscriptionData['Name'],
        'dogName': widget.subscriptionData['Name'], // Add dog name for easy access
        'mealPlan': mealPlanName, // Store meal plan name for backward compatibility
        'selectedMealPlan': selectedMealPlanDetails, // Store full meal plan details
        'frequency': widget.subscriptionData['frequency'],
        'dogSize': widget.subscriptionData['dogSize'],
        'paymentScreenshotUrl': screenshotBase64,
        'status': 'pending', // Start with pending status
        'mealPlanStatus': 'pending', // Track meal plan approval separately
        'createdAt': DateTime.now().toIso8601String(),
        'monthlyPrice': widget.subscriptionData['monthlyPrice'],
        'totalAmount': getTotalAmount(),
        'paymentMethod': paymentMethod,
        'transactionId': transactionId,
        // Include health data for meal customization
        'healthGoals': widget.subscriptionData['healthGoals'] ?? [],
        'foodAllergies': widget.subscriptionData['foodAllergies'] ?? [],
        'favoriteFoods': widget.subscriptionData['favoriteFoods'] ?? [],
        'activityLevel': widget.subscriptionData['activityLevel'] ?? '',
        'weight': widget.subscriptionData['weight'] ?? '',
        'weightUnit': widget.subscriptionData['weightUnit'] ?? 'kg',
        // Store comprehensive meal plan information for admin review
        'mealPlanDetails': _buildEnhancedMealPlanForAdmin(selectedMealPlanDetails),
        // Store pet location data for delivery
        'deliveryLocation': {
          'address': deliveryAddressController.text.trim(),
          'city': deliveryCityController.text.trim(),
          'postalCode': deliveryPostalCodeController.text.trim(),
          'latitude': widget.subscriptionData['LAT'] ?? 0.0,
          'longitude': widget.subscriptionData['LONG'] ?? 0.0,
          'coordinates': widget.subscriptionData['LAT'] != null && widget.subscriptionData['LONG'] != null 
              ? "Lat: ${widget.subscriptionData['LAT']}, Long: ${widget.subscriptionData['LONG']}"
              : '',
        },
        // 🔥 Link the meal document
        'mealId': mealRef.id,
      };

      // Save to 'subscriptions' collection
      // var db = FirebaseFirestore.instance;
      await db.collection('subscriptions').doc(subscriptionId).set(subscriptionRecord);

      // Update user's subscription status to pending
      String userEmail = widget.subscriptionData['userEmail'] ?? FirebaseAuth.instance.currentUser?.email ?? '';
      if (userEmail.isNotEmpty) {
        await db.collection('UserData').doc(userEmail).update({
          'subscriptionStatus': 'pending',
          'subscriptionDetails': {
            'subscriptionId': subscriptionId,
            'mealPlan': mealPlanName,
            'mealPlanDetails': _buildEnhancedMealPlanForAdmin(selectedMealPlanDetails),
            'frequency': widget.subscriptionData['frequency'],
            'dogSize': widget.subscriptionData['dogSize'],
            'paymentScreenshotUrl': screenshotBase64,
            'petName': widget.subscriptionData['Name'],
            'petId': widget.subscriptionData['Email'],
            'dogName': widget.subscriptionData['Name'], // Add dog name for location lookup
            'monthlyPrice': widget.subscriptionData['monthlyPrice'],
            'baseMealCost': widget.subscriptionData['baseMealCost'],
            'actualMealPrice': widget.subscriptionData['actualMealPrice'],
            'mealsPerMonth': widget.subscriptionData['mealsPerMonth'],
          }
        });
      }
      
      // 🔔 NOTIFICATION TRIGGER: Notify admin of new subscription request
      try {
        await NotificationService.notifyAdminOfSubscriptionRequest(
          userName: widget.subscriptionData['Name'] ?? 'Pet Owner',
          userEmail: userEmail,
          subscriptionType: '${widget.subscriptionData['dogSize']} - ${widget.subscriptionData['frequency']}',
          amount: getTotalAmount().toStringAsFixed(2),
        );
        print('✅ Admin notification sent for subscription request');
        print('📍 Delivery Address: ${deliveryAddressController.text}');
        print('🏙️ Delivery City: ${deliveryCityController.text}');
        print('📮 Postal Code: ${deliveryPostalCodeController.text}');
      } catch (e) {
        print('⚠️ Failed to send admin notification: $e');
        // Don't fail the payment process if notification fails
      }
      
      setState(() {
        showSpinner = false;
      });

      showPendingDialog();
    } catch (e) {
      setState(() {
        showSpinner = false;
      });
      showErrorMessage('Payment processing failed: $e');
    }
  }

  Future<void> pickPaymentScreenshot() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          paymentScreenshot = File(image.path);
          screenshotUploaded = true;
        });
        
        final snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: '✅ Done! 🐾',
            message: '📷 Perfect! Your payment proof is uploaded! 🌟',
            contentType: ContentType.success,
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      showErrorMessage('Failed to upload screenshot: $e');
    }
  }

  void showPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.pending_actions, color: Colors.orange, size: 25),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '✅ Done! 🐾 Thank you!',
                   style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🔄 Your subscription request for ${widget.subscriptionData['Name'] ?? 'your pet'} has been submitted for approval.'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Next Steps:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('• Admin will review your payment proof'),
                    Text('• You\'ll receive notification once approved'),
                    Text('• Check subscription status in your profile'),
                    Text('• Delivery will start after approval'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                
                // Navigate back to home safely
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text('Got it!'),
            ),
          ],
        );
      },
    );
  }

  void showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 25),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Subscription Active!',
                   style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                  
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🎉 Congratulations! Your meal subscription for ${widget.subscriptionData['Name']} is now active.'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Subscription Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('• Plan: ${widget.subscriptionData['dogSize']} Dog'),
                    Text('• Frequency: ${widget.subscriptionData['frequency']}'),
                    Text('• Meal: ${widget.subscriptionData['selectedMealPlan']}'),
                    Text('• Monthly Total: ฿${getTotalAmount().toStringAsFixed(2)}'),
                    Text('• Next Delivery: ${DateTime.now().add(Duration(days: 7)).toString().split(' ')[0]}'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                
                // Navigate back to home safely
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text('Great!'),
            ),
          ],
        );
      },
    );
  }

  void showErrorMessage(String message) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: '😔 Oops! Something went wrong!',
        message: message,
        contentType: ContentType.failure,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget buildQRCode() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Scan QR Code to Pay',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 20),
          
          // QR Code placeholder (in a real app, use qr_flutter package)
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code,
                  size: 80,
                  color: Colors.grey.shade600,
                ),
                SizedBox(height: 8),
                Text(
                  'QR Payment Code',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20),
          
          Text(
            'Amount: ฿${getTotalAmount().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          
          SizedBox(height: 8),
          
          Text(
            'Transaction ID: $transactionId',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontFamily: 'monospace',
            ),
          ),
          
          SizedBox(height: 20),
          
          // Payment Screenshot Upload Section
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: screenshotUploaded ? Colors.green.shade50 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: screenshotUploaded ? Colors.green.shade300 : Colors.blue.shade300,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  screenshotUploaded ? Icons.check_circle : Icons.upload_file,
                  color: screenshotUploaded ? Colors.green.shade600 : Colors.blue.shade600,
                  size: 32,
                ),
                SizedBox(height: 8),
                Text(
                  screenshotUploaded ? 'Payment Screenshot Uploaded' : 'Upload Payment Screenshot',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: screenshotUploaded ? Colors.green.shade700 : Colors.blue.shade700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  screenshotUploaded 
                    ? 'Screenshot ready for admin review'
                    : 'Please upload proof of payment',
                  style: TextStyle(
                    fontSize: 12,
                    color: screenshotUploaded ? Colors.green.shade600 : Colors.blue.shade600,
                  ),
                ),
                if (!screenshotUploaded) ...[
                  SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: pickPaymentScreenshot,
                    icon: Icon(Icons.photo_library),
                    label: Text('Choose Screenshot'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // Confirm Payment Button - only show if screenshot is uploaded
          if (screenshotUploaded)
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Submit for Approval',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Complete Payment",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: listTileColorSecond,
          ),
        ),
      ),
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: Stack(
          children: [
            Positioned.fill(
              child: PetBackgroundPattern(
                opacity: 0.8,
                symbolSize: 80.0,
                density: 0.3,
              ),
            ),
            Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.grey.shade50, Colors.grey.shade200],
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order summary
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '📋',
                              style: TextStyle(fontSize: 24),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Order Summary',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 20),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Pet:', style: TextStyle(fontWeight: FontWeight.w500)),
                            Expanded(
                              child: Text(
                                '${widget.subscriptionData['Name']} (${widget.subscriptionData['dogSize']})',
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Meal Plan:', style: TextStyle(fontWeight: FontWeight.w500)),
                            Expanded(
                              child: Text(
                                widget.subscriptionData['selectedMealPlan'] is String 
                                  ? widget.subscriptionData['selectedMealPlan']
                                  : (widget.subscriptionData['selectedMealPlan'] is Map 
                                      ? widget.subscriptionData['selectedMealPlan']['name'] ?? 'Custom Plan'
                                      : 'Custom Plan'),
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        
                        // Show meal plan details if available
                        if (widget.subscriptionData['selectedMealPlan'] is Map && 
                            widget.subscriptionData['selectedMealPlan']['description'] != null)
                          Container(
                            padding: EdgeInsets.all(12),
                            margin: EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      widget.subscriptionData['selectedMealPlan']['image'] ?? '🍗',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Meal Plan Details',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  widget.subscriptionData['selectedMealPlan']['description'] ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                                if (widget.subscriptionData['selectedMealPlan']['calories'] != null)
                                  Text(
                                    '${widget.subscriptionData['selectedMealPlan']['calories']} calories per serving',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue.shade500,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Frequency:', style: TextStyle(fontWeight: FontWeight.w500)),
                            Expanded(
                              child: Text(
                                '${widget.subscriptionData['frequency']}',
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Base Subscription:', style: TextStyle(fontWeight: FontWeight.w500)),
                            Expanded(
                              child: Text(
                                '฿${widget.subscriptionData['monthlyPrice'].toStringAsFixed(2)}/month',
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        
                        Divider(thickness: 2, height: 30),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Total Monthly:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '\฿${getTotalAmount().toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30),

                  // Delivery location section
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '📦',
                                  style: TextStyle(fontSize: 24),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Delivery Location',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                // Single button that opens location picker
                                if (widget.subscriptionData['LAT'] != null && widget.subscriptionData['LONG'] != null)
                                  TextButton.icon(
                                    onPressed: _openLocationPicker,
                                    icon: Icon(
                                      Icons.edit_location_alt,
                                      size: 18,
                                      color: Colors.blue.shade600,
                                    ),
                                    label: Text(
                                      'Edit',
                                      style: TextStyle(
                                        color: Colors.blue.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  )
                                else
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        isEditingDelivery = !isEditingDelivery;
                                      });
                                    },
                                    icon: Icon(
                                      isEditingDelivery ? Icons.save : Icons.edit,
                                      size: 18,
                                      color: Colors.blue.shade600,
                                    ),
                                    label: Text(
                                      isEditingDelivery ? 'Save' : 'Edit',
                                      style: TextStyle(
                                        color: Colors.blue.shade600,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Pet location info with resolved address
                        if (widget.subscriptionData['LAT'] != null && widget.subscriptionData['LONG'] != null)
                          Container(
                            padding: EdgeInsets.all(12),
                            margin: EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.pets, color: Colors.blue.shade600, size: 20),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${widget.subscriptionData['Name']}\'s registered location',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    if (isLoadingAddress)
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: lottie.Lottie.asset(
                                          'assets/Animations/AnimalcareLoading.json',
                                          width: 24,
                                          height: 24,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                // Show resolved address if available
                                if (resolvedAddress.isNotEmpty && !isLoadingAddress)
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    margin: EdgeInsets.only(top: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.green.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.location_on, color: Colors.green.shade600, size: 16),
                                        SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            resolvedAddress,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                SizedBox(height: 4),
                                Text(
                                  'Coordinates: ${widget.subscriptionData['LAT']?.toStringAsFixed(6)}, ${widget.subscriptionData['LONG']?.toStringAsFixed(6)}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        // Address fields
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delivery Address:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            SizedBox(height: 8),
                            
                            isEditingDelivery
                                ? Column(
                                    children: [
                                      TextFormField(
                                        controller: deliveryAddressController,
                                        decoration: InputDecoration(
                                          hintText: 'Enter full address',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                        maxLines: 2,
                                      ),
                                      SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              controller: deliveryCityController,
                                              decoration: InputDecoration(
                                                hintText: 'City',
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                contentPadding: EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: TextFormField(
                                              controller: deliveryPostalCodeController,
                                              decoration: InputDecoration(
                                                hintText: 'Postal Code',
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                contentPadding: EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                              ),
                                              keyboardType: TextInputType.number,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                : Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          deliveryAddressController.text.isNotEmpty
                                              ? deliveryAddressController.text
                                              : 'No address provided - please add delivery address',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: deliveryAddressController.text.isNotEmpty 
                                                ? Colors.grey.shade800
                                                : Colors.red.shade600,
                                            fontWeight: deliveryAddressController.text.isNotEmpty 
                                                ? FontWeight.normal
                                                : FontWeight.w500,
                                          ),
                                        ),
                                        if (deliveryCityController.text.isNotEmpty || 
                                            deliveryPostalCodeController.text.isNotEmpty)
                                          SizedBox(height: 4),
                                        if (deliveryCityController.text.isNotEmpty || 
                                            deliveryPostalCodeController.text.isNotEmpty)
                                          Text(
                                            '${deliveryCityController.text}${deliveryCityController.text.isNotEmpty && deliveryPostalCodeController.text.isNotEmpty ? ', ' : ''}${deliveryPostalCodeController.text}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                          ],
                        ),
                        
                        SizedBox(height: 12),
                        
                        // Warning if no address
                        if (deliveryAddressController.text.trim().isEmpty)
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber, color: Colors.orange.shade600, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Please add a delivery address for meal delivery',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30),

                  // Payment method selection
                  Text(
                    '💳 Choose Payment Method',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  
                  SizedBox(height: 15),

                  // Payment options
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title: Row(
                            children: [
                              Icon(Icons.qr_code, color: Colors.blue.shade600),
                              SizedBox(width: 8),
                              Text('QR Code Payment'),
                            ],
                          ),
                          subtitle: Text('Scan to pay with mobile wallet'),
                          value: 'qr',
                          groupValue: paymentMethod,
                          onChanged: (value) {
                            setState(() {
                              paymentMethod = value!;
                              showQRCode = true;
                            });
                          },
                        ),
                        Divider(height: 1),
                        RadioListTile<String>(
                          title: Row(
                            children: [
                              Icon(Icons.payment, color: Colors.green.shade600),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Line Pay',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text('Pay through Line application'),
                          value: 'line',
                          groupValue: paymentMethod,
                          onChanged: (value) {
                            setState(() {
                              paymentMethod = value!;
                              showQRCode = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30),

                  // QR Code display
                  if (showQRCode && paymentMethod == 'qr')
                    buildQRCode(),

                  SizedBox(height: 30),

                  // Payment button
                  if (!showQRCode || paymentMethod != 'qr')
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: processPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              paymentMethod == 'line' ? Icons.payment : Icons.payment,
                              color: Colors.white,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                paymentMethod == 'line' ? 'Pay with Line' : 'Complete Payment',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  SizedBox(height: 20),

                  // Security note
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.security, color: Colors.blue.shade600, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your payment is secured with 256-bit SSL encryption. You can cancel your subscription anytime.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
          ],
        ),
      ),
    );
  }

  /// Build enhanced meal plan data for admin with comprehensive details
  Map<String, dynamic> _buildEnhancedMealPlanForAdmin(Map<String, dynamic> selectedMealPlanDetails) {
    // Get AI meal plan details if available
    Map<String, dynamic>? aiMealPlan = widget.subscriptionData['mealPlanDetails'];
    
    // Calculate meal pricing details
    double baseMealPrice = widget.subscriptionData['baseMealCost']?.toDouble() ?? 0.0;
    double actualMealPrice = widget.subscriptionData['actualMealPrice']?.toDouble() ?? baseMealPrice;
    double portionMultiplier = widget.subscriptionData['portionMultiplier']?.toDouble() ?? 1.0;
    double finalMealPrice = actualMealPrice * portionMultiplier;
    
    // Get frequency details
    String frequency = widget.subscriptionData['frequency'] ?? '';
    int mealsPerMonth = widget.subscriptionData['mealsPerMonth'] ?? 4;
    
    return {
      // Basic meal information
      'meal_name': _cleanMealName(aiMealPlan?['meal_name'] ?? selectedMealPlanDetails['name'] ?? 'Custom Meal Plan'),
      'name': _cleanMealName(selectedMealPlanDetails['name'] ?? 'Custom Meal Plan'), // For backward compatibility
      'description': aiMealPlan?['description'] ?? selectedMealPlanDetails['description'] ?? 'AI-generated personalized meal plan',
      'image': aiMealPlan?['image'] ?? selectedMealPlanDetails['image'] ?? '🍗',
      'calories': selectedMealPlanDetails['calories'] ?? 350,
      'rating': selectedMealPlanDetails['rating'] ?? 0.0,
      
      // Enhanced AI meal plan data (if available)
      'ingredients': aiMealPlan?['ingredients'] ?? selectedMealPlanDetails['ingredients'] ?? [],
      'supplements_vitamins_minerals': aiMealPlan?['supplements_vitamins_minerals'] ?? [],
      'snacks_treats_special_diet': aiMealPlan?['snacks_treats_special_diet'] ?? [],
      'preparation_instructions': aiMealPlan?['preparation_instructions'] ?? 'Standard meal preparation instructions will be provided by kitchen staff.',
      
      // Pricing breakdown for admin
      'pricing_details': {
        'base_meal_price': baseMealPrice,
        'actual_ai_meal_price': actualMealPrice,
        'dog_size': widget.subscriptionData['dogSize'],
        'portion_multiplier': portionMultiplier,
        'final_meal_price': finalMealPrice,
        'frequency': frequency,
        'meals_per_month': mealsPerMonth,
        'monthly_total': widget.subscriptionData['monthlyPrice']?.toDouble() ?? 0.0,
      },
      
      // Subscription plan details for admin
      'subscription_details': {
        'frequency': frequency,
        'dog_size': widget.subscriptionData['dogSize'],
        'selected_plan': '${widget.subscriptionData['dogSize']} Dog - $frequency Delivery',
        'portion_adjustment': '${(portionMultiplier * 100).toInt()}% of base portion',
        'meals_per_delivery': frequency.contains('1x') ? 1 : 2,
        'deliveries_per_month': mealsPerMonth ~/ (frequency.contains('1x') ? 1 : 2),
      },
      
      // Pet health information for meal customization
      'pet_health_profile': {
        'health_goals': widget.subscriptionData['healthGoals'] ?? [],
        'food_allergies': widget.subscriptionData['foodAllergies'] ?? [],
        'favorite_foods': widget.subscriptionData['favoriteFoods'] ?? [],
        'activity_level': widget.subscriptionData['activityLevel'] ?? '',
        'weight': '${widget.subscriptionData['weight'] ?? ''} ${widget.subscriptionData['weightUnit'] ?? 'kg'}',
        'breed': widget.subscriptionData['Breed'] ?? '',
        'age': widget.subscriptionData['Age'] ?? '',
      },
      
      // Legacy fields for backward compatibility
      'benefits': selectedMealPlanDetails['benefits'] ?? [],
      'price': finalMealPrice,
      'total_price': finalMealPrice,
      
      // Admin instruction summary
      'admin_summary': {
        'meal_type': aiMealPlan != null ? 'AI-Generated Custom Meal' : 'Standard Meal Plan',
        'kitchen_ready': aiMealPlan?['preparation_instructions'] != null,
        'ingredient_count': aiMealPlan?['ingredients']?.length ?? 0,
        'has_supplements': (aiMealPlan?['supplements_vitamins_minerals'] ?? []).isNotEmpty,
        'has_special_treats': (aiMealPlan?['snacks_treats_special_diet'] ?? []).isNotEmpty,
        'personalization_level': aiMealPlan != null ? 'High - AI Personalized' : 'Standard',
      },
    };
  }

  /// Clean meal name by removing pet name prefix
  String _cleanMealName(String originalName) {
    if (originalName.isEmpty) return 'Custom Meal Plan';
    
    String petName = widget.subscriptionData['Name'] ?? '';
    if (petName.isNotEmpty && originalName.contains(petName)) {
      // Remove pet's name prefix like "Newi's " or "Newi's "
      String cleaned = originalName.replaceFirst("$petName's ", '').replaceFirst("${petName}'s ", '');
      return cleaned.isNotEmpty ? cleaned : originalName;
    }
    
    return originalName;
  }
}

// Google Maps Location Picker Screen
class LocationPickerScreen extends StatefulWidget {
  final LatLng initialPosition;
  final String currentAddress;

  const LocationPickerScreen({
    super.key,
    required this.initialPosition,
    required this.currentAddress,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? mapController;
  LatLng selectedPosition = LatLng(0, 0);
  String selectedAddress = '';
  bool isLoadingAddress = false;
  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    selectedPosition = widget.initialPosition;
    selectedAddress = widget.currentAddress;
    _addMarker(selectedPosition);
  }

  void _addMarker(LatLng position) {
    setState(() {
      markers.clear();
      markers.add(
        Marker(
          markerId: MarkerId('selected_location'),
          position: position,
          draggable: true,
          onDragEnd: (LatLng newPosition) {
            selectedPosition = newPosition;
            _getAddressFromCoordinates(newPosition);
          },
          infoWindow: InfoWindow(
            title: 'Delivery Location',
            snippet: 'Drag to adjust position',
          ),
        ),
      );
    });
  }

  Future<void> _getAddressFromCoordinates(LatLng position) async {
    setState(() {
      isLoadingAddress = true;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '';

        if (place.street != null && place.street!.isNotEmpty) {
          address += place.street!;
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.subLocality!;
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.locality!;
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.administrativeArea!;
        }

        setState(() {
          selectedAddress = address.isNotEmpty ? address : 'Address not found';
          isLoadingAddress = false;
        });
      }
    } catch (e) {
      print('Error getting address: $e');
      setState(() {
        selectedAddress = 'Unable to get address';
        isLoadingAddress = false;
      });
    }
  }

  void _onMapTap(LatLng position) {
    selectedPosition = position;
    _addMarker(position);
    _getAddressFromCoordinates(position);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Delivery Location',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue.shade600,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, selectedPosition);
            },
            child: Text(
              'CONFIRM',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Address display
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Location:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.blue.shade600, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: isLoadingAddress
                            ? Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: lottie.Lottie.asset(
                                      'assets/Animations/AnimalcareLoading.json',
                                      width: 16,
                                      height: 16,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Loading address...'),
                                ],
                              )
                            : Text(
                                selectedAddress.isNotEmpty 
                                    ? selectedAddress 
                                    : 'Tap on map to select location',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Coordinates: ${selectedPosition.latitude.toStringAsFixed(6)}, ${selectedPosition.longitude.toStringAsFixed(6)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          // Google Map
          Expanded(
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: widget.initialPosition,
                zoom: 16.0,
              ),
              markers: markers,
              onTap: _onMapTap,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapType: MapType.normal,
              zoomControlsEnabled: true,
            ),
          ),
          
          // Instructions
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tap anywhere on the map or drag the marker to select your delivery location',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, selectedPosition);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Confirm Location',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
