import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/currency_utils.dart';

/// Script to update existing Firestore ingredients from USD to THB pricing
/// 
/// This script should be run once to convert all existing ingredient prices
/// from USD to THB in the Firestore database.
class CurrencyMigrationScript {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Update all ingredients in Firestore to use THB instead of USD
  static Future<void> updateIngredientsToTHB() async {
    try {
      print('🔄 Starting currency migration from USD to THB...');
      
      // Get all ingredients from Firestore
      QuerySnapshot ingredientsSnapshot = await _firestore
          .collection('ingredients')
          .get();

      int updatedCount = 0;
      
      for (QueryDocumentSnapshot doc in ingredientsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Check if the ingredient has a price field
        if (data.containsKey('price')) {
          double currentPrice = (data['price'] as num).toDouble();
          
          // Convert USD to THB
          double thbPrice = CurrencyUtils.convertUsdToThb(currentPrice);
          
          // Update the document
          await doc.reference.update({
            'price': thbPrice,
            'currency': 'THB',
            'originalUsdPrice': currentPrice, // Keep for reference
            'lastCurrencyUpdate': FieldValue.serverTimestamp(),
          });
          
          updatedCount++;
          print('✅ Updated ${data['name'] ?? 'Unknown'}: \$${currentPrice.toStringAsFixed(2)} → ${CurrencyUtils.formatThb(thbPrice)}');
        }
      }
      
      print('🎉 Currency migration completed! Updated $updatedCount ingredients.');
      
    } catch (e) {
      print('❌ Error during currency migration: $e');
    }
  }

  /// Update meal prices in any existing subscriptions to THB
  static Future<void> updateSubscriptionsToTHB() async {
    try {
      print('🔄 Starting subscription price migration...');
      
      // Get all subscriptions
      QuerySnapshot subscriptionsSnapshot = await _firestore
          .collection('subscriptions')
          .get();

      int updatedCount = 0;
      
      for (QueryDocumentSnapshot doc in subscriptionsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        bool needsUpdate = false;
        Map<String, dynamic> updates = {};
        
        // Update monthly price if it exists
        if (data.containsKey('monthlyPrice')) {
          double currentPrice = (data['monthlyPrice'] as num).toDouble();
          double thbPrice = CurrencyUtils.convertUsdToThb(currentPrice);
          updates['monthlyPrice'] = thbPrice;
          updates['originalUsdMonthlyPrice'] = currentPrice;
          needsUpdate = true;
        }
        
        // Update meal price if it exists
        if (data.containsKey('mealPrice')) {
          double currentPrice = (data['mealPrice'] as num).toDouble();
          double thbPrice = CurrencyUtils.convertUsdToThb(currentPrice);
          updates['mealPrice'] = thbPrice;
          updates['originalUsdMealPrice'] = currentPrice;
          needsUpdate = true;
        }
        
        if (needsUpdate) {
          updates['currency'] = 'THB';
          updates['lastCurrencyUpdate'] = FieldValue.serverTimestamp();
          
          await doc.reference.update(updates);
          updatedCount++;
          print('✅ Updated subscription for ${data['petName'] ?? 'Unknown pet'}');
        }
      }
      
      print('🎉 Subscription migration completed! Updated $updatedCount subscriptions.');
      
    } catch (e) {
      print('❌ Error during subscription migration: $e');
    }
  }

  /// Add sample THB ingredients to Firestore for testing
  static Future<void> addSampleThbIngredients() async {
    try {
      print('🔄 Adding sample THB ingredients...');
      
      List<Map<String, dynamic>> sampleIngredients = [
        {
          'name': 'Premium Chicken Breast',
          'price': CurrencyUtils.convertUsdToThb(3.50), // ~126 THB
          'currency': 'THB',
          'category': 'Protein',
          'nutritionalValue': {'protein': 25, 'fat': 3, 'carbs': 0},
          'description': 'High-quality lean protein source',
        },
        {
          'name': 'Sweet Potato',
          'price': CurrencyUtils.convertUsdToThb(1.20), // ~43 THB
          'currency': 'THB',
          'category': 'Carbohydrate',
          'nutritionalValue': {'protein': 2, 'fat': 0, 'carbs': 20},
          'description': 'Nutritious complex carbohydrate',
        },
        {
          'name': 'Salmon Oil',
          'price': CurrencyUtils.convertUsdToThb(2.80), // ~101 THB
          'currency': 'THB',
          'category': 'Fat',
          'nutritionalValue': {'protein': 0, 'fat': 100, 'carbs': 0},
          'description': 'Rich in omega-3 fatty acids',
        },
        {
          'name': 'Brown Rice',
          'price': CurrencyUtils.convertUsdToThb(0.80), // ~29 THB
          'currency': 'THB',
          'category': 'Carbohydrate',
          'nutritionalValue': {'protein': 3, 'fat': 1, 'carbs': 45},
          'description': 'Easily digestible grain',
        },
        {
          'name': 'Carrots',
          'price': CurrencyUtils.convertUsdToThb(0.60), // ~22 THB
          'currency': 'THB',
          'category': 'Vegetable',
          'nutritionalValue': {'protein': 1, 'fat': 0, 'carbs': 10},
          'description': 'Rich in beta-carotene and fiber',
        },
      ];
      
      for (Map<String, dynamic> ingredient in sampleIngredients) {
        await _firestore.collection('ingredients').add({
          ...ingredient,
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });
        
        print('✅ Added ${ingredient['name']}: ${CurrencyUtils.formatThb(ingredient['price'])}');
      }
      
      print('🎉 Sample THB ingredients added successfully!');
      
    } catch (e) {
      print('❌ Error adding sample ingredients: $e');
    }
  }

  /// Main migration function to run all currency updates
  static Future<void> runFullCurrencyMigration() async {
    print('🚀 Starting full currency migration to THB...');
    print('Exchange rate: 1 USD = ${CurrencyUtils.USD_TO_THB_RATE} THB');
    print('');
    
    await updateIngredientsToTHB();
    print('');
    await updateSubscriptionsToTHB();
    print('');
    await addSampleThbIngredients();
    print('');
    
    print('🎊 Full currency migration completed successfully!');
    print('Your app is now using Thai Baht (THB) currency! 🇹🇭');
  }
}
