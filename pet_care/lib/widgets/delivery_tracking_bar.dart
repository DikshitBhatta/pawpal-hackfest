import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ColorsScheme {
  static const Color primaryBackgroundColor = Color(0xff2A2438);
  static const Color secondaryBackgroundColor = Color(0xff352F44);
  static const Color primaryTextColor = Color(0xffFFFFFF);
  static const Color secondaryTextColor = Color(0xffB0A0D6);
  static const Color primaryIconColor = Color(0xff8476AA);
}

class DeliveryTrackingBar extends StatelessWidget {
  final String userId;
  final List<Map<String, dynamic>>? prefetchedOrders;
  
  const DeliveryTrackingBar({
    Key? key, 
    required this.userId,
    this.prefetchedOrders,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Always use StreamBuilder for real-time updates
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['on_way', 'on_mid_way'])
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final orderData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        return _buildTrackingBar(orderData);
      },
    );
  }
  
  Widget _buildTrackingBar(Map<String, dynamic> orderData) {
    final status = orderData['status'] ?? 'on_way';
    final petName = orderData['petName'] ?? 'Your Pet';
    final mealPlan = orderData['mealPlan'];
    final estimatedDelivery = orderData['estimatedDelivery'] ?? '';
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.purple.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with delivery info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.local_shipping,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery in Progress',
                      style: TextStyle(
                        color: ColorsScheme.primaryTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (mealPlan != null && mealPlan is Map)
                      Text(
                        '${mealPlan['image'] ?? '🍗'} ${mealPlan['name'] ?? 'Meal'} for $petName',
                        style: TextStyle(
                          color: ColorsScheme.secondaryTextColor,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Progress bar
          _buildProgressBar(status),
          const SizedBox(height: 12),
          
          // Status indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusIndicator('On Way', 'on_way', status),
              _buildStatusIndicator('Mid Way', 'on_mid_way', status),
              _buildStatusIndicator('Delivered', 'delivered', status),
            ],
          ),
          
          // Estimated delivery time
          if (estimatedDelivery.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Estimated delivery: ${_formatEstimatedTime(estimatedDelivery)}',
                    style: TextStyle(
                      color: ColorsScheme.secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar(String currentStatus) {
    double progress = 0.0;
    
    switch (currentStatus) {
      case 'on_way':
        progress = 0.33;
        break;
      case 'on_mid_way':
        progress = 0.66;
        break;
      case 'delivered':
        progress = 1.0;
        break;
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: constraints.maxWidth * progress,
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.green],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(String label, String statusValue, String currentStatus) {
    bool isActive = _isStatusActive(statusValue, currentStatus);
    bool isCompleted = _isStatusCompleted(statusValue, currentStatus);
    
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isCompleted 
                ? Colors.green 
                : isActive 
                    ? Colors.blue 
                    : Colors.grey.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(
              color: isCompleted || isActive 
                  ? Colors.transparent 
                  : Colors.grey.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Icon(
            isCompleted 
                ? Icons.check 
                : isActive 
                    ? Icons.radio_button_unchecked 
                    : Icons.radio_button_unchecked,
            color: isCompleted || isActive 
                ? Colors.white 
                : Colors.grey.withOpacity(0.5),
            size: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isCompleted || isActive 
                ? ColorsScheme.primaryTextColor 
                : ColorsScheme.secondaryTextColor,
            fontSize: 10,
            fontWeight: isCompleted || isActive 
                ? FontWeight.bold 
                : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  bool _isStatusActive(String statusValue, String currentStatus) {
    return statusValue == currentStatus;
  }

  bool _isStatusCompleted(String statusValue, String currentStatus) {
    const statusOrder = ['on_way', 'on_mid_way', 'delivered'];
    int currentIndex = statusOrder.indexOf(currentStatus);
    int statusIndex = statusOrder.indexOf(statusValue);
    
    return currentIndex > statusIndex;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
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

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'on_way':
        return 'ON THE WAY';
      case 'on_mid_way':
        return 'MIDWAY';
      case 'delivered':
        return 'DELIVERED';
      default:
        return status.toUpperCase();
    }
  }

  String _formatEstimatedTime(String estimatedDelivery) {
    try {
      final date = DateTime.parse(estimatedDelivery);
      final now = DateTime.now();
      final difference = date.difference(now);
      
      if (difference.inHours > 0) {
        return '${difference.inHours}h ${difference.inMinutes % 60}m';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return 'Soon';
      }
    } catch (e) {
      return 'Soon';
    }
  }
}
