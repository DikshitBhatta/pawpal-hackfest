import 'package:flutter/material.dart';
import 'package:pet_care/ColorsScheme.dart';
import 'package:pet_care/Subscription/PaymentScreen.dart';

class MealRecommendationScreen extends StatefulWidget {
  final Map<String, dynamic> subscriptionData;
  
  const MealRecommendationScreen({super.key, required this.subscriptionData});

  @override
  State<MealRecommendationScreen> createState() => _MealRecommendationScreenState();
}

class _MealRecommendationScreenState extends State<MealRecommendationScreen> {
  Map<String, dynamic>? selectedMealPlan;

  List<Map<String, dynamic>> getMealRecommendations() {
    String dogSize = widget.subscriptionData['dogSize'];
    List<String> healthGoals = List<String>.from(widget.subscriptionData['healthGoals'] ?? []);
    List<String> foodAllergies = List<String>.from(widget.subscriptionData['foodAllergies'] ?? []);
    String activityLevel = widget.subscriptionData['activityLevel'] ?? '';

    List<Map<String, dynamic>> recommendations = [
      {
        'name': 'Chicken & Pumpkin Supreme',
        'description': 'Premium blend with lean chicken, organic pumpkin, and essential vitamins',
        'ingredients': ['Free-range chicken', 'Organic pumpkin', 'Sweet potatoes', 'Carrots', 'Spinach'],
        'benefits': ['High protein', 'Easy digestion', 'Skin & coat health'],
        'suitable': ['Diet', 'Senior Care', 'Muscle Building'],
        'price': _getMealPrice('premium'),
        'rating': 4.8,
        'image': '🍗',
        'calories': _getCaloriesBySize(dogSize, 'high'),
      },
      {
        'name': 'Salmon & Carrot Delight',
        'description': 'Ocean-fresh salmon with garden carrots for optimal nutrition',
        'ingredients': ['Wild salmon', 'Organic carrots', 'Brown rice', 'Peas', 'Blueberries'],
        'benefits': ['Omega-3 rich', 'Joint support', 'Brain health'],
        'suitable': ['Joint Care', 'Skin Care', 'Senior Care'],
        'price': _getMealPrice('premium'),
        'rating': 4.7,
        'image': '🐟',
        'calories': _getCaloriesBySize(dogSize, 'medium'),
      },
      {
        'name': 'Turkey & Rice Balance',
        'description': 'Gentle turkey with brown rice, perfect for sensitive stomachs',
        'ingredients': ['Ground turkey', 'Brown rice', 'Green beans', 'Cranberries', 'Herbs'],
        'benefits': ['Gentle on stomach', 'Balanced nutrition', 'Weight management'],
        'suitable': ['Diet', 'Senior Care'],
        'price': _getMealPrice('standard'),
        'rating': 4.6,
        'image': '🦃',
        'calories': _getCaloriesBySize(dogSize, 'low'),
      },
      {
        'name': 'Beef & Vegetable Power',
        'description': 'Hearty beef with mixed vegetables for active dogs',
        'ingredients': ['Grass-fed beef', 'Mixed vegetables', 'Quinoa', 'Kale', 'Turmeric'],
        'benefits': ['High energy', 'Muscle building', 'Antioxidants'],
        'suitable': ['Muscle Building', 'Joint Care'],
        'price': _getMealPrice('premium'),
        'rating': 4.9,
        'image': '🥩',
        'calories': _getCaloriesBySize(dogSize, 'high'),
      },
    ];

    // Filter based on allergies
    if (foodAllergies.isNotEmpty) {
      recommendations = recommendations.where((meal) {
        return !meal['ingredients'].any((ingredient) =>
            foodAllergies.any((allergy) =>
                ingredient.toLowerCase().contains(allergy.toLowerCase())));
      }).toList();
    }

    // Sort by health goals match
    recommendations.sort((a, b) {
      int aScore = 0;
      int bScore = 0;
      for (String goal in healthGoals) {
        if (a['suitable'].contains(goal)) aScore++;
        if (b['suitable'].contains(goal)) bScore++;
      }
      return bScore.compareTo(aScore);
    });

    // Consider activity level for high-energy meals
    if (activityLevel == 'High') {
      recommendations = recommendations.where((meal) => meal['calories'] >= 350).toList()
        + recommendations.where((meal) => meal['calories'] < 350).toList();
    }

    return recommendations;
  }

