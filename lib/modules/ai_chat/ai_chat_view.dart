import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'ai_chat_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/app_icons.dart';

class AiChatView extends GetView<AiChatController> {
  const AiChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(AppIcons.ai, size: AppSpacing.iconM),
            SizedBox(width: AppSpacing.s),
            Text('AI Assistant'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.delete),
            onPressed: () {
              // Optional: Clear chat functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              return ListView.builder(
                controller: controller.scrollController,
                padding: const EdgeInsets.all(AppSpacing.m),
                itemCount: controller.messages.length +
                    (controller.isLoading.value ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == controller.messages.length) {
                    return const _LoadingBubble();
                  }
                  final msg = controller.messages[index];
                  return _MessageBubble(
                    message: msg.message,
                    isUser: msg.isUser,
                    timestamp: msg.timestamp,
                  );
                },
              );
            }),
          ),
          _buildInputArea(context),
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.textController,
              decoration: InputDecoration(
                hintText: 'Ask about your budget...',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.l,
                  vertical: AppSpacing.m,
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => controller.sendMessage(),
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          FloatingActionButton(
            onPressed: controller.sendMessage,
            mini: true,
            elevation: AppSpacing.elevationS,
            child: const Icon(AppIcons.ai),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final DateTime timestamp;

  const _MessageBubble({
    required this.message,
    required this.isUser,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.m),
        constraints: BoxConstraints(maxWidth: Get.width * 0.75),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.primary
              : isDark
                  ? AppColors.cardDark
                  : AppColors.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppSpacing.radiusL),
            topRight: const Radius.circular(AppSpacing.radiusL),
            bottomLeft: Radius.circular(
                isUser ? AppSpacing.radiusL : AppSpacing.radiusXs),
            bottomRight: Radius.circular(
                isUser ? AppSpacing.radiusXs : AppSpacing.radiusL),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    AppIcons.ai,
                    size: AppSpacing.iconXs,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'AI Assistant',
                    style: AppFonts.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: AppFonts.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            Text(
              message,
              style: AppFonts.bodyMedium.copyWith(
                color: isUser ? AppColors.textWhite : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              DateFormat('h:mm a').format(timestamp),
              style: AppFonts.caption.copyWith(
                color: isUser
                    ? AppColors.textWhite.withOpacity(0.7)
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingBubble extends StatelessWidget {
  const _LoadingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.m),
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppSpacing.radiusL),
            topRight: Radius.circular(AppSpacing.radiusL),
            bottomLeft: Radius.circular(AppSpacing.radiusXs),
            bottomRight: Radius.circular(AppSpacing.radiusL),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: AppSpacing.iconXs,
              height: AppSpacing.iconXs,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppSpacing.s),
            Text('Thinking...', style: AppFonts.bodySmall),
          ],
        ),
      ),
    );
  }
}
