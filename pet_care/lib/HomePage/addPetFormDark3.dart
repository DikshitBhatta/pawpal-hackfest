import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:pet_care/ColorsScheme.dart';
import 'package:pet_care/HomePage/addPetFormDark4.dart';
import 'package:pet_care/widgets/step_progress_indicator.dart';
import 'package:pet_care/widgets/pet_background_pattern.dart';

class addPetFormDark3 extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Map<String, dynamic> petData;
  
  const addPetFormDark3({super.key, required this.userData, required this.petData});

  @override
  State<addPetFormDark3> createState() => _addPetFormDark3State();
}

class _addPetFormDark3State extends State<addPetFormDark3> {
  bool showSpinner = false;
  
  // Food allergies and dislikes
  List<String> selectedAllergies = [];
  List<Map<String, String>> customAllergies = []; // {ingredient: "", brand: ""}
  TextEditingController customAllergyController = TextEditingController();
  TextEditingController customAllergyBrandController = TextEditingController();
  
  // Favorite foods
  List<String> selectedFavorites = [];
  List<Map<String, String>> customFavorites = []; // {ingredient: "", brand: ""}
  TextEditingController customFavoriteController = TextEditingController();
  TextEditingController customFavoriteBrandController = TextEditingController();
  
  // Feeding frequency
  String selectedFeedingFrequency = '';
  
  final List<Map<String, dynamic>> commonAllergies = [
    {'name': 'Chicken', 'icon': '🐔', 'isSelected': false},
    {'name': 'Beef', 'icon': '🥩', 'isSelected': false},
    {'name': 'Dairy', 'icon': '🥛', 'isSelected': false},
    {'name': 'Fish', 'icon': '🐟', 'isSelected': false},
    {'name': 'Soy', 'icon': '🫘', 'isSelected': false},
    {'name': 'None', 'icon': '✅', 'isSelected': false},
  ];

  final List<Map<String, dynamic>> favoriteFoods = [
    {'name': 'Chicken', 'icon': '🐔', 'isSelected': false},
    {'name': 'Turkey', 'icon': '🦃', 'isSelected': false},
    {'name': 'Salmon', 'icon': '🐟', 'isSelected': false},
    {'name': 'Rice', 'icon': '🍚', 'isSelected': false},
    {'name': 'Sweet Potato', 'icon': '🍠', 'isSelected': false},
    {'name': 'Carrots', 'icon': '🥕', 'isSelected': false},
    {'name': 'Pumpkin', 'icon': '🎃', 'isSelected': false},
    {'name': 'Lamb', 'icon': '🐑', 'isSelected': false},
  ];

  final List<Map<String, dynamic>> feedingFrequencies = [
    {
      'frequency': 'Once a day',
      'icon': '🍽️',
      'description': 'Single daily meal',
      'timeDescription': 'Usually in the evening',
    },
    {
      'frequency': 'Twice a day',
      'icon': '🍽️🍽️',
      'description': 'Morning and evening meals',
      'timeDescription': 'Most common schedule',
    },
    {
      'frequency': '3 times a day',
      'icon': '🍽️🍽️🍽️',
      'description': 'Morning, afternoon, and evening',
      'timeDescription': 'Good for puppies or small dogs',
    },
    {
      'frequency': 'Free feeding',
      'icon': '🥣',
      'description': 'Food available all the time',
      'timeDescription': 'Pet eats when hungry',
    },
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    customAllergyController.dispose();
    customAllergyBrandController.dispose();
    customFavoriteController.dispose();
    customFavoriteBrandController.dispose();
    super.dispose();
  }

  void toggleAllergy(int index) {
    setState(() {
      final allergyName = commonAllergies[index]['name'];
      
      // If selecting "None", deselect all others
      if (allergyName == 'None') {
        if (!commonAllergies[index]['isSelected']) {
          // Deselect all other allergies
          for (int i = 0; i < commonAllergies.length; i++) {
            if (i != index) {
              commonAllergies[i]['isSelected'] = false;
            }
          }
          selectedAllergies.clear();
          selectedAllergies.add('None');
        }
        commonAllergies[index]['isSelected'] = !commonAllergies[index]['isSelected'];
        if (!commonAllergies[index]['isSelected']) {
          selectedAllergies.remove('None');
        }
      } else {
        // Check if this ingredient is already in favorites
        if (selectedFavorites.contains(allergyName)) {
          showErrorSnackBar('${allergyName} is already selected as a favorite food. Please remove it from favorites first 🔄');
          return;
        }
        
        // If selecting any other allergy, deselect "None"
        for (int i = 0; i < commonAllergies.length; i++) {
          if (commonAllergies[i]['name'] == 'None') {
            commonAllergies[i]['isSelected'] = false;
            selectedAllergies.remove('None');
            break;
          }
        }
        
        commonAllergies[index]['isSelected'] = !commonAllergies[index]['isSelected'];
        
        if (commonAllergies[index]['isSelected']) {
          selectedAllergies.add(allergyName);
        } else {
          selectedAllergies.remove(allergyName);
        }
      }
    });
  }

