import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ColorsScheme {
  static const Color primaryBackgroundColor = Color(0xff2A2438);
  static const Color secondaryBackgroundColor = Color(0xff352F44);
  static const Color primaryTextColor = Color(0xffFFFFFF);
  static const Color secondaryTextColor = Color(0xffB0A0D6);
  static const Color primaryIconColor = Color(0xff8476AA);
}

class AIRuleMapping extends StatefulWidget {
  const AIRuleMapping({Key? key}) : super(key: key);

  @override
  _AIRuleMappingState createState() => _AIRuleMappingState();
}

class _AIRuleMappingState extends State<AIRuleMapping> {
  final TextEditingController _ruleNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priorityController = TextEditingController();
  
  String _selectedCondition = 'Weight Loss';
  String _selectedDogSize = 'Small';
  String _selectedActivityLevel = 'Low';
  
  List<String> _conditions = ['Weight Loss', 'Weight Gain', 'Maintain Weight', 'Puppy Growth', 'Senior Care', 'Allergies'];
  List<String> _dogSizes = ['Small', 'Medium', 'Large'];
  List<String> _activityLevels = ['Low', 'Medium', 'High'];
  List<String> _selectedRecommendations = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsScheme.primaryBackgroundColor,
      appBar: AppBar(
        backgroundColor: ColorsScheme.primaryBackgroundColor,
        title: Text(
          'AI Rule Mapping',
          style: TextStyle(
            color: ColorsScheme.primaryTextColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: ColorsScheme.primaryIconColor),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Create AI Rule Form - Fixed height
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ColorsScheme.secondaryBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create AI Rule',
                        style: TextStyle(
                          color: ColorsScheme.primaryTextColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(_ruleNameController, 'Rule Name'),
                      const SizedBox(height: 12),
                      _buildTextField(_descriptionController, 'Description', maxLines: 2),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildDropdown('Health Condition', _selectedCondition, _conditions, (value) {
                            setState(() {
                              _selectedCondition = value!;
                            });
                          })),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField(_priorityController, 'Priority (1-10)')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildDropdown('Dog Size', _selectedDogSize, _dogSizes, (value) {
                            setState(() {
                              _selectedDogSize = value!;
                            });
                          })),
                          const SizedBox(width: 12),
                          Expanded(child: _buildDropdown('Activity Level', _selectedActivityLevel, _activityLevels, (value) {
                            setState(() {
                              _selectedActivityLevel = value!;
                            });
                          })),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Meal Recommendations (${_selectedRecommendations.length})',
                              style: TextStyle(
                                color: ColorsScheme.primaryTextColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _showMealPresetPicker,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorsScheme.primaryIconColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Add Meal',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildSelectedRecommendations(),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _createAIRule,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorsScheme.primaryIconColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Create AI Rule',
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
              ),
            ),
            const SizedBox(height: 16),
            
