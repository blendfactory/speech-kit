import 'package:speech_kit/src/domain/value_objects/assets/asset_inventory_status.dart';
import 'package:test/test.dart';

void main() {
  group('AssetInventoryStatus', () {
    test('ordering matches Apple Comparable progression', () {
      expect(
        AssetInventoryStatus.unsupported < AssetInventoryStatus.supported,
        isTrue,
      );
      expect(
        AssetInventoryStatus.supported < AssetInventoryStatus.downloading,
        isTrue,
      );
      expect(
        AssetInventoryStatus.downloading < AssetInventoryStatus.installed,
        isTrue,
      );
      expect(
        AssetInventoryStatus.installed.compareTo(
          AssetInventoryStatus.installed,
        ),
        0,
      );
    });
  });
}
