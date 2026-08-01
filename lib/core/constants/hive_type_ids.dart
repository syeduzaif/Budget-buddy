/// Hive `typeId` registry. Ids are baked into every record already written to
/// disk, so they are append-only: never renumber a live id, never reuse a
/// retired one.
///
/// Retired (do not reuse): 2 = income, 7 = chatMessage — both models were
/// removed in the local-first pivot.
class HiveTypeIds {
  static const int category = 0;
  static const int transaction = 1;
}
