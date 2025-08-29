import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import 'package:pet_care/ColorsScheme.dart';
import 'package:pet_care/Subscription/PaymentScreen.dart';
import 'package:pet_care/services/ingredient_service.dart';
import 'package:pet_care/utils/sample_data_helper.dart';
import 'package:pet_care/utils/currency_utils.dart';
import 'package:pet_care/widgets/pet_background_pattern.dart';

class SubscriptionPlanScreen extends StatefulWidget {
  final Map<String, dynamic> petData;
  
  const SubscriptionPlanScreen({super.key, required this.petData});

  @override
  State<SubscriptionPlanScreen> createState() => _SubscriptionPlanScreenState();
}

class _SubscriptionPlanScreenState extends State<SubscriptionPlanScreen> {
  String selectedFrequency = '';
  String selectedDogSize = '';
  List<Map<String, dynamic>> availableIngredients = [];
  bool isLoadingIngredients = true;
  
  final List<Map<String, dynamic>> frequencies = [
    {
      'frequency': '1x/week',
      'title': 'Weekly Plan',
      'subtitle': '4 meals per month',
      'icon': '📅',
      'mealsPerMonth': 4,
      'discountMultiplier': 1.0,
    },
    {
      'frequency': '2x/week',
      'title': 'Bi-Weekly Plan',
      'subtitle': '8 meals per month',
      'icon': '📋',
      'mealsPerMonth': 8,
      'discountMultiplier': 0.9, // 10% discount for more frequent orders
    },
  ];

  final List<Map<String, dynamic>> dogSizes = [
    {
      'size': 'Small',
      'weight': '< 25 lbs (< 11.3 kg)',
      'portionMultiplier': 0.7, // 70% of base portion
      'icon': '🐕',
      'description': 'Perfect for toy breeds and small companions',
      'weightRange': [0.0, 11.3],
    },
    {
      'size': 'Medium',
      'weight': '25-60 lbs (11.3-27.2 kg)',
      'portionMultiplier': 1.0, // 100% of base portion
      'icon': '🐶',
      'description': 'Ideal for most family dogs',
      'weightRange': [11.3, 27.2],
    },
    {
      'size': 'Large',
      'weight': '> 60 lbs (> 27.2 kg)',
      'portionMultiplier': 1.4, // 140% of base portion
      'icon': '🐕‍🦺',
      'description': 'Great for big breeds and active dogs',
      'weightRange': [27.2, double.infinity],
    },
  ];

  double calculateMonthlyPrice() {
    // If we have actual meal price from AI, use it even if ingredients aren't loaded
    if (widget.petData['actualMealPrice'] != null) {
      if (selectedFrequency.isEmpty || selectedDogSize.isEmpty) return 0.0;
    } else {
      // For fallback calculation, we need ingredients
      if (selectedFrequency.isEmpty || selectedDogSize.isEmpty || availableIngredients.isEmpty) return 0.0;
    }
    
    var sizeData = dogSizes.firstWhere((size) => size['size'] == selectedDogSize);
    var frequencyData = frequencies.firstWhere((freq) => freq['frequency'] == selectedFrequency);
    
    // Calculate base meal cost using real ingredient prices OR actual AI meal price
    double baseMealCost = calculateBaseMealCost();
    
    // Apply size multiplier (portion size affects ingredient quantities)
    double portionMultiplier = sizeData['portionMultiplier'];
    double adjustedMealCost = baseMealCost * portionMultiplier;
    
    // Calculate monthly cost
    int mealsPerMonth = frequencyData['mealsPerMonth'];
    double monthlyTotal = adjustedMealCost * mealsPerMonth;
    
    // Apply frequency discount
    double discountMultiplier = frequencyData['discountMultiplier'];
    
    return monthlyTotal * discountMultiplier;
  }

