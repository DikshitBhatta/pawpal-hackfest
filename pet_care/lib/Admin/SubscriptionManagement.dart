import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:pet_care/services/subscription_order_service.dart';

class SubscriptionManagement extends StatefulWidget {
  const SubscriptionManagement({Key? key}) : super(key: key);

  @override
  State<SubscriptionManagement> createState() => _SubscriptionManagementState();
}

class _SubscriptionManagementState extends State<SubscriptionManagement> {
  String selectedFilter = 'pending';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff2A2438),
      appBar: AppBar(
        backgroundColor: const Color(0xff2A2438),
        title: const Text(
          'Subscription Management',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Pending', 'pending'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Approved', 'approved'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Rejected', 'rejected'),
                        const SizedBox(width: 8),
                        _buildFilterChip('All', 'all'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getSubscriptionsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }

                final subscriptions = snapshot.data?.docs ?? [];
                
                if (selectedFilter != 'all' && subscriptions.isNotEmpty) {
                  subscriptions.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    final aTime = aData['createdAt'] ?? '';
                    final bTime = bData['createdAt'] ?? '';
                    
                    return bTime.toString().compareTo(aTime.toString());
                  });
                }

                if (subscriptions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No ${selectedFilter == 'all' ? '' : selectedFilter} subscriptions found',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: subscriptions.length,
                  itemBuilder: (context, index) {
                    final subscription = subscriptions[index].data() as Map<String, dynamic>;
                    final subscriptionId = subscriptions[index].id;
                    
                    return _buildSubscriptionCard(subscription, subscriptionId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getSubscriptionsStream() {
    Query query = FirebaseFirestore.instance.collection('subscriptions');
    
    if (selectedFilter != 'all') {
      query = query.where('status', isEqualTo: selectedFilter);
      return query.snapshots();
    } else {
      return query.orderBy('createdAt', descending: true).snapshots();
    }
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = selectedFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xffB0A0D6),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            selectedFilter = value;
          });
        }
      },
      backgroundColor: const Color(0xff352F44),
      selectedColor: const Color(0xff8476AA),
      checkmarkColor: Colors.white,
    );
  }

  Widget _buildSubscriptionCard(Map<String, dynamic> subscription, String subscriptionId) {
    final status = subscription['status'] ?? 'pending';
    final createdAt = subscription['createdAt'] ?? '';
    final petName = subscription['petName'] ?? 'Unknown Pet';
    final mealPlanDetails = subscription['mealPlanDetails'];
    final totalAmount = subscription['totalAmount']?.toDouble() ?? 0.0;
    final hasScreenshot = subscription['paymentScreenshotUrl'] != null && 
                         subscription['paymentScreenshotUrl'].toString().isNotEmpty;

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending_actions;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xff352F44),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(createdAt),
                  style: const TextStyle(
                    color: Color(0xffB0A0D6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        petName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (mealPlanDetails != null)
                        Row(
                          children: [
                            Text(
                              '${mealPlanDetails['image'] ?? '🍗'} ',
                              style: const TextStyle(fontSize: 16),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mealPlanDetails['meal_name'] ?? mealPlanDetails['name'] ?? 'AI Meal Plan',
                                    style: const TextStyle(
                                      color: Color(0xffB0A0D6),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (mealPlanDetails['total_price'] != null || mealPlanDetails['price'] != null)
                                    Text(
                                      '฿${(mealPlanDetails['total_price'] ?? mealPlanDetails['price'] ?? 0.0).toStringAsFixed(2)} per meal',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Text(
                        '${subscription['dogSize'] ?? 'Unknown'} • ${subscription['frequency'] ?? 'Unknown'}',
                        style: const TextStyle(
                          color: Color(0xffB0A0D6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '฿${totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'per month',
                      style: const TextStyle(
                        color: Color(0xffB0A0D6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Top row: View Proof and Meal Plan buttons
            Row(
              children: [
                if (hasScreenshot) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showPaymentProof(subscription),
                      icon: const Icon(Icons.image, size: 16),
                      label: const Text('View Proof'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xffB0A0D6),
                        side: const BorderSide(color: Color(0xffB0A0D6)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (mealPlanDetails != null) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showMealPlanDetails(subscription),
                      icon: const Icon(Icons.restaurant_menu, size: 16),
                      label: const Text('Meal Plan'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xffB0A0D6),
                        side: const BorderSide(color: Color(0xffB0A0D6)),
                      ),
                    ),
                  ),
                ],
                // For non-pending statuses, show View Details in top row
                if (status != 'pending' && !hasScreenshot && mealPlanDetails == null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showSubscriptionDetails(subscription),
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: const Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xffB0A0D6),
                        side: const BorderSide(color: Color(0xffB0A0D6)),
                      ),
                    ),
                  ),
              ],
            ),
            
            // Bottom row: Reject and Approve buttons (only for pending status)
            if (status == 'pending') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateSubscriptionStatus(subscriptionId, 'rejected'),
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateSubscriptionStatus(subscriptionId, 'approved'),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showMealPlanDetails(Map<String, dynamic> subscription) {
    final mealPlanDetails = subscription['mealPlanDetails'];
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xff352F44),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      '${mealPlanDetails['image'] ?? '🍗'} ',
                      style: const TextStyle(fontSize: 24),
                    ),
                    Expanded(
                      child: Text(
                        mealPlanDetails['meal_name'] ?? mealPlanDetails['name'] ?? 'AI Meal Plan',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Meal Description
                if (mealPlanDetails['description'] != null)
                  Text(
                    mealPlanDetails['description'],
                    style: const TextStyle(
                      color: Color(0xffB0A0D6),
                      fontSize: 14,
                    ),
                  ),
                
                // Show only the enhanced meal plan display
                const SizedBox(height: 16),
                _buildMealPlanReviewCard(mealPlanDetails),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPaymentProof(Map<String, dynamic> subscription) {
    final screenshotUrl = subscription['paymentScreenshotUrl'];
    
    if (screenshotUrl == null || screenshotUrl.toString().isEmpty) {
      _showMessage('No payment proof available', ContentType.warning);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xff352F44),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text(
                    'Payment Proof',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(
                  maxHeight: 400,
                  maxWidth: 300,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: screenshotUrl.toString().startsWith('data:image')
                    ? Image.memory(
                        Uri.parse(screenshotUrl).data!.contentAsBytes(),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: Text('Error loading image'),
                            ),
                          );
                        },
                      )
                    : Image.network(
                        screenshotUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: Text('Error loading image'),
                            ),
                          );
                        },
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubscriptionDetails(Map<String, dynamic> subscription) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xff352F44),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                      'Subscription Plan Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
                
                // Customer & Pet Information
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xff2A2438),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xff8476AA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '👤 Customer & Pet Info',
                        style: TextStyle(
                          color: Color(0xffB0A0D6),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
              _buildDetailRow('Pet Name', subscription['petName'] ?? 'N/A'),
              _buildDetailRow('User ID', subscription['userId'] ?? 'N/A'),
              _buildDetailRow('Dog Size', subscription['dogSize'] ?? 'N/A'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Subscription Details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xff2A2438),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xff8476AA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📋 Subscription Details',
                        style: TextStyle(
                          color: Color(0xffB0A0D6),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow('Delivery Frequency', subscription['frequency'] ?? 'N/A'),
                      _buildDetailRow('Monthly Price', '฿${(subscription['totalAmount']?.toDouble() ?? 0.0).toStringAsFixed(2)}'),
              _buildDetailRow('Status', subscription['status'] ?? 'N/A'),
                      _buildDetailRow('Created', _formatDate(subscription['createdAt'] ?? '')),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Meal Plan Section
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xff2A2438),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xff8476AA)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
              const Text(
                            '🍽️ AI-Generated Meal Plan',
                style: TextStyle(
                              color: Color(0xffB0A0D6),
                              fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              if (subscription['mealPlanDetails'] != null) ...[
                _buildMealPlanReviewCard(subscription['mealPlanDetails']),
              ] else if (subscription['selectedMealPlan'] != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                                color: const Color(0xff1F1A2E),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xff8476AA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meal Plan: ${subscription['selectedMealPlan']}',
                        style: const TextStyle(
                          color: Color(0xffB0A0D6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Simple meal plan - admin can approve for preparation',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                              ),
                              child: const Text(
                                'No meal plan details available',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                ),
                              ),
                            ),
              ],
            ],
                      ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Color(0xffB0A0D6),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateSubscriptionStatus(String subscriptionId, String newStatus) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      final subscriptionRef = FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(subscriptionId);
      
      final subscriptionDoc = await subscriptionRef.get();
      if (!subscriptionDoc.exists) {
        _showMessage('Subscription not found', ContentType.failure);
        return;
      }
      
      final subscriptionData = subscriptionDoc.data() as Map<String, dynamic>;
      
      batch.update(subscriptionRef, {
        'status': newStatus,
        'mealPlanStatus': newStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      final userId = subscriptionData['userId'];
      if (userId != null && userId.toString().isNotEmpty) {
        final userRef = FirebaseFirestore.instance
            .collection('UserData')
            .doc(userId);
        
        batch.update(userRef, {
          'subscriptionStatus': newStatus,
          'subscriptionDetails.status': newStatus,
        });
      }

      if (newStatus == 'approved') {
        await _createImmediateOrderFromSubscription(subscriptionData, subscriptionId, batch);
      }

      await batch.commit();

      final statusText = newStatus == 'approved' ? 'approved' : 'rejected';
      _showMessage(
        'Subscription successfully $statusText!${newStatus == 'approved' ? ' Order created for meal preparation.' : ''}',
        newStatus == 'approved' ? ContentType.success : ContentType.warning,
      );
    } catch (e) {
      _showMessage('Error updating subscription: $e', ContentType.failure);
    }
  }

  Future<void> _createImmediateOrderFromSubscription(
    Map<String, dynamic> subscriptionData, 
    String subscriptionId, 
    WriteBatch batch
  ) async {
    try {
      // Use the new subscription order service to create immediate order
      Map<String, dynamic> result = await SubscriptionOrderService.createImmediateOrderFromSubscription(
        subscriptionId,
        subscriptionData,
        DateTime.now(),
      );
      
      if (!result['success']) {
        throw Exception(result['message']);
      }
      
      print('Immediate order created with ID: ${result['orderId']} for subscription: $subscriptionId');
    } catch (e) {
      print('Error creating immediate order: $e');
      throw e;
    }
  }

  void _showMessage(String message, ContentType type) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: type == ContentType.success ? 'Success!' : 
               type == ContentType.failure ? 'Error!' : 'Notice',
        message: message,
        contentType: type,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildMealPlanReviewCard(Map<String, dynamic> mealPlanDetails) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xff2A2438),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xff8476AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal Header
          Row(
            children: [
              Text(
                '${mealPlanDetails['image'] ?? '🍗'} ',
                style: const TextStyle(fontSize: 20),
              ),
              Expanded(
                child: Text(
                  mealPlanDetails['meal_name'] ?? mealPlanDetails['name'] ?? 'AI Meal Plan',
                  style: const TextStyle(
                    color: Color(0xffB0A0D6),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (mealPlanDetails['total_price'] != null || mealPlanDetails['price'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '\$${(mealPlanDetails['total_price'] ?? mealPlanDetails['price'] ?? 0.0).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          
          if (mealPlanDetails['description'] != null) ...[
            const SizedBox(height: 8),
            Text(
              mealPlanDetails['description'],
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 14,
              ),
            ),
          ],
          
          // Enhanced JSON Ingredients (with quantities)
          if (mealPlanDetails['ingredients'] != null && 
              (mealPlanDetails['ingredients'] as List).isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '🥩 Ingredients & Quantities:',
              style: const TextStyle(
                color: Color(0xffB0A0D6),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            ..._buildIngredientsWithQuantities(mealPlanDetails['ingredients']),
          ],
          
          // Supplements & Vitamins
          if (mealPlanDetails['supplements_vitamins_minerals'] != null && 
              (mealPlanDetails['supplements_vitamins_minerals'] as List).isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '💊 Supplements & Vitamins:',
              style: const TextStyle(
                color: Color(0xffB0A0D6),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: (mealPlanDetails['supplements_vitamins_minerals'] as List)
                  .map<Widget>((supplement) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      supplement.toString(),
                      style: const TextStyle(
                        color: Colors.purple,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ))
                  .toList(),
            ),
          ],
          
          // Snacks & Treats
          if (mealPlanDetails['snacks_treats_special_diet'] != null && 
              (mealPlanDetails['snacks_treats_special_diet'] as List).isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '🍖 Snacks & Treats:',
              style: const TextStyle(
                color: Color(0xffB0A0D6),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: (mealPlanDetails['snacks_treats_special_diet'] as List)
                  .map<Widget>((snack) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      snack.toString(),
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ))
                  .toList(),
            ),
          ],
          
          // Legacy ingredients support (for old meal plans)
          if (mealPlanDetails['ingredients'] != null && 
              mealPlanDetails['ingredients'] is List &&
              (mealPlanDetails['ingredients'] as List).isNotEmpty &&
              !(mealPlanDetails['ingredients'] as List).first.toString().contains('amount_grams')) ...[
            const SizedBox(height: 8),
            Text(
              'Ingredients:',
              style: const TextStyle(
                color: Color(0xffB0A0D6),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: (mealPlanDetails['ingredients'] as List)
                  .map<Widget>((ingredient) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ingredient.toString(),
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 11,
                      ),
                    ),
                  ))
                  .toList(),
            ),
          ],
          
          // Legacy benefits support
          if (mealPlanDetails['benefits'] != null && 
              (mealPlanDetails['benefits'] as List).isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Benefits:',
              style: const TextStyle(
                color: Color(0xffB0A0D6),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: (mealPlanDetails['benefits'] as List)
                  .map<Widget>((benefit) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      benefit.toString(),
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 11,
                      ),
                    ),
                  ))
                  .toList(),
            ),
          ],
          
          // Subscription Plan Details (NEW)
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade400),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📋 Subscription Plan',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('Plan', mealPlanDetails['subscription_details']?['selected_plan'] ?? 'N/A'),
                _buildDetailRow('Frequency', mealPlanDetails['subscription_details']?['frequency'] ?? 'N/A'),
                _buildDetailRow('Dog Size', mealPlanDetails['subscription_details']?['dog_size'] ?? 'N/A'),
                _buildDetailRow('Portion Size', mealPlanDetails['subscription_details']?['portion_adjustment'] ?? 'N/A'),
                _buildDetailRow('Meals/Month', '${mealPlanDetails['subscription_details']?['meals_per_month'] ?? 'N/A'}'),
              ],
            ),
          ),
          
          // Price display (supports both total_price and price)
          if (mealPlanDetails['total_price'] != null || mealPlanDetails['price'] != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Meal Cost:',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '\$${(mealPlanDetails['total_price'] ?? mealPlanDetails['price']).toStringAsFixed(2)} per meal',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildIngredientsWithQuantities(List ingredients) {
    return ingredients.map<Widget>((ingredient) {
      if (ingredient is Map) {
        // New JSON format with quantities - show only name and amount, no calories
        String name = ingredient['name']?.toString() ?? 'Unknown';
        String amount = ingredient['amount_grams']?.toString() ?? '0';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Text(
            '$name - ${amount}g',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
        );
      } else {
        // Legacy format
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            ingredient.toString(),
            style: const TextStyle(
              color: Colors.green,
              fontSize: 11,
            ),
          ),
        );
      }
    }).toList();
  }
}