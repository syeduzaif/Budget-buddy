import '../../data/models/category.dart';
import '../constants/app_constants.dart';

/// The one order every category LIST in the app is shown in: by name, with the
/// reserved bucket last.
///
/// The store hands categories back newest-created-first, which for one month's
/// clones — written in a single batch, so all carrying the same `createdAt` —
/// is an arbitrary order, and `List.sort` is not stable, so it can differ month
/// to month and even between runs. Three consequences, all measured: the Add
/// picker's rows moved under the user's thumb and its "first category" fallback
/// became a lottery the reserved bucket could win (BUG-020); and the Categories
/// tab listed nine categories in no readable order at all with the bucket at
/// the top (BUG-R2-main-01).
///
/// Comparison is on the trimmed, case-folded name, because that is how the app
/// compares category names everywhere else — [isReservedCategoryName] and the
/// duplicate-name rule (F-08) both do it, and a list that sorted " food" apart
/// from "Food" would contradict a form that calls them the same name.
///
/// Reserved last rather than merely excluded: the bucket has to be visible and
/// pickable — it is where a user can deliberately file something they cannot
/// classify, and where deleted categories' transactions land — but it is the
/// row that REPORTS a data problem, so it belongs at the bottom of every list
/// and nowhere near a default (F-01 rule 4, palwasha 8c).
///
/// This is the comparator F-09 AC-5 names. The **dashboard preview** is
/// deliberately NOT one of its callers: that card shows 4 of however many exist
/// and sorts by budget pressure so the one category worth seeing is the one
/// shown (F-09 AC-4, `category_budget_list.dart`). Ratio ordering belongs to
/// that preview alone; every full list is alphabetical.
class CategoryOrder {
  CategoryOrder._();

  /// Reserved bucket last, then name ascending (trimmed, case-folded), then
  /// `id`.
  ///
  /// The `id` tail is not decoration: it makes the answer a TOTAL order. Two
  /// categories of one name should not exist in a month (F-08), but a box
  /// written before that rule did can hold them, and `List.sort` is not stable
  /// — without a unique final key the list could reshuffle itself between
  /// rebuilds, which is exactly what this comparator removes.
  static int byName(Category a, Category b) {
    final aReserved = isReservedCategoryName(a.name) ? 1 : 0;
    final bReserved = isReservedCategoryName(b.name) ? 1 : 0;
    if (aReserved != bReserved) return aReserved - bReserved;

    final byName =
        a.name.trim().toLowerCase().compareTo(b.name.trim().toLowerCase());
    return byName != 0 ? byName : a.id.compareTo(b.id);
  }

  /// [categories] in [byName] order, as a NEW list.
  ///
  /// A copy on purpose. Both callers hold the controller's `RxList`, read
  /// inside an `Obx`; sorting one in place would write to an observable during
  /// a rebuild that observes it, which is a rebuild loop (F-09 §5).
  static List<Category> sortedByName(List<Category> categories) =>
      List<Category>.of(categories)..sort(byName);
}
