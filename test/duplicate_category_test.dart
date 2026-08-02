import 'dart:io';

import 'package:budget_buddy/core/constants/app_constants.dart';
import 'package:budget_buddy/data/local/hive_storage.dart';
import 'package:budget_buddy/data/models/category.dart';
import 'package:budget_buddy/data/models/transaction_item.dart';
import 'package:budget_buddy/data/predefined_categories.dart';
import 'package:budget_buddy/data/repositories/category_repository.dart';
import 'package:budget_buddy/modules/categories/widgets/category_card.dart';
import 'package:budget_buddy/modules/category_form/category_form_controller.dart';
import 'package:budget_buddy/modules/category_form/category_form_view.dart';
import 'package:budget_buddy/services/app/settings_service.dart';
import 'package:budget_buddy/services/local/local_store_service.dart';
import 'package:budget_buddy/utils/currency_utils.dart';
import 'package:budget_buddy/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// F-08 — one tap could create a data-quality defect.
///
/// Quick Select offered all nine presets regardless of what the month already
/// held, and save had no name check at all. Tapping "Food" a second time created
/// a second Food with its own budget, and the month's spend then split across
/// two authoritative-looking rows with nothing in the app to explain it.
///
/// Plus FD-12: the reserved bucket's edit pencil, which was still on screen
/// after F-01 gave the repository the power to refuse the rename it opens.
void main() {
  late Directory tempDir;
  late CategoryRepository categories;
  late SettingsService settings;

  final thisMonth = AppDateUtils.getCurrentMonthKey();
  final lastMonth = AppDateUtils.getPreviousMonthKey(thisMonth);

  Category category({
    required String id,
    required String name,
    String? month,
  }) =>
      Category(
        id: id,
        name: name,
        budgetLimitMinor: 500000,
        colorValue: 0xFF2D8B8B,
        iconCodePoint: Icons.restaurant.codePoint,
        month: month ?? thisMonth,
        createdAt: DateTime(2026, 1, 1, 9),
        updatedAt: DateTime(2026, 1, 1, 9),
      );

  setUpAll(() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CategoryAdapter());
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionItemAdapter());
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('buddgetbuddy_dupes');
    Hive.init(tempDir.path);
    await HiveStorage.openSettings();
    Get.put<LocalStoreService>(await LocalStoreService().init());
    categories = Get.put(CategoryRepository());
    settings = Get.put(SettingsService());
    await settings.setCurrentMonth(thisMonth);
    Get.testMode = true;
  });

  tearDown(() async {
    Get.testMode = false;
    Get.reset();
    await Hive.deleteFromDisk();
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// A form controller with its category stream settled. [editing] mirrors the
  /// route argument the Categories tab passes.
  Future<CategoryFormController> openForm({Category? editing}) async {
    if (Get.isRegistered<CategoryFormController>()) {
      Get.delete<CategoryFormController>();
    }
    final ctrl = CategoryFormController(
      categoryRepo: categories,
      settings: settings,
    );
    if (editing != null) {
      // Same effect as arriving with the category as a route argument; onInit
      // reads Get.arguments, which a testMode navigation does not carry.
      ctrl.editingCategory = editing;
      ctrl.nameController.text = editing.name;
    }
    Get.put(ctrl);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return ctrl;
  }

  group('Quick Select offers only what is missing', () {
    test('AC-1: a preset that already exists is not offered', () async {
      await categories.addCategory(category(id: 'food', name: 'Food'));
      final ctrl = await openForm();

      final offered = ctrl.availablePresets.map((e) => e.value.name).toList();
      expect(offered, isNot(contains('Food')));
      expect(offered, hasLength(kPredefinedCategories.length - 1));
    });

    test('the compare is case-insensitive and trimmed', () async {
      await categories.addCategory(category(id: 'food', name: '  fOOd '));
      final ctrl = await openForm();

      expect(ctrl.availablePresets.map((e) => e.value.name), isNot(contains('Food')));
    });

    test('AC-6: with all nine present there is nothing left to offer',
        () async {
      await categories.addCategories([
        for (var i = 0; i < kPredefinedCategories.length; i++)
          category(id: 'seed-$i', name: kPredefinedCategories[i].name),
      ]);
      final ctrl = await openForm();

      expect(ctrl.availablePresets, isEmpty,
          reason: 'the view drops the header and the divider with the chips');
    });

    test('another month\'s categories do not shrink this month\'s offer',
        () async {
      await categories.addCategory(
          category(id: 'food-last', name: 'Food', month: lastMonth));
      final ctrl = await openForm();

      expect(ctrl.availablePresets.map((e) => e.value.name), contains('Food'),
          reason: 'each month is its own namespace by construction');
    });

    test('a surviving preset keeps its index in the full preset list', () async {
      // selectPreset speaks the index in kPredefinedCategories; filtering must
      // not renumber, or a chip fills the form with the wrong preset.
      await categories.addCategory(category(id: 'food', name: 'Food'));
      final ctrl = await openForm();

      for (final entry in ctrl.availablePresets) {
        expect(kPredefinedCategories[entry.key].name, entry.value.name);
      }
    });
  });

  group('the name a user types', () {
    test('AC-2: a case-different duplicate is refused, with the real name back',
        () async {
      await categories.addCategory(category(id: 'food', name: 'Food'));
      final ctrl = await openForm();

      expect(ctrl.validateName('food'), 'You already have a "Food" category',
          reason: 'the message names the category that IS there, in its own '
              'spelling');
    });

    test('AC-3: a trailing space does not make it a new category', () async {
      await categories.addCategory(category(id: 'food', name: 'Food'));
      final ctrl = await openForm();

      expect(ctrl.validateName('Food '), isNotNull);
    });

    test('a genuinely new name passes', () async {
      await categories.addCategory(category(id: 'food', name: 'Food'));
      final ctrl = await openForm();

      expect(ctrl.validateName('Groceries'), isNull);
    });

    test('AC-5: the reserved name is refused outright', () async {
      final ctrl = await openForm();

      expect(ctrl.validateName(kUncategorisedCategoryName),
          '"$kUncategorisedCategoryName" is a reserved name');
      expect(ctrl.validateName(' uncategorised '), isNotNull,
          reason: 'reserved is reserved however it is typed');
    });

    test('the shared rules still run first', () async {
      final ctrl = await openForm();

      expect(ctrl.validateName(''), 'Category name is required');
      expect(ctrl.validateName('x' * 31), 'Name must be under 30 characters');
    });

    test('AC-4: a rename may not take another category\'s name, but may keep '
        'its own', () async {
      await categories.addCategories([
        category(id: 'transport', name: 'Transport'),
        category(id: 'health', name: 'Health'),
      ]);
      final ctrl =
          await openForm(editing: category(id: 'transport', name: 'Transport'));

      expect(ctrl.validateName('Health'), isNotNull,
          reason: 'renaming onto another row is the same duplicate by another '
              'route');
      expect(ctrl.validateName('Transport'), isNull,
          reason: 'its own name, unchanged, is always allowed');
      expect(ctrl.validateName('Transportation'), isNull);
      expect(ctrl.validateName(kUncategorisedCategoryName), isNotNull,
          reason: 'without the rename half, any category could hijack the '
              'system bucket');
    });

    test('save writes nothing when the name is taken', () async {
      await categories.addCategory(category(id: 'food', name: 'Food'));
      final ctrl = await openForm();
      ctrl.nameController.text = 'food';
      ctrl.budgetController.text = '500';

      await ctrl.save();

      expect(Get.find<LocalStoreService>().readCategories(), hasLength(1),
          reason: 'the validator is what the user sees; save must not be the '
              'hole it walks through');
    });

    test('save still writes a fresh name', () async {
      final ctrl = await openForm();
      ctrl.nameController.text = ' Groceries ';
      ctrl.budgetController.text = '500';

      await ctrl.save();

      final stored = Get.find<LocalStoreService>().readCategories();
      expect(stored, hasLength(1));
      expect(stored.single.name, 'Groceries', reason: 'trimmed before saving');
      expect(stored.single.month, thisMonth);
    });
  });

  group('FD-12: the reserved bucket has no edit affordance', () {
    final pkr = CurrencyUtils.currencies.firstWhere((c) => c.code == 'PKR');

    Future<void> pumpCard(WidgetTester tester,
            {required Category subject, VoidCallback? onEdit}) =>
        tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: CategoryCard(
              category: subject,
              spentMinor: 0,
              currency: pkr,
              onTap: () {},
              onEdit: onEdit,
            ),
          ),
        ));

    testWidgets('an ordinary category still shows its pencil', (tester) async {
      await pumpCard(tester,
          subject: category(id: 'food', name: 'Food'), onEdit: () {});
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });

    testWidgets('with no edit callback the pencil is absent, not disabled',
        (tester) async {
      await pumpCard(tester,
          subject:
              category(id: 'bucket', name: kUncategorisedCategoryName));
      expect(find.byIcon(Icons.edit_outlined), findsNothing,
          reason: 'an affordance that exists only to refuse is worse than '
              'none (danish 8b)');
    });

    testWidgets('and the form it used to open still hides delete',
        (tester) async {
      // Unreachable from the Categories tab now, but the second guard stays:
      // the repository refuses the delete either way, and nothing should ever
      // offer it.
      await tester.pumpWidget(const GetMaterialApp(
          home: Scaffold(body: Center(child: Text('home')))));
      Get.to(() => const CategoryFormView(),
          arguments: category(id: 'bucket', name: kUncategorisedCategoryName));
      await tester.pumpAndSettle();

      expect(find.text('Edit Category'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
      expect(find.text('Quick Select'), findsNothing,
          reason: 'presets belong to creation, not to editing');
    });
  });
}
