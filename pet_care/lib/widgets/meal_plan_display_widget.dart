import 'package:flutter/material.dart';
import 'package:pet_care/ColorsScheme.dart';
import 'package:pet_care/models/meal_plan_model.dart';
import '../utils/app_icons.dart';

class MealPlanDisplayWidget extends StatefulWidget {
  final MealPlanModel mealPlan;
  final List<Map<String, dynamic>> availableIngredients;

  const MealPlanDisplayWidget({
    Key? key,
    required this.mealPlan,
    required this.availableIngredients,
  }) : super(key: key);

  @override
  State<MealPlanDisplayWidget> createState() => _MealPlanDisplayWidgetState();
}

class _MealPlanDisplayWidgetState extends State<MealPlanDisplayWidget> {
  bool _isNutritionalStrategyExpanded = false;
  String _selectedMealPlan = '';
  bool _showMealDetails = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: headingBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
            children: [
              AppIcons.petIcon(color: TextColor, size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI Meal Plan for ${widget.mealPlan.petName}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: TextColor,
                  ),
                ),
              ),
              Icon(Icons.auto_fix_high, color: Colors.green.shade400),
            ],
          ),
        ),

        // Available Ingredients Grid
        // _buildIngredientsGrid(),

        // AI Generated Meal Plan Options
        _buildAIMealPlanOptions(),

        // Show detailed view only if a meal plan is selected
        if (_selectedMealPlan.isNotEmpty) ...[
          // Nutritional Strategy (Expandable)
          _buildNutritionalStrategy(),

          // Supplements Section
          _buildSupplementsSection(),

          // Daily Meals Detail
          _buildMealsSection(),

          // Health Guidelines
          // _buildHealthGuidelines(),

          // Feeding Schedule Timeline
          // _buildFeedingSchedule(),
        ],
      ],
    );
  }

  // Widget _buildIngredientsGrid() {
  //   return Container(
  //     margin: EdgeInsets.all(16),
  //     padding: EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         colors: [Colors.green.shade50, Colors.blue.shade50],
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //       ),
  //       borderRadius: BorderRadius.circular(12),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black12,
  //           blurRadius: 8,
  //           offset: Offset(0, 4),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Icon(Icons.inventory, color: Colors.green.shade600, size: 20),
  //             SizedBox(width: 8),
  //             Text(
  //               'Available Ingredients',
  //               style: TextStyle(
  //                 fontSize: 16,
  //                 fontWeight: FontWeight.bold,
  //                 color: Colors.green.shade700,
  //               ),
  //             ),
  //             Spacer(),
  //             Container(
  //               padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //               decoration: BoxDecoration(
  //                 color: Colors.green.shade100,
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //               child: Text(
  //                 '${widget.availableIngredients.length} items',
  //                 style: TextStyle(
  //                   fontSize: 12,
  //                   fontWeight: FontWeight.bold,
  //                   color: Colors.green.shade700,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         SizedBox(height: 12),
  //         SizedBox(
  //           height: 120,
  //           child: GridView.builder(
  //             scrollDirection: Axis.horizontal,
  //             gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
  //               crossAxisCount: 2,
  //               childAspectRatio: 1.0, // Increased from 0.8 to give more height
  //               crossAxisSpacing: 8,
  //               mainAxisSpacing: 8,
  //             ),
  //             itemCount: widget.availableIngredients.length,
  //             itemBuilder: (context, index) {
  //               final ingredient = widget.availableIngredients[index];
  //               return _buildIngredientCard(ingredient);
  //             },
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildIngredientCard(Map<String, dynamic> ingredient) {
    return Container(
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _getIngredientColor(ingredient['category']),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getIngredientIcon(ingredient['category']),
              color: Colors.white,
              size: 12,
            ),
          ),
          SizedBox(height: 2),
          Flexible(
            child: Text(
              ingredient['name'] ?? 'Unknown',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${ingredient['stock'] ?? 0}',
            style: TextStyle(
              fontSize: 7,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getIngredientColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'protein':
      case 'meat':
        return Colors.red.shade400;
      case 'vegetables':
      case 'vegetable':
        return Colors.green.shade400;
      case 'fruits':
      case 'fruit':
        return Colors.orange.shade400;
      case 'grains':
      case 'grain':
        return Colors.brown.shade400;
      case 'dairy':
        return Colors.blue.shade400;
      case 'supplements':
      case 'supplement':
        return Colors.purple.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  IconData _getIngredientIcon(String? category) {
    return AppIcons.getIngredientIcon(category);
  }

  Widget _buildAIMealPlanOptions() {
    List<Map<String, dynamic>> mealPlanOptions = _generateMealPlanOptions();
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: Colors.purple.shade600,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Generated Meal Plans',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                      Text(
                        'Choose from personalized options below',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Meal Plan Option Cards
          ...mealPlanOptions.map((option) => _buildMealPlanOptionCard(option)).toList(),
        ],
      ),
    );
  }

  Widget _buildMealPlanOptionCard(Map<String, dynamic> option) {
    bool isSelected = _selectedMealPlan == option['id'];
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.purple.shade300 : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected ? Colors.purple.withOpacity(0.1) : Colors.black12,
            blurRadius: isSelected ? 12 : 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main Content
          InkWell(
            onTap: () {
              setState(() {
                _selectedMealPlan = isSelected ? '' : option['id'];
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with meal name and price
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: option['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          option['icon'],
                          color: option['color'],
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option['name'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              option['description'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${option['price'].toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: option['color'],
                            ),
                          ),
                          Text(
                            'per week',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Available ingredients
                  Text(
                    'Available Ingredients:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: option['availableIngredients'].map<Widget>((ingredient) => 
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          ingredient,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ).toList(),
                  ),
                  
                  SizedBox(height: 12),
                  
                  // Selection indicator
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? option['color'] : Colors.grey.shade400,
                            width: 2,
                          ),
                          color: isSelected ? option['color'] : Colors.transparent,
                        ),
                        child: isSelected
                          ? Icon(Icons.check, color: Colors.white, size: 14)
                          : null,
                      ),
                      SizedBox(width: 8),
                      Text(
                        isSelected ? 'Selected' : 'Tap to select',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? option['color'] : Colors.grey.shade600,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      Spacer(),
                      if (isSelected)
                        Text(
                          '${option['calories']} cal/day',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // More Details button (only shown when selected)
          if (isSelected)
            Container(
              decoration: BoxDecoration(
                color: option['color'].withOpacity(0.05),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: InkWell(
                onTap: () {
                  // This will show the detailed view below
                  setState(() {
                    _showMealDetails = true;
                  });
                },
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.visibility,
                        color: option['color'],
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'View More Details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: option['color'],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _generateMealPlanOptions() {
    // Generate 3 different meal plan options based on the AI response
    // This would ideally come from multiple Gemini API calls or a single call asking for multiple options
    
    return [
      {
        'id': 'balanced_plan',
        'name': 'Balanced Nutrition Plan',
        'description': 'Well-rounded meals for overall health',
        'icon': Icons.balance,
        'color': Colors.blue.shade600,
        'price': 24.99,
        'calories': 1200,
        'availableIngredients': _getAvailableIngredientsForPlan(['chicken', 'rice', 'carrots', 'peas']),
      },
      {
        'id': 'high_protein_plan',
        'name': 'High Protein Plan',
        'description': 'Protein-rich meals for active pets',
        'icon': Icons.fitness_center,
        'color': Colors.red.shade600,
        'price': 29.99,
        'calories': 1350,
        'availableIngredients': _getAvailableIngredientsForPlan(['beef', 'salmon', 'turkey', 'quinoa']),
      },
      {
        'id': 'sensitive_stomach_plan',
        'name': 'Gentle Digest Plan',
        'description': 'Easy-to-digest meals for sensitive tummies',
        'icon': Icons.healing,
        'color': Colors.green.shade600,
        'price': 27.99,
        'calories': 1100,
        'availableIngredients': _getAvailableIngredientsForPlan(['white_rice', 'chicken', 'pumpkin', 'sweet_potato']),
      },
    ];
  }

  List<String> _getAvailableIngredientsForPlan(List<String> planIngredients) {
    // Filter available ingredients based on what's actually in inventory
    List<String> available = [];
    for (String ingredient in planIngredients) {
      // Check if ingredient exists in available ingredients
      bool found = widget.availableIngredients.any((item) => 
        item['name']?.toLowerCase().contains(ingredient.toLowerCase()) == true
      );
      if (found) {
        available.add(ingredient.replaceAll('_', ' ').toUpperCase());
      }
    }
    return available.isEmpty ? ['Custom ingredients available'] : available;
  }

  Widget _buildNutritionalStrategy() {
    if (widget.mealPlan.nutritionalStrategy.isEmpty) return SizedBox.shrink();
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isNutritionalStrategyExpanded = !_isNutritionalStrategyExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.bar_chart, 
                      color: Colors.blue.shade600, 
                      size: 20
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nutritional Strategy',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        Text(
                          'Tap to view detailed strategy',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _isNutritionalStrategyExpanded 
                        ? Icons.expand_less 
                        : Icons.expand_more,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isNutritionalStrategyExpanded)
            Container(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Text(
                      widget.mealPlan.nutritionalStrategy,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade800,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSupplementsSection() {
    // Extract or generate supplement recommendations
    List<Map<String, dynamic>> supplements = _extractSupplements();
    
    if (supplements.isEmpty) return SizedBox.shrink();
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.medical_services, 
                    color: Colors.purple.shade600, 
                    size: 20
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recommended Supplements',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                      Text(
                        'Based on nutritional analysis',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${supplements.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: supplements.map((supplement) => _buildSupplementTile(supplement)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplementTile(Map<String, dynamic> supplement) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.purple.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.local_pharmacy,
              color: Colors.purple.shade600,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supplement['name'] ?? 'Supplement',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade800,
                  ),
                ),
                Text(
                  supplement['dosage'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.purple.shade600,
                  ),
                ),
                if (supplement['benefit']?.isNotEmpty ?? false)
                  Text(
                    supplement['benefit'],
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.purple.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: supplement['recommended'] == true 
                ? Colors.green.shade100 
                : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              supplement['recommended'] == true 
                ? Icons.check_circle 
                : Icons.info,
              color: supplement['recommended'] == true 
                ? Colors.green.shade600 
                : Colors.orange.shade600,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _extractSupplements() {
    // For now, generate basic supplements based on common pet needs
    // In a real app, this could be extracted from the AI response or database
    return [
      {
        'name': 'Omega-3 Fish Oil',
        'dosage': '1 capsule daily',
        'benefit': 'Supports coat health and joint function',
        'recommended': true,
      },
      {
        'name': 'Probiotics',
        'dosage': '1/2 tsp with meals',
        'benefit': 'Promotes digestive health',
        'recommended': true,
      },
      {
        'name': 'Multivitamin',
        'dosage': 'As directed by vet',
        'benefit': 'Ensures complete nutrition',
        'recommended': false,
      },
    ];
  }

  Widget _buildMealsSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.restaurant_menu, color: Colors.green.shade600, size: 20),
                SizedBox(width: 8),
                Text(
                  'Daily Meal Plan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
          ...widget.mealPlan.meals.map((meal) => MealCard(meal: meal)).toList(),
        ],
      ),
    );
  }

  Widget _buildHealthGuidelines() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.health_and_safety, color: Colors.orange.shade600, size: 20),
              SizedBox(width: 8),
              Text(
                'Health Guidelines',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          HealthGuidelinesCard(guidelines: widget.mealPlan.healthGuidelines),
        ],
      ),
    );
  }

  Widget _buildFeedingSchedule() {
    List<Map<String, dynamic>> scheduleItems = _generateScheduleItems();
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.schedule, 
                    color: Colors.teal.shade600, 
                    size: 20
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Feeding Schedule',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade700,
                        ),
                      ),
                      Text(
                        'Optimal timing for your pet',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.teal.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: scheduleItems.map((item) => _buildScheduleTimelineItem(item)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTimelineItem(Map<String, dynamic> item) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Timeline dot and line
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: item['color'] ?? Colors.teal.shade400,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              if (item != _generateScheduleItems().last)
                Container(
                  width: 2,
                  height: 30,
                  color: Colors.teal.shade200,
                ),
            ],
          ),
          SizedBox(width: 16),
          // Schedule content
          Expanded(
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (item['color'] as Color?)?.withOpacity(0.1) ?? Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (item['color'] as Color?)?.withOpacity(0.3) ?? Colors.teal.shade200
                ),
              ),
              child: Row(
                children: [
                  Text(
                    item['emoji'] ?? '🍽️',
                    style: TextStyle(fontSize: 20),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['time'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: item['color'] ?? Colors.teal.shade700,
                          ),
                        ),
                        Text(
                          item['activity'] ?? '',
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
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _generateScheduleItems() {
    return [
      {
        'time': '7:00 AM',
        'activity': 'Breakfast Time',
        'emoji': '🌅',
        'color': Colors.orange.shade400,
      },
      {
        'time': '12:00 PM',
        'activity': 'Lunch Time',
        'emoji': '☀️',
        'color': Colors.blue.shade400,
      },
      {
        'time': '3:00 PM',
        'activity': 'Playtime & Water',
        'emoji': '🎾',
        'color': Colors.green.shade400,
      },
      {
        'time': '6:00 PM',
        'activity': 'Dinner Time',
        'emoji': '🌙',
        'color': Colors.purple.shade400,
      },
      {
        'time': '8:00 PM',
        'activity': 'Evening Walk',
        'emoji': '🚶',
        'color': Colors.teal.shade400,
      },
    ];
  }
}

class MealCard extends StatefulWidget {
  final MealModel meal;

  const MealCard({Key? key, required this.meal}) : super(key: key);

  @override
  State<MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<MealCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getMealColor(),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        widget.meal.emoji,
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.meal.typeDisplayName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          widget.meal.name.isNotEmpty ? widget.meal.name : 'Healthy ${widget.meal.typeDisplayName}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (widget.meal.time.isNotEmpty)
                          Text(
                            'Time: ${widget.meal.time}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Container(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: Colors.grey.shade300),
                  SizedBox(height: 8),
                  
                  // Ingredients
                  if (widget.meal.ingredients.isNotEmpty) ...[
                    _buildSectionHeader('Ingredients', Icons.list_alt),
                    SizedBox(height: 4),
                    ...widget.meal.ingredients.map((ingredient) => 
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• ', style: TextStyle(color: Colors.green.shade600, fontWeight: FontWeight.bold)),
                            Expanded(child: Text(ingredient, style: TextStyle(fontSize: 14))),
                          ],
                        ),
                      ),
                    ).toList(),
                    SizedBox(height: 12),
                  ],
                  
                  // Preparation
                  if (widget.meal.preparation.isNotEmpty) ...[
                    _buildSectionHeader('Preparation', Icons.kitchen),
                    SizedBox(height: 4),
                    ...widget.meal.preparation.asMap().entries.map((entry) => 
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(child: Text(entry.value, style: TextStyle(fontSize: 14))),
                          ],
                        ),
                      ),
                    ).toList(),
                    SizedBox(height: 12),
                  ],
                  
                  // Health Benefits
                  if (widget.meal.healthBenefits.isNotEmpty) ...[
                    _buildSectionHeader('Health Benefits', Icons.favorite),
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.meal.healthBenefits,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade800,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Color _getMealColor() {
    switch (widget.meal.type) {
      case MealType.breakfast:
        return Colors.orange.shade100;
      case MealType.lunch:
        return Colors.blue.shade100;
      case MealType.dinner:
        return Colors.purple.shade100;
    }
  }
}

