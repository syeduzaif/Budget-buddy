import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../services/local/local_store_service.dart';
import '../../utils/date_utils.dart';
import '../models/category.dart';
import '../models/transaction_item.dart';

/// Refusal of a write that would break the reserved bucket's contract:
/// renaming it, deleting it, or minting a second category under its name.
///
/// Thrown from the repository so BOTH delete entry points and BOTH name-write
/// entry points are covered by one rule; controllers already catch and surface
/// write failures with `Get.snackbar` (H3).
class ReservedCategoryException implements Exception {
  final String message;
  const ReservedCategoryException(this.message);

  @override
  String toString() => 'ReservedCategoryException: $message';
}

/// What [CategoryRepository.resolveForMonth] decided.
class CategoryResolution {
  /// The category the transaction must be attributed to.
  final Category category;

  /// True when the picked category no longer existed and the transaction went
  /// to the reserved bucket instead. The caller tells the user — a deleted
  /// category is never resurrected behind their back.
  final bool pickedWasDeleted;

  const CategoryResolution(this.category, {required this.pickedWasDeleted});
}

/// Categories, and the ONE place transaction attribution is decided.
///
/// Every month holds its own clones of the user's categories — same names,
/// fresh `id`s — so "which category does this transaction belong to?" is a
/// question about the transaction's DATE-month, never about the month the user
/// happens to be looking at. Answering it in several places is how the app
/// grew three different answers (F-01 paths A/A'/B: back-dating, past-month
/// add, delete-orphans), each of which broke the invariant that a month's
/// Spent equals the sum of the rows shown beneath it.
///
/// [resolveForMonth] is the single answer and every write site calls it
/// (mechanism (a), adil's D6 dry-run ruling). Three divergent copies of this
/// logic is the recorded trigger to abandon (a) for stable cross-month
/// category identity — so if you are about to write a fourth attribution rule
/// somewhere else, that is the decision to reopen, not the code to duplicate.
class CategoryRepository extends GetxService {
  final LocalStoreService _store = Get.find<LocalStoreService>();

  static const Uuid _uuid = Uuid();

  /// In-flight ensures, keyed by month. Two callers that overlap at an `await`
  /// (a chevron tap while the launch roll is still running, say) must produce
  /// ONE set of clones, not two — 18 categories where 9 belong.
  final Map<String, Future<void>> _ensureInFlight = {};
  final Map<String, Future<Category>> _uncategorisedInFlight = {};

  /// Live list of every category, newest first.
  Stream<List<Category>> getCategories() => _store.watchCategories();

  /// Adds a user category.
  ///
  /// Refuses the reserved name: the bucket is minted by
  /// [ensureUncategorised] alone, so a month can never hold two of them.
  Future<void> addCategory(Category category) async {
    _refuseReservedName(category.name);
    await _store.putCategory(category);
  }

  Future<void> addCategories(List<Category> categories) async {
    for (final category in categories) {
      _refuseReservedName(category.name);
    }
    await _store.putCategories(categories);
  }

  /// Updates a category. The reserved bucket may be re-coloured, but not
  /// renamed — and no ordinary category may be renamed into its name.
  Future<void> updateCategory(Category category) async {
    final stored = _byId(_store.readCategories(), category.id);
    final storedIsReserved = stored != null && isReservedCategoryName(stored.name);
    if (storedIsReserved && !isReservedCategoryName(category.name)) {
      throw const ReservedCategoryException(
          '"$kUncategorisedCategoryName" cannot be renamed.');
    }
    if (!storedIsReserved && isReservedCategoryName(category.name)) {
      throw const ReservedCategoryException(
          '"$kUncategorisedCategoryName" is a reserved name.');
    }
    await _store.putCategory(category);
  }

