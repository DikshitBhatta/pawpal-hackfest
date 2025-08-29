class MealPlanModel {
  final String petName;
  final String nutritionalStrategy;
  final List<MealModel> meals;
  final HealthGuidelinesModel healthGuidelines;

  MealPlanModel({
    required this.petName,
    required this.nutritionalStrategy,
    required this.meals,
    required this.healthGuidelines,
  });

  static MealPlanModel fromGeminiText(String geminiResponse) {
    // Parse the Gemini response text and extract structured data
    String petName = _extractSection(geminiResponse, 'PERSONALIZED MEAL PLAN FOR', '\n');
    String nutritionalStrategy = _extractSection(geminiResponse, '📊 NUTRITIONAL STRATEGY:', '🌅');
    
    List<MealModel> meals = [];
    
    // Extract breakfast
    String breakfastSection = _extractMealSection(geminiResponse, '🌅 BREAKFAST', '☀️');
    if (breakfastSection.isNotEmpty) {
      meals.add(MealModel.fromText(breakfastSection, MealType.breakfast));
    }
    
    // Extract lunch
    String lunchSection = _extractMealSection(geminiResponse, '☀️ LUNCH', '🌙');
    if (lunchSection.isNotEmpty) {
      meals.add(MealModel.fromText(lunchSection, MealType.lunch));
    }
    
    // Extract dinner
    String dinnerSection = _extractMealSection(geminiResponse, '🌙 DINNER', '💡');
    if (dinnerSection.isNotEmpty) {
      meals.add(MealModel.fromText(dinnerSection, MealType.dinner));
    }
    
    // Extract health guidelines
    String healthSection = _extractSection(geminiResponse, '💡 HEALTH-FOCUSED FEEDING GUIDELINES:', '');
    HealthGuidelinesModel healthGuidelines = HealthGuidelinesModel.fromText(healthSection);
    
    return MealPlanModel(
      petName: petName.trim(),
      nutritionalStrategy: nutritionalStrategy.trim(),
      meals: meals,
      healthGuidelines: healthGuidelines,
    );
  }

  static String _extractSection(String text, String startMarker, String endMarker) {
    int startIndex = text.indexOf(startMarker);
    if (startIndex == -1) return '';
    
    startIndex += startMarker.length;
    
    int endIndex = endMarker.isEmpty ? text.length : text.indexOf(endMarker, startIndex);
    if (endIndex == -1) endIndex = text.length;
    
    return text.substring(startIndex, endIndex).trim();
  }

  static String _extractMealSection(String text, String startMarker, String endMarker) {
    int startIndex = text.indexOf(startMarker);
    if (startIndex == -1) return '';
    
    int endIndex = text.indexOf(endMarker, startIndex);
    if (endIndex == -1) endIndex = text.length;
    
    return text.substring(startIndex, endIndex).trim();
  }
}

enum MealType { breakfast, lunch, dinner }

class MealModel {
  final MealType type;
  final String time;
  final String name;
  final List<String> ingredients;
  final List<String> preparation;
  final String healthBenefits;

  MealModel({
    required this.type,
    required this.time,
    required this.name,
    required this.ingredients,
    required this.preparation,
    required this.healthBenefits,
  });

  static MealModel fromText(String mealText, MealType type) {
    String time = _extractLineValue(mealText, 'Time:');
    String name = _extractLineValue(mealText, 'Meal Name:');
    
    List<String> ingredients = _extractListSection(mealText, 'Ingredients:', 'Preparation:');
    List<String> preparation = _extractListSection(mealText, 'Preparation:', 'Health Benefits:');
    String healthBenefits = _extractLineValue(mealText, 'Health Benefits:');
    
    return MealModel(
      type: type,
      time: time,
      name: name,
      ingredients: ingredients,
      preparation: preparation,
      healthBenefits: healthBenefits,
    );
  }

  static String _extractLineValue(String text, String marker) {
    List<String> lines = text.split('\n');
    for (String line in lines) {
      if (line.contains(marker)) {
        return line.split(marker).last.trim();
      }
    }
    return '';
  }

  static List<String> _extractListSection(String text, String startMarker, String endMarker) {
    int startIndex = text.indexOf(startMarker);
    if (startIndex == -1) return [];
    
    int endIndex = text.indexOf(endMarker, startIndex);
    if (endIndex == -1) endIndex = text.length;
    
    String section = text.substring(startIndex + startMarker.length, endIndex);
    return section
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) => line.trim().replaceFirst(RegExp(r'^-\s*'), ''))
        .toList();
  }

  String get emoji {
    switch (type) {
      case MealType.breakfast:
        return '🌅';
      case MealType.lunch:
        return '☀️';
      case MealType.dinner:
        return '🌙';
    }
  }

  String get typeDisplayName {
    switch (type) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
    }
  }
}

class HealthGuidelinesModel {
  final String totalDailyCalories;
  final String feedingSchedule;
  final String digestiveHealthTips;
  final String activityLevelAdjustments;
  final String healthGoalProgress;
  final String favoriteFoodIntegration;
  final String allergyManagement;
  final String weeklyMonitoring;

  HealthGuidelinesModel({
    required this.totalDailyCalories,
    required this.feedingSchedule,
    required this.digestiveHealthTips,
    required this.activityLevelAdjustments,
    required this.healthGoalProgress,
    required this.favoriteFoodIntegration,
    required this.allergyManagement,
    required this.weeklyMonitoring,
  });

  static HealthGuidelinesModel fromText(String text) {
    return HealthGuidelinesModel(
      totalDailyCalories: _extractGuidelineValue(text, 'Total Daily Calories:'),
      feedingSchedule: _extractGuidelineValue(text, 'Feeding Schedule:'),
      digestiveHealthTips: _extractGuidelineValue(text, 'Digestive Health Tips:'),
      activityLevelAdjustments: _extractGuidelineValue(text, 'Activity Level Adjustments:'),
      healthGoalProgress: _extractGuidelineValue(text, 'Health Goal Progress:'),
      favoriteFoodIntegration: _extractGuidelineValue(text, 'Favorite Food Integration:'),
      allergyManagement: _extractGuidelineValue(text, 'Allergy Management:'),
      weeklyMonitoring: _extractGuidelineValue(text, 'Weekly Monitoring:'),
    );
  }

  static String _extractGuidelineValue(String text, String marker) {
    List<String> lines = text.split('\n');
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains(marker)) {
        String value = lines[i].split(marker).last.trim();
        
        // If the value starts with '[', get the content within brackets
        if (value.startsWith('[') && value.contains(']')) {
          int endBracket = value.indexOf(']');
          value = value.substring(1, endBracket);
        }
        
        return value;
      }
    }
    return '';
  }
}