class HealthGuidelinesCard extends StatelessWidget {
  final HealthGuidelinesModel guidelines;

  const HealthGuidelinesCard({Key? key, required this.guidelines}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<GuidelineItem> items = [
      GuidelineItem('Total Daily Calories', guidelines.totalDailyCalories, Icons.local_fire_department),
      GuidelineItem('Feeding Schedule', guidelines.feedingSchedule, Icons.schedule),
      GuidelineItem('Digestive Health Tips', guidelines.digestiveHealthTips, Icons.healing),
      GuidelineItem('Activity Adjustments', guidelines.activityLevelAdjustments, Icons.directions_run),
      GuidelineItem('Health Goal Progress', guidelines.healthGoalProgress, Icons.trending_up),
      if (guidelines.favoriteFoodIntegration.isNotEmpty)
        GuidelineItem('Favorite Foods', guidelines.favoriteFoodIntegration, Icons.favorite),
      if (guidelines.allergyManagement.isNotEmpty)
        GuidelineItem('Allergy Management', guidelines.allergyManagement, Icons.warning),
      GuidelineItem('Weekly Monitoring', guidelines.weeklyMonitoring, Icons.monitor_heart),
    ];

    return Column(
      children: items
          .where((item) => item.value.isNotEmpty)
          .map((item) => _buildGuidelineItem(item))
          .toList(),
    );
  }

  Widget _buildGuidelineItem(GuidelineItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, size: 18, color: Colors.orange.shade600),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  item.value,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange.shade800,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GuidelineItem {
  final String title;
  final String value;
  final IconData icon;

  GuidelineItem(this.title, this.value, this.icon);
}