  /// Deletes a category, keeping its transactions.
  ///
  /// Re-points them FIRST — each to the reserved bucket of its OWN date-month
  /// — and deletes only once every re-point has landed. Order is load-bearing:
  /// delete-then-re-point manufactures exactly the orphans this exists to
  /// prevent, and a failure here throws with nothing lost, so the caller's
  /// failure snackbar is the truth (F-01 rule 3).
  ///
  /// Re-pointing is part of deleting, not a safer variant callers may forget:
  /// there is one delete method and both entry points (Categories-tab swipe,
  /// category-form delete) go through it.
  Future<void> deleteCategory(String id) async {
    final category = _byId(_store.readCategories(), id);
    if (category == null) {
      // Already gone. Keep the box call so a stale id still clears.
      await _store.deleteCategory(id);
      return;
    }
    if (isReservedCategoryName(category.name)) {
      throw const ReservedCategoryException(
          '"$kUncategorisedCategoryName" cannot be deleted — it is where '
          'transactions go when their category is.');
    }

    final orphaned =
        _store.readTransactions().where((t) => t.categoryId == id).toList();
    if (orphaned.isNotEmpty) {
      final now = DateTime.now();
      final repointed = <TransactionItem>[];
      for (final t in orphaned) {
        final bucket = await ensureUncategorised(
            AppDateUtils.getMonthKeyFromDate(t.date));
        // A fresh instance, never the one that came out of the box: Hive
        // throws if a single HiveObject is stored under two keys.
        repointed.add(TransactionItem(
          id: t.id,
          categoryId: bucket.id,
          amountMinor: t.amountMinor,
          note: t.note,
          date: t.date,
          createdAt: t.createdAt,
          updatedAt: now,
          synced: t.synced,
        ));
      }
      // One batch: a half-applied re-point would leave some transactions
      // pointing at a category that is about to disappear.
      await _store.putTransactions(repointed);
    }

    await _store.deleteCategory(id);
  }

  /// Removes every category. Used by the "erase all data" flow.
  ///
  /// Deliberately below the reserved-name guard: erasing everything erases the
  /// bucket too.
  Future<void> deleteAll() => _store.clearCategories();

  /// One-shot fetch of categories for a specific month key (e.g. "2026-03").
  Future<List<Category>> getCategoriesForMonth(String month) async =>
      _store.readCategoriesForMonth(month);

  /// One-shot read of every month's categories, newest first.
  ///
  /// For callers that need the whole set once rather than a live view — the CSV
  /// export, which names each transaction's category as it was in that month.
  Future<List<Category>> getAllCategories() async => _store.readCategories();

  // --- Attribution ----------------------------------------------------------

  /// Gives [monthKey] the same category structure as the nearest month that
  /// has one — names, colours, icons and limits carried, spend starting at 0.
  ///
  /// A no-op when the month already holds a user category, so launching twice,
  /// tapping the chevrons, and the save-time resolver can all call it freely.
  /// Idempotence is not enough on its own: overlapping callers are
  /// de-duplicated through [_ensureInFlight], because two ensures that both
  /// pass the emptiness check before either writes would each clone the whole
  /// set.
  ///
  /// Reads the box ONCE and groups by month. The per-month probe this replaces
  /// re-read and re-sorted the entire box up to 14 times, which is now on the
  /// launch path (F-02) that the splash budgets at 800 ms.
  ///
  /// The reserved bucket is never cloned forward, and a month holding only the
  /// bucket still counts as empty — otherwise deleting a month's last real
  /// category would freeze that month empty forever.
  ///
  /// Limits follow FD-1's DIRECTION rule, not the caller's identity: a forward
  /// rollover (the current month, or a month ahead of it) carries limits, while
  /// filling in a month that has already happened carries 0 — see
  /// [_isBackwardFill]. Browsing '‹' into an unvisited past month is a backward
  /// fill, so it must not hand that month a budget structure the user never set
  /// (BUG-120).
  ///
  /// [nowMonthKey] is a test seam, not a clock dependency: the default reads
  /// the real clock. Threading it through the launch/resume rollover keeps
  /// simulated-clock tests independent of the machine's actual date.
  Future<void> ensureMonth(
    String monthKey, {
    String Function() nowMonthKey = AppDateUtils.getCurrentMonthKey,
  }) {
    final existing = _ensureInFlight[monthKey];
    // De-duplication is by target month only: an in-flight ensure for M wins,
    // whatever seam the second caller brought. Every production caller reads
    // the same real clock, so the seam can only differ inside tests.
    if (existing != null) return existing;
    // Block body, not an arrow: `Map.remove` returns the very future this
    // callback belongs to, and a `whenComplete` callback that RETURNS a future
    // waits for it — an instant deadlock.
    final future = _ensureMonth(monthKey, nowMonthKey).whenComplete(() {
      _ensureInFlight.remove(monthKey);
    });
    _ensureInFlight[monthKey] = future;
    return future;
  }

