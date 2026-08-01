import 'dart:async';
import 'dart:io';

import 'package:budget_buddy/data/models/category.dart';
import 'package:budget_buddy/data/models/transaction_item.dart';
import 'package:budget_buddy/services/local/local_store_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// C4 changed field 2 of both models from a `double` of major units to an
/// `int` of minor units, reusing the same field index. A box written by a
/// pre-C4 build therefore cannot be decoded by the current adapters — and it
/// is opened during `main()`, before any screen exists to show an error.
///
/// These tests exercise that exact path with a real legacy record on disk.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('buddgetbuddy_migration');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('a pre-C4 box is reset instead of crashing at startup', () async {
    // 1. Write a record the way the float build did: typeId 0, field 2 is a
    //    double of major units.
    //    `override` swaps the adapter for typeId 0 without Hive.resetAdapters,
    //    which would also unregister Hive's built-in DateTime adapter.
    Hive.registerAdapter<_LegacyCategory>(_LegacyCategoryAdapter(),
        override: true);
    final legacy = await Hive.openBox<_LegacyCategory>('categories');
    await legacy.put('a', _LegacyCategory());
    await legacy.close();

    // 2. Today's build starts up against it.
    Hive.registerAdapter<Category>(CategoryAdapter(), override: true);
    Hive.registerAdapter<TransactionItem>(TransactionItemAdapter(),
        override: true);

    final store = await _initAbsorbingHiveStrayError();

    // The unreadable box is gone rather than fatal, and the app is usable.
    expect(store.readCategories(), isEmpty);
    await store.putCategory(Category(
      id: 'new',
      name: 'Food',
      budgetLimitMinor: 50000,
      colorValue: 0,
      month: '2026-08',
      createdAt: DateTime(2026, 8, 1),
      updatedAt: DateTime(2026, 8, 1),
    ));
    expect(store.readCategories().single.budgetLimitMinor, 50000);
  });

  test('a healthy box is opened untouched', () async {
    Hive.registerAdapter<Category>(CategoryAdapter(), override: true);
    Hive.registerAdapter<TransactionItem>(TransactionItemAdapter(),
        override: true);

    final first = await LocalStoreService().init();
    await first.putCategory(Category(
      id: 'keep',
      name: 'Rent',
      budgetLimitMinor: 120000,
      colorValue: 0,
      month: '2026-08',
      createdAt: DateTime(2026, 8, 1),
      updatedAt: DateTime(2026, 8, 1),
    ));
    await Hive.close();

    final second = await LocalStoreService().init();
    expect(second.readCategories().single.id, 'keep');
    expect(second.readCategories().single.budgetLimitMinor, 120000);
  });
}

/// Runs `LocalStoreService.init()` and swallows one specific piece of noise.
///
/// When `openBox` fails, Hive completes an internal completer with the error
/// (`hive_impl.dart:116`) that nothing is listening to, so it also surfaces as
/// an unhandled ASYNC error — separately from the synchronous throw our guard
/// already caught. In the app that is a printed stack; under `flutter_test`
/// an unhandled async error fails the test. Real failures still propagate:
/// they come back through the completer.
Future<LocalStoreService> _initAbsorbingHiveStrayError() {
  final completer = Completer<LocalStoreService>();
  runZonedGuarded(
    () async {
      try {
        completer.complete(await LocalStoreService().init());
      } catch (e, s) {
        completer.completeError(e, s);
      }
    },
    (error, stack) {
      // ignore: avoid_print
      print('absorbed Hive stray async error: $error');
    },
  );
  return completer.future;
}

/// Stand-in for the pre-C4 `Category`: same typeId, same field indices, but
/// field 2 is a `double`.
class _LegacyCategory {}

class _LegacyCategoryAdapter extends TypeAdapter<_LegacyCategory> {
  @override
  final int typeId = 0;

  @override
  _LegacyCategory read(BinaryReader reader) => _LegacyCategory();

  @override
  void write(BinaryWriter writer, _LegacyCategory obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write('legacy-id')
      ..writeByte(1)
      ..write('Food')
      ..writeByte(2)
      ..write(500.0) // the float budget this migration exists to retire
      ..writeByte(3)
      ..write(0)
      ..writeByte(4)
      ..write('2026-07')
      ..writeByte(5)
      ..write(DateTime(2026, 7, 1))
      ..writeByte(6)
      ..write(DateTime(2026, 7, 1))
      ..writeByte(7)
      ..write(false)
      ..writeByte(8)
      ..write(null);
  }
}
