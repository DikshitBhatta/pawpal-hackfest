import 'dart:io';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:lottie/lottie.dart';
import 'package:pet_care/ColorsScheme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pet_care/AIScreen/AIMealPlanScreen.dart';
import 'package:pet_care/widgets/pet_background_pattern.dart';
import 'package:pet_care/utils/app_icons.dart';
import 'package:pet_care/services/image_compression_service.dart';

class EditPetForm extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Map<String, dynamic> petData;
  
  const EditPetForm({super.key, required this.userData, required this.petData});

  @override
  State<EditPetForm> createState() => _EditPetFormState();
}

class _EditPetFormState extends State<EditPetForm> {
  bool showSpinner = false;

  // Pet basic info controllers
  late TextEditingController petNameController;
  late TextEditingController oneLineController;
  late TextEditingController breedController;
  late TextEditingController weightController;
  late TextEditingController customHealthGoalController;
  late TextEditingController customAllergyController;
  late TextEditingController customAllergyBrandController;
  late TextEditingController customFavoriteController;
  late TextEditingController customFavoriteBrandController;
  late TextEditingController healthNotesController;
  
  DateTime date = DateTime.now();
  String dateOfBirthController = "";
  String dropdownvalue = 'Dog'; // Default to Dog since it's a dog-only app
  File? pickedImage;
  String selectedCategory = "Dog"; // Default to Dog since it's a dog-only app
  String selectedWeightUnit = 'kg';
  String selectedActivityLevel = '';
  int selectedPoopStatusIndex = 2; // Default to Normal (index 2, level 3)
  
  // Gender and physical characteristics
  String selectedGender = '';
  String selectedNeuteredStatus = 'No';
  String selectedBodyCondition = 'Normal';
  
  // Poop details
  String selectedPoopColor = '';
  String selectedPoopFrequency = '';
  String selectedPoopQuantity = '';
  
  // Daily activity minutes
  late TextEditingController dailyActivityMinutesController;
  
  // Lists for multi-select
  List<String> selectedHealthGoals = [];
  List<String> selectedAllergies = [];
  List<String> selectedFavorites = [];
  
  // Priority system for health goals (same as addPetFormDark2)
  Map<String, int> healthGoalPriorities = {};
  
  // Custom items (similar to add forms)
  List<Map<String, String>> customAllergies = [];
  List<Map<String, String>> customFavorites = [];
  List<Map<String, String>> customHealthGoals = [];
  
  // Feeding frequency (from addPetFormDark3)
  String selectedFeedingFrequency = '';
  
  // Poop status options
  final List<Map<String, dynamic>> poopStatus = [
    {'emoji': '🪨', 'description': 'Very Hard', 'color': Colors.brown.shade900},
    {'emoji': '🪨', 'description': 'Hard', 'color': Colors.brown.shade700},
    {'emoji': '💩', 'description': 'Normal', 'color': Colors.brown.shade500},
    {'emoji': '💧', 'description': 'Soft', 'color': Colors.brown.shade300},
    {'emoji': '💧', 'description': 'Very Soft', 'color': Colors.orange.shade400},
  ];
  
  // Medical file
  PlatformFile? pickedMedicalFile;
  bool isMedicalFileUploaded = false;

  // Remove cat breeds since this is a dog-only app
  var dogValue = [
    'Dog', 'Labrador Retriever', 'German Shepherd', 'Golden Retriever', 'Bulldog',
    'Beagle', 'Poodle', 'French Bulldog', 'Rottweiler', 'Siberian Husky', 'Border Collie',
    'Australian Shepherd', 'Yorkshire Terrier', 'Dachshund', 'Boxer', 'Chihuahua', 'Mixed Breed'
  ];

  final List<Map<String, dynamic>> healthGoals = [
    {'name': 'Diet', 'icon': '🍽️', 'isSelected': false},
    {'name': 'Senior Care', 'icon': '👴', 'isSelected': false},
    {'name': 'Joint Care', 'icon': '🦴', 'isSelected': false},
    {'name': 'Digestive Health', 'icon': '🫃', 'isSelected': false},
    {'name': 'Skin & Coat', 'icon': '✨', 'isSelected': false},
    {'name': 'Energy & Vitality', 'icon': '⚡', 'isSelected': false},
    {'name': 'Senior Care', 'icon': '👴', 'isSelected': false},
    {'name': 'Muscle Building', 'icon': '💪', 'isSelected': false},
    {'name': 'Skin Care', 'icon': '✨', 'isSelected': false},
  ];

  final List<Map<String, dynamic>> commonAllergies = [
    {'name': 'Chicken', 'icon': '🐔', 'isSelected': false},
    {'name': 'Beef', 'icon': '🥩', 'isSelected': false},
    {'name': 'Dairy', 'icon': '🥛', 'isSelected': false},
    {'name': 'Fish', 'icon': '🐟', 'isSelected': false},
    {'name': 'Grains', 'icon': '🌾', 'isSelected': false},
    {'name': 'Soy', 'icon': '🫘', 'isSelected': false},
    {'name': 'None', 'icon': '✅', 'isSelected': false},
  ];

  final List<Map<String, dynamic>> favoriteFoods = [
    {'name': 'Chicken', 'icon': '🐔', 'isSelected': false},
    {'name': 'Turkey', 'icon': '🦃', 'isSelected': false},
    {'name': 'Salmon', 'icon': '🐟', 'isSelected': false},
    {'name': 'Beef', 'icon': '🥩', 'isSelected': false},
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

  // final List<Map<String, dynamic>> poopStatus = [
  //   {'level': 1, 'description': 'Very Hard', 'color': Colors.brown.shade800, 'emoji': '🪨'},
  //   {'level': 2, 'description': 'Hard', 'color': Colors.brown.shade600, 'emoji': '🪨'},
  //   {'level': 3, 'description': 'Normal', 'color': Colors.brown.shade400, 'emoji': '�'},
  //   {'level': 4, 'description': 'Soft', 'color': Colors.brown.shade300, 'emoji': '�'},
  //   {'level': 5, 'description': 'Very Soft', 'color': Colors.brown.shade200, 'emoji': '�'},
  // ];

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
    _initializeWithExistingData();
  }

