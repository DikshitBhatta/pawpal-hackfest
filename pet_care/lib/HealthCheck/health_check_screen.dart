import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet_care/ColorsScheme.dart';
import 'package:pet_care/HealthCheck/health_check_service.dart';

class HealthCheckScreen extends StatefulWidget {
  // Optional: Pass dog data for personalized analysis
  final String? dogName;
  final String? dogAge;
  final String? dogWeight;
  final String? dogBreed;
  final List<String>? allergies;

  const HealthCheckScreen({
    super.key,
    this.dogName,
    this.dogAge,
    this.dogWeight,
    this.dogBreed,
    this.allergies,
  });

  @override
  State<HealthCheckScreen> createState() => _HealthCheckScreenState();
}

class _HealthCheckScreenState extends State<HealthCheckScreen> {
  final TextEditingController _symptomController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;
  String? _errorMessage;

  @override
  void dispose() {
    _symptomController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: $e');
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff352F44),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Upload Image',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildImageOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xff5C5470),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Future<void> _analyzeSymptoms() async {
    if (_symptomController.text.trim().isEmpty && _selectedImage == null) {
      _showSnackBar('Please enter symptoms or upload an image');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _analysisResult = null;
    });

    try {
      final result = await HealthCheckService.analyzeSymptoms(
        symptoms: _symptomController.text,
        dogName: widget.dogName ?? 'Your dog',
        dogAge: widget.dogAge,
        dogWeight: widget.dogWeight,
        dogBreed: widget.dogBreed,
        allergies: widget.allergies,
        image: _selectedImage,
      );

      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Analysis failed: $e';
        _isAnalyzing = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xff5C5470),
      ),
    );
  }

  void _clearAll() {
    setState(() {
      _symptomController.clear();
      _selectedImage = null;
      _analysisResult = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🩺 Health Check',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: appBarColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_analysisResult != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _clearAll,
              tooltip: 'New Check',
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: backgroundColor),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                _buildHeaderCard(),
                const SizedBox(height: 20),

                // Input Section
                _buildInputSection(),
                const SizedBox(height: 20),

                // Image Preview
                if (_selectedImage != null) _buildImagePreview(),

                // Analyze Button
                _buildAnalyzeButton(),
                const SizedBox(height: 20),

                // Results Section
                if (_isAnalyzing) _buildLoadingIndicator(),
                if (_errorMessage != null) _buildErrorCard(),
                if (_analysisResult != null &&
                    _analysisResult!['success'] == true)
                  _buildResultsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: cardColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.pets, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.dogName != null
                      ? "${widget.dogName}'s Health Check"
                      : "Dog Health Check",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Describe symptoms or ask about food safety',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff352F44),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xff5C5470), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Describe the symptoms',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _symptomController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText:
                  'e.g., "Max is scratching and losing hair" or "Can my dog eat chocolate?"',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              filled: true,
              fillColor: const Color(0xff2A2438),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showImagePicker,
                  icon: const Icon(Icons.add_a_photo, size: 20),
                  label: Text(_selectedImage != null
                      ? 'Change Image'
                      : 'Add Image (Optional)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xff8476AA)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xff5C5470), width: 2),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Image.file(
              _selectedImage!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() => _selectedImage = null),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isAnalyzing ? null : _analyzeSymptoms,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isAnalyzing ? Icons.hourglass_top : Icons.search,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Text(
              _isAnalyzing ? 'Analyzing...' : '🔍 Analyze Symptoms',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xff8476AA)),
          ),
          const SizedBox(height: 16),
          Text(
            'Analyzing with AI...',
            style: TextStyle(color: Colors.grey.shade300),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    final result = _analysisResult!;
    final queryType = result['query_type'] ?? 'health_check';

    return Column(
      children: [
        // Summary Card
        _buildSummaryCard(result),
        const SizedBox(height: 16),

        // Possible Causes Section
        if (result['possible_causes'] != null)
          _buildSectionCard(
            icon: Icons.help_outline,
            iconColor: Colors.amber,
            title: queryType == 'food_safety'
                ? '⚠️ Why It\'s Harmful'
                : '🟡 Possible Causes',
            child: _buildCausesList(result['possible_causes']),
          ),
        const SizedBox(height: 12),

        // Home Care Section
        if (result['home_care'] != null)
          _buildSectionCard(
            icon: Icons.home,
            iconColor: Colors.green,
            title: '🏠 What You Can Do',
            child: _buildHomeCareList(result['home_care']),
          ),
        const SizedBox(height: 12),

        // Warning Signs Section
        if (result['warning_signs'] != null)
          _buildSectionCard(
            icon: Icons.warning_amber,
            iconColor: Colors.red,
            title: '🚨 When to See a Vet',
            child: _buildWarningsList(result['warning_signs']),
          ),
        const SizedBox(height: 20),

        // Disclaimer
        _buildDisclaimer(),
      ],
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> result) {
    final urgency = result['urgency_level'] ?? 'moderate';
    final queryType = result['query_type'];

    Color urgencyColor;
    IconData urgencyIcon;

    if (queryType == 'food_safety') {
      final toxicity = result['toxicity_level'] ?? 'unknown';
      urgencyColor = toxicity == 'severe'
          ? Colors.red
          : toxicity == 'moderate'
              ? Colors.orange
              : toxicity == 'mild'
                  ? Colors.yellow
                  : Colors.green;
      urgencyIcon =
          result['is_safe'] == true ? Icons.check_circle : Icons.dangerous;
    } else {
      urgencyColor = urgency == 'emergency'
          ? Colors.red
          : urgency == 'urgent'
              ? Colors.orange
              : urgency == 'moderate'
                  ? Colors.yellow
                  : Colors.green;
      urgencyIcon = urgency == 'emergency' || urgency == 'urgent'
          ? Icons.warning
          : Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff5C5470), Color(0xff8476AA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: urgencyColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(urgencyIcon, color: urgencyColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  queryType == 'food_safety'
                      ? 'Food Safety Analysis'
                      : 'Health Analysis Complete',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result['summary'] ?? 'Analysis completed.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff352F44),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xff5C5470).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xff2A2438),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildCausesList(dynamic causes) {
    if (causes is List) {
      return Column(
        children: causes.map<Widget>((cause) {
          if (cause is Map) {
            return _buildListItem(
              title: cause['name'] ?? cause.toString(),
              subtitle: cause['description'],
              badge: cause['likelihood'],
            );
          }
          return _buildListItem(title: cause.toString());
        }).toList(),
      );
    }
    return _buildListItem(title: causes.toString());
  }

  Widget _buildHomeCareList(dynamic homeCare) {
    if (homeCare is List) {
      return Column(
        children: homeCare.map<Widget>((item) {
          if (item is Map) {
            return _buildListItem(
              title: item['action'] ?? item.toString(),
              subtitle: item['details'],
              icon: Icons.check_circle_outline,
              iconColor: Colors.green,
            );
          }
          return _buildListItem(
            title: item.toString(),
            icon: Icons.check_circle_outline,
            iconColor: Colors.green,
          );
        }).toList(),
      );
    }
    return _buildListItem(title: homeCare.toString());
  }

  Widget _buildWarningsList(dynamic warnings) {
    if (warnings is List) {
      return Column(
        children: warnings.map<Widget>((warning) {
          if (warning is Map) {
            final urgency = warning['urgency'] ?? 'monitor';
            return _buildListItem(
              title: warning['sign'] ?? warning.toString(),
              icon: Icons.error_outline,
              iconColor: urgency == 'immediate' ? Colors.red : Colors.orange,
              badge: urgency,
            );
          }
          return _buildListItem(
            title: warning.toString(),
            icon: Icons.error_outline,
            iconColor: Colors.orange,
          );
        }).toList(),
      );
    }
    return _buildListItem(title: warnings.toString());
  }

  Widget _buildListItem({
    required String title,
    String? subtitle,
    String? badge,
    IconData icon = Icons.circle,
    Color iconColor = const Color(0xff8476AA),
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getBadgeColor(badge),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getBadgeColor(String badge) {
    switch (badge.toLowerCase()) {
      case 'high':
      case 'immediate':
      case 'severe':
        return Colors.red;
      case 'medium':
      case 'soon':
      case 'urgent':
      case 'moderate':
        return Colors.orange;
      case 'low':
      case 'monitor':
      case 'mild':
        return Colors.green;
      default:
        return const Color(0xff8476AA);
    }
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This is AI-powered guidance only. Always consult a veterinarian for proper diagnosis and treatment.',
              style: TextStyle(
                color: Colors.blue.shade200,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
