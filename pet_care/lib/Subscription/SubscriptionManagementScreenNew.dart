import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import 'package:pet_care/ColorsScheme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pet_care/widgets/pet_background_pattern.dart';
import 'package:pet_care/utils/currency_utils.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:pet_care/DataBase.dart';
import 'package:pet_care/AIScreen/AIMealPlanScreen.dart';
import 'package:pet_care/HomePage/EditPetForm.dart';

class SubscriptionManagementScreenNew extends StatefulWidget {
  final String userEmail;
  
  const SubscriptionManagementScreenNew({super.key, required this.userEmail});

  @override
  State<SubscriptionManagementScreenNew> createState() => _SubscriptionManagementScreenNewState();
}

class _SubscriptionManagementScreenNewState extends State<SubscriptionManagementScreenNew> {
  List<Map<String, dynamic>> subscriptions = [];
  bool isLoading = true;
  bool isGeneratingMeal = false;
  Map<String, dynamic>? currentGeneratedMeal;

  @override
  void initState() {
    super.initState();
    loadSubscriptions();
  }

  Future<void> loadSubscriptions() async {
    setState(() {
      isLoading = true;
    });

    try {
      var db = FirebaseFirestore.instance;
      var querySnapshot = await db.collection('subscriptions')
          .where('petId', isEqualTo: widget.userEmail)
          .get();

      List<Map<String, dynamic>> loadedSubscriptions = [];
      for (var doc in querySnapshot.docs) {
        var data = doc.data();
        data['docId'] = doc.id; // Store document ID for updates
        loadedSubscriptions.add(data);
      }

      setState(() {
        subscriptions = loadedSubscriptions;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading subscriptions: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Navigate to AI Meal Plan Screen for generating new meals
  Future<void> generateNewMeal(Map<String, dynamic> subscription) async {
    try {
      // Get pet data for this subscription
      Map<String, dynamic> petData = await _getPetDataForSubscription(subscription);
      
      if (petData.isEmpty) {
        _showErrorDialog('Could not find pet data for this subscription');
        return;
      }

      // Navigate to existing AI Meal Plan Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AIMealPlanScreen(petData: petData),
        ),
      );
    } catch (e) {
      _showErrorDialog('Failed to open meal planner: ${e.toString()}');
    }
  }

  /// Get pet data for subscription from database
  Future<Map<String, dynamic>> _getPetDataForSubscription(Map<String, dynamic> subscription) async {
    try {
      String petId = subscription['petId'] ?? '';
      String userEmail = subscription['userId'] ?? widget.userEmail;
      
      if (petId.isEmpty) {
        throw Exception('Pet ID not found in subscription');
      }

      // Get pet data from database
      Map<String, dynamic> petData = await DataBase.readData(userEmail, petId);
      return petData;
    } catch (e) {
      print('Error getting pet data: $e');
      return {};
    }
  }

  /// Navigate to AI Meal Plan Screen for editing current meal
  Future<void> editCurrentMeal(Map<String, dynamic> subscription) async {
    try {
      // Get pet data for this subscription
      Map<String, dynamic> petData = await _getPetDataForSubscription(subscription);
      
      if (petData.isEmpty) {
        _showErrorDialog('Could not find pet data for this subscription');
        return;
      }

      // Navigate to existing AI Meal Plan Screen
      // The AIMealPlanScreen has edit functionality built-in
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AIMealPlanScreen(petData: petData),
        ),
      );
    } catch (e) {
      _showErrorDialog('Failed to open meal editor: ${e.toString()}');
    }
  }

  /// Navigate to Edit Pet Form and regenerate meal after update
  Future<void> editPetDetails(Map<String, dynamic> subscription) async {
    try {
      // Get current pet data
      String userEmail = subscription['userId'] ?? widget.userEmail;
      String petId = subscription['petId'] ?? '';
      
      if (userEmail.isEmpty || petId.isEmpty) {
        _showErrorDialog('Missing pet information.');
        return;
      }

      // Fetch current pet data
      Map<String, dynamic> petData = await DataBase.readData(userEmail, petId);
      Map<String, dynamic> userData = await DataBase.readData('UserData', userEmail);

      if (petData.isEmpty) {
        _showErrorDialog('Could not load pet data.');
        return;
      }

      if (userData.isEmpty) {
        _showErrorDialog('Could not load user data.');
        return;
      }

      // Navigate to existing edit pet form
      bool? wasUpdated = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditPetForm(
            userData: userData,
            petData: petData,
          ),
        ),
      );

