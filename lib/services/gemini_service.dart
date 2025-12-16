import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for Google Gemini AI integration
class GeminiService extends GetxService {
  late GenerativeModel _model;
  late ChatSession _chatSession;

  // Load API key from environment variables (.env file)
  // This keeps the key secure and out of version control
  String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  final isInitialized = false.obs;
  final lastError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeGemini();
  }

  void _initializeGemini() {
    try {
      // Initialize Gemini model
      _model = GenerativeModel(
        model: 'gemini-2.0-flash-exp',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        ),
        systemInstruction: Content.system(
          'You are a helpful AI financial advisor for a budget management app called "Budget Buddy". '
          'Provide concise, practical advice about budgeting, saving, and expense management. '
          'Be friendly, encouraging, and supportive. Keep responses under 150 words unless asked for detailed analysis. '
          'Focus on actionable tips and positive reinforcement.',
        ),
      );

      // Start chat session
      _chatSession = _model.startChat();

      isInitialized.value = true;
      lastError.value = '';
    } catch (e) {
      lastError.value = 'Failed to initialize AI: $e';
      isInitialized.value = false;
    }
  }

  /// Generate AI response for user message
  Future<String> generateResponse(String userMessage) async {
    if (!isInitialized.value) {
      return 'AI service is not available. Please check your API key configuration.';
    }

    try {
      final response = await _chatSession.sendMessage(
        Content.text(userMessage),
      );

      return response.text ?? 'Sorry, I couldn\'t generate a response.';
    } catch (e) {
      lastError.value = e.toString();
      return 'Sorry, I encountered an error: ${e.toString()}';
    }
  }

  /// Generate financial insights based on spending data
  Future<String> generateInsights({
    required double monthlyIncome,
    required double totalSpent,
    required double totalBudget,
    required List<Map<String, dynamic>> categorySpending,
  }) async {
    if (!isInitialized.value) {
      return 'AI insights are not available.';
    }

    try {
      final prompt = '''
Analyze this monthly budget data and provide 3-4 key insights:

Monthly Income: \$${monthlyIncome.toStringAsFixed(2)}
Total Budget Allocated: \$${totalBudget.toStringAsFixed(2)}
Total Spent: \$${totalSpent.toStringAsFixed(2)}
Remaining: \$${(monthlyIncome - totalSpent).toStringAsFixed(2)}

Category Breakdown:
${categorySpending.map((cat) => '- ${cat['name']}: Spent \$${cat['spent']} / Budget \$${cat['budget']} (${cat['percentage']}%)').join('\n')}

Provide:
1. Overall spending health assessment
2. Top spending category concern (if any)
3. One actionable recommendation
4. Positive encouragement

Keep it concise and friendly.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Unable to generate insights.';
    } catch (e) {
      return 'Error generating insights: ${e.toString()}';
    }
  }

  /// Get quick financial advice for specific query
  Future<String> getQuickAdvice(String query) async {
    if (!isInitialized.value) {
      return 'AI service is not available.';
    }

    try {
      final prompt = 'As a financial advisor, briefly answer: $query';
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Unable to provide advice.';
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  /// Reset chat session
  void resetChat() {
    if (isInitialized.value) {
      _chatSession = _model.startChat();
    }
  }
}
