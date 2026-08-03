import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction_item.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../services/app/settings_service.dart';
import '../../utils/currency_utils.dart';
import '../../utils/date_utils.dart';

class TransactionFormController extends GetxController {
  final CategoryRepository categoryRepo;
  final TransactionRepository transactionRepo;
  final SettingsService settings;

  /// The record being edited, or null when adding a new one.
  ///
  /// A SNAPSHOT taken when the sheet opened, never the box's own instance: it
  /// supplies the prefill and the `id`/`createdAt` to write back with, and
  /// nothing else about it is trusted at save time — the resolver re-reads the
  /// category live, because the sheet may have been open for a while (F-01).
  final TransactionItem? editing;

  /// The category a category-scoped entry point asked for, or null.
  ///
  /// A constructor argument rather than a `Get.arguments` read: the form is a
  /// SHEET, so `Get.arguments` belongs to whatever page is underneath it —
  /// opening this over the category-filtered transactions list would have
  /// silently picked up that screen's `{categoryId, categoryName}`.
  final String? preselectedCategoryId;

  TransactionFormController({
    required this.categoryRepo,
    required this.transactionRepo,
    required this.settings,
    this.editing,
    this.preselectedCategoryId,
  });

  final amountController = TextEditingController();
  final noteController = TextEditingController();
  final categories = <Category>[].obs;
  final selectedCategory = Rxn<Category>();
  final selectedDate = DateTime.now().obs;
  final isLoading = false.obs;

  /// True when the sheet is correcting an existing record rather than creating
  /// one. Drives the title, the save button's label, and which write the
  /// repository is asked for.
  bool get isEditing => editing != null;

  /// How long a success confirmation stays up. Long enough to read the amount
  /// back, short enough not to sit over the next save (F-05).
  static const Duration confirmationDuration = Duration(seconds: 4);

  /// The date a newly opened sheet starts on, for a user viewing [viewedMonth].
  ///
  /// Viewing the current month (or, defensively, a future one — the month
  /// chevron itself is unbounded) keeps today. Viewing a PAST month starts on
  /// the 1st of that month: the old unconditional `DateTime.now()` meant
  /// browsing to July and tapping Add silently filed the expense in August,
  /// against August's category clone (F-01 path A′). Month keys are
  /// zero-padded `YYYY-MM`, so comparing them as strings is chronological.
  static DateTime defaultDateForMonth(String viewedMonth, DateTime now) {
    if (viewedMonth.compareTo(AppDateUtils.getMonthKeyFromDate(now)) >= 0) {
      return now;
    }
    return AppDateUtils.parseMonthKey(viewedMonth) ?? now;
  }

  @override
  void onInit() {
    super.onInit();
    final edited = editing;
    if (edited != null) {
      // Minor units are never shown raw: back to major-unit text, in exactly
      // the shape the field parses again.
      final amountText =
          CurrencyUtils.formatForInput(edited.amountMinor, settings.currency);
      // SELECTED, not merely prefilled. The field autofocuses, and
      // `TextEditingController.text` leaves the selection invalid, which a
      // focused field resolves to a caret at the END — so digits typed
      // straight into the sheet APPENDED to the old amount: 100 then "120"
      // saved ₨100,120 (BUG-081, and the amplifier that turned BUG-080's
      // swallowed tap into money corruption). Selected means the first
      // keystroke replaces, which is what "correct this amount" means; a user
      // who wants to append still taps to place the caret.
      amountController.value = TextEditingValue(
        text: amountText,
        selection: TextSelection(baseOffset: 0, extentOffset: amountText.length),
      );
      noteController.text = edited.note;
      selectedDate.value = edited.date;
    } else {
      selectedDate.value =
          defaultDateForMonth(settings.effectiveMonth, DateTime.now());
    }

    categoryRepo.getCategories().listen(
      (list) {
        final filtered = orderForPicker(
            list.where((c) => c.month == settings.currentMonth.value).toList());
        categories.assignAll(filtered);
        if (selectedCategory.value == null) {
          selectedCategory.value = _initialCategory(list, filtered);
        }
      },
      onError: (Object e, StackTrace s) {
        // The local store swallows read failures and re-emits the last
        // good snapshot, so this should never fire — but every listener
        // carries onError so a future failing source cannot kill the
        // stream silently (H2).
        debugPrint('[TransactionFormController] category stream failed: $e\n$s');
      },
    );
  }

