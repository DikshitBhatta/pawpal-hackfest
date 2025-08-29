import 'package:cloud_firestore/cloud_firestore.dart';

class SampleDataHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Adds sample ingredients to the database if none exist
  static Future<void> addSampleIngredientsIfEmpty() async {
    try {
      // Check if ingredients collection has any documents
      final QuerySnapshot snapshot = await _firestore
          .collection('ingredients')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        print('No ingredients found. Adding sample ingredients...');
        await _addSampleIngredients();
        print('Sample ingredients added successfully!');
      } else {
        print('Ingredients already exist in database (${snapshot.docs.length} found)');
      }
    } catch (e) {
      print('Error checking/adding sample ingredients: $e');
    }
  }

  static Future<void> _addSampleIngredients() async {
    final List<Map<String, dynamic>> sampleIngredients = [
      // Protein Sources
      {
        'name': 'Chicken Breast',
        'category': 'Protein',
        'protein': 31.0,
        'fat': 3.6,
        'fiber': 0.0,
        'calcium': 15.0,
        'iron': 1.0,
        'vitaminA': 21.0,
        'vitaminC': 0.0,
        'vitaminD': 0.1,
        'omega3': 0.08,
        'stock': 25.0,
        'unit': 'kg',
        'availability': true,
        'pricePerUnit': 12.99,
      },
      {
        'name': 'Salmon Fillet',
        'category': 'Protein',
        'protein': 25.4,
        'fat': 13.4,
        'fiber': 0.0,
        'calcium': 12.0,
        'iron': 0.8,
        'vitaminA': 58.0,
        'vitaminC': 0.0,
        'vitaminD': 11.1,
        'omega3': 2.3,
        'stock': 15.0,
        'unit': 'kg',
        'availability': true,
        'pricePerUnit': 18.99,
      },
      {
        'name': 'Lean Beef',
        'category': 'Protein',
        'protein': 26.1,
        'fat': 15.0,
        'fiber': 0.0,
        'calcium': 18.0,
        'iron': 2.6,
        'vitaminA': 0.0,
        'vitaminC': 0.0,
        'vitaminD': 0.1,
        'omega3': 0.05,
        'stock': 20.0,
        'unit': 'kg',
        'availability': true,
        'pricePerUnit': 16.99,
      },
      {
        'name': 'Turkey',
        'category': 'Protein',
        'protein': 29.0,
        'fat': 7.0,
        'fiber': 0.0,
        'calcium': 20.0,
        'iron': 1.4,
        'vitaminA': 0.0,
        'vitaminC': 0.0,
        'vitaminD': 0.1,
        'omega3': 0.06,
        'stock': 18.0,
        'unit': 'kg',
        'availability': true,
        'pricePerUnit': 14.99,
      },
      {
        'name': 'Lamb',
        'category': 'Protein',
        'protein': 25.6,
        'fat': 20.9,
        'fiber': 0.0,
        'calcium': 17.0,
        'iron': 1.9,
        'vitaminA': 0.0,
        'vitaminC': 0.0,
        'vitaminD': 0.1,
        'omega3': 0.18,
        'stock': 12.0,
        'unit': 'kg',
        'availability': true,
        'pricePerUnit': 22.99,
      },

      // Carbohydrates
      {
        'name': 'Sweet Potato',
        'category': 'Carbohydrate',
        'protein': 2.0,
        'fat': 0.1,
        'fiber': 3.0,
        'calcium': 30.0,
        'iron': 0.6,
        'vitaminA': 1043.0,
        'vitaminC': 2.4,
        'vitaminD': 0.0,
        'omega3': 0.0,
        'stock': 30.0,
        'unit': 'kg',
        'availability': true,
        'pricePerUnit': 3.99,
      },
      {
        'name': 'Brown Rice',
        'category': 'Carbohydrate',
        'protein': 7.9,
        'fat': 2.9,
        'fiber': 3.5,
        'calcium': 23.0,
        'iron': 1.5,
        'vitaminA': 0.0,
        'vitaminC': 0.0,
        'vitaminD': 0.0,
        'omega3': 0.027,
        'stock': 40.0,
        'unit': 'kg',
        'availability': true,
        'pricePerUnit': 2.99,
      },
      {
        'name': 'Quinoa',
        'category': 'Carbohydrate',
        'protein': 14.1,
        'fat': 6.1,
        'fiber': 7.0,
        'calcium': 47.0,
        'iron': 4.6,
        'vitaminA': 1.0,
        'vitaminC': 0.0,
        'vitaminD': 0.0,
        'omega3': 0.085,
        'stock': 25.0,
        'unit': 'kg',
        'availability': true,
        'pricePerUnit': 8.99,
      },
      {
        'name': 'Pumpkin',
        'category': 'Vegetable',
        'protein': 1.0,
        'fat': 0.1,
        'fiber': 0.5,
        'calcium': 21.0,
        'iron': 0.8,
        'vitaminA': 426.0,
        'vitaminC': 9.0,
        'vitaminD': 0.0,
        'omega3': 0.0,
        'stock': 35.0,
        'unit': 'kg',
        'availability': true,
        'pricePerUnit': 2.49,
      },

      // Vegetables
      {
        'name': 'Carrots',
        'category': 'Vegetable',
        'protein': 0.9,
        'fat': 0.2,
        'fiber': 2.8,
        'calcium': 33.0,
        'iron': 0.3,
        'vitaminA': 835.0,
        'vitaminC': 5.9,
        'vitaminD': 0.0,
        'omega3': 0.0,
        'stock': 22.0,
        'unit': 'kg',
        'availability': true,
        'pricePerUnit': 1.99,
      },
      {
        'name': 'Spinach',
        'category': 'Vegetable',
        'protein': 2.9,
        'fat': 0.4,
        'fiber': 2.2,
        'calcium': 99.0,
        'iron': 2.7,
        'vitaminA': 469.0,
        'vitaminC': 28.1,
        'vitaminD': 0.0,
        'omega3': 0.138,
        'stock': 18.0,
        'unit': 'kg',
        'availability': true,
        'pricePerUnit': 4.99,
      },
      {
        'name': 'Broccoli',
        'category': 'Vegetable',
        'protein': 2.8,
        'fat': 0.4,
        'fiber': 2.6,
        'calcium': 47.0,
        'iron': 0.7,
        'vitaminA': 31.0,
        'vitaminC': 89.2,
        'vitaminD': 0.0,
        'omega3': 0.021,
        'stock': 20.0,
        'unit': 'kg',
        'availability': true,
        'pricePerUnit': 3.49,
      },
      {
        'name': 'Green Beans',
        'category': 'Vegetable',
        'protein': 1.8,
        'fat': 0.2,
        'fiber': 2.7,
        'calcium': 37.0,
        'iron': 1.0,
        'vitaminA': 35.0,
        'vitaminC': 12.2,
        'vitaminD': 0.0,
        'omega3': 0.0,
        'stock': 15.0,
        'unit': 'kg',
        'availability': true,
        'pricePerUnit': 2.79,
      },

      // Fruits
      {
        'name': 'Blueberries',
        'category': 'Fruit',
        'protein': 0.7,
        'fat': 0.3,
        'fiber': 2.4,
        'calcium': 6.0,
        'iron': 0.3,
        'vitaminA': 3.0,
        'vitaminC': 9.7,
        'vitaminD': 0.0,
        'omega3': 0.058,
        'stock': 8.0,
        'unit': 'kg',
        'availability': true,
        'pricePerUnit': 12.99,
      },
      {
        'name': 'Apple (without seeds)',
        'category': 'Fruit',
        'protein': 0.3,
        'fat': 0.2,
        'fiber': 2.4,
        'calcium': 6.0,
        'iron': 0.1,
        'vitaminA': 3.0,
        'vitaminC': 4.6,
        'vitaminD': 0.0,
        'omega3': 0.009,
        'stock': 25.0,
        'unit': 'kg',
        'availability': true,
        'pricePerUnit': 3.99,
      },

      // Healthy Fats
      {
        'name': 'Fish Oil',
        'category': 'Supplement',
        'protein': 0.0,
        'fat': 100.0,
        'fiber': 0.0,
        'calcium': 0.0,
        'iron': 0.0,
        'vitaminA': 30000.0,
        'vitaminC': 0.0,
        'vitaminD': 1000.0,
        'omega3': 30.0,
        'stock': 5.0,
        'unit': 'liters',
        'availability': true,
        'pricePerUnit': 29.99,
      },
      {
        'name': 'Coconut Oil',
        'category': 'Fat',
        'protein': 0.0,
        'fat': 99.1,
        'fiber': 0.0,
        'calcium': 0.0,
        'iron': 0.0,
        'vitaminA': 0.0,
        'vitaminC': 0.0,
        'vitaminD': 0.0,
        'omega3': 0.0,
        'stock': 10.0,
        'unit': 'liters',
        'availability': true,
        'pricePerUnit': 15.99,
      },

      // Supplements
      {
        'name': 'Calcium Supplement',
        'category': 'Supplement',
        'protein': 0.0,
        'fat': 0.0,
        'fiber': 0.0,
        'calcium': 500.0,
        'iron': 0.0,
        'vitaminA': 0.0,
        'vitaminC': 0.0,
        'vitaminD': 400.0,
        'omega3': 0.0,
        'stock': 50.0,
        'unit': 'tablets',
        'availability': true,
        'pricePerUnit': 19.99,
      },
      {
        'name': 'Probiotic Powder',
        'category': 'Supplement',
        'protein': 0.0,
        'fat': 0.0,
        'fiber': 0.0,
        'calcium': 0.0,
        'iron': 0.0,
        'vitaminA': 0.0,
        'vitaminC': 0.0,
        'vitaminD': 0.0,
        'omega3': 0.0,
        'stock': 30.0,
        'unit': 'grams',
        'availability': true,
        'pricePerUnit': 24.99,
      },
    ];

    // Add each ingredient to Firestore
    final batch = _firestore.batch();
    
    for (final ingredient in sampleIngredients) {
      final docRef = _firestore.collection('ingredients').doc();
      batch.set(docRef, {
        ...ingredient,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// Force refresh ingredients (useful for testing)
  static Future<void> refreshSampleIngredients() async {
    try {
      // Delete all existing ingredients
      final QuerySnapshot snapshot = await _firestore
          .collection('ingredients')
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Add fresh sample ingredients
      await _addSampleIngredients();
      print('Sample ingredients refreshed successfully!');
    } catch (e) {
      print('Error refreshing sample ingredients: $e');
    }
  }
}
