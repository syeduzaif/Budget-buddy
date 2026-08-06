import 'dart:io';

import 'package:budget_buddy/core/theme/app_theme.dart';
import 'package:budget_buddy/data/local/hive_storage.dart';
import 'package:budget_buddy/data/models/category.dart';
import 'package:budget_buddy/data/models/transaction_item.dart';
import 'package:budget_buddy/data/repositories/category_repository.dart';
import 'package:budget_buddy/data/repositories/transaction_repository.dart';
import 'package:budget_buddy/modules/dashboard/dashboard_controller.dart';
import 'package:budget_buddy/modules/dashboard/dashboard_view.dart';
import 'package:budget_buddy/services/app/settings_service.dart';
import 'package:budget_buddy/services/local/local_store_service.dart';
import 'package:budget_buddy/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// AC-D027-1 — the dashboard has no pull-to-refresh, and is still draggable.
///
/// D-027: the `RefreshIndicator` called `.refresh()` on two Hive-backed
/// RxLists, i.e. it re-emitted identical data behind a 300 ms spinner. The
/// gesture means "ask the server again" everywhere it exists, and this app
/// ships with no platform permissions — not even INTERNET.
///
/// The half that is easy to get wrong is the KEEP: `AlwaysScrollableScrollPhysics`
/// was there for the indicator, and deleting it with the indicator would leave
/// an empty past month — content shorter than the viewport — refusing the drag
/// entirely. That reads as a frozen screen, which is a worse outcome than the
/// spinner this change removes. So both halves are asserted, and the second one
/// is measured on a page that is provably shorter than its viewport.
void main() {
  final thisMonth = AppDateUtils.getCurrentMonthKey();
  final lastMonth = AppDateUtils.getPreviousMonthKey(thisMonth);

  int yearOf(String monthKey) => int.parse(monthKey.split('-')[0]);
  int monthOf(String monthKey) => int.parse(monthKey.split('-')[1]);

  Category category({required String id, required String name}) => Category(
        id: id,
        name: name,
        budgetLimitMinor: 500000,
        colorValue: 0xFF2D8B8B,
        iconCodePoint: Icons.restaurant.codePoint,
        month: thisMonth,
        createdAt: DateTime(2026, 1, 1, 9),
        updatedAt: DateTime(2026, 1, 1, 9),
      );

  TransactionItem txn({required String id, required int day}) {
    final when = DateTime(yearOf(thisMonth), monthOf(thisMonth), day, 12);
    return TransactionItem(
      id: id,
      categoryId: 'food',
      amountMinor: 10000,
      note: 'Row $id',
      date: when,
      createdAt: when,
      updatedAt: when,
    );
  }

  late Directory tempDir;
  late SettingsService settings;

  setUpAll(() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CategoryAdapter());
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionItemAdapter());
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('buddgetbuddy_refresh');
    Hive.init(tempDir.path);
    await HiveStorage.openSettings();
    Get.put<LocalStoreService>(await LocalStoreService().init());
    Get.put(CategoryRepository());
    Get.put(TransactionRepository());
    settings = Get.put(SettingsService());
    await settings.setCurrency('PKR', '₨');
    await settings.setCurrentMonth(thisMonth);
    await settings.setMonthlyIncomeMinor(15000000);
    await Get.find<CategoryRepository>().addCategories([
      category(id: 'food', name: 'Food'),
      category(id: 'travel', name: 'Travel'),
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

  Future<void> pumpDashboard(WidgetTester tester) async {
    await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const DashboardView()));
    await tester.pumpAndSettle();
  }

  ScrollPosition positionOf(WidgetTester tester) =>
      tester.state<ScrollableState>(find.byType(Scrollable).first).position;

  /// The gesture a user makes when they expect a refresh: press near the top
  /// and pull down. Deliberately NOT `pumpAndSettle` afterwards — a
  /// `RefreshIndicator` shows its spinner while the drag is live, so settling
  /// first is how a test misses one.
  Future<void> pullDownFromTop(WidgetTester tester) async {
    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(Scrollable)));
    for (var step = 0; step < 12; step++) {
      await gesture.moveBy(const Offset(0, 25));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.byType(RefreshProgressIndicator), findsNothing,
        reason: 'AC-D027-1: no spinner appears mid-pull');
    await gesture.up();
    await tester.pumpAndSettle();
  }

  group('AC-D027-1 — a populated month', () {
    testWidgets('no RefreshIndicator, and a pull raises no spinner',
        (tester) async {
      await tester.runAsync(() async {
        final repo = Get.find<TransactionRepository>();
        for (var day = 1; day <= 5; day++) {
          await repo.addTransaction(txn(id: 't$day', day: day));
        }
      });
      await pumpDashboard(tester);

      expect(find.byType(RefreshIndicator), findsNothing);

      await pullDownFromTop(tester);

      expect(find.byType(RefreshProgressIndicator), findsNothing);
      expect(find.byType(RefreshIndicator), findsNothing);
    });

    testWidgets('the page still scrolls', (tester) async {
      await tester.runAsync(() async {
        final repo = Get.find<TransactionRepository>();
        for (var day = 1; day <= 5; day++) {
          await repo.addTransaction(txn(id: 't$day', day: day));
        }
      });
      await pumpDashboard(tester);

      final position = positionOf(tester);
      expect(position.maxScrollExtent, greaterThan(0),
          reason: 'a month with records is taller than the viewport — if this '
              'ever fails, the scroll assertion below has stopped meaning '
              'anything');

      await tester.drag(find.byType(Scrollable), const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(position.pixels, greaterThan(0));
    });
  });

  group('AC-D027-1 — an empty past month, shorter than the viewport', () {
    /// A viewport tall enough that the empty state cannot fill it, so
    /// `maxScrollExtent == 0` is a fact of the fixture rather than a hope.
    Future<void> pumpTallViewport(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.runAsync(() async {
        await settings.setCurrentMonth(lastMonth);
      });
      await pumpDashboard(tester);
    }

    testWidgets('a pull raises no spinner', (tester) async {
      await pumpTallViewport(tester);

      expect(find.byType(RefreshIndicator), findsNothing);

      await pullDownFromTop(tester);

      expect(find.byType(RefreshProgressIndicator), findsNothing);
    });

    testWidgets('the drag is still accepted — the physics stayed',
        (tester) async {
      await pumpTallViewport(tester);

      final position = positionOf(tester);
      expect(position.maxScrollExtent, 0,
          reason: 'the fixture must really be the short case, or this test '
              'proves nothing about it');
      expect(position.physics, isA<AlwaysScrollableScrollPhysics>());
      expect(position.physics.shouldAcceptUserOffset(position), isTrue,
          reason: 'D-027 keeps AlwaysScrollableScrollPhysics: dropping it with '
              'the indicator would make an empty past month refuse the drag '
              'outright, which reads as a frozen screen');
    });
  });
}
