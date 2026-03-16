import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_fonts.dart';
import '../../services/firebase/firebase_auth_service.dart';
import '../../utils/currency_utils.dart';
import 'settings_controller.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(SettingsController());
    final authService = Get.find<FirebaseAuthService>();

    return Scaffold(
      appBar: AppBar(title: Text('Settings', style: AppFonts.h6)),
      body: Obx(() {
        final settings = ctrl.settings;
        return ListView(
          children: [
            // Profile section
            Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(Icons.person,
                        size: 32, color: AppColors.primaryDark),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(authService.currentUserName ?? 'User',
                            style: AppFonts.h6),
                        Text(authService.currentUserEmail ?? '',
                            style: AppFonts.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Preferences
            const _SectionHeader('Preferences'),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Monthly Income'),
              subtitle: Obx(() => Text(
                    '${settings.currencySymbol.value} ${settings.monthlyIncome.value.toStringAsFixed(0)}',
                    style: AppFonts.bodySmall,
                  )),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showIncomeSheet(context, ctrl),
            ),
            ListTile(
              leading: const Icon(Icons.currency_exchange),
              title: const Text('Currency'),
              subtitle: Obx(() => Text(
                    '${settings.currencyCode.value} (${settings.currencySymbol.value})',
                    style: AppFonts.bodySmall,
                  )),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showCurrencySheet(context, ctrl),
            ),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Theme'),
              subtitle: Obx(() => Text(
                    _themeLabel(settings.themeMode.value),
                    style: AppFonts.bodySmall,
                  )),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showThemeSheet(context, ctrl),
            ),
            const Divider(height: 1),

            // Sign out
            const _SectionHeader('Account'),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: Text('Sign Out',
                  style: AppFonts.labelLarge.copyWith(color: AppColors.error)),
              onTap: ctrl.isLoading.value ? null : ctrl.signOut,
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever_outlined,
                  color: AppColors.error),
              title: Text('Delete Account',
                  style: AppFonts.labelLarge.copyWith(color: AppColors.error)),
              subtitle: Text('Permanentally delete your data',
                  style: AppFonts.caption.copyWith(color: AppColors.textMuted)),
              onTap:
                  ctrl.isLoading.value ? null : () => _showDeleteDialog(context, ctrl),
            ),

            // Version footer
            const SizedBox(height: AppSpacing.xxl),
            Center(
              child: Text(
                '${AppConstants.appName} v${AppConstants.appVersion}',
                style: AppFonts.caption,
              ),
            ),
            const SizedBox(height: AppSpacing.m),
          ],
        );
      }),
    );
  }

  String _themeLabel(String mode) {
    switch (mode) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      default:
        return 'System';
    }
  }

  void _showIncomeSheet(BuildContext context, SettingsController ctrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.l,
          right: AppSpacing.l,
          top: AppSpacing.l,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.l,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Monthly Income', style: AppFonts.h5),
            const SizedBox(height: AppSpacing.m),
            TextField(
              controller: ctrl.incomeInputController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '${ctrl.settings.currencySymbol.value} ',
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            FilledButton(onPressed: ctrl.saveIncome, child: const Text('Save')),
          ],
        ),
      ),
    );
  }

  void _showCurrencySheet(BuildContext context, SettingsController ctrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Text('Select Currency', style: AppFonts.h5),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: CurrencyUtils.currencies.length,
                itemBuilder: (_, i) {
                  final currency = CurrencyUtils.currencies[i];
                  return ListTile(
                    leading: Text(currency.symbol,
                        style: AppFonts.h6.copyWith(color: AppColors.primary)),
                    title: Text(currency.name),
                    subtitle: Text(currency.code),
                    onTap: () {
                      ctrl.selectCurrency(currency);
                      Get.back();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeSheet(BuildContext context, SettingsController ctrl) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Theme', style: AppFonts.h5),
            const SizedBox(height: AppSpacing.m),
            for (final entry in {
              'system': 'System Default',
              'light': 'Light',
              'dark': 'Dark',
            }.entries)
              ListTile(
                title: Text(entry.value),
                leading: Icon(
                  ctrl.settings.themeMode.value == entry.key
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: ctrl.settings.themeMode.value == entry.key
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
                onTap: () {
                  ctrl.setTheme(entry.key);
                  Get.back();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, SettingsController ctrl) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This action is permanent and cannot be undone. All your data including expenses, '
          'categories, and files will be deleted forever.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back(); // Close confirmation dialog
              try {
                await ctrl.deleteAccount();
              } catch (e) {
                if (e == 'reauthentication-required' && context.mounted) {
                  _showReauthDialog(context, ctrl);
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete Permanentally'),
          ),
        ],
      ),
    );
  }

  void _showReauthDialog(BuildContext context, SettingsController ctrl) {
    final passwordController = TextEditingController();

    if (ctrl.isGoogleUser) {
      // For Google users, we just call the reauth method which triggers Google sign-in
      ctrl.reauthenticateAndDelete('');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Re-authenticate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'For security reasons, please enter your password to confirm account deletion.',
            ),
            const SizedBox(height: AppSpacing.m),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final pwd = passwordController.text.trim();
              if (pwd.isNotEmpty) {
                Get.back();
                ctrl.reauthenticateAndDelete(pwd);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Deletion'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.m, AppSpacing.m, AppSpacing.m, AppSpacing.xs),
      child: Text(title,
          style: AppFonts.overline.copyWith(color: AppColors.primary)),
    );
  }
}