  void _initializeWithExistingData() {
    // Initialize controllers with existing data
    petNameController = TextEditingController(text: widget.petData['Name'] ?? '');
    oneLineController = TextEditingController(text: widget.petData['oneLine'] ?? '');
    breedController = TextEditingController(text: widget.petData['Breed'] ?? '');
    weightController = TextEditingController(text: widget.petData['weight']?.toString() ?? '');
    customHealthGoalController = TextEditingController(text: widget.petData['customHealthGoal'] ?? '');
    
    // Initialize brand controllers
    customAllergyBrandController = TextEditingController();
    customFavoriteBrandController = TextEditingController();
    
    // Handle custom allergies - can be either string or List<Map<String, String>>
    if (widget.petData['customAllergies'] is List) {
      customAllergies = List<Map<String, String>>.from(
        (widget.petData['customAllergies'] as List).map((item) => Map<String, String>.from(item))
      );
      customAllergyController = TextEditingController();
    } else {
      customAllergyController = TextEditingController(text: widget.petData['customAllergies']?.toString() ?? '');
      customAllergies = [];
    }
    
    // Handle custom favorites - can be either string or List<Map<String, String>>
    if (widget.petData['customFavorites'] is List) {
      customFavorites = List<Map<String, String>>.from(
        (widget.petData['customFavorites'] as List).map((item) => Map<String, String>.from(item))
      );
      customFavoriteController = TextEditingController();
    } else {
      customFavoriteController = TextEditingController(text: widget.petData['customFavorites']?.toString() ?? '');
      customFavorites = [];
    }
    
    // Handle custom health goals - new functionality
    if (widget.petData['customHealthGoals'] is List) {
      customHealthGoals = List<Map<String, String>>.from(
        (widget.petData['customHealthGoals'] as List).map((item) => Map<String, String>.from(item))
      );
    } else {
      customHealthGoals = [];
    }
    customHealthGoalController = TextEditingController();
    
    healthNotesController = TextEditingController(text: widget.petData['healthNotes'] ?? '');
    
    // Set category and breed (always Dog since this is a dog-only app)
    selectedCategory = "Dog";
    dropdownvalue = widget.petData['Breed'] ?? 'Dog';
    
    // Set weight unit
    selectedWeightUnit = widget.petData['weightUnit'] ?? 'kg';
    
    // Set activity level
    selectedActivityLevel = widget.petData['activityLevel'] ?? '';
    
    // Set poop status
    selectedPoopStatusIndex = (double.tryParse(widget.petData['poopStatus']?.toString() ?? '3.0') ?? 3.0).round() - 1;
    
    // Set date of birth
    dateOfBirthController = widget.petData['DateOfBirth'] ?? '';
    if (dateOfBirthController.isNotEmpty) {
      try {
        List<String> dateParts = dateOfBirthController.split('/');
        if (dateParts.length == 3) {
          date = DateTime(int.parse(dateParts[2]), int.parse(dateParts[1]), int.parse(dateParts[0]));
        }
      } catch (e) {
        print('Error parsing date: $e');
      }
    }
    
    // Initialize health goals and priorities
    if (widget.petData['healthGoals'] != null) {
      selectedHealthGoals = List<String>.from(widget.petData['healthGoals']);
      // Reset all health goals first
      for (int i = 0; i < healthGoals.length; i++) {
        healthGoals[i]['isSelected'] = false;
      }
      // Then mark selected ones
      for (int i = 0; i < healthGoals.length; i++) {
        healthGoals[i]['isSelected'] = selectedHealthGoals.contains(healthGoals[i]['name']);
      }
    } else {
      selectedHealthGoals = [];
      // Ensure all are unselected
      for (int i = 0; i < healthGoals.length; i++) {
        healthGoals[i]['isSelected'] = false;
      }
    }
    
    // Initialize health goal priorities
    if (widget.petData['healthGoalPriorities'] != null) {
      healthGoalPriorities = Map<String, int>.from(widget.petData['healthGoalPriorities']);
    }
    
    // Initialize feeding frequency
    selectedFeedingFrequency = widget.petData['feedingFrequency'] ?? '';
    
    // Initialize allergies
    if (widget.petData['allergies'] != null) {
      selectedAllergies = List<String>.from(widget.petData['allergies']);
      // Reset all allergies first
      for (int i = 0; i < commonAllergies.length; i++) {
        commonAllergies[i]['isSelected'] = false;
      }
      // Then mark selected ones
      for (int i = 0; i < commonAllergies.length; i++) {
        commonAllergies[i]['isSelected'] = selectedAllergies.contains(commonAllergies[i]['name']);
      }
    } else {
      selectedAllergies = [];
      // Ensure all are unselected
      for (int i = 0; i < commonAllergies.length; i++) {
        commonAllergies[i]['isSelected'] = false;
      }
    }
    
    // Initialize favorites
    if (widget.petData['favorites'] != null) {
      selectedFavorites = List<String>.from(widget.petData['favorites']);
      // Reset all favorites first
      for (int i = 0; i < favoriteFoods.length; i++) {
        favoriteFoods[i]['isSelected'] = false;
      }
      // Then mark selected ones
      for (int i = 0; i < favoriteFoods.length; i++) {
        favoriteFoods[i]['isSelected'] = selectedFavorites.contains(favoriteFoods[i]['name']);
      }
    } else {
      selectedFavorites = [];
      // Ensure all are unselected
      for (int i = 0; i < favoriteFoods.length; i++) {
        favoriteFoods[i]['isSelected'] = false;
      }
    }
    
    // Initialize gender and physical characteristics
    selectedGender = widget.petData['gender'] ?? '';
    selectedNeuteredStatus = widget.petData['neuteredStatus'] ?? 'No';
    selectedBodyCondition = widget.petData['bodyCondition'] ?? 'Normal';
    
    // Initialize poop details
    selectedPoopColor = widget.petData['poopColor'] ?? '';
    selectedPoopFrequency = widget.petData['poopFrequency'] ?? '';
    selectedPoopQuantity = widget.petData['poopQuantity'] ?? '';
    
    // Initialize daily activity minutes controller
    dailyActivityMinutesController = TextEditingController(
      text: widget.petData['dailyActivityMinutes']?.toString() ?? ''
    );
  }

