import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';

class ColorsScheme {
  static const Color primaryBackgroundColor = Color(0xff2A2438);
  static const Color secondaryBackgroundColor = Color(0xff352F44);
  static const Color primaryTextColor = Color(0xffFFFFFF);
  static const Color secondaryTextColor = Color(0xffB0A0D6);
  static const Color primaryIconColor = Color(0xff8476AA);
}

class DeliverySetup extends StatefulWidget {
  const DeliverySetup({Key? key}) : super(key: key);

  @override
  _DeliverySetupState createState() => _DeliverySetupState();
}

class _DeliverySetupState extends State<DeliverySetup> with TickerProviderStateMixin {
  late TabController _tabController;

  // Cache for resolved addresses to avoid repeated API calls
  Map<String, String> _addressCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsScheme.primaryBackgroundColor,
      appBar: AppBar(
        backgroundColor: ColorsScheme.primaryBackgroundColor,
        title: Text(
          'Delivery Management',
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
            Tab(text: 'Delivery Queue'),
            Tab(text: 'Track Delivery'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDeliveryQueueTab(),
          _buildTrackDeliveryTab(),
          _buildDeliveryHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildDeliveryQueueTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'ready')
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

  Widget _buildTrackDeliveryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', whereIn: ['on_way', 'on_mid_way'])
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
                  Icons.track_changes,
                  size: 64,
                  color: ColorsScheme.secondaryTextColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'No deliveries in progress',
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
            
            return _buildTrackingCard(data, doc.id);
          },
        );
      },
    );
  }

  Widget _buildDeliveryCard(Map<String, dynamic> orderData, String orderId) {
    final petName = orderData['petName'] ?? 'Unknown Pet';
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
                Text(
                  'Delivery Address:',
                    style: TextStyle(
                    color: ColorsScheme.primaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _buildDeliveryAddressWidget(orderData),
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

  Widget _buildTrackingCard(Map<String, dynamic> orderData, String orderId) {
    final petName = orderData['petName'] ?? 'Unknown Pet';
    final status = orderData['status'] ?? 'ready';
    final scheduledDate = orderData['scheduledDeliveryDate'] ?? '';
    final mealPlan = orderData['mealPlan'];
    final dispatchedAt = orderData['dispatchedAt'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: ColorsScheme.secondaryBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with pet name and current status
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
                    color: _getDeliveryStatusColor(status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getDeliveryStatusText(status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Meal plan info
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

            // Delivery address in tracking card
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Delivery Address:',
                    style: TextStyle(
                    color: ColorsScheme.primaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _buildDeliveryAddressWidget(orderData),
            const SizedBox(height: 8),

            // Scheduled delivery time
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

            // Dispatch time if available
            if (dispatchedAt.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.local_shipping, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Dispatched: ${_formatDate(dispatchedAt)}',
                    style: TextStyle(
                      color: ColorsScheme.secondaryTextColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Status update buttons
            _buildDeliveryStatusButtons(orderData, orderId, status),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryStatusButtons(Map<String, dynamic> orderData, String orderId, String status) {
    switch (status) {
      case 'on_way':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openDeliveryLocation(orderData),
                icon: const Icon(Icons.location_on, size: 16),
                label: const Text('Location'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _updateDeliveryStatus(orderId, 'on_mid_way'),
                icon: const Icon(Icons.navigation, size: 16),
                label: const Text('Mid Way'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );

      case 'on_mid_way':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openDeliveryLocation(orderData),
                icon: const Icon(Icons.location_on, size: 16),
                label: const Text('Location'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _updateDeliveryStatus(orderId, 'delivered'),
                icon: const Icon(Icons.check_circle, size: 16),
                label: const Text('Delivered'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
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
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Delivery Completed',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
    }
  }

  Color _getDeliveryStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ready':
        return Colors.blue;
      case 'on_way':
        return Colors.orange;
      case 'on_mid_way':
        return Colors.amber;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getDeliveryStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'ready':
        return 'READY';
      case 'on_way':
        return 'ON WAY';
      case 'on_mid_way':
        return 'MID WAY';
      case 'delivered':
        return 'DELIVERED';
      default:
        return status.toUpperCase();
    }
  }

  Future<void> _updateDeliveryStatus(String orderId, String newStatus) async {
    try {
      Map<String, dynamic> updateData = {
        'status': newStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Add specific timestamps based on status
      switch (newStatus) {
        case 'on_way':
          updateData['dispatchedAt'] = DateTime.now().toIso8601String();
          updateData['estimatedDelivery'] = DateTime.now().add(Duration(hours: 2)).toIso8601String();
          break;
        case 'on_mid_way':
          updateData['midWayAt'] = DateTime.now().toIso8601String();
          updateData['estimatedDelivery'] = DateTime.now().add(Duration(hours: 1)).toIso8601String();
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

      _showMessage('Delivery status updated to ${_getDeliveryStatusText(newStatus)}!');
    } catch (e) {
      _showMessage('Error updating delivery status: $e');
    }
  }

  Future<void> _markAsDispatched(String orderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'status': 'on_way',
        'dispatchedAt': DateTime.now().toIso8601String(),
        'estimatedDelivery': DateTime.now().add(Duration(hours: 2)).toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      _showMessage('Order dispatched successfully!');
    } catch (e) {
      _showMessage('Error dispatching order: $e');
    }
  }

  Future<void> _openDeliveryLocation(Map<String, dynamic> orderData) async {
    // Get location coordinates
    final deliveryLatitude = orderData['deliveryLatitude']?.toDouble();
    final deliveryLongitude = orderData['deliveryLongitude']?.toDouble();
    
    if (deliveryLatitude != null && deliveryLongitude != null && 
        deliveryLatitude != 0.0 && deliveryLongitude != 0.0) {
      _showMessage(
        'Location: $deliveryLatitude, $deliveryLongitude\n(Map integration coming soon)',
      );
      return;
    }
    
    _showMessage('No location coordinates available');
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

  Widget _buildDeliveryHistoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'delivered')
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
                  Icons.history,
                  size: 64,
                  color: ColorsScheme.secondaryTextColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'No delivery history found',
                  style: TextStyle(
                    color: ColorsScheme.secondaryTextColor,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          );
        }
        
        // Sort delivered orders by delivery date (newest first)
        final sortedDocs = snapshot.data!.docs.toList();
        sortedDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['deliveredAt']?.toString() ?? aData['updatedAt']?.toString() ?? '';
          final bTime = bData['deliveredAt']?.toString() ?? bData['updatedAt']?.toString() ?? '';
          return bTime.compareTo(aTime); // Descending order (newest first)
        });
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedDocs.length,
          itemBuilder: (context, index) {
            final doc = sortedDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            
            return _buildDeliveryHistoryCard(data);
          },
        );
      },
    );
  }

  Widget _buildDeliveryHistoryCard(Map<String, dynamic> orderData) {
    final petName = orderData['petName'] ?? 'Unknown Pet';
    final scheduledDate = orderData['scheduledDeliveryDate'] ?? '';
    final deliveredAt = orderData['deliveredAt'] ?? orderData['updatedAt'] ?? '';
    final mealPlan = orderData['mealPlan'];
    final totalAmount = (orderData['totalAmount'] ?? 0.0).toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: ColorsScheme.secondaryBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with pet name and delivered status
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
                    'DELIVERED',
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

            // Meal plan info
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

            // Order amount
            Row(
              children: [
                Icon(Icons.attach_money, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Amount: \$${totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: ColorsScheme.primaryTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Delivery address in history card
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Delivery Address:',
                  style: TextStyle(
                    color: ColorsScheme.primaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _buildDeliveryAddressWidget(orderData),
            const SizedBox(height: 8),

            // Scheduled delivery time
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
            const SizedBox(height: 8),

            // Delivered time
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Delivered: ${_formatDate(deliveredAt)}',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Success indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Successfully Delivered',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ColorsScheme.primaryIconColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
  Widget _buildDeliveryAddressWidget(Map<String, dynamic> orderData) {
    String savedAddress = orderData['deliveryAddress'] ?? '';
    String deliveryCity = orderData['deliveryCity'] ?? '';
    double? lat = orderData['deliveryLatitude']?.toDouble() ?? orderData['LAT']?.toDouble();
    double? lng = orderData['deliveryLongitude']?.toDouble() ?? orderData['LONG']?.toDouble();
    
    String fullSavedAddress = '$savedAddress${deliveryCity.isNotEmpty ? ', $deliveryCity' : ''}';
    
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
              child: Row(
                children: [
                  Icon(Icons.bookmark, color: Colors.blue, size: 14),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      fullSavedAddress,
                      style: TextStyle(
                        color: ColorsScheme.primaryTextColor,
                        fontSize: 12,
                      ),
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
                        'Resolving exact location...',
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
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.green, size: 14),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          snapshot.data!,
                          style: TextStyle(
                            color: ColorsScheme.primaryTextColor,
                            fontSize: 12,
                          ),
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
                child: Row(
                  children: [
                    Icon(Icons.my_location, color: Colors.grey, size: 14),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Coordinates: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                        style: TextStyle(
                          color: ColorsScheme.secondaryTextColor,
                          fontSize: 11,
                        ),
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
      fullSavedAddress.isNotEmpty ? fullSavedAddress : 'Address not provided',
      style: TextStyle(
        color: ColorsScheme.secondaryTextColor,
        fontSize: 14,
      ),
    );
  }
}