  Future<void> _ensureMonth(
      String monthKey, String Function() nowMonthKey) async {
    final byMonth = _groupByMonth(_store.readCategories());
    if (_userCategories(byMonth, monthKey).isNotEmpty) return;

    final source = _nearestSource(byMonth, monthKey);
    if (source == null) return; // nothing anywhere to clone yet

    final backward = _isBackwardFill(monthKey, nowMonthKey);
    final now = DateTime.now();
    await _store.putCategories([
      for (final cat in source)
        _cloneInto(
            cat, monthKey, now, backward ? 0 : cat.budgetLimitMinor),
    ]);
  }

  /// The reserved bucket for [monthKey], created on demand.
  ///
  /// Zero limit by construction: the bucket must never make a budget claim
  /// nobody set (F-09 renders it as "No limit set").
  Future<Category> ensureUncategorised(String monthKey) {
    final existing = _uncategorisedInFlight[monthKey];
    if (existing != null) return existing;
    // Block body — see [ensureMonth].
    final future = _ensureUncategorised(monthKey).whenComplete(() {
      _uncategorisedInFlight.remove(monthKey);
    });
    _uncategorisedInFlight[monthKey] = future;
    return future;
  }

  Future<Category> _ensureUncategorised(String monthKey) async {
    final found = _oldestByName(
        _store.readCategories(), monthKey, kUncategorisedCategoryName);
    if (found != null) return found;

    final now = DateTime.now();
    final bucket = Category(
      id: _uuid.v4(),
      name: kUncategorisedCategoryName,
      budgetLimitMinor: 0,
      colorValue: kUncategorisedColorValue,
      iconCodePoint: kUncategorisedIcon.codePoint,
      month: monthKey,
      createdAt: now,
      updatedAt: now,
    );
    await _store.putCategory(bucket);
    return bucket;
  }

  /// Decides which category a transaction dated into [monthKey] belongs to.
  ///
  /// The order, and why each step exists:
  ///
  /// 0. **Live id first.** [picked] may be a stale copy held by an open form.
  ///    If it no longer exists the transaction goes to the reserved bucket and
  ///    the caller says so — a deleted category is never resurrected.
  /// 1. **Fast path.** Already the right month: return it, write nothing.
  /// 2. **Whole-month ensure.** A month nobody has visited gets the user's
  ///    whole structure, not one lonely row (`ensureMonth` no-ops otherwise).
  /// 3. **Name match**, trimmed and case-insensitive — name is this app's
  ///    operative category identity, and the oldest `createdAt` wins so the
  ///    answer is stable when duplicates exist.
  /// 4. **Single back-fill clone.** A clone into a PAST month carries 0; the
  ///    current month (and anything ahead of it) carries the limit — FD-1:
  ///    forward rollover carries limits, backward back-fill does not, so the
  ///    app cannot invent a budget the user never set for a month that has
  ///    already happened. Same test — [_isBackwardFill] — as step 2's ensure.
  ///
  /// [nowMonthKey] is a seam for tests, not a clock dependency: the default is
  /// the real current month.
  Future<CategoryResolution> resolveForMonth(
    Category? picked,
    String monthKey, {
    String Function() nowMonthKey = AppDateUtils.getCurrentMonthKey,
  }) async {
    if (picked == null) {
      return CategoryResolution(await ensureUncategorised(monthKey),
          pickedWasDeleted: false);
    }

    final live = _byId(_store.readCategories(), picked.id);
    if (live == null) {
      return CategoryResolution(await ensureUncategorised(monthKey),
          pickedWasDeleted: true);
    }

    if (live.month == monthKey) {
      return CategoryResolution(live, pickedWasDeleted: false);
    }

    // The bucket is per-month like everything else, but it is created rather
    // than cloned — one find-or-create, so a month cannot end up with two.
    if (isReservedCategoryName(live.name)) {
      return CategoryResolution(await ensureUncategorised(monthKey),
          pickedWasDeleted: false);
    }

    await ensureMonth(monthKey, nowMonthKey: nowMonthKey);

    final match = _oldestByName(_store.readCategories(), monthKey, live.name);
    if (match != null) {
      return CategoryResolution(match, pickedWasDeleted: false);
    }

    final backfillLimitMinor =
        _isBackwardFill(monthKey, nowMonthKey) ? 0 : live.budgetLimitMinor;
    final clone =
        _cloneInto(live, monthKey, DateTime.now(), backfillLimitMinor);
    await _store.putCategory(clone);
    return CategoryResolution(clone, pickedWasDeleted: false);
  }

