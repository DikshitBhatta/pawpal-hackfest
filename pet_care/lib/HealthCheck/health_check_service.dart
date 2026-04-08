import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:pet_care/apiKey.dart';

/// Service for dog health analysis using Gemini AI
class HealthCheckService {
  // Using gemini-2.0-flash for health analysis
  static final _model = GenerativeModel(
    model: 'gemini-2.0-flash',
    apiKey: GEMINIAPI,
  );

  /// Symptom keywords database for quick matching
  static final Map<String, List<String>> _symptomDatabase = {
    'skin_issues': [
      'itching',
      'scratching',
      'rash',
      'redness',
      'hair loss',
      'bald spots',
      'dry skin',
      'flaky'
    ],
    'digestive': [
      'vomiting',
      'diarrhea',
      'not eating',
      'loss of appetite',
      'constipation',
      'bloating'
    ],
    'respiratory': [
      'coughing',
      'sneezing',
      'wheezing',
      'difficulty breathing',
      'runny nose'
    ],
    'mobility': [
      'limping',
      'stiffness',
      'not walking',
      'pain',
      'swelling',
      'joint'
    ],
    'behavioral': [
      'lethargy',
      'tired',
      'restless',
      'anxious',
      'aggressive',
      'hiding'
    ],
    'eye_ear': [
      'red eyes',
      'discharge',
      'ear scratching',
      'head shaking',
      'swollen ear'
    ],
    'food_safety': [
      'chocolate',
      'grapes',
      'onion',
      'garlic',
      'xylitol',
      'avocado',
      'alcohol',
      'caffeine'
    ],
  };

  /// Possible conditions based on symptom categories
  static final Map<String, List<String>> _possibleConditions = {
    'skin_issues': ['Allergies', 'Fleas/Parasites', 'Skin Infection', 'Mange'],
    'digestive': [
      'Food Intolerance',
      'Gastritis',
      'Parasites',
      'Dietary Indiscretion'
    ],
    'respiratory': [
      'Kennel Cough',
      'Allergies',
      'Respiratory Infection',
      'Heart Issues'
    ],
    'mobility': ['Arthritis', 'Injury', 'Hip Dysplasia', 'Muscle Strain'],
    'behavioral': ['Illness', 'Pain', 'Anxiety', 'Depression'],
    'eye_ear': [
      'Ear Infection',
      'Conjunctivitis',
      'Allergies',
      'Foreign Object'
    ],
    'food_safety': ['Toxicity Risk', 'Poisoning'],
  };

  /// Extract symptom keywords from user input
  static Map<String, dynamic> extractSymptoms(String input) {
    final lowerInput = input.toLowerCase();
    List<String> matchedSymptoms = [];
    Set<String> matchedCategories = {};
    List<String> possibleCauses = [];

    for (var category in _symptomDatabase.entries) {
      for (var symptom in category.value) {
        if (lowerInput.contains(symptom)) {
          matchedSymptoms.add(symptom);
          matchedCategories.add(category.key);
        }
      }
    }

    // Get possible conditions
    for (var category in matchedCategories) {
      possibleCauses.addAll(_possibleConditions[category] ?? []);
    }

    // Remove duplicates
    possibleCauses = possibleCauses.toSet().toList();

    return {
      'symptoms': matchedSymptoms,
      'categories': matchedCategories.toList(),
      'possibleCauses': possibleCauses.take(3).toList(),
      'isFoodSafetyQuery': matchedCategories.contains('food_safety'),
    };
  }

  /// Analyze symptoms with Gemini AI
  static Future<Map<String, dynamic>> analyzeSymptoms({
    required String symptoms,
    String? dogName,
    String? dogAge,
    String? dogWeight,
    String? dogBreed,
    List<String>? allergies,
    File? image,
  }) async {
    try {
      // First extract keywords locally
      final extracted = extractSymptoms(symptoms);

      // Build dog profile
      final dogProfile = '''
Dog Profile:
- Name: ${dogName ?? 'Unknown'}
- Age: ${dogAge ?? 'Unknown'}
- Weight: ${dogWeight ?? 'Unknown'}
- Breed: ${dogBreed ?? 'Unknown'}
- Known Allergies: ${allergies?.join(', ') ?? 'None reported'}
''';

      // Check if it's a food safety query
      final isFoodQuery = extracted['isFoodSafetyQuery'] as bool;

      String prompt;
      if (isFoodQuery) {
        prompt = '''
$dogProfile

User Question: $symptoms

You are a veterinary health assistant. The user is asking about food safety for their dog.

Please respond in this EXACT JSON format:
{
  "query_type": "food_safety",
  "food_item": "the food being asked about",
  "is_safe": true/false,
  "toxicity_level": "safe/mild/moderate/severe",
  "possible_causes": ["list of why it's harmful if unsafe"],
  "home_care": ["what to do if dog ate it"],
  "warning_signs": ["symptoms to watch for"],
  "summary": "Brief 1-2 sentence summary"
}

Be accurate and helpful. If the food is toxic, clearly state the danger level.
''';
      } else {
        prompt = '''
$dogProfile

Reported Symptoms: $symptoms

Extracted Keywords: ${extracted['symptoms']}
Initial Assessment Categories: ${extracted['categories']}
Possible Causes (from keyword matching): ${extracted['possibleCauses']}

You are a veterinary health assistant. Analyze these symptoms and provide helpful guidance.

Please respond in this EXACT JSON format:
{
  "query_type": "health_check",
  "possible_causes": [
    {"name": "Condition Name", "likelihood": "high/medium/low", "description": "Brief explanation"}
  ],
  "home_care": [
    {"action": "What to do", "details": "How to do it"}
  ],
  "warning_signs": [
    {"sign": "What to watch for", "urgency": "immediate/soon/monitor"}
  ],
  "urgency_level": "emergency/urgent/moderate/low",
  "summary": "Brief 2-3 sentence summary of the situation"
}

Important:
- Be helpful but always recommend seeing a vet for serious concerns
- Provide practical home care steps
- Clearly indicate warning signs that need immediate attention
- Keep explanations simple and safe
''';
      }

      List<Content> content = [];

      // Add image if provided
      if (image != null) {
        final imageBytes = await image.readAsBytes();
        final imagePart = DataPart('image/jpeg', imageBytes);
        content.add(Content.multi([
          TextPart(prompt +
              "\n\nAlso analyze the attached image for visible health issues."),
          imagePart,
        ]));
      } else {
        content.add(Content.text(prompt));
      }

      final response = await _model.generateContent(content);

      if (response.text != null) {
        // Parse JSON response
        String jsonStr = _extractJson(response.text!);
        final result = json.decode(jsonStr) as Map<String, dynamic>;
        result['raw_extraction'] = extracted;
        result['success'] = true;
        return result;
      }

      return {
        'success': false,
        'error': 'No response from AI',
        'raw_extraction': extracted,
      };
    } catch (e) {
      print('Health check error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'raw_extraction': extractSymptoms(symptoms),
      };
    }
  }

  /// Extract JSON from response
  static String _extractJson(String response) {
    int start = response.indexOf('{');
    int end = response.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      String jsonStr = response.substring(start, end + 1);
      // Clean up common issues
      jsonStr = jsonStr.replaceAll(RegExp(r'//.*?(?=\n|$)'), '');
      jsonStr = jsonStr.replaceAll(RegExp(r',\s*}'), '}');
      jsonStr = jsonStr.replaceAll(RegExp(r',\s*]'), ']');
      return jsonStr;
    }
    throw Exception('No valid JSON found');
  }
}
