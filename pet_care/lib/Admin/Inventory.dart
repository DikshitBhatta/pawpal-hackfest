import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'IngredientDetailPage.dart';

class ColorsScheme {
  static const Color primaryBackgroundColor = Color(0xff2A2438);
  static const Color secondaryBackgroundColor = Color(0xff352F44);
  static const Color primaryTextColor = Color(0xffFFFFFF);
  static const Color secondaryTextColor = Color(0xffB0A0D6);
  static const Color primaryIconColor = Color(0xff8476AA);
}

class Inventory extends StatefulWidget {
  const Inventory({Key? key}) : super(key: key);

  @override
  _InventoryState createState() => _InventoryState();
}

class _InventoryState extends State<Inventory> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsScheme.primaryBackgroundColor,
      appBar: AppBar(
        backgroundColor: ColorsScheme.primaryBackgroundColor,
        title: Text(
          'Inventory',
          style: TextStyle(
            color: ColorsScheme.primaryTextColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: ColorsScheme.primaryIconColor),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: ColorsScheme.primaryTextColor),
              decoration: InputDecoration(
                hintText: 'Search ingredients...',
                hintStyle: TextStyle(color: ColorsScheme.secondaryTextColor),
                prefixIcon: Icon(
                  Icons.search,
                  color: ColorsScheme.primaryIconColor,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                        icon: Icon(
                          Icons.clear,
                          color: ColorsScheme.primaryIconColor,
                        ),
                      )
                    : null,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: ColorsScheme.secondaryTextColor.withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: ColorsScheme.primaryIconColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: ColorsScheme.secondaryBackgroundColor,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          
          // Ingredients Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ingredients')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: ColorsScheme.primaryIconColor,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: ColorsScheme.secondaryTextColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No ingredients found',
                          style: TextStyle(
                            color: ColorsScheme.secondaryTextColor,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add ingredients from Ingredient Management',
                          style: TextStyle(
                            color: ColorsScheme.secondaryTextColor.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter ingredients based on search query
                final ingredients = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final category = (data['category'] ?? '').toString().toLowerCase();
                  return _searchQuery.isEmpty ||
                      name.contains(_searchQuery) ||
                      category.contains(_searchQuery);
                }).toList();

                if (ingredients.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: ColorsScheme.secondaryTextColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No ingredients match your search',
                          style: TextStyle(
                            color: ColorsScheme.secondaryTextColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: ingredients.length,
                  itemBuilder: (context, index) {
                    final doc = ingredients[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildIngredientCard(doc.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientCard(String docId, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Unknown';
    final category = data['category'] ?? 'Unknown';
    final stock = data['stock'] ?? 0;
    final unit = data['unit'] ?? 'units';
    final price = data['pricePerUnit'] ?? 0.0;
    final isAvailable = data['availability'] ?? true;
    final isAllergen = data['isAllergen'] ?? false;
    final imageBase64 = data['imageBase64'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IngredientDetailPage(
              ingredientId: docId,
              ingredientData: data,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: ColorsScheme.secondaryBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isAvailable 
                ? ColorsScheme.primaryIconColor.withOpacity(0.3)
                : Colors.red.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: ColorsScheme.primaryBackgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: imageBase64 != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: Image.memory(
                          base64Decode(imageBase64),
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.inventory_2,
                        size: 40,
                        color: ColorsScheme.primaryIconColor,
                      ),
              ),
            ),
            
            // Content Section
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and Allergen Badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              color: ColorsScheme.primaryTextColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isAllergen)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '⚠️',
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Category
                    Text(
                      category,
                      style: TextStyle(
                        color: ColorsScheme.secondaryTextColor,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // Stock Info
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: stock > 0 
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Stock: $stock $unit',
                        style: TextStyle(
                          color: stock > 0 ? Colors.green : Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Price and Availability
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '฿${price.toStringAsFixed(2)}/$unit',
                          style: TextStyle(
                            color: ColorsScheme.primaryIconColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isAvailable ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
