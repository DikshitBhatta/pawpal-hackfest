import 'package:cloud_firestore/cloud_firestore.dart';

class IngredientService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches all available ingredients from Firestore
  /// Returns only ingredients where availability == true and stock > 0
  static Future<List<Map<String, dynamic>>> fetchAvailableIngredients() async {
    try {
      print('🔍 Fetching ingredients from Firestore...');
      
      // First, try to get all ingredients to debug
      final QuerySnapshot allSnapshot = await _firestore
          .collection('ingredients')
          .get();
      
      print('📊 Total ingredients in database: ${allSnapshot.docs.length}');
      
      // Check each document for debugging
      if (allSnapshot.docs.isNotEmpty) {
        for (int i = 0; i < allSnapshot.docs.length && i < 3; i++) {
          final doc = allSnapshot.docs[i];
          final data = doc.data() as Map<String, dynamic>;
          print('📋 Sample ingredient #${i + 1}:');
          print('   ID: ${doc.id}');
          print('   Fields: ${data.keys.toList()}');
          print('   Name: ${data['name']}');
          print('   Availability: ${data['availability']} (type: ${data['availability'].runtimeType})');
          print('   Stock: ${data['stock']} (type: ${data['stock'].runtimeType})');
        }
      }

      // Try different approaches to get ingredients
      List<Map<String, dynamic>> ingredients = [];

      // Approach 1: Get all and filter manually (most reliable)
      print('🔄 Attempting to fetch all ingredients and filter manually...');
      for (var doc in allSnapshot.docs) {
        Map<String, dynamic> ingredient = doc.data() as Map<String, dynamic>;
        ingredient['id'] = doc.id;
        
        // Check availability and stock conditions
        bool isAvailable = ingredient['availability'] == true;
        bool hasStock = false;
        
        if (ingredient['stock'] != null) {
          var stockValue = ingredient['stock'];
          if (stockValue is num) {
            hasStock = stockValue > 0;
          } else if (stockValue is String) {
            try {
              hasStock = double.parse(stockValue) > 0;
            } catch (e) {
              print('⚠️ Could not parse stock value: $stockValue');
            }
          }
        }
        
        print('🧪 ${ingredient['name']}: available=$isAvailable, hasStock=$hasStock (stock=${ingredient['stock']})');
        
        if (isAvailable && hasStock) {
          // Ensure consistent field naming for compatibility
          if (ingredient['stock'] != null && ingredient['stockQuantity'] == null) {
            ingredient['stockQuantity'] = ingredient['stock'];
          }
          ingredients.add(ingredient);
        }
      }

      print('✅ Found ${ingredients.length} available ingredients');
      
      if (ingredients.isEmpty) {
        print('⚠️ No ingredients found! This suggests a data issue.');
        print('💡 Checking if any ingredients exist without filters...');
        
        // Return first few ingredients for debugging, regardless of filters
        for (int i = 0; i < allSnapshot.docs.length && i < 5; i++) {
          var doc = allSnapshot.docs[i];
          Map<String, dynamic> ingredient = doc.data() as Map<String, dynamic>;
          ingredient['id'] = doc.id;
          ingredient['stockQuantity'] = ingredient['stock'] ?? 0;
          ingredients.add(ingredient);
        }
        print('🔧 Returning ${ingredients.length} ingredients for debugging');
      }
      
      return ingredients;
      
    } catch (e) {
      print('❌ Error fetching ingredients: $e');
      print('📍 Error type: ${e.runtimeType}');
      return [];
    }
  }

  /// Filters ingredients to remove allergens for a specific pet
  static List<Map<String, dynamic>> filterAllergens(
      List<Map<String, dynamic>> ingredients, List<String> allergies) {
    
    if (allergies.isEmpty) return ingredients;

    return ingredients.where((ingredient) {
      String ingredientName = (ingredient['name'] ?? '').toLowerCase();
      
      // Check if this ingredient contains any allergens
      for (String allergy in allergies) {
        if (ingredientName.contains(allergy.toLowerCase())) {
          return false; // Filter out this ingredient
        }
      }
      return true; // Keep this ingredient
    }).toList();
  }

  /// Constructs a nutrition summary string for an ingredient
  static String getNutritionSummary(Map<String, dynamic> ingredient) {
    List<String> nutritionParts = [];
    
    // Macronutrients
    if (ingredient['protein'] != null && ingredient['protein'] > 0) {
      nutritionParts.add('Protein: ${ingredient['protein']}g');
    }
    if (ingredient['fat'] != null && ingredient['fat'] > 0) {
      nutritionParts.add('Fat: ${ingredient['fat']}g');
    }
    if (ingredient['fiber'] != null && ingredient['fiber'] > 0) {
      nutritionParts.add('Fiber: ${ingredient['fiber']}g');
    }
    
    // Vitamins
    if (ingredient['vitaminA'] != null && ingredient['vitaminA'] > 0) {
      nutritionParts.add('Vitamin A: ${ingredient['vitaminA']}mg');
    }
    if (ingredient['vitaminC'] != null && ingredient['vitaminC'] > 0) {
      nutritionParts.add('Vitamin C: ${ingredient['vitaminC']}mg');
    }
    if (ingredient['vitaminD'] != null && ingredient['vitaminD'] > 0) {
      nutritionParts.add('Vitamin D: ${ingredient['vitaminD']}mg');
    }
    
    // Minerals
    if (ingredient['calcium'] != null && ingredient['calcium'] > 0) {
      nutritionParts.add('Calcium: ${ingredient['calcium']}mg');
    }
    if (ingredient['iron'] != null && ingredient['iron'] > 0) {
      nutritionParts.add('Iron: ${ingredient['iron']}mg');
    }
    
    // Special nutrients
    if (ingredient['omega3'] != null && ingredient['omega3'] > 0) {
      nutritionParts.add('Omega-3: ${ingredient['omega3']}mg');
    }
    
    return nutritionParts.join(', ');
  }

  /// Gets a simple ingredient description for the prompt
  static String getIngredientDescription(Map<String, dynamic> ingredient) {
    String name = ingredient['name'] ?? 'Unknown';
    String category = ingredient['category'] ?? '';
    String unit = ingredient['unit'] ?? '';
    
    // Handle both 'stock' and 'stockQuantity' field names
    double stockQuantity = 0.0;
    if (ingredient['stockQuantity'] != null) {
      stockQuantity = ingredient['stockQuantity']?.toDouble() ?? 0.0;
    } else if (ingredient['stock'] != null) {
      stockQuantity = ingredient['stock']?.toDouble() ?? 0.0;
    }
    
    String description = name;
    if (category.isNotEmpty) {
      description += ' ($category)';
    }
    
    String nutritionSummary = getNutritionSummary(ingredient);
    if (nutritionSummary.isNotEmpty) {
      description += ' - $nutritionSummary';
    }
    
    description += ' [Stock: ${stockQuantity.toStringAsFixed(1)} $unit]';
    
    return description;
  }
}
