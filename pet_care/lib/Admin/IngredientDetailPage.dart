import 'package:flutter/material.dart';
import 'dart:convert';

class ColorsScheme {
  static const Color primaryBackgroundColor = Color(0xff2A2438);
  static const Color secondaryBackgroundColor = Color(0xff352F44);
  static const Color primaryTextColor = Color(0xffFFFFFF);
  static const Color secondaryTextColor = Color(0xffB0A0D6);
  static const Color primaryIconColor = Color(0xff8476AA);
}

class IngredientDetailPage extends StatelessWidget {
  final String ingredientId;
  final Map<String, dynamic> ingredientData;

  const IngredientDetailPage({
    Key? key,
    required this.ingredientId,
    required this.ingredientData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsScheme.primaryBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: ColorsScheme.primaryBackgroundColor,
            iconTheme: IconThemeData(color: ColorsScheme.primaryTextColor),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      ColorsScheme.secondaryBackgroundColor,
                      ColorsScheme.primaryBackgroundColor,
                    ],
                  ),
                ),
                child: _buildImageSection(),
              ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: 24),
                  _buildStockAndPriceSection(),
                  const SizedBox(height: 24),
                  _buildNutritionSection(),
                  const SizedBox(height: 24),
                  _buildMetadataSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    final imageBase64 = ingredientData['imageBase64'];
    
    return Container(
      width: double.infinity,
      child: imageBase64 != null
          ? ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              child: Image.memory(
                base64Decode(imageBase64),
                fit: BoxFit.cover,
              ),
            )
          : Container(
              decoration: BoxDecoration(
                color: ColorsScheme.secondaryBackgroundColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 80,
                      color: ColorsScheme.primaryIconColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Image Available',
                      style: TextStyle(
                        color: ColorsScheme.secondaryTextColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderSection() {
    final name = ingredientData['name'] ?? 'Unknown Ingredient';
    final category = ingredientData['category'] ?? 'Unknown Category';
    final isAvailable = ingredientData['availability'] ?? false;
    final isAllergen = ingredientData['isAllergen'] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: ColorsScheme.primaryTextColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isAvailable ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isAvailable ? 'Available' : 'Out of Stock',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ColorsScheme.primaryIconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: ColorsScheme.primaryIconColor,
                  width: 1,
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: ColorsScheme.primaryIconColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isAllergen) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.orange,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('⚠️', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      'Allergen',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStockAndPriceSection() {
    final stock = ingredientData['stock'] ?? 0;
    final unit = ingredientData['unit'] ?? 'units';
    final pricePerUnit = ingredientData['pricePerUnit'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorsScheme.secondaryBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Icon(
                  Icons.inventory,
                  color: ColorsScheme.primaryIconColor,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Stock',
                  style: TextStyle(
                    color: ColorsScheme.secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$stock $unit',
                  style: TextStyle(
                    color: ColorsScheme.primaryTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: ColorsScheme.primaryIconColor.withOpacity(0.3),
          ),
          Expanded(
            child: Column(
              children: [
                Icon(
                  Icons.attach_money,
                  color: ColorsScheme.primaryIconColor,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Price per $unit',
                  style: TextStyle(
                    color: ColorsScheme.secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '฿${pricePerUnit.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: ColorsScheme.primaryTextColor,
                    fontSize: 18,
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

  Widget _buildNutritionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nutritional Information',
          style: TextStyle(
            color: ColorsScheme.primaryTextColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ColorsScheme.secondaryBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildNutritionGrid(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionGrid() {
    final nutritionData = [
      {'label': 'Protein', 'value': ingredientData['protein'] ?? 0, 'unit': 'g', 'icon': Icons.fitness_center},
      {'label': 'Fat', 'value': ingredientData['fat'] ?? 0, 'unit': 'g', 'icon': Icons.opacity},
      {'label': 'Fiber', 'value': ingredientData['fiber'] ?? 0, 'unit': 'g', 'icon': Icons.grass},
      {'label': 'Calcium', 'value': ingredientData['calcium'] ?? 0, 'unit': 'mg', 'icon': Icons.healing},
      {'label': 'Iron', 'value': ingredientData['iron'] ?? 0, 'unit': 'mg', 'icon': Icons.favorite},
      {'label': 'Omega-3', 'value': ingredientData['omega3'] ?? 0, 'unit': 'g', 'icon': Icons.water_drop},
      {'label': 'Vitamin A', 'value': ingredientData['vitaminA'] ?? 0, 'unit': 'IU', 'icon': Icons.visibility},
      {'label': 'Vitamin C', 'value': ingredientData['vitaminC'] ?? 0, 'unit': 'mg', 'icon': Icons.local_pharmacy},
      {'label': 'Vitamin D', 'value': ingredientData['vitaminD'] ?? 0, 'unit': 'IU', 'icon': Icons.wb_sunny},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0, // Changed from 1.2 to 1.0
      ),
      itemCount: nutritionData.length,
      itemBuilder: (context, index) {
        final item = nutritionData[index];
        return Container(
          padding: const EdgeInsets.all(8), // Reduced from 12 to 8
          decoration: BoxDecoration(
            color: ColorsScheme.primaryBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ColorsScheme.primaryIconColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Added this
            children: [
              Icon(
                item['icon'] as IconData,
                color: ColorsScheme.primaryIconColor,
                size: 18, // Reduced from 20 to 18
              ),
              const SizedBox(height: 2), // Reduced from 4 to 2
              Flexible( // Wrapped with Flexible
                child: Text(
                  item['label'] as String,
                  style: TextStyle(
                    color: ColorsScheme.secondaryTextColor,
                    fontSize: 9, // Reduced from 10 to 9
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 1), // Reduced from 2 to 1
              Flexible( // Wrapped with Flexible
                child: Text(
                  '${item['value']}${item['unit']}',
                  style: TextStyle(
                    color: ColorsScheme.primaryTextColor,
                    fontSize: 11, // Reduced from 12 to 11
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetadataSection() {
    final createdAt = ingredientData['createdAt'];
    final updatedAt = ingredientData['updatedAt'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Information',
          style: TextStyle(
            color: ColorsScheme.primaryTextColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ColorsScheme.secondaryBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildInfoRow('Ingredient ID', ingredientId),
              const SizedBox(height: 12),
              _buildInfoRow('Created', _formatTimestamp(createdAt)),
              const SizedBox(height: 12),
              _buildInfoRow('Last Updated', _formatTimestamp(updatedAt)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              color: ColorsScheme.secondaryTextColor,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: ColorsScheme.primaryTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    
    try {
      DateTime dateTime;
      if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else {
        // Firestore Timestamp
        dateTime = timestamp.toDate();
      }
      
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }
}
