import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:pet_care/ColorsScheme.dart';
import 'package:pet_care/HomePage/addPetFormDark5.dart';
import 'package:pet_care/widgets/step_progress_indicator.dart';
import 'package:pet_care/widgets/pet_background_pattern.dart';

class addPetFormDark4 extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Map<String, dynamic> petData;
  
  const addPetFormDark4({super.key, required this.userData, required this.petData});

  @override
  State<addPetFormDark4> createState() => _addPetFormDark4State();
}

class _addPetFormDark4State extends State<addPetFormDark4> {
  bool showSpinner = false;
  
  // Gender
  String selectedGender = '';
  
  // Neutered/Spayed status
  String selectedNeuteredStatus = 'No'; // Default to 'No' - more common default
  
  // Body condition
  String selectedBodyCondition = 'Normal'; // Default to 'Normal' - most common condition

  final List<Map<String, dynamic>> genderOptions = [
    {'value': 'Male', 'icon': '♂️', 'color': Colors.blue},
    {'value': 'Female', 'icon': '♀️', 'color': Colors.pink},
  ];

  final List<Map<String, dynamic>> neuteredOptions = [
    {'value': 'Yes', 'icon': '✅', 'description': 'Neutered/Spayed'},
    {'value': 'No', 'icon': '❌', 'description': 'Not neutered/spayed'},
  ];

  final List<Map<String, dynamic>> bodyConditions = [
    {
      'condition': 'Slim',
      'icon': '📏',
      'description': 'Underweight, ribs easily visible',
      'color': Colors.orange.shade400,
    },
    {
      'condition': 'Normal',
      'icon': '✨',
      'description': 'Ideal weight, ribs easily felt',
      'color': Colors.green.shade400,
    },
    {
      'condition': 'Overweight',
      'icon': '📈',
      'description': 'Overweight, ribs hard to feel',
      'color': Colors.red.shade400,
    },
  ];

  @override
  void initState() {
    super.initState();
  }

  bool validateForm() {
    if (selectedGender.isEmpty) {
      showErrorSnackBar('Please select your pet\'s gender - this is required for nutrition planning 🐕');
      return false;
    }
    
    // selectedNeuteredStatus and selectedBodyCondition have default values,
    // so they should always be valid, but we can add additional validation here if needed
    
    return true;
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

  Future<void> submitCompleteForm() async {
    if (!validateForm()) return;
    
    setState(() {
      showSpinner = true;
    });

    try {
      // Combine all pet data for the next form
      Map<String, dynamic> completePetData = Map.from(widget.petData);
      
      // Add new data from this form
      completePetData['gender'] = selectedGender;
      completePetData['neuteredStatus'] = selectedNeuteredStatus;
      completePetData['bodyCondition'] = selectedBodyCondition;

      print('=== PASSING DATA TO NEXT FORM ===');
      print('All fields: ${completePetData.keys.toList()}');

      setState(() {
        showSpinner = false;
      });

      // Navigate to next form (Health & Activity)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => addPetFormDark5(
            userData: widget.userData,
            petData: completePetData,
          ),
        ),
      );

    } catch (e) {
      setState(() {
        showSpinner = false;
      });
      
      showErrorSnackBar('Error processing data: $e');
      print('Error processing data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: showSpinner,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Basic Characteristics 🐾",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: listTileColorSecond,
            ),
          ),
          iconTheme: IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
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
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step Progress Indicator
                StepProgressIndicator(
                  currentStep: 4,
                  totalSteps: 5,
                  stepLabels: [
                    'Basic Info',
                    'Details',
                    'Food Prefs',
                    'Physical',
                    'Health',
                  ],
                ),
                
                // Header
                Container(
                  padding: EdgeInsets.all(20),
                  margin: EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade100, Colors.purple.shade100],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.pets,
                        size: 40,
                        color: Colors.purple.shade600,
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Basic Characteristics 🐾",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 5),
                      Text(
                        "Tell us about ${widget.petData['Name'] ?? 'your pet'}'s gender and physical details",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Gender Selection
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
                            "🐕 Gender",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            " *",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        "What's your pet's gender? (Required) 🎭",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      SizedBox(height: 15),
                      Row(
                        children: genderOptions.map((gender) {
                          bool isSelected = selectedGender == gender['value'];
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedGender = gender['value'];
                                });
                              },
                              child: Container(
                                margin: EdgeInsets.only(right: gender['value'] == 'Male' ? 10 : 0),
                                padding: EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: isSelected ? gender['color'].withOpacity(0.2) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? gender['color'] : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      gender['icon'],
                                      style: TextStyle(fontSize: 30),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      gender['value'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? gender['color'] : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                // Neutered/Spayed Status
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
                        "🏥 Neutered/Spayed Status",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Has your pet been neutered or spayed? (Default: No) 💊",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      SizedBox(height: 15),
                      Row(
                        children: neuteredOptions.map((option) {
                          bool isSelected = selectedNeuteredStatus == option['value'];
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedNeuteredStatus = option['value'];
                                });
                              },
                              child: Container(
                                margin: EdgeInsets.only(right: option['value'] == 'Yes' ? 10 : 0),
                                padding: EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.blue.shade50 : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? Colors.blue.shade400 : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      option['icon'],
                                      style: TextStyle(fontSize: 25),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      option['value'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.blue.shade600 : Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      option['description'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                // Body Condition
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
                        "📊 Body Condition",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "How would you describe your pet's current body condition? (Default: Normal) ⚖️",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      SizedBox(height: 15),
                      Column(
                        children: bodyConditions.map((condition) {
                          bool isSelected = selectedBodyCondition == condition['condition'];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedBodyCondition = condition['condition'];
                              });
                            },
                            child: Container(
                              width: double.infinity,
                              margin: EdgeInsets.only(bottom: 10),
                              padding: EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: isSelected ? condition['color'].withOpacity(0.1) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? condition['color'] : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    condition['icon'],
                                    style: TextStyle(fontSize: 25),
                                  ),
                                  SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          condition['condition'],
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? condition['color'] : Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          condition['description'],
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
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                // Submit Button
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(top: 20, bottom: 40),
                  child: ElevatedButton(
                    onPressed: submitCompleteForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appBarColor,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    child: Text(
                      "Continue to Health & Activity 🏃‍♀️",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
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
