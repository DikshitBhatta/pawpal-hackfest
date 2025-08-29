import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:pet_care/apiKey.dart';
import 'package:pet_care/services/ingredient_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class GeminiMealService {
  static final _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: GEMINIAPI,
  );

  /// Enhanced meal generation for individual pets using comprehensive pet data from Firestore
  /// Returns JSON formatted meal plan with exact ingredients, supplements, and preparation instructions
  static Future<Map<String, dynamic>?> generateOptimalPersonalizedMeal({
    required String userEmail,
    required String petId,
  }) async {
    try {
      // Fetch comprehensive pet data from Firestore
      final petData = await _fetchPetDataFromFirestore(userEmail, petId);
      if (petData == null) {
        return {'error': 'Could not fetch pet data. Please ensure the pet exists.'};
      }

      return await generateOptimalPersonalizedMealWithData(petData: petData);
    } catch (e) {
      print('Error generating optimal personalized meal: $e');
      return {'error': 'Error generating personalized meal plan. Please try again.'};
    }
  }

  /// Enhanced meal generation using pet data directly
  /// Returns JSON formatted meal plan optimized for the specific dog
  static Future<Map<String, dynamic>?> generateOptimalPersonalizedMealWithData({
    required Map<String, dynamic> petData,
  }) async {
    try {
      // Fetch available ingredients from inventory
      final availableIngredients = await IngredientService.fetchAvailableIngredients();
      if (availableIngredients.isEmpty) {
        return {'error': 'No ingredients available in inventory. Please contact administrator.'};
      }

      // Filter ingredients based on pet allergies
      final safeIngredients = _filterIngredientsForAllergies(availableIngredients, petData);
      
      // Filter supplements and special diet items
      final availableSupplements = safeIngredients.where((item) => 
        item['category'] == 'Supplement' || 
        item['category'] == 'Vitamin' || 
        item['category'] == 'Mineral').toList();
      
      // Generate activity personalization note
      final activityNote = _generateActivityPersonalizationNote(petData);

      // Build comprehensive prompt with all pet data and inventory
      final prompt = _buildOptimalMealPrompt(petData, safeIngredients, availableSupplements);

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text != null) {
        // Parse JSON response from Gemini
        try {
          // Clean the response to extract JSON
          String jsonResponse = _extractJsonFromResponse(response.text!);
          final Map<String, dynamic> mealPlan = json.decode(jsonResponse);
          
          // Calculate meal price
          double totalPrice = calculateMealPrice(mealPlan, safeIngredients);
          mealPlan['total_price'] = totalPrice;
          
          // Add activity personalization note to the meal plan
          mealPlan['activity_personalization_note'] = activityNote;
          
          return mealPlan;
        } catch (parseError) {
          print('Error parsing JSON response: $parseError');
          print('Raw response: ${response.text}');
          
          // Try to extract and clean JSON one more time with more aggressive cleaning
          try {
            String jsonResponse = _extractJsonFromResponse(response.text!);
            jsonResponse = _aggressiveCleanJson(jsonResponse);
            final Map<String, dynamic> mealPlan = json.decode(jsonResponse);
            
            // Calculate meal price
            double totalPrice = calculateMealPrice(mealPlan, safeIngredients);
            mealPlan['total_price'] = totalPrice;
            mealPlan['activity_personalization_note'] = activityNote;
            
            return mealPlan;
          } catch (secondParseError) {
            print('Second parsing attempt failed: $secondParseError');
          return {'error': 'Failed to parse meal plan. Please try again.'};
        }
      }
      }

      return {'error': 'Failed to generate personalized meal plan'};
    } catch (e) {
      print('Error generating optimal personalized meal: $e');
      return {'error': 'Error generating personalized meal plan. Please try again.'};
    }
  }

  /// Extract JSON from Gemini response (removes any text before/after JSON and cleans invalid syntax)
  static String _extractJsonFromResponse(String response) {
    // Find the first { and last }
    int startIndex = response.indexOf('{');
    int endIndex = response.lastIndexOf('}');
    
    if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
      String jsonString = response.substring(startIndex, endIndex + 1);
      
      // Clean up invalid JSON syntax
      jsonString = _cleanJsonString(jsonString);
      
      return jsonString;
    }
    
    throw Exception('No valid JSON found in response');
  }

  /// Clean JSON string by removing comments and fixing common issues
  static String _cleanJsonString(String jsonString) {
    // Remove single-line comments (// comment)
    jsonString = jsonString.replaceAll(RegExp(r'//.*?(?=\n|$)'), '');
    
    // Remove multi-line comments (/* comment */)
    jsonString = jsonString.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
    
    // Fix trailing commas before closing brackets/braces
    jsonString = jsonString.replaceAll(RegExp(r',\s*}'), '}');
    jsonString = jsonString.replaceAll(RegExp(r',\s*]'), ']');
    
    // Remove any extra whitespace and newlines that might cause issues
    jsonString = jsonString.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return jsonString;
  }

  /// More aggressive JSON cleaning for problematic responses
  static String _aggressiveCleanJson(String jsonString) {
    // Start with regular cleaning
    jsonString = _cleanJsonString(jsonString);
    
    // Remove any text after closing JSON brace
    int lastBrace = jsonString.lastIndexOf('}');
    if (lastBrace != -1) {
      jsonString = jsonString.substring(0, lastBrace + 1);
    }
    
    // Fix common JSON issues
    // Fix unquoted values after colons (except numbers, booleans, null)
    jsonString = jsonString.replaceAllMapped(
      RegExp(r':\s*([^",\[\{\d\-][^,\]\}]*?)(?=[,\]\}])'),
      (match) => ': "${match.group(1)?.trim()}"'
    );
    
    // Remove any remaining invalid characters at line boundaries
    jsonString = jsonString.replaceAll(RegExp(r'[^\x20-\x7E]'), '');
    
    return jsonString;
  }

  /// Calculate total meal price based on ingredients and quantities
  static double calculateMealPrice(Map<String, dynamic> mealPlan, List<Map<String, dynamic>> inventory) {
    double totalPrice = 0.0;
    
    try {
      // Calculate ingredient costs
      if (mealPlan['ingredients'] != null) {
        List<dynamic> ingredients = mealPlan['ingredients'];
        
        for (var ingredient in ingredients) {
          String ingredientName = ingredient['name']?.toString() ?? '';
          double amountGrams = (ingredient['amount_grams'] ?? 0).toDouble();
          
          // Find ingredient in inventory
          var inventoryItem = inventory.firstWhere(
            (item) => item['name']?.toString().toLowerCase() == ingredientName.toLowerCase(),
            orElse: () => {},
          );
          
          if (inventoryItem.isNotEmpty) {
            double pricePerGram = (inventoryItem['pricePerUnit'] ?? 0.0).toDouble() / 1000; // Convert price per kg to per gram
            totalPrice += pricePerGram * amountGrams;
          }
        }
      }
      
      // Add supplement costs (if any)
      if (mealPlan['supplements_vitamins_minerals'] != null) {
        List<dynamic> supplements = mealPlan['supplements_vitamins_minerals'];
        
        for (var supplementName in supplements) {
          var inventoryItem = inventory.firstWhere(
            (item) => item['name']?.toString().toLowerCase() == supplementName.toString().toLowerCase(),
            orElse: () => {},
          );
          
          if (inventoryItem.isNotEmpty) {
            // Assume standard supplement portion (e.g., 1 tablet, 5g powder)
            double supplementCost = (inventoryItem['pricePerUnit'] ?? 0.0).toDouble() * 0.1; // 10% of unit price per meal
            totalPrice += supplementCost;
          }
        }
      }
      
      // Add snacks/treats costs (if any)
      if (mealPlan['snacks_treats_special_diet'] != null) {
        List<dynamic> snacks = mealPlan['snacks_treats_special_diet'];
        
        for (var snackName in snacks) {
          var inventoryItem = inventory.firstWhere(
            (item) => item['name']?.toString().toLowerCase() == snackName.toString().toLowerCase(),
            orElse: () => {},
          );
          
          if (inventoryItem.isNotEmpty) {
            // Assume standard treat portion
            double treatCost = (inventoryItem['pricePerUnit'] ?? 0.0).toDouble() * 0.05; // 5% of unit price per meal
            totalPrice += treatCost;
          }
        }
      }
      
    } catch (e) {
      print('Error calculating meal price: $e');
    }
    
    return double.parse(totalPrice.toStringAsFixed(2));
  }

  /// Edit an existing meal plan based on user request
  /// Returns updated JSON formatted meal plan
  static Future<Map<String, dynamic>?> editMealPlan({
    required Map<String, dynamic> currentMealPlan,
    required Map<String, dynamic> petData,
    required String editRequest,
  }) async {
    try {
      // Fetch available ingredients from inventory
      final availableIngredients = await IngredientService.fetchAvailableIngredients();
      if (availableIngredients.isEmpty) {
        return {'error': 'No ingredients available in inventory. Please contact administrator.'};
      }

      // Filter ingredients based on pet allergies
      final safeIngredients = _filterIngredientsForAllergies(availableIngredients, petData);
      
      // Filter supplements and special diet items
      final availableSupplements = safeIngredients.where((item) => 
        item['category'] == 'Supplement' || 
        item['category'] == 'Vitamin' || 
        item['category'] == 'Mineral'
      ).toList();

      // Build edit meal prompt
      final prompt = _buildEditMealPrompt(
        currentMealPlan,
        petData,
        editRequest,
        safeIngredients,
        availableSupplements,
      );

      print('=== MEAL EDIT REQUEST DEBUG ===');
      print('Current Meal: ${currentMealPlan['meal_name']}');
      print('Edit Request: $editRequest');
      print('Pet: ${petData['Name']}');
      print('Available Ingredients: ${safeIngredients.length}');
      print('===============================');

      final response = await _model.generateContent([Content.text(prompt)]);

      if (response.text != null) {
        // Parse JSON response from Gemini
        try {
          // Clean the response to extract JSON
          String jsonResponse = _extractJsonFromResponse(response.text!);
          final Map<String, dynamic> editedMealPlan = json.decode(jsonResponse);
          
          // Calculate meal price
          double totalPrice = calculateMealPrice(editedMealPlan, safeIngredients);
          editedMealPlan['total_price'] = totalPrice;
          
          return editedMealPlan;
        } catch (parseError) {
          print('Error parsing JSON response: $parseError');
          print('Raw response: ${response.text}');
          
          // Try to extract and clean JSON one more time with more aggressive cleaning
          try {
            String jsonResponse = _extractJsonFromResponse(response.text!);
            jsonResponse = _aggressiveCleanJson(jsonResponse);
            final Map<String, dynamic> editedMealPlan = json.decode(jsonResponse);
            
            // Calculate meal price
            double totalPrice = calculateMealPrice(editedMealPlan, safeIngredients);
            editedMealPlan['total_price'] = totalPrice;
            
            return editedMealPlan;
          } catch (secondParseError) {
            print('Second parse attempt failed: $secondParseError');
            return {'error': 'Failed to parse meal plan. Please try again with a simpler request.'};
          }
        }
      }

      return {'error': 'Failed to generate edited meal plan'};
    } catch (e) {
      print('Error editing meal plan: $e');
      return {'error': 'Error editing meal plan. Please try again.'};
    }
  }

  /// Build edit meal prompt for modifying existing meal plans
  static String _buildEditMealPrompt(
    Map<String, dynamic> currentMealPlan,
    Map<String, dynamic> petData, 
    String editRequest,
    List<Map<String, dynamic>> availableIngredients,
    List<Map<String, dynamic>> availableSupplements,
  ) {
    final prompt = StringBuffer();
    
    // Extract pet information
    String petName = petData['Name'] ?? petData['name'] ?? 'Unknown Pet';
    String petType = petData['Category'] ?? petData['type'] ?? 'Dog';
    String breed = petData['Breed'] ?? petData['breed'] ?? 'Mixed';
    double weight = double.tryParse(petData['weight']?.toString() ?? '0') ?? 0.0;
    String weightUnit = petData['weightUnit'] ?? 'kg';
    String activityLevel = petData['activityLevel'] ?? 'Medium';
    
    // Get current meal details
    String currentMealName = currentMealPlan['meal_name'] ?? 'Current Meal';
    List<dynamic> currentIngredients = currentMealPlan['ingredients'] ?? [];
    List<dynamic> currentSupplements = currentMealPlan['supplements_vitamins_minerals'] ?? [];
    List<dynamic> currentSnacks = currentMealPlan['snacks_treats_special_diet'] ?? [];
    String currentPreparation = currentMealPlan['preparation_instructions'] ?? '';

    // Extract allergies for safety
    List<String> allergies = [];
    if (petData['allergies'] != null) {
      allergies.addAll(List<String>.from(petData['allergies']));
    }
    if (petData['customAllergies'] != null && petData['customAllergies'].toString().isNotEmpty) {
      allergies.addAll(petData['customAllergies'].toString().split(',').map((e) => e.trim()));
    }

    // Build the prompt
    prompt.writeln('🎯 TASK: EDIT EXISTING MEAL PLAN');
    prompt.writeln('You are a professional canine nutritionist AI with veterinary expertise.');
    prompt.writeln('');
    prompt.writeln('Edit the existing meal plan based on the user\'s specific request while maintaining nutritional balance for the dog.');
    prompt.writeln('');
    prompt.writeln('🐶 DOG PROFILE:');
    prompt.writeln('• Pet Name: $petName');
    prompt.writeln('• Pet Type: $petType');
    prompt.writeln('• Breed: $breed');
    prompt.writeln('• Weight: $weight $weightUnit');
    prompt.writeln('• Activity Level: $activityLevel');
    
    if (allergies.isNotEmpty) {
      prompt.writeln('• Allergies: ${allergies.join(', ')} (⚠️ NEVER include these ingredients)');
    }
    
    prompt.writeln('');
    prompt.writeln('📋 CURRENT MEAL PLAN:');
    prompt.writeln('• Meal Name: $currentMealName');
    prompt.writeln('• Current Ingredients:');
    for (var ingredient in currentIngredients) {
      String name = ingredient['name'] ?? 'Unknown';
      String amount = ingredient['amount_grams']?.toString() ?? '0';
      prompt.writeln('  - $name: ${amount}g');
    }
    
    if (currentSupplements.isNotEmpty) {
      prompt.writeln('• Current Supplements: ${currentSupplements.join(', ')}');
    }
    
    if (currentSnacks.isNotEmpty) {
      prompt.writeln('• Current Snacks/Treats: ${currentSnacks.join(', ')}');
    }
    
    prompt.writeln('• Current Preparation: $currentPreparation');
    
    prompt.writeln('');
    prompt.writeln('✏️ EDIT REQUEST:');
    prompt.writeln('"$editRequest"');
    
    prompt.writeln('');
    prompt.writeln('🧾 AVAILABLE INVENTORY (use only these ingredients):');
    prompt.writeln('```json');
    prompt.writeln('[');
    
    for (int i = 0; i < availableIngredients.length; i++) {
      var ingredient = availableIngredients[i];
      prompt.writeln('  {');
      prompt.writeln('    "name": "${ingredient['name']}",');
      prompt.writeln('    "category": "${ingredient['category']}",');
      prompt.writeln('    "protein": ${ingredient['protein'] ?? 0},');
      prompt.writeln('    "fat": ${ingredient['fat'] ?? 0},');
      prompt.writeln('    "carbs": ${ingredient['carbs'] ?? 0},');
      prompt.writeln('    "fiber": ${ingredient['fiber'] ?? 0},');
      prompt.writeln('    "price_per_unit": ${ingredient['pricePerUnit'] ?? 0},');
      prompt.writeln('    "stock_quantity": ${ingredient['stockQuantity'] ?? 0},');
      prompt.writeln('    "unit": "${ingredient['unit'] ?? 'kg'}"');
      prompt.write('  }');
      if (i < availableIngredients.length - 1) prompt.write(',');
      prompt.writeln('');
    }
    
    prompt.writeln(']');
    prompt.writeln('```');
    
    // Add supplements inventory if available
    if (availableSupplements.isNotEmpty) {
      prompt.writeln('');
      prompt.writeln('💊 AVAILABLE SUPPLEMENTS:');
      for (var supplement in availableSupplements) {
        prompt.writeln('- ${supplement['name']} (${supplement['category']})');
      }
    }
    
    prompt.writeln('');
    prompt.writeln('📦 YOUR RESPONSE FORMAT (strict JSON):');
    prompt.writeln('Return only the following JSON structure with the edited meal plan:');
    prompt.writeln('');
    prompt.writeln('```json');
    prompt.writeln('{');
    prompt.writeln('  "meal_name": "Updated Meal Name (reflect the changes made)",');
    prompt.writeln('  "recommendation_reason": "Brief explanation of why this edited meal is optimal.",');
    prompt.writeln('  "ingredients": [');
    prompt.writeln('    {');
    prompt.writeln('      "name": "Ingredient Name",');
    prompt.writeln('      "amount_grams": 150');
    prompt.writeln('    }');
    prompt.writeln('  ],');
    prompt.writeln('  "supplements_vitamins_minerals": [');
    prompt.writeln('    "Supplement Name if needed"');
    prompt.writeln('  ],');
    prompt.writeln('  "ai_suggested_snacks": [');
    prompt.writeln('    "Frozen carrot sticks",');
    prompt.writeln('    "Dehydrated sweet potato chips"');
    prompt.writeln('  ],');
    prompt.writeln('  "medical_care_instructions": "Care instructions if health conditions exist, or null if none",');
    prompt.writeln('  "activity_recommendation": {');
    prompt.writeln('    "recommendation": "Specific activity recommendation if needed",');
    prompt.writeln('    "reason": "Why this activity level is recommended",');
    prompt.writeln('    "activities": ["Specific activity 1", "Specific activity 2"]');
    prompt.writeln('  },');
    prompt.writeln('  "preparation_instructions": "Updated preparation instructions reflecting the changes"');
    prompt.writeln('}');
    prompt.writeln('```');
    prompt.writeln('');
    prompt.writeln('🛑 IMPORTANT REQUIREMENTS:');
    prompt.writeln('- Apply the user\'s edit request accurately while maintaining nutritional balance');
    prompt.writeln('- Only use ingredients from the provided inventory - NO EXCEPTIONS');
    prompt.writeln('- Provide a short, one-line recommendation reason explaining why this edited meal is optimal');
    prompt.writeln('  Examples: "Updated for better protein balance.", "Enhanced with additional omega-3 for joint support.", "Modified for weight management goals."');
    prompt.writeln('- Respect all pet allergies and dietary restrictions');
    prompt.writeln('- Keep portion sizes appropriate for the dog\'s weight and activity level');
    prompt.writeln('- Update the meal name to reflect the changes made');
    prompt.writeln('- Update preparation instructions if cooking methods change');
    prompt.writeln('- DO NOT include any text outside the JSON object');
    prompt.writeln('- DO NOT include comments in the JSON');
    prompt.writeln('- Return only valid JSON format');
    
    return prompt.toString();
  }

  /// Build optimal meal prompt for JSON response
  static String _buildOptimalMealPrompt(
    Map<String, dynamic> petData, 
    List<Map<String, dynamic>> availableIngredients,
    List<Map<String, dynamic>> availableSupplements,
  ) {
    final prompt = StringBuffer();
    
    // Extract pet information with fallbacks
    String petName = petData['Name'] ?? petData['name'] ?? 'Unknown Pet';
    String petType = petData['Category'] ?? petData['type'] ?? 'Dog';
    String breed = petData['Breed'] ?? petData['breed'] ?? 'Mixed';
    double weight = double.tryParse(petData['weight']?.toString() ?? '0') ?? 0.0;
    String weightUnit = petData['weightUnit'] ?? 'kg';
    String activityLevel = petData['activityLevel'] ?? 'Medium';
    String dateOfBirth = petData['DateOfBirth'] ?? petData['dateOfBirth'] ?? '';
    
    // Calculate age from date of birth
    int age = _calculateAgeFromDOB(dateOfBirth);
    
    // NEW ENHANCED FIELDS - Demographics & Physical Condition
    String gender = petData['gender']?.toString() ?? '';
    String neuteredStatus = petData['neuteredStatus']?.toString() ?? '';
    String bodyCondition = petData['bodyCondition']?.toString() ?? '';
    
    // NEW ENHANCED FIELDS - Feeding Information
    String feedingFrequency = petData['feedingFrequency']?.toString() ?? '';
    
    // NEW ENHANCED FIELDS - Activity & Exercise
    int dailyActivityMinutes = int.tryParse(petData['dailyActivityMinutes']?.toString() ?? '0') ?? 0;
    
    // NEW ENHANCED FIELDS - Detailed Health & Poop Tracking
    String poopStatus = petData['poopStatus']?.toString() ?? '';
    String poopColor = petData['poopColor']?.toString() ?? '';
    String poopFrequency = petData['poopFrequency']?.toString() ?? '';
    String poopConsistency = petData['poopConsistency']?.toString() ?? '';
    String poopQuantity = petData['poopQuantity']?.toString() ?? '';
    
    // Existing Health Information
    String existingHealthCondition = petData['ExistingHealthCondition']?.toString() ?? '';
    String medicationDetails = petData['MedicationDetails']?.toString() ?? '';
    
    // Health information
    List<String> healthGoals = [];
    Map<String, int> healthGoalPriorities = {};
    if (petData['healthGoals'] != null) {
      healthGoals.addAll(List<String>.from(petData['healthGoals']));
    }
    if (petData['healthGoalPriorities'] != null) {
      healthGoalPriorities = Map<String, int>.from(petData['healthGoalPriorities']);
    }
    String customHealthGoal = petData['customHealthGoal']?.toString() ?? '';
    int customHealthGoalPriority = petData['customHealthGoalPriority']?.toInt() ?? 0;
    
    // Food preferences
    List<String> favoritefoods = [];
    if (petData['favorites'] != null) {
      favoritefoods.addAll(List<String>.from(petData['favorites']));
    }
    String customFavorites = petData['customFavorites']?.toString() ?? '';
    
    // Allergies
    List<String> allergies = [];
    if (petData['allergies'] != null) {
      allergies.addAll(List<String>.from(petData['allergies']));
    }
    String customAllergies = petData['customAllergies']?.toString() ?? '';
    
    // Health status
    String poopDescription = petData['poopDescription']?.toString() ?? 'Normal';
    String healthNotes = petData['healthNotes']?.toString() ?? '';
    String medicalFile = petData['MedicalFile']?.toString() ?? '';

    // Build the prompt
    prompt.writeln('🎯 TASK:');
    prompt.writeln('You are a professional canine nutritionist AI with veterinary expertise.');
    prompt.writeln('');
    prompt.writeln('Generate the **best possible personalized meal** for this dog based on their comprehensive profile, using only ingredients from the provided inventory.');
    prompt.writeln('Consider ALL aspects of the dog\'s health, physical condition, activity level, digestive health, and dietary needs.');
    prompt.writeln('Along with food suggest nutritional supplements, vitamins and minerals from the inventory.');
    prompt.writeln('');
    prompt.writeln('**IMPORTANT**: Instead of using snacks from inventory, AI should suggest appropriate homemade/natural snacks based on the dog\'s health profile.');
    prompt.writeln('');
    prompt.writeln('The meal should:');
    prompt.writeln('- Be optimized for the dog\'s breed characteristics, age, weight, gender, and neutered status');
    prompt.writeln('- Account for their current body condition (slim/normal/overweight) and activity level');
    prompt.writeln('- Consider their digestive health based on stool analysis (color, frequency, consistency, quantity)');
    prompt.writeln('- Align with their current feeding frequency and daily activity minutes');
    prompt.writeln('- Address any existing health conditions and medication interactions');
    prompt.writeln('- Incorporate their favorite foods while avoiding all allergens');
    prompt.writeln('- Include a **creative meal name** that reflects the dog\'s profile');
    prompt.writeln('- Use **only ingredients** and **supplements** from the provided list');
    prompt.writeln('- Include exact **ingredient quantities (in grams)** appropriate for their weight and condition');
    prompt.writeln('- Provide **step-by-step preparation instructions** (for the kitchen)');
    prompt.writeln('- Recommend **nutritional supplements, vitamins and minerals from the list** that suit the dog\'s health profile');
    prompt.writeln('- Generate **AI-suggested natural snacks** (not from inventory) that complement the meal');
    prompt.writeln('- Include **medical care instructions** if the dog has any health conditions or recent medical procedures');
    prompt.writeln('- Provide **activity recommendations** based on current activity level, weight, and health status');
    prompt.writeln('');
    prompt.writeln('💡 DO NOT suggest any ingredient or supplement not included in the inventory list.');
    prompt.writeln('💡 Pay special attention to portion control based on body condition and activity level.');
    prompt.writeln('💡 Consider digestive health indicators when selecting ingredients and preparation methods.');
    prompt.writeln('💡 For snacks, suggest healthy homemade options that complement the meal (not from inventory).');
    prompt.writeln('💡 If medical conditions exist, provide simple care instructions alongside the meal plan.');
    prompt.writeln('💡 Evaluate current activity level and provide recommendations if adjustments are needed.');
    prompt.writeln('');
    prompt.writeln('🐶 DOG PROFILE:');
    prompt.writeln('• Pet Name: $petName');
    prompt.writeln('• Pet Type: $petType');
    prompt.writeln('• Breed: $breed');
    prompt.writeln('• Weight: $weight $weightUnit');
    prompt.writeln('• Age: $age years (DOB: $dateOfBirth)');
    prompt.writeln('• Activity Level: $activityLevel');
    
    // NEW ENHANCED DEMOGRAPHICS & PHYSICAL CONDITION
    if (gender.isNotEmpty) {
      prompt.writeln('• Gender: $gender');
    }
    
    if (neuteredStatus.isNotEmpty) {
      prompt.writeln('• Neutered/Spayed: $neuteredStatus');
    }
    
    if (bodyCondition.isNotEmpty) {
      prompt.writeln('• Body Condition: $bodyCondition');
    }
    
    // NEW ENHANCED FEEDING & ACTIVITY INFORMATION
    if (feedingFrequency.isNotEmpty) {
      prompt.writeln('• Current Feeding Frequency: $feedingFrequency');
    }
    
    if (dailyActivityMinutes > 0) {
      prompt.writeln('• Daily Activity Minutes: $dailyActivityMinutes minutes');
    }
    
    // NEW ENHANCED HEALTH & DIGESTIVE TRACKING
    if (existingHealthCondition.isNotEmpty) {
      prompt.writeln('• Existing Health Conditions: $existingHealthCondition');
    }
    
    if (medicationDetails.isNotEmpty) {
      prompt.writeln('• Current Medications: $medicationDetails');
    }
    
    if (poopColor.isNotEmpty) {
      prompt.writeln('• Stool Color: $poopColor');
    }
    
    if (poopFrequency.isNotEmpty) {
      prompt.writeln('• Stool Frequency: $poopFrequency');
    }
    
    if (poopConsistency.isNotEmpty) {
      prompt.writeln('• Stool Consistency: $poopConsistency');
    }
    
    if (poopQuantity.isNotEmpty) {
      prompt.writeln('• Stool Quantity: $poopQuantity');
    }
    
    if (poopStatus.isNotEmpty) {
      prompt.writeln('• Overall Digestive Health: $poopStatus');
    }
    
    if (healthGoals.isNotEmpty) {
      // Create prioritized health goals list
      List<String> prioritizedGoals = [];
      
      // Sort health goals by priority (lower number = higher priority)
      List<String> sortedGoals = List.from(healthGoals);
      sortedGoals.sort((a, b) {
        int priorityA = healthGoalPriorities[a] ?? 999;
        int priorityB = healthGoalPriorities[b] ?? 999;
        return priorityA.compareTo(priorityB);
      });
      
      // Format each goal with its priority
      for (String goal in sortedGoals) {
        int priority = healthGoalPriorities[goal] ?? 0;
        if (priority > 0) {
          prioritizedGoals.add('$goal (Priority: $priority)');
        } else {
          prioritizedGoals.add(goal);
        }
      }
      
      prompt.writeln('• Health Goals (in priority order): ${prioritizedGoals.join(', ')}');
      
      // Add priority explanation for AI
      if (healthGoalPriorities.isNotEmpty) {
        prompt.writeln('  📍 IMPORTANT: Focus meal recommendations primarily on Priority 1 goals, then Priority 2, etc.');
      }
    }
    
    if (customHealthGoal.isNotEmpty) {
      if (customHealthGoalPriority > 0) {
        prompt.writeln('• Custom Health Goal: $customHealthGoal (Priority: $customHealthGoalPriority)');
      } else {
      prompt.writeln('• Custom Health Goal: $customHealthGoal');
    }
    }
    
    if (favoritefoods.isNotEmpty) {
      prompt.writeln('• Favorite Foods: ${favoritefoods.join(', ')}');
    }
    
    if (customFavorites.isNotEmpty) {
      prompt.writeln('• Other Favorites: $customFavorites');
    }
    
    if (allergies.isNotEmpty) {
      prompt.writeln('• Food Allergies: ${allergies.join(', ')}');
    }
    
    if (customAllergies.isNotEmpty) {
      prompt.writeln('• Other Allergies: $customAllergies');
    }
    
    if (poopDescription.isNotEmpty && poopDescription != 'Normal') {
      prompt.writeln('• Current Poop Status: $poopDescription');
    }
    
    if (healthNotes.isNotEmpty) {
      prompt.writeln('• Additional Health Notes: $healthNotes');
    }
    
    if (medicalFile.isNotEmpty) {
      prompt.writeln('• Medical Records: Available');
    }
    
    prompt.writeln('');
    prompt.writeln('🧾 INGREDIENT INVENTORY (with nutrition & pricing):');
    prompt.writeln('```json');
    prompt.writeln('[');
    
    for (int i = 0; i < availableIngredients.length; i++) {
      var ingredient = availableIngredients[i];
      prompt.writeln('  {');
      prompt.writeln('    "name": "${ingredient['name']}",');
      prompt.writeln('    "category": "${ingredient['category'] ?? 'Unknown'}",');
      prompt.writeln('    "price_per_gram": ${((ingredient['pricePerUnit'] ?? 0.0) / 1000).toStringAsFixed(4)},');
      prompt.writeln('    "stock_available": "${ingredient['stock'] ?? 0} ${ingredient['unit'] ?? 'units'}",');
      
      // Add nutrition info if available
      Map<String, dynamic> nutrition = {};
      if (ingredient['protein'] != null) nutrition['protein'] = ingredient['protein'];
      if (ingredient['fat'] != null) nutrition['fat'] = ingredient['fat'];
      if (ingredient['fiber'] != null) nutrition['fiber'] = ingredient['fiber'];
      if (ingredient['calcium'] != null) nutrition['calcium'] = ingredient['calcium'];
      if (ingredient['vitaminA'] != null) nutrition['vitaminA'] = ingredient['vitaminA'];
      if (ingredient['omega3'] != null) nutrition['omega3'] = ingredient['omega3'];
      
      if (nutrition.isNotEmpty) {
        prompt.writeln('    "nutrition_per_100g": ${json.encode(nutrition)}');
      } else {
        prompt.writeln('    "nutrition_per_100g": {}');
      }
      
      if (i < availableIngredients.length - 1) {
        prompt.writeln('  },');
      } else {
        prompt.writeln('  }');
      }
    }
    
    prompt.writeln(']');
    prompt.writeln('```');
    
    // Add supplements inventory
    if (availableSupplements.isNotEmpty) {
      prompt.writeln('');
      prompt.writeln('💊 SUPPLEMENT INVENTORY:');
      prompt.writeln('```json');
      prompt.writeln('[');
      
      for (int i = 0; i < availableSupplements.length; i++) {
        var supplement = availableSupplements[i];
        prompt.writeln('  {');
        prompt.writeln('    "name": "${supplement['name']}",');
        prompt.writeln('    "category": "${supplement['category'] ?? 'Supplement'}",');
        prompt.writeln('    "benefits": "Health support supplement"');
        
        if (i < availableSupplements.length - 1) {
          prompt.writeln('  },');
        } else {
          prompt.writeln('  }');
        }
      }
      
      prompt.writeln(']');
      prompt.writeln('```');
    }
    
    prompt.writeln('');
    prompt.writeln('📦 YOUR RESPONSE FORMAT (strict JSON):');
    prompt.writeln('Return only the following JSON structure:');
    prompt.writeln('');
    prompt.writeln('```json');
    prompt.writeln('{');
    prompt.writeln('  "meal_name": "Energy Booster Bowl",');
    prompt.writeln('  "recommendation_reason": "Tailored for joint health and weight control.",');
    prompt.writeln('  "ingredients": [');
    prompt.writeln('    {');
    prompt.writeln('      "name": "Chicken Breast",');
    prompt.writeln('      "amount_grams": 150');
    prompt.writeln('    },');
    prompt.writeln('    {');
    prompt.writeln('      "name": "Brown Rice",');
    prompt.writeln('      "amount_grams": 50');
    prompt.writeln('    }');
    prompt.writeln('  ],');
    prompt.writeln('  "supplements_vitamins_minerals": [');
    prompt.writeln('    "Fish Oil"');
    prompt.writeln('  ],');
    prompt.writeln('  "ai_suggested_snacks": [');
    prompt.writeln('    "Frozen carrot sticks",');
    prompt.writeln('    "Dehydrated sweet potato chips"');
    prompt.writeln('  ],');
    prompt.writeln('  "medical_care_instructions": "Keep incision area clean and dry. Monitor for swelling.",');
    prompt.writeln('  "activity_recommendation": {');
    prompt.writeln('    "recommendation": "Increase daily walks to 45 minutes",');
    prompt.writeln('    "reason": "Current activity level too low for weight management",');
    prompt.writeln('    "activities": ["Morning walk: 20 minutes", "Evening walk: 25 minutes"]');
    prompt.writeln('  },');
    prompt.writeln('  "preparation_instructions": "Boil the chicken for 15 minutes. Cook brown rice separately. Mix together and top with Fish Oil. Serve warm. Ensure water is available."');
    prompt.writeln('}');
    prompt.writeln('```');
    prompt.writeln('');
    prompt.writeln('🛑 DO NOT explain anything.');
    prompt.writeln('🛑 DO NOT include text outside of the JSON object.');
    prompt.writeln('🛑 DO NOT include comments (// or /* */) in the JSON.');
    prompt.writeln('🛑 DO NOT add any explanatory text after values.');
    prompt.writeln('🛑 ONLY return valid JSON format.');
    prompt.writeln('');
    prompt.writeln('📌 REQUIREMENTS:');
    prompt.writeln('- Only use the provided inventory for ingredients and supplements - NO EXCEPTIONS');
    prompt.writeln('- Include cooking method suitable for dogs');
    prompt.writeln('- Provide a short, one-line recommendation reason explaining why this meal is optimal for this specific dog');
    prompt.writeln('  Examples: "Tailored for joint health and weight control.", "Optimized for senior digestive support.", "High-energy formula for active working dogs.", "Gentle on sensitive stomach with digestive support."');
    prompt.writeln('- For snacks, suggest healthy homemade/natural options that complement the meal (NOT from inventory)');
    prompt.writeln('  Examples: "Frozen carrot sticks", "Dehydrated sweet potato chips", "Ice cubes with low-sodium broth", "Apple slices (no seeds)"');
    prompt.writeln('- If medical conditions exist, provide simple care instructions alongside the meal');
    prompt.writeln('  Examples: "Keep incision area clean and dry", "Monitor for swelling", "Ensure adequate rest periods"');
    prompt.writeln('- Evaluate current activity level and provide recommendations if needed');
    prompt.writeln('  Include specific activities and duration based on dog\'s weight, age, and health status');
    prompt.writeln('- Recommend only needed supplements based on health profile');
    prompt.writeln('- Consider the dog\'s specific health profile, favorites, and allergies');
    prompt.writeln('- Optimize portion sizes for the dog\'s weight, body condition, and activity level');
    prompt.writeln('- Account for gender and neutered status in nutritional needs');
    prompt.writeln('- Consider digestive health indicators (stool analysis) for ingredient selection');
    prompt.writeln('- Align meal timing with current feeding frequency');
    prompt.writeln('- Factor in daily activity minutes for caloric requirements');
    prompt.writeln('- Address any existing health conditions through nutrition');
    prompt.writeln('- Ensure meal supports optimal body condition (weight management if needed)');
    
    return prompt.toString();
  }

  /// Fetch comprehensive pet data from Firestore
  static Future<Map<String, dynamic>?> _fetchPetDataFromFirestore(String userEmail, String petId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(userEmail)
          .doc(petId)
          .get();
      
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error fetching pet data: $e');
      return null;
    }
  }

  /// Calculate age from date of birth string
  static int _calculateAgeFromDOB(String dateOfBirth) {
    if (dateOfBirth.isEmpty) return 0;
    
    try {
      // Parse date in DD/MM/YYYY format
      List<String> parts = dateOfBirth.split('/');
      if (parts.length == 3) {
        int day = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        int year = int.parse(parts[2]);
        
        DateTime dob = DateTime(year, month, day);
        DateTime now = DateTime.now();
        
        int age = now.year - dob.year;
        if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
          age--;
        }
        
        return age > 0 ? age : 0;
      }
    } catch (e) {
      print('Error calculating age from DOB: $e');
    }
    
    return 0;
  }

  /// Filter ingredients to exclude allergens
  static List<Map<String, dynamic>> _filterIngredientsForAllergies(
    List<Map<String, dynamic>> ingredients, 
    Map<String, dynamic> petData
  ) {
    // Get pet allergies from various sources
    List<String> allergies = [];
    
    // Standard allergies list
    if (petData['allergies'] != null) {
      allergies.addAll(List<String>.from(petData['allergies']));
    }
    
    // Custom allergies
    if (petData['customAllergies'] != null && petData['customAllergies'].toString().isNotEmpty) {
      allergies.addAll(petData['customAllergies'].toString().split(',').map((e) => e.trim()));
    }

    if (allergies.isEmpty) return ingredients;

    return ingredients.where((ingredient) {
      String ingredientName = ingredient['name']?.toString().toLowerCase() ?? '';
      return !allergies.any((allergy) => 
        ingredientName.contains(allergy.toLowerCase()) ||
        allergy.toLowerCase().contains(ingredientName)
      );
    }).toList();
  }

  /// Generate activity personalization note based on pet's health, weight, and activity level
  static Map<String, dynamic> _generateActivityPersonalizationNote(Map<String, dynamic> petData) {
    String petName = petData['Name'] ?? petData['name'] ?? 'your dog';
    double weight = double.tryParse(petData['weight']?.toString() ?? '0') ?? 0.0;
    String weightUnit = petData['weightUnit'] ?? 'kg';
    String currentActivity = petData['activityLevel'] ?? 'Medium';
    String bodyCondition = petData['bodyCondition']?.toString() ?? '';
    String poopStatus = petData['poopStatus']?.toString() ?? '';
    String existingHealthCondition = petData['ExistingHealthCondition']?.toString() ?? '';
    int dailyActivityMinutes = int.tryParse(petData['dailyActivityMinutes']?.toString() ?? '0') ?? 0;
    
    // Determine ideal weight range based on breed (simplified logic)
    // String breed = petData['Breed'] ?? petData['breed'] ?? 'Mixed'; // Future use for breed-specific recommendations
    bool isOverweight = bodyCondition.toLowerCase().contains('overweight') || 
                       bodyCondition.toLowerCase().contains('obese');
    bool isUnderweight = bodyCondition.toLowerCase().contains('slim') || 
                        bodyCondition.toLowerCase().contains('underweight');
    
    // Health status assessment
    bool hasHealthIssues = existingHealthCondition.isNotEmpty || 
                          poopStatus.toLowerCase().contains('poor') ||
                          poopStatus.toLowerCase().contains('bad');
    
    String personalizationNote = '';
    String activityRecommendation = '';
    String recommendationType = 'maintain'; // maintain, increase, decrease
    
    // Generate personalization note and activity recommendation
    if (isOverweight) {
      personalizationNote = "Based on $petName's weight ($weight$weightUnit) and body condition, this meal plan focuses on weight management with lean proteins and controlled portions.";
      
      if (currentActivity.toLowerCase() == 'low') {
        activityRecommendation = "Gradually increase activity to 30-45 minutes daily with gentle walks and play sessions to support healthy weight loss.";
        recommendationType = 'increase';
      } else if (currentActivity.toLowerCase() == 'medium') {
        activityRecommendation = "Increase activity to 45-60 minutes daily with more vigorous exercise like longer walks, swimming, or interactive play.";
        recommendationType = 'increase';
      } else {
        activityRecommendation = "Maintain current high activity level while monitoring caloric intake to achieve gradual weight loss.";
        recommendationType = 'maintain';
      }
    } else if (isUnderweight) {
      personalizationNote = "Based on $petName's lean body condition, this meal plan includes calorie-dense ingredients to support healthy weight gain.";
      
      if (currentActivity.toLowerCase() == 'high') {
        activityRecommendation = "Consider reducing intense exercise to 30-40 minutes daily to help with weight gain while maintaining muscle tone.";
        recommendationType = 'decrease';
      } else {
        activityRecommendation = "Maintain moderate activity (20-30 minutes daily) to build muscle while supporting weight gain.";
        recommendationType = 'maintain';
      }
    } else if (hasHealthIssues) {
      personalizationNote = "Based on $petName's health conditions, this meal plan includes easily digestible ingredients and therapeutic nutrients.";
      
      if (currentActivity.toLowerCase() == 'high') {
        activityRecommendation = "Reduce to gentle, low-impact activities (15-25 minutes daily) until health improves. Focus on mental stimulation.";
        recommendationType = 'decrease';
      } else {
        activityRecommendation = "Continue with gentle activities and gradually increase based on health improvement and vet guidance.";
        recommendationType = 'maintain';
      }
    } else {
      // Healthy weight and condition
      personalizationNote = "Based on $petName's optimal weight ($weight$weightUnit), $currentActivity activity level, and healthy condition, this meal plan maintains their excellent health.";
      
      if (currentActivity.toLowerCase() == 'low' && dailyActivityMinutes < 20) {
        activityRecommendation = "Consider increasing activity to 25-35 minutes daily for better cardiovascular health and mental stimulation.";
        recommendationType = 'increase';
      } else if (currentActivity.toLowerCase() == 'high' && dailyActivityMinutes > 90) {
        activityRecommendation = "Excellent activity level! Maintain 60-90 minutes of varied exercise to keep $petName healthy and happy.";
        recommendationType = 'maintain';
      } else {
        activityRecommendation = "Current activity level is perfect! Continue with $currentActivity intensity exercise to maintain optimal health.";
        recommendationType = 'maintain';
      }
    }
    
    return {
      'personalization_note': personalizationNote,
      'activity_recommendation': activityRecommendation,
      'recommendation_type': recommendationType,
      'current_activity_level': currentActivity,
      'recommended_daily_minutes': _getRecommendedMinutes(recommendationType, currentActivity, dailyActivityMinutes),
    };
  }
  
  /// Get recommended daily activity minutes based on recommendation type
  static int _getRecommendedMinutes(String recommendationType, String currentActivity, int currentMinutes) {
    switch (recommendationType) {
      case 'increase':
        if (currentActivity.toLowerCase() == 'low') return 35;
        if (currentActivity.toLowerCase() == 'medium') return 55;
        return 75; // high
      case 'decrease':
        if (currentActivity.toLowerCase() == 'high') return 25;
        if (currentActivity.toLowerCase() == 'medium') return 20;
        return 15; // low
      default: // maintain
        if (currentMinutes > 0) return currentMinutes;
        if (currentActivity.toLowerCase() == 'low') return 25;
        if (currentActivity.toLowerCase() == 'medium') return 45;
        return 65; // high
    }
  }

  // =============================================================================
  // LEGACY METHODS (for backward compatibility)
  // =============================================================================

  /// Enhanced meal generation for individual pets using comprehensive pet data from Firestore
  static Future<String> generatePersonalizedMeal({
    required String userEmail,
    required String petId,
  }) async {
    try {
      // Fetch comprehensive pet data from Firestore
      final petData = await _fetchPetDataFromFirestore(userEmail, petId);
      if (petData == null) {
        return 'Error: Could not fetch pet data. Please ensure the pet exists.';
      }

      // Fetch available ingredients from inventory
      final availableIngredients = await IngredientService.fetchAvailableIngredients();
      if (availableIngredients.isEmpty) {
        return 'Error: No ingredients available in inventory. Please contact administrator.';
      }

      // Filter ingredients based on pet allergies
      final safeIngredients = _filterIngredientsForAllergies(availableIngredients, petData);

      // Build comprehensive prompt with all pet data
      final prompt = _buildPersonalizedMealPrompt(petData, safeIngredients);

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      return response.text ?? 'Failed to generate personalized meal plan';
    } catch (e) {
      print('Error generating personalized meal: $e');
      return 'Error generating personalized meal plan. Please try again.';
    }
  }

  /// Convenience method for generating meals with pet data directly
  static Future<String> generatePersonalizedMealWithData({
    required Map<String, dynamic> petData,
  }) async {
    try {
      // Fetch available ingredients from inventory
      final availableIngredients = await IngredientService.fetchAvailableIngredients();
      if (availableIngredients.isEmpty) {
        return 'Error: No ingredients available in inventory. Please contact administrator.';
      }

      // Filter ingredients based on pet allergies
      final safeIngredients = _filterIngredientsForAllergies(availableIngredients, petData);

      // Build comprehensive prompt with all pet data
      final prompt = _buildPersonalizedMealPrompt(petData, safeIngredients);

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      return response.text ?? 'Failed to generate personalized meal plan';
    } catch (e) {
      print('Error generating personalized meal: $e');
      return 'Error generating personalized meal plan. Please try again.';
    }
  }

  /// Build comprehensive personalized meal prompt
  static String _buildPersonalizedMealPrompt(
    Map<String, dynamic> petData, 
    List<Map<String, dynamic>> availableIngredients
  ) {
    final prompt = StringBuffer();
    
    // Extract pet information with fallbacks
    String petName = petData['Name'] ?? petData['name'] ?? 'Unknown Pet';
    String petType = petData['Category'] ?? petData['type'] ?? 'Dog';
    String breed = petData['Breed'] ?? petData['breed'] ?? 'Mixed';
    double weight = double.tryParse(petData['weight']?.toString() ?? '0') ?? 0.0;
    String weightUnit = petData['weightUnit'] ?? 'kg';
    String activityLevel = petData['activityLevel'] ?? 'Medium';
    String dateOfBirth = petData['DateOfBirth'] ?? petData['dateOfBirth'] ?? '';
    
    // Calculate age from date of birth
    int age = _calculateAgeFromDOB(dateOfBirth);
    
    // Health information
    List<String> healthGoals = [];
    Map<String, int> healthGoalPriorities = {};
    if (petData['healthGoals'] != null) {
      healthGoals.addAll(List<String>.from(petData['healthGoals']));
    }
    if (petData['healthGoalPriorities'] != null) {
      healthGoalPriorities = Map<String, int>.from(petData['healthGoalPriorities']);
    }
    String customHealthGoal = petData['customHealthGoal']?.toString() ?? '';
    int customHealthGoalPriority = petData['customHealthGoalPriority']?.toInt() ?? 0;
    
    // Food preferences
    List<String> favoritefoods = [];
    if (petData['favorites'] != null) {
      favoritefoods.addAll(List<String>.from(petData['favorites']));
    }
    String customFavorites = petData['customFavorites']?.toString() ?? '';
    
    // Allergies
    List<String> allergies = [];
    if (petData['allergies'] != null) {
      allergies.addAll(List<String>.from(petData['allergies']));
    }
    String customAllergies = petData['customAllergies']?.toString() ?? '';
    
    // Health status
    String poopDescription = petData['poopDescription']?.toString() ?? 'Normal';
    String healthNotes = petData['healthNotes']?.toString() ?? '';
    String medicalFile = petData['MedicalFile']?.toString() ?? '';

    // Build the prompt header
    prompt.writeln('🐾 PET NUTRITION EXPERT - PERSONALIZED MEAL PLAN');
    prompt.writeln('');
    prompt.writeln('Create the optimal personalized meal plan for:');
    prompt.writeln('• Pet Name: $petName');
    prompt.writeln('• Pet Type: $petType');
    prompt.writeln('• Breed: $breed');
    prompt.writeln('• Weight: $weight $weightUnit');
    prompt.writeln('• Age: $age years (DOB: $dateOfBirth)');
    prompt.writeln('• Activity Level: $activityLevel');
    
    if (healthGoals.isNotEmpty) {
      // Create prioritized health goals list
      List<String> prioritizedGoals = [];
      
      // Sort health goals by priority (lower number = higher priority)
      List<String> sortedGoals = List.from(healthGoals);
      sortedGoals.sort((a, b) {
        int priorityA = healthGoalPriorities[a] ?? 999;
        int priorityB = healthGoalPriorities[b] ?? 999;
        return priorityA.compareTo(priorityB);
      });
      
      // Format each goal with its priority
      for (String goal in sortedGoals) {
        int priority = healthGoalPriorities[goal] ?? 0;
        if (priority > 0) {
          prioritizedGoals.add('$goal (Priority: $priority)');
        } else {
          prioritizedGoals.add(goal);
        }
      }
      
      prompt.writeln('• Health Goals (in priority order): ${prioritizedGoals.join(', ')}');
      
      // Add priority explanation for AI
      if (healthGoalPriorities.isNotEmpty) {
        prompt.writeln('  📍 CRITICAL: Prioritize meal ingredients and recommendations based on Priority 1 goals first, then Priority 2, etc.');
      }
    }
    
    if (customHealthGoal.isNotEmpty) {
      if (customHealthGoalPriority > 0) {
        prompt.writeln('• Custom Health Goal: $customHealthGoal (Priority: $customHealthGoalPriority)');
      } else {
      prompt.writeln('• Custom Health Goal: $customHealthGoal');
    }
    }
    
    if (favoritefoods.isNotEmpty) {
      prompt.writeln('• Favorite Foods: ${favoritefoods.join(', ')} (prefer these ingredients when possible)');
    }
    
    if (customFavorites.isNotEmpty) {
      prompt.writeln('• Other Favorites: $customFavorites');
    }
    
    if (allergies.isNotEmpty) {
      prompt.writeln('• Food Allergies: ${allergies.join(', ')} (AVOID these ingredients)');
    }
    
    if (customAllergies.isNotEmpty) {
      prompt.writeln('• Other Allergies: $customAllergies (AVOID these)');
    }
    
    if (poopDescription.isNotEmpty && poopDescription != 'Normal') {
      prompt.writeln('• Current Digestive Status: $poopDescription (consider digestive health)');
    }
    
    if (healthNotes.isNotEmpty) {
      prompt.writeln('• Additional Health Notes: $healthNotes');
    }
    
    if (medicalFile.isNotEmpty) {
      prompt.writeln('• Medical Records: Available (consider any health conditions)');
    }
    
    // Available ingredients
    prompt.writeln('');
    prompt.writeln('🧾 AVAILABLE INGREDIENTS (use ONLY these):');
    for (var ingredient in availableIngredients) {
      String description = IngredientService.getIngredientDescription(ingredient);
      prompt.writeln('• $description');
    }
    
    prompt.writeln('');
    prompt.writeln('📋 REQUIREMENTS:');
    prompt.writeln('1. Create ONE optimal meal plan specifically tailored to this pet');
    prompt.writeln('2. Use ONLY ingredients from the available list above');
    prompt.writeln('3. Consider ALL pet health factors: breed, weight, age, activity, health goals, favorites, allergies, digestive status');
    prompt.writeln('4. ⭐ PRIORITY SYSTEM: When health goals have priorities, focus primarily on Priority 1 goals in ingredient selection and meal composition, then incorporate Priority 2, etc.');
    prompt.writeln('5. Provide specific portions based on pet size and needs');
    prompt.writeln('6. Include preparation instructions suitable for pet consumption');
    prompt.writeln('7. Explain health benefits specific to this pet\'s profile, emphasizing how the meal addresses highest priority health goals');
    prompt.writeln('8. Consider digestive health and adjust accordingly');
    prompt.writeln('9. Incorporate favorite foods when nutritionally appropriate and aligned with health goal priorities');
    prompt.writeln('');
    prompt.writeln('PROVIDE:');
    prompt.writeln('• Creative meal name reflecting the pet\'s personality or needs');
    prompt.writeln('• Detailed nutritional breakdown');
    prompt.writeln('• Three meals (breakfast, lunch, dinner) with specific ingredients and portions');
    prompt.writeln('• Preparation instructions for each meal');
    prompt.writeln('• Health benefits explanation for this specific pet, clearly explaining how the meal addresses Priority 1 health goals first');
    prompt.writeln('• Feeding guidelines and schedule');
    prompt.writeln('• Any special considerations based on the pet\'s profile and priority health goals');
    
    return prompt.toString();
  }

  static Future<String> generateMultipleMealOptions({
    required String petName,
    required String petType,
    required String breed,
    required double weight,
    required int age,
    required String activityLevel,
    required List<String> healthConcerns,
    required List<String> dietaryRestrictions,
    required List<String> availableIngredients,
  }) async {
    try {
      final prompt = _buildMealPlanPrompt(
        petName: petName,
        petType: petType,
        breed: breed,
        weight: weight,
        age: age,
        activityLevel: activityLevel,
        healthConcerns: healthConcerns,
        dietaryRestrictions: dietaryRestrictions,
        availableIngredients: availableIngredients,
      );

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      return response.text ?? 'Failed to generate meal plan options';
    } catch (e) {
      print('Error generating multiple meal options: $e');
      return 'Error generating meal plan options. Please try again.';
    }
  }

  static String _buildMealPlanPrompt({
    required String petName,
    required String petType,
    required String breed,
    required double weight,
    required int age,
    required String activityLevel,
    required List<String> healthConcerns,
    required List<String> dietaryRestrictions,
    required List<String> availableIngredients,
  }) {
    final prompt = StringBuffer();
    
    prompt.writeln('🐾 PET NUTRITION EXPERT - MEAL PLAN GENERATION');
    prompt.writeln('');
    prompt.writeln('Create 3 DIFFERENT meal plan options for:');
    prompt.writeln('• Pet Name: $petName');
    prompt.writeln('• Pet Type: $petType');
    prompt.writeln('• Breed: $breed');
    prompt.writeln('• Weight: ${weight}kg');
    prompt.writeln('• Age: $age years');
    prompt.writeln('• Activity Level: $activityLevel');
    
    if (healthConcerns.isNotEmpty) {
      prompt.writeln('• Health Concerns: ${healthConcerns.join(', ')}');
    }
    
    if (dietaryRestrictions.isNotEmpty) {
      prompt.writeln('• Dietary Restrictions: ${dietaryRestrictions.join(', ')}');
    }
    
    if (availableIngredients.isNotEmpty) {
      prompt.writeln('• Available Ingredients: ${availableIngredients.join(', ')}');
    }
    
    prompt.writeln('');
    prompt.writeln('REQUIREMENTS:');
    prompt.writeln('1. Generate EXACTLY 3 different meal plan options');
    prompt.writeln('2. Each option should have a DIFFERENT nutritional focus');
    prompt.writeln('3. Use structured percentage format for nutrition (e.g., "Protein: 25-30%")');
    prompt.writeln('4. Include breakfast, lunch, and dinner for each option');
    prompt.writeln('5. Make each meal plan genuinely different, not variations of the same plan');
    
    return prompt.toString();
  }

  static Future<String> generateMealPlan({
    required String petName,
    required String petType,
    required String breed,
    required double weight,
    required int age,
    required String activityLevel,
    required List<String> healthConcerns,
    required List<String> dietaryRestrictions,
    required List<String> availableIngredients,
  }) async {
    try {
      final prompt = _buildSingleMealPlanPrompt(
        petName: petName,
        petType: petType,
        breed: breed,
        weight: weight,
        age: age,
        activityLevel: activityLevel,
        healthConcerns: healthConcerns,
        dietaryRestrictions: dietaryRestrictions,
        availableIngredients: availableIngredients,
      );

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      return response.text ?? 'Failed to generate meal plan';
    } catch (e) {
      print('Error generating meal plan: $e');
      return 'Error generating meal plan. Please try again.';
    }
  }

  static String _buildSingleMealPlanPrompt({
    required String petName,
    required String petType,
    required String breed,
    required double weight,
    required int age,
    required String activityLevel,
    required List<String> healthConcerns,
    required List<String> dietaryRestrictions,
    required List<String> availableIngredients,
  }) {
    final prompt = StringBuffer();
    
    prompt.writeln('🐾 PET NUTRITION EXPERT - MEAL PLAN');
    prompt.writeln('');
    prompt.writeln('Create a personalized meal plan for:');
    prompt.writeln('• Pet Name: $petName');
    prompt.writeln('• Pet Type: $petType');
    prompt.writeln('• Breed: $breed');
    prompt.writeln('• Weight: ${weight}kg');
    prompt.writeln('• Age: $age years');
    prompt.writeln('• Activity Level: $activityLevel');
    
    if (healthConcerns.isNotEmpty) {
      prompt.writeln('• Health Concerns: ${healthConcerns.join(', ')}');
    }
    
    if (dietaryRestrictions.isNotEmpty) {
      prompt.writeln('• Dietary Restrictions: ${dietaryRestrictions.join(', ')}');
    }
    
    if (availableIngredients.isNotEmpty) {
      prompt.writeln('• Available Ingredients: ${availableIngredients.join(', ')}');
    }
    
    prompt.writeln('');
    prompt.writeln('Please provide:');
    prompt.writeln('1. Nutritional analysis with specific percentages');
    prompt.writeln('2. 3 meals (breakfast, lunch, dinner) with portions');
    prompt.writeln('3. Preparation instructions');
    prompt.writeln('4. Health benefits for each meal');
    prompt.writeln('5. Feeding schedule and guidelines');
    
    return prompt.toString();
  }

  static Future<List<String>> generateMealSuggestions({
    required String petType,
    required String healthGoal,
    required List<String> availableIngredients,
  }) async {
    try {
      final prompt = '''
      Generate 5 quick meal suggestions for a $petType with focus on $healthGoal.
      
      Available ingredients: ${availableIngredients.join(', ')}
      
      Format each suggestion as:
      - Meal Name: [Creative name]
      - Main ingredients: [2-3 key ingredients]
      - Prep time: [X minutes]
      - Health benefit: [Brief description]
      
      Keep suggestions concise and practical.
      ''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text != null) {
        return response.text!
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .toList();
      }
      
      return ['Failed to generate meal suggestions'];
    } catch (e) {
      print('Error generating meal suggestions: $e');
      return ['Error generating meal suggestions'];
    }
  }
}
