// USAGE EXAMPLE: Enhanced Gemini Meal Service
// This file demonstrates how to use the new personalized meal generation features

import 'package:pet_care/services/gemini_meal_service.dart';

class MealServiceUsageExample {
  
  /// Example 1: Generate optimal meal using user email and pet ID (fetches from Firestore)
  /// Returns JSON formatted meal plan with pricing
  static Future<void> exampleGenerateOptimalMealFromFirestore() async {
    try {
      String userEmail = "user@example.com";
      String petId = "user@example.com_Buddy_1642123456789";
      
      Map<String, dynamic>? mealPlan = await GeminiMealService.generateOptimalPersonalizedMeal(
        userEmail: userEmail,
        petId: petId,
      );
      
      if (mealPlan != null && mealPlan['error'] == null) {
        print("=== OPTIMAL PERSONALIZED MEAL PLAN ===");
        print("Meal Name: ${mealPlan['meal_name']}");
        print("Total Price: \$${mealPlan['total_price']}");
        print("\nIngredients:");
        for (var ingredient in mealPlan['ingredients']) {
          print("- ${ingredient['name']}: ${ingredient['amount_grams']}g");
        }
        print("\nSupplements: ${mealPlan['supplements_vitamins_minerals']}");
        print("Snacks/Treats: ${mealPlan['snacks_treats_special_diet']}");
        print("\nPreparation: ${mealPlan['preparation_instructions']}");
      } else {
        print("Error: ${mealPlan?['error'] ?? 'Unknown error'}");
      }
    } catch (e) {
      print("Error generating meal: $e");
    }
  }
  
  /// Example 2: Generate optimal meal using pet data directly
  static Future<void> exampleGenerateOptimalMealWithData(Map<String, dynamic> petData) async {
    try {
      Map<String, dynamic>? mealPlan = await GeminiMealService.generateOptimalPersonalizedMealWithData(
        petData: petData,
      );
      
      if (mealPlan != null && mealPlan['error'] == null) {
        print("=== OPTIMAL PERSONALIZED MEAL PLAN ===");
        print("Meal Name: ${mealPlan['meal_name']}");
        print("Total Price: \$${mealPlan['total_price']}");
        print("\nIngredients:");
        for (var ingredient in mealPlan['ingredients']) {
          print("- ${ingredient['name']}: ${ingredient['amount_grams']}g");
        }
        print("\nSupplements: ${mealPlan['supplements_vitamins_minerals']}");
        print("Snacks/Treats: ${mealPlan['snacks_treats_special_diet']}");
        print("\nPreparation: ${mealPlan['preparation_instructions']}");
      } else {
        print("Error: ${mealPlan?['error'] ?? 'Unknown error'}");
      }
    } catch (e) {
      print("Error generating meal: $e");
    }
  }

  /// Example 3: Edit existing meal plan based on user request
  static Future<void> exampleEditMealPlan() async {
    try {
      // First generate a meal plan
      Map<String, dynamic> petData = examplePetData();
      Map<String, dynamic>? originalMealPlan = await GeminiMealService.generateOptimalPersonalizedMealWithData(
        petData: petData,
      );
      
      if (originalMealPlan != null && originalMealPlan['error'] == null) {
        print("=== ORIGINAL MEAL PLAN ===");
        print("Meal Name: ${originalMealPlan['meal_name']}");
        print("Total Price: \$${originalMealPlan['total_price']}");
        print("Ingredients: ${originalMealPlan['ingredients']}");
        print("");
        
        // Now edit the meal plan
        String editRequest = "Add more vegetables and include fish oil supplement for omega-3. Also remove rice and add sweet potato instead.";
        
        Map<String, dynamic>? editedMealPlan = await GeminiMealService.editMealPlan(
          currentMealPlan: originalMealPlan,
          petData: petData,
          editRequest: editRequest,
        );
        
        if (editedMealPlan != null && editedMealPlan['error'] == null) {
          print("=== EDITED MEAL PLAN ===");
          print("Edit Request: \"$editRequest\"");
          print("Updated Meal Name: ${editedMealPlan['meal_name']}");
          print("New Total Price: \$${editedMealPlan['total_price']}");
          print("Updated Ingredients:");
          for (var ingredient in editedMealPlan['ingredients']) {
            print("  • ${ingredient['name']}: ${ingredient['amount_grams']}g");
          }
          print("Updated Supplements: ${editedMealPlan['supplements_vitamins_minerals']}");
          if (editedMealPlan['edit_summary'] != null) {
            print("Changes Made: ${editedMealPlan['edit_summary']}");
          }
        } else {
          print("❌ ERROR editing meal: ${editedMealPlan != null ? editedMealPlan['error'] : 'Unknown error'}");
        }
      } else {
        print("❌ ERROR generating original meal: ${originalMealPlan?['error'] ?? 'Unknown error'}");
      }
    } catch (e) {
      print("Error in edit meal example: $e");
    }
  }

