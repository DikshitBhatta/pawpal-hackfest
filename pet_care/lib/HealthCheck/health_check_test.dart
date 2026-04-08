import 'package:flutter/material.dart';
import 'package:pet_care/ColorsScheme.dart';
import 'package:pet_care/HealthCheck/health_check_screen.dart';

/// Test launcher for the Health Check feature
/// Run this to test without integrating into main app
class HealthCheckTestLauncher extends StatelessWidget {
  const HealthCheckTestLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🧪 Health Check Test',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: appBarColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: backgroundColor),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Icon
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    gradient: cardColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.health_and_safety,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),

                // Title
                const Text(
                  'Dog Health Check',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'AI-Powered Health Analysis',
                  style: TextStyle(
                    color: Colors.grey.shade300,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),

                // Test Scenarios
                _buildTestScenario(
                  context,
                  icon: Icons.pets,
                  title: 'Test with Demo Dog',
                  subtitle: 'Max - 2 years, 15kg Golden Retriever',
                  onTap: () => _launchHealthCheck(context, withDogData: true),
                ),
                const SizedBox(height: 16),

                _buildTestScenario(
                  context,
                  icon: Icons.search,
                  title: 'Test without Dog Data',
                  subtitle: 'General health check mode',
                  onTap: () => _launchHealthCheck(context, withDogData: false),
                ),
                const SizedBox(height: 40),

                // Demo suggestions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xff352F44).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '💡 Try these test queries:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildSuggestion('• "Max is scratching and losing hair"'),
                      _buildSuggestion('• "Can my dog eat chocolate?"'),
                      _buildSuggestion('• "My dog is vomiting and not eating"'),
                      _buildSuggestion('• "Dog limping on back leg"'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestScenario(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestion(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade300,
          fontSize: 13,
        ),
      ),
    );
  }

  void _launchHealthCheck(BuildContext context, {required bool withDogData}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthCheckScreen(
          dogName: withDogData ? 'Max' : null,
          dogAge: withDogData ? '2 years' : null,
          dogWeight: withDogData ? '15kg' : null,
          dogBreed: withDogData ? 'Golden Retriever' : null,
          allergies: withDogData ? ['chicken'] : null,
        ),
      ),
    );
  }
}

/// Standalone main to test Health Check feature
/// Run with: flutter run -t lib/HealthCheck/health_check_test.dart
void main() {
  runApp(const HealthCheckTestApp());
}

class HealthCheckTestApp extends StatelessWidget {
  const HealthCheckTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Check Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xff2A2438),
      ),
      home: const HealthCheckTestLauncher(),
    );
  }
}
