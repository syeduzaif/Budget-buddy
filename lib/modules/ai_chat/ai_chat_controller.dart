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

    final userMsg = ChatMessageModel(
      id: const Uuid().v4(),
      message: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );
    await _chatRepo.addMessage(userMsg);

    isTyping.value = true;
    try {
      String response;
      if (_isInsightQuery(text)) {
        response = await _generateInsights();
      } else {
        response = await _gemini.generateResponse(text.trim());
      }

      final aiMsg = ChatMessageModel(
        id: const Uuid().v4(),
        message: response,
        isUser: false,
        timestamp: DateTime.now(),
      );
      await _chatRepo.addMessage(aiMsg);
    } finally {
      isTyping.value = false;
    }
  }

  bool _isInsightQuery(String text) {
    final lower = text.toLowerCase();
    return lower.contains('analyze') ||
        lower.contains('budget') ||
        lower.contains('overspend') ||
        lower.contains('spending');
  }

  Future<String> _generateInsights() async {
    final categories = await _categoryRepo
        .getCategories()
        .first;
    final transactions = await _transactionRepo
        .getTransactions()
        .first;

    final currentMonth = _settings.currentMonth.value;
    final monthTx = transactions.where(
        (t) => AppDateUtils.getMonthKeyFromDate(t.date) == currentMonth);

    final categorySpending = categories.map((cat) {
      final spent = monthTx
          .where((t) => t.categoryId == cat.id)
          .fold(0.0, (s, t) => s + t.amount);
      final pct = cat.budgetLimit > 0
          ? (spent / cat.budgetLimit * 100).toStringAsFixed(0)
          : '0';
      return {
        'name': cat.name,
        'spent': spent.toStringAsFixed(2),
        'budget': cat.budgetLimit.toStringAsFixed(2),
        'percentage': pct,
      };
    }).toList();

    final totalSpent =
        monthTx.fold(0.0, (s, t) => s + t.amount);
    final totalBudget =
        categories.fold(0.0, (s, c) => s + c.budgetLimit);

    return _gemini.generateInsights(
      monthlyIncome: _settings.monthlyIncome.value,
      totalSpent: totalSpent,
      totalBudget: totalBudget,
      categorySpending: categorySpending,
    );
  }

  Future<void> clearChat() async {
    await _chatRepo.deleteAllMessages();
    _gemini.resetChat();
  }
}
