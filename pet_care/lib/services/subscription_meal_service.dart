import 'package:pet_care/services/gemini_meal_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pet_care/DataBase.dart';

class SubscriptionMealService {
  /// Enhanced meal generation specifically for subscription management
  /// Generates meals with subscription context and delivery frequency
  static Future<Map<String, dynamic>?> generateMealForSubscription({
    required String userEmail,
    required String petId,
    required String frequency,
    String? dogSize,
    List<String>? healthGoals,
    List<String>? foodAllergies,
    String? activityLevel,
  }) async {
    try {
      // Use the existing Gemini meal service as base
      Map<String, dynamic>? baseMealPlan = await GeminiMealService.generateOptimalPersonalizedMeal(
        userEmail: userEmail,
        petId: petId,
      );

      if (baseMealPlan == null || baseMealPlan.containsKey('error')) {
        return baseMealPlan;
      }

      // Enhance meal plan with subscription-specific information
      Map<String, dynamic> enhancedMealPlan = Map<String, dynamic>.from(baseMealPlan);
      
      // Add frequency and portion information
      enhancedMealPlan['subscriptionFrequency'] = frequency;
      enhancedMealPlan['generatedFor'] = 'subscription';
      enhancedMealPlan['generatedAt'] = DateTime.now().toIso8601String();
      
      // Calculate portion sizes based on dog size
      if (dogSize != null) {
        enhancedMealPlan['portionSize'] = _calculatePortionSize(dogSize);
        enhancedMealPlan['dogSize'] = dogSize;
      }

      // Add delivery schedule information
      enhancedMealPlan['deliverySchedule'] = _generateDeliverySchedule(frequency);
      
      // Add meal variety if multiple meals per week
      if (frequency == '2x/week') {
        enhancedMealPlan['mealVariations'] = await _generateMealVariations(enhancedMealPlan);
      }

      return enhancedMealPlan;
    } catch (e) {
      print('Error generating subscription meal: $e');
      return {'error': 'Failed to generate meal for subscription: $e'};
    }
  }

  /// Edit existing meal plan with new preferences
  static Future<Map<String, dynamic>?> editMealPlan({
    required Map<String, dynamic> currentMealPlan,
    required String userEmail,
    required String petId,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      // Get current pet data for context
      Map<String, dynamic> petData = await DataBase.readData(userEmail, petId);
      
      // Create modification request based on preferences
      String modificationPrompt = _buildMealModificationPrompt(currentMealPlan, preferences, petData);
      
      // Use Gemini to modify the meal plan
      Map<String, dynamic>? modifiedMeal = await GeminiMealService.generateOptimalPersonalizedMealWithData(
        petData: {
          ...petData,
          'mealModificationRequest': modificationPrompt,
          'currentMealPlan': currentMealPlan,
          'userPreferences': preferences,
        },
      );

      if (modifiedMeal != null && !modifiedMeal.containsKey('error')) {
        modifiedMeal['modifiedAt'] = DateTime.now().toIso8601String();
        modifiedMeal['originalMeal'] = currentMealPlan['name'] ?? 'Original Plan';
        modifiedMeal['modificationType'] = 'user_edit';
      }

      return modifiedMeal;
    } catch (e) {
      print('Error editing meal plan: $e');
      return {'error': 'Failed to edit meal plan: $e'};
    }
  }

