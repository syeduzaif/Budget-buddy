import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_fonts.dart';
import 'ai_chat_controller.dart';
import 'widgets/chat_bubble.dart';

class AiChatView extends StatelessWidget {
  const AiChatView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AiChatController>();
    final textCtrl = TextEditingController();
    final scrollCtrl = ScrollController();

    void sendAndScroll(String text) {
      ctrl.sendMessage(text);
      textCtrl.clear();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (scrollCtrl.hasClients) {
          scrollCtrl.animateTo(
            scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primaryLight,
              child: Icon(Icons.auto_awesome, size: 16, color: AppColors.primaryDark),
            ),
            const SizedBox(width: AppSpacing.s),
            Text('AI Financial Advisor', style: AppFonts.h6),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear chat',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Clear Chat'),
                content: const Text('Delete all chat history?'),
                actions: [
                  TextButton(
                      onPressed: () => Get.back(), child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () {
                        ctrl.clearChat();
                        Get.back();
                      },
                      child: const Text('Clear')),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Obx(() {
              final msgs = ctrl.messages;
              if (msgs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome,
                          size: 64, color: AppColors.primaryLight),
                      const SizedBox(height: AppSpacing.m),
                      Text('Your AI Financial Advisor', style: AppFonts.h5),
                      const SizedBox(height: AppSpacing.s),
                      Text(
                        'Ask me anything about your budget,\nsavings, or spending habits.',
                        style: AppFonts.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(AppSpacing.m),
                itemCount: msgs.length + (ctrl.isTyping.value ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i == msgs.length && ctrl.isTyping.value) {
                    return _TypingIndicator();
                  }
                  return ChatBubble(message: msgs[i]);
                },
              );
            }),
          ),

          // Quick prompts
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
              itemCount: AiChatController.quickPrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.s),
              itemBuilder: (_, i) {
                final prompt = AiChatController.quickPrompts[i];
                return ActionChip(
                  label: Text(prompt, style: AppFonts.labelSmall),
                  onPressed: () => sendAndScroll(prompt),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.s),

          // Input area
          Container(
            padding: EdgeInsets.only(
              left: AppSpacing.m,
              right: AppSpacing.m,
              bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.m,
              top: AppSpacing.s,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ask your financial advisor...',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: sendAndScroll,
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Obx(() => IconButton.filled(
                      onPressed: ctrl.isTyping.value
                          ? null
                          : () => sendAndScroll(textCtrl.text),
                      icon: const Icon(Icons.send_rounded),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primaryLight,
            child: Icon(Icons.auto_awesome, size: 16, color: AppColors.primaryDark),
          ),
          const SizedBox(width: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m, vertical: AppSpacing.s),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppSpacing.radiusL),
            ),
            child: Text('Thinking...',
                style: AppFonts.bodySmall.copyWith(color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }
}
