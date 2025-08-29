import 'package:flutter/material.dart';
import 'package:pet_care/ColorsScheme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionManagementScreen extends StatefulWidget {
  final String userEmail;
  
  const SubscriptionManagementScreen({super.key, required this.userEmail});

  @override
  State<SubscriptionManagementScreen> createState() => _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState extends State<SubscriptionManagementScreen> {
  List<Map<String, dynamic>> subscriptions = [];
  bool isLoading = true;

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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Subscription cancelled successfully'),
            backgroundColor: Colors.red,
          ),
        );

        loadSubscriptions(); // Reload subscriptions
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel subscription: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My Subscriptions",
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey.shade50, Colors.grey.shade200],
          ),
        ),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
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
                                          Text('Meal Plan:', style: TextStyle(fontWeight: FontWeight.w500)),
                                          Flexible(
                                            child: Text(
                                              subscription['selectedMealPlan'] ?? 'Unknown',
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
                                            '฿${(subscription['totalAmount'] ?? 0).toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (subscription['nextDelivery'] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Next Delivery:', style: TextStyle(fontWeight: FontWeight.w500)),
                                              Text(
                                                DateTime.parse(subscription['nextDelivery']).toString().split(' ')[0],
                                                style: TextStyle(color: Colors.blue.shade700),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                
                                SizedBox(height: 16),
                                
                                Row(
                                  children: [
                                    if (isActive) ...[
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            // TODO: Implement modify subscription
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Modify feature coming soon!')),
                                            );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: Colors.blue),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.edit, size: 16, color: Colors.blue),
                                              SizedBox(width: 4),
                                              Text('Modify', style: TextStyle(color: Colors.blue)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => cancelSubscription(
                                            subscription['docId'],
                                            subscription['petName'] ?? 'Pet',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red.shade500,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.cancel, size: 16, color: Colors.white),
                                              SizedBox(width: 4),
                                              Text('Cancel', style: TextStyle(color: Colors.white)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ] else ...[
                                      Expanded(
                                        child: Container(
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
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
