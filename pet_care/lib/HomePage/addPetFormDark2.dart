import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:pet_care/ColorsScheme.dart';
import 'package:pet_care/HomePage/addPetFormDark3.dart';
import 'package:pet_care/widgets/step_progress_indicator.dart';
import 'package:pet_care/widgets/pet_background_pattern.dart';

class addPetFormDark2 extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Map<String, dynamic> petData;
  
  const addPetFormDark2({super.key, required this.userData, required this.petData});

  @override
  State<addPetFormDark2> createState() => _addPetFormDark2State();
}

class _addPetFormDark2State extends State<addPetFormDark2> {
  bool showSpinner = false;
  
  // Weight related variables
  TextEditingController weightController = TextEditingController();
  String selectedWeightUnit = 'kg';
  
  // Health Goal related variables
  List<String> selectedHealthGoals = [];
  Map<String, int> healthGoalPriorities = {}; // Store priorities for health goals
  TextEditingController customHealthGoalController = TextEditingController();
  int customHealthGoalPriority = 1; // Priority for custom health goal
  List<Map<String, String>> customHealthGoals = []; // Store custom health goals
  
  final List<Map<String, dynamic>> healthGoals = [
    {'name': 'Diet', 'icon': '🍽️', 'isSelected': false},
    {'name': 'Senior Care', 'icon': '👴', 'isSelected': false},
    {'name': 'Joint Care', 'icon': '🦴', 'isSelected': false},
    {'name': 'Muscle Building', 'icon': '💪', 'isSelected': false},
    {'name': 'Skin Care', 'icon': '✨', 'isSelected': false},
  ];

  @override
  void initState() {
    super.initState();
  }

  void toggleHealthGoal(int index) {
    setState(() {
      healthGoals[index]['isSelected'] = !healthGoals[index]['isSelected'];
      
      if (healthGoals[index]['isSelected']) {
        selectedHealthGoals.add(healthGoals[index]['name']);
        // Assign priority based on selection order if not already set
        if (!healthGoalPriorities.containsKey(healthGoals[index]['name'])) {
          healthGoalPriorities[healthGoals[index]['name']] = selectedHealthGoals.length;
        }
      } else {
        selectedHealthGoals.remove(healthGoals[index]['name']);
        healthGoalPriorities.remove(healthGoals[index]['name']);
        // Reassign priorities to maintain order
        _reassignPriorities();
      }
    });
  }

  void _reassignPriorities() {
    Map<String, int> newPriorities = {};
    for (int i = 0; i < selectedHealthGoals.length; i++) {
      newPriorities[selectedHealthGoals[i]] = i + 1;
    }
    healthGoalPriorities = newPriorities;
  }

  void updateHealthGoalPriority(String goalName, int newPriority) {
    setState(() {
      if (newPriority >= 1 && newPriority <= getTotalSelectedGoals()) {
        healthGoalPriorities[goalName] = newPriority;
        _sortHealthGoalsByPriority();
      }
    });
  }

  void _sortHealthGoalsByPriority() {
    selectedHealthGoals.sort((a, b) {
      int priorityA = healthGoalPriorities[a] ?? 999;
      int priorityB = healthGoalPriorities[b] ?? 999;
      return priorityA.compareTo(priorityB);
    });
  }

  int getTotalSelectedGoals() {
    int total = selectedHealthGoals.length;
    if (customHealthGoalController.text.isNotEmpty) {
      total += 1;
    }
    return total;
  }

  void addCustomHealthGoal() {
    if (customHealthGoalController.text.trim().isEmpty) {
      showErrorSnackBar('Please enter a health goal 📝');
      return;
    }

    final healthGoal = customHealthGoalController.text.trim();
    
    // Check if already exists in selected health goals
    if (selectedHealthGoals.contains(healthGoal)) {
      showErrorSnackBar('${healthGoal} is already selected 📋');
      return;
    }
    
    // Check if already exists in custom health goals
    if (customHealthGoals.any((goal) => goal['goal']?.toLowerCase() == healthGoal.toLowerCase())) {
      showErrorSnackBar('${healthGoal} is already added 📋');
      return;
    }

    setState(() {
      customHealthGoals.add({
        'goal': healthGoal,
      });
      // Also add to selected health goals with default priority
      selectedHealthGoals.add(healthGoal);
      healthGoalPriorities[healthGoal] = selectedHealthGoals.length; // Default priority
      customHealthGoalController.clear();
    });

    showSuccessSnackBar('Health goal "${healthGoal}" added successfully! 🎯');
  }

