import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../utils/date_utils.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessageModel message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primaryLight,
              child: Icon(Icons.auto_awesome, size: 16, color: AppColors.primaryDark),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.m, vertical: AppSpacing.s),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : Theme.of(context).cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppSpacing.radiusL),
                  topRight: const Radius.circular(AppSpacing.radiusL),
                  bottomLeft: isUser
                      ? const Radius.circular(AppSpacing.radiusL)
                      : const Radius.circular(AppSpacing.radiusXs),
                  bottomRight: isUser
                      ? const Radius.circular(AppSpacing.radiusXs)
                      : const Radius.circular(AppSpacing.radiusL),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: AppFonts.bodyMedium.copyWith(
                      color: isUser ? Colors.white : null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    AppDateUtils.formatDate(message.timestamp),
                    style: AppFonts.caption.copyWith(
                      color: isUser
                          ? Colors.white60
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: AppSpacing.xs),
        ],
      ),
    );
  }
}