  void toggleFavorite(int index) {
    setState(() {
      final foodName = favoriteFoods[index]['name'];
      
      // Check if this ingredient is already in allergies
      if (selectedAllergies.contains(foodName)) {
        showErrorSnackBar('${foodName} is already selected as an allergy. Please remove it from allergies first 🔄');
        return;
      }
      
      favoriteFoods[index]['isSelected'] = !favoriteFoods[index]['isSelected'];
      
      if (favoriteFoods[index]['isSelected']) {
        selectedFavorites.add(foodName);
      } else {
        selectedFavorites.remove(foodName);
      }
    });
  }

  void addCustomAllergy() {
    if (customAllergyController.text.trim().isEmpty) {
      showErrorSnackBar('Please enter an ingredient name 📝');
      return;
    }

    final ingredient = customAllergyController.text.trim();
    final brand = customAllergyBrandController.text.trim();
    
    // Check if ingredient already exists in favorites
    if (selectedFavorites.contains(ingredient) || 
        customFavorites.any((fav) => fav['ingredient']?.toLowerCase() == ingredient.toLowerCase())) {
      showErrorSnackBar('${ingredient} is already in favorites. Cannot add as allergy ⚠️');
      return;
    }
    
    // Check if already exists in custom allergies
    if (customAllergies.any((allergy) => allergy['ingredient']?.toLowerCase() == ingredient.toLowerCase())) {
      showErrorSnackBar('${ingredient} is already added to allergies 📋');
      return;
    }

    setState(() {
      customAllergies.add({
        'ingredient': ingredient,
        'brand': brand,
      });
      customAllergyController.clear();
      customAllergyBrandController.clear();
    });
  }

  void removeCustomAllergy(int index) {
    setState(() {
      customAllergies.removeAt(index);
    });
  }

  void addCustomFavorite() {
    if (customFavoriteController.text.trim().isEmpty) {
      showErrorSnackBar('Please enter an ingredient name 📝');
      return;
    }

    final ingredient = customFavoriteController.text.trim();
    final brand = customFavoriteBrandController.text.trim();
    
    // Check if ingredient already exists in allergies
    if (selectedAllergies.contains(ingredient) || 
        customAllergies.any((allergy) => allergy['ingredient']?.toLowerCase() == ingredient.toLowerCase())) {
      showErrorSnackBar('${ingredient} is already in allergies. Cannot add as favorite ⚠️');
      return;
    }
    
    // Check if already exists in custom favorites
    if (customFavorites.any((fav) => fav['ingredient']?.toLowerCase() == ingredient.toLowerCase())) {
      showErrorSnackBar('${ingredient} is already added to favorites 📋');
      return;
    }

    setState(() {
      customFavorites.add({
        'ingredient': ingredient,
        'brand': brand,
      });
      customFavoriteController.clear();
      customFavoriteBrandController.clear();
    });
  }

  void removeCustomFavorite(int index) {
    setState(() {
      customFavorites.removeAt(index);
    });
  }

  // Helper method to check if an ingredient is in favorites (including custom)
  bool isIngredientInFavorites(String ingredient) {
    return selectedFavorites.contains(ingredient) ||
        customFavorites.any((fav) => fav['ingredient']?.toLowerCase() == ingredient.toLowerCase());
  }

  // Helper method to check if an ingredient is in allergies (including custom)
  bool isIngredientInAllergies(String ingredient) {
    return selectedAllergies.contains(ingredient) ||
        customAllergies.any((allergy) => allergy['ingredient']?.toLowerCase() == ingredient.toLowerCase());
  }

