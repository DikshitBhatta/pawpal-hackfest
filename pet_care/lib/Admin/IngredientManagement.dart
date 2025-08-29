import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

class ColorsScheme {
  static const Color primaryBackgroundColor = Color(0xff2A2438);
  static const Color secondaryBackgroundColor = Color(0xff352F44);
  static const Color primaryTextColor = Color(0xffFFFFFF);
  static const Color secondaryTextColor = Color(0xffB0A0D6);
  static const Color primaryIconColor = Color(0xff8476AA);
}

class IngredientManagement extends StatefulWidget {
  const IngredientManagement({Key? key}) : super(key: key);

  @override
  _IngredientManagementState createState() => _IngredientManagementState();
}

class _IngredientManagementState extends State<IngredientManagement> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();
  final TextEditingController _fiberController = TextEditingController();
  final TextEditingController _omega3Controller = TextEditingController();
  final TextEditingController _omega6Controller = TextEditingController();
  final TextEditingController _vitaminAController = TextEditingController();
  final TextEditingController _vitaminBController = TextEditingController();
  final TextEditingController _vitaminCController = TextEditingController();
  final TextEditingController _vitaminDController = TextEditingController();
  final TextEditingController _vitaminEController = TextEditingController();
  final TextEditingController _calciumController = TextEditingController();
  final TextEditingController _phosphorusController = TextEditingController();
  final TextEditingController _ironController = TextEditingController();
  final TextEditingController _zincController = TextEditingController();
  final TextEditingController _taurineController = TextEditingController();
  final TextEditingController _magnesiumController = TextEditingController();
  final TextEditingController _glucosamineController = TextEditingController();
  final TextEditingController _chondroitinController = TextEditingController();
  final TextEditingController _probioticsController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  
  String _selectedCategory = 'Food';
  List<String> _categories = [
    'Food',
    'Nutritional Supplement',
    'Vitamins and Minerals',
    'Snacks and Treats',
    'Special Diet Item'
  ];
  
  String _selectedUnit = 'kg';
  Map<String, List<String>> _categoryUnits = {
    'Food': ['kg', 'g', 'lbs', 'pieces'],
    'Nutritional Supplement': ['g', 'mg', 'tablets', 'capsules', 'ml', 'bottles'],
    'Vitamins and Minerals': ['g', 'mg', 'tablets', 'capsules', 'bottles'],
    'Snacks and Treats': ['kg', 'g', 'pieces', 'packs'],
    'Special Diet Item': ['kg', 'g', 'lbs', 'cans', 'pieces'],
  };
  
  bool _isAvailable = true;
  bool _isAllergen = false;
  
  File? _selectedImage;
  String? _imageBase64;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsScheme.primaryBackgroundColor,
      appBar: AppBar(
        backgroundColor: ColorsScheme.primaryBackgroundColor,
        title: Text(
          'Ingredient Management',
          style: TextStyle(
            color: ColorsScheme.primaryTextColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: ColorsScheme.primaryIconColor),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Add Ingredient Form
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
                    'Add New Ingredient',
                    style: TextStyle(
                      color: ColorsScheme.primaryTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Basic Information
                  _buildTextField(_nameController, 'Ingredient Name'),
                  const SizedBox(height: 12),
                  _buildDropdown(),
                  const SizedBox(height: 12),
                  
                  // Image Upload Section
                  _buildImagePicker(),
                  const SizedBox(height: 12),
                  
                  _buildTextField(_priceController, 'Price per Unit (\$)'),
                  const SizedBox(height: 12),
                  _buildStockWithUnit(),
                  const SizedBox(height: 16),
                  
                  // Availability and Allergen Status
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Checkbox(
                              value: _isAvailable,
                              onChanged: (value) {
                                setState(() {
                                  _isAvailable = value ?? true;
                                });
                              },
                              activeColor: ColorsScheme.primaryIconColor,
                            ),
                            Text(
                              'Available',
                              style: TextStyle(color: ColorsScheme.primaryTextColor),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Checkbox(
                              value: _isAllergen,
                              onChanged: (value) {
                                setState(() {
                                  _isAllergen = value ?? false;
                                });
                              },
                              activeColor: Colors.orange,
                            ),
                            Text(
                              'Allergen',
                              style: TextStyle(color: ColorsScheme.primaryTextColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Nutrition Information
                  Text(
                    'Nutrition Information (per 100g)',
                    style: TextStyle(
                      color: ColorsScheme.primaryTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Macronutrients
                  Text(
                    'Macronutrients',
                    style: TextStyle(
                      color: ColorsScheme.secondaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_proteinController, 'Protein (g)')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildTextField(_fatController, 'Fat (g)')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_fiberController, 'Fiber (g)')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildTextField(_omega3Controller, 'Omega-3 (mg)')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(_omega6Controller, 'Omega-6 (mg)'),
                  const SizedBox(height: 16),
                  
                  // Vitamins
                  Text(
                    'Vitamins',
                    style: TextStyle(
                      color: ColorsScheme.secondaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_vitaminAController, 'Vitamin A (IU)')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildTextField(_vitaminBController, 'Vitamin B (mg)')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_vitaminCController, 'Vitamin C (mg)')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildTextField(_vitaminDController, 'Vitamin D (IU)')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(_vitaminEController, 'Vitamin E (mg)'),
                  const SizedBox(height: 16),
                  
                  // Minerals
                  Text(
                    'Minerals',
                    style: TextStyle(
                      color: ColorsScheme.secondaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_calciumController, 'Calcium (mg)')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildTextField(_phosphorusController, 'Phosphorus (mg)')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_ironController, 'Iron (mg)')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildTextField(_zincController, 'Zinc (mg)')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(_magnesiumController, 'Magnesium (mg)'),
                  const SizedBox(height: 16),
                  
                  // Special Nutrients
                  Text(
                    'Special Nutrients',
                    style: TextStyle(
                      color: ColorsScheme.secondaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_taurineController, 'Taurine (mg)')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildTextField(_glucosamineController, 'Glucosamine (mg)')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_chondroitinController, 'Chondroitin (mg)')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildTextField(_probioticsController, 'Probiotics (CFU)')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addIngredient,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorsScheme.primaryIconColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Add Ingredient',
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
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
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
      keyboardType: label.contains('Name') || label.contains('Ingredient') 
          ? TextInputType.text 
          : TextInputType.numberWithOptions(decimal: true),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      style: TextStyle(color: ColorsScheme.primaryTextColor),
      decoration: InputDecoration(
        labelText: 'Category',
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
      items: _categories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(
            category,
            style: TextStyle(color: ColorsScheme.primaryTextColor),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value!;
          // Update unit to first available unit for the new category
          _selectedUnit = _categoryUnits[_selectedCategory]!.first;
        });
      },
    );
  }

  void _addIngredient() async {
    if (_nameController.text.trim().isEmpty) {
      _showErrorDialog('Please enter ingredient name');
      return;
    }

    try {
      // Helper function to get nutrition value or null if empty
      double? getNutritionValue(TextEditingController controller) {
        final text = controller.text.trim();
        if (text.isEmpty) return null;
        return double.tryParse(text);
      }

      // Build nutrition map with only filled values
      Map<String, dynamic> nutritionMap = {};
      
      final nutritionFields = {
        'protein': _proteinController,
        'fat': _fatController,
        'fiber': _fiberController,
        'omega3': _omega3Controller,
        'omega6': _omega6Controller,
        'vitaminA': _vitaminAController,
        'vitaminBComplex': _vitaminBController,
        'vitaminC': _vitaminCController,
        'vitaminD': _vitaminDController,
        'vitaminE': _vitaminEController,
        'calcium': _calciumController,
        'phosphorus': _phosphorusController,
        'iron': _ironController,
        'zinc': _zincController,
        'taurine': _taurineController,
        'magnesium': _magnesiumController,
        'glucosamine': _glucosamineController,
        'chondroitin': _chondroitinController,
        'probiotics': _probioticsController,
      };

      // Only add nutrition values that are filled
      nutritionFields.forEach((key, controller) {
        final value = getNutritionValue(controller);
        if (value != null) {
          nutritionMap[key] = value;
        }
      });

      Map<String, dynamic> ingredientData = {
        'name': _nameController.text.trim(),
        'category': _selectedCategory,
        'pricePerUnit': double.tryParse(_priceController.text) ?? 0.0,
        'stock': int.tryParse(_stockController.text) ?? 0,
        'unit': _selectedUnit,
        'availability': _isAvailable,
        'isAllergen': _isAllergen,
        'nutrition': nutritionMap.isNotEmpty ? nutritionMap : {},
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add image if selected
      if (_imageBase64 != null) {
        ingredientData['imageBase64'] = _imageBase64;
      }

      await FirebaseFirestore.instance.collection('ingredients').add(ingredientData);

      _clearForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingredient added successfully!')),
      );
    } catch (e) {
      _showErrorDialog('Error adding ingredient: $e');
    }
  }

  void _clearForm() {
    _nameController.clear();
    _proteinController.clear();
    _fatController.clear();
    _fiberController.clear();
    _omega3Controller.clear();
    _omega6Controller.clear();
    _vitaminAController.clear();
    _vitaminBController.clear();
    _vitaminCController.clear();
    _vitaminDController.clear();
    _vitaminEController.clear();
    _calciumController.clear();
    _phosphorusController.clear();
    _ironController.clear();
    _zincController.clear();
    _taurineController.clear();
    _magnesiumController.clear();
    _glucosamineController.clear();
    _chondroitinController.clear();
    _probioticsController.clear();
    _priceController.clear();
    _stockController.clear();
    setState(() {
      _selectedCategory = 'Food';
      _selectedUnit = 'kg';
      _isAvailable = true;
      _isAllergen = false;
      _selectedImage = null;
      _imageBase64 = null;
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

  // Image Picker Widget
  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingredient Image',
          style: TextStyle(
            color: ColorsScheme.secondaryTextColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: ColorsScheme.primaryBackgroundColor,
            border: Border.all(
              color: ColorsScheme.secondaryTextColor.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _selectedImage != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImage!,
                        width: double.infinity,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImage = null;
                            _imageBase64 = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : GestureDetector(
                  onTap: _pickImage,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 40,
                        color: ColorsScheme.secondaryTextColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to add image',
                        style: TextStyle(
                          color: ColorsScheme.secondaryTextColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  // Stock Quantity with Unit Selector
  Widget _buildStockWithUnit() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stock Quantity',
          style: TextStyle(
            color: ColorsScheme.secondaryTextColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _stockController,
                style: TextStyle(color: ColorsScheme.primaryTextColor),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  labelStyle: TextStyle(color: ColorsScheme.secondaryTextColor),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: ColorsScheme.secondaryTextColor.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: ColorsScheme.primaryIconColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: ColorsScheme.primaryBackgroundColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                value: _selectedUnit,
                style: TextStyle(color: ColorsScheme.primaryTextColor),
                decoration: InputDecoration(
                  labelText: 'Unit',
                  labelStyle: TextStyle(color: ColorsScheme.secondaryTextColor),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: ColorsScheme.secondaryTextColor.withOpacity(0.3),
                    ),
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
                items: _categoryUnits[_selectedCategory]!.map((unit) {
                  return DropdownMenuItem(
                    value: unit,
                    child: Text(
                      unit,
                      style: TextStyle(color: ColorsScheme.primaryTextColor),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedUnit = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Image Picker Function
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      
      if (image != null) {
        final File imageFile = File(image.path);
        final Uint8List imageBytes = await imageFile.readAsBytes();
        final String base64Image = base64Encode(imageBytes);
        
        setState(() {
          _selectedImage = imageFile;
          _imageBase64 = base64Image;
        });
      }
    } catch (e) {
      _showErrorDialog('Error picking image: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _omega3Controller.dispose();
    _omega6Controller.dispose();
    _vitaminAController.dispose();
    _vitaminBController.dispose();
    _vitaminCController.dispose();
    _vitaminDController.dispose();
    _vitaminEController.dispose();
    _calciumController.dispose();
    _phosphorusController.dispose();
    _ironController.dispose();
    _zincController.dispose();
    _taurineController.dispose();
    _magnesiumController.dispose();
    _glucosamineController.dispose();
    _chondroitinController.dispose();
    _probioticsController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }
}