  /// The month's categories in the order the picker lists them: by name,
  /// case-insensitively, with the reserved bucket LAST.
  ///
  /// The store hands categories back newest-created-first, which for one month's
  /// clones — written in a single batch, so all carrying the same `createdAt` —
  /// is an arbitrary order, and `List.sort` is not stable, so it can differ
  /// month to month and even between runs. Two consequences, both measured:
  /// the rows moved under the user's thumb, and the "first category" fallback
  /// below became a lottery that the reserved bucket could win (BUG-020).
  ///
  /// Reserved last rather than merely excluded: the bucket has to be pickable —
  /// it is where a user can deliberately file something they cannot classify —
  /// but it is the row that REPORTS a data problem, so it belongs at the bottom
  /// of the list and nowhere near the default (F-01 rule 4, palwasha 8c).
  ///
  /// `id` breaks name ties so the answer is total: a month should not hold two
  /// categories of one name (F-08), but a box written before that rule existed
  /// can, and an arbitrary order is exactly what this method removes.
  static List<Category> orderForPicker(List<Category> monthCategories) {
    final ordered = monthCategories.toList()
      ..sort((a, b) {
        final aReserved = isReservedCategoryName(a.name) ? 1 : 0;
        final bReserved = isReservedCategoryName(b.name) ? 1 : 0;
        if (aReserved != bReserved) return aReserved - bReserved;
        final byName =
            a.name.trim().toLowerCase().compareTo(b.name.trim().toLowerCase());
        return byName != 0 ? byName : a.id.compareTo(b.id);
      });
    return ordered;
  }

  /// The category a fallback may land on: the first one the USER manages, and
  /// the reserved bucket only when there is nothing else in the month.
  ///
  /// [orderForPicker] already sorts the bucket last, so this is belt and braces
  /// — deliberately, because the rule that matters is "never default to the
  /// bucket", and that must not depend on a comparator somewhere else staying
  /// the way it is (BUG-020).
  static Category? _firstPickable(List<Category> monthCategories) {
    for (final c in monthCategories) {
      if (!isReservedCategoryName(c.name)) return c;
    }
    return monthCategories.isEmpty ? null : monthCategories.first;
  }

  /// What the picker starts on, once, before the user has touched it.
  ///
  /// In order:
  ///
  /// 1. **Editing** starts on the transaction's OWN category, looked up across
  ///    every month rather than in [monthCategories]: a row dated into another
  ///    month points at that month's clone, which the picker's list does not
  ///    contain. If that category is gone entirely the picker deliberately
  ///    starts EMPTY — re-aiming an existing amount at whichever category
  ///    happens to sort first would move money the user never moved. Saving
  ///    from there attributes it to the reserved bucket, and says so.
  /// 2. **An explicit preselection** from a category-scoped entry point always
  ///    wins over the remembered default (F-06 rule 3).
  /// 3. **The category the last save used**, matched by name in the VIEWED
  ///    month. Nine categories meant the old "first category" default was wrong
  ///    about eight times in nine, at two taps and a modal each time.
  /// 4. **The month's first category** in [orderForPicker]'s order, skipping the
  ///    reserved bucket. Uncategorised exists to say "this spend lost its
  ///    category"; a sheet that opens on it files NEW spend into the row that
  ///    reports a problem, which is the mis-attribution the bucket exists to
  ///    make visible (BUG-020, F-06 rule 2).
  Category? _initialCategory(
      List<Category> allCategories, List<Category> monthCategories) {
    final edited = editing;
    if (edited != null) {
      return _byId(allCategories, edited.categoryId);
    }
    if (monthCategories.isEmpty) return null;
    final preselected = preselectedCategoryId;
    if (preselected != null) {
      return _byId(monthCategories, preselected) ??
          _firstPickable(monthCategories);
    }
    // Exact, case-sensitive: category names are user-typed and displayed
    // verbatim, so "food" and "Food" are two different labels to the person who
    // typed them (F-06 rule 4). Deliberately a different comparison from the
    // attribution resolver's trimmed/case-insensitive one, which is settling
    // identity rather than reading a preference.
    //
    // No match — renamed, deleted, a month whose clones do not exist yet, any
    // reason at all — is silent. This is a preference, not an operation that
    // can fail.
    final remembered = settings.lastUsedCategoryName;
    if (remembered != null) {
      final match = _byExactName(monthCategories, remembered);
      if (match != null) return match;
    }
    return _firstPickable(monthCategories);
  }

