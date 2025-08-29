import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ColorsScheme {
  static const Color primaryBackgroundColor = Color(0xff2A2438);
  static const Color secondaryBackgroundColor = Color(0xff352F44);
  static const Color primaryTextColor = Color(0xffFFFFFF);
  static const Color secondaryTextColor = Color(0xffB0A0D6);
  static const Color primaryIconColor = Color(0xff8476AA);
}

class MealPresets extends StatefulWidget {
  const MealPresets({Key? key}) : super(key: key);

  @override
  _MealPresetsState createState() => _MealPresetsState();
}

class _MealPresetsState extends State<MealPresets> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  
  String _selectedDogSize = 'Small';
  String _selectedMealType = 'Breakfast';
  List<String> _dogSizes = ['Small', 'Medium', 'Large'];
  List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
  List<Map<String, dynamic>> _selectedIngredients = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsScheme.primaryBackgroundColor,
      appBar: AppBar(
        backgroundColor: ColorsScheme.primaryBackgroundColor,
        title: Text(
          'Meal Presets',
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
          // Create Meal Preset Form
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorsScheme.secondaryBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Meal Preset',
                  style: TextStyle(
                    color: ColorsScheme.primaryTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField(_nameController, 'Meal Name'),
                const SizedBox(height: 12),
                _buildTextField(_descriptionController, 'Description'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildDropdown('Dog Size', _selectedDogSize, _dogSizes, (value) {
                      setState(() {
                        _selectedDogSize = value!;
                      });
                    })),
                    const SizedBox(width: 8),
                    Expanded(child: _buildDropdown('Meal Type', _selectedMealType, _mealTypes, (value) {
                      setState(() {
                        _selectedMealType = value!;
                      });
                    })),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTextField(_instructionsController, 'Preparation Instructions', maxLines: 3),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ingredients (${_selectedIngredients.length})',
                        style: TextStyle(
                          color: ColorsScheme.primaryTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _showIngredientPicker,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorsScheme.primaryIconColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Add Ingredient',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildSelectedIngredients(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _createMealPreset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsScheme.primaryIconColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Create Meal Preset',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Existing Meal Presets
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Existing Meal Presets',
                    style: TextStyle(
                      color: ColorsScheme.primaryTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('meal_presets')
                          .orderBy('name')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Text(
                              'No meal presets created yet',
                              style: TextStyle(
                                color: ColorsScheme.secondaryTextColor,
                                fontSize: 16,
                              ),
                            ),
                          );
                        }
                        
                        return ListView.builder(
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final doc = snapshot.data!.docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: ColorsScheme.secondaryBackgroundColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ExpansionTile(
                                title: Text(
                                  data['name'] ?? 'Unknown',
                                  style: TextStyle(
                                    color: ColorsScheme.primaryTextColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${data['dogSize']} • ${data['mealType']}',
                                  style: TextStyle(
                                    color: ColorsScheme.secondaryTextColor,
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
                                          'Description:',
                                          style: TextStyle(
                                            color: ColorsScheme.primaryTextColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          data['description'] ?? 'No description',
                                          style: TextStyle(
                                            color: ColorsScheme.secondaryTextColor,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Instructions:',
                                          style: TextStyle(
                                            color: ColorsScheme.primaryTextColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          data['instructions'] ?? 'No instructions',
                                          style: TextStyle(
                                            color: ColorsScheme.secondaryTextColor,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Ingredients:',
                                          style: TextStyle(
                                            color: ColorsScheme.primaryTextColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        ...((data['ingredients'] as List?) ?? []).map((ingredient) {
                                          return Text(
                                            '• ${ingredient['name']} (${ingredient['quantity']}g)',
                                            style: TextStyle(
                                              color: ColorsScheme.secondaryTextColor,
                                            ),
                                          );
                                        }).toList(),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton(
                                              onPressed: () => _deleteMealPreset(doc.id),
                                              child: Text(
                                                'Delete',
                                                style: TextStyle(color: Colors.red[400]),
                                              ),
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
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: ColorsScheme.primaryTextColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: ColorsScheme.secondaryTextColor),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: ColorsScheme.secondaryTextColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: ColorsScheme.primaryIconColor),
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: ColorsScheme.primaryBackgroundColor,
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      style: TextStyle(color: ColorsScheme.primaryTextColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: ColorsScheme.secondaryTextColor),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: ColorsScheme.secondaryTextColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: ColorsScheme.primaryIconColor),
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: ColorsScheme.primaryBackgroundColor,
      ),
      dropdownColor: ColorsScheme.secondaryBackgroundColor,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            item,
            style: TextStyle(color: ColorsScheme.primaryTextColor),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSelectedIngredients() {
    if (_selectedIngredients.isEmpty) {
      return Text(
        'No ingredients selected',
        style: TextStyle(
          color: ColorsScheme.secondaryTextColor,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      children: _selectedIngredients.map((ingredient) {
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: ColorsScheme.primaryBackgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: ColorsScheme.secondaryTextColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${ingredient['name']} - ${ingredient['quantity']}g',
                  style: TextStyle(color: ColorsScheme.primaryTextColor),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedIngredients.remove(ingredient);
                  });
                },
                icon: Icon(
                  Icons.remove_circle,
                  color: Colors.red[400],
                  size: 20,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showIngredientPicker() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('ingredients')
        .orderBy('name')
        .get();

    if (snapshot.docs.isEmpty) {
      _showErrorDialog('No ingredients available. Please add ingredients first.');
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ColorsScheme.secondaryBackgroundColor,
          title: Text(
            'Select Ingredient',
            style: TextStyle(color: ColorsScheme.primaryTextColor),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: snapshot.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.docs[index];
                final data = doc.data() as Map<String, dynamic>;
                
                return ListTile(
                  title: Text(
                    data['name'],
                    style: TextStyle(color: ColorsScheme.primaryTextColor),
                  ),
                  subtitle: Text(
                    data['category'],
                    style: TextStyle(color: ColorsScheme.secondaryTextColor),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showQuantityDialog(data['name']);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: ColorsScheme.primaryIconColor),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showQuantityDialog(String ingredientName) {
    final TextEditingController quantityController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ColorsScheme.secondaryBackgroundColor,
          title: Text(
            'Enter Quantity',
            style: TextStyle(color: ColorsScheme.primaryTextColor),
          ),
          content: TextField(
            controller: quantityController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: ColorsScheme.primaryTextColor),
            decoration: InputDecoration(
              labelText: 'Quantity (grams)',
              labelStyle: TextStyle(color: ColorsScheme.secondaryTextColor),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: ColorsScheme.secondaryTextColor.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: ColorsScheme.primaryIconColor),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: ColorsScheme.secondaryTextColor),
              ),
            ),
            TextButton(
              onPressed: () {
                if (quantityController.text.trim().isNotEmpty) {
                  setState(() {
                    _selectedIngredients.add({
                      'name': ingredientName,
                      'quantity': double.tryParse(quantityController.text) ?? 0.0,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: Text(
                'Add',
                style: TextStyle(color: ColorsScheme.primaryIconColor),
              ),
            ),
          ],
        );
      },
    );
  }

  void _createMealPreset() async {
    if (_nameController.text.trim().isEmpty) {
      _showErrorDialog('Please enter meal name');
      return;
    }

    if (_selectedIngredients.isEmpty) {
      _showErrorDialog('Please add at least one ingredient');
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('meal_presets').add({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'instructions': _instructionsController.text.trim(),
        'dogSize': _selectedDogSize,
        'mealType': _selectedMealType,
        'ingredients': _selectedIngredients,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _clearForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal preset created successfully!')),
      );
    } catch (e) {
      _showErrorDialog('Error creating meal preset: $e');
    }
  }

  void _deleteMealPreset(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('meal_presets').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal preset deleted successfully!')),
      );
    } catch (e) {
      _showErrorDialog('Error deleting meal preset: $e');
    }
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _instructionsController.clear();
    setState(() {
      _selectedDogSize = 'Small';
      _selectedMealType = 'Breakfast';
      _selectedIngredients.clear();
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorsScheme.secondaryBackgroundColor,
        title: Text(
          'Error',
          style: TextStyle(color: ColorsScheme.primaryTextColor),
        ),
        content: Text(
          message,
          style: TextStyle(color: ColorsScheme.secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: ColorsScheme.primaryIconColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }
}