  double _getMealPrice(String tier) {
    // Use the base meal cost from subscription data if available
    double baseCost = widget.subscriptionData['baseMealCost'] ?? 8.99;
    double portionMultiplier = widget.subscriptionData['portionMultiplier'] ?? 1.0;
    
    switch (tier) {
      case 'premium':
        return (baseCost * portionMultiplier * 1.3); // 30% premium for premium tier
      case 'standard':
        return (baseCost * portionMultiplier);
      default:
        return (baseCost * portionMultiplier * 0.8); // 20% discount for basic tier
    }
  }

  int _getCaloriesBySize(String size, String intensity) {
    Map<String, Map<String, int>> calorieChart = {
      'Small': {'low': 200, 'medium': 250, 'high': 300},
      'Medium': {'low': 350, 'medium': 400, 'high': 450},
      'Large': {'low': 500, 'medium': 600, 'high': 700},
    };
    return calorieChart[size]?[intensity] ?? 350;
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> recommendations = getMealRecommendations();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Meal Recommendations",
          style: TextStyle(
            fontSize: 24,
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
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey.shade50, Colors.grey.shade200],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subscription summary
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: listTileColor,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            '🍽️',
                            style: TextStyle(fontSize: 24),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Plan: ${widget.subscriptionData['dogSize']} Dog',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '${widget.subscriptionData['frequency']} • \$${widget.subscriptionData['monthlyPrice'].toStringAsFixed(2)}/month',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (widget.subscriptionData['healthGoals'] != null && 
                          (widget.subscriptionData['healthGoals'] as List).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Wrap(
                            spacing: 8,
                            children: (widget.subscriptionData['healthGoals'] as List)
                                .map<Widget>((goal) => Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    goal,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ))
                                .toList(),
                          ),
                        ),
                    ],
                  ),
                ),

                SizedBox(height: 30),

                Text(
                  '🌟 Recommended Meals for ${widget.subscriptionData['Name']}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                
                SizedBox(height: 15),

                // Meal recommendations
                ...recommendations.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, dynamic> meal = entry.value;
                  bool isRecommended = index == 0; // First item is most recommended
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedMealPlan = meal;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: selectedMealPlan != null && selectedMealPlan!['name'] == meal['name']
                              ? Colors.green.shade100 
                              : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: selectedMealPlan != null && selectedMealPlan!['name'] == meal['name']
                                ? Colors.green 
                                : (isRecommended ? Colors.orange : Colors.grey.shade300),
                            width: isRecommended ? 3 : 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Center(
                                    child: Text(
                                      meal['image'],
                                      style: TextStyle(fontSize: 24),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              meal['name'],
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (isRecommended)
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.orange,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                'Top Choice',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.star, color: Colors.orange, size: 16),
                                          Text(
                                            ' ${meal['rating']} • ${meal['calories']} cal',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '\$${meal['price'].toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                    Text(
                                      'per meal',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                if (selectedMealPlan == meal['name'])
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 24,
                                    ),
                                  ),
                              ],
                            ),
                            
                            SizedBox(height: 12),
                            
                            Text(
                              meal['description'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            
                            SizedBox(height: 12),
                            
                            // Benefits tags
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: (meal['benefits'] as List<String>)
                                  .map((benefit) => Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      benefit,
                                      style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ))
                                  .toList(),
                            ),
                            
                            SizedBox(height: 8),
                            
                            // Ingredients
                            ExpansionTile(
                              title: Text(
                                'Ingredients',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              tilePadding: EdgeInsets.zero,
                              childrenPadding: EdgeInsets.zero,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: (meal['ingredients'] as List<String>)
                                        .map((ingredient) => Text(
                                          '• $ingredient',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ))
                                        .toList(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),

                SizedBox(height: 30),

                // Proceed button
                if (selectedMealPlan != null)
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Map<String, dynamic> finalSubscriptionData = {
                          ...widget.subscriptionData,
                          'selectedMealPlan': selectedMealPlan!, // Pass the full meal plan object
                          'mealPrice': selectedMealPlan!['price'],
                        };
                        
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentScreen(
                              subscriptionData: finalSubscriptionData,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 5,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.payment,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Proceed to Payment',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