  static Category? _byId(List<Category> categories, String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  static Category? _byExactName(List<Category> categories, String name) {
    for (final c in categories) {
      if (c.name == name) return c;
    }
    return null;
  }

  @override
  void onClose() {
    amountController.dispose();
    noteController.dispose();
    super.onClose();
  }

  void selectDate(DateTime date) => selectedDate.value = date;
  void selectCategory(Category cat) => selectedCategory.value = cat;

  Future<void> save() async {
    // Text → minor units directly. No double.parse, no multiply by 100: the
    // currency's own exponent decides the scale (C4).
    final amountMinor = CurrencyUtils.tryParseToMinor(
        amountController.text, settings.currency);
    if (amountMinor == null || amountMinor <= 0) return;

    isLoading.value = true;
    final edited = editing;
    CategoryResolution resolution;
    String? createdId;
    try {
      // Attribution follows the transaction's DATE-month, never the month the
      // user happens to be viewing, and the repository is the only place that
      // decides it (F-01). A null pick lands in that month's reserved bucket.
      // Editing runs the same rule: moving a row's date into another month
      // re-points it at that month's category of the same name.
      resolution = await categoryRepo.resolveForMonth(
        selectedCategory.value,
        AppDateUtils.getMonthKeyFromDate(selectedDate.value),
      );

      if (edited != null) {
        // ONE put over the same key — amount, note, category and date land
        // together or not at all, so a failed edit can never leave half the
        // change behind (F-07 rule 4). A FRESH instance, never the box's own:
        // Hive throws if one HiveObject is stored under two keys. `id` and
        // `createdAt` are carried through unchanged; this is a correction, not
        // a new record.
        await transactionRepo.updateTransaction(TransactionItem(
          id: edited.id,
          categoryId: resolution.category.id,
          amountMinor: amountMinor,
          note: noteController.text.trim(),
          date: selectedDate.value,
          createdAt: edited.createdAt,
          updatedAt: DateTime.now(),
          synced: edited.synced,
        ));
      } else {
        // Kept, because the confirmation's Undo has to be able to name exactly
        // this record four seconds from now (F-05).
        createdId = const Uuid().v4();
        await transactionRepo.addTransaction(TransactionItem(
          id: createdId,
          categoryId: resolution.category.id,
          amountMinor: amountMinor,
          note: noteController.text.trim(),
          date: selectedDate.value,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
      // The next Add sheet opens on this category (F-06). Success path only,
      // and in its own try: remembering a preference is not part of saving the
      // money, so its failure must never be reported as a failed save. The
      // service refuses to store the reserved bucket.
      try {
        await settings.rememberLastUsedCategory(resolution.category.name);
      } catch (e, stack) {
        debugPrint(
            '[TransactionFormController] remembering the category failed: '
            '$e\n$stack');
      }
    } catch (e, stack) {
      // Owner-approved mobile convention (2026-07-28): user-visible
      // failures surface via Get.snackbar. Hive throws on a failed
      // write, so a failure is never reported as a success (H3).
      debugPrint('[TransactionFormController] save failed: $e\n$stack');
      Get.snackbar(
        edited != null ? 'Could not save changes' : 'Could not save transaction',
        edited != null
            ? 'The transaction is unchanged. Please try again.'
            : 'Nothing was saved. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    } finally {
      isLoading.value = false;
    }
    // The sheet closes only once the write is known to have landed —
    // dismissing it first would report a success that never happened.
    _closeSheet();

    if (resolution.pickedWasDeleted) {
      // The category was deleted while this sheet was open. The amount is
      // saved and visible, but not where the user aimed it — say so rather
      // than resurrecting a category they deleted. This outranks the plain
      // confirmation below: two snackbars would queue, and the surprising
      // destination is the one worth reading.
      _confirm('Saved to $kUncategorisedCategoryName',
          detail: 'That category was deleted.');
    } else if (edited != null) {
      // No Undo here, unlike a fresh save (F-05): the sheet reopens on a tap,
      // so a wrong correction is corrected the same way it was made. One
      // safety mechanism per action.
      _confirm('Updated — '
          '${_exact(amountMinor)} in ${resolution.category.name}');
    } else if (createdId != null) {
      // The proof the log landed, and the only chance to take it back — the
      // sheet is closed and the row is one tap deep, so this is the moment an
      // Undo is worth anything.
      final undoId = createdId;
      _confirm(
        '${_exact(amountMinor)} added to ${resolution.category.name}',
        action: TextButton(
          onPressed: () => _undoCreate(undoId),
          style: TextButton.styleFrom(
            // A real target: the theme's TextButton is 40 high, and this one
            // is the only way back from a mistake (F-05 AC-4).
            minimumSize: const Size(64, 48),
          ),
          child: const Text('Undo', maxLines: 1),
        ),
      );
    }
  }

  /// Pops the sheet, whether or not a confirmation is on screen.
  ///
  /// Deliberately NOT `Get.back()`. At get 4.7.3 that method opens with
  ///
  /// ```dart
  /// if (isSnackbarOpen && !closeOverlays) { closeCurrentSnackbar(); return; }
  /// ```
  ///
  /// (`extension_navigation.dart:826`), so while ANY snackbar is up it closes
  /// the snackbar and pops nothing. The money is already written by the time
  /// this runs, so the user would be left looking at a filled-in sheet over a
  /// dashboard that already holds the row — and a second tap on Save would
  /// write a duplicate. Logging two expenses back to back is F-05 AC-5's own
  /// scenario, so that is the normal path, not an edge case (BUG-080).
  ///
  /// `Get.key` is the navigator `GetMaterialApp` installs when no
  /// `navigatorKey` is passed — `main.dart` passes none and the app has no
  /// nested navigators — i.e. exactly the one `Get.back()` would have popped.
  void _closeSheet() {
    final navigator = Get.key.currentState;
    if (navigator != null && navigator.canPop()) navigator.pop();
  }

  /// Deletes the transaction the confirmation is about.
  ///
  /// Dismisses the snackbar with [Get.closeCurrentSnackbar] and never
  /// `Get.back()`: a snackbar is an overlay entry, not a route, so popping
  /// would take the user off whatever screen they are on.
  ///
  /// Safe to run after this controller has been discarded — opening the sheet
  /// again deletes the instance while the snackbar may still be up, and the
  /// repository reference this closure holds outlives that.
  Future<void> _undoCreate(String transactionId) async {
    Get.closeCurrentSnackbar();
    try {
      await transactionRepo.deleteTransaction(transactionId);
    } catch (e, stack) {
      debugPrint('[TransactionFormController] undo failed: $e\n$stack');
      // The row is back on screen either way, so the message says which
      // outcome that is (H3: a failed write is never silent). Shown with the
      // sheet already gone, so it takes the same tab-bar-clearing geometry as
      // a confirmation.
      _showAboveTabBar('Could not remove it — it is still saved.');
    }
    // A successful undo needs no confirmation of its own: the row disappearing
    // from Recent and the totals dropping back are the message (F-05 rule 2).
  }

  /// The amount a confirmation names: exact, currency-formatted.
  ///
  /// Deliberately NOT [CurrencyUtils.formatAmountCompact], which rounds to
  /// whole major units — a ₨0.50 expense stored exactly was announced as "₨1
  /// added to Food", i.e. an amount that exists nowhere in the data, and
  /// anything under ₨0.50 would have read "₨0" (BUG-082). The compact
  /// formatter is for tight rows; a confirmation is the proof of what landed,
  /// and F-05 AC-1 asks for the exact amount.
  String _exact(int amountMinor) =>
      CurrencyUtils.formatAmount(amountMinor, settings.currency);

  /// One line of confirmation, optionally a second line of detail, optionally
  /// carrying the only action that can undo it.
  void _confirm(String line, {String detail = '', TextButton? action}) {
    _afterSheetCloses(
        () => _showAboveTabBar(line, detail: detail, action: action));
  }

  /// Every bar this controller shows AFTER the sheet has closed.
  ///
  /// One method, because they all need the same geometry: a bar at the bottom
  /// of the screen is a bar on top of the tab bar, and the tab bar is where the
  /// user's next tap is going (BUG-080 / FD-14).
  ///
  /// `GetSnackBar` always renders a message slot beneath the title, so
  /// single-line copy gets a zero-size widget there rather than a blank second
  /// row; passing `null` lets GetX build the real second line from [detail].
  void _showAboveTabBar(String line, {String detail = '', TextButton? action}) {
    Get.snackbar(
      line,
      detail,
      messageText: detail.isEmpty ? const SizedBox.shrink() : null,
      snackPosition: SnackPosition.BOTTOM,
      duration: confirmationDuration,
      mainButton: action,
      margin: confirmationMargin,
      // GetX wraps the bar in a `Dismissible`, whose `HitTestBehavior.opaque`
      // covers the MARGIN as well as the bar — so with the margin alone the tab
      // bar would still have been dead, just invisibly. Dropping swipe-to-
      // dismiss costs nothing the spec asked for: the bar leaves on its own in
      // [confirmationDuration], and its own bounds still absorb (measured in
      // `save_confirmation_test`), so a tap meant for the bar cannot reach a
      // row underneath.
      isDismissible: false,
    );
  }

  /// Height of the app's bottom navigation chrome, in logical pixels.
  ///
  /// Material 3's `NavigationBar` has no public height constant, so this is its
  /// default (`_NavigationBarDefaults.height`) written down. It is asserted
  /// against a real `NavigationBar` in `save_confirmation_test`, so a Material
  /// change moves the number here and nowhere else. The device's bottom inset
  /// is NOT included: `GetSnackBar` already puts its body inside a bottom
  /// `SafeArea`, so adding it here would double-count.
  static const double navigationBarHeight = 80.0;

  /// Where a post-save bar sits: above the tab bar, with air around it.
  ///
  /// BUG-080: with no margin the bar covered the whole tab-bar strip and
  /// absorbed every touch there for its full ~5 s life. The four tabs were
  /// dead, an Add tap was silently lost and unreported, and the taps that
  /// followed landed on the dashboard rows beneath — which is how a ₨100
  /// transaction became ₨100,120.
  static const EdgeInsets confirmationMargin =
      EdgeInsets.only(left: 8, right: 8, bottom: navigationBarHeight + 8);

  /// Runs [show] once the sheet's pop has finished, with any confirmation
  /// still on screen cleared first.
  ///
  /// Both halves are load-bearing at get 4.7.3, and both were measured:
  ///
  /// * Snackbars **queue**. Logging twice inside the display window would
  ///   otherwise hold the second confirmation until the first expired, and
  ///   then show it ~4 s after the save it describes (F-05 AC-5).
  /// * The overlay a snackbar inserts into belongs to the route that
  ///   [Get.back] has only just returned to, so showing it during that same
  ///   frame is a race. A post-frame callback is the fix.
  ///
  /// One home for both rules, so the edit confirmation here and F-05's create
  /// confirmation cannot drift apart.
  void _afterSheetCloses(void Function() show) {
    Get.closeCurrentSnackbar();
    WidgetsBinding.instance.addPostFrameCallback((_) => show());
  }
}
