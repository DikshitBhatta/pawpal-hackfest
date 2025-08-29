import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:pet_care/ColorsScheme.dart';
import 'package:pet_care/DataBase.dart';
import 'package:pet_care/AIScreen/AIMealPlanScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class addPetFormDark4 extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Map<String, dynamic> petData;
  
  const addPetFormDark4({super.key, required this.userData, required this.petData});

  @override
  State<addPetFormDark4> createState() => _addPetFormDark4State();
}

class _addPetFormDark4State extends State<addPetFormDark4> {
  bool showSpinner = false;
  
  // Activity level
  String selectedActivityLevel = '';
  
  // Poop status
  double poopStatusValue = 3.0; // Default middle value
  
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
    {'level': 1, 'description': 'Very Hard', 'color': Colors.brown.shade800, 'emoji': '🟤'},
    {'level': 2, 'description': 'Hard', 'color': Colors.brown.shade600, 'emoji': '🟤'},
    {'level': 3, 'description': 'Normal', 'color': Colors.brown.shade400, 'emoji': '🟤'},
    {'level': 4, 'description': 'Soft', 'color': Colors.brown.shade300, 'emoji': '🟫'},
    {'level': 5, 'description': 'Very Soft', 'color': Colors.brown.shade200, 'emoji': '🟫'},
  ];

  @override
  void initState() {
    super.initState();
  }

  bool validateForm() {
    if (selectedActivityLevel.isEmpty) {
      showErrorSnackBar('Please select your pet\'s activity level 🏃‍♀️');
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

  // Convert image to base64 string
  Future<String?> convertImageToBase64(File imageFile) async {
    try {
      Uint8List imageBytes = await imageFile.readAsBytes();
      String base64String = base64Encode(imageBytes);
      return "data:image/png;base64,$base64String";
    } catch (e) {
      print('Error converting image to base64: $e');
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

  String getPoopDescription(double value) {
    int index = (value - 1).round();
    if (index >= 0 && index < poopStatus.length) {
      return poopStatus[index]['description'];
    }
    return 'Normal';
  }

  Color getPoopColor(double value) {
    int index = (value - 1).round();
    if (index >= 0 && index < poopStatus.length) {
      return poopStatus[index]['color'];
    }
    return Colors.brown.shade400;
  }

  Future<void> submitCompleteForm() async {
    if (!validateForm()) return;
    
    setState(() {
      showSpinner = true;
    });

    try {
      // Add the final data to petData
      Map<String, dynamic> completePetData = Map.from(widget.petData);
      completePetData['activityLevel'] = selectedActivityLevel;
      completePetData['poopStatus'] = poopStatusValue.toString();
      completePetData['poopDescription'] = getPoopDescription(poopStatusValue);
      if (healthNotesController.text.isNotEmpty) {
        completePetData['healthNotes'] = healthNotesController.text;
      }

      print('Pet data before image processing: ${completePetData.keys}');

      // Handle image upload - convert to base64 instead of Firebase Storage
      if (completePetData["pickedImage"] != null) {
        try {
          String? base64Image = await convertImageToBase64(completePetData["pickedImage"]);
          if (base64Image != null && base64Image.isNotEmpty) {
            completePetData["Photo"] = base64Image;
          } else {
            // Set default image path if conversion fails
            completePetData["Photo"] = "assets/images/petPic.png";
          }
        } catch (e) {
          print('Error processing image: $e');
          completePetData["Photo"] = "assets/images/petPic.png";
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

      // Remove temporary file references before saving to database
      completePetData.remove("pickedImage");

      // Clean up any null values that might cause issues
      completePetData.removeWhere((key, value) => value == null);

      print('Pet data before saving to Firestore: $completePetData');

      // Generate a unique pet ID
      String petId = "${widget.userData["Email"]}_${completePetData["Name"]}_${DateTime.now().millisecondsSinceEpoch}";
      completePetData["petId"] = petId;

      // Save to database using the user's email as collection and pet ID as document
      var db = FirebaseFirestore.instance;
      await db.collection(widget.userData["Email"]).doc(petId).set(completePetData);
      print('Save successful');
      
      setState(() {
        showSpinner = false;
      });

      // Navigate directly to AI Meal Plan Screen instead of subscription
      showPetSuccessAndNavigateToMealPlan(completePetData);
    } catch (ex) {
      setState(() {
        showSpinner = false;
      });
      print('Error saving pet: $ex');
      showErrorSnackBar('Something went wrong. Please try again.');
    }
  }

  void showPetSuccessAndNavigateToMealPlan(Map<String, dynamic> petData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.pets,
                size: 60,
                color: Colors.green.shade500,
              ),
              SizedBox(height: 20),
              Text(
                "🎉 ${petData['Name']} Added Successfully!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                "Let's create a personalized meal plan for ${petData['Name']}! 🍽️",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to home
                  Navigator.of(context).pop(); // Go back to previous form
                  Navigator.of(context).pop(); // Go back to previous form
                  Navigator.of(context).pop(); // Go back to initial form
                  
                  // Navigate to AI Meal Plan Screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AIMealPlanScreen(petData: petData),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade500,
                  minimumSize: Size(200, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  "Create Meal Plan 🚀",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Final Details - Step 4 🏁",
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
        child: Container(
          height: double.maxFinite,
          decoration: BoxDecoration(
            gradient: backgroundColor,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress indicator - all filled
                  Container(
                    margin: EdgeInsets.only(bottom: 30),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: appBarColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: appBarColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: appBarColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: appBarColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
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
                          "🏁 Almost done! Just a few more details about ${widget.petData['Name']}",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          "This helps us create the perfect care plan! 🎯",
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
                        Text(
                          "How active is ${widget.petData['Name']}? 🐕",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
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
                                color: getPoopColor(poopStatusValue).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: getPoopColor(poopStatusValue)),
                              ),
                              child: Text(
                                getPoopDescription(poopStatusValue),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: getPoopColor(poopStatusValue),
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    flex: 2,
                                    child: Text(
                                      "Very Hard",
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Flexible(
                                    flex: 2,
                                    child: Text(
                                      "Very Soft",
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                      textAlign: TextAlign.end,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 8,
                                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
                                  overlayShape: RoundSliderOverlayShape(overlayRadius: 20),
                                ),
                                child: Slider(
                                  value: poopStatusValue,
                                  min: 1,
                                  max: 5,
                                  divisions: 4,
                                  activeColor: getPoopColor(poopStatusValue),
                                  inactiveColor: Colors.grey.shade300,
                                  onChanged: (value) {
                                    setState(() {
                                      poopStatusValue = value;
                                    });
                                  },
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: List.generate(5, (index) {
                                  final level = index + 1;
                                  return Text(
                                    poopStatus[index]['emoji'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: poopStatusValue.round() == level 
                                          ? poopStatus[index]['color'] 
                                          : Colors.grey,
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
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
                                      ? "File Selected: ${pickedMedicalFile?.name}" 
                                      : "Tap to upload medical file",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isMedicalFileUploaded 
                                        ? Colors.green.shade700 
                                        : Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
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
                              "Add ${widget.petData['Name']} to Family! 🎉",
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
      ),
    );
  }
}
