import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

class ColorsScheme {
  static const Color primaryBackgroundColor = Color(0xff2A2438);
  static const Color secondaryBackgroundColor = Color(0xff352F44);
  static const Color primaryTextColor = Color(0xffFFFFFF);
  static const Color secondaryTextColor = Color(0xffB0A0D6);
  static const Color primaryIconColor = Color(0xff8476AA);
}

class OrderReview extends StatefulWidget {
  const OrderReview({Key? key}) : super(key: key);

  @override
  _OrderReviewState createState() => _OrderReviewState();
}

class _OrderReviewState extends State<OrderReview> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStatusFilter = 'All';
  List<String> _statusFilters = ['All', 'pending', 'preparing', 'ready', 'delivered', 'failed'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsScheme.primaryBackgroundColor,
      appBar: AppBar(
        backgroundColor: ColorsScheme.primaryBackgroundColor,
        title: Text(
          'Order Management',
          style: TextStyle(
            color: ColorsScheme.primaryTextColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: ColorsScheme.primaryIconColor),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: ColorsScheme.primaryIconColor,
          unselectedLabelColor: ColorsScheme.secondaryTextColor,
          indicatorColor: ColorsScheme.primaryIconColor,
          tabs: const [
            Tab(text: 'Meal Orders'),
            Tab(text: 'Delivery Queue'),
            Tab(text: 'Analytics'),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: ColorsScheme.secondaryBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStatusFilter,
                style: TextStyle(color: ColorsScheme.primaryTextColor),
                dropdownColor: ColorsScheme.secondaryBackgroundColor,
                items: _statusFilters.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(
                      status,
                      style: TextStyle(
                        color: ColorsScheme.primaryTextColor,
                        fontSize: 14,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStatusFilter = value!;
                  });
                },
              ),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMealOrdersTab(),
          _buildDeliveryQueueTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildMealOrdersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getOrdersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 64,
                  color: ColorsScheme.secondaryTextColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'No meal orders found',
                  style: TextStyle(
                    color: ColorsScheme.secondaryTextColor,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            
            return _buildMealOrderCard(data, doc.id);
          },
        );
      },
    );
  }

  Widget _buildMealOrderCard(Map<String, dynamic> orderData, String orderId) {
    final status = orderData['status'] ?? 'pending';
    final petName = orderData['petName'] ?? 'Unknown Pet';
    final mealPlan = orderData['mealPlan'];
    final totalAmount = orderData['totalAmount']?.toDouble() ?? 0.0;
    final scheduledDate = orderData['scheduledDeliveryDate'] ?? '';
    final specialInstructions = orderData['specialInstructions'] ?? '';

    Color statusColor = _getStatusColor(status);
    IconData statusIcon = _getStatusIcon(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: ColorsScheme.secondaryBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status and order info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '\$${totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: ColorsScheme.primaryTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Pet and meal info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.pets, color: ColorsScheme.primaryIconColor, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Pet: $petName',
                            style: TextStyle(
                              color: ColorsScheme.primaryTextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (mealPlan != null && mealPlan is Map)
                        Row(
                          children: [
                            Text(
                              '${mealPlan['image'] ?? '🍗'} ',
                              style: const TextStyle(fontSize: 16),
                            ),
                            Expanded(
                              child: Text(
                                mealPlan['name'] ?? 'Custom Meal',
                                style: TextStyle(
                                  color: ColorsScheme.secondaryTextColor,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'Scheduled: ${_formatDate(scheduledDate)}',
                        style: TextStyle(
                          color: ColorsScheme.secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Special instructions
            if (specialInstructions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade300,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Special Instructions:',
                          style: TextStyle(
                            color: Colors.blue.shade300,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      specialInstructions,
                      style: TextStyle(
                        color: ColorsScheme.primaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Action buttons based on status
            _buildStatusActionButtons(orderData, orderId, status),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusActionButtons(Map<String, dynamic> orderData, String orderId, String status) {
    switch (status) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showOrderDetails(orderData),
                icon: const Icon(Icons.info_outline, size: 16),
                label: const Text('View Details'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorsScheme.secondaryTextColor,
                  side: BorderSide(color: ColorsScheme.secondaryTextColor),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _updateOrderStatus(orderId, 'preparing'),
                icon: const Icon(Icons.kitchen, size: 16),
                label: const Text('Start Preparing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );

      case 'preparing':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showOrderDetails(orderData),
                icon: const Icon(Icons.info_outline, size: 16),
                label: const Text('View Details'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorsScheme.secondaryTextColor,
                  side: BorderSide(color: ColorsScheme.secondaryTextColor),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _updateOrderStatus(orderId, 'ready'),
                icon: const Icon(Icons.check_circle, size: 16),
                label: const Text('Mark Ready'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );

      case 'ready':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showOrderDetails(orderData),
                icon: const Icon(Icons.info_outline, size: 16),
                label: const Text('View Details'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorsScheme.secondaryTextColor,
                  side: BorderSide(color: ColorsScheme.secondaryTextColor),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _openDeliveryLocation(orderData),
                icon: const Icon(Icons.location_on, size: 16),
                label: const Text('View Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );

      default:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showOrderDetails(orderData),
                icon: const Icon(Icons.info_outline, size: 16),
                label: const Text('View Details'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorsScheme.secondaryTextColor,
                  side: BorderSide(color: ColorsScheme.secondaryTextColor),
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildDeliveryQueueTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'ready')
          .orderBy('readyForDeliveryAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_shipping,
                  size: 64,
                  color: ColorsScheme.secondaryTextColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'No orders ready for delivery',
                  style: TextStyle(
                    color: ColorsScheme.secondaryTextColor,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            
            return _buildDeliveryCard(data, doc.id);
          },
        );
      },
    );
  }

  Widget _buildDeliveryCard(Map<String, dynamic> orderData, String orderId) {
    final petName = orderData['petName'] ?? 'Unknown Pet';
    final deliveryAddress = orderData['deliveryAddress'] ?? 'Address not provided';
    final deliveryCity = orderData['deliveryCity'] ?? '';
    final scheduledDate = orderData['scheduledDeliveryDate'] ?? '';
    final mealPlan = orderData['mealPlan'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: ColorsScheme.secondaryBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pets, color: ColorsScheme.primaryIconColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    petName,
                    style: TextStyle(
                      color: ColorsScheme.primaryTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'READY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (mealPlan != null && mealPlan is Map)
              Row(
                children: [
                  Text(
                    '${mealPlan['image'] ?? '🍗'} ',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    mealPlan['name'] ?? 'Custom Meal',
                    style: TextStyle(
                      color: ColorsScheme.secondaryTextColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),

            Row(
              children: [
                Icon(Icons.location_on, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$deliveryAddress${deliveryCity.isNotEmpty ? ', $deliveryCity' : ''}',
                    style: TextStyle(
                      color: ColorsScheme.secondaryTextColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Icon(Icons.schedule, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Scheduled: ${_formatDate(scheduledDate)}',
                  style: TextStyle(
                    color: ColorsScheme.secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openDeliveryLocation(orderData),
                    icon: const Icon(Icons.location_on, size: 16),
                    label: const Text('Open Location'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _markAsDispatched(orderId),
                    icon: const Icon(Icons.local_shipping, size: 16),
                    label: const Text('Dispatch'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics,
            size: 64,
            color: ColorsScheme.secondaryTextColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Analytics Coming Soon',
            style: TextStyle(
              color: ColorsScheme.secondaryTextColor,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getOrdersStream() {
    Query query = FirebaseFirestore.instance.collection('orders');
    
    if (_selectedStatusFilter != 'All') {
      query = query.where('status', isEqualTo: _selectedStatusFilter);
    }
    
    return query.orderBy('createdAt', descending: true).snapshots();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'preparing':
        return Colors.blue;
      case 'ready':
        return Colors.green;
      case 'delivered':
        return Colors.teal;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending_actions;
      case 'preparing':
        return Icons.kitchen;
      case 'ready':
        return Icons.check_circle;
      case 'delivered':
        return Icons.local_shipping;
      case 'failed':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  void _showOrderDetails(Map<String, dynamic> orderData) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: ColorsScheme.secondaryBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Order Details',
                    style: TextStyle(
                      color: ColorsScheme.primaryTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: ColorsScheme.primaryTextColor),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildDetailRow('Pet Name', orderData['petName'] ?? 'N/A'),
              _buildDetailRow('Dog Name', orderData['dogName'] ?? orderData['petName'] ?? 'N/A'),
              _buildDetailRow('Order ID', orderData['orderId'] ?? 'N/A'),
              _buildDetailRow('Status', orderData['status'] ?? 'N/A'),
              _buildDetailRow('Dog Size', orderData['dogSize'] ?? 'N/A'),
              _buildDetailRow('Frequency', orderData['frequency'] ?? 'N/A'),
              _buildDetailRow('Total Amount', '\$${(orderData['totalAmount']?.toDouble() ?? 0.0).toStringAsFixed(2)}'),
              _buildDetailRow('Scheduled Delivery', _formatDate(orderData['scheduledDeliveryDate'] ?? '')),
              
              if (orderData['specialInstructions'] != null && orderData['specialInstructions'].toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildDetailRow('Special Instructions', orderData['specialInstructions']),
              ],
              
              // Show meal plan details if available
              if (orderData['mealPlan'] != null && orderData['mealPlan'] is Map) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Meal Plan Details:',
                  style: TextStyle(
                    color: ColorsScheme.primaryTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildMealPlanDetailsCard(orderData['mealPlan']),
              ],
            ],
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
              style: TextStyle(
                color: ColorsScheme.secondaryTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: ColorsScheme.primaryTextColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealPlanDetailsCard(Map<String, dynamic> mealPlan) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorsScheme.primaryBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColorsScheme.primaryIconColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal Header
          Row(
            children: [
              Text(
                '${mealPlan['image'] ?? '🍗'} ',
                style: const TextStyle(fontSize: 20),
              ),
              Expanded(
                child: Text(
                  mealPlan['meal_name'] ?? mealPlan['name'] ?? 'Custom Meal',
                  style: TextStyle(
                    color: ColorsScheme.primaryTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (mealPlan['calories'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${mealPlan['calories']} cal',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          
          if (mealPlan['description'] != null) ...[
            const SizedBox(height: 8),
            Text(
              mealPlan['description'],
              style: TextStyle(
                color: ColorsScheme.secondaryTextColor,
                fontSize: 14,
              ),
            ),
          ],
          
          // Enhanced JSON Ingredients (with quantities)
          if (mealPlan['ingredients'] != null && 
              (mealPlan['ingredients'] as List).isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '🥩 Ingredients & Quantities:',
              style: TextStyle(
                color: ColorsScheme.primaryTextColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            ..._buildIngredientsWithQuantities(mealPlan['ingredients']),
          ],
          
          // Supplements & Vitamins
          if (mealPlan['supplements_vitamins_minerals'] != null && 
              (mealPlan['supplements_vitamins_minerals'] as List).isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '💊 Supplements & Vitamins:',
              style: TextStyle(
                color: ColorsScheme.primaryTextColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: (mealPlan['supplements_vitamins_minerals'] as List)
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
          if (mealPlan['snacks_treats_special_diet'] != null && 
              (mealPlan['snacks_treats_special_diet'] as List).isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '🍖 Snacks & Treats:',
              style: TextStyle(
                color: ColorsScheme.primaryTextColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: (mealPlan['snacks_treats_special_diet'] as List)
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
          
          // 🍳 COOKING INSTRUCTIONS - KEY FEATURE FOR KITCHEN STAFF!
          if (mealPlan['preparation_instructions'] != null && 
              mealPlan['preparation_instructions'].toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        color: Colors.red.shade300,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '👨‍🍳 Kitchen Preparation Instructions',
                        style: TextStyle(
                          color: Colors.red.shade300,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mealPlan['preparation_instructions'].toString(),
                    style: TextStyle(
                      color: Colors.red.shade200,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Price display (supports both total_price and price)
          if (mealPlan['total_price'] != null || mealPlan['price'] != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Meal Cost:',
                  style: TextStyle(
                    color: ColorsScheme.secondaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '\$${(mealPlan['total_price'] ?? mealPlan['price']).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
          
          // Kitchen status indicator
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.kitchen,
                  color: Colors.orange.shade300,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ready for kitchen preparation. Follow the cooking instructions above for best results.',
                    style: TextStyle(
                      color: Colors.orange.shade300,
                      fontSize: 11,
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

  List<Widget> _buildIngredientsWithQuantities(List ingredients) {
    return ingredients.map<Widget>((ingredient) {
      if (ingredient is Map) {
        // New JSON format with quantities
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${amount}g',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
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

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'Not specified';
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      Map<String, dynamic> updateData = {
        'status': newStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Add specific timestamps based on status
      switch (newStatus) {
        case 'preparing':
          updateData['preparationStartedAt'] = DateTime.now().toIso8601String();
          break;
        case 'ready':
          updateData['preparationCompletedAt'] = DateTime.now().toIso8601String();
          updateData['readyForDeliveryAt'] = DateTime.now().toIso8601String();
          break;
        case 'delivered':
          updateData['deliveredAt'] = DateTime.now().toIso8601String();
          updateData['actualDeliveryDate'] = DateTime.now().toIso8601String();
          break;
      }

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update(updateData);

      _showMessage(
        'Order status updated to ${newStatus.toUpperCase()}!',
        ContentType.success,
      );
    } catch (e) {
      _showMessage('Error updating order status: $e', ContentType.failure);
    }
  }

  Future<void> _openDeliveryLocation(Map<String, dynamic> orderData) async {
    // First try to get location from delivery data
    final deliveryLatitude = orderData['deliveryLatitude']?.toDouble();
    final deliveryLongitude = orderData['deliveryLongitude']?.toDouble();
    
    if (deliveryLatitude != null && deliveryLongitude != null && 
        deliveryLatitude != 0.0 && deliveryLongitude != 0.0) {
      _showMessage(
        'Location: $deliveryLatitude, $deliveryLongitude\n(Map integration coming soon)',
        ContentType.help,
      );
      return;
    }
    
    // If no direct delivery location, try to fetch from dog profile using dogName
    final dogName = orderData['dogName'] ?? orderData['petName'];
    final userId = orderData['userId'];
    
    if (dogName != null && userId != null) {
      try {
        // Try to find the dog profile in the user's pet collection
        final userDoc = await FirebaseFirestore.instance
            .collection('UserData')
            .doc(userId)
            .get();
            
        if (userDoc.exists) {
          // Search through user's pets to find the matching dog
          
          // Try to get pet data from subcollection or direct reference
          final petsQuery = await FirebaseFirestore.instance
              .collection(userId) // User's pet collection
              .where('Name', isEqualTo: dogName)
              .limit(1)
              .get();
              
          if (petsQuery.docs.isNotEmpty) {
            final petData = petsQuery.docs.first.data();
            final petLat = petData['LAT']?.toDouble();
            final petLong = petData['LONG']?.toDouble();
            
            if (petLat != null && petLong != null) {
              // Update the order with the pet's location for future reference
              await FirebaseFirestore.instance
                  .collection('orders')
                  .doc(orderData['orderId'])
                  .update({
                'deliveryLatitude': petLat,
                'deliveryLongitude': petLong,
                'deliveryAddress': '${petData['location'] ?? 'Pet Location'}',
                'deliveryCity': '${petData['city'] ?? ''}',
              });
              
              _showMessage(
                'Pet Location Found: $petLat, $petLong\n(Saved for future deliveries)',
                ContentType.success,
              );
              return;
            }
          }
        }
        
        _showMessage(
          'Could not locate pet "$dogName" coordinates. Please verify pet profile has location data.',
          ContentType.warning,
        );
        
      } catch (e) {
        _showMessage(
          'Error fetching pet location: $e',
          ContentType.failure,
        );
      }
    } else {
      _showMessage('No location coordinates available', ContentType.warning);
    }
  }

  Future<void> _markAsDispatched(String orderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'dispatchedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      _showMessage('Order marked as dispatched!', ContentType.success);
    } catch (e) {
      _showMessage('Error marking as dispatched: $e', ContentType.failure);
    }
  }

  void _showMessage(String message, ContentType type) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: type == ContentType.success ? 'Success!' : 
               type == ContentType.failure ? 'Error!' : 
               type == ContentType.help ? 'Info' : 'Notice',
        message: message,
        contentType: type,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
