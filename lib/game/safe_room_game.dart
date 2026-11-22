import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/palette.dart';
import 'package:material_ui/material_ui.dart';

import '../data/datasources/local/local_storage_service.dart';
import 'components/room.dart';
import 'components/player.dart';
import 'components/breakable_object.dart';
import 'components/cat.dart';
import 'components/shop_zone.dart';

/// SafeRoom Game - proper full-screen landscape game
class SafeRoomGame extends FlameGame {
  Room? room;
  late Player player;
  late JoystickComponent joystick;

  final String userId;
  final LocalStorageService? localStorage;
  final String initialRoomBackground;
  final void Function(bool isNearDesk)? onDeskInteraction;
  final void Function(bool isSitting)? onCouchInteraction;
  final void Function(bool isNear)? onCouchProximity;
  final void Function(bool isInside)? onShopInteraction;
  final void Function(bool isNear)? onLibraryInteraction;

  SafeRoomGame({
    required this.userId,
    this.localStorage,
    this.initialRoomBackground = 'room_background.png',
    this.onDeskInteraction,
    this.onCouchInteraction,
    this.onCouchProximity,
    this.onShopInteraction,
    this.onLibraryInteraction,
  });

  @override
  Color backgroundColor() => const Color(0xFF1a1a2e);

  @override
  Future<void> onLoad() async {
    debugPrint('=== SafeRoomGame onLoad ===');
    debugPrint('Game canvas size: ${size.x} x ${size.y}');
    
    // CRITICAL: Use the actual game size for the room
    final roomSize = size;
    
    // Create room component
    room = Room(
      screenSize: roomSize,
      backgroundAsset: initialRoomBackground,
    );
    await add(room!);
    
    // Create joystick control
    final knobPaint = BasicPalette.white.withAlpha(180).paint();
    final backgroundPaint = BasicPalette.white.withAlpha(60).paint();
    
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 30, paint: knobPaint),
      background: CircleComponent(radius: 75, paint: backgroundPaint),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
    camera.viewport.add(joystick);
    
    // Create player
    player = Player(
      joystick: joystick,
      onNearDesk: (isNear) => onDeskInteraction?.call(isNear),
      onSitStateChanged: (isSitting) => onCouchInteraction?.call(isSitting),
      onNearCouch: (isNear) => onCouchProximity?.call(isNear),
      onNearLibrary: (isNear) => onLibraryInteraction?.call(isNear),
    );
    
    player.position = Vector2(roomSize.x * 0.5, roomSize.y * 0.55);
    await add(player);
    
    await _loadBreakableObjects();
    
    // Add Cat Companion 🐱
    final cat = Cat(player: player, position: Vector2(roomSize.x * 0.5, roomSize.y * 0.7));
    await add(cat);
    
    // Add Shop Zone (Center of the map)
    final shopZone = ShopZone(
      position: Vector2(roomSize.x * 0.5, roomSize.y * 0.5),
      size: Vector2(100, 100),
      player: player,
      onProximity: (isInside) => onShopInteraction?.call(isInside),
    );
    await add(shopZone);
    
    debugPrint('=== Game loaded successfully ===');
  }
  
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    debugPrint('Game resized to: ${size.x} x ${size.y}');
  }
  
  Future<void> _loadBreakableObjects() async {
    final storage = localStorage;
    if (storage != null) {
      final saved = await storage.getRoomDecor(userId);
      if (saved.isNotEmpty) {
        for (final raw in saved) {
          await add(_attachPersist(BreakableObject.fromStateMap(raw)));
        }
        return;
      }
    }

    // Default starter decoration for first-time rooms.
    final breakablePos = room?.getBreakableObjectPosition() ??
        Vector2(size.x * 0.8, size.y * 0.8);
    final starter = _attachPersist(
      BreakableObject(
        id: 'starter-plant',
        position: breakablePos,
        decorType: BreakableDecorType.plant,
      ),
    );
    await add(starter);
    await _saveBreakableObjects();
  }

  Future<void> placeDecor(BreakableDecorType type, Vector2 position) async {
    final centered = Vector2(
      (position.x - type.sizeX / 2).clamp(0.0, size.x - type.sizeX),
      (position.y - type.sizeY / 2).clamp(0.0, size.y - type.sizeY),
    );
    final decor = _attachPersist(
      BreakableObject(
        id: 'decor-${DateTime.now().microsecondsSinceEpoch}',
        position: centered,
        decorType: type,
      ),
    );
    await add(decor);
    await _saveBreakableObjects();
  }

  void resetBreakableObject() {
    var changed = false;
    for (final child in children) {
      if (child is BreakableObject && child.isBroken) {
        child.reset();
        changed = true;
      }
    }
    if (changed) {
      // Fire-and-forget: the repaired state should persist, but the UI should
      // not wait on local storage during task-completion updates.
      _saveBreakableObjects();
    }
  }

  BreakableObject _attachPersist(BreakableObject object) {
    object.onChanged = _saveBreakableObjects;
    return object;
  }

  Future<void> setRoomBackground(String assetPath) async {
    await room?.setBackground(assetPath);
  }

  Future<void> _saveBreakableObjects() async {
    final storage = localStorage;
    if (storage == null) return;
    final objects = children
        .whereType<BreakableObject>()
        .map((object) => object.toStateMap())
        .toList(growable: false);
    await storage.saveRoomDecor(userId, objects);
  }
}
