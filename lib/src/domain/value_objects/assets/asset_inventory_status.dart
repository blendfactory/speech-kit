/// Installation state for on-device assets required by configured speech
/// modules.
///
/// Ordering matches `Speech.AssetInventory.Status` (Comparable) in Apple’s
/// Speech framework: `unsupported` < `supported` < `downloading` < `installed`.
enum AssetInventoryStatus implements Comparable<AssetInventoryStatus> {
  unsupported(0),
  supported(1),
  downloading(2),
  installed(3)
  ;

  const AssetInventoryStatus(this._rank);
  final int _rank;

  bool operator <(AssetInventoryStatus other) => _rank < other._rank;

  bool operator <=(AssetInventoryStatus other) => _rank <= other._rank;

  bool operator >(AssetInventoryStatus other) => _rank > other._rank;

  bool operator >=(AssetInventoryStatus other) => _rank >= other._rank;

  @override
  int compareTo(AssetInventoryStatus other) => _rank.compareTo(other._rank);
}