  void removeCustomHealthGoal(int index) {
    if (index >= 0 && index < customHealthGoals.length) {
      final goalToRemove = customHealthGoals[index]['goal'];
      setState(() {
        customHealthGoals.removeAt(index);
        // Also remove from selected health goals and priorities
        selectedHealthGoals.remove(goalToRemove);
        healthGoalPriorities.remove(goalToRemove);
      });
      showSuccessSnackBar('Health goal removed successfully! ✅');
    }
  }

  void toggleCustomHealthGoal(String goalName) {
    setState(() {
      if (selectedHealthGoals.contains(goalName)) {
        // Remove from selected
        selectedHealthGoals.remove(goalName);
        healthGoalPriorities.remove(goalName);
      } else {
        // Add to selected with appropriate priority
        selectedHealthGoals.add(goalName);
        healthGoalPriorities[goalName] = selectedHealthGoals.length;
      }
      // Re-normalize priorities
      _reorderPriorities();
    });
  }

  void _reorderPriorities() {
    int priority = 1;
    for (String goal in selectedHealthGoals) {
      healthGoalPriorities[goal] = priority++;
    }
  }

  void showSuccessSnackBar(String message) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: 'Success! 🎉',
        message: message,
        contentType: ContentType.success,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  String _getHealthGoalIcon(String goalName) {
    // Try to find in predefined health goals first
    try {
      final predefinedGoal = healthGoals.firstWhere((goal) => goal['name'] == goalName);
      return predefinedGoal['icon'] ?? '🎯';
    } catch (e) {
      // If not found (likely a custom health goal), return default icon
      return '🎯';
    }
  }

