import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_fonts.dart';
import '../../utils/currency_utils.dart';
import 'settings_controller.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(SettingsController());

    return Scaffold(
      appBar: AppBar(title: Text('Settings', style: AppFonts.h6)),
      body: Obx(() {
        final settings = ctrl.settings;
        return ListView(
          children: [
            // Preferences
            const _SectionHeader('Preferences'),
            ListTile(
              // Not a dollar glyph: wrong for 22 of the 23 currencies (UI-08).
              leading: const Icon(Icons.payments_outlined),
              title: const Text('Monthly Income'),
              // No inline style on any of these three subtitles: the inline
              // AppFonts.bodySmall baked the light-theme textSecondary
              // (2.79:1 in dark), while listTileTheme.subtitleTextStyle
              // already carries the right colour for each theme (N6).
              subtitle: Obx(() => Text(
                    CurrencyUtils.formatAmount(
                        settings.monthlyIncomeMinor.value, settings.currency),
                  )),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showIncomeSheet(context, ctrl),
            ),
            ListTile(
              // The live symbol instead of a `$`-inside-arrows glyph — exactly
              // what the currency sheet's own rows do below (UI-08).
              leading: Obx(() => Text(
                    settings.currency.symbol,
                    style: AppFonts.h6.copyWith(color: AppColors.primary),
                  )),
              title: const Text('Currency'),
              subtitle: Obx(() => Text(
                    '${settings.currencyCode.value} (${settings.currency.symbol})',
                  )),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showCurrencySheet(context, ctrl),
            ),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Theme'),
              subtitle: Obx(() => Text(
                    _themeLabel(settings.themeMode.value),
                  )),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showThemeSheet(context, ctrl),
            ),
            const Divider(height: 1),

            const _SectionHeader('Data'),
            ListTile(
              // colorScheme.error, not the raw token: the dark scheme's
              // lighter error tone (#E89088) reads on #1E1B15 where #C25D4E
              // sits at ~4.3:1 (UI-20).
              leading: Icon(Icons.delete_forever_outlined,
                  color: Theme.of(context).colorScheme.error),
              title: Text('Erase All Data',
                  style: AppFonts.labelLarge
                      .copyWith(color: Theme.of(context).colorScheme.error)),
              subtitle: Text(
                  'Delete every category, transaction and preference on this device',
                  style: AppFonts.caption.copyWith(color: AppColors.textMuted)),
              trailing: ctrl.isLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              onTap: ctrl.isLoading.value
                  ? null
                  : () => _showEraseDialog(context, ctrl),
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
                prefixText: '${ctrl.settings.currency.symbol} ',
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

  void _showEraseDialog(BuildContext context, SettingsController ctrl) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Erase all data?'),
        // This used to promise that no backup of the data existed anywhere,
        // which was false on both platforms: Android has backed this app up by
        // default since API 23, and the iOS documents directory is in
        // iCloud/device backups. Saying it in the one dialog a user reads
        // before wiping their records is a straight lie, so the last sentence
        // now tells them where a copy may survive. Platform-neutral on purpose
        // — the old line was wrong on both sides, so branching on the platform
        // would only have produced two wrong answers (F-12).
        content: const Text(
          'This deletes every category, transaction and preference stored on '
          'this device, and takes you back through setup. The app keeps no '
          'other copy and cannot undo this. If your phone\'s own backup is '
          'switched on, a copy may still exist there.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back(); // Close the confirmation dialog first.
              ctrl.eraseAllData();
            },
            // The pattern the other three delete dialogs now copy (N9) — with
            // the scheme's error, since this text sits on a dark dialog
            // surface where the raw token is 3.22:1.
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Erase Everything'),
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