  // --- Internals ------------------------------------------------------------

  /// FD-1 in one place: is cloning into [monthKey] a BACKWARD fill?
  ///
  /// "Forward rollover clones carry limits; backward back-fill does not." The
  /// rule is about direction, so both clone paths — the whole-month
  /// [ensureMonth] and the single-category back-fill in [resolveForMonth] —
  /// must ask the same question, or they drift and only one of them obeys the
  /// spec (which is exactly what BUG-120 caught).
  ///
  /// `"YYYY-MM"` keys are fixed-width and zero-padded, so a lexicographic
  /// compare IS a chronological compare — no parsing, no timezone, no
  /// `DateFormat` (which would render non-ASCII digits under fa/ar_EG).
  /// Strictly *before* the current month: the current month carries limits (the
  /// budget is live), and so does anything ahead of it (forward rollover).
  static bool _isBackwardFill(String monthKey, String Function() nowMonthKey) =>
      monthKey.compareTo(nowMonthKey()) < 0;

  void _refuseReservedName(String name) {
    if (isReservedCategoryName(name)) {
      throw const ReservedCategoryException(
          '"$kUncategorisedCategoryName" is a reserved name.');
    }
  }

  /// A clone of [source] stamped into [monthKey].
  ///
  /// `createdAt` is the real time of the write, NOT a date inside the target
  /// month. That mismatch — a record whose `createdAt` month differs from its
  /// `month` — is the only trail showing a category was back-filled rather
  /// than budgeted at the time. Do not "tidy" it (adil, test T13).
  Category _cloneInto(
    Category source,
    String monthKey,
    DateTime now,
    int budgetLimitMinor,
  ) =>
      Category(
        id: _uuid.v4(),
        name: source.name,
        budgetLimitMinor: budgetLimitMinor,
        colorValue: source.colorValue,
        iconCodePoint: source.iconCodePoint,
        month: monthKey,
        createdAt: now,
        updatedAt: now,
      );

  Map<String, List<Category>> _groupByMonth(List<Category> all) {
    final byMonth = <String, List<Category>>{};
    for (final c in all) {
      byMonth.putIfAbsent(c.month, () => <Category>[]).add(c);
    }
    return byMonth;
  }

  /// The categories of [monthKey] that the user actually manages — the
  /// reserved bucket does not make a month "populated".
  List<Category> _userCategories(
          Map<String, List<Category>> byMonth, String monthKey) =>
      (byMonth[monthKey] ?? const <Category>[])
          .where((c) => !isReservedCategoryName(c.name))
          .toList();

  /// The month to clone from: the month before, then the month after (the user
  /// may have browsed backwards first), then up to twelve further months back.
  /// Nothing older — a back-date beyond that correctly degrades to a single
  /// back-fill clone rather than resurrecting a year-old structure.
  List<Category>? _nearestSource(
      Map<String, List<Category>> byMonth, String monthKey) {
    var probe = AppDateUtils.getPreviousMonthKey(monthKey);
    final candidates = <String>[probe, AppDateUtils.getNextMonthKey(monthKey)];
    for (var i = 0; i < 12; i++) {
      probe = AppDateUtils.getPreviousMonthKey(probe);
      candidates.add(probe);
    }
    for (final month in candidates) {
      final users = _userCategories(byMonth, month);
      if (users.isNotEmpty) return users;
    }
    return null;
  }

  Category? _byId(List<Category> all, String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// The oldest category in [monthKey] whose name matches [name] under the
  /// resolver's comparison (trimmed, case-insensitive), with `id` as the
  /// tie-break so the answer does not depend on box iteration order.
  Category? _oldestByName(List<Category> all, String monthKey, String name) {
    final key = _matchKey(name);
    Category? best;
    for (final c in all) {
      if (c.month != monthKey || _matchKey(c.name) != key) continue;
      if (best == null ||
          c.createdAt.isBefore(best.createdAt) ||
          (c.createdAt == best.createdAt && c.id.compareTo(best.id) < 0)) {
        best = c;
      }
    }
    return best;
  }

  static String _matchKey(String name) => name.trim().toLowerCase();
}
