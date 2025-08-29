import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:pet_care/ColorsScheme.dart';
import 'package:pet_care/services/ingredient_service.dart';
import 'package:pet_care/services/gemini_meal_service.dart';
import 'package:pet_care/utils/sample_data_helper.dart';
import 'package:pet_care/Subscription/SubscriptionPlanScreen.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:pet_care/utils/image_utils.dart';
import 'package:pet_care/widgets/pet_background_pattern.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AIMealPlanScreen extends StatefulWidget {
  final Map<String, dynamic> petData;
  
  const AIMealPlanScreen({Key? key, required this.petData}) : super(key: key);

  @override
  State<AIMealPlanScreen> createState() => _AIMealPlanScreenState();
}

class _AIMealPlanScreenState extends State<AIMealPlanScreen> {
  void _showLoadingSubscriptionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: Lottie.asset(
                  'assets/Animations/AnimalcareLoading.json',
                  repeat: true,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(width: 5),
              Text('Loading Subscription...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
  bool _isLoading = false;
  Map<String, dynamic>? _currentMealPlan; // Store single JSON meal plan
  List<Map<String, dynamic>> _availableIngredients = [];
  String _errorMessage = '';
  double _totalMealPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchIngredients();
  }

  Future<void> _fetchIngredients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // First, ensure we have sample ingredients if database is empty
      await SampleDataHelper.addSampleIngredientsIfEmpty();
      
      final ingredients = await IngredientService.fetchAvailableIngredients();
      setState(() {
        _availableIngredients = ingredients;
        _isLoading = false;
      });

      if (ingredients.isEmpty) {
        setState(() {
          _errorMessage = 'No ingredients available in inventory. Please check with admin.';
        });
        _showErrorSnackBar('No ingredients found in inventory 📦');
      } else {
        print('Successfully loaded ${ingredients.length} ingredients');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to fetch ingredients: ${e.toString()}';
      });
      _showErrorSnackBar('Failed to load ingredients 😔');
    }
  }

  Future<void> _generateMealPlan() async {
    if (_availableIngredients.isEmpty) {
      _showErrorSnackBar('No ingredients available. Please refresh and try again.');
      return;
    }

    setState(() {
      _isLoading = true;
      _currentMealPlan = null;
      _errorMessage = '';
      _totalMealPrice = 0.0;
    });

    try {
      // Debug: Show what data we're sending
      print('=== OPTIMAL MEAL PLAN GENERATION DEBUG ===');
      print('Pet Data: ${widget.petData}');
      print('Available Ingredients Count: ${_availableIngredients.length}');
      print('Pet Weight: ${widget.petData['weight']} ${widget.petData['weightUnit']}');
      print('Pet Activity: ${widget.petData['activityLevel']}');
      print('Pet Allergies: ${widget.petData['allergies']}');
      print('Pet Health Goals: ${widget.petData['healthGoals']}');
      print('Pet Favorites: ${widget.petData['favorites']}');
      print('==========================================');

      // Generate single optimal meal
      final mealPlan = await GeminiMealService.generateOptimalPersonalizedMealWithData(
        petData: widget.petData,
      );
      
      setState(() {
        _isLoading = false;
        
        if (mealPlan != null && mealPlan['error'] == null) {
          _currentMealPlan = mealPlan;
          _totalMealPrice = mealPlan['total_price']?.toDouble() ?? 0.0;
          _errorMessage = '';
        } else {
          _currentMealPlan = null;
          _errorMessage = mealPlan?['error'] ?? 'Failed to generate meal plan. Please try again.';
        }
      });

      if (_currentMealPlan != null) {
        _showSuccessSnackBar('Generated personalized meal plan! 🎉');
      } else {
        _showErrorSnackBar(_errorMessage.isNotEmpty ? _errorMessage : 'Failed to generate meal plan. Please try again.');
      }
    } catch (e) {
      print('Error generating optimal meal plan: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to generate meal plan: ${e.toString()}';
        _currentMealPlan = null;
      });
      _showErrorSnackBar('Failed to generate meal plan 😔');
    }
  }

  void _showErrorSnackBar(String message) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: 'Oops! 😅',
        message: message,
        contentType: ContentType.failure,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showSuccessSnackBar(String message) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: 'Success! 🎉',
        message: message,
        contentType: ContentType.success,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showPetDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.petData['Name']} Details'),
        content: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Species', widget.petData['Category'] ?? 'Unknown'),
                _buildDetailRow('Breed', widget.petData['Breed'] ?? 'Mixed'),
                _buildDetailRow('Weight', '${widget.petData['weight'] ?? 'Not set'} ${widget.petData['weightUnit'] ?? ''}'),
                _buildDetailRow('Activity Level', widget.petData['activityLevel'] ?? 'Not set'),
                _buildDetailRow('Date of Birth', widget.petData['DateOfBirth'] ?? 'Not set'),
                if (widget.petData['allergies'] != null && (widget.petData['allergies'] as List).isNotEmpty)
                  _buildDetailRow('Allergies', (widget.petData['allergies'] as List).join(', ')),
                if (widget.petData['healthGoals'] != null && (widget.petData['healthGoals'] as List).isNotEmpty)
                  _buildDetailRow('Health Goals', (widget.petData['healthGoals'] as List).join(', ')),
                if (widget.petData['favorites'] != null && (widget.petData['favorites'] as List).isNotEmpty)
                  _buildDetailRow('Favorites', (widget.petData['favorites'] as List).join(', ')),
                if (widget.petData['healthNotes'] != null && widget.petData['healthNotes'].toString().isNotEmpty)
                  _buildDetailRow('Health Notes', widget.petData['healthNotes']),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildPetInfoCard() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: headingBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ImageUtils.buildPetAvatar(
                imagePath: widget.petData["Photo"],
                radius: 25,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.petData['Name'] ?? 'Unknown Pet',
                      style: TextStyle(
                        color: TextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${widget.petData['Category'] ?? 'Unknown'} • ${widget.petData['Breed'] ?? 'Mixed'}',
                      style: TextStyle(
                        color: TextColor.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Quick access to pet details
              IconButton(
                onPressed: _showPetDataDialog,
                icon: Icon(Icons.info_outline, color: TextColor.withOpacity(0.7)),
                tooltip: 'View pet details',
              ),
            ],
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip('Weight', '${widget.petData['weight'] ?? 'Unknown'} ${widget.petData['weightUnit'] ?? ''}'),
              _buildInfoChip('Activity', widget.petData['activityLevel'] ?? 'Unknown'),
              if (widget.petData['allergies'] != null && 
                  (widget.petData['allergies'] as List).isNotEmpty)
                _buildInfoChip('Allergies', (widget.petData['allergies'] as List).join(', '), color: Colors.red.shade200),
              if (widget.petData['healthGoals'] != null && 
                  (widget.petData['healthGoals'] as List).isNotEmpty)
                _buildInfoChip('Goals', (widget.petData['healthGoals'] as List).join(', '), color: Colors.green.shade200),
              if (widget.petData['favorites'] != null && 
                  (widget.petData['favorites'] as List).isNotEmpty)
                _buildInfoChip('Favorites', (widget.petData['favorites'] as List).join(', '), color: Colors.blue.shade200),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, {Color? color}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: TextColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  // Widget _buildIngredientsStatus() {
  //   return Container(
  //     margin: EdgeInsets.symmetric(horizontal: 16),
  //     padding: EdgeInsets.all(12),
  //     decoration: BoxDecoration(
  //       color: appBarColor,
  //       borderRadius: BorderRadius.circular(8),
  //     ),
  //     child: Column(
  //       children: [
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Row(
  //               children: [
  //                 Icon(Icons.inventory_2, color: TextColor, size: 20),
  //                 SizedBox(width: 8),
  //                 Text(
  //                   'Available Ingredients: ${_availableIngredients.length}',
  //                   style: TextStyle(
  //                     color: TextColor,
  //                     fontSize: 14,
  //                     fontWeight: FontWeight.w500,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             Row(
  //               children: [
  //                 IconButton(
  //                   onPressed: _fetchIngredients,
  //                   icon: Icon(Icons.refresh, color: TextColor),
  //                   iconSize: 20,
  //                   tooltip: 'Refresh ingredients',
  //                 ),
  //                 // Debug button for development
  //                 IconButton(
  //                   onPressed: () async {
  //                     setState(() => _isLoading = true);
  //                     try {
  //                       await SampleDataHelper.refreshSampleIngredients();
  //                       await _fetchIngredients();
  //                       _showSuccessSnackBar('Sample ingredients refreshed! 🔄');
  //                     } catch (e) {
  //                       _showErrorSnackBar('Failed to refresh ingredients');
  //                     }
  //                     setState(() => _isLoading = false);
  //                   },
  //                   icon: Icon(Icons.science, color: TextColor),
  //                   iconSize: 20,
  //                   tooltip: 'Refresh sample data (dev)',
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //         if (_availableIngredients.isNotEmpty) ...[
  //           SizedBox(height: 8),
  //           Container(
  //             height: 80,
  //             child: ListView.builder(
  //               scrollDirection: Axis.horizontal,
  //               itemCount: _availableIngredients.take(10).length,
  //               itemBuilder: (context, index) {
  //                 final ingredient = _availableIngredients[index];
  //                 return Container(
  //                   width: 120,
  //                   margin: EdgeInsets.only(right: 8),
  //                   padding: EdgeInsets.all(8),
  //                   decoration: BoxDecoration(
  //                     color: Colors.white.withOpacity(0.1),
  //                     borderRadius: BorderRadius.circular(8),
  //                   ),
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Text(
  //                         ingredient['name'] ?? 'Unknown',
  //                         style: TextStyle(
  //                           color: TextColor,
  //                           fontSize: 12,
  //                           fontWeight: FontWeight.bold,
  //                         ),
  //                         maxLines: 1,
  //                         overflow: TextOverflow.ellipsis,
  //                       ),
  //                       Text(
  //                         ingredient['category'] ?? '',
  //                         style: TextStyle(
  //                           color: TextColor.withOpacity(0.7),
  //                           fontSize: 10,
  //                         ),
  //                       ),
  //                       Text(
  //                         '${ingredient['stockQuantity']?.toString() ?? '0'} ${ingredient['unit'] ?? ''}',
  //                         style: TextStyle(
  //                           color: TextColor.withOpacity(0.8),
  //                           fontSize: 10,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 );
  //               },
  //             ),
  //           ),
  //         ],
  //       ],
  //     ),
  //   );
  // }

  Widget _buildGenerateButton() {
    bool hasRequiredData = _availableIngredients.isNotEmpty && 
                          (widget.petData['weight'] != null && widget.petData['weight'].toString() != '0');
    
    // If meal plan exists, show edit button instead
    if (_currentMealPlan != null && _errorMessage.isEmpty) {
      return Container(
        margin: EdgeInsets.all(16),
        child: Row(
          children: [
            // Edit Meal Plan Button
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: !_isLoading ? _showEditMealDialog : null,
                icon: Icon(Icons.edit, color: Colors.white),
                label: Text(
                  'Edit Meal Plan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
              ),
            ),
            SizedBox(width: 12),
            // Generate New Meal Button
            Expanded(
              flex: 1,
              child: ElevatedButton.icon(
                onPressed: !_isLoading ? _generateMealPlan : null,
                icon: Icon(Icons.refresh, color: Colors.white),
                label: Text(
                  'New',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Original generate button for when no meal plan exists
    return Column(
      children: [
        if (!hasRequiredData) ...[
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade600),
                    SizedBox(width: 8),
                    Text(
                      'Tips for Better Meal Plans',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '• Add your pet\'s weight for accurate portions\n'
                  '• Include allergies to avoid harmful ingredients\n'
                  '• Set health goals for targeted nutrition\n'
                  '• Mark favorite foods for better acceptance',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 12,
                  ),
                ),
                if (_availableIngredients.isEmpty)
                  Text(
                    '\n• No ingredients available - contact admin or refresh',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 16),
        ],
        Container(
          margin: EdgeInsets.all(16),
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _availableIngredients.isNotEmpty && !_isLoading 
                ? _generateMealPlan 
                : null,
            icon: Icon(Icons.auto_fix_high, color: Colors.white),
            label: Text(
              hasRequiredData ? 'Generate AI Meal Plan' : 'Generate Basic Meal Plan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _availableIngredients.isNotEmpty 
                  ? (hasRequiredData ? Colors.green.shade600 : Colors.blue.shade600)
                  : Colors.grey,
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealPlanCard() {
    if (_currentMealPlan == null && _errorMessage.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.all(16),
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
          if (_errorMessage.isNotEmpty)
            Container(
              padding: EdgeInsets.all(16),
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_currentMealPlan != null)
            // Display our new JSON meal plan
            _buildJSONMealPlanDisplay(_currentMealPlan!),
          
          // Subscription button when meal plan is generated
          if (_currentMealPlan != null && _errorMessage.isEmpty)
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () async {
                  _showLoadingSubscriptionDialog();
                  await _sendMealPlanToAdmin(_currentMealPlan!);
                  Map<String, dynamic> enhancedPetData = {
                    ...widget.petData,
                    'actualMealPrice': _totalMealPrice,
                    'mealPlanDetails': _currentMealPlan,
                  };
                  Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading dialog
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubscriptionPlanScreen(petData: enhancedPetData),
                    ),
                  );
                },
                icon: Icon(Icons.restaurant, color: Colors.white),
                label: Text(
                  'Start Meal Subscription',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build the new JSON meal plan display widget
  Widget _buildJSONMealPlanDisplay(Map<String, dynamic> mealPlan) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Meal Card (always visible)
          _buildMainMealCard(mealPlan),
          SizedBox(height: 16),
          
          // Expandable Details Section
          _buildExpandableDetailsSection(mealPlan),
        ],
      ),
    );
  }

  Widget _buildMainMealCard(Map<String, dynamic> mealPlan) {
    String mealName = _getActualMealName(mealPlan);
    List<dynamic> ingredients = mealPlan['ingredients'] ?? [];
  String recommendationReason = mealPlan['recommendation_reason'] ?? '';
    
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
            // Meal Header
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
                        'For ${widget.petData['Name'] ?? 'your pet'}',
                        style: TextStyle(
                          color: TextColor.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Price chip
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '฿${_totalMealPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: TextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            // AI Recommendation Reason (if available)
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
            
            // Ingredients Grid
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
        childAspectRatio: 0.85, // Changed from 1.0 to 0.85 to give more height
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: ingredients.length,
      itemBuilder: (context, index) {
        final ingredient = ingredients[index];
        return _buildIngredientGridItem(ingredient);
      },
    );
  }

  Widget _buildIngredientGridItem(dynamic ingredient) {
    String name = ingredient['name'] ?? 'Unknown';
    double amount = (ingredient['amount_grams'] ?? 0).toDouble();
    
    // Find ingredient details from inventory
    Map<String, dynamic>? inventoryItem = _availableIngredients.firstWhere(
      (item) => item['name']?.toString().toLowerCase() == name.toLowerCase(),
      orElse: () => {},
    );
    
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
            // Ingredient image/icon
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _getIngredientColor(inventoryItem['category']),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                _getIngredientIcon(inventoryItem['category']),
                color: Colors.white,
                size: 16,
              ),
            ),
            SizedBox(height: 2),
            // Ingredient name
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
            // Amount with proper formatting
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
        'Tap to view supplements, snacks, activity & care instructions',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      leading: Icon(Icons.expand_more, color: Colors.orange.shade600),
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Supplements Section
              _buildSupplementsSection(mealPlan),
              SizedBox(height: 16),
              
              // Snacks & Treats Section  
              _buildAISuggestedSnacksSection(mealPlan),
              SizedBox(height: 16),

              // Activity Recommendations Section
              _buildActivityRecommendationSection(mealPlan),
              SizedBox(height: 16),

               // Medical Care Instructions Section (ADD THIS)
            _buildMedicalCareSection(mealPlan),
            SizedBox(height: 16),


              
              // Nutritional Benefits
              _buildNutritionalBenefits(mealPlan),
            ],
          ),
        ),
      ],
    );
  }

  String _getActualMealName(Map<String, dynamic> mealPlan) {
    String originalName = mealPlan['meal_name'] ?? 'Custom Meal';
    
    // If the original name contains pet's name, extract just the meal type
    // E.g., "Jingra's Muscle Building Feast" -> "Muscle Building Feast"
    String petName = widget.petData['Name'] ?? '';
    if (petName.isNotEmpty && originalName.contains(petName)) {
      originalName = originalName.replaceFirst("$petName's ", '').replaceFirst("${petName}'s ", '');
    }
    
    // Create descriptive names based on main ingredients
    List<dynamic> ingredients = mealPlan['ingredients'] ?? [];
    if (ingredients.isNotEmpty) {
      // Find main protein and carb
      String? mainProtein = ingredients.firstWhere(
        (ing) => _getIngredientCategory(ing['name']) == 'Protein',
        orElse: () => null,
      )?['name'];
      
      String? mainCarb = ingredients.firstWhere(
        (ing) => _getIngredientCategory(ing['name']) == 'Carbohydrate',
        orElse: () => null,
      )?['name'];
      
      if (mainProtein != null && mainCarb != null) {
        return '$mainProtein & $mainCarb Bowl';
      } else if (mainProtein != null) {
        return '$mainProtein Feast';
      }
    }
    
    // Fallback to cleaned original name
    return originalName;
  }

  String _getIngredientCategory(String? ingredientName) {
    if (ingredientName == null) return 'Unknown';
    
    Map<String, dynamic>? inventoryItem = _availableIngredients.firstWhere(
      (item) => item['name']?.toString().toLowerCase() == ingredientName.toLowerCase(),
      orElse: () => {},
    );
    
    return inventoryItem['category'] ?? 'Unknown';
  }

  /// Send meal plan with preparation instructions to admin
  Future<void> _sendMealPlanToAdmin(Map<String, dynamic> mealPlan) async {
    try {
      // Add preparation instructions and pet details to meal plan
      Map<String, dynamic> adminMealData = {
        ...mealPlan,
        'pet_info': {
          'name': widget.petData['Name'],
          'breed': widget.petData['Breed'],
          'weight': '${widget.petData['weight']} ${widget.petData['weightUnit']}',
          'activity_level': widget.petData['activityLevel'],
          'allergies': widget.petData['allergies'],
          'health_goals': widget.petData['healthGoals'],
        },
        'order_timestamp': DateTime.now().toIso8601String(),
        'customer_email': 'user@example.com', // You can get this from auth
        'order_status': 'pending_preparation',
      };

      // Store in Firestore admin orders collection
      await FirebaseFirestore.instance
          .collection('admin_meal_orders')
          .add(adminMealData);
      
      print('Meal plan sent to admin successfully');
    } catch (e) {
      print('Error sending meal plan to admin: $e');
      // Don't block the subscription flow for this error
    }
  }

  /// Show edit meal dialog with options for user
  void _showEditMealDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditMealDialog(
          currentMealPlan: _currentMealPlan!,
          petData: widget.petData,
          onMealEdited: (editedMealPlan) {
            setState(() {
              _currentMealPlan = editedMealPlan;
              _totalMealPrice = editedMealPlan['total_price']?.toDouble() ?? 0.0;
            });
            _showSuccessSnackBar('Meal plan updated successfully! 🎉');
          },
        );
      },
    );
  }





  Widget _buildAISuggestedSnacksSection(Map<String, dynamic> mealPlan) {
    List<dynamic> aiSnacks = mealPlan['ai_suggested_snacks'] ?? [];
    
    if (aiSnacks.isEmpty) return SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.pets, color: Colors.amber.shade600, size: 20),
            SizedBox(width: 8),
            Text(
              'Snacks and Treats',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade700,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: aiSnacks.map<Widget>((snack) {
              return Container(
                constraints: BoxConstraints(maxWidth: 200), // Prevent excessive width
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 14, color: Colors.amber.shade700),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        snack.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                          color: Colors.amber.shade800,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityRecommendationSection(Map<String, dynamic> mealPlan) {
    Map<String, dynamic>? activityRec = mealPlan['activity_recommendation'];
    
    if (activityRec == null || activityRec.isEmpty) return SizedBox.shrink();
    
    String recommendation = activityRec['recommendation'] ?? '';
    String reason = activityRec['reason'] ?? '';
    List<dynamic> activities = activityRec['activities'] ?? [];
    
    if (recommendation.isEmpty) return SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.directions_run, color: Colors.green.shade600, size: 20),
            SizedBox(width: 8),
            Text(
              'Activity Recommendation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recommendation,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              if (reason.isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  'Why: $reason',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              if (activities.isNotEmpty) ...[
                SizedBox(height: 12),
                Text(
                  'Suggested Activities:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade800,
                  ),
                ),
                SizedBox(height: 6),
                ...activities.map<Widget>((activity) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            activity.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedicalCareSection(Map<String, dynamic> mealPlan) {
    String? medicalInstructions = mealPlan['medical_care_instructions'];
    
    if (medicalInstructions == null || medicalInstructions.isEmpty || medicalInstructions.toLowerCase() == 'null') {
      return SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.medical_services, color: Colors.red.shade600, size: 20),
            SizedBox(width: 8),
            Text(
              'Medical Care Instructions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.health_and_safety, color: Colors.red.shade600, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  medicalInstructions,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSupplementsSection(Map<String, dynamic> mealPlan) {
    List<dynamic> supplements = mealPlan['supplements_vitamins_minerals'] ?? [];
    
    if (supplements.isEmpty) return SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.health_and_safety, color: Colors.purple.shade600),
            SizedBox(width: 8),
            Text(
              'Supplements & Vitamins',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade700,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: supplements.map<Widget>((supplement) {
              // Handle both string and object formats for supplements
              String supplementName = '';
              String supplementAmount = '';
              
              if (supplement is Map<String, dynamic>) {
                supplementName = supplement['name'] ?? supplement.toString();
                // Check if supplement has amount (some might have dosage info)
                if (supplement['amount_grams'] != null) {
                  supplementAmount = ' - ${supplement['amount_grams']}g';
                } else if (supplement['amount'] != null) {
                  supplementAmount = ' - ${supplement['amount']}';
                }
              } else {
                supplementName = supplement.toString();
              }
              
              return Container(
                constraints: BoxConstraints(maxWidth: 200), // Limit max width
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.purple.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.medication, color: Colors.purple.shade600, size: 16),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '$supplementName$supplementAmount',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                          color: Colors.purple.shade700,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }


  Widget _buildNutritionalBenefits(Map<String, dynamic> mealPlan) {
    List<dynamic> ingredients = mealPlan['ingredients'] ?? [];
    
    // Calculate nutritional summary from ingredients
    Map<String, double> nutritionSummary = _calculateNutritionalSummary(ingredients);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics, color: Colors.teal.shade600),
            SizedBox(width: 8),
            Text(
              'Nutritional Composition',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade700,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: nutritionSummary.entries.map<Widget>((entry) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(_getNutritionIcon(entry.key), color: Colors.teal.shade600, size: 16),
                    SizedBox(width: 8),
                    Text(
                      '${entry.key}:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.teal.shade700,
                      ),
                    ),
                    Spacer(),
                    Text(
                      '${entry.value.toStringAsFixed(1)}g',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Map<String, double> _calculateNutritionalSummary(List<dynamic> ingredients) {
    Map<String, double> summary = {
      'Protein': 0.0,
      'Fat': 0.0,
      'Fiber': 0.0,
      'Calcium': 0.0,
    };
    
    for (var ingredient in ingredients) {
      String name = ingredient['name'] ?? '';
      double amount = (ingredient['amount_grams'] ?? 0).toDouble();
      
      // Find ingredient in inventory to get nutrition data
      Map<String, dynamic>? inventoryItem = _availableIngredients.firstWhere(
        (item) => item['name']?.toString().toLowerCase() == name.toLowerCase(),
        orElse: () => {},
      );
      
      if (inventoryItem.isNotEmpty) {
        double portionRatio = amount / 100.0; // Amount in grams / 100g
        
        summary['Protein'] = (summary['Protein'] ?? 0) + ((inventoryItem['protein'] ?? 0) * portionRatio);
        summary['Fat'] = (summary['Fat'] ?? 0) + ((inventoryItem['fat'] ?? 0) * portionRatio);
        summary['Fiber'] = (summary['Fiber'] ?? 0) + ((inventoryItem['fiber'] ?? 0) * portionRatio);
        summary['Calcium'] = (summary['Calcium'] ?? 0) + ((inventoryItem['calcium'] ?? 0) * portionRatio);
      }
    }
    
    return summary;
  }

  Color _getIngredientColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'protein':
        return Colors.red.shade600;
      case 'carbohydrate':
        return Colors.orange.shade600;
      case 'vegetable':
        return Colors.green.shade600;
      case 'supplement':
      case 'vitamin':
      case 'mineral':
        return Colors.purple.shade600;
      case 'treat':
      case 'snack':
        return Colors.amber.shade600;
      default:
        return Colors.blue.shade600;
    }
  }

  IconData _getIngredientIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'protein':
        return Icons.set_meal;
      case 'carbohydrate':
        return Icons.grain;
      case 'vegetable':
        return Icons.eco;
      case 'supplement':
      case 'vitamin':
      case 'mineral':
        return Icons.medication;
      case 'treat':
      case 'snack':
        return Icons.star;
      default:
        return Icons.restaurant;
    }
  }

  IconData _getNutritionIcon(String nutrient) {
    switch (nutrient.toLowerCase()) {
      case 'protein':
        return Icons.fitness_center;
      case 'fat':
        return Icons.water_drop;
      case 'fiber':
        return Icons.grass;
      case 'calcium':
        return Icons.construction;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: headingBackgroundColor.colors.first,
      appBar: AppBar(
        title: Text(
          'AI Meal Planner',
          style: TextStyle(
            color: TextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: appBarColor,
        iconTheme: IconThemeData(color: TextColor),
        elevation: 0,
      ),
      body: ModalProgressHUD(
        inAsyncCall: _isLoading,
        progressIndicator: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 150,
                height: 150,
                child: Lottie.asset(
                  'assets/Animations/FoodLoadingAnimation.json',
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                  repeat: true,
                  animate: true,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'We are preparing your meal plan...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Analyzing ingredients and nutritional needs',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
             child: Stack(
          children: [
            PetBackgroundPattern(
              opacity: 0.8,
              symbolSize: 80.0,
              density: 0.3,
            ),
            Container(
              height: double.maxFinite,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xff2A2438).withOpacity(0.85), // Semi-transparent
                    Color(0xff77669E).withOpacity(0.85), // Semi-transparent
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildPetInfoCard(),
              // _buildIngredientsStatus(),
              _buildGenerateButton(),
              _buildMealPlanCard(),
              SizedBox(height: 20),
            ],
          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for editing meal plans with AI assistance
class EditMealDialog extends StatefulWidget {
  final Map<String, dynamic> currentMealPlan;
  final Map<String, dynamic> petData;
  final Function(Map<String, dynamic>) onMealEdited;

  const EditMealDialog({
    Key? key,
    required this.currentMealPlan,
    required this.petData,
    required this.onMealEdited,
  }) : super(key: key);

  @override
  State<EditMealDialog> createState() => _EditMealDialogState();
}

class _EditMealDialogState extends State<EditMealDialog> {
  final TextEditingController _editRequestController = TextEditingController();
  bool _isLoading = false;
  List<String> _quickEditOptions = [
    "Add more protein ingredients",
    "Reduce the carbohydrate content",
    "Add fish oil supplement for omega-3",
    "Include more vegetables for fiber",
    "Add calcium supplement for bone health",
    "Include training treats",
    "Remove chicken and add beef instead",
    "Increase portion sizes by 20%",
    "Add probiotics for digestive health",
    "Include joint care supplements",
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: headingBackgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit, color: TextColor, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Meal Plan',
                          style: TextStyle(
                            color: TextColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Tell AI how to modify ${widget.petData['Name']}\'s meal',
                          style: TextStyle(
                            color: TextColor.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: TextColor),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current meal summary
                    _buildCurrentMealSummary(),
                    SizedBox(height: 20),
                    
                    // Quick edit options
                    _buildQuickEditOptions(),
                    SizedBox(height: 20),
                    
                    // Custom edit request
                    _buildCustomEditRequest(),
                  ],
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _editRequestController.text.trim().isNotEmpty && !_isLoading
                          ? _submitEditRequest
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 32,
                              width: 32,
                              child: Lottie.asset(
                                'assets/Animations/AnimalcareLoading.json',
                                fit: BoxFit.contain,
                              ),
                            )
                          : Text(
                              'Update Meal Plan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentMealSummary() {
    List<dynamic> ingredients = widget.currentMealPlan['ingredients'] ?? [];
    List<dynamic> supplements = widget.currentMealPlan['supplements_vitamins_minerals'] ?? [];
    List<dynamic> snacks = widget.currentMealPlan['snacks_treats_special_diet'] ?? [];
    String recommendationReason = widget.currentMealPlan['recommendation_reason'] ?? '';
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Meal: ${widget.currentMealPlan['meal_name'] ?? 'Unnamed Meal'}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          // AI Recommendation Reason
          if (recommendationReason.isNotEmpty) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.blue.shade600,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      recommendationReason,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 8),
          Text(
            'Ingredients: ${ingredients.map((i) {
              String name = i['name'] ?? 'Unknown';
              String amount = i['amount_grams']?.toString() ?? '0';
              return '$name - ${amount}g';
            }).join(', ')}',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          if (supplements.isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              'Supplements: ${supplements.join(', ')}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
          if (snacks.isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              'Snacks: ${snacks.join(', ')}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickEditOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Edit Options',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickEditOptions.map((option) {
            return InkWell(
              onTap: () {
                setState(() {
                  _editRequestController.text = option;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _editRequestController.text == option 
                      ? Colors.blue.shade100 
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _editRequestController.text == option 
                        ? Colors.blue.shade300 
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 12,
                    color: _editRequestController.text == option 
                        ? Colors.blue.shade700 
                        : Colors.grey.shade700,
                    fontWeight: _editRequestController.text == option 
                        ? FontWeight.w600 
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomEditRequest() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom Edit Request',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Describe how you want to modify the meal plan:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 12),
        TextField(
          controller: _editRequestController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'e.g., "Add more vegetables and remove rice, include calcium supplement for bone health"',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue.shade400),
            ),
          ),
          onChanged: (value) {
            setState(() {}); // Update button state
          },
        ),
        SizedBox(height: 8),
        Text(
          'Tip: You can add/remove ingredients, supplements, adjust portions, or change nutritional focus.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Future<void> _submitEditRequest() async {
    String editRequest = _editRequestController.text.trim();
    if (editRequest.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Call the AI service to edit the meal plan
      final editedMealPlan = await GeminiMealService.editMealPlan(
        currentMealPlan: widget.currentMealPlan,
        petData: widget.petData,
        editRequest: editRequest,
      );

      setState(() {
        _isLoading = false;
      });

      if (editedMealPlan != null && editedMealPlan['error'] == null) {
        // Success - return edited meal plan
        widget.onMealEdited(editedMealPlan);
        Navigator.pop(context);
        
        // Show success message with edit summary
        if (editedMealPlan['edit_summary'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              elevation: 0,
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.transparent,
              content: AwesomeSnackbarContent(
                title: 'Meal Updated! 🎉',
                message: editedMealPlan['edit_summary'],
                contentType: ContentType.success,
              ),
            ),
          );
        }
      } else {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: AwesomeSnackbarContent(
              title: 'Edit Failed 😔',
              message: editedMealPlan?['error'] ?? 'Failed to edit meal plan. Please try again.',
              contentType: ContentType.failure,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'Error 😔',
            message: 'Failed to edit meal plan: ${e.toString()}',
            contentType: ContentType.failure,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _editRequestController.dispose();
    super.dispose();
  }
}