  double calculateBaseMealCost() {
    // Check if we have actual meal price from AI meal planner
    if (widget.petData['actualMealPrice'] != null) {
      return widget.petData['actualMealPrice'].toDouble();
    }
    
    // Fallback to ingredient-based calculation if no actual meal price
    if (availableIngredients.isEmpty) return 8.99; // fallback price

    // Base portions for a medium dog meal (can be scaled by dog size)
    Map<String, double> baseMealPortions = {
      'Protein': 0.15, // 150g protein per meal
      'Carbohydrate': 0.10, // 100g carbs per meal
      'Vegetable': 0.08, // 80g vegetables per meal
      'Supplement': 0.01, // 10g supplements per meal
    };

    double totalCost = 0.0;
    
    for (String category in baseMealPortions.keys) {
      // Find the average price for this category
      List<Map<String, dynamic>> categoryIngredients = availableIngredients
          .where((ingredient) => ingredient['category'] == category)
          .toList();
      
      if (categoryIngredients.isNotEmpty) {
        // Use average price of available ingredients in this category
        double avgPricePerUnit = categoryIngredients
            .map<double>((ing) => (ing['pricePerUnit'] ?? 0.0).toDouble())
            .reduce((a, b) => a + b) / categoryIngredients.length;
        
        double portionSize = baseMealPortions[category]!;
        totalCost += avgPricePerUnit * portionSize;
      }
    }
    
    // Ensure minimum viable price
    return totalCost < 5.0 ? 8.99 : totalCost;
  }

  Future<void> loadIngredients() async {
    setState(() {
      isLoadingIngredients = true;
    });

    try {
      // Ensure sample ingredients exist
      await SampleDataHelper.addSampleIngredientsIfEmpty();
      
      // Fetch available ingredients
      final ingredients = await IngredientService.fetchAvailableIngredients();
      setState(() {
        availableIngredients = ingredients;
        isLoadingIngredients = false;
      });
      
      if (ingredients.isEmpty) {
        // Add some basic fallback prices if no ingredients available
        print('No ingredients found, using fallback pricing');
      }
    } catch (e) {
      print('Error loading ingredients: $e');
      setState(() {
        isLoadingIngredients = false;
      });
    }
  }

  String getRecommendedPlan() {
    if (widget.petData['weight'] != null) {
      double? weight = double.tryParse(widget.petData['weight'].toString());
      if (weight != null) {
        // Convert to kg if needed
        String weightUnit = widget.petData['weightUnit'] ?? 'kg';
        if (weightUnit.toLowerCase() == 'lbs' || weightUnit.toLowerCase() == 'pounds') {
          weight = weight * 0.453592; // Convert lbs to kg
        }
        
        for (var sizeData in dogSizes) {
          List<dynamic> weightRange = sizeData['weightRange'];
          double minWeight = (weightRange[0] as num).toDouble();
          double maxWeight = (weightRange[1] as num).toDouble();
          
          if (weight >= minWeight && weight < maxWeight) {
            return sizeData['size'];
          }
        }
      }
    }
    
    // Fallback to age-based recommendation
    if (widget.petData['age'] != null) {
      String age = widget.petData['age'].toString().toLowerCase();
      if (age.contains('puppy') || age.contains('young')) {
        return 'Small';
      } else if (age.contains('senior') || age.contains('old')) {
        return 'Medium'; // Senior dogs often need moderate portions
      }
    }
    
    return 'Medium'; // Default recommendation
  }

  String getPricePerMeal({String? dogSize}) {
    // Use the provided dogSize or fall back to selectedDogSize
    String sizeToUse = dogSize ?? selectedDogSize;
    if (sizeToUse.isEmpty) return '--';
    
    // If we have actual meal price from AI, we don't need ingredients to be loaded
    if (widget.petData['actualMealPrice'] != null || availableIngredients.isNotEmpty) {
      var sizeData = dogSizes.firstWhere((size) => size['size'] == sizeToUse);
      double baseMealCost = calculateBaseMealCost();
      double portionMultiplier = sizeData['portionMultiplier'];
      double adjustedMealCost = baseMealCost * portionMultiplier;
      
      return CurrencyUtils.formatThb(adjustedMealCost);
    }
    
    return '--';
  }