  bool validateForm() {
    // Make food allergies mandatory
    if (selectedAllergies.isEmpty) {
      showErrorSnackBar('Please select at least one allergy option (or "None" if no allergies) 🚨');
      return false;
    }
    
    // Make feeding frequency mandatory
    if (selectedFeedingFrequency.isEmpty) {
      showErrorSnackBar('Please select feeding frequency 🍽️');
      return false;
    }
    
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
        contentType: ContentType.failure,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void continueToNextPage() {
    // Validate form before continuing
    if (!validateForm()) return;
    
    setState(() {
      showSpinner = true;
    });

    // Add the new data to petData
    Map<String, dynamic> updatedPetData = Map.from(widget.petData);
    updatedPetData['allergies'] = selectedAllergies;
    updatedPetData['favorites'] = selectedFavorites;
    updatedPetData['customAllergies'] = customAllergies;
    updatedPetData['customFavorites'] = customFavorites;
    updatedPetData['feedingFrequency'] = selectedFeedingFrequency;

    setState(() {
      showSpinner = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => addPetFormDark4(
          userData: widget.userData,
          petData: updatedPetData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Food Preferences 🍽️",
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
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step Progress Indicator
                  StepProgressIndicator(
                    currentStep: 3,
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
                    margin: EdgeInsets.only(bottom: 30),
                    decoration: BoxDecoration(
                      gradient: BackgroundOverlayColorReverse,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "🍽️ Tell us about ${widget.petData['Name']}'s food preferences!",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: subTextColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          "This helps us recommend the best diet and avoid any problems 🥰",
                          style: TextStyle(
                            fontSize: 14,
                            color: subTextColor.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        // SizedBox(height: 8),
                        // Container(
                        //   padding: EdgeInsets.all(12),
                        //   decoration: BoxDecoration(
                        //     color: Colors.blue.shade50,
                        //     borderRadius: BorderRadius.circular(8),
                        //     border: Border.all(color: Colors.blue.shade200),
                        //   ),
                        //   // child: Row(
                        //   //   children: [
                        //   //     Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
                        //   //     SizedBox(width: 8),
                        //   //     Expanded(
                        //   //       child: Text(
                        //   //         "Smart Conflict Detection: We'll prevent you from selecting the same ingredient as both an allergy and favorite!",
                        //   //         style: TextStyle(
                        //   //           fontSize: 12,
                        //   //           color: Colors.blue.shade700,
                        //   //           fontWeight: FontWeight.w500,
                        //   //         ),
                        //   //       ),
                        //   //     ),
                        //   //   ],
                        //   // ),
                        // ),
                      ],
                    ),
                  ),

                  // Allergies and Dislikes Section
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
                            Flexible(
                              child: Text(
                                "⚠️ Food Allergies",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
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
                        SizedBox(height: 8),
                        Text(
                          "Help us keep ${widget.petData['Name']} safe and happy! 🛡️",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: 15),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.5, // Changed from 3.0 to 1.5 to make containers taller and more proportionate
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: commonAllergies.length,
                          itemBuilder: (context, index) {
                            final allergy = commonAllergies[index];
                            final isSelected = allergy['isSelected'];
                            final allergyName = allergy['name'];
                            final hasConflict = allergyName != 'None' && isIngredientInFavorites(allergyName);
                            
                            return GestureDetector(
                              onTap: () => toggleAllergy(index),
                              child: Tooltip(
                                message: hasConflict 
                                    ? "⚠️ WARNING: $allergyName is already selected as a favorite food! This creates a conflict."
                                    : isSelected 
                                        ? "Selected allergy: $allergyName"
                                        : "Tap to select $allergyName as an allergy",
                              child: Container(
                                decoration: BoxDecoration(
                                    color: isSelected 
                                        ? Colors.red.shade400 
                                        : hasConflict 
                                            ? Colors.red.shade50  // More prominent red background
                                            : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: isSelected 
                                          ? Colors.red.shade400 
                                          : hasConflict
                                              ? Colors.red.shade600  // Red border instead of orange
                                              : Colors.grey.shade300,
                                      width: hasConflict ? 3 : 2,  // Thicker border for conflicts
                                    ),
                                    // Add box shadow for conflicts
                                    boxShadow: hasConflict ? [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                  ),
                                    ] : null,
                                ),
                                  child: Stack(
                                    children: [
                                      Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        allergy['icon'],
                                              style: TextStyle(fontSize: 16), // Increased from 14 to 16
                                      ),
                                            SizedBox(height: 4), // Increased from 1 to 4
                                      Text(
                                              allergyName,
                                        style: TextStyle(
                                                fontSize: 11, // Increased from 10 to 11
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                                color: isSelected 
                                                    ? Colors.white 
                                                    : hasConflict
                                                        ? Colors.red.shade700  // Red text for conflicts
                                                        : Colors.black87,
                                        ),
                                        textAlign: TextAlign.center,
                                              maxLines: 2, // Keep max lines
                                              overflow: TextOverflow.ellipsis, // Keep overflow handling
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (hasConflict) ...[
                                        // Large warning icon
                                        Positioned(
                                          top: 2,
                                          right: 2,
                                          child: Container(
                                            padding: EdgeInsets.all(1),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.warning,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        // Pulsing effect overlay
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.red.withOpacity(0.6),
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 15),
                        
                        // Conflict Warning Banner
                        if (selectedAllergies.any((allergyName) => allergyName != 'None' && isIngredientInFavorites(allergyName))) ...[
                          Container(
                            padding: EdgeInsets.all(12),
                            margin: EdgeInsets.only(bottom: 15),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.shade400, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    Icons.warning,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                        Text(
                                        "⚠️ ALLERGY CONFLICT DETECTED",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red.shade700,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        "Some ingredients are selected as both allergies and favorites. Please review and fix conflicts above.",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.red.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        Text(
                          "📝 Add Custom Allergies:",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        
                        // Custom Allergy Input
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                          controller: customAllergyController,
                          decoration: InputDecoration(
                                        labelText: "Ingredient *",
                                        hintText: "e.g., Corn, Wheat",
                            border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                            ),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          style: TextStyle(fontSize: 14),
                        ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    flex: 1,
                                    child: TextFormField(
                                      controller: customAllergyBrandController,
                                      decoration: InputDecoration(
                                        labelText: "Brand",
                                        hintText: "Optional",
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: addCustomAllergy,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade400,
                                      shape: CircleBorder(),
                                      padding: EdgeInsets.all(12),
                                    ),
                                    child: Icon(Icons.add, color: Colors.white, size: 20),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Display Custom Allergies
                        if (customAllergies.isNotEmpty) ...[
                          SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: customAllergies.asMap().entries.map((entry) {
                              final index = entry.key;
                              final allergy = entry.value;
                              return Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.red.shade300),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      allergy['brand']!.isNotEmpty 
                                          ? "${allergy['ingredient']} (${allergy['brand']})"
                                          : allergy['ingredient']!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => removeCustomAllergy(index),
                                      child: Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Favorite Foods Section
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
                            Flexible(
                              child: Text(
                                "❤️ Favorite Foods",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Optional",
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.blue.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          "What does ${widget.petData['Name']} love to eat? 😋",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: 15),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 1.8,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: favoriteFoods.length,
                          itemBuilder: (context, index) {
                            final food = favoriteFoods[index];
                            final isSelected = food['isSelected'];
                            final foodName = food['name'];
                            final hasConflict = isIngredientInAllergies(foodName);
                            
                            return GestureDetector(
                              onTap: () => toggleFavorite(index),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? Colors.green.shade400 
                                      : hasConflict 
                                          ? Colors.orange.shade100
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected 
                                        ? Colors.green.shade400 
                                        : hasConflict
                                            ? Colors.orange.shade400
                                            : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        food['icon'],
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                            foodName,
                                        style: TextStyle(
                                          fontSize: 8,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                              color: isSelected 
                                                  ? Colors.white 
                                                  : hasConflict
                                                      ? Colors.orange.shade700
                                                      : Colors.black87,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                    if (hasConflict)
                                      Positioned(
                                        top: 2,
                                        right: 2,
                                        child: Icon(
                                          Icons.warning,
                                          size: 12,
                                          color: Colors.orange.shade600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 15),
                        
                        Text(
                          "🌟 Add Custom Favorites:",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        
                        // Custom Favorite Input
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                          controller: customFavoriteController,
                          decoration: InputDecoration(
                                        labelText: "Ingredient *",
                                        hintText: "e.g., Salmon, Turkey",
                            border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                            ),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          style: TextStyle(fontSize: 14),
                        ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    flex: 1,
                                    child: TextFormField(
                                      controller: customFavoriteBrandController,
                                      decoration: InputDecoration(
                                        labelText: "Brand",
                                        hintText: "Optional",
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: addCustomFavorite,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade400,
                                      shape: CircleBorder(),
                                      padding: EdgeInsets.all(12),
                                    ),
                                    child: Icon(Icons.add, color: Colors.white, size: 20),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Display Custom Favorites
                        if (customFavorites.isNotEmpty) ...[
                          SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: customFavorites.asMap().entries.map((entry) {
                              final index = entry.key;
                              final favorite = entry.value;
                              return Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.green.shade300),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      favorite['brand']!.isNotEmpty 
                                          ? "${favorite['ingredient']} (${favorite['brand']})"
                                          : favorite['ingredient']!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => removeCustomFavorite(index),
                                      child: Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // // Summary Section
                  // if (selectedAllergies.isNotEmpty || customAllergies.isNotEmpty || 
                  //     selectedFavorites.isNotEmpty || customFavorites.isNotEmpty) ...[
                  //   Container(
                  //     padding: EdgeInsets.all(20),
                  //     margin: EdgeInsets.only(bottom: 20),
                  //     decoration: BoxDecoration(
                  //       color: Colors.blue.shade50,
                  //       borderRadius: BorderRadius.circular(15),
                  //       border: Border.all(color: Colors.blue.shade200),
                  //     ),
                  //     child: Column(
                  //       crossAxisAlignment: CrossAxisAlignment.start,
                  //       children: [
                  //         Text(
                  //           "📋 Summary for ${widget.petData['Name']}",
                  //           style: TextStyle(
                  //             fontSize: 16,
                  //             fontWeight: FontWeight.bold,
                  //             color: Colors.blue.shade800,
                  //           ),
                  //         ),
                  //         SizedBox(height: 12),
                          
                  //         if (selectedAllergies.isNotEmpty || customAllergies.isNotEmpty) ...[
                  //           Text(
                  //             "⚠️ Allergies:",
                  //             style: TextStyle(
                  //               fontSize: 14,
                  //               fontWeight: FontWeight.w600,
                  //               color: Colors.red.shade700,
                  //             ),
                  //           ),
                  //           SizedBox(height: 4),
                  //           Text(
                  //             [
                  //               ...selectedAllergies,
                  //               ...customAllergies.map((allergy) => 
                  //                   allergy['brand']!.isNotEmpty 
                  //                       ? "${allergy['ingredient']} (${allergy['brand']})"
                  //                       : allergy['ingredient']!)
                  //             ].join(", "),
                  //             style: TextStyle(
                  //               fontSize: 12,
                  //               color: Colors.red.shade600,
                  //             ),
                  //           ),
                  //           SizedBox(height: 8),
                  //         ],
                          
                  //         if (selectedFavorites.isNotEmpty || customFavorites.isNotEmpty) ...[
                  //           Text(
                  //             "❤️ Favorites:",
                  //             style: TextStyle(
                  //               fontSize: 14,
                  //               fontWeight: FontWeight.w600,
                  //               color: Colors.green.shade700,
                  //             ),
                  //           ),
                  //           SizedBox(height: 4),
                  //           Text(
                  //             [
                  //               ...selectedFavorites,
                  //               ...customFavorites.map((fav) => 
                  //                   fav['brand']!.isNotEmpty 
                  //                       ? "${fav['ingredient']} (${fav['brand']})"
                  //                       : fav['ingredient']!)
                  //             ].join(", "),
                  //             style: TextStyle(
                  //               fontSize: 12,
                  //               color: Colors.green.shade600,
                  //             ),
                  //           ),
                  //         ],
                  //       ],
                  //     ),
                  //   ),
                  // ],

                  // SizedBox(height: 20),

                  // Feeding Frequency Section
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
                          "🍽️ Feeding Frequency",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "How often do you feed your pet? 🕐",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: 15),
                        Column(
                          children: feedingFrequencies.map((feeding) {
                            bool isSelected = selectedFeedingFrequency == feeding['frequency'];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedFeedingFrequency = feeding['frequency'];
                                });
                              },
                              child: Container(
                                width: double.infinity,
                                margin: EdgeInsets.only(bottom: 10),
                                padding: EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.orange.shade50 : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? Colors.orange.shade400 : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      feeding['icon'],
                                      style: TextStyle(fontSize: 25),
                                    ),
                                    SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            feeding['frequency'],
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected ? Colors.orange.shade600 : Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            feeding['description'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          Text(
                                            feeding['timeDescription'],
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500,
                                              fontStyle: FontStyle.italic,
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
                        if (selectedFeedingFrequency.isNotEmpty) ...[
                          SizedBox(height: 10),
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.orange.shade600, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  "Selected: $selectedFeedingFrequency",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: 30),

                  // Continue Button
                  Center(
                    child: ElevatedButton(
                      onPressed: continueToNextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appBarColor,
                        minimumSize: Size(280, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              "Continue to Basic Details 🐾",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: subTextColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: subTextColor,
                            size: 24,
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
    );
  }
}