  /// Example 4: Calculate meal price for existing meal plan
  static void exampleCalculateMealPrice() {
    // Sample meal plan (as returned by Gemini)
    Map<String, dynamic> sampleMealPlan = {
      "meal_name": "Buddy's Power Bowl",
      "ingredients": [
        {"name": "Chicken Breast", "amount_grams": 150},
        {"name": "Brown Rice", "amount_grams": 80},
        {"name": "Carrots", "amount_grams": 30},
      ],
      "supplements_vitamins_minerals": ["Fish Oil"],
      "snacks_treats_special_diet": ["Training Treats"],
      "preparation_instructions": "Boil chicken, cook rice, steam carrots, mix together."
    };

    // Sample inventory (would normally come from Firestore)
    List<Map<String, dynamic>> sampleInventory = [
      {"name": "Chicken Breast", "pricePerUnit": 15.99, "category": "Protein"},
      {"name": "Brown Rice", "pricePerUnit": 3.50, "category": "Carbohydrate"},
      {"name": "Carrots", "pricePerUnit": 2.99, "category": "Vegetable"},
      {"name": "Fish Oil", "pricePerUnit": 12.99, "category": "Supplement"},
      {"name": "Training Treats", "pricePerUnit": 8.99, "category": "Treat"},
    ];

    double totalPrice = GeminiMealService.calculateMealPrice(sampleMealPlan, sampleInventory);
    print("Calculated meal price: \$${totalPrice.toStringAsFixed(2)}");
  }

  /// Example pet data structure (based on your Firestore schema)
  static Map<String, dynamic> examplePetData() {
    return {
      // Basic Info
      'Name': 'Buddy',
      'Category': 'Dog',
      'Breed': 'Golden Retriever',
      'DateOfBirth': '15/06/2020',
      'weight': '25',
      'weightUnit': 'kg',
      
      // Activity and Health
      'activityLevel': 'High',
      'poopDescription': 'Normal - well-formed',
      'healthNotes': 'Healthy, no major concerns. Gets excited during meal times.',
      
      // Health Goals
      'healthGoals': ['Muscle Building', 'Joint Care'],
      'customHealthGoal': 'Maintain energy for hiking and swimming',
      
      // Food Preferences
      'favorites': ['Chicken', 'Salmon', 'Sweet Potato'],
      'customFavorites': 'Loves carrots as treats',
      
      // Allergies & Restrictions
      'allergies': ['Beef', 'Dairy'],
      'customAllergies': 'Sensitive to grains during summer',
      
      // Medical
      'MedicalFile': 'medical_file_vaccination_records.pdf',
      
      // Location (for delivery context)
      'LAT': 31.5607552,
      'LONG': 74.378948,
    };
  }

  /// Example using legacy methods (for backward compatibility)
  static Future<void> exampleLegacyMultipleMealOptions() async {
    try {
      String mealOptions = await GeminiMealService.generateMultipleMealOptions(
        petName: 'Buddy',
        petType: 'Dog',
        breed: 'Golden Retriever',
        weight: 25.0,
        age: 4,
        activityLevel: 'High',
        healthConcerns: ['Joint care needed'],
        dietaryRestrictions: ['No beef', 'No dairy'],
        availableIngredients: ['Chicken', 'Rice', 'Carrots', 'Salmon'],
      );
      
      print("=== MULTIPLE MEAL OPTIONS ===");
      print(mealOptions);
    } catch (e) {
      print("Error generating meal options: $e");
    }
  }

  /// Example: Complete workflow for meal generation and pricing
  static Future<void> exampleCompleteWorkflow() async {
    print("🔥 STARTING COMPLETE MEAL GENERATION WORKFLOW");
    print("=" * 50);
    
    // Step 1: Use sample pet data
    Map<String, dynamic> petData = examplePetData();
    print("📊 Pet: ${petData['Name']} (${petData['Breed']})");
    print("🎯 Health Goals: ${petData['healthGoals']}");
    print("❤️ Favorites: ${petData['favorites']}");
    print("🚫 Allergies: ${petData['allergies']}");
    print("");
    
    // Step 2: Generate optimal meal plan
    print("🤖 Generating optimal meal plan...");
    Map<String, dynamic>? mealPlan = await GeminiMealService.generateOptimalPersonalizedMealWithData(
      petData: petData,
    );
    
    if (mealPlan != null && mealPlan['error'] == null) {
      print("✅ SUCCESS! Generated meal plan:");
      print("");
      print("🍽️  MEAL: ${mealPlan['meal_name']}");
      print("💰 PRICE: \$${mealPlan['total_price']}");
      print("");
      print("🥩 INGREDIENTS:");
      for (var ingredient in mealPlan['ingredients']) {
        print("   • ${ingredient['name']}: ${ingredient['amount_grams']}g");
      }
      
      if (mealPlan['supplements_vitamins_minerals'] != null && 
          (mealPlan['supplements_vitamins_minerals'] as List).isNotEmpty) {
        print("");
        print("💊 SUPPLEMENTS:");
        for (var supplement in mealPlan['supplements_vitamins_minerals']) {
          print("   • $supplement");
        }
      }
      
      if (mealPlan['snacks_treats_special_diet'] != null && 
          (mealPlan['snacks_treats_special_diet'] as List).isNotEmpty) {
        print("");
        print("🍖 SNACKS & TREATS:");
        for (var snack in mealPlan['snacks_treats_special_diet']) {
          print("   • $snack");
        }
      }
      
      print("");
      print("👨‍🍳 PREPARATION:");
      print("   ${mealPlan['preparation_instructions']}");
      
    } else {
      print("❌ ERROR: ${mealPlan?['error'] ?? 'Unknown error'}");
    }
    
    print("");
    print("=" * 50);
    print("🎉 WORKFLOW COMPLETE");
  }
}