  String getMonthlyPrice({String? dogSize, String? frequency}) {
    // If we have actual meal price from AI, we don't need ingredients to be loaded
    if (widget.petData['actualMealPrice'] == null && availableIngredients.isEmpty) return '--';
    
    String sizeToUse = dogSize ?? selectedDogSize;
    String freqToUse = frequency ?? selectedFrequency;
    
    if (sizeToUse.isEmpty || freqToUse.isEmpty) return '--';
    
    var sizeData = dogSizes.firstWhere((size) => size['size'] == sizeToUse);
    var frequencyData = frequencies.firstWhere((freq) => freq['frequency'] == freqToUse);
    
    double baseMealCost = calculateBaseMealCost();
    double portionMultiplier = sizeData['portionMultiplier'];
    double adjustedMealCost = baseMealCost * portionMultiplier;
    
    int mealsPerMonth = frequencyData['mealsPerMonth'];
    double monthlyTotal = adjustedMealCost * mealsPerMonth;
    double discountMultiplier = frequencyData['discountMultiplier'];
    
    return CurrencyUtils.formatThb(monthlyTotal * discountMultiplier);
  }

  @override
  void initState() {
    super.initState();
    // Load ingredients first
    loadIngredients();
    
    // Auto-select recommended plan based on pet weight/age
    String recommended = getRecommendedPlan();
    if (recommended.isNotEmpty) {
      selectedDogSize = recommended;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Select Your Plan",
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
      body: SafeArea(
        bottom: true,
        child: Stack(
          children: [
          PetBackgroundPattern(
            opacity: 0.05,
            symbolSize: 14.0,
            density: 0.5,
          ),
          Container(
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
                // Pet info card
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
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child: Text(
                            '🐕',
                            style: TextStyle(fontSize: 30),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.petData['Name'] ?? 'Your Dog',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${widget.petData['Breed'] ?? 'Mixed Breed'} • ${widget.petData['weight'] ?? 'Unknown'} ${widget.petData['weightUnit'] ?? 'kg'}',
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
                ),
                
                SizedBox(height: 30),

                // Delivery frequency section
                Text(
                  '📦 Choose Delivery Frequency',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 15),
                
                ...frequencies.map((frequency) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedFrequency = frequency['frequency'];
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selectedFrequency == frequency['frequency'] 
                            ? Colors.green.shade100 
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedFrequency == frequency['frequency'] 
                              ? Colors.green 
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(
                            frequency['icon'],
                            style: TextStyle(fontSize: 24),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  frequency['title'],
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  frequency['subtitle'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (selectedFrequency == frequency['frequency'])
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  ),
                )).toList(),

                SizedBox(height: 30),

                // Dog size section
                Text(
                  '🐕 Choose Dog Size & Portions',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 15),

                ...dogSizes.map((size) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedDogSize = size['size'];
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selectedDogSize == size['size'] 
                            ? Colors.blue.shade100 
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedDogSize == size['size'] 
                              ? Colors.blue 
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none, // Allow the badge to extend outside the container
                        children: [
                          // Main content without any special padding
                          Column(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    size['icon'],
                                    style: TextStyle(fontSize: 28),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          size['size'],
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          size['weight'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        Text(
                                          'Portion: ${(size['portionMultiplier'] * 100).round()}% of base',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (isLoadingIngredients && widget.petData['actualMealPrice'] == null)
                                        SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: Lottie.asset(
                                            'assets/Animations/AnimalcareLoading.json',
                                            fit: BoxFit.contain,
                                          ),
                                        )
                                      else ...[
                                        Text(
                                          getPricePerMeal(dogSize: size['size']),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                        if (selectedFrequency.isNotEmpty)
                                          Text(
                                            getMonthlyPrice(dogSize: size['size']),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                      ],
                                      Text(
                                        selectedFrequency.isNotEmpty ? 'per month' : 'per meal',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (selectedDogSize == size['size'])
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Colors.blue,
                                        size: 24,
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                size['description'],
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                          // Recommended badge - orange rectangular badge at top-right corner
                          if (size['size'] == getRecommendedPlan())
                            Positioned(
                              top: -24,
                              right: -10,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(0.4),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Recommended',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                )).toList(),

                SizedBox(height: 30),

                // Price summary and ingredient loading status
                if (selectedFrequency.isNotEmpty && selectedDogSize.isNotEmpty)
                  Column(
                    children: [
                      // Ingredient loading status (only show if we don't have actual meal price)
                      if (isLoadingIngredients && widget.petData['actualMealPrice'] == null)
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Lottie.asset(
                                  'assets/Animations/AnimalcareLoading.json',
                                  fit: BoxFit.contain,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Loading ingredient prices...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      SizedBox(height: 16),
                      
                      // Price breakdown
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange.shade400, Colors.orange.shade600],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Monthly Subscription',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  (isLoadingIngredients && widget.petData['actualMealPrice'] == null)
                                      ? 'Calculating...'
                                      : CurrencyUtils.formatThb(calculateMonthlyPrice()),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            
                            // Meal breakdown
                            if (!isLoadingIngredients || widget.petData['actualMealPrice'] != null) ...[
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Per meal cost:',
                                          style: TextStyle(color: Colors.white70, fontSize: 14),
                                        ),
                                        Text(
                                          getPricePerMeal(),
                                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Meals per month:',
                                          style: TextStyle(color: Colors.white70, fontSize: 14),
                                        ),
                                        Text(
                                          '${frequencies.firstWhere((f) => f['frequency'] == selectedFrequency)['mealsPerMonth']}',
                                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                    if (frequencies.firstWhere((f) => f['frequency'] == selectedFrequency)['discountMultiplier'] < 1.0) ...[
                                      SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Frequency discount:',
                                            style: TextStyle(color: Colors.white70, fontSize: 14),
                                          ),
                                          Text(
                                            '${((1 - frequencies.firstWhere((f) => f['frequency'] == selectedFrequency)['discountMultiplier']) * 100).round()}% OFF',
                                            style: TextStyle(color: Colors.green.shade200, fontSize: 14, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              SizedBox(height: 8),
                            ],
                            
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '$selectedDogSize Dog • $selectedFrequency',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!isLoadingIngredients || widget.petData['actualMealPrice'] != null)
                                  Flexible(
                                    flex: 1,
                                    child: Text(
                                      widget.petData['actualMealPrice'] != null 
                                          ? 'AI meal prices'
                                          : 'Real prices',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white60,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      textAlign: TextAlign.end,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                SizedBox(height: 30),

                // Continue button
                if (selectedFrequency.isNotEmpty && selectedDogSize.isNotEmpty)
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (isLoadingIngredients && widget.petData['actualMealPrice'] == null) ? null : () {
                        Map<String, dynamic> subscriptionData = {
                          ...widget.petData,
                          'frequency': selectedFrequency,
                          'dogSize': selectedDogSize,
                          'monthlyPrice': calculateMonthlyPrice(),
                          'baseMealCost': calculateBaseMealCost(),
                          'mealPrice': calculateBaseMealCost() * dogSizes.firstWhere((size) => size['size'] == selectedDogSize)['portionMultiplier'],
                          'portionMultiplier': dogSizes.firstWhere((size) => size['size'] == selectedDogSize)['portionMultiplier'],
                          'mealsPerMonth': frequencies.firstWhere((freq) => freq['frequency'] == selectedFrequency)['mealsPerMonth'],
                          'availableIngredients': availableIngredients,
                          'selectedMealPlan': widget.petData['mealPlanDetails'] ?? 'Custom Premium Plan', // Use AI meal plan if available
                        };
                        
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => 
                            PaymentScreen(
                              subscriptionData: subscriptionData,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (isLoadingIngredients && widget.petData['actualMealPrice'] == null)
                            ? Colors.grey.shade400 
                            : Colors.green.shade600,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: (isLoadingIngredients && widget.petData['actualMealPrice'] == null) ? 0 : 5,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isLoadingIngredients && widget.petData['actualMealPrice'] == null)
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Lottie.asset(
                                'assets/Animations/AnimalcareLoading.json',
                                fit: BoxFit.contain,
                              ),
                            )
                          else
                            Icon(
                              Icons.payment,
                              color: Colors.white,
                              size: 24,
                            ),
                          SizedBox(width: 8),
                          Text(
                            (isLoadingIngredients && widget.petData['actualMealPrice'] == null)
                                ? 'Loading Ingredients...'
                                : 'Proceed to Payment',
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
        ],
        ),
      ),
    );
  }
}
