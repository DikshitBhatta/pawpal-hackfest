import 'package:flutter/material.dart';
import 'package:pet_care/Subscription/SubscriptionPlanScreen.dart';

class SubscriptionLauncherWidget extends StatelessWidget {
  final Map<String, dynamic> petData;
  
  const SubscriptionLauncherWidget({super.key, required this.petData});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFfb9a14), Color(0xFFfb9a14)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.4),
            spreadRadius: 2,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
          // Header with back button (optional)
          Row(
            children: [
              Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Premium Meal Plans',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    Text(
                      'Custom meal subscriptions for ${petData['Name'] ?? 'Bullie'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 40),
          
          // Feature Icons Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFeatureIcon('🍽️', 'Custom'),
              _buildFeatureIcon('📦', 'Weekly'),
              _buildFeatureIcon('💚', 'Health'),
            ],
          ),
          
          SizedBox(height: 150),
          
          // Subscription Button
          Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubscriptionPlanScreen(
                      petData: petData,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 3,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  SizedBox(width: 12),
                  Text(
                    'Start Meal Subscription',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFfb9a14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Price and Terms
          Text(
            'Dynamic pricing based on real ingredients \n • Cancel anytime •',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
              fontStyle: FontStyle.italic,
              decoration: TextDecoration.none,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 20),
          
          // Terms and Privacy Links
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  // Handle Terms tap
                },
                child: Text(
                  'Terms',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              SizedBox(width: 80),
              GestureDetector(
                onTap: () {
                  // Handle Privacy tap
                },
                child: Text(
                  'Privacy',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 20),
          
          // Subscription Details
          Text(
            '🧮 Smart Pricing: Our meal plans use real ingredient costs\nfrom our inventory to calculate fair, transparent pricing.\n\n'
            '📏 Size Matters: Portions automatically adjust based on\nyour dog\'s size and activity level.\n\n'
            '💰 Frequency Discounts: Save up to 10% with more\nfrequent deliveries.\n\n'
            'Subscription automatically renews unless cancelled\n24 hours before the next billing cycle.',
            style: TextStyle(
              fontSize: 08,
              color: Colors.white.withOpacity(0.8),
              height: 1.4,
              decoration: TextDecoration.none,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildFeatureIcon(String emoji, String label) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: TextStyle(
              fontSize: 28,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}