/*
HOW THE NEW ENHANCED SERVICE WORKS:

🆕 **NEW OPTIMAL MEAL METHODS:**

1. `generateOptimalPersonalizedMeal()` - Fetches pet data from Firestore and generates JSON meal plan
2. `generateOptimalPersonalizedMealWithData()` - Uses provided pet data to generate JSON meal plan
3. `editMealPlan()` - Edits existing meal plan based on user requests ✨ NEW! ✨
4. `calculateMealPrice()` - Calculates total cost based on ingredients and inventory prices

🎯 **NEW MEAL EDITING FEATURE:**

✨ **MEAL EDITING CAPABILITIES:**
   - Add or remove specific ingredients from the meal
   - Adjust ingredient quantities (increase/decrease portions)
   - Add or remove supplements, vitamins, and minerals
   - Add or remove snacks, treats, and special diet items
   - Modify nutritional composition (more protein, less carbs, etc.)
   - Replace ingredients with alternatives (e.g., chicken to beef)
   - Customize preparation methods

🤖 **INTELLIGENT EDITING:**
   - Maintains nutritional balance when making changes
   - Respects pet allergies and restrictions during edits
   - Uses only available inventory ingredients
   - Updates meal pricing automatically
   - Provides edit summary explaining what was changed
   - Preserves pet's health goals and preferences

� **USER INTERFACE IMPROVEMENTS:**
   - "Generate AI Meal Plan" becomes "Edit Meal Plan" after generation
   - Quick edit options for common requests
   - Custom edit request field for specific modifications
   - Real-time price updates after edits
   - Edit history and summary display

�📊 **DATA COLLECTION**: 
   - Fetches comprehensive pet data from Firestore (all form data from pet registration)
   - Gets real-time inventory data from ingredients collection
   - Filters out allergens automatically
   - Separates ingredients into categories: main ingredients, supplements, snacks, special diet

🎯 **ENHANCED PERSONALIZATION**:
   - Uses ALL available pet data: health goals, favorites, allergies, activity level, age, poop status, health notes, medical records
   - Calculates age from date of birth
   - Considers digestive health status (poop description)
   - Integrates favorite foods while maintaining nutrition balance
   - Filters based on allergies and restrictions

📦 **INVENTORY INTEGRATION**:
   - Only uses ingredients that are actually available in stock
   - Shows stock quantities to AI for better portion planning
   - Ensures meals can actually be prepared
   - Includes pricing information for cost calculation

🤖 **SMART JSON PROMPTING**:
   - Creates a comprehensive prompt with all pet details
   - Provides complete inventory with nutrition and pricing data
   - Requests strict JSON response format for easy parsing
   - Asks AI to consider each aspect of the pet's profile

💰 **AUTOMATIC PRICING**:
   - Calculates ingredient costs based on gram amounts and inventory prices
   - Adds supplement costs (10% of unit price per meal)
   - Adds treat costs (5% of unit price per meal)
   - Returns total meal cost in dollars
   - Updates pricing automatically after edits

📋 **OUTPUT FORMAT**:
   - JSON structure with meal name, ingredients (with grams), supplements, snacks, preparation
   - Automatic price calculation included
   - Edit summary for tracking changes
   - Ready for UI display and kitchen preparation
   - Easy to parse and store in database

🔄 **BACKWARD COMPATIBILITY**:
   - All legacy methods still available and functional
   - `generatePersonalizedMeal()` - Text-based meal plans
   - `generateMultipleMealOptions()` - Multiple meal plan options
   - `generateMealSuggestions()` - Quick meal suggestions

BENEFITS OVER PREVIOUS VERSION:
- ✅ Uses real Firestore data (no manual input needed)
- ✅ Returns structured JSON instead of text
- ✅ Automatic price calculation included
- ✅ Considers ALL pet health factors simultaneously
- ✅ Integrates with actual inventory system
- ✅ Automatic allergy filtering for safety
- ✅ Age calculation from date of birth
- ✅ Digestive health consideration (poop status)
- ✅ Medical record awareness
- ✅ Favorite food integration
- ✅ Custom health goals support
- ✅ Supplement and treat recommendations
- ✅ Ready for admin/kitchen display
- ✅ Supports subscription pricing calculations
- ✅ **NEW:** Interactive meal editing with AI assistance
- ✅ **NEW:** Quick edit options for common modifications
- ✅ **NEW:** Custom edit requests with natural language
- ✅ **NEW:** Intelligent nutritional balance maintenance
- ✅ **NEW:** Real-time pricing updates after edits
- ✅ **NEW:** Edit history and change tracking
*/