            // Existing AI Rules - Fixed height to prevent overflow
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: ColorsScheme.secondaryBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'AI Rules',
                              style: TextStyle(
                                color: ColorsScheme.primaryTextColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _testAIRecommendation,
                            icon: Icon(Icons.psychology, color: ColorsScheme.primaryIconColor),
                            label: Text(
                              'Test AI',
                              style: TextStyle(color: ColorsScheme.primaryIconColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('ai_rules')
                              .orderBy('priority', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            
                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return Center(
                                child: Text(
                                  'No AI rules created yet',
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
                                    color: ColorsScheme.primaryBackgroundColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ExpansionTile(
                                    title: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: ColorsScheme.primaryIconColor,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'P${data['priority'] ?? 0}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            data['ruleName'] ?? 'Unknown Rule',
                                            style: TextStyle(
                                              color: ColorsScheme.primaryTextColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      '${data['condition']} • ${data['dogSize']} • ${data['activityLevel']} Activity',
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
                                              'Recommended Meals:',
                                              style: TextStyle(
                                                color: ColorsScheme.primaryTextColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            ...((data['recommendations'] as List?) ?? []).map((meal) {
                                              return Text(
                                                '• $meal',
                                                style: TextStyle(
                                                  color: ColorsScheme.secondaryTextColor,
                                                ),
                                              );
                                            }).toList(),
                                            const SizedBox(height: 16),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Active: ${data['isActive'] ?? true ? 'Yes' : 'No'}',
                                                  style: TextStyle(
                                                    color: (data['isActive'] ?? true)
                                                        ? Colors.green
                                                        : Colors.red,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    TextButton(
                                                      onPressed: () => _toggleRuleStatus(doc.id, !(data['isActive'] ?? true)),
                                                      child: Text(
                                                        (data['isActive'] ?? true) ? 'Disable' : 'Enable',
                                                        style: TextStyle(color: ColorsScheme.primaryIconColor),
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () => _deleteAIRule(doc.id),
                                                      child: Text(
                                                        'Delete',
                                                        style: TextStyle(color: Colors.red[400]),
                                                      ),
                                                    ),
                                                  ],
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
            ),
          ],
        ),
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
      keyboardType: label.contains('Priority') ? TextInputType.number : TextInputType.text,
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
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

  Widget _buildSelectedRecommendations() {
    if (_selectedRecommendations.isEmpty) {
      return Text(
        'No meal recommendations selected',
        style: TextStyle(
          color: ColorsScheme.secondaryTextColor,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      children: _selectedRecommendations.map((meal) {
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
                  meal,
                  style: TextStyle(color: ColorsScheme.primaryTextColor),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedRecommendations.remove(meal);
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

  void _showMealPresetPicker() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('meal_presets')
        .orderBy('name')
        .get();

    if (snapshot.docs.isEmpty) {
      _showErrorDialog('No meal presets available. Please create meal presets first.');
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ColorsScheme.secondaryBackgroundColor,
          title: Text(
            'Select Meal Preset',
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
                    '${data['dogSize']} • ${data['mealType']}',
                    style: TextStyle(color: ColorsScheme.secondaryTextColor),
                  ),
                  onTap: () {
                    if (!_selectedRecommendations.contains(data['name'])) {
                      setState(() {
                        _selectedRecommendations.add(data['name']);
                      });
                    }
                    Navigator.pop(context);
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

  void _createAIRule() async {
    if (_ruleNameController.text.trim().isEmpty) {
      _showErrorDialog('Please enter rule name');
      return;
    }

    if (_selectedRecommendations.isEmpty) {
      _showErrorDialog('Please add at least one meal recommendation');
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('ai_rules').add({
        'ruleName': _ruleNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'condition': _selectedCondition,
        'dogSize': _selectedDogSize,
        'activityLevel': _selectedActivityLevel,
        'priority': int.tryParse(_priorityController.text) ?? 1,
        'recommendations': _selectedRecommendations,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _clearForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI rule created successfully!')),
      );
    } catch (e) {
      _showErrorDialog('Error creating AI rule: $e');
    }
  }

  void _toggleRuleStatus(String docId, bool newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('ai_rules').doc(docId).update({
        'isActive': newStatus,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rule ${newStatus ? 'enabled' : 'disabled'} successfully!')),
      );
    } catch (e) {
      _showErrorDialog('Error updating rule status: $e');
    }
  }

  void _deleteAIRule(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('ai_rules').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI rule deleted successfully!')),
      );
    } catch (e) {
      _showErrorDialog('Error deleting AI rule: $e');
    }
  }

  void _testAIRecommendation() {
    showDialog(
      context: context,
      builder: (context) {
        String testCondition = 'Weight Loss';
        String testDogSize = 'Medium';
        String testActivity = 'Medium';
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: ColorsScheme.secondaryBackgroundColor,
              title: Text(
                'Test AI Recommendation',
                style: TextStyle(color: ColorsScheme.primaryTextColor),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDropdown('Condition', testCondition, _conditions, (value) {
                    setDialogState(() {
                      testCondition = value!;
                    });
                  }),
                  const SizedBox(height: 12),
                  _buildDropdown('Dog Size', testDogSize, _dogSizes, (value) {
                    setDialogState(() {
                      testDogSize = value!;
                    });
                  }),
                  const SizedBox(height: 12),
                  _buildDropdown('Activity Level', testActivity, _activityLevels, (value) {
                    setDialogState(() {
                      testActivity = value!;
                    });
                  }),
                ],
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
                  onPressed: () => _runAITest(testCondition, testDogSize, testActivity),
                  child: Text(
                    'Test',
                    style: TextStyle(color: ColorsScheme.primaryIconColor),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _runAITest(String condition, String dogSize, String activity) async {
    Navigator.pop(context);
    
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('ai_rules')
          .where('condition', isEqualTo: condition)
          .where('dogSize', isEqualTo: dogSize)
          .where('activityLevel', isEqualTo: activity)
          .where('isActive', isEqualTo: true)
          .orderBy('priority', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        _showErrorDialog('No matching AI rules found for the specified criteria.');
        return;
      }

      final data = snapshot.docs.first.data() as Map<String, dynamic>;
      final recommendations = (data['recommendations'] as List).cast<String>();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: ColorsScheme.secondaryBackgroundColor,
          title: Text(
            'AI Recommendation Result',
            style: TextStyle(color: ColorsScheme.primaryTextColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rule: ${data['ruleName']}',
                style: TextStyle(
                  color: ColorsScheme.primaryTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Priority: ${data['priority']}',
                style: TextStyle(color: ColorsScheme.secondaryTextColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Recommended Meals:',
                style: TextStyle(
                  color: ColorsScheme.primaryTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ...recommendations.map((meal) => Text(
                '• $meal',
                style: TextStyle(color: ColorsScheme.secondaryTextColor),
              )).toList(),
            ],
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
    } catch (e) {
      _showErrorDialog('Error running AI test: $e');
    }
  }

  void _clearForm() {
    _ruleNameController.clear();
    _descriptionController.clear();
    _priorityController.clear();
    setState(() {
      _selectedCondition = 'Weight Loss';
      _selectedDogSize = 'Small';
      _selectedActivityLevel = 'Low';
      _selectedRecommendations.clear();
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorsScheme.secondaryBackgroundColor,
        title: Text(
          'Message',
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
    _ruleNameController.dispose();
    _descriptionController.dispose();
    _priorityController.dispose();
    super.dispose();
  }
}
