import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../services/ai_insights_service.dart';
import '../../services/gemini_service.dart';

class AiChatController extends GetxController {
  final AiInsightsService _insightsService = Get.find<AiInsightsService>();
  final GeminiService _geminiService = Get.find<GeminiService>();
  final ChatRepository _chatRepository = Get.find<ChatRepository>();

  final messages = <ChatMessageModel>[].obs;
  final textController = TextEditingController();
  final scrollController = ScrollController();
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _bindMessages();
  }

  void _bindMessages() {
    _chatRepository.getMessages().listen((list) {
      messages.assignAll(list);

      // Add initial greeting if empty
      if (messages.isEmpty) {
        _saveMessage(ChatMessageModel(
          id: const Uuid().v4(),
          message:
              "Hello! I'm your AI Budget Assistant. How can I help you manage your finances today?",
          isUser: false,
          timestamp: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      } else {
        _scrollToBottom();
      }
    });
  }

  Future<void> sendMessage() async {
    final text = textController.text.trim();
    if (text.isEmpty) return;

    textController.clear();

    // Add user message
    final userMsg = ChatMessageModel(
      id: const Uuid().v4(),
      message: text,
      isUser: true,
      timestamp: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _saveMessage(userMsg);

    isLoading.value = true;
    _scrollToBottom();

    // Generate AI response
    try {
      final response = await _generateResponse(text);
      await _addAiMessage(response);
    } catch (e) {
      await _addAiMessage("Sorry, I encountered an error: $e");
    } finally {
      isLoading.value = false;
      _scrollToBottom();
    }
  }

  Future<String> _generateResponse(String userMessage) async {
    final lowerMsg = userMessage.toLowerCase();

    // Check if user wants spending analysis
    if (lowerMsg.contains("analyze") ||
        lowerMsg.contains("insight") ||
        lowerMsg.contains("spending") ||
        lowerMsg.contains("budget overview")) {
      // Use local insights service for data analysis
      final insights = _insightsService.analyzeMonthlySpending();
      if (insights.isEmpty) {
        return await _geminiService.generateResponse(
            "The user asked for spending analysis but has no transactions yet. "
            "Encourage them to start tracking expenses.");
      }

      // Let Gemini provide insights based on the data
      return await _geminiService.generateResponse(
          "Provide financial insights based on this data: ${insights.join(', ')}");
    }

    // For all other queries, use Gemini AI
    return await _geminiService.generateResponse(userMessage);
  }

  Future<void> _addAiMessage(String text) async {
    final aiMsg = ChatMessageModel(
      id: const Uuid().v4(),
      message: text,
      isUser: false,
      timestamp: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _saveMessage(aiMsg);
  }

  Future<void> _saveMessage(ChatMessageModel msg) async {
    await _chatRepository.addMessage(msg);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void onClose() {
    textController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
