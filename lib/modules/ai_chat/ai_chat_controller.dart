import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../services/app/gemini_service.dart';
import '../../services/app/settings_service.dart';
import '../../utils/date_utils.dart';

class AiChatController extends GetxController {
  final ChatRepository _chatRepo = Get.find<ChatRepository>();
  final GeminiService _gemini = Get.find<GeminiService>();
  final SettingsService _settings = Get.find<SettingsService>();
  final CategoryRepository _categoryRepo = Get.find<CategoryRepository>();
  final TransactionRepository _transactionRepo = Get.find<TransactionRepository>();

  final messages = <ChatMessageModel>[].obs;
  final isTyping = false.obs;

  /// Max characters accepted by the proxy — mirrored by the input field.
  static const int maxMessageLength = 2000;

  static const List<String> quickPrompts = [
    'Analyze my budget',
    'Saving tips',
    'Where am I overspending?',
    'How to reduce expenses?',
  ];

  @override
  void onInit() {
    super.onInit();
    _chatRepo.getMessages().listen((list) => messages.assignAll(list));
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final outgoing = text.trim();

    // Snapshot the conversation BEFORE persisting the outgoing message: the
    // request contract wants the history that precedes it, and `messages` is
    // repopulated asynchronously by the Firestore listener.
    final priorHistory = List<ChatMessageModel>.from(messages);

    final userMsg = ChatMessageModel(
      id: const Uuid().v4(),
      message: outgoing,
      isUser: true,
      timestamp: DateTime.now(),
    );
    await _chatRepo.addMessage(userMsg);

    isTyping.value = true;
    try {
      final String response;
      if (_isInsightQuery(outgoing)) {
        response = await _generateInsights();
      } else {
        response = await _gemini.generateResponse(outgoing, priorHistory);
      }

      // Only a real answer is persisted — a failure must never look like a reply.
      final aiMsg = ChatMessageModel(
        id: const Uuid().v4(),
        message: response,
        isUser: false,
        timestamp: DateTime.now(),
      );
      await _chatRepo.addMessage(aiMsg);
    } on AiApiException catch (e) {
      _showError(_errorMessageFor(e.kind));
    } catch (_) {
      _showError('Something went wrong. Please try again.');
    } finally {
      isTyping.value = false;
    }
  }

  /// Routing rule frozen with the web surface: only this exact phrase reaches
  /// `/api/insights`; every other prompt (including the other quick prompts)
  /// is a plain chat turn.
  bool _isInsightQuery(String text) {
    final lower = text.toLowerCase();
    return lower.contains('analyze my budget') ||
        lower.contains('analyse my budget');
  }

  Future<String> _generateInsights() async {
    final currentMonth = _settings.currentMonth.value.isNotEmpty
        ? _settings.currentMonth.value
        : AppDateUtils.getCurrentMonthKey();

    // Month-scoped categories only: getCategories() spans every auto-cloned
    // month and inflates totalBudget.
    final categories = await _categoryRepo.getCategoriesForMonth(currentMonth);
    final transactions = await _transactionRepo.getTransactions().first;

    final monthTx = transactions
        .where((t) => AppDateUtils.getMonthKeyFromDate(t.date) == currentMonth)
        .toList();

    final rows = categories.map((cat) {
      final spent = monthTx
          .where((t) => t.categoryId == cat.id)
          .fold(0.0, (s, t) => s + t.amount);
      return <String, dynamic>{
        'name': cat.name,
        'budgetLimit': cat.budgetLimit,
        'spent': spent,
      };
    }).toList()
      ..sort((a, b) => (b['spent'] as double).compareTo(a['spent'] as double));

    final truncatedCount = rows.length > GeminiService.maxInsightCategories
        ? rows.length - GeminiService.maxInsightCategories
        : 0;
    final payload = truncatedCount > 0
        ? rows.sublist(0, GeminiService.maxInsightCategories)
        : rows;

    final totalSpent = monthTx.fold(0.0, (s, t) => s + t.amount);
    final totalBudget = categories.fold(0.0, (s, c) => s + c.budgetLimit);

    return _gemini.generateInsights(
      currencyCode: _settings.currencyCode.value,
      monthlyIncome: _settings.monthlyIncome.value,
      totalSpent: totalSpent,
      totalBudget: totalBudget,
      categories: payload,
      truncatedCount: truncatedCount,
      month: currentMonth,
    );
  }

  Future<void> clearChat() async {
    await _chatRepo.deleteAllMessages();
    _gemini.resetChat();
  }

  String _errorMessageFor(AiApiErrorKind kind) {
    switch (kind) {
      case AiApiErrorKind.notConfigured:
        return "AI isn't configured in this build.";
      case AiApiErrorKind.notSignedIn:
      case AiApiErrorKind.unauthorized:
        return 'Please sign in again.';
      case AiApiErrorKind.quotaExceeded:
        return 'Daily AI limit reached — try again tomorrow.';
      case AiApiErrorKind.badRequest:
        return 'Message is too long.';
      case AiApiErrorKind.unavailable:
        return 'AI service is unavailable right now.';
    }
  }

  void _showError(String message) {
    Get.snackbar('AI Advisor', message,
        snackPosition: SnackPosition.BOTTOM);
  }
}
