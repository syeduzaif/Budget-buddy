import 'dart:io';

import 'package:budget_buddy/core/theme/app_spacing.dart';
import 'package:budget_buddy/core/theme/app_theme.dart';
import 'package:budget_buddy/data/local/hive_storage.dart';
import 'package:budget_buddy/data/models/category.dart';
import 'package:budget_buddy/data/models/transaction_item.dart';
import 'package:budget_buddy/data/repositories/category_repository.dart';
import 'package:budget_buddy/data/repositories/transaction_repository.dart';
import 'package:budget_buddy/modules/dashboard/dashboard_controller.dart';
import 'package:budget_buddy/modules/dashboard/dashboard_view.dart';
import 'package:budget_buddy/modules/dashboard/widgets/category_budget_list.dart';
import 'package:budget_buddy/modules/dashboard/widgets/recent_transactions_card.dart';
import 'package:budget_buddy/services/app/settings_service.dart';
import 'package:budget_buddy/services/local/local_store_service.dart';
import 'package:budget_buddy/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// F-04 AC-A6 — the dashboard's blocks are in the order D-001 decided:
/// **budgets → recent → donut**, under the summary row.
///
/// This file exists because the suite was provably blind to block order. Before
/// it: zero goldens, no `ensureVisible` / `scrollUntilVisible`, no `drag`, and
/// `SingleChildScrollView` builds its child eagerly — so every `find.text`
/// resolves whether the widget is on screen or 1,200dp below it, and all five
/// dashboard-touching test files passed with the donut first or last. A green
/// suite measured what was asserted, and nobody had asserted this.
///
/// It also guards the specific wrong fix. `FadeSlideItem.index` is a stagger
/// DELAY (`animations.dart:42`, `Future.delayed(delay * index, …)`), not a sort
/// key; a diff that renumbered the indices and moved no block literals would
/// look correct and change nothing a user sees. Y offsets can only be satisfied
/// by moving the blocks.
///
/// Scoping obeys AC-A6: two headers by `find.descendant` of their own widget
/// type, the third by [kDonutHeaderKey]. Never a bare `find.byType(Text)` sweep
/// — that is what would make this flaky the moment any block grows a second
/// heading.
void main() {
  final thisMonth = AppDateUtils.getCurrentMonthKey();

  int yearOf(String monthKey) => int.parse(monthKey.split('-')[0]);
  int monthOf(String monthKey) => int.parse(monthKey.split('-')[1]);
  DateTime dayIn(String monthKey, int day) =>
      DateTime(yearOf(monthKey), monthOf(monthKey), day, 12);

  Category category({
    required String id,
    required String name,
    int limitMinor = 500000,
  }) =>
      Category(
        id: id,
        name: name,
        budgetLimitMinor: limitMinor,
        colorValue: 0xFF2D8B8B,
        iconCodePoint: Icons.restaurant.codePoint,
        month: thisMonth,
        createdAt: DateTime(2026, 1, 1, 9),
        updatedAt: DateTime(2026, 1, 1, 9),
      );

  TransactionItem txn({
    required String id,
    required int day,
    int amountMinor = 10000,
    String note = '',
    String categoryId = 'food',
  }) =>
      TransactionItem(
        id: id,
        categoryId: categoryId,
        amountMinor: amountMinor,
        note: note,
        date: dayIn(thisMonth, day),
        createdAt: dayIn(thisMonth, day),
        updatedAt: dayIn(thisMonth, day),
      );

  late Directory tempDir;

  setUpAll(() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CategoryAdapter());
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionItemAdapter());
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('buddgetbuddy_order');
    Hive.init(tempDir.path);
    await HiveStorage.openSettings();
    Get.put<LocalStoreService>(await LocalStoreService().init());
    Get.put(CategoryRepository());
    Get.put(TransactionRepository());
    final settings = Get.put(SettingsService());
    await settings.setCurrency('PKR', '₨');
    await settings.setCurrentMonth(thisMonth);
    await settings.setMonthlyIncomeMinor(15000000);
    await Get.find<CategoryRepository>().addCategories([
      category(id: 'food', name: 'Food'),
      category(id: 'travel', name: 'Travel', limitMinor: 300000),
    ]);
    Get.put(DashboardController(
      categoryRepo: Get.find<CategoryRepository>(),
      transactionRepo: Get.find<TransactionRepository>(),
      settings: settings,
    ));
  });

  tearDown(() async {
    Get.reset();
    await Hive.deleteFromDisk();
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// The budgets header. `isCurrentMonth` is true throughout this file — the
  /// fixture views the month `AppClock` reports — so the card renders its
  /// "This Month's" wording rather than "July's Budgets".
  final budgetsHeader = find.descendant(
    of: find.byType(CategoryBudgetList),
    matching: find.text("This Month's Budgets"),
  );
  final recentHeader = find.descendant(
    of: find.byType(RecentTransactionsCard),
    matching: find.text('Recent'),
  );
  final donutHeader = find.byKey(kDonutHeaderKey);

  Future<void> pumpDashboard(WidgetTester tester) async {
    await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const DashboardView()));
    // Settles the staggered entrance. Until it finishes, FadeSlideItem holds
    // each block under a Transform.translate, so a mid-animation read would be
    // measuring the animation rather than the layout.
    await tester.pumpAndSettle();
  }

  double topOf(WidgetTester tester, Finder finder) {
    expect(finder, findsOneWidget);
    return tester.getTopLeft(finder).dy;
  }

  testWidgets('AC-A6: budgets sit above recent, and recent above the donut',
      (tester) async {
    await tester.runAsync(() async {
      final repo = Get.find<TransactionRepository>();
      await repo.addTransaction(txn(id: 't1', day: 3, note: 'Biryani'));
      await repo.addTransaction(txn(id: 't2', day: 4, note: 'Bus'));
    });
    await pumpDashboard(tester);

    final budgetsY = topOf(tester, budgetsHeader);
    final recentY = topOf(tester, recentHeader);
    final donutY = topOf(tester, donutHeader);

    expect(budgetsY, lessThan(recentY),
        reason: 'D-001: the verdict — am I inside my budgets — comes first. '
            'It used to render last, ~1,190dp down a 623dp viewport.');
    expect(recentY, lessThan(donutY),
        reason: 'proof of the last log outranks the breakdown chart');
  });

  testWidgets(
      'AC-A6: the order holds with no Recent card, which is the common month',
      (tester) async {
    // No transactions at all. Recent is absent (F-04 AC-3) and the two blocks
    // that remain must still be the right way round — the arrangement a user
    // sees on the first day of any month.
    await pumpDashboard(tester);

    expect(recentHeader, findsNothing);
    expect(topOf(tester, budgetsHeader), lessThan(topOf(tester, donutHeader)));
  });

  testWidgets('the gap above and below each block is exactly one AppSpacing.l',
      (tester) async {
    // The move's real risk was never the order, it was the spacers: `:201` is a
    // standalone child while the other two sat INSIDE their blocks' conditional
    // spreads, and the budgets block had no trailing spacer because it was
    // last. A naive move doubles the gap above budgets and drops the one below,
    // differing by how many sections happen to render — which no order
    // assertion would catch. Measured on the cards, not the headers, because a
    // header carries its own internal padding.
    await tester.runAsync(() async {
      await Get.find<TransactionRepository>()
          .addTransaction(txn(id: 't1', day: 3, note: 'Biryani'));
    });
    await pumpDashboard(tester);

    // dashboard_view wraps the budgets list in a Card of its own, so that Card
    // is an ANCESTOR here; RecentTransactionsCard builds its own Card, so its
    // own render box already is the card. Both rects therefore include the
    // theme's 6dp vertical card margin, and the distance between them is the
    // SizedBox alone.
    final budgetsRect = tester.getRect(find
        .ancestor(
          of: find.byType(CategoryBudgetList),
          matching: find.byType(Card),
        )
        .first);
    final recentRect = tester.getRect(find.byType(RecentTransactionsCard));
    final donutTop = tester.getTopLeft(donutHeader).dy;

    expect(recentRect.top - budgetsRect.bottom, closeTo(AppSpacing.l, 0.5),
        reason: 'one AppSpacing.l between budgets and recent — not two, which '
            'is what a trailing spacer left in place would have produced');
    expect(donutTop - recentRect.bottom, closeTo(AppSpacing.l, 0.5),
        reason: 'one AppSpacing.l between recent and the donut header — not '
            'zero, which is what moving the budgets block without giving the '
            'donut a leading spacer would have produced');
  });
}
