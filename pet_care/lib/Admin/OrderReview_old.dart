import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  List<String> _statusFilters = ['All', 'Pending', 'Confirmed', 'Preparing', 'Delivered', 'Cancelled'];

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
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            
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
                        'Order #${data['orderNumber'] ?? doc.id.substring(0, 8)}',
                        style: TextStyle(
                          color: ColorsScheme.primaryTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '\$${(data['totalAmount'] ?? 0.0).toStringAsFixed(2)}',
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
                      'Date: ${_formatDate(data['orderDate'])}',
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
                          data['deliveryAddress'] ?? 'No address provided',
                          style: TextStyle(
                            color: ColorsScheme.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (data['status'] == 'Pending')
                              _buildActionButton(
                                'Confirm',
                                Colors.green,
                                () => _updateOrderStatus(doc.id, 'Confirmed'),
                              ),
                            if (data['status'] == 'Confirmed')
                              _buildActionButton(
                                'Start Preparing',
                                Colors.orange,
                                () => _updateOrderStatus(doc.id, 'Preparing'),
                              ),
                            if (data['status'] == 'Preparing')
                              _buildActionButton(
                                'Mark Delivered',
                                Colors.blue,
                                () => _updateOrderStatus(doc.id, 'Delivered'),
                              ),
                            if (data['status'] != 'Cancelled' && data['status'] != 'Delivered')
                              _buildActionButton(
                                'Cancel',
                                Colors.red,
                                () => _updateOrderStatus(doc.id, 'Cancelled'),
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
          .where('status', isEqualTo: 'Delivered')
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
                  _buildRevenueRow('Number of Delivered Orders', revenue['deliveredOrders'].toString()),
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
      return FirebaseFirestore.instance
          .collection('orders')
          .orderBy('orderDate', descending: true)
          .snapshots();
    } else {
      return FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: _selectedStatusFilter)
          .orderBy('orderDate', descending: true)
          .snapshots();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Confirmed':
        return Colors.blue;
      case 'Preparing':
        return Colors.purple;
      case 'Delivered':
        return Colors.green;
      case 'Cancelled':
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
      final status = data['status'] ?? 'Pending';
      final amount = (data['totalAmount'] ?? 0.0).toDouble();
      final orderDate = data['orderDate'];
      
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      totalAmount += amount;
      
      if (status == 'Pending') pendingOrders++;
      if (status == 'Delivered') completedOrders++;
      
      if (orderDate != null && orderDate is Timestamp) {
        final orderDateTime = orderDate.toDate();
        if (orderDateTime.isAfter(today)) {
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
      final orderDate = data['orderDate'];
      
      totalRevenue += amount;
      if (amount > highestOrder) highestOrder = amount;
      if (amount < lowestOrder) lowestOrder = amount;
      
      if (orderDate != null && orderDate is Timestamp) {
        final orderDateTime = orderDate.toDate();
        
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
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating order status: $e')),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
