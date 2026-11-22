import '../../../domain/entities/room_background.dart';
import 'local_storage_service.dart';

/// Persists room background ownership and equipped selection.
///
/// Data is stored per user in SharedPreferences through the existing
/// [LocalStorageService], so it survives app restarts without any backend.
class RoomCustomizationStorage {
  static const String defaultBackgroundId = 'default';
  static const List<RoomBackground> catalog = [
    RoomBackground(
      id: 'default',
      name: 'Cozy Default',
      description: 'The warm original SafeRoom.',
      assetPath: 'room_background.png',
      price: 0,
      owned: true,
      equipped: true,
    ),
    RoomBackground(
      id: 'sunset',
      name: 'Sunset Glow',
      description: 'A rosy room bathed in golden hour light.',
      assetPath: 'backgrounds/room_background_sunset.jpg',
      price: 100,
      owned: false,
      equipped: false,
    ),
    RoomBackground(
      id: 'night',
      name: 'Moonlit Night',
      description: 'A calm night room with moonlight through the window.',
      assetPath: 'backgrounds/room_background_night.jpg',
      price: 150,
      owned: false,
      equipped: false,
    ),
    RoomBackground(
      id: 'forest',
      name: 'Forest Retreat',
      description: 'A fresh green room inspired by nature.',
      assetPath: 'backgrounds/room_background_forest.jpg',
      price: 200,
      owned: false,
      equipped: false,
    ),
  ];

  final LocalStorageService _localStorage;

  RoomCustomizationStorage(this._localStorage);

  String _key(String userId) =>
      'room_customization_${userId.isEmpty ? 'guest' : userId}';

  Future<RoomCustomizationState> load(String userId) async {
    final json = await _localStorage.getJson(_key(userId));
    final ownedIds = <String>{defaultBackgroundId};
    var equippedId = defaultBackgroundId;

    final rawOwned = json?['ownedIds'];
    if (rawOwned is List) {
      for (final id in rawOwned) {
        if (id is String && id.isNotEmpty) ownedIds.add(id);
      }
    }

    final rawEquipped = json?['equippedId'];
    if (rawEquipped is String && rawEquipped.isNotEmpty) {
      equippedId = rawEquipped;
    }

    // Ensure equipped background is always owned and exists.
    if (!ownedIds.contains(equippedId) ||
        !catalog.any((item) => item.id == equippedId)) {
      equippedId = defaultBackgroundId;
    }
    ownedIds.add(defaultBackgroundId);

    final backgrounds = catalog
        .map(
          (item) => item.copyWith(
            owned: ownedIds.contains(item.id),
            equipped: item.id == equippedId,
          ),
        )
        .toList(growable: false);

    // Persist normalized state (also handles first-run defaults).
    await save(userId, backgrounds);

    return RoomCustomizationState(
      backgrounds: backgrounds,
      equippedBackgroundId: equippedId,
    );
  }

  Future<void> save(String userId, List<RoomBackground> backgrounds) async {
    final ownedIds = backgrounds
        .where((item) => item.owned)
        .map((item) => item.id)
        .toSet()
      ..add(defaultBackgroundId);
    final equipped = backgrounds.where((item) => item.equipped).toList();
    final equippedId = equipped.isNotEmpty
        ? equipped.first.id
        : defaultBackgroundId;

    await _localStorage.saveJson(_key(userId), {
      'ownedIds': ownedIds.toList()..sort(),
      'equippedId': ownedIds.contains(equippedId)
          ? equippedId
          : defaultBackgroundId,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<RoomBackground> getEquipped(String userId) async {
    final state = await load(userId);
    return state.backgrounds.firstWhere(
      (item) => item.id == state.equippedBackgroundId,
      orElse: () => catalog.first,
    );
  }
}

class RoomCustomizationState {
  final List<RoomBackground> backgrounds;
  final String equippedBackgroundId;

  const RoomCustomizationState({
    required this.backgrounds,
    required this.equippedBackgroundId,
  });

  RoomBackground get equipped => backgrounds.firstWhere(
        (item) => item.id == equippedBackgroundId,
        orElse: () => backgrounds.first,
      );
}
