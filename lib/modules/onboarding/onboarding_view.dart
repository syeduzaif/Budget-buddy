import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_fonts.dart';
import '../../utils/currency_utils.dart';
import 'onboarding_controller.dart';

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Obx(() => LinearProgressIndicator(
                  value: (controller.currentPage.value + 1) / 3,
                  // The bar read BACKWARDS in dark: the unfilled track was
                  // AppColors.border (#E3DDD2, 12.7:1) while the filled part
                  // was 3.9:1 — the empty part 3× brighter than the progress
                  // (N7).
                  backgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
                  color: colorScheme.primary,
                  minHeight: 3,
                )),
            Expanded(
              child: PageView(
                controller: controller.pageController,
                onPageChanged: controller.onPageChanged,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _WelcomePage(),
                  _CurrencyPage(),
                  _IncomePage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<OnboardingController>();
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded,
                size: 64, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text('Welcome to BuddgetBuddy',
              style: AppFonts.h3, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.m),
          Text(
            // Describes what ships. The old copy promised "financial goals",
            // a feature that does not exist (UI-24).
            'Track your spending, set a budget per category, and see where the '
            'month went.',
            // textSecondary is a light-theme token: 2.79:1 on the dark
            // background (N6).
            style:
                AppFonts.bodyLarge.copyWith(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxxl),
          FilledButton(
            onPressed: ctrl.nextPage,
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }
}

class _CurrencyPage extends StatefulWidget {
  const _CurrencyPage();

  @override
  State<_CurrencyPage> createState() => _CurrencyPageState();
}

class _CurrencyPageState extends State<_CurrencyPage> {
  /// The grid's shape, in one place, because [_revealOffset] does arithmetic
  /// with the same three numbers the delegate does.
  static const int _crossAxisCount = 2;
  static const double _childAspectRatio = 2.5;
  static const double _spacing = AppSpacing.s;

  /// Created once, on the first build that knows the viewport, and never
  /// rebuilt: `initialScrollOffset` only applies when the controller attaches,
  /// and re-creating it on every selection change would yank the grid back
  /// under the user's finger.
  ScrollController? _gridController;

  @override
  void dispose() {
    _gridController?.dispose();
    super.dispose();
  }

  /// How far the grid must start scrolled for the preselected currency to be
  /// on screen (AC-D009-2).
  ///
  /// D-009 made PKR the default, and PKR is entry 13 of 23 in a 2-across grid
  /// — row 7, ~490dp down. A default nobody can see is not a default: a
  /// first-run user who sees nothing highlighted picks the top-left cell,
  /// which is the currency D-009 moved away from. Reordering
  /// `CurrencyUtils.currencies` was refused — the ISO-4217 `decimalDigits`
  /// table lives on that list, so a picker's layout must never get a vote in
  /// it — so the picker moves instead of the data.
  ///
  /// MINIMAL scroll, not centred: the selection is brought just inside the
  /// fold with one gap of headroom, so the rows above it stay visible and the
  /// grid still reads as a list that starts at the top. On a tall enough
  /// device the answer is 0 and nothing moves at all.
  ///
  /// This duplicates the delegate's row arithmetic, which is the one fragile
  /// thing here — so `onboarding_currency_default_test.dart` asserts the tile's
  /// rect against the real viewport. Change the delegate without changing this
  /// and the test says so.
  double _revealOffset(BoxConstraints constraints, int selectedIndex) {
    if (!constraints.hasBoundedHeight || selectedIndex <= 0) return 0;

    final tileWidth =
        (constraints.maxWidth - _spacing * (_crossAxisCount - 1)) /
            _crossAxisCount;
    final tileHeight = tileWidth / _childAspectRatio;
    final rowExtent = tileHeight + _spacing;

    final rowCount =
        (CurrencyUtils.currencies.length + _crossAxisCount - 1) ~/
            _crossAxisCount;
    // The grid's scrollable content: every row plus the gaps between them.
    final contentExtent = rowCount * rowExtent - _spacing;
    final maxOffset = (contentExtent - constraints.maxHeight).clamp(
      0.0,
      double.infinity,
    );

    final rowBottom = (selectedIndex ~/ _crossAxisCount) * rowExtent +
        tileHeight;
    if (rowBottom <= constraints.maxHeight) return 0;

    return (rowBottom - constraints.maxHeight + _spacing)
        .clamp(0.0, maxOffset);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<OnboardingController>();
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text('Pick Your Currency', style: AppFonts.h3),
          const SizedBox(height: AppSpacing.s),
          Text('Choose the currency you use for your budget.',
              style: AppFonts.bodyMedium
                  .copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.l),
          Expanded(
            child: Obx(() {
              // Read the observable directly in the Obx scope so GetX can track it
              final selectedCode = ctrl.selectedCurrency.value.code;
              return LayoutBuilder(builder: (context, constraints) {
                _gridController ??= ScrollController(
                  initialScrollOffset: _revealOffset(
                    constraints,
                    CurrencyUtils.currencies
                        .indexWhere((c) => c.code == selectedCode),
                  ),
                );
                return GridView.builder(
                  controller: _gridController,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _crossAxisCount,
                    childAspectRatio: _childAspectRatio,
                    crossAxisSpacing: _spacing,
                    mainAxisSpacing: _spacing,
                  ),
                  itemCount: CurrencyUtils.currencies.length,
                  itemBuilder: (context, i) {
                    final currency = CurrencyUtils.currencies[i];
                    final selected = selectedCode == currency.code;
                    return InkWell(
                      onTap: () => ctrl.selectCurrency(currency),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusM),
                      child: Container(
                        decoration: BoxDecoration(
                          // primaryDark, not primary: white on #4E5E38 is
                          // 6.9:1, where white70 on #6B7F4E was 3.04:1 — below
                          // AA for 14px text (UI-13).
                          color: selected
                              ? AppColors.primaryDark
                              : Colors.transparent,
                          border: Border.all(
                            color: selected
                                ? AppColors.primaryDark
                                : AppColors.border,
                            width: selected ? 2 : 1,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusM),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s, vertical: AppSpacing.xs),
                        child: Row(
                          children: [
                            // Unselected cards sit on the page background, so
                            // their text must come from the scheme:
                            // textPrimary (#2C2518) on backgroundDark was
                            // 1.13:1 — invisible — and the code beside it
                            // 2.79:1 (N2). Selected keeps white on
                            // primaryDark, 6.9:1.
                            Text(currency.symbol,
                                style: AppFonts.labelLarge.copyWith(
                                    color: selected
                                        ? Colors.white
                                        : colorScheme.onSurface)),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(currency.code,
                                  style: AppFonts.labelMedium.copyWith(
                                      color: selected
                                          ? Colors.white
                                          : colorScheme.onSurfaceVariant),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              });
            }),
          ),
          const SizedBox(height: AppSpacing.l),
          FilledButton(
            onPressed: ctrl.nextPage,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}

class _IncomePage extends StatelessWidget {
  const _IncomePage();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<OnboardingController>();
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Centred rather than pinned to the top with ~700px of dead space
          // below the field, and the space spent on the "why" instead (UI-25).
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Set Monthly Income', style: AppFonts.h3),
                const SizedBox(height: AppSpacing.s),
                Text(
                  // The caption below already says it can be changed later
                  // (N11).
                  'What is your approximate monthly income?',
                  style: AppFonts.bodyMedium
                      .copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.xl),
                Obx(() => TextFormField(
                      controller: ctrl.incomeController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: AppFonts.h3,
                      decoration: InputDecoration(
                        labelText: 'Monthly Income',
                        prefixText: '${ctrl.selectedCurrency.value.symbol} ',
                        prefixStyle:
                            AppFonts.h4.copyWith(color: AppColors.primary),
                        // The unit at rest, without the doubled "₨ ₨0.00" the
                        // UI-17 hint produced (N1): Flutter drives the prefix's
                        // opacity off the floating label, so an always-floating
                        // label is what makes `prefixText` paint on an empty,
                        // unfocused field — measured 0.0 → 1.0 opacity. No hint
                        // needed, and no second symbol.
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                    )),
                const SizedBox(height: AppSpacing.s),
                Text(
                  'Used to work out what\'s left this month. You can change it '
                  'any time.',
                  style: AppFonts.caption
                      .copyWith(color: context.semanticColors.textMuted),
                ),
              ],
            ),
          ),
          // BOTH controls finish onboarding, and both are disabled while it
          // runs. That pairing is the whole point: the primary used to sit
          // inert-looking through five awaited Hive writes with "Skip for now"
          // directly beneath it, so the natural next move — tap the thing
          // under the button that did nothing — ran the seeder a second time
          // and left the install with eighteen categories (D-026/5(b)). The
          // controller's latch is the guarantee; this is what stops the second
          // tap being made.
          //
          // The spinner is on the primary only. Two spinners would read as two
          // operations, and the greyed-out secondary already says it is not
          // available. Same shape as the category and transaction forms
          // (`category_form_view.dart:321`, `transaction_form_view.dart:146`).
          Obx(() => FilledButton(
                onPressed: ctrl.isLoading.value ? null : ctrl.finish,
                child: ctrl.isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Start Budgeting'),
              )),
          const SizedBox(height: AppSpacing.m),
          Obx(() => TextButton(
                onPressed: ctrl.isLoading.value ? null : ctrl.finish,
                child: const Text('Skip for now'),
              )),
        ],
      ),
    );
  }
}
