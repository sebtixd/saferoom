import 'package:flutter_test/flutter_test.dart';

import 'package:safe_room/data/datasources/local/room_customization_storage.dart';
import 'helpers/fakes.dart';

void main() {
  test('room customization defaults to owned+equipped default background', () async {
    final storage = RoomCustomizationStorage(FakeLocalStorage());

    final state = await storage.load('user-1');

    expect(state.equippedBackgroundId, 'default');
    final defaultBg = state.backgrounds.firstWhere((b) => b.id == 'default');
    expect(defaultBg.owned, isTrue);
    expect(defaultBg.equipped, isTrue);
  });

  test('room customization persists owned and equipped background across restart', () async {
    final local = FakeLocalStorage();
    final storage = RoomCustomizationStorage(local);

    var state = await storage.load('user-1');
    var updated = state.backgrounds.map((b) {
      if (b.id == 'sunset') return b.copyWith(owned: true, equipped: true);
      return b.copyWith(equipped: false);
    }).toList();
    await storage.save('user-1', updated);

    // "Restart" by creating a new storage instance over same local storage.
    final restarted = RoomCustomizationStorage(local);
    state = await restarted.load('user-1');

    final sunset = state.backgrounds.firstWhere((b) => b.id == 'sunset');
    final defaultBg = state.backgrounds.firstWhere((b) => b.id == 'default');
    expect(sunset.owned, isTrue);
    expect(sunset.equipped, isTrue);
    expect(defaultBg.equipped, isFalse);
    expect(state.equippedBackgroundId, 'sunset');
  });
}