  bool validateForm() {
    if (weightController.text.isEmpty) {
      showErrorSnackBar('Please enter your pet\'s weight 📏');
      return false;
    }
    
    double? weight = double.tryParse(weightController.text);
    if (weight == null || weight <= 0) {
      showErrorSnackBar('Please enter a valid weight 🔢');
      return false;
    }
    
    if (selectedHealthGoals.isEmpty && customHealthGoalController.text.isEmpty) {
      showErrorSnackBar('Please select at least one health goal 🎯');
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
        contentType: ContentType.warning,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void continueToNextPage() {
    if (!validateForm()) return;
    
    setState(() {
      showSpinner = true;
    });

    // Add the new data to petData
    Map<String, dynamic> updatedPetData = Map.from(widget.petData);
    updatedPetData['weight'] = weightController.text;
    updatedPetData['weightUnit'] = selectedWeightUnit;
    updatedPetData['healthGoals'] = selectedHealthGoals;
    updatedPetData['healthGoalPriorities'] = healthGoalPriorities;
    
    // Add custom health goals
    if (customHealthGoals.isNotEmpty) {
      updatedPetData['customHealthGoals'] = customHealthGoals;
    }
    
    if (customHealthGoalController.text.isNotEmpty) {
      updatedPetData['customHealthGoal'] = customHealthGoalController.text;
      updatedPetData['customHealthGoalPriority'] = customHealthGoalPriority;
    }

    setState(() {
      showSpinner = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => addPetFormDark3(
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
          "Pet Details 📊",
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
                    currentStep: 2,
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
                          "🎯 Let's set up ${widget.petData['Name']}'s health profile!",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: subTextColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          "This helps us provide personalized care recommendations 💝",
                          style: TextStyle(
                            fontSize: 14,
                            color: subTextColor.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Weight Section
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
                              "⚖️ Weight",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Spacer(),
                            Text(
                              "Required",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: weightController,
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: "⚖️ Enter weight",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  prefixIcon: Icon(Icons.monitor_weight),
                                ),
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              flex: 1,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey.shade400),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedWeightUnit,
                                    isExpanded: true,
                                    items: ['kg', 'lbs'].map((String unit) {
                                      return DropdownMenuItem<String>(
                                        value: unit,
                                        child: Text(
                                          unit,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        selectedWeightUnit = newValue!;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Health Goals Section
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
                              "🎯 Health Goals",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Spacer(),
                            Text(
                              "Select any",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 15),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 2.5,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: healthGoals.length,
                          itemBuilder: (context, index) {
                            final goal = healthGoals[index];
                            final isSelected = goal['isSelected'];
                            
                            return GestureDetector(
                              onTap: () => toggleHealthGoal(index),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? appBarColor : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? appBarColor : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        goal['icon'],
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          goal['name'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                            color: isSelected ? Colors.white : Colors.black87,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 20),
                        
                        // Priority Settings Section (only show when multiple goals are selected)
                        if (getTotalSelectedGoals() > 1) ...[
                          Container(
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.priority_high, color: Colors.blue.shade700, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      "Priority Settings",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Set priority for your selected health goals (1 = highest priority)",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                                SizedBox(height: 15),
                                
                                // Priority list for selected goals
                                ...selectedHealthGoals.asMap().entries.map((entry) {
                                  String goalName = entry.value;
                                  int currentPriority = healthGoalPriorities[goalName] ?? 1;
                                  
                                  return Container(
                                    margin: EdgeInsets.only(bottom: 10),
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Row(
                                      children: [
                                        // Goal icon and name
                                        Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: appBarColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          child: Center(
                                            child: Text(
                                              _getHealthGoalIcon(goalName),
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            goalName,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        
                                        // Priority selector
                                        Text(
                                          "Priority:",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey.shade300),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<int>(
                                              value: currentPriority,
                                              items: List.generate(getTotalSelectedGoals(), (index) {
                                                return DropdownMenuItem<int>(
                                                  value: index + 1,
                                                  child: Text(
                                                    "${index + 1}",
                                                    style: TextStyle(fontSize: 14),
                                                  ),
                                                );
                                              }),
                                              onChanged: (int? newPriority) {
                                                if (newPriority != null) {
                                                  updateHealthGoalPriority(goalName, newPriority);
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                        ],
                        
                        // Enhanced Custom health goals section
                        Text(
                          "✨ Other Health Goals",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 10),
                        
                        // Add custom health goal row
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                          controller: customHealthGoalController,
                          decoration: InputDecoration(
                                  hintText: 'Add custom health goal',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Icon(Icons.edit_note),
                          ),
                          style: TextStyle(fontSize: 14),
                        ),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: addCustomHealthGoal,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade400,
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Icon(
                                Icons.add,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        
                        // Display custom health goals
                        if (customHealthGoals.isNotEmpty) ...[
                          SizedBox(height: 12),
                          Text(
                            'Custom Health Goals:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: customHealthGoals.asMap().entries.map((entry) {
                              int index = entry.key;
                              Map<String, String> healthGoal = entry.value;
                              String goalName = healthGoal['goal'] ?? '';
                              bool isSelected = selectedHealthGoals.contains(goalName);
                              int priority = healthGoalPriorities[goalName] ?? 0;
                              String priorityIcon = priority == 1 ? '🥇' : priority == 2 ? '🥈' : priority == 3 ? '🥉' : '🎯';
                              
                              return GestureDetector(
                                onTap: () {
                                  toggleCustomHealthGoal(goalName);
                                },
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.85,
                                  ),
                                  margin: EdgeInsets.only(bottom: 8),
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                        ? Colors.green.withOpacity(0.3)
                                        : Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected 
                                          ? Colors.green.shade400 
                                          : Colors.green.shade300,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        priorityIcon,
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              goalName,
                                              style: TextStyle(
                                                color: Colors.black87,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                            ),
                                            // Priority dropdown for custom health goals
                                            if (isSelected && selectedHealthGoals.length > 1) ...[
                                              SizedBox(height: 4),
                                              Container(
                                                height: 25,
                                                padding: EdgeInsets.symmetric(horizontal: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.8),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: Colors.green.shade300),
                                                ),
                                                child: DropdownButton<int>(
                                                  value: priority > 0 ? priority : 1,
                                                  underline: SizedBox(),
                                                  style: TextStyle(fontSize: 10, color: Colors.black87),
                                                  items: List.generate(selectedHealthGoals.length, (index) => index + 1)
                                                      .map((priorityValue) => DropdownMenuItem<int>(
                                                          value: priorityValue,
                                                          child: Text(
                                                            'Priority $priorityValue',
                                                            style: TextStyle(fontSize: 10, color: Colors.black87),
                                                          )))
                                                      .toList(),
                                                  onChanged: (newPriority) {
                                                    if (newPriority != null) {
                                                      updateHealthGoalPriority(goalName, newPriority);
                                                    }
                                                  },
                                                  isDense: true,
                                                  isExpanded: true,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => removeCustomHealthGoal(index),
                                        child: Icon(
                                          Icons.close,
                                          size: 18,
                                          color: Colors.green.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
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
                              "Continue to Preferences 🍽️",
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