      if (wasUpdated == true) {
        // Pet details were updated, show success message
        _showSuccessSnackBar('Pet details updated successfully! 🐕');
        
        // Reload subscriptions to reflect any changes
        await loadSubscriptions();
      }
    } catch (e) {
      print('Error editing pet details: $e');
      _showErrorDialog('Failed to load pet details for editing.');
    }
  }

  /// Show success snackbar
  void _showSuccessSnackBar(String message) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: 'Success!',
        message: message,
        contentType: ContentType.success,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showMealPreviewDialog(Map<String, dynamic> mealPlan, Map<String, dynamic> subscription, bool isNewMeal) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.grey.shade50],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                // Background pattern
                PetBackgroundPattern(
                  opacity: 0.03,
                  symbolSize: 12.0,
                  density: 0.3,
                ),
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Row(
                          children: [
                            Text(
                              isNewMeal ? '🆕 New Meal Plan' : '✏️ Current Meal Plan',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            Spacer(),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(Icons.close, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Meal plan display - Using simplified display instead of widget
                        _buildMealPlanDisplay(mealPlan),
                        
                        SizedBox(height: 20),
                        
                        // Action buttons
                        Column(
                          children: [
                            if (isNewMeal) ...[
                              Container(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await _saveMealPlan(mealPlan, subscription);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    elevation: 5,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: Text(
                                    '✅ Use This Meal Plan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    generateNewMeal(subscription); // Generate another one
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.blue),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: Text(
                                    '🔄 Generate Another Plan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
                              Container(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    generateNewMeal(subscription);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    elevation: 5,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: Text(
                                    '🆕 Generate New Meal',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'Close',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMealPlanDisplay(Map<String, dynamic> mealPlan) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.green.shade50],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                mealPlan['image'] ?? '🍽️',
                style: TextStyle(fontSize: 32),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mealPlan['name'] ?? 'Custom Meal Plan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      mealPlan['description'] ?? 'AI-generated meal plan for your pet',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Ingredients
          if (mealPlan['ingredients'] != null) ...[
            Text(
              '🥘 Ingredients:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            ...((mealPlan['ingredients'] as List<dynamic>?) ?? []).take(5).map((ingredient) => 
              Padding(
                padding: EdgeInsets.only(left: 16, bottom: 4),
                child: Text(
                  '• ${ingredient.toString()}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ],
          
          SizedBox(height: 12),
          
          // Price info
          if (mealPlan['price'] != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Price per meal:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  CurrencyUtils.formatThb(mealPlan['price']),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _saveMealPlan(Map<String, dynamic> newMealPlan, Map<String, dynamic> subscription) async {
    try {
      var db = FirebaseFirestore.instance;
      String docId = subscription['docId'];
      
      // Update subscription with new meal plan
      await db.collection('subscriptions').doc(docId).update({
        'selectedMealPlan': newMealPlan,
        'mealPlan': newMealPlan['name'] ?? 'Custom Meal Plan',
        'mealPlanDetails': newMealPlan,
        'lastMealUpdate': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Show success message
      _showSuccessDialog('✅ Meal Plan Updated!', 'Your new meal plan has been saved successfully. It will be used for your next delivery.');
      
      // Reload subscriptions to show updated data
      loadSubscriptions();
    } catch (e) {
      print('Error saving meal plan: $e');
      _showErrorDialog('Failed to save the new meal plan. Please try again.');
    }
  }

  Future<void> cancelSubscription(String docId, String petName) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cancel Subscription'),
          content: Text('Are you sure you want to cancel the meal subscription for $petName?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Keep Subscription'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Cancel Subscription', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        var db = FirebaseFirestore.instance;
        await db.collection('subscriptions').doc(docId).update({
          'status': 'cancelled',
          'cancelledAt': DateTime.now().toIso8601String(),
        });

        _showSuccessDialog('❌ Subscription Cancelled', 'Subscription cancelled successfully');
        loadSubscriptions(); // Reload subscriptions
      } catch (e) {
        _showErrorDialog('Failed to cancel subscription: $e');
      }
    }
  }

  void _showErrorDialog(String message) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: 'Error!',
        message: message,
        contentType: ContentType.failure,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showSuccessDialog(String title, String message) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: title,
        message: message,
        contentType: ContentType.success,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showInfoDialog(String title, String message) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: title,
        message: message,
        contentType: ContentType.help,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  String getNextDeliveryText(Map<String, dynamic> subscription) {
    String frequency = subscription['frequency'] ?? '';
    String createdAt = subscription['createdAt'] ?? '';
    
    if (createdAt.isEmpty) return 'Date TBD';
    
    try {
      DateTime created = DateTime.parse(createdAt);
      DateTime nextDelivery;
      
      if (frequency == '1x/week') {
        nextDelivery = created.add(Duration(days: 7));
      } else if (frequency == '2x/week') {
        nextDelivery = created.add(Duration(days: 3)); // First delivery after 3 days, then every 3-4 days
      } else {
        nextDelivery = created.add(Duration(days: 7)); // Default to weekly
      }
      
      return '${nextDelivery.day}/${nextDelivery.month}/${nextDelivery.year}';
    } catch (e) {
      return 'Date TBD';
    }
  }

  String getStatusBadgeText(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'cancelled':
        return 'Cancelled';
      case 'paused':
        return 'Paused';
      case 'pending':
        return 'Pending';
      default:
        return 'Unknown';
    }
  }

  Color getStatusBadgeColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'paused':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Manage Subscription",
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
              child: isLoading
                  ? Center(
                      child: Lottie.asset(
                        'assets/Animations/AnimalcareLoading.json',
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                      ),
                    )
                  : subscriptions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '🍽️',
                                style: TextStyle(fontSize: 80),
                              ),
                              SizedBox(height: 20),
                              Text(
                                'No Active Subscriptions',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Start a meal subscription for your pets\nto get custom nutrition delivered!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: loadSubscriptions,
                          child: ListView.builder(
                            padding: EdgeInsets.all(20),
                            itemCount: subscriptions.length,
                            itemBuilder: (context, index) {
                              final subscription = subscriptions[index];
                              final bool isActive = subscription['status'] == 'active';
                              
                              return Card(
                                margin: EdgeInsets.only(bottom: 16),
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Container(
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    gradient: isActive 
                                        ? LinearGradient(
                                            colors: [Colors.green.shade50, Colors.green.shade100],
                                          )
                                        : LinearGradient(
                                            colors: [Colors.grey.shade100, Colors.grey.shade200],
                                          ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Pet header
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: isActive ? Colors.green.shade100 : Colors.grey.shade200,
                                              borderRadius: BorderRadius.circular(30),
                                            ),
                                            child: Text(
                                              '🐕',
                                              style: TextStyle(fontSize: 24),
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
                                                        subscription['petName'] ?? 'Unknown Pet',
                                                        style: TextStyle(
                                                          fontSize: 20,
                                                          fontWeight: FontWeight.bold,
                                                          color: isActive ? Colors.green.shade800 : Colors.grey.shade700,
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: getStatusBadgeColor(subscription['status'] ?? 'unknown'),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Text(
                                                        getStatusBadgeText(subscription['status'] ?? 'unknown'),
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  '${subscription['dogSize']} Dog • ${subscription['frequency']}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      SizedBox(height: 16),
                                      
                                      // Current meal plan
                                      Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text('Current Meal Plan:', style: TextStyle(fontWeight: FontWeight.w500)),
                                                Flexible(
                                                  child: Text(
                                                    subscription['mealPlan'] ?? 'Unknown',
                                                    textAlign: TextAlign.right,
                                                    style: TextStyle(fontSize: 14),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text('Monthly Total:', style: TextStyle(fontWeight: FontWeight.w500)),
                                                Text(
                                                  CurrencyUtils.formatThb(subscription['totalAmount'] ?? 0),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text('Next Delivery:', style: TextStyle(fontWeight: FontWeight.w500)),
                                                Text(
                                                  getNextDeliveryText(subscription),
                                                  style: TextStyle(color: Colors.blue.shade700),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      SizedBox(height: 16),
                                      
                                      // Management buttons
                                      if (isActive) ...[
                                        // Meal management section
                                        Text(
                                          '🍽️ Meal Management',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: isGeneratingMeal ? null : () => generateNewMeal(subscription),
                                                icon: isGeneratingMeal 
                                                  ? SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child: Lottie.asset(
                                                        'assets/Animations/AnimalcareLoading.json',
                                                        width: 24,
                                                        height: 24,
                                                        fit: BoxFit.contain,
                                                      ),
                                                    )
                                                  : Icon(Icons.auto_awesome, size: 16),
                                                label: Text(
                                                  isGeneratingMeal ? 'Generating...' : 'Generate New',
                                                  style: TextStyle(fontSize: 12),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.blue,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () => editCurrentMeal(subscription),
                                                icon: Icon(Icons.edit, size: 16),
                                                label: Text(
                                                  'Edit Current',
                                                  style: TextStyle(fontSize: 12),
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  side: BorderSide(color: Colors.green),
                                                  foregroundColor: Colors.green,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        SizedBox(height: 16),
                                        
                                        // Pet and subscription management
                                        Text(
                                          '🐕 Pet & Subscription',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () => editPetDetails(subscription),
                                                icon: Icon(Icons.pets, size: 16),
                                                label: Text(
                                                  'Edit Pet Details',
                                                  style: TextStyle(fontSize: 12),
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  side: BorderSide(color: Colors.orange),
                                                  foregroundColor: Colors.orange,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: () => cancelSubscription(
                                                  subscription['docId'],
                                                  subscription['petName'] ?? 'Pet',
                                                ),
                                                icon: Icon(Icons.cancel, size: 16),
                                                label: Text(
                                                  'Cancel',
                                                  style: TextStyle(fontSize: 12),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red.shade500,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ] else ...[
                                        Container(
                                          padding: EdgeInsets.symmetric(vertical: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade300,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Subscription ${getStatusBadgeText(subscription['status'] ?? 'unknown')}',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// Edit Pet Form Dark adapted for editing
class EditPetFormDark extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Map<String, dynamic> petData;
  
  const EditPetFormDark({super.key, required this.userData, required this.petData});

  @override
  State<EditPetFormDark> createState() => _EditPetFormDarkState();
}

class _EditPetFormDarkState extends State<EditPetFormDark> {
  final GlobalKey<FormState> petForm = GlobalKey<FormState>();
  final TextEditingController petNameController = TextEditingController();
  final TextEditingController oneLineController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  
  String dateOfBirthController = "";
  String dropdownvalue = 'Cat';
  String selectedCategory = "Cat";
  String selectedWeightUnit = "kg";
  
  bool showSpinner = false;
  bool isDateOfBirthSelected = false;
  
  var catValue = [
    'Cat', 'Persian', 'Siamese', 'Maine Coon', 'Bengal', 'Ragdoll',
    'British Shorthair', 'Sphynx', 'Abyssinian', 'Scottish Fold', 'Siberian'
  ];
  var dogValue = [
    'Dog', 'Labrador Retriever', 'German Shepherd', 'Golden Retriever',
    'Bulldog', 'Beagle', 'Poodle', 'French Bulldog', 'Rottweiler',
    'Yorkshire Terrier', 'Boxer'
  ];

  @override
  void initState() {
    super.initState();
    _populateFields();
  }

  void _populateFields() {
    petNameController.text = widget.petData['Name'] ?? '';
    oneLineController.text = widget.petData['oneLine'] ?? '';
    weightController.text = widget.petData['weight'] ?? '';
    ageController.text = widget.petData['age'] ?? '';
    selectedCategory = widget.petData['Category'] ?? 'Dog';
    dropdownvalue = widget.petData['Breed'] ?? (selectedCategory == 'Cat' ? 'Cat' : 'Dog');
    dateOfBirthController = widget.petData['DateOfBirth'] ?? '';
    selectedWeightUnit = widget.petData['weightUnit'] ?? 'kg';
    
    if (dateOfBirthController.isNotEmpty) {
      isDateOfBirthSelected = true;
    }
  }

  Future<void> _saveChanges() async {
    if (petForm.currentState!.validate()) {
      setState(() {
        showSpinner = true;
      });

      try {
        Map<String, dynamic> updatedPetData = {
          ...widget.petData,
          "Name": petNameController.text,
          "oneLine": oneLineController.text,
          "Category": selectedCategory,
          "Breed": dropdownvalue,
          "DateOfBirth": dateOfBirthController,
          "weight": weightController.text,
          "weightUnit": selectedWeightUnit,
          "age": ageController.text,
          "updatedAt": DateTime.now().toIso8601String(),
        };

        // Update in database
        bool success = await DataBase.updateUserData(
          widget.userData["Email"], 
          widget.petData["Email"], 
          updatedPetData
        );

        if (success) {
          final snackBar = SnackBar(
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: AwesomeSnackbarContent(
              title: 'Pet Updated!',
              message: 'Pet details updated successfully',
              contentType: ContentType.success,
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
          
          Navigator.pop(context, updatedPetData);
        } else {
          throw Exception('Failed to update pet data');
        }
      } catch (e) {
        final snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'Error!',
            message: 'Failed to update pet details: $e',
            contentType: ContentType.failure,
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      } finally {
        setState(() {
          showSpinner = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Edit Pet Details",
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
        height: double.maxFinite,
        decoration: BoxDecoration(gradient: backgroundColor),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: petForm,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Pet Name
                  TextFormField(
                    controller: petNameController,
                    validator: (value) => value?.isEmpty ?? true ? "Please Enter Pet Name" : null,
                    decoration: InputDecoration(
                      labelText: "Pet Name",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey[400],
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // One Line Description
                  TextFormField(
                    controller: oneLineController,
                    validator: (value) => value?.isEmpty ?? true ? "Please Enter Description" : null,
                    decoration: InputDecoration(
                      labelText: "One Line Description",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey[400],
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Weight
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: weightController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Weight",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[400],
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedWeightUnit,
                          onChanged: (newValue) {
                            setState(() {
                              selectedWeightUnit = newValue!;
                            });
                          },
                          items: ['kg', 'lbs'].map((String unit) {
                            return DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            );
                          }).toList(),
                          decoration: InputDecoration(
                            labelText: "Unit",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[400],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  
                  // Age
                  TextFormField(
                    controller: ageController,
                    decoration: InputDecoration(
                      labelText: "Age (e.g., 2 years, 6 months)",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey[400],
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Category selection
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text("Cat", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                              value: "Cat",
                              groupValue: selectedCategory,
                              onChanged: (String? value) {
                                setState(() {
                                  selectedCategory = value!;
                                  dropdownvalue = catValue.first;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text("Dog", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                              value: "Dog",
                              groupValue: selectedCategory,
                              onChanged: (String? value) {
                                setState(() {
                                  selectedCategory = value!;
                                  dropdownvalue = dogValue.first;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Breed dropdown
                  DropdownButtonFormField(
                    value: dropdownvalue,
                    onChanged: (newValue) {
                      setState(() {
                        dropdownvalue = newValue as String;
                      });
                    },
                    items: (selectedCategory == "Cat" ? catValue : dogValue).map((String item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      labelText: "Breed",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey[400],
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Date of Birth
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            "Date of Birth :",
                            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(1990),
                                lastDate: DateTime.now(),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  isDateOfBirthSelected = true;
                                  dateOfBirthController = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              dateOfBirthController.isEmpty ? "Select Date of Birth" : dateOfBirthController,
                              style: TextStyle(fontSize: 16, color: subTextColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  
                  // Save button
                  ElevatedButton(
                    onPressed: showSpinner ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      disabledBackgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    ),
                    child: showSpinner
                        ? Lottie.asset(
                            'assets/Animations/AnimalcareLoading.json',
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                          )
                        : Text(
                            "Save Changes",
                            style: TextStyle(
                              fontSize: 18,
                              color: subTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
