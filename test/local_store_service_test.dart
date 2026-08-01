import 'dart:io';

import 'package:budget_buddy/data/models/category.dart';
import 'package:budget_buddy/data/models/transaction_item.dart';
import 'package:budget_buddy/data/repositories/category_repository.dart';
import 'package:budget_buddy/data/repositories/transaction_repository.dart';
import 'package:budget_buddy/services/local/local_store_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// Covers the local Hive store that replaced Firestore: ordering, live stream
/// behaviour, and the repository surface the controllers depend on.
void main() {
  late Directory tempDir;
  late LocalStoreService store;

  Category category(String id, {DateTime? createdAt, String month = '2026-08'}) {
    final now = createdAt ?? DateTime(2026, 8, 1);
    return Category(
      id: id,
      name: 'Cat $id',
      budgetLimitMinor: 10000,
      colorValue: 0xFF2D8B8B,
      month: month,
      createdAt: now,
      updatedAt: now,
    );
  }

  TransactionItem transaction(String id, {required DateTime date}) =>
      TransactionItem(
        id: id,
        categoryId: 'c1',
        amountMinor: 1000,
        note: 'note $id',
        date: date,
        createdAt: date,
        updatedAt: date,
      );

  setUpAll(() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CategoryAdapter());
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionItemAdapter());
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('buddgetbuddy_test');
    Hive.init(tempDir.path);
    store = await LocalStoreService().init();
    Get.put<LocalStoreService>(store);
  });

  tearDown(() async {
    Get.reset();
    await Hive.deleteFromDisk();
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('LocalStoreService', () {
    test('categories come back newest-created first', () async {
      await store.putCategory(category('a', createdAt: DateTime(2026, 1, 1)));
      await store.putCategory(category('b', createdAt: DateTime(2026, 3, 1)));
      await store.putCategory(category('c', createdAt: DateTime(2026, 2, 1)));

      expect(store.readCategories().map((c) => c.id), ['b', 'c', 'a']);
    });

    test('transactions come back newest-dated first', () async {
      await store.putTransaction(transaction('a', date: DateTime(2026, 1, 5)));
      await store.putTransaction(transaction('b', date: DateTime(2026, 4, 5)));

      expect(store.readTransactions().map((t) => t.id), ['b', 'a']);
    });

    test('a put of an existing id updates in place rather than duplicating',
        () async {
      await store.putCategory(category('a'));
      final renamed = category('a')..name = 'Renamed';
      await store.putCategory(renamed);

      final all = store.readCategories();
      expect(all, hasLength(1));
      expect(all.single.name, 'Renamed');
    });

    test('watch emits current contents immediately, then on every change',
        () async {
      await store.putCategory(category('a'));

      final emissions = <List<String>>[];
      final sub = store
          .watchCategories()
          .listen((list) => emissions.add(list.map((c) => c.id).toList()));

      await pumpEventQueue();
      expect(emissions, [
        ['a']
      ], reason: 'initial emission must arrive without waiting for a change');

      await store.putCategory(category('b', createdAt: DateTime(2026, 9, 1)));
      await pumpEventQueue();
      expect(emissions.last, ['b', 'a']);

      await store.deleteCategory('a');
      await pumpEventQueue();
      expect(emissions.last, ['b']);

      await sub.cancel();
    });

    test('clearing a box re-emits an empty list to live listeners', () async {
      await store.putCategory(category('a'));

      final emissions = <int>[];
      final sub = store.watchCategories().listen((l) => emissions.add(l.length));
      await pumpEventQueue();

      await store.clearCategories();
      await pumpEventQueue();

      expect(emissions.last, 0);
      await sub.cancel();
    });
  });

  group('repository surface', () {
    late CategoryRepository categories;
    late TransactionRepository transactions;

    setUp(() {
      categories = Get.put(CategoryRepository());
      transactions = Get.put(TransactionRepository());
    });

    test('addCategories writes the whole batch', () async {
      await categories.addCategories([category('a'), category('b')]);
      expect(store.readCategories(), hasLength(2));
    });

    test('getCategoriesForMonth filters by month key', () async {
      await categories.addCategories([
        category('a', month: '2026-08'),
        category('b', month: '2026-09'),
      ]);

      final august = await categories.getCategoriesForMonth('2026-08');
      expect(august.map((c) => c.id), ['a']);
    });

    test('getCategories().first resolves — month auto-clone depends on it',
        () async {
      await categories.addCategory(category('a'));
      expect(await categories.getCategories().first, hasLength(1));
    });

    test('deleteAll empties both boxes', () async {
      await categories.addCategory(category('a'));
      await transactions.addTransaction(
        transaction('t', date: DateTime(2026, 8, 2)),
      );

      await categories.deleteAll();
      await transactions.deleteAll();

      expect(store.readCategories(), isEmpty);
      expect(store.readTransactions(), isEmpty);
    });
  });
}