  @override
  void dispose() {
    petNameController.dispose();
    oneLineController.dispose();
    breedController.dispose();
    weightController.dispose();
    customHealthGoalController.dispose();
    customAllergyController.dispose();
    customAllergyBrandController.dispose();
    customFavoriteController.dispose();
    customFavoriteBrandController.dispose();
    healthNotesController.dispose();
    dailyActivityMinutesController.dispose();
    super.dispose();
  }

  Future<void> selectDate() async {
    DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (newDate != null) {
      setState(() {
        date = newDate;
        dateOfBirthController = "${date.day}/${date.month}/${date.year}";
      });
    }
  }

  Future<void> pickImageFromGallery() async {
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
          pickedImage = File(image.path);
        });
        showSuccessSnackBar('📸 Perfect photo! Your pet looks amazing! 🌟');
      }
    } catch (e) {
      showErrorSnackBar('Error selecting image: $e');
    }
  }

  Future<void> pickMedicalFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          pickedMedicalFile = result.files.first;
          isMedicalFileUploaded = true;
        });
        showSuccessSnackBar('📄 Medical file ready! ${pickedMedicalFile!.name} 🏥');
      }
    } catch (e) {
      showErrorSnackBar('Error selecting file: $e');
    }
  }

  void toggleHealthGoal(int index) {
    setState(() {
      healthGoals[index]['isSelected'] = !healthGoals[index]['isSelected'];
      
      if (healthGoals[index]['isSelected']) {
        selectedHealthGoals.add(healthGoals[index]['name']);
        // Set default priority when adding a health goal
        healthGoalPriorities[healthGoals[index]['name']] = selectedHealthGoals.length;
      } else {
        selectedHealthGoals.remove(healthGoals[index]['name']);
        healthGoalPriorities.remove(healthGoals[index]['name']);
        // Reorder priorities for remaining goals
        _reorderPriorities();
      }
    });
  }

  void updateHealthGoalPriority(String goalName, int priority) {
    setState(() {
      if (selectedHealthGoals.contains(goalName)) {
        healthGoalPriorities[goalName] = priority;
      }
    });
  }

  void _reorderPriorities() {
    int priority = 1;
    for (String goal in selectedHealthGoals) {
      healthGoalPriorities[goal] = priority++;
    }
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

  void removeCustomAllergy(int index) {
    setState(() {
      customAllergies.removeAt(index);
    });
  }

  void removeCustomFavorite(int index) {
    setState(() {
      customFavorites.removeAt(index);
    });
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

    showSuccessSnackBar('Health goal "${healthGoal}" added and selected! Tap to toggle priority! 🎯');
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

  // Helper methods to check conflicts
  bool isIngredientInFavorites(String ingredient) {
    return selectedFavorites.contains(ingredient) ||
        customFavorites.any((fav) => fav['ingredient']?.toLowerCase() == ingredient.toLowerCase());
  }

  bool isIngredientInAllergies(String ingredient) {
    return selectedAllergies.contains(ingredient) ||
        customAllergies.any((allergy) => allergy['ingredient']?.toLowerCase() == ingredient.toLowerCase());
  }

  bool validateForm() {
    if (petNameController.text.isEmpty) {
      showErrorSnackBar('Please enter your pet\'s name 🐾');
      return false;
    }
    
    if (dateOfBirthController.isEmpty) {
      showErrorSnackBar('Please select date of birth 📅');
      return false;
    }
    
    if (weightController.text.isEmpty) {
      showErrorSnackBar('Please enter your pet\'s weight 📏');
      return false;
    }
    
    double? weight = double.tryParse(weightController.text);
    if (weight == null || weight <= 0) {
      showErrorSnackBar('Please enter a valid weight 🔢');
      return false;
    }
    
    if (selectedActivityLevel.isEmpty) {
      showErrorSnackBar('Please select activity level 🏃');
      return false;
    }
    
    if (selectedGender.isEmpty) {
      showErrorSnackBar('Please select your pet\'s gender 🐕');
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
    
    // Validate daily activity minutes if provided
    if (dailyActivityMinutesController.text.isNotEmpty) {
      int? minutes = int.tryParse(dailyActivityMinutesController.text);
      if (minutes == null || minutes < 0 || minutes > 1440) {
        showErrorSnackBar('Please enter valid activity minutes (0-1440) ⏰');
        return false;
      }
    }
    
    return true;
  }

  Future<void> updatePetData() async {
    if (!validateForm()) return;
    
    setState(() {
      showSpinner = true;
    });

    try {
      // Create updated pet data
      Map<String, dynamic> updatedPetData = Map.from(widget.petData);
      
      // Update basic info
      updatedPetData['Name'] = petNameController.text;
      updatedPetData['oneLine'] = oneLineController.text;
      updatedPetData['Breed'] = breedController.text;
      updatedPetData['Category'] = "Dog"; // Always Dog since this is a dog-only app
      updatedPetData['DateOfBirth'] = dateOfBirthController;
      updatedPetData['weight'] = weightController.text;
      updatedPetData['weightUnit'] = selectedWeightUnit;
      updatedPetData['activityLevel'] = selectedActivityLevel;
      updatedPetData['poopStatus'] = (selectedPoopStatusIndex + 1).toString();
      updatedPetData['poopDescription'] = getPoopDescription(selectedPoopStatusIndex);
      
      // Update gender and physical characteristics
      updatedPetData['gender'] = selectedGender;
      updatedPetData['neuteredStatus'] = selectedNeuteredStatus;
      updatedPetData['bodyCondition'] = selectedBodyCondition;
      
      // Update poop details
      updatedPetData['poopColor'] = selectedPoopColor;
      updatedPetData['poopFrequency'] = selectedPoopFrequency;
      updatedPetData['poopQuantity'] = selectedPoopQuantity;
      
      // Update daily activity minutes
      if (dailyActivityMinutesController.text.isNotEmpty) {
        updatedPetData['dailyActivityMinutes'] = int.tryParse(dailyActivityMinutesController.text) ?? 0;
      }
      
      // Update health goals and priorities
      updatedPetData['healthGoals'] = selectedHealthGoals;
      updatedPetData['healthGoalPriorities'] = healthGoalPriorities;
      if (customHealthGoalController.text.isNotEmpty) {
        updatedPetData['customHealthGoal'] = customHealthGoalController.text;
      }
      
      // Update feeding frequency
      updatedPetData['feedingFrequency'] = selectedFeedingFrequency;
      
      // Update allergies
      updatedPetData['allergies'] = selectedAllergies;
      if (customAllergies.isNotEmpty) {
        updatedPetData['customAllergies'] = customAllergies;
      } else if (customAllergyController.text.isNotEmpty) {
        updatedPetData['customAllergies'] = customAllergyController.text;
      }
      
      // Update favorites
      updatedPetData['favorites'] = selectedFavorites;
      if (customFavorites.isNotEmpty) {
        updatedPetData['customFavorites'] = customFavorites;
      } else if (customFavoriteController.text.isNotEmpty) {
        updatedPetData['customFavorites'] = customFavoriteController.text;
      }
      
      // Update custom health goals
      if (customHealthGoals.isNotEmpty) {
        updatedPetData['customHealthGoals'] = customHealthGoals;
      }
      
      // Update health notes
      if (healthNotesController.text.isNotEmpty) {
        updatedPetData['healthNotes'] = healthNotesController.text;
      }

      // Handle image update
      if (pickedImage != null) {
        try {
          String? base64Image = await convertImageToBase64(pickedImage!);
          if (base64Image != null && base64Image.isNotEmpty) {
            if (base64Image == "placeholder_image") {
              showErrorSnackBar('Image was too large. Keeping existing image. 📸');
            } else {
              updatedPetData["Photo"] = base64Image;
            }
          }
        } catch (e) {
          print('Error processing image: $e');
          showErrorSnackBar('Error processing image. Keeping existing image. 📸');
        }
      }

      // Handle medical file update
      if (pickedMedicalFile != null) {
        updatedPetData["MedicalFile"] = "medical_file_${pickedMedicalFile!.name}";
      }

      // Update timestamp
      updatedPetData['lastUpdated'] = DateTime.now().toIso8601String();

      // Update in Firestore
      var db = FirebaseFirestore.instance;
      String petId = widget.petData['petId'];
      String userEmail = widget.userData["Email"];
      
      await db.collection(userEmail).doc(petId).update(updatedPetData);
      
      setState(() {
        showSpinner = false;
      });

      showSuccessSnackBar('🎉 Your pet\'s info is all updated! Great job! �');
      
      // Navigate back with updated data
      Navigator.pop(context, updatedPetData);
      
    } catch (e) {
      setState(() {
        showSpinner = false;
      });
      print('Error updating pet: $e');
      showErrorSnackBar('Failed to update pet information. Please try again.');
    }
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
        contentType: ContentType.failure,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void showSuccessSnackBar(String message) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: '✅ Done! 🐾 Thank you!',
        message: message,
        contentType: ContentType.success,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Get a shortened version of the pet name to prevent overflow
  String _getShortPetName() {
    String fullName = petNameController.text.isEmpty 
        ? (widget.petData['Name'] ?? 'Your Pet') 
        : petNameController.text;
    
    // If name is short enough, return as is
    if (fullName.length <= 10) {
      return fullName;
    }
    
    // Split by spaces and take first name only
    List<String> nameParts = fullName.split(' ');
    String firstName = nameParts.first;
    
    // If first name is still too long, truncate it
    if (firstName.length > 8) {
      return firstName.substring(0, 8) + '...';
    }
    
    return firstName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Edit ${(widget.petData['Name'] ?? 'Pet').length > 10 ? (widget.petData['Name'] ?? 'Pet').split(' ').first : (widget.petData['Name'] ?? 'Pet')} 🐾",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: listTileColorSecond),
        ),
        leading: IconButton(
          icon: AppIcons.backIcon(),
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
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Information Section
                      _buildSectionHeader('Basic Information', AppIcons.petIcon().icon!),
                      _buildBasicInfoSection(),
                      SizedBox(height: 30),
                      // Weight & Health Goals Section
                      _buildSectionHeader('Health & Fitness', AppIcons.fitnessIcon().icon!),
                      _buildWeightAndHealthSection(),
                      SizedBox(height: 30),
                      // Food Preferences Section
                      _buildSectionHeader('Food Preferences', AppIcons.mealIcon().icon!),
                      _buildFoodPreferencesSection(),
                      SizedBox(height: 30),
                      // Physical Characteristics Section
                      _buildSectionHeader('Physical Characteristics', AppIcons.petIcon().icon!),
                      _buildPhysicalCharacteristicsSection(),
                      SizedBox(height: 30),
                      // Activity & Health Status Section
                      _buildSectionHeader('Activity & Health Status', AppIcons.heartIcon().icon!),
                      _buildActivityAndHealthSection(),
                      SizedBox(height: 30),
                      // Enhanced AI Meal Preview Button
                      _buildEnhancedAIMealPreviewButton(),
                      SizedBox(height: 20),
                      // Update Button
                      Container(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: updatePetData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonColor,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 5,
                          ),
                          child: Text(
                            'Update Pet Information',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            if (showSpinner)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Lottie.asset(
                    'assets/Animations/AnimalcareLoading.json',
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build Enhanced AI Meal Preview Button
  Widget _buildEnhancedAIMealPreviewButton() {
    String displayName = _getShortPetName();

    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _showMealPreviewDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple.shade600, // Purple theme for AI
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: Colors.purple.withOpacity(0.4),
        ).copyWith(
          backgroundColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed)) {
                return Colors.purple.shade700;
              }
              if (states.contains(MaterialState.hovered)) {
                return Colors.purple.shade500;
              }
              return Colors.purple.shade600;
            },
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: AppIcons.petFoodIcon(
                size: 18, 
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'AI Meal Preview for ${displayName}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 12,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'AI',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show meal preview dialog
  void _showMealPreviewDialog() {
    String displayName = _getShortPetName();

    // Get current activity level for sample
    String activityLevel = selectedActivityLevel.isEmpty 
        ? (widget.petData['activityLevel'] ?? 'Medium') 
        : selectedActivityLevel;
    
    // Get current weight for sample
    String weight = weightController.text.isEmpty 
        ? (widget.petData['weight']?.toString() ?? '25') 
        : weightController.text;
    String weightUnit = selectedWeightUnit;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              minHeight: 200,
            ),
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade50, Colors.blue.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.purple.shade200, width: 1.5),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with close button
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: AppIcons.petFoodIcon(
                          color: Colors.purple.shade600,
                          size: 18,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sample Meal Plan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade800,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Text(
                              'Based on current form data',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.purple.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: AppIcons.cancelIcon(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Sample meal details
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.purple.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.shade100,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildMealDetailRow('🍖', 'Protein', 'Chicken & Turkey'),
                        SizedBox(height: 12),
                        _buildMealDetailRow('🥕', 'Vegetables', 'Carrots & Sweet Potato'),
                        SizedBox(height: 12),
                        _buildMealDetailRow('🌾', 'Grains', 'Brown Rice'),
                        SizedBox(height: 12),
                        _buildMealDetailRow('⚖️', 'Portion', '${weight}${weightUnit} dog - ${activityLevel} activity'),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Info note
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade600,
                          size: 18,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This is a sample preview. The full AI meal plan will use your current form changes including any updated allergies, preferences, and health information.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Generate AI Meal Plan button
                  Container(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog first
                        _navigateToAIMealPlanner();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade500,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                      ),
                      
                      label: Text(
                        'Generate Full AI Meal Plan 🤖',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Navigate to AI meal planner with current form data
  void _navigateToAIMealPlanner() {
    // Get current form data with all updates from the form
    Map<String, dynamic> currentData = _getCurrentFormData();
    
    // Show confirmation that current form data is being used
    showSuccessSnackBar('🤖 AI is creating a special meal plan! Exciting! ✨');
    
    // Navigate to AI Meal Plan Screen with updated data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIMealPlanScreen(
          petData: currentData,
        ),
      ),
    );
  }

  /// Get current form data for AI meal planner
  Map<String, dynamic> _getCurrentFormData() {
    Map<String, dynamic> currentData = Map.from(widget.petData);
    
    // Update with current form values
    currentData['Name'] = petNameController.text.isEmpty ? widget.petData['Name'] : petNameController.text;
    currentData['oneLine'] = oneLineController.text;
    currentData['Breed'] = breedController.text.isEmpty ? dropdownvalue : breedController.text;
    currentData['Category'] = "Dog";
    currentData['DateOfBirth'] = dateOfBirthController.isEmpty ? widget.petData['DateOfBirth'] : dateOfBirthController;
    currentData['weight'] = weightController.text.isEmpty ? widget.petData['weight'] : weightController.text;
    currentData['weightUnit'] = selectedWeightUnit;
    currentData['activityLevel'] = selectedActivityLevel.isEmpty ? widget.petData['activityLevel'] : selectedActivityLevel;
    currentData['poopStatus'] = (selectedPoopStatusIndex + 1).toString();
    currentData['poopDescription'] = getPoopDescription(selectedPoopStatusIndex);
    
    // Physical characteristics
    currentData['gender'] = selectedGender.isEmpty ? widget.petData['gender'] : selectedGender;
    currentData['neuteredStatus'] = selectedNeuteredStatus;
    currentData['bodyCondition'] = selectedBodyCondition;
    
    // Poop details
    currentData['poopColor'] = selectedPoopColor.isEmpty ? widget.petData['poopColor'] : selectedPoopColor;
    currentData['poopFrequency'] = selectedPoopFrequency.isEmpty ? widget.petData['poopFrequency'] : selectedPoopFrequency;
    currentData['poopQuantity'] = selectedPoopQuantity.isEmpty ? widget.petData['poopQuantity'] : selectedPoopQuantity;
    
    // Activity minutes
    if (dailyActivityMinutesController.text.isNotEmpty) {
      currentData['dailyActivityMinutes'] = int.tryParse(dailyActivityMinutesController.text) ?? 0;
    }
    
    // Health and food preferences
    currentData['healthGoals'] = selectedHealthGoals;
    if (customHealthGoals.isNotEmpty) {
      currentData['customHealthGoals'] = customHealthGoals;
    }
    if (customHealthGoalController.text.isNotEmpty) {
      currentData['customHealthGoal'] = customHealthGoalController.text;
    }
    
    currentData['allergies'] = selectedAllergies;
    if (customAllergies.isNotEmpty) {
      currentData['customAllergies'] = customAllergies;
    } else if (customAllergyController.text.isNotEmpty) {
      currentData['customAllergies'] = customAllergyController.text;
    }
    
    currentData['favorites'] = selectedFavorites;
    if (customFavorites.isNotEmpty) {
      currentData['customFavorites'] = customFavorites;
    } else if (customFavoriteController.text.isNotEmpty) {
      currentData['customFavorites'] = customFavoriteController.text;
    }
    
    if (healthNotesController.text.isNotEmpty) {
      currentData['healthNotes'] = healthNotesController.text;
    }
    
    return currentData;
  }

  /// Build meal detail row helper
  Widget _buildMealDetailRow(String emoji, String label, String value) {
    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                emoji,
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppIcons.primaryIconColor, size: 24),
          ),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: subHeadingColortwo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      children: [
        // Pet Name
        Container(
          margin: EdgeInsets.only(bottom: 20),
          child: TextFormField(
            controller: petNameController,
            style: TextStyle(color: subTextColor),
            decoration: InputDecoration(
              labelText: '🐾 Pet Name',
              labelStyle: TextStyle(color: subHeadingColor),
              prefixIcon: AppIcons.petIcon(),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // Breed Selection (Dog breeds only since this is a dog-only app)
        Container(
          margin: EdgeInsets.only(bottom: 20),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: listTileColorSecond,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🐕 Dog Breed',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: subHeadingColor,
                ),
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: dropdownvalue,
                style: TextStyle(color: subTextColor),
                dropdownColor: Colors.grey.shade800,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: dogValue.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: TextStyle(color: subTextColor)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    dropdownvalue = newValue!;
                    breedController.text = newValue;
                  });
                },
              ),
            ],
          ),
        ),

        // Date of Birth
        Container(
          margin: EdgeInsets.only(bottom: 20),
          child: GestureDetector(
            onTap: selectDate,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: listTileColorSecond,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  AppIcons.dateIcon(),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date of Birth',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: subHeadingColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          dateOfBirthController.isEmpty 
                              ? 'Select date of birth' 
                              : dateOfBirthController,
                          style: TextStyle(
                            color: dateOfBirthController.isEmpty 
                                ? Colors.grey 
                                : subTextColor,
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

        // One Line Description
        Container(
          margin: EdgeInsets.only(bottom: 20),
          child: TextFormField(
            controller: oneLineController,
            style: TextStyle(color: subTextColor),
            decoration: InputDecoration(
              labelText: 'One Line Description (Optional)',
              labelStyle: TextStyle(color: subHeadingColor),
              prefixIcon: AppIcons.documentIcon(),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // Image Section
        Container(
          margin: EdgeInsets.only(bottom: 20),
          child: GestureDetector(
            onTap: pickImageFromGallery,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: listTileColorSecond,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.withOpacity(0.3)),
              ),
              child: pickedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        pickedImage!,
                        width: double.infinity,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Stack(
                      children: [
                        // Placeholder image background
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            height: 120,
                            child: Image.asset(
                              'assets/images/placeholder.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade300,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        AppIcons.cameraIcon(size: 40),
                                        SizedBox(height: 8),
                                        Text(
                                          'Tap to update photo',
                                          style: TextStyle(color: subHeadingColor),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // Semi-transparent overlay with add icon
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.black.withOpacity(0.3),
                            ),
                          ),
                        ),
                        // Centered add icon
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.add,
                              color: Colors.teal,
                              size: 20,
                            ),
                          ),
                        ),
                        // Camera instruction text
                        Positioned(
                          bottom: 10,
                          left: 10,
                          right: 10,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Tap to update photo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightAndHealthSection() {
    return Column(
      children: [
        // Weight Section
        Container(
          margin: EdgeInsets.only(bottom: 20),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: listTileColorSecond,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weight',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: subHeadingColor,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: subTextColor),
                      decoration: InputDecoration(
                        hintText: '⚖️ Enter weight',
                        hintStyle: TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedWeightUnit,
                      style: TextStyle(color: subTextColor),
                      dropdownColor: Colors.grey.shade800,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: ['kg', 'lbs'].map((String unit) {
                        return DropdownMenuItem<String>(
                          value: unit,
                          child: Text(unit, style: TextStyle(color: subTextColor)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedWeightUnit = newValue!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Health Goals Section
        Container(
          margin: EdgeInsets.only(bottom: 20),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: listTileColorSecond,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Health Goals',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: subHeadingColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Select health goals and set their priority (1 = highest priority)',
                style: TextStyle(
                  fontSize: 12,
                  color: subHeadingColor.withOpacity(0.8),
                ),
              ),
              SizedBox(height: 12),
              
              // Health Goals Grid
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.4, // Increased height to prevent overflow
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: healthGoals.length,
                itemBuilder: (context, index) {
                  final goal = healthGoals[index];
                  final isSelected = goal['isSelected'];
                  final goalName = goal['name'];
                  final currentPriority = healthGoalPriorities[goalName] ?? 0;
                  
                  return GestureDetector(
                    onTap: () => toggleHealthGoal(index),
                    child: Container(
                      padding: EdgeInsets.all(6), // Reduced padding
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Colors.teal.withOpacity(0.3)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected 
                              ? Colors.teal
                              : Colors.grey.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min, // Prevent overflow
                        children: [
                          // Icon and text row
                          Flexible(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  goal['icon'],
                                  style: TextStyle(fontSize: 14), // Smaller icon
                                ),
                                SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    goalName,
                                    style: TextStyle(
                                      color: subTextColor,
                                      fontSize: 10, // Smaller text
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Priority section
                          if (isSelected) ...[
                            SizedBox(height: 2),
                            Flexible(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'P:',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 2),
                                  Container(
                                    constraints: BoxConstraints(
                                      maxWidth: 35,
                                      maxHeight: 18,
                                    ),
                                    child: DropdownButtonFormField<int>(
                                      value: currentPriority > 0 ? currentPriority : 1,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      dropdownColor: Colors.grey[900],
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(3),
                                          borderSide: BorderSide(color: Colors.teal.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(3),
                                          borderSide: BorderSide(color: Colors.teal.shade300),
                                        ),
                                      ),
                                      items: List.generate(selectedHealthGoals.length, (i) => i + 1)
                                          .map((priority) => DropdownMenuItem<int>(
                                                value: priority,
                                                child: Text(
                                                  '$priority',
                                                  style: TextStyle(fontSize: 9, color: Colors.white),
                                                ),
                                              ))
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
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 12),
              
              // Custom Health Goals Section
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: customHealthGoalController,
                          style: TextStyle(color: subTextColor),
                          decoration: InputDecoration(
                            hintText: 'Add custom health goal',
                            hintStyle: TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
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
                    color: subHeadingColor,
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
                                    color: subTextColor,
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
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.green.shade300),
                                    ),
                                    child: DropdownButton<int>(
                                      value: priority > 0 ? priority : 1,
                                      underline: SizedBox(),
                                      style: TextStyle(fontSize: 10, color: Colors.white),
                                      dropdownColor: Colors.grey[900],
                                      items: List.generate(selectedHealthGoals.length, (index) => index + 1)
                                          .map((priorityValue) => DropdownMenuItem<int>(
                                              value: priorityValue,
                                              child: Text(
                                                'Priority $priorityValue',
                                                style: TextStyle(fontSize: 10, color: Colors.white),
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
      ],
    );
  }

  Widget _buildFoodPreferencesSection() {
    return Column(
      children: [
        // Allergies Section
        Container(
          margin: EdgeInsets.only(bottom: 20),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: listTileColorSecond,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Food Allergies',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: subHeadingColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Help us keep your pet safe and happy! 🛡️',
                style: TextStyle(
                  fontSize: 12,
                  color: subHeadingColor.withOpacity(0.8),
                ),
              ),
              SizedBox(height: 12),
              
              // Allergy Grid
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.5,
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
                                  ? Colors.red.shade50
                                  : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected 
                                ? Colors.red.shade400 
                                : hasConflict
                                    ? Colors.red.shade600
                                    : Colors.grey.shade300,
                            width: hasConflict ? 3 : 2,
                          ),
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
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    allergyName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: isSelected 
                                          ? Colors.white 
                                          : hasConflict
                                              ? Colors.red.shade700
                                              : subTextColor,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (hasConflict) ...[
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
              
              SizedBox(height: 12),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: customAllergyController,
                          style: TextStyle(color: subTextColor),
                          decoration: InputDecoration(
                            hintText: 'Ingredient name',
                            hintStyle: TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: customAllergyBrandController,
                          style: TextStyle(color: subTextColor),
                          decoration: InputDecoration(
                            hintText: 'Brand (optional)',
                            hintStyle: TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: addCustomAllergy,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
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
                ],
              ),
              
              // Display custom allergies
              if (customAllergies.isNotEmpty) ...[
                SizedBox(height: 12),
                Text(
                  'Custom Allergies:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: subHeadingColor,
                  ),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: customAllergies.asMap().entries.map((entry) {
                    int index = entry.key;
                    Map<String, String> allergy = entry.value;
                    return Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.85,
                      ),
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  allergy['ingredient'] ?? '',
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                if (allergy['brand']?.isNotEmpty == true)
                                  Text(
                                    'Brand: ${allergy['brand']}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => removeCustomAllergy(index),
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.red.shade600,
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
          margin: EdgeInsets.only(bottom: 20),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: listTileColorSecond,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Favorite Foods',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: subHeadingColor,
                ),
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(favoriteFoods.length, (index) {
                  final foodName = favoriteFoods[index]['name'];
                  final hasConflict = isIngredientInAllergies(foodName);
                  
                  return GestureDetector(
                    onTap: () => toggleFavorite(index),
                    child: Container(
                      constraints: BoxConstraints(
                        minWidth: 0,
                        maxWidth: MediaQuery.of(context).size.width * 0.8, // Limit maximum width
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: favoriteFoods[index]['isSelected']
                            ? Colors.green.withOpacity(0.3)
                            : hasConflict 
                                ? Colors.orange.withOpacity(0.2)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: favoriteFoods[index]['isSelected']
                              ? Colors.green
                              : hasConflict
                                  ? Colors.orange.shade400
                                  : Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                favoriteFoods[index]['icon'],
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  foodName,
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 13,
                                    fontWeight: favoriteFoods[index]['isSelected'] 
                                        ? FontWeight.w700 
                                        : FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                          if (hasConflict)
                            Positioned(
                              top: -6,
                              right: -6,
                              child: Container(
                                padding: EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade600,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.warning,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(height: 12),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: customFavoriteController,
                          style: TextStyle(color: subTextColor),
                          decoration: InputDecoration(
                            hintText: 'Ingredient name',
                            hintStyle: TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: customFavoriteBrandController,
                          style: TextStyle(color: subTextColor),
                          decoration: InputDecoration(
                            hintText: 'Brand (optional)',
                            hintStyle: TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: addCustomFavorite,
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
                ],
              ),
              
              // Display custom favorites
              if (customFavorites.isNotEmpty) ...[
                SizedBox(height: 12),
                Text(
                  'Custom Favorites:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: subHeadingColor,
                  ),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: customFavorites.asMap().entries.map((entry) {
                    int index = entry.key;
                    Map<String, String> favorite = entry.value;
                    return Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.85,
                      ),
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  favorite['ingredient'] ?? '',
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                if (favorite['brand']?.isNotEmpty == true)
                                  Text(
                                    'Brand: ${favorite['brand']}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => removeCustomFavorite(index),
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.green.shade600,
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

        // Feeding Frequency Section
        Container(
          margin: EdgeInsets.only(bottom: 20),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: listTileColorSecond,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🍽️ Feeding Frequency',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: subHeadingColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'How often do you feed your pet? 🕐',
                style: TextStyle(
                  fontSize: 12,
                  color: subHeadingColor.withOpacity(0.8),
                ),
              ),
              SizedBox(height: 12),
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
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.orange.shade50 : Colors.white.withOpacity(0.1),
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
                            style: TextStyle(fontSize: 20),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  feeding['frequency'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.orange.shade600 : subTextColor,
                                  ),
                                ),
                                Text(
                                  feeding['description'],
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                Text(
                                  feeding['timeDescription'],
                                  style: TextStyle(
                                    fontSize: 10,
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
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(8),
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
      ],
    );
  }

  Widget _buildPhysicalCharacteristicsSection() {
    return Column(
      children: [
        // Gender Selection
        Container(
          margin: EdgeInsets.only(bottom: 20),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: listTileColorSecond,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Gender',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: subHeadingColor,
                    ),
                  ),
                  Text(
                    ' *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
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
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? gender['color'].withOpacity(0.2) : Colors.white.withOpacity(0.1),
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
                                fontSize: 13, // Slightly smaller 
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.normal,
                                color: subTextColor,
                              ),
                              overflow: TextOverflow.ellipsis,
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

        // Neutered Status
        Container(
          margin: EdgeInsets.only(bottom: 20),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: listTileColorSecond,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Neutered/Spayed Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: subHeadingColor,
                ),
              ),
              SizedBox(height: 12),
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
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.teal.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.teal : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              option['icon'],
                              style: TextStyle(fontSize: 24),
                            ),
                            SizedBox(height: 5),
                            Text(
                              option['value'],
                              style: TextStyle(
                                fontSize: 13, // Slightly smaller to accommodate bold text
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.normal,
                                color: subTextColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              option['description'],
                              style: TextStyle(
                                fontSize: 9, // Smaller description text
                                color: Colors.grey.shade400,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2, // Allow wrapping to 2 lines
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
          margin: EdgeInsets.only(bottom: 20),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: listTileColorSecond,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Body Condition',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: subHeadingColor,
                ),
              ),
              SizedBox(height: 12),
              Column(
                children: bodyConditions.map((condition) {
                  bool isSelected = selectedBodyCondition == condition['condition'];
                  return Container(
                    margin: EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedBodyCondition = condition['condition'];
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? condition['color'].withOpacity(0.2) : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? condition['color'] : Colors.grey.withOpacity(0.3),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              condition['icon'],
                              style: TextStyle(fontSize: 24),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    condition['condition'],
                                    style: TextStyle(
                                      fontSize: 15, // Slightly smaller
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.normal,
                                      color: subTextColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    condition['description'],
                                    style: TextStyle(
                                      fontSize: 11, // Slightly smaller
                                      color: Colors.grey.shade400,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2, // Allow wrapping
                                  ),
                                ],
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
      ],
    );
  }

  Widget _buildActivityAndHealthSection() {
    return Column(
      children: [
        // Activity Level Section
        Container(
          margin: EdgeInsets.only(bottom: 20),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: listTileColorSecond,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Activity Level',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: subHeadingColor,
                ),
              ),
              SizedBox(height: 12),
              Column(
                children: activityLevels.map((activity) {
                  return Container(
                    margin: EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedActivityLevel = activity['level'];
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: selectedActivityLevel == activity['level']
                              ? activity['color'].withOpacity(0.3)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedActivityLevel == activity['level']
                                ? activity['color']
                                : Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              activity['icon'],
                              style: TextStyle(fontSize: 24),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activity['level'],
                                    style: TextStyle(
                                      fontSize: 15, // Slightly smaller
                                      fontWeight: selectedActivityLevel == activity['level'] ? FontWeight.w800 : FontWeight.w500,
                                      color: subTextColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    activity['description'],
                                    style: TextStyle(
                                      fontSize: 11, // Slightly smaller
                                      color: Colors.grey.shade400,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2, // Allow wrapping
                                  ),
                                ],
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

        // Daily Activity Minutes Section
        Container(
          margin: EdgeInsets.only(bottom: 20),
          child: TextFormField(
            controller: dailyActivityMinutesController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: subTextColor),
            decoration: InputDecoration(
              labelText: 'Daily Activity Minutes (Optional)',
              labelStyle: TextStyle(color: subHeadingColor),
              hintText: 'e.g., 60 minutes',
              hintStyle: TextStyle(color: Colors.grey),
              prefixIcon: AppIcons.timerIcon(),
              suffixText: 'min',
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // Poop Status Section
        Container(
          margin: EdgeInsets.only(bottom: 20),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: listTileColorSecond,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '💩 Current Poop Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: subHeadingColor,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: getPoopColor(selectedPoopStatusIndex).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: getPoopColor(selectedPoopStatusIndex)),
                ),
                child: Text(
                  getPoopDescription(selectedPoopStatusIndex),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 12),
              Text(
                "Select the poop status that matches your pet:",
                style: TextStyle(
                  fontSize: 12,
                  color: subHeadingColor.withOpacity(0.8),
                ),
              ),
              SizedBox(height: 8),
              
              // Poop status indicators grid
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  childAspectRatio: 0.7,
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
                          flex: 3,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? status['color'].withOpacity(0.3)
                                  : Colors.white.withOpacity(0.1),
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
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Text label below the rectangle
                        SizedBox(height: 2),
                        Expanded(
                          flex: 2,
                          child: Text(
                            status['description'] == 'Very Hard' 
                                ? 'Very\nHard'
                                : status['description'] == 'Very Soft'
                                    ? 'Very\nSoft'
                                    : status['description'],
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? status['color'] : subTextColor,
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
            ],
          ),
        ),

        // Poop Details Section
        Container(
          margin: EdgeInsets.only(bottom: 20),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: listTileColorSecond,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Poop Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: subHeadingColor,
                ),
              ),
              SizedBox(height: 16),
              
              // Poop Color
              Row(
                children: [
                  Text(
                    'Color',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: subTextColor,
                    ),
                  ),
                  Text(
                    ' *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedPoopColor.isEmpty ? null : selectedPoopColor,
                    hint: Text(
                      'Select poop color',
                      style: TextStyle(color: Colors.grey),
                    ),
                    isExpanded: true,
                    dropdownColor: Colors.grey.shade800,
                    style: TextStyle(color: subTextColor),
                    items: poopColors.map((color) {
                      return DropdownMenuItem<String>(
                        value: color,
                        child: Text(
                          color,
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 13, // Smaller font size
                            fontWeight: selectedPoopColor == color ? FontWeight.w800 : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis, // Prevent overflow
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedPoopColor = value ?? '';
                      });
                    },
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Poop Frequency
              Row(
                children: [
                  Text(
                    'Frequency',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: subTextColor,
                    ),
                  ),
                  Text(
                    ' *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedPoopFrequency.isEmpty ? null : selectedPoopFrequency,
                    hint: Text(
                      'Select frequency',
                      style: TextStyle(color: Colors.grey),
                    ),
                    isExpanded: true,
                    dropdownColor: Colors.grey.shade800,
                    style: TextStyle(color: subTextColor),
                    items: poopFrequencies.map((frequency) {
                      return DropdownMenuItem<String>(
                        value: frequency,
                        child: Text(
                          frequency,
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 13, // Smaller font size
                            fontWeight: selectedPoopFrequency == frequency ? FontWeight.w800 : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis, // Prevent overflow
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedPoopFrequency = value ?? '';
                      });
                    },
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Poop Quantity
              Row(
                children: [
                  Text(
                    'Quantity',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: subTextColor,
                    ),
                  ),
                  Text(
                    ' *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedPoopQuantity.isEmpty ? null : selectedPoopQuantity,
                    hint: Text(
                      'Select quantity',
                      style: TextStyle(color: Colors.grey),
                    ),
                    isExpanded: true,
                    dropdownColor: Colors.grey.shade800,
                    style: TextStyle(color: subTextColor),
                    items: poopQuantities.map((quantity) {
                      return DropdownMenuItem<String>(
                        value: quantity,
                        child: Text(
                          quantity,
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 13, // Smaller font size
                            fontWeight: selectedPoopQuantity == quantity ? FontWeight.w800 : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis, // Prevent overflow
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedPoopQuantity = value ?? '';
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        // Health Notes Section
        Container(
          margin: EdgeInsets.only(bottom: 20),
          child: TextFormField(
            controller: healthNotesController,
            maxLines: 3,
            style: TextStyle(color: subTextColor),
            decoration: InputDecoration(
              labelText: 'Health Notes (Optional)',
              labelStyle: TextStyle(color: subHeadingColor),
              hintText: 'Any additional health information...',
              hintStyle: TextStyle(color: Colors.grey),
              prefixIcon: AppIcons.noteIcon(),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // Medical File Section
        Container(
          margin: EdgeInsets.only(bottom: 20),
          child: GestureDetector(
            onTap: pickMedicalFile,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: listTileColorSecond,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    isMedicalFileUploaded ? AppIcons.documentIcon().icon! : AppIcons.uploadIcon().icon!,
                    color: AppIcons.primaryIconColor,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Medical File (Optional)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: subHeadingColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          isMedicalFileUploaded 
                              ? 'File: ${pickedMedicalFile!.name}'
                              : 'Tap to upload medical records',
                          style: TextStyle(
                            color: isMedicalFileUploaded 
                                ? subTextColor 
                                : Colors.grey,
                            fontSize: 12,
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
      ],
    );
  }
}
