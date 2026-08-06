import 'dart:io';

import 'package:budget_buddy/data/local/hive_storage.dart';
import 'package:budget_buddy/data/models/category.dart';
import 'package:budget_buddy/data/models/transaction_item.dart';
import 'package:budget_buddy/data/repositories/category_repository.dart';
import 'package:budget_buddy/data/repositories/transaction_repository.dart';
import 'package:budget_buddy/modules/dashboard/dashboard_controller.dart';
import 'package:budget_buddy/services/app/settings_service.dart';
import 'package:budget_buddy/services/local/local_store_service.dart';
import 'package:budget_buddy/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// D-025, dashboard half — the month chevrons run the same roll-then-ensure
/// pair as the splash and the resume hook, and were the last of the three left
/// unguarded on a path a user reaches by tapping.
///
/// **AC-D025-3: the header never silently names an un-cloned month.** The word
/// doing the work is *silently*. There are two failures behind one chevron and
/// they leave the screen in opposite states, so the criterion is an agreement
/// rule rather than a single expected value:
///
/// * the roll fails → the header stays on the month the user tapped away from,
///   i.e. a chevron that visibly did nothing;
/// * the clone fails → the header moves onto a month with no categories in it,
///   on an install that has three.
///
/// Either way the invariant asserted below must hold: every category on screen
/// belongs to the month the header names, and the user has been told. That is
/// what makes "No categories yet" honest instead of a lie about the data.
///
/// The failure is injected as a WRITE at the two shipped seams — `SettingsService
/// .setCurrentMonth` (`settings_service.dart:150` → `hive_storage.dart:118`)
/// and `LocalStoreService.putCategories` (`local_store_service.dart:95`) — with
/// the rest of the app running as shipped.
void main() {
  late Directory tempDir;
  late _FailingCategoryWriteStore store;
  late _FailingMonthWriteSettings settings;
  late CategoryRepository categoryRepo;
  late DashboardController controller;

  final thisMonth = AppDateUtils.getCurrentMonthKey();
  final lastMonth = AppDateUtils.getPreviousMonthKey(thisMonth);

  Category category(String id, String name, String month) {
    final stamp = DateTime(2026, 1, 1, 9);
    return Category(
      id: id,
      name: name,
      budgetLimitMinor: 2250000,
      colorValue: 0xFF2D8B8B,
      iconCodePoint: Icons.restaurant.codePoint,
      month: month,
      createdAt: stamp,
      updatedAt: stamp,
    );
  }

  setUpAll(() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CategoryAdapter());
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionItemAdapter());
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('buddgetbuddy_month_switch');
    Hive.init(tempDir.path);
    await HiveStorage.openSettings();
    store = await _FailingCategoryWriteStore().init()
        as _FailingCategoryWriteStore;
    Get.put<LocalStoreService>(store);
    categoryRepo = Get.put(CategoryRepository());
    Get.put(TransactionRepository());
    settings = _FailingMonthWriteSettings();
    Get.put<SettingsService>(settings);

    await settings.completeOnboarding();
    // Only the current month is populated, so stepping back has a real clone to
    // perform — and a real one to fail.
    await categoryRepo.addCategories([
      category('food', 'Food', thisMonth),
      category('rent', 'Rent', thisMonth),
      category('gym', 'Gym', thisMonth),
    ]);
    await settings.setCurrentMonth(thisMonth);

    controller = Get.put(DashboardController(
      categoryRepo: categoryRepo,
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

  /// A navigator, so `Get.snackbar` has an overlay to live in.
  Future<void> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(const GetMaterialApp(
      home: Scaffold(body: Center(child: Text('dashboard-stub'))),
    ));
    await tester.pumpAndSettle();
  }

  /// Taps a chevron and lets the switch finish.
  ///
  /// `runAsync` because a real Hive write only completes on the real event
  /// loop; the trailing delay covers `_refreshCategories`, which the shipped
  /// code fires without awaiting.
  Future<void> tapChevron(
      WidgetTester tester, Future<void> Function() chevron) async {
    await tester.runAsync(() async {
      await chevron();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    for (var frame = 0; frame < 12; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Closes the snackbar and lets GetX finish with it — GetX's snackbar queue
  /// is static and strictly serial, and one bar left hanging blocks every later
  /// test in the file (see `splash_failure_test.dart` for the measurement).
  Future<void> drainSnackbar(WidgetTester tester) async {
    await tester.runAsync(() async {
      Get.closeAllSnackbars();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    for (var frame = 0; frame < 5; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// AC-D025-3 as one sentence of Dart: the header and the body agree.
  void expectHeaderAgreesWithBody(String reason) {
    for (final c in controller.categories) {
      expect(c.month, settings.currentMonth.value, reason: reason);
    }
  }

  group('AC-D025-3 — the header never silently names an un-cloned month', () {
    testWidgets('the clone fails: the month moves, and the screen says so',
        (tester) async {
      await pumpHost(tester);
      store.failWrites = true;

      await tapChevron(tester, controller.goToPreviousMonth);

      expect(settings.currentMonth.value, lastMonth,
          reason: 'the roll itself succeeded');
      expect(store.readCategories().where((c) => c.month == lastMonth), isEmpty,
          reason: 'the clone is what failed');
      expect(controller.categories, isEmpty,
          reason: 'AC-D025-3: the body must not keep showing THIS month\'s '
              'categories under LAST month\'s header');
      expectHeaderAgreesWithBody('the header names a month the body denies');
      expect(find.byType(GetSnackBar), findsOneWidget,
          reason: 'AC-D025-3: not silently');

      await drainSnackbar(tester);
    });

    testWidgets('the roll fails: the header stays put, and the screen says so',
        (tester) async {
      await pumpHost(tester);
      settings.failWrites = true;

      await tapChevron(tester, controller.goToPreviousMonth);

      expect(settings.currentMonth.value, thisMonth,
          reason: 'nothing moved, so the header must not claim it did');
      expect(controller.categories.map((c) => c.name).toSet(),
          {'Food', 'Rent', 'Gym'});
      expectHeaderAgreesWithBody('the header moved without the body');
      expect(find.byType(GetSnackBar), findsOneWidget,
          reason: 'a chevron that visibly does nothing is still a failed user '
              'action (H3)');

      await drainSnackbar(tester);
    });

    testWidgets('the forward chevron is guarded too', (tester) async {
      // Both entry points go through one guarded method, so they cannot drift
      // — which is the whole reason the pair was extracted.
      await pumpHost(tester);
      await tapChevron(tester, controller.goToPreviousMonth);
      expect(settings.currentMonth.value, lastMonth);
      store.failWrites = true;
      settings.failWrites = true;

      await tapChevron(tester, controller.goToNextMonth);

      expect(settings.currentMonth.value, lastMonth);
      expectHeaderAgreesWithBody('forward switch left the two disagreeing');
      expect(find.byType(GetSnackBar), findsOneWidget);

      await drainSnackbar(tester);
    });

    testWidgets('the copy states what is true now — no "try again later"',
        (tester) async {
      await pumpHost(tester);
      store.failWrites = true;

      await tapChevron(tester, controller.goToPreviousMonth);

      final copy = tester
          .widgetList<Text>(find.descendant(
              of: find.byType(GetSnackBar), matching: find.byType(Text)))
          .map((t) => t.data ?? '')
          .join(' ')
          .toLowerCase();
      expect(copy, contains('your data is safe'));
      expect(copy.contains('try again'), isFalse, reason: 'L2');
      expect(copy.contains('later'), isFalse, reason: 'L2');

      await drainSnackbar(tester);
    });
  });

  group('the guard did not change a healthy switch', () {
    testWidgets('stepping back clones the month and shows it', (tester) async {
      await pumpHost(tester);

      await tapChevron(tester, controller.goToPreviousMonth);

      expect(settings.currentMonth.value, lastMonth);
      expect(controller.categories.map((c) => c.name).toSet(),
          {'Food', 'Rent', 'Gym'});
      expectHeaderAgreesWithBody('a healthy switch must still agree');
      expect(find.byType(GetSnackBar), findsNothing,
          reason: 'crying wolf on a good switch costs the signal on a bad one');
    });

    testWidgets('stepping back and forward returns to the current month',
        (tester) async {
      await pumpHost(tester);

      await tapChevron(tester, controller.goToPreviousMonth);
      await tapChevron(tester, controller.goToNextMonth);

      expect(settings.currentMonth.value, thisMonth);
      expect(controller.categories.map((c) => c.name).toSet(),
          {'Food', 'Rent', 'Gym'});
      expect(find.byType(GetSnackBar), findsNothing);
    });
  });
}

/// A store whose batch category write fails on demand — the `putAll` at
/// `local_store_service.dart:95`, reached from `CategoryRepository.ensureMonth`.
class _FailingCategoryWriteStore extends LocalStoreService {
  bool failWrites = false;

  @override
  Future<void> putCategories(List<Category> categories) async {
    if (failWrites) {
      throw StateError('simulated Hive putAll failure');
    }
    return super.putCategories(categories);
  }
}

/// Settings whose month write fails on demand — `setCurrentMonth`
/// (`settings_service.dart:150`), whose `HiveStorage.setCurrentMonth` is the
/// `_box.put` at `hive_storage.dart:118`. That call is static, so the seam is
/// taken one level up; a throwing `_box.put` produces exactly this.
class _FailingMonthWriteSettings extends SettingsService {
  bool failWrites = false;

  @override
  Future<void> setCurrentMonth(String month) async {
    if (failWrites) {
      throw StateError('simulated Hive put failure');
    }
    return super.setCurrentMonth(month);
  }
}
