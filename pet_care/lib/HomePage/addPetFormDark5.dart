import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:pet_care/ColorsScheme.dart';
import 'package:pet_care/AIScreen/AIMealPlanScreen.dart';
import 'package:pet_care/widgets/step_progress_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pet_care/services/image_compression_service.dart';
import 'dart:io';
import 'package:pet_care/widgets/pet_background_pattern.dart';
import 'package:lottie/lottie.dart';

class addPetFormDark5 extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Map<String, dynamic> petData;
  
  const addPetFormDark5({super.key, required this.userData, required this.petData});

  @override
  State<addPetFormDark5> createState() => _addPetFormDark5State();
}

class _addPetFormDark5State extends State<addPetFormDark5> {
  void showAddingPetDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: Lottie.asset(
                  'assets/Animations/AnimalcareLoading.json',
                  repeat: true,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(width: 24),
              Text('Adding Pet...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
  bool showSpinner = false;
  
  // Activity level
  String selectedActivityLevel = '';
  
  // Daily activity minutes
  TextEditingController dailyActivityMinutesController = TextEditingController();
  
  // Poop status
  int selectedPoopStatusIndex = 2; // Default to Normal (index 2, level 3)
  
  // Additional poop details
  String selectedPoopColor = '';
  String selectedPoopFrequency = '';
  String selectedPoopQuantity = '';
  
  // Health notes
  TextEditingController healthNotesController = TextEditingController();

  // Medical file upload
  PlatformFile? pickedMedicalFile;
  bool isMedicalFileUploaded = false;

  final List<Map<String, dynamic>> activityLevels = [
    {
      'level': 'Low',
      'icon': '😴',
      'description': 'Prefers lounging and short walks',
      'color': Colors.blue.shade300,
    },
    {
      'level': 'Medium',
      'icon': '🚶',
      'description': 'Enjoys regular walks and play',
      'color': Colors.orange.shade300,
    },
    {
      'level': 'High',
      'icon': '🏃',
      'description': 'Very active, loves running and exercise',
      'color': Colors.red.shade300,
    },
  ];

  final List<Map<String, dynamic>> poopStatus = [
    {'level': 1, 'description': 'Very Hard', 'color': Colors.brown.shade800, 'emoji': '🪨'},
    {'level': 2, 'description': 'Hard', 'color': Colors.brown.shade600, 'emoji': '🪨'},
    {'level': 3, 'description': 'Normal', 'color': Colors.brown.shade400, 'emoji': '💩'},
    {'level': 4, 'description': 'Soft', 'color': Colors.brown.shade300, 'emoji': '💧'},
    {'level': 5, 'description': 'Very Soft', 'color': Colors.brown.shade200, 'emoji': '💧'},
  ];

  final List<String> poopColors = [
    'Brown',
    'Dark Brown',
    'Light Brown',
    'Black',
    'Green',
    'Yellow',
    'Red',
    'Gray',
  ];

  final List<String> poopFrequencies = [
    'Once a day',
    'Twice a day',
    '3 times a day',
    'Every other day',
    '3-4 times a week',
    'Once a week',
    'More than 3 times a day',
  ];

  final List<String> poopQuantities = [
    'Very Small',
    'Small',
    'Normal',
    'Large',
    'Very Large',
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    dailyActivityMinutesController.dispose();
    healthNotesController.dispose();
    super.dispose();
  }

  /// Get a shortened version of the pet name to prevent overflow
  String _getShortPetName() {
    String fullName = widget.petData['Name'] ?? 'your pet';
    
    // If name is short enough, return as is
    if (fullName.length <= 10) {
      return fullName;
    }
    
    // Split by spaces and take first name only
    List<String> nameParts = fullName.split(' ');
    String firstName = nameParts.first;
    
    // If first name is still too long, truncate it
    if (firstName.length > 10) {
      return firstName.substring(0, 10) + '...';
    }
    
    return firstName;
  }

  /// Get a shortened version of any pet name to prevent overflow
  String _getShortPetNameFromData(Map<String, dynamic> petData) {
    String fullName = petData['Name'] ?? petData['name'] ?? 'your pet';
    
    // If name is short enough, return as is
    if (fullName.length <= 10) {
      return fullName;
    }
    
    // Split by spaces and take first name only
    List<String> nameParts = fullName.split(' ');
    String firstName = nameParts.first;
    
    // If first name is still too long, truncate it
    if (firstName.length > 10) {
      return firstName.substring(0, 10) + '...';
    }
    
    return firstName;
  }

  /// Shorten file names to prevent UI overflow
  String _shortenFileName(String fileName) {
    if (fileName.length <= 20) {
      return fileName;
    }
    
    // Get file extension
    String extension = '';
    int dotIndex = fileName.lastIndexOf('.');
    if (dotIndex != -1) {
      extension = fileName.substring(dotIndex);
      fileName = fileName.substring(0, dotIndex);
    }
    
    // Truncate and add extension back
    if (fileName.length > 15) {
      return fileName.substring(0, 15) + '...' + extension;
    }
    
    return fileName + extension;
  }

  bool validateForm() {
    if (selectedActivityLevel.isEmpty) {
      showErrorSnackBar('Please select your pet\'s activity level 🏃‍♀️');
      return false;
    }
    
    if (dailyActivityMinutesController.text.isEmpty) {
      showErrorSnackBar('Please enter daily activity minutes ⏰');
      return false;
    }
    
    int? minutes = int.tryParse(dailyActivityMinutesController.text);
    if (minutes == null || minutes < 0 || minutes > 1440) { // 1440 minutes = 24 hours
      showErrorSnackBar('Please enter valid activity minutes (0-1440) 📊');
      return false;
    }
    
    if (selectedPoopColor.isEmpty) {
      showErrorSnackBar('Please select poop color 💩');
      return false;
    }
    
    if (selectedPoopFrequency.isEmpty) {
      showErrorSnackBar('Please select poop frequency 📅');
      return false;
    }
    
    if (selectedPoopQuantity.isEmpty) {
      showErrorSnackBar('Please select poop quantity 📏');
      return false;
    }
    
    return true;
  }

  Future<void> selectMedicalFile() async {
    try {
      var extension = ['pdf', 'jpg', 'png', 'doc', 'docx'];
      var result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Please select a medical file:',
        allowedExtensions: extension,
        type: FileType.custom,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          isMedicalFileUploaded = true;
          pickedMedicalFile = result.files.first;
        });
      } else {
        print('No file selected');
      }
    } catch (e) {
      print('Error picking file: $e');
      showErrorSnackBar('Error selecting file. Please try again.');
    }
  }

  // Convert image to base64 string with proper compression
  Future<String?> convertImageToBase64(File imageFile) async {
    try {
      // Use the ImageCompressionService for proper compression
      String? compressedBase64 = await ImageCompressionService.compressImageForFirestore(imageFile);
      
      if (compressedBase64 == null) {
        print('Failed to compress image, using placeholder');
        showErrorSnackBar('Image too large. Please select a smaller image or try again.');
        return "placeholder_image";
      }
      
      // Add the data URI prefix for proper storage
      String dataUri = "data:image/jpeg;base64,$compressedBase64";
      
      // Final size check (base64 data URI should be under 1MB for Firestore)
      if (dataUri.length > 1024 * 1024) { // 1MB limit
        print('Compressed image still too large (${(dataUri.length / 1024).round()}KB), using placeholder');
        showErrorSnackBar('Image could not be compressed enough. Please try a different image.');
        return "placeholder_image";
      }
      
      print('Image successfully compressed to ${(dataUri.length / 1024).round()}KB');
      return dataUri;
      
    } catch (e) {
      print('Error converting image to base64: $e');
      showErrorSnackBar('Error processing image. Please try again.');
      return null;
    }
  }

  void showErrorSnackBar(String message) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: 'Oops! 😅',
        message: message,
        contentType: ContentType.warning,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  String getPoopDescription(int index) {
    if (index >= 0 && index < poopStatus.length) {
      return poopStatus[index]['description'];
    }
    return 'Normal';
  }

  Color getPoopColor(int index) {
    if (index >= 0 && index < poopStatus.length) {
      return poopStatus[index]['color'];
    }
    return Colors.brown.shade400;
  }

  String getPoopEmoji(int index) {
    if (index >= 0 && index < poopStatus.length) {
      return poopStatus[index]['emoji'];
    }
    return '💩';
  }

  Future<void> submitCompleteForm() async {
    if (!validateForm()) return;
    setState(() {
      showSpinner = true;
    });
    showAddingPetDialog();
    await Future.delayed(Duration.zero); // Ensure dialog is rendered before heavy work

    try {
      // Add the current page data to petData
      Map<String, dynamic> completePetData = Map.from(widget.petData);
      completePetData['activityLevel'] = selectedActivityLevel;
      completePetData['dailyActivityMinutes'] = int.parse(dailyActivityMinutesController.text);
      completePetData['poopStatus'] = (selectedPoopStatusIndex + 1).toString();
      completePetData['poopDescription'] = getPoopDescription(selectedPoopStatusIndex);
      completePetData['poopColor'] = selectedPoopColor;
      completePetData['poopFrequency'] = selectedPoopFrequency;
      completePetData['poopQuantity'] = selectedPoopQuantity;
      if (healthNotesController.text.isNotEmpty) {
        completePetData['healthNotes'] = healthNotesController.text;
      }

      print('Pet data before image processing: ${completePetData.keys}');

      // Handle image upload - convert to base64 with size limits
      if (completePetData["pickedImage"] != null) {
        try {
          String? base64Image = await convertImageToBase64(completePetData["pickedImage"]);
          if (base64Image != null && base64Image.isNotEmpty) {
            if (base64Image == "placeholder_image") {
              // Image was too large, use asset placeholder
              completePetData["Photo"] = "assets/images/petPic.png";
              showErrorSnackBar('Image was too large. Using default image instead. 📸');
            } else {
              completePetData["Photo"] = base64Image;
            }
          } else {
            // Set default image path if conversion fails
            completePetData["Photo"] = "assets/images/petPic.png";
          }
        } catch (e) {
          print('Error processing image: $e');
          completePetData["Photo"] = "assets/images/petPic.png";
          showErrorSnackBar('Error processing image. Using default image instead. 📸');
        }
      } else {
        // Set default image if no image selected
        completePetData["Photo"] = "assets/images/petPic.png";
      }

      // Upload medical file if exists
      if (pickedMedicalFile != null) {
        // For now, just set a placeholder - later implement actual file upload
        completePetData["MedicalFile"] = "medical_file_${pickedMedicalFile!.name}";
      } else {
        completePetData["MedicalFile"] = "";
      }

      // Remove temporary file references
      completePetData.remove("pickedImage");

      // Generate unique pet ID
      String petId = "${widget.userData["Email"]}_${completePetData["Name"]}_${DateTime.now().millisecondsSinceEpoch}";
      completePetData["petId"] = petId;

      print('=== FINAL PET DATA TO BE STORED ===');
      print('All fields: ${completePetData.keys.toList()}');
      print('Complete data: $completePetData');

      // Save to Firestore using the old direct collection method
      await FirebaseFirestore.instance
          .collection(widget.userData["Email"])
          .doc(petId)
          .set(completePetData);

      setState(() {
        showSpinner = false;
      });
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss progress dialog
      // Show success dialog
      _showSuccessDialog(completePetData);
    } catch (ex) {
      setState(() {
        showSpinner = false;
      });
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss progress dialog
      print('Error processing data: $ex');
      showErrorSnackBar('Something went wrong. Please try again.');
    }
  }

  void _showSuccessDialog(Map<String, dynamic> petData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 30),
              SizedBox(width: 10),
              Text('Success! 🎉'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🎉 ${_getShortPetNameFromData(petData)} is now part of our family! 🏠✨',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              SizedBox(height: 10),
              Text(
                'Ready to get personalized meal recommendations?',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to home
                Navigator.of(context).pop(); // Go back to previous form
                Navigator.of(context).pop(); // Go back to previous form
                Navigator.of(context).pop(); // Go back to previous form
                Navigator.of(context).pop(); // Go back to initial form
              },
              child: Text('Go to Home'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to home
                Navigator.of(context).pop(); // Go back to previous form
                Navigator.of(context).pop(); // Go back to previous form
                Navigator.of(context).pop(); // Go back to previous form
                Navigator.of(context).pop(); // Go back to initial form
                
                // Navigate to AI Meal Plan Screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AIMealPlanScreen(
                      petData: petData,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: appBarColor,
                minimumSize: Size(200, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                'Create AI Meal Plan! 🤖',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Health & Activity 🏃‍♀️",
          style: TextStyle(
            fontSize: 22,
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: SafeArea(
          bottom: true,
          child: Stack(
            children: [
              PetBackgroundPattern(
                opacity: 0.8,
                symbolSize: 80.0,
                density: 0.3,
              ),
              Container(
                height: double.maxFinite,
                decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xff2A2438).withOpacity(0.85), // Semi-transparent
                  Color(0xff77669E).withOpacity(0.85), // Semi-transparent
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20.0,
                20.0,
                20.0,
                20.0 + MediaQuery.of(context).viewPadding.bottom,
              ),
              child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step Progress Indicator
                  StepProgressIndicator(
                    currentStep: 5,
                    totalSteps: 5,
                    stepLabels: [
                      'Basic Info',
                      'Details',
                      'Food Prefs',
                      'Physical',
                      'Health',
                    ],
                  ),

                  // Welcome message
                  Container(
                    padding: EdgeInsets.all(20),
                    margin: EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.pets,
                          size: 40,
                          color: Colors.blue.shade600,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "🏁 Almost Done! Final health details for ${_getShortPetName()}",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Complete these final details to finish registration! 🎯",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Activity Level Section
                  Container(
                    padding: EdgeInsets.all(20),
                    margin: EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "How active is ${_getShortPetName()}? 🐕",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Required",
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.red.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 15),
                        Column(
                          children: activityLevels.map((activity) {
                            final isSelected = selectedActivityLevel == activity['level'];
                            return Container(
                              margin: EdgeInsets.only(bottom: 10),
                              child: Material(
                                borderRadius: BorderRadius.circular(12),
                                elevation: isSelected ? 8 : 2,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    setState(() {
                                      selectedActivityLevel = activity['level'];
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isSelected ? activity['color'] : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? activity['color'] : Colors.grey.shade300,
                                        width: isSelected ? 3 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          activity['icon'],
                                          style: TextStyle(fontSize: 24),
                                        ),
                                        SizedBox(width: 15),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                activity['level'],
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: isSelected ? Colors.white : Colors.black87,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                activity['description'],
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: isSelected ? Colors.white70 : Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 25),
                        
                        // Daily Activity Minutes Field
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: Colors.blue.shade600,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Daily Activity Minutes",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "Required",
                                      style: TextStyle(
                                        fontSize: 8,
                                        color: Colors.red.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                "How many minutes does ${_getShortPetName()} spend being active daily?",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  Text(
                                    "Quick Select:",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Wrap(
                                      spacing: 6,
                                      children: [15, 30, 60, 90, 120, 180].map((minutes) {
                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              dailyActivityMinutesController.text = minutes.toString();
                                            });
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: dailyActivityMinutesController.text == minutes.toString() 
                                                  ? Colors.blue.shade600 
                                                  : Colors.blue.shade100,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              "${minutes}m",
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: dailyActivityMinutesController.text == minutes.toString() 
                                                    ? Colors.white 
                                                    : Colors.blue.shade700,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              TextFormField(
                                controller: dailyActivityMinutesController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: "Minutes per day",
                                  hintText: "e.g., 30, 60, 120",
                                  prefixIcon: Icon(Icons.timer, color: Colors.blue.shade600),
                                  suffixText: "min",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(height: 8),
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.blue.shade600,
                                      size: 16,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Include walks, play time, training, and other physical activities",
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
                      ],
                    ),
                  ),

                  // Poop Status Section
                  Container(
                    padding: EdgeInsets.all(20),
                    margin: EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "💩 Current Poop Status",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: getPoopColor(selectedPoopStatusIndex).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: getPoopColor(selectedPoopStatusIndex)),
                              ),
                              child: Text(
                                getPoopDescription(selectedPoopStatusIndex),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: getPoopColor(selectedPoopStatusIndex),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          "This helps us recommend the right diet 🎯",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: 20),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                "Select the poop status that matches your pet:",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 16),
                              
                              // Poop status indicators grid
                              GridView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 5,
                                  childAspectRatio: 0.7, // Reduced from 1.0 to 0.7 to give more height
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: poopStatus.length,
                                itemBuilder: (context, index) {
                                  final status = poopStatus[index];
                                  final isSelected = selectedPoopStatusIndex == index;
                                  
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedPoopStatusIndex = index;
                                      });
                                    },
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Rectangle container with emoji - flexible size
                                        Expanded(
                                          flex: 3, // Give more space to the rectangle
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: isSelected 
                                                  ? status['color'].withOpacity(0.3)
                                                  : Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isSelected 
                                                    ? status['color']
                                                    : Colors.grey.shade300,
                                                width: isSelected ? 3 : 1,
                                              ),
                                              boxShadow: isSelected ? [
                                                BoxShadow(
                                                  color: status['color'].withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: Offset(0, 2),
                                                ),
                                              ] : null,
                                            ),
                                            child: Center(
                                              child: Text(
                                                status['emoji'],
                                                style: TextStyle(
                                                  fontSize: 20, // Reduced from 24 to 20
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Text label below the rectangle
                                        SizedBox(height: 2), // Reduced from 4 to 2
                                        Expanded(
                                          flex: 2, // Give space to the text area
                                          child: Text(
                                            status['description'] == 'Very Hard' 
                                                ? 'Very\nHard'
                                                : status['description'] == 'Very Soft'
                                                    ? 'Very\nSoft'
                                                    : status['description'],
                                            style: TextStyle(
                                              fontSize: 8, // Reduced from 10 to 8
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                              color: isSelected ? status['color'] : Colors.black54,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              
                              SizedBox(height: 12),
                              
                              // Helper text
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Tap on the icon that best describes your pet's current poop consistency",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue.shade700,
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
                        
                        // Additional Poop Details
                        SizedBox(height: 20),
                        Text(
                          "Additional Poop Details",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 15),
                        
                        // Poop Color
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Poop Color",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selectedPoopColor.isEmpty ? Colors.red.shade300 : Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: DropdownButton<String>(
                                value: selectedPoopColor.isEmpty ? null : selectedPoopColor,
                                hint: Text("Select poop color"),
                                isExpanded: true,
                                underline: SizedBox.shrink(),
                                items: poopColors.map((color) {
                                  return DropdownMenuItem<String>(
                                    value: color,
                                    child: Text(color),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedPoopColor = value ?? '';
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 15),
                        
                        // Poop Frequency
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Poop Frequency",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selectedPoopFrequency.isEmpty ? Colors.red.shade300 : Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: DropdownButton<String>(
                                value: selectedPoopFrequency.isEmpty ? null : selectedPoopFrequency,
                                hint: Text("Select poop frequency"),
                                isExpanded: true,
                                underline: SizedBox.shrink(),
                                items: poopFrequencies.map((frequency) {
                                  return DropdownMenuItem<String>(
                                    value: frequency,
                                    child: Text(frequency),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedPoopFrequency = value ?? '';
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 15),
                        
                        // Poop Quantity
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Poop Quantity",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selectedPoopQuantity.isEmpty ? Colors.red.shade300 : Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: DropdownButton<String>(
                                value: selectedPoopQuantity.isEmpty ? null : selectedPoopQuantity,
                                hint: Text("Select poop quantity"),
                                isExpanded: true,
                                underline: SizedBox.shrink(),
                                items: poopQuantities.map((quantity) {
                                  return DropdownMenuItem<String>(
                                    value: quantity,
                                    child: Text(quantity),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedPoopQuantity = value ?? '';
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Health Notes Section
                  Container(
                    padding: EdgeInsets.all(20),
                    margin: EdgeInsets.only(bottom: 30),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "🩺 Additional Health Notes",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Spacer(),
                            Text(
                              "Optional",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Any other health information we should know? 📝",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: 15),
                        TextFormField(
                          controller: healthNotesController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: "Medications, conditions, behaviors, etc...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Icon(Icons.health_and_safety),
                          ),
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  // Medical File Upload Section  
                  Container(
                    padding: EdgeInsets.all(20),
                    margin: EdgeInsets.only(bottom: 30),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "📄 Medical Records",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Spacer(),
                            Text(
                              "Optional",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Upload vaccination records, test results, or medical documents 🏥",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: 15),
                        GestureDetector(
                          onTap: selectMedicalFile,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isMedicalFileUploaded 
                                    ? Colors.green.shade400 
                                    : Colors.grey.shade400,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  isMedicalFileUploaded 
                                      ? Icons.check_circle 
                                      : Icons.cloud_upload_outlined,
                                  size: 40,
                                  color: isMedicalFileUploaded 
                                      ? Colors.green.shade600 
                                      : Colors.grey.shade600,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  isMedicalFileUploaded 
                                      ? "File Selected: ${_shortenFileName(pickedMedicalFile?.name ?? '')}" 
                                      : "Tap to upload medical file",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isMedicalFileUploaded 
                                        ? Colors.green.shade700 
                                        : Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                                if (!isMedicalFileUploaded) ...[
                                  SizedBox(height: 4),
                                  Text(
                                    "PDF, JPG, PNG, DOC accepted",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Add Pet Button
                  Center(
                    child: ElevatedButton(
                      onPressed: submitCompleteForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade500,
                        minimumSize: Size(300, 60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.pets,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              "Complete Registration 🎉",
                              style: TextStyle(
                                fontSize: 16,
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
                ],
              ),
            ),
          ),
        ),
            ],
          ),
        ),
      ),
    );
  }
}