  /// Save meal plan to subscription
  static Future<bool> saveMealToSubscription({
    required String subscriptionId,
    required Map<String, dynamic> mealPlan,
  }) async {
    try {
      var db = FirebaseFirestore.instance;
      
      await db.collection('subscriptions').doc(subscriptionId).update({
        'selectedMealPlan': mealPlan,
        'mealPlan': mealPlan['name'] ?? 'Custom Meal Plan',
        'mealPlanDetails': mealPlan,
        'lastMealUpdate': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Also save to meal history
      await db.collection('mealHistory').add({
        'subscriptionId': subscriptionId,
        'mealPlan': mealPlan,
        'savedAt': DateTime.now().toIso8601String(),
        'type': 'subscription_update',
      });

      return true;
    } catch (e) {
      print('Error saving meal to subscription: $e');
      return false;
    }
  }

  static double _calculatePortionSize(String dogSize) {
    switch (dogSize.toLowerCase()) {
      case 'small':
        return 0.7; // 70% of base portion
      case 'medium':
        return 1.0; // 100% of base portion
      case 'large':
        return 1.4; // 140% of base portion
      default:
        return 1.0;
    }
  }

  static Map<String, dynamic> _generateDeliverySchedule(String frequency) {
    DateTime now = DateTime.now();
    List<DateTime> deliveryDates = [];

    if (frequency == '1x/week') {
      // Weekly deliveries for next 4 weeks
      for (int i = 1; i <= 4; i++) {
        deliveryDates.add(now.add(Duration(days: 7 * i)));
      }
    } else if (frequency == '2x/week') {
      // Twice weekly deliveries for next 4 weeks
      for (int i = 0; i < 4; i++) {
        deliveryDates.add(now.add(Duration(days: 3 + (7 * i)))); // Wednesday
        deliveryDates.add(now.add(Duration(days: 7 + (7 * i)))); // Sunday
      }
    }

    return {
      'frequency': frequency,
      'nextDeliveryDate': deliveryDates.isNotEmpty ? deliveryDates.first.toIso8601String() : null,
      'upcomingDeliveries': deliveryDates.map((date) => date.toIso8601String()).toList(),
      'scheduledAt': DateTime.now().toIso8601String(),
    };
  }

  static Future<List<Map<String, dynamic>>> _generateMealVariations(Map<String, dynamic> baseMeal) async {
    // For 2x/week subscriptions, create meal variations
    List<Map<String, dynamic>> variations = [];
    
    // Create a lighter variation for the second meal of the week
    Map<String, dynamic> variation1 = Map<String, dynamic>.from(baseMeal);
    variation1['name'] = '${baseMeal['name']} - Light Variation';
    variation1['description'] = 'Lighter version for the second meal of the week';
    variation1['calories'] = ((baseMeal['calories'] ?? 400) * 0.8).round(); // 20% fewer calories
    variation1['variationType'] = 'light';
    
    variations.add(variation1);

    return variations;
  }

  static String _buildMealModificationPrompt(
    Map<String, dynamic> currentMeal,
    Map<String, dynamic>? preferences,
    Map<String, dynamic> petData,
  ) {
    String prompt = 'Please modify the current meal plan based on the following preferences:\n\n';
    prompt += 'Current Meal: ${currentMeal['name'] ?? 'Unknown'}\n';
    prompt += 'Current Ingredients: ${(currentMeal['ingredients'] as List<dynamic>?)?.join(', ') ?? 'Not specified'}\n\n';
    
    if (preferences != null) {
      if (preferences['addIngredients'] != null) {
        prompt += 'Add these ingredients: ${preferences['addIngredients']}\n';
      }
      if (preferences['removeIngredients'] != null) {
        prompt += 'Remove these ingredients: ${preferences['removeIngredients']}\n';
      }
      if (preferences['changeProtein'] != null) {
        prompt += 'Change protein to: ${preferences['changeProtein']}\n';
      }
      if (preferences['dietaryRestrictions'] != null) {
        prompt += 'Consider these dietary restrictions: ${preferences['dietaryRestrictions']}\n';
      }
      if (preferences['preferredFlavors'] != null) {
        prompt += 'Include these preferred flavors: ${preferences['preferredFlavors']}\n';
      }
    }

    prompt += '\nPet Information:\n';
    prompt += 'Name: ${petData['Name'] ?? 'Unknown'}\n';
    prompt += 'Breed: ${petData['Breed'] ?? 'Unknown'}\n';
    prompt += 'Weight: ${petData['weight'] ?? 'Unknown'} ${petData['weightUnit'] ?? ''}\n';
    
    return prompt;
  }
}
