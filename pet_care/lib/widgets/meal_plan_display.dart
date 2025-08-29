import 'package:flutter/material.dart';
import 'package:pet_care/ColorsScheme.dart';

class MealPlanDisplay extends StatelessWidget {
  final Map<String, dynamic> mealPlan;
  final Map<String, dynamic>? petData;
  final double? totalMealPrice;
  const MealPlanDisplay({
    Key? key,
    required this.mealPlan,
    this.petData,
    this.totalMealPrice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMainMealCard(mealPlan, petData, totalMealPrice),
          SizedBox(height: 16),
          if (mealPlan['activity_personalization_note'] != null)
            _buildActivityPersonalizationCard(mealPlan['activity_personalization_note'], petData),
          if (mealPlan['activity_personalization_note'] != null)
            SizedBox(height: 16),
          _buildExpandableDetailsSection(mealPlan),
        ],
      ),
    );
  }

  Widget _buildMainMealCard(Map<String, dynamic> mealPlan, Map<String, dynamic>? petData, double? totalMealPrice) {
    String rawMealName = mealPlan['meal_name'] ?? mealPlan['name'] ?? 'Custom Meal';
    String mealName = _getCleanMealName(rawMealName, petData);
    List<dynamic> ingredients = mealPlan['ingredients'] ?? [];
    String recommendationReason = mealPlan['recommendation_reason'] ?? '';
    String petName = petData != null ? (petData['Name'] ?? petData['petName'] ?? 'your pet') : 'your pet';
    double price = totalMealPrice ?? (mealPlan['total_price'] is num ? mealPlan['total_price'].toDouble() : 0.0);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: headingBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.restaurant_menu,
                    color: TextColor,
                    size: 28,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mealName,
                        style: TextStyle(
                          color: TextColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'For $petName',
                        style: TextStyle(
                          color: TextColor.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '฿${price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: TextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (recommendationReason.isNotEmpty) ...[
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.amber.shade300,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        recommendationReason,
                        style: TextStyle(
                          color: TextColor.withOpacity(0.9),
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 16),
            Text(
              'Ingredients',
              style: TextStyle(
                color: TextColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            _buildIngredientsGrid(ingredients),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientsGrid(List<dynamic> ingredients) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: ingredients.length,
      itemBuilder: (context, index) {
        final ingredient = ingredients[index];
        String name = ingredient['name'] ?? 'Unknown';
        double amount = (ingredient['amount_grams'] ?? 0).toDouble();
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fastfood, color: Colors.orange, size: 16),
                SizedBox(height: 2),
                Text(
                  name,
                  style: TextStyle(
                    color: TextColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${amount.toInt()}g',
                  style: TextStyle(
                    color: TextColor.withOpacity(0.7),
                    fontSize: 8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityPersonalizationCard(Map<String, dynamic> activityData, Map<String, dynamic>? petData) {
    String personalizationNote = activityData['personalization_note'] ?? '';
    String activityRecommendation = activityData['activity_recommendation'] ?? '';
    String recommendationType = activityData['recommendation_type'] ?? 'maintain';
    String currentActivityLevel = activityData['current_activity_level'] ?? 'Medium';
    int recommendedMinutes = activityData['recommended_daily_minutes'] ?? 30;
    IconData recommendationIcon;
    Color recommendationColor;
    String recommendationTitle;
    switch (recommendationType) {
      case 'increase':
        recommendationIcon = Icons.trending_up;
        recommendationColor = Colors.orange.shade600;
        recommendationTitle = 'Increase Activity';
        break;
      case 'decrease':
        recommendationIcon = Icons.trending_down;
        recommendationColor = Colors.blue.shade600;
        recommendationTitle = 'Reduce Activity';
        break;
      default:
        recommendationIcon = Icons.check_circle;
        recommendationColor = Colors.green.shade600;
        recommendationTitle = 'Maintain Activity';
        break;
    }
    String petName = petData != null ? (petData['Name'] ?? petData['petName'] ?? 'your dog') : 'your dog';
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            recommendationColor.withOpacity(0.1),
            recommendationColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: recommendationColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: recommendationColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    recommendationIcon,
                    color: recommendationColor,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recommendationTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: recommendationColor,
                        ),
                      ),
                      Text(
                        'Based on $petName\'s profile',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (personalizationNote.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        personalizationNote,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
            ],
            if (activityRecommendation.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: recommendationColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.directions_run,
                          color: recommendationColor,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Activity Recommendation',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: recommendationColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      activityRecommendation,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActivityStat(
                            'Current Level',
                            currentActivityLevel,
                            Icons.speed,
                            Colors.blue.shade600,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildActivityStat(
                            'Recommended',
                            '$recommendedMinutes min/day',
                            Icons.timer,
                            recommendationColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActivityStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableDetailsSection(Map<String, dynamic> mealPlan) {
    return ExpansionTile(
      title: Text(
        'Nutritional Details & Supplements',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.orange.shade700,
        ),
      ),
      subtitle: Text(
        'Tap to view vitamins, minerals, snacks & nutrition info',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      leading: Icon(Icons.expand_more, color: Colors.orange.shade600),
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Supplements Section
              if (mealPlan['supplements'] != null && mealPlan['supplements'] is List)
                _buildSupplementsSection(mealPlan),
              SizedBox(height: 16),
              // Snacks & Treats Section
              if (mealPlan['snacks'] != null && mealPlan['snacks'] is List)
                _buildSnacksSection(mealPlan),
              SizedBox(height: 16),
              // Nutritional Benefits
              if (mealPlan['nutritional_benefits'] != null)
                _buildNutritionalBenefits(mealPlan),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSupplementsSection(Map<String, dynamic> mealPlan) {
    List<dynamic> supplements = mealPlan['supplements'] ?? [];
    if (supplements.isEmpty) return SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Supplements',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
        SizedBox(height: 8),
        ...supplements.map((supplement) => Row(
          children: [
            Icon(Icons.add, color: Colors.blue.shade400, size: 16),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                supplement['name'] ?? 'Supplement',
                style: TextStyle(fontSize: 13),
              ),
            ),
            if (supplement['amount'] != null)
              Text('${supplement['amount']}'),
          ],
        )),
      ],
    );
  }

  Widget _buildSnacksSection(Map<String, dynamic> mealPlan) {
    List<dynamic> snacks = mealPlan['snacks'] ?? [];
    if (snacks.isEmpty) return SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Snacks & Treats',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.purple.shade700,
          ),
        ),
        SizedBox(height: 8),
        ...snacks.map((snack) => Row(
          children: [
            Icon(Icons.cake, color: Colors.purple.shade400, size: 16),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                snack['name'] ?? 'Snack',
                style: TextStyle(fontSize: 13),
              ),
            ),
            if (snack['amount'] != null)
              Text('${snack['amount']}'),
          ],
        )),
      ],
    );
  }

  Widget _buildNutritionalBenefits(Map<String, dynamic> mealPlan) {
    final benefits = mealPlan['nutritional_benefits'];
    if (benefits == null) return SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nutritional Benefits',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        SizedBox(height: 8),
        if (benefits is List)
          ...benefits.map((b) => Row(
            children: [
              Icon(Icons.check, color: Colors.green.shade400, size: 16),
              SizedBox(width: 6),
              Expanded(child: Text(b.toString(), style: TextStyle(fontSize: 13))),
            ],
          )),
        if (benefits is String)
          Text(benefits, style: TextStyle(fontSize: 13)),
      ],
    );
  }

  /// Extract clean meal name without pet name prefix
  String _getCleanMealName(String originalName, Map<String, dynamic>? petData) {
    String cleanName = originalName;
    
    // Get pet name from pet data
    String? petName = petData != null ? (petData['Name'] ?? petData['petName']) : null;
    
    // Remove pet name prefix if present
    if (petName != null && petName.isNotEmpty && cleanName.contains(petName)) {
      cleanName = cleanName.replaceFirst("$petName's ", '').replaceFirst("${petName}'s ", '');
    }
    
    // Additional cleaning for common patterns
    cleanName = cleanName.replaceFirst(RegExp(r".*'s "), ''); // Remove any possessive
    
    return cleanName;
  }
}
