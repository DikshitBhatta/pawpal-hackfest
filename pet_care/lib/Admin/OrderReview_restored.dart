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
          return const Center(child: CircularProgressIndicator(color: Colors.white));
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
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            
            return _buildOrderCard(data, doc.id);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> orderData, String orderId) {
    final status = orderData['status'] ?? 'pending';
    final petName = orderData['petName'] ?? orderData['customerName'] ?? 'Unknown';
    final orderNumber = orderData['orderNumber'] ?? orderId.substring(0, 8);
    final totalAmount = (orderData['totalAmount'] ?? 0.0).toDouble();
    final orderDate = orderData['orderDate'] ?? orderData['createdAt'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ColorsScheme.secondaryBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(status).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status.toUpperCase(),
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
                'Order #$orderNumber',
                style: TextStyle(
                  color: ColorsScheme.primaryTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '\$${totalAmount.toStringAsFixed(2)}',
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
              'Customer: $petName',
              style: TextStyle(
                color: ColorsScheme.secondaryTextColor,
              ),
            ),
            Text(
              'Date: ${_formatDate(orderDate)}',
              style: TextStyle(
                color: ColorsScheme.secondaryTextColor,
                fontSize: 12,
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
                
                // Show meal plan if available
                if (orderData['mealPlan'] != null && orderData['mealPlan'] is Map)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: ColorsScheme.primaryBackgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${orderData['mealPlan']['image'] ?? '🍗'} ',
                          style: const TextStyle(fontSize: 20),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                orderData['mealPlan']['name'] ?? 'Custom Meal',
                                style: TextStyle(
                                  color: ColorsScheme.primaryTextColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (orderData['mealPlan']['calories'] != null)
                                Text(
                                  '${orderData['mealPlan']['calories']} calories',
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
                  ),
                
                const Divider(),
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
                Text(
                  orderData['deliveryAddress'] ?? 'No address provided',
                  style: TextStyle(
                    color: ColorsScheme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (status == 'pending')
                      _buildActionButton(
                        'Start Preparing',
                        Colors.blue,
                        () => _updateOrderStatus(orderId, 'preparing'),
                      ),
                    if (status == 'preparing')
                      _buildActionButton(
                        'Mark Ready',
                        Colors.green,
                        () => _updateOrderStatus(orderId, 'ready'),
                      ),
                    if (status == 'ready')
                      _buildActionButton(
                        'Mark Delivered',
                        Colors.teal,
                        () => _updateOrderStatus(orderId, 'delivered'),
                      ),
                    if (status != 'failed' && status != 'delivered')
                      _buildActionButton(
                        'Mark Failed',
                        Colors.red,
                        () => _updateOrderStatus(orderId, 'failed'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
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
            _buildAnalyticsCard('Today\'s Orders', analytics['todayOrders'].toString(), Icons.today),
            const SizedBox(height: 12),
            _buildAnalyticsCard('Avg Order Value', '\$${analytics['averageOrderValue'].toStringAsFixed(2)}', Icons.monetization_on),
            const SizedBox(height: 20),
            Text(
              'Order Status Breakdown:',
              style: TextStyle(
                color: ColorsScheme.primaryTextColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...(analytics['statusCounts'] as Map<String, int>).entries.map((entry) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorsScheme.secondaryBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getStatusColor(entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.key.toUpperCase(),
                        style: TextStyle(
                          color: ColorsScheme.primaryTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '${entry.value}',
                      style: TextStyle(
                        color: ColorsScheme.primaryIconColor,
                        fontWeight: FontWeight.bold,
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
          .where('status', isEqualTo: 'delivered')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        
        final orders = snapshot.data?.docs ?? [];
        final revenue = _calculateRevenue(orders);
        
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildRevenueCard('Total Revenue', '\$${revenue['totalRevenue'].toStringAsFixed(2)}', Icons.account_balance_wallet, Colors.green),
            const SizedBox(height: 12),
            _buildRevenueCard('Monthly Revenue', '\$${revenue['monthlyRevenue'].toStringAsFixed(2)}', Icons.calendar_month, Colors.blue),
            const SizedBox(height: 12),
            _buildRevenueCard('Weekly Revenue', '\$${revenue['weeklyRevenue'].toStringAsFixed(2)}', Icons.date_range, Colors.orange),
            const SizedBox(height: 12),
            _buildRevenueCard('Daily Revenue', '\$${revenue['dailyRevenue'].toStringAsFixed(2)}', Icons.today, Colors.purple),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorsScheme.secondaryBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revenue Details',
                    style: TextStyle(
                      color: ColorsScheme.primaryTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRevenueRow('Delivered Orders', '${revenue['deliveredOrders']}'),
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
                    fontSize: 24,
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
                    fontSize: 24,
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
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: ColorsScheme.primaryTextColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
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

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    if (date is Timestamp) {
      final dateTime = date.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    if (date is String) {
      try {
        final dateTime = DateTime.parse(date);
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      } catch (e) {
        return date;
      }
    }
    return date.toString();
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
      if (status == 'delivered') completedOrders++;
      
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
      'deliveredOrders': orders.length,
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

  void _showMessage(String message, ContentType type) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: type == ContentType.success ? 'Success!' : 'Error!',
        message: message,
        contentType: type,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
