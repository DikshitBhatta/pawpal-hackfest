import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pet_care/services/subscription_order_service.dart';
import 'package:geocoding/geocoding.dart';

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
  late TabController _historyTabController;
  String _selectedStatusFilter = 'All';
  List<String> _statusFilters = ['All', 'pending', 'preparing'];
  
  // Cache for resolved addresses to avoid repeated API calls
  Map<String, String> _addressCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _historyTabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsScheme.primaryBackgroundColor,
      appBar: AppBar(
        backgroundColor: ColorsScheme.primaryBackgroundColor,
        title: Text(
          'Order Review',
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
            Tab(text: 'Orders'),
            Tab(text: 'History'),
            Tab(text: 'Analytics'),
            Tab(text: 'Revenue'),
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
          _buildOrdersTab(),
          _buildHistoryTab(),
          _buildAnalyticsTab(),
          _buildRevenueTab(),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getOrdersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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
                  'No orders found',
                  style: TextStyle(
                    color: ColorsScheme.secondaryTextColor,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          );
        }
        
        // Sort orders by priority and due date/timing
        final sortedDocs = snapshot.data!.docs.toList();
        
        // Sort by priority and due date for display (no need for order number calculation)
        sortedDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          
          // First sort by priority (urgent > critical > normal)
          final aPriority = aData['priority']?.toString() ?? 'normal';
          final bPriority = bData['priority']?.toString() ?? 'normal';
          
          int priorityComparison = _comparePriority(aPriority, bPriority);
          if (priorityComparison != 0) return priorityComparison;
          
          // Then sort by due date/timing
          final aDueDate = aData['dueDate']?.toString() ?? '';
          final bDueDate = bData['dueDate']?.toString() ?? '';
          
          // Urgent orders (no due date) come first
          if (aDueDate.isEmpty && bDueDate.isNotEmpty) return -1;
          if (bDueDate.isEmpty && aDueDate.isNotEmpty) return 1;
          if (aDueDate.isEmpty && bDueDate.isEmpty) {
            // Both urgent, sort by creation time (newest first)
            final aTime = aData['createdAt']?.toString() ?? '';
            final bTime = bData['createdAt']?.toString() ?? '';
            return bTime.compareTo(aTime);
          }
          
          // Both have due dates, sort by due date (earliest first)
          return aDueDate.compareTo(bDueDate);
        });
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedDocs.length,
          itemBuilder: (context, index) {
            final doc = sortedDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: ColorsScheme.secondaryBackgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getPriorityColor(data['priority'] ?? 'normal').withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.all(16),
                childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row with order number and status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Order number with counter (from stored orderNumber field)
                        Text(
                          'Order #${(data['orderNumber'] ?? 0).toString().padLeft(3, '0')}',
                          style: TextStyle(
                            color: ColorsScheme.primaryTextColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Status indicator in top right
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(data['status'] ?? 'Pending'),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            (data['status'] ?? 'Pending').toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Priority flag bar
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(data['priority'] ?? 'normal').withOpacity(0.15),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: _getPriorityColor(data['priority'] ?? 'normal').withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getPriorityIcon(data['priority'] ?? 'normal'),
                            color: _getPriorityColor(data['priority'] ?? 'normal'),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getPriorityText(data['priority'] ?? 'normal'),
                            style: TextStyle(
                              color: _getPriorityColor(data['priority'] ?? 'normal'),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (data['priority'] == 'urgent') ...[
                            const SizedBox(width: 8),
                            Text(
                              '• No due date',
                              style: TextStyle(
                                color: _getPriorityColor(data['priority'] ?? 'normal'),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                          if (data['dueDate'] != null && data['dueDate'].toString().isNotEmpty && data['priority'] != 'urgent') ...[
                            const SizedBox(width: 8),
                            Text(
                              '• Due: ${_formatDateShort(data['dueDate'])}',
                              style: TextStyle(
                                color: _getPriorityColor(data['priority'] ?? 'normal'),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                subtitle: Container(
                  margin: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer and Pet info row
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  color: ColorsScheme.secondaryTextColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    data['customerName'] ?? 'Unknown',
                                    style: TextStyle(
                                      color: ColorsScheme.secondaryTextColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.pets,
                                  color: ColorsScheme.secondaryTextColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    data['petName'] ?? data['dogName'] ?? 'Unknown Pet',
                                    style: TextStyle(
                                      color: ColorsScheme.secondaryTextColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Amount and Date row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.attach_money,
                                color: ColorsScheme.primaryIconColor,
                                size: 18,
                              ),
                              Text(
                                '฿${(data['totalAmount'] ?? 0.0).toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: ColorsScheme.primaryIconColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: ColorsScheme.secondaryTextColor,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                data['dueDate'] != null && data['dueDate'].toString().isNotEmpty 
                                    ? 'Due: ${_formatDateShort(data['dueDate'])}'
                                    : 'Added: ${_formatDateShort(data['createdAt'] ?? data['orderDate'])}',
                                style: TextStyle(
                                  color: ColorsScheme.secondaryTextColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                iconColor: ColorsScheme.primaryIconColor,
                collapsedIconColor: ColorsScheme.primaryIconColor,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Details:',
                          style: TextStyle(
                            color: ColorsScheme.primaryTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Handle subscription meal orders
                        if (data['orderType'] == 'subscription_meal') ...[
                          _buildMealOrderDetails(data),
                        ] else ...[
                          // Handle traditional orders with items
                          ...((data['items'] as List?) ?? []).map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item['name']} x${item['quantity']}',
                                      style: TextStyle(
                                        color: ColorsScheme.secondaryTextColor,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '฿${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: ColorsScheme.secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                        
                        const Divider(),
                        
                        // Special instructions for subscription meals
                        if (data['specialInstructions'] != null && data['specialInstructions'].toString().isNotEmpty) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
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
                                  data['specialInstructions'],
                                  style: TextStyle(
                                    color: ColorsScheme.primaryTextColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Delivery Address:',
                                style: TextStyle(
                                  color: ColorsScheme.primaryTextColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        _buildDeliveryAddressWidget(data),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (data['status'] == 'pending')
                              _buildActionButton(
                                'Start Preparing',
                                Colors.orange,
                                () => _updateOrderStatus(doc.id, 'preparing'),
                              ),
                            if (data['status'] == 'preparing')
                              _buildActionButton(
                                'Mark Ready',
                                Colors.green,
                                () => _updateOrderStatus(doc.id, 'ready'),
                              ),
                            if (data['status'] != 'cancelled' && data['status'] != 'ready')
                              _buildActionButton(
                                'Cancel',
                                Colors.red,
                                () => _updateOrderStatus(doc.id, 'cancelled'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return Scaffold(
      backgroundColor: ColorsScheme.primaryBackgroundColor,
      appBar: AppBar(
        backgroundColor: ColorsScheme.primaryBackgroundColor,
        automaticallyImplyLeading: false,
        elevation: 0,
        bottom: TabBar(
          controller: _historyTabController,
          labelColor: ColorsScheme.primaryIconColor,
          unselectedLabelColor: ColorsScheme.secondaryTextColor,
          indicatorColor: ColorsScheme.primaryIconColor,
          tabs: const [
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _historyTabController,
        children: [
          _buildCompletedOrdersTab(),
          _buildCancelledOrdersTab(),
        ],
      ),
    );
  }

  Widget _buildCompletedOrdersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', whereIn: ['ready', 'on_way', 'on_mid_way', 'delivered'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: ColorsScheme.secondaryTextColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'No completed orders found',
                  style: TextStyle(
                    color: ColorsScheme.secondaryTextColor,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          );
        }
        
        // Sort completed orders by creation time on client side (newest first)
        final sortedDocs = snapshot.data!.docs.toList();
          sortedDocs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['createdAt']?.toString() ?? '';
            final bTime = bData['createdAt']?.toString() ?? '';
            return bTime.compareTo(aTime); // Descending order (newest first)
          });
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedDocs.length,
          itemBuilder: (context, index) {
            final doc = sortedDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            
            return _buildHistoryOrderCard(doc, data);
          },
        );
      },
    );
  }

  Widget _buildCancelledOrdersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'cancelled')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cancel_outlined,
                  size: 64,
                  color: ColorsScheme.secondaryTextColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'No cancelled orders found',
                  style: TextStyle(
                    color: ColorsScheme.secondaryTextColor,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          );
        }
        
        // Sort cancelled orders by creation time on client side (newest first)
        final sortedDocs = snapshot.data!.docs.toList();
        sortedDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['createdAt']?.toString() ?? '';
          final bTime = bData['createdAt']?.toString() ?? '';
          return bTime.compareTo(aTime); // Descending order (newest first)
        });
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedDocs.length,
          itemBuilder: (context, index) {
            final doc = sortedDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            
            return _buildHistoryOrderCard(doc, data);
          },
        );
      },
    );
  }

  Widget _buildHistoryOrderCard(QueryDocumentSnapshot doc, Map<String, dynamic> data) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: ColorsScheme.secondaryBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getStatusColor(data['status'] ?? 'Pending').withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: ExpansionTile(
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(data['status'] ?? 'Pending'),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        data['status'] ?? 'Pending',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                'Order #${(data['orderNumber'] ?? doc.id.substring(0, 8)).toString().padLeft(3, '0')}',
                        style: TextStyle(
                          color: ColorsScheme.primaryTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
              '฿${(data['totalAmount'] ?? 0.0).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: ColorsScheme.primaryIconColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'Customer: ${data['customerName'] ?? 'Unknown'}',
                      style: TextStyle(
                        color: ColorsScheme.secondaryTextColor,
                      ),
                    ),
                    Text(
                      'Pet: ${data['petName'] ?? data['dogName'] ?? 'Unknown Pet'}',
                      style: TextStyle(
                        color: ColorsScheme.secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                    Text(
              data['dueDate'] != null && data['dueDate'].toString().isNotEmpty 
                  ? 'Due: ${_formatDate(data['dueDate'])}'
                  : 'Added: ${_formatDate(data['createdAt'] ?? data['orderDate'])}',
                      style: TextStyle(
                        color: ColorsScheme.secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                    if (data['dogSize'] != null || data['frequency'] != null)
                      Text(
                        '${data['dogSize'] ?? ''} Dog - ${data['frequency'] ?? ''}',
                        style: TextStyle(
                          color: ColorsScheme.secondaryTextColor,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
                iconColor: ColorsScheme.primaryIconColor,
                collapsedIconColor: ColorsScheme.primaryIconColor,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Details:',
                          style: TextStyle(
                            color: ColorsScheme.primaryTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Handle subscription meal orders
                        if (data['orderType'] == 'subscription_meal') ...[
                          _buildMealOrderDetails(data),
                        ] else ...[
                          // Handle traditional orders with items
                          ...((data['items'] as List?) ?? []).map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item['name']} x${item['quantity']}',
                                      style: TextStyle(
                                        color: ColorsScheme.secondaryTextColor,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '\$${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: ColorsScheme.secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                        
                        const Divider(),
                        
                        // Special instructions for subscription meals
                        if (data['specialInstructions'] != null && data['specialInstructions'].toString().isNotEmpty) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
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
                                  data['specialInstructions'],
                                  style: TextStyle(
                                    color: ColorsScheme.primaryTextColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Delivery Address:',
                                style: TextStyle(
                                  color: ColorsScheme.primaryTextColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                SizedBox(height: 8),
                _buildDeliveryAddressWidget(data),
                
                // Show completion/delivery timestamp
                if (['ready', 'on_way', 'on_mid_way', 'delivered'].contains(data['status'])) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          data['status'] == 'delivered' ? Icons.local_shipping :
                          ['on_way', 'on_mid_way'].contains(data['status']) ? Icons.directions :
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          data['status'] == 'delivered' 
                              ? 'Delivered: ${_formatDate(data['deliveredAt'] ?? data['preparationCompletedAt'])}'
                              : data['status'] == 'on_way'
                                  ? 'Out for delivery: ${_formatDate(data['dispatchedAt'] ?? data['preparationCompletedAt'])}'
                                  : data['status'] == 'on_mid_way'
                                      ? 'Mid way: ${_formatDate(data['midWayAt'] ?? data['preparationCompletedAt'])}'
                                      : 'Ready: ${_formatDate(data['preparationCompletedAt'])}',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                if (data['status'] == 'cancelled' && data['updatedAt'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                          children: [
                        Icon(
                          Icons.cancel,
                          color: Colors.red,
                          size: 16,
                              ),
                        const SizedBox(width: 8),
                        Text(
                          'Cancelled: ${_formatDate(data['updatedAt'])}',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                              ),
                          ],
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

  Widget _buildAnalyticsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final orders = snapshot.data?.docs ?? [];
        final analytics = _calculateAnalytics(orders);
        
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildAnalyticsCard('Total Orders', analytics['totalOrders'].toString(), Icons.receipt_long),
            const SizedBox(height: 12),
            _buildAnalyticsCard('Pending Orders', analytics['pendingOrders'].toString(), Icons.pending_actions),
            const SizedBox(height: 12),
            _buildAnalyticsCard('Completed Orders', analytics['completedOrders'].toString(), Icons.check_circle),
            const SizedBox(height: 12),
            _buildAnalyticsCard('Average Order Value', '\$${analytics['averageOrderValue'].toStringAsFixed(2)}', Icons.attach_money),
            const SizedBox(height: 12),
            _buildAnalyticsCard('Today\'s Orders', analytics['todayOrders'].toString(), Icons.today),
            const SizedBox(height: 20),
            Text(
              'Order Status Breakdown',
              style: TextStyle(
                color: ColorsScheme.primaryTextColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._statusFilters.where((status) => status != 'All').map((status) {
              final count = analytics['statusCounts'][status] ?? 0;
              final percentage = analytics['totalOrders'] > 0 
                  ? (count / analytics['totalOrders'] * 100).toStringAsFixed(1)
                  : '0.0';
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorsScheme.secondaryBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        status,
                        style: TextStyle(
                          color: ColorsScheme.primaryTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '$count ($percentage%)',
                      style: TextStyle(
                        color: ColorsScheme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildRevenueTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', whereIn: ['ready', 'on_way', 'on_mid_way', 'delivered'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final orders = snapshot.data?.docs ?? [];
        final revenue = _calculateRevenue(orders);
        
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildRevenueCard('Total Revenue', '\$${revenue['totalRevenue'].toStringAsFixed(2)}', Icons.account_balance_wallet, Colors.green),
            const SizedBox(height: 12),
            _buildRevenueCard('This Month', '\$${revenue['monthlyRevenue'].toStringAsFixed(2)}', Icons.calendar_month, Colors.blue),
            const SizedBox(height: 12),
            _buildRevenueCard('This Week', '\$${revenue['weeklyRevenue'].toStringAsFixed(2)}', Icons.date_range, Colors.orange),
            const SizedBox(height: 12),
            _buildRevenueCard('Today', '\$${revenue['dailyRevenue'].toStringAsFixed(2)}', Icons.today, Colors.purple),
            const SizedBox(height: 20),
            Text(
              'Revenue Breakdown',
              style: TextStyle(
                color: ColorsScheme.primaryTextColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorsScheme.secondaryBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildRevenueRow('Number of Ready Orders', revenue['readyOrders'].toString()),
                  _buildRevenueRow('Average Order Value', '\$${revenue['avgOrderValue'].toStringAsFixed(2)}'),
                  _buildRevenueRow('Highest Order', '\$${revenue['highestOrder'].toStringAsFixed(2)}'),
                  _buildRevenueRow('Lowest Order', '\$${revenue['lowestOrder'].toStringAsFixed(2)}'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildMealOrderDetails(Map<String, dynamic> orderData) {
    final mealPlan = orderData['mealPlan'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Meal Plan Info
        if (mealPlan != null && mealPlan is Map) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${mealPlan['image'] ?? '🍗'} ',
                      style: const TextStyle(fontSize: 18),
                    ),
                    Expanded(
                      child: Text(
                        mealPlan['name'] ?? 'Custom Meal Plan',
                        style: TextStyle(
                          color: ColorsScheme.primaryTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
                      fontSize: 12,
                    ),
                  ),
                ],
                
                // Ingredients with quantities
                if (mealPlan['ingredients'] != null && (mealPlan['ingredients'] as List).isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    '🥘 Ingredients & Quantities:',
                    style: TextStyle(
                      color: ColorsScheme.primaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...((mealPlan['ingredients'] as List).map((ingredient) {
                    if (ingredient is Map) {
                      String name = ingredient['name']?.toString() ?? 'Unknown';
                      String amount = ingredient['amount_grams']?.toString() ?? '0';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '• $name - ${amount}g',
                              style: TextStyle(
                                color: ColorsScheme.primaryTextColor,
                                fontSize: 12,
                              ),
                            ),
                      );
                    } else {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '• ${ingredient.toString()}',
                          style: TextStyle(
                            color: ColorsScheme.primaryTextColor,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }
                  }).toList()),
                ],
                
                // Cooking Instructions
                if (mealPlan['preparation_instructions'] != null && mealPlan['preparation_instructions'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _showCookingInstructionsDialog(context, mealPlan['preparation_instructions']),
                    child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.restaurant,
                              color: Colors.orange.shade300,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '🍳 Cooking Instructions:',
                              style: TextStyle(
                                color: Colors.orange.shade300,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                              const Spacer(),
                              Icon(
                                Icons.zoom_in,
                                color: Colors.orange.shade300,
                                size: 16,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mealPlan['preparation_instructions'],
                          style: TextStyle(
                            color: ColorsScheme.primaryTextColor,
                            fontSize: 11,
                          ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  ),
                ],
                
                // Price info
                if (mealPlan['total_price'] != null || mealPlan['price'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Spacer(),
                      Text(
                        'Meal Price: \$${((mealPlan['total_price'] ?? mealPlan['price']) ?? 0.0).toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.green.shade300,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
        ] else ...[
          // Fallback for orders without detailed meal plan
          Text(
            'Subscription meal order - Total: \$${(orderData['totalAmount'] ?? 0.0).toStringAsFixed(2)}',
            style: TextStyle(
              color: ColorsScheme.secondaryTextColor,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsScheme.secondaryBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorsScheme.primaryIconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: ColorsScheme.primaryIconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: ColorsScheme.secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: ColorsScheme.primaryTextColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsScheme.secondaryBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: ColorsScheme.secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: ColorsScheme.primaryTextColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: ColorsScheme.secondaryTextColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: ColorsScheme.primaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getOrdersStream() {
    if (_selectedStatusFilter == 'All') {
      // Remove orderBy to avoid index requirement for whereIn query
      return FirebaseFirestore.instance
          .collection('orders')
          .where('status', whereIn: ['pending', 'preparing'])
          .snapshots();
    } else if (_selectedStatusFilter == 'pending' || _selectedStatusFilter == 'preparing') {
      // Remove orderBy to avoid index requirement
      return FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: _selectedStatusFilter)
          .snapshots();
    } else {
      // For other statuses, return empty stream since they are handled in History
      return const Stream.empty();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'preparing':
        return Colors.purple;
      case 'ready':
        return Colors.green;
      case 'on_way':
        return Colors.blue;
      case 'on_mid_way':
        return Colors.amber;
      case 'delivered':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Priority comparison helper
  int _comparePriority(String priority1, String priority2) {
    const Map<String, int> priorityOrder = {
      'urgent': 0,
      'critical': 1,
      'normal': 2,
    };
    
    int p1 = priorityOrder[priority1] ?? 2;
    int p2 = priorityOrder[priority2] ?? 2;
    
    return p1.compareTo(p2);
  }

  // Priority color helper
  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'critical':
        return Colors.orange;
      case 'normal':
      default:
        return Colors.blue;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    
    try {
      DateTime dateTime;
      if (date is Timestamp) {
        dateTime = date.toDate();
      } else if (date is String) {
        dateTime = DateTime.parse(date);
      } else {
        return date.toString();
      }
      
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return date.toString();
    }
  }

  Map<String, dynamic> _calculateAnalytics(List<QueryDocumentSnapshot> orders) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    int totalOrders = orders.length;
    int pendingOrders = 0;
    int completedOrders = 0;
    int todayOrders = 0;
    double totalAmount = 0;
    Map<String, int> statusCounts = {};
    
    for (var doc in orders) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] ?? 'pending';
      final amount = (data['totalAmount'] ?? 0.0).toDouble();
      final orderDate = data['orderDate'] ?? data['createdAt'];
      
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      totalAmount += amount;
      
      if (status == 'pending') pendingOrders++;
      if (['ready', 'on_way', 'on_mid_way', 'delivered'].contains(status)) completedOrders++;
      
      if (orderDate != null) {
        DateTime? orderDateTime;
        if (orderDate is Timestamp) {
          orderDateTime = orderDate.toDate();
        } else if (orderDate is String) {
          try {
            orderDateTime = DateTime.parse(orderDate);
          } catch (e) {
            // Handle parsing error
          }
        }
        
        if (orderDateTime != null && orderDateTime.isAfter(today)) {
          todayOrders++;
        }
      }
    }
    
    return {
      'totalOrders': totalOrders,
      'pendingOrders': pendingOrders,
      'completedOrders': completedOrders,
      'todayOrders': todayOrders,
      'averageOrderValue': totalOrders > 0 ? totalAmount / totalOrders : 0.0,
      'statusCounts': statusCounts,
    };
  }

  Map<String, dynamic> _calculateRevenue(List<QueryDocumentSnapshot> orders) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeek = today.subtract(Duration(days: now.weekday - 1));
    final thisMonth = DateTime(now.year, now.month, 1);
    
    double totalRevenue = 0;
    double dailyRevenue = 0;
    double weeklyRevenue = 0;
    double monthlyRevenue = 0;
    double highestOrder = 0;
    double lowestOrder = double.infinity;
    
    for (var doc in orders) {
      final data = doc.data() as Map<String, dynamic>;
      final amount = (data['totalAmount'] ?? 0.0).toDouble();
      final orderDate = data['orderDate'] ?? data['createdAt'];
      
      totalRevenue += amount;
      if (amount > highestOrder) highestOrder = amount;
      if (amount < lowestOrder) lowestOrder = amount;
      
      if (orderDate != null) {
        DateTime? orderDateTime;
        if (orderDate is Timestamp) {
          orderDateTime = orderDate.toDate();
        } else if (orderDate is String) {
          try {
            orderDateTime = DateTime.parse(orderDate);
          } catch (e) {
            // Handle parsing error
          }
        }
        
        if (orderDateTime != null) {
          if (orderDateTime.isAfter(today)) {
            dailyRevenue += amount;
          }
          if (orderDateTime.isAfter(thisWeek)) {
            weeklyRevenue += amount;
          }
          if (orderDateTime.isAfter(thisMonth)) {
            monthlyRevenue += amount;
          }
        }
      }
    }
    
    if (lowestOrder == double.infinity) lowestOrder = 0;
    
    return {
      'totalRevenue': totalRevenue,
      'dailyRevenue': dailyRevenue,
      'weeklyRevenue': weeklyRevenue,
      'monthlyRevenue': monthlyRevenue,
      'readyOrders': orders.length,
      'avgOrderValue': orders.isNotEmpty ? totalRevenue / orders.length : 0.0,
      'highestOrder': highestOrder,
      'lowestOrder': lowestOrder,
    };
  }

  void _updateOrderStatus(String orderId, String newStatus) async {
    try {
      Map<String, dynamic> updateData = {
        'status': newStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Add specific timestamps based on status
      switch (newStatus) {
        case 'preparing':
          updateData['preparationStartedAt'] = DateTime.now().toIso8601String();
          // Lock meal for editing when preparation starts
          await SubscriptionOrderService.lockMealForPreparation(orderId);
          break;
        case 'ready':
          updateData['preparationCompletedAt'] = DateTime.now().toIso8601String();
          updateData['readyForDeliveryAt'] = DateTime.now().toIso8601String();
          // When meal is ready, it automatically moves to Delivery Management queue
          // OrderReview stops tracking the order at 'ready' status
          break;
      }

      await FirebaseFirestore.instance.collection('orders').doc(orderId).update(updateData);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order status updated to ${newStatus.toUpperCase()}!',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating order status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // New helper methods for enhanced card design
  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Icons.warning;
      case 'critical':
        return Icons.priority_high;
      case 'normal':
      default:
        return Icons.check_circle_outline;
    }
  }

  String _getPriorityText(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return 'URGENT';
      case 'critical':
        return 'CRITICAL';
      case 'normal':
      default:
        return 'NORMAL';
    }
  }

  void _showCookingInstructionsDialog(BuildContext context, String instructions) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(
              maxWidth: 400,
              maxHeight: 600,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      color: ColorsScheme.primaryIconColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '🍳 Cooking Instructions',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: ColorsScheme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: ColorsScheme.secondaryTextColor.withOpacity(0.3)),
                const SizedBox(height: 16),
                
                // Instructions content
                Flexible(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        instructions,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsScheme.primaryIconColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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

  String _formatDateShort(dynamic timestamp) {
    if (timestamp == null) return 'No date';
    
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is String) {
      try {
        date = DateTime.parse(timestamp);
      } catch (e) {
        return 'Invalid date';
      }
    } else {
      return 'Invalid date';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = dateOnly.difference(today);

    if (difference.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays == -1) {
      return 'Yesterday';
    } else if (difference.inDays > 1 && difference.inDays < 7) {
      return 'In ${difference.inDays} days';
    } else if (difference.inDays < -1 && difference.inDays > -7) {
      return '${difference.inDays.abs()} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Reverse geocoding helper function
  Future<String> _getAddressFromCoordinates(double? lat, double? lng) async {
    if (lat == null || lng == null || lat == 0.0 || lng == 0.0) {
      return '';
    }
    
    // Create cache key
    String cacheKey = '${lat.toStringAsFixed(6)}_${lng.toStringAsFixed(6)}';
    
    // Check cache first
    if (_addressCache.containsKey(cacheKey)) {
      return _addressCache[cacheKey]!;
    }
    
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '';
        
        // Build readable address
        if (place.street != null && place.street!.isNotEmpty) {
          address += place.street!;
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.subLocality!;
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.locality!;
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.administrativeArea!;
        }
        
        String resolvedAddress = address.isNotEmpty ? address : 'Address not found';
        
        // Cache the result
        _addressCache[cacheKey] = resolvedAddress;
        return resolvedAddress;
      }
    } catch (e) {
      print('Error in reverse geocoding: $e');
    }
    
    return 'Unable to resolve address';
  }

  // Widget to display delivery address with reverse geocoding
  Widget _buildDeliveryAddressWidget(Map<String, dynamic> data) {
    String savedAddress = data['deliveryAddress'] ?? '';
    double? lat = data['deliveryLatitude']?.toDouble() ?? data['LAT']?.toDouble();
    double? lng = data['deliveryLongitude']?.toDouble() ?? data['LONG']?.toDouble();
    
    // If we have coordinates, show both saved address and resolved address
    if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (savedAddress.isNotEmpty)
            Container(
              padding: EdgeInsets.all(8),
              margin: EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bookmark, color: Colors.blue, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Saved Address:',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    savedAddress,
                    style: TextStyle(
                      color: ColorsScheme.primaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          
          FutureBuilder<String>(
            future: _getAddressFromCoordinates(lat, lng),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Resolving location...',
                        style: TextStyle(
                          color: ColorsScheme.secondaryTextColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              if (snapshot.hasData && snapshot.data!.isNotEmpty && 
                  snapshot.data != 'Unable to resolve address') {
                return Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.green, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Exact Location:',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2),
                      Text(
                        snapshot.data!,
                        style: TextStyle(
                          color: ColorsScheme.primaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              // Show coordinates if can't resolve address
              return Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.my_location, color: Colors.grey, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Coordinates:',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}',
                      style: TextStyle(
                        color: ColorsScheme.secondaryTextColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      );
    }
    
    // Fallback: show saved address only
    return Text(
      savedAddress.isNotEmpty ? savedAddress : 'No address provided',
      style: TextStyle(
        color: ColorsScheme.secondaryTextColor,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _historyTabController.dispose();
    super.dispose();
  }
}
