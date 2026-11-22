import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:material_ui/material_ui.dart';

import 'breakable_object.dart';
import '../safe_room_game.dart';

/// Player - LARGE and visible character
class Player extends PositionComponent with HasGameReference<SafeRoomGame> {
  // Extra-large character for visibility (2x the previous in-game size).
  static const double playerWidth = 120.0;
  static const double playerHeight = 156.0;

  static const double moveSpeed = 200.0;
  static const double friction = 0.80;
  
  Vector2 velocity = Vector2.zero();
  
  int direction = 0;
  bool isMoving = false;
  double animationTimer = 0;
  int animationFrame = 0;

  // Directional sprite frames, paired as (idle, walk) for each direction.
  // Index order matches [_spriteIndex]: front, left, right, back.
  static const List<String> spriteFiles = [
    'sprites/player_front_idle.png',
    'sprites/player_front_walk.png',
    'sprites/player_left_idle.png',
    'sprites/player_left_walk.png',
    'sprites/player_right_idle.png',
    'sprites/player_right_walk.png',
    'sprites/player_back_idle.png',
    'sprites/player_back_walk.png',
  ];

  List<Sprite>? _sprites;

  // Flame's default Image cache prefixes "assets/images/". These sprites live
  // in assets/sprites/, so use a cache rooted at assets/ instead.
  static final Images spriteImages = Images(prefix: 'assets/');

  final JoystickComponent? joystick;
  
  // Callbacks
  final void Function(bool isNear)? onNearDesk;
  final void Function(bool isSitting)? onSitStateChanged;
  final void Function(bool isNear)? onNearCouch; 
  final void Function(bool isNear)? onNearLibrary;
  
  // State
  bool _wasNearDesk = false;
  bool _wasNearCouch = false;
  bool _wasNearLibrary = false;
  bool isSitting = false;
  
  Rect get hitbox => Rect.fromCenter(
    center: Offset(position.x, position.y + playerHeight * 0.2),
    width: playerWidth * 0.5,
    height: playerHeight * 0.35,
  );

  Player({
    this.joystick, 
    this.onNearDesk,
    this.onSitStateChanged,
    this.onNearCouch,
    this.onNearLibrary,
  }) : super(priority: 10);

  @override
  Future<void> onLoad() async {
    size = Vector2(playerWidth, playerHeight);
    anchor = Anchor.center;

    _sprites = await Future.wait(
      spriteFiles.map(
        (file) => Sprite.load(file, images: spriteImages),
      ),
    );
    // Keep the hard pixel edges crisp instead of bilinear-blurring the art.
    for (final sprite in _sprites!) {
      sprite.paint.filterQuality = FilterQuality.none;
    }
  }

  @override
  void render(Canvas canvas) {
    final sprites = _sprites;
    if (sprites != null && sprites.length == spriteFiles.length) {
      final bob = isMoving && animationFrame.isOdd ? 1.0 : 0.0;
      final sittingOffset = isSitting ? 5.0 : 0.0;
      sprites[_spriteIndex()].render(
        canvas,
        position: Vector2(0, bob + sittingOffset),
        size: size,
      );
    }
    super.render(canvas);
  }

  /// Maps the joystick direction to the matching sprite pair:
  /// 0 = front/down, 1 = left profile, 2 = right profile, 3 = back/up.
  int _spriteIndex() {
    final directionBase = switch (direction) {
      1 => 2, // left
      2 => 4, // right
      3 => 6, // back
      _ => 0, // front
    };
    final frame = isMoving && animationFrame.isOdd ? 1 : 0;
    return directionBase + frame;
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    Vector2 input = Vector2.zero();
    if (joystick != null && !joystick!.delta.isZero()) {
      input = joystick!.relativeDelta;
    }

    if (!input.isZero()) {
      // If moving, stand up logic
      if (isSitting) {
        isSitting = false;
        onSitStateChanged?.call(false);
      }
      
      velocity += input * moveSpeed * dt;
      isMoving = true;
      
      if (input.x.abs() > input.y.abs()) {
        direction = input.x > 0 ? 2 : 1;
      } else {
        direction = input.y > 0 ? 0 : 3;
      }
      
      animationTimer += dt;
      if (animationTimer > 0.10) {
        animationTimer = 0;
        animationFrame = (animationFrame + 1) % 4;
      }
    } else {
      isMoving = false;
      animationFrame = 0;
    }
    
    velocity *= friction;
    if (velocity.length < 0.5) velocity.setZero();
    
    if (!velocity.isZero()) {
      _moveWithCollision(dt);
    }
    
    _checkDeskProximity();
    _checkCouchProximity();
    _checkLibraryProximity();
    _checkBreakableCollision();
  }
  
  void _moveWithCollision(double dt) {
    if (game.room == null) {
      position += velocity * dt * 10;
      return;
    }
    
    final obstacles = game.room!.getCollisionRects();
    final movement = velocity * dt * 10;
    
    final newPos = position + movement;
    if (_isValid(newPos, obstacles)) {
      position = newPos;
      return;
    }
    
    final newX = position + Vector2(movement.x, 0);
    if (_isValid(newX, obstacles)) {
      position = newX;
    }
    
    final newY = position + Vector2(0, movement.y);
    if (_isValid(newY, obstacles)) {
      position = newY;
    }
  }
  
  bool _isValid(Vector2 pos, List<Rect> obstacles) {
    final box = Rect.fromCenter(
      center: Offset(pos.x, pos.y + playerHeight * 0.2),
      width: playerWidth * 0.5,
      height: playerHeight * 0.35,
    );
    
    for (final obs in obstacles) {
      if (box.overlaps(obs)) return false;
    }
    return true;
  }

  void _checkDeskProximity() {
    if (game.room == null || onNearDesk == null) return;
    
    final deskZone = game.room!.getDeskInteractionZone();
    final isNear = hitbox.overlaps(deskZone);
    
    if (isNear && !_wasNearDesk) {
      onNearDesk!(true);
    } else if (!isNear && _wasNearDesk) {
      onNearDesk!(false);
    }
    
    _wasNearDesk = isNear;
  }

  void _checkCouchProximity() {
    if (game.room == null) return;
    
    final couchZone = game.room!.getCouchInteractionZone();
    final isNear = hitbox.overlaps(couchZone);
    
    // Proximity trigger (shows tasks)
    if (isNear && !_wasNearCouch) {
      onNearCouch?.call(true);
    } else if (!isNear && _wasNearCouch) {
      onNearCouch?.call(false);
    }
    _wasNearCouch = isNear;
    
    // Sitting logic (still requires stopping)
    if (isNear) {
       if (!isMoving && !isSitting) {
         isSitting = true;
         velocity.setZero();
         onSitStateChanged?.call(true);
       }
    } else {
      // If moved away, stand up
      if (isSitting) {
        isSitting = false;
        onSitStateChanged?.call(false);
      }
    }
  }

  void _checkLibraryProximity() {
    if (game.room == null || onNearLibrary == null) return;

    final libraryZone = game.room!.getLibraryInteractionZone();
    final isNear = hitbox.overlaps(libraryZone);

    if (isNear && !_wasNearLibrary) {
      onNearLibrary!(true);
    } else if (!isNear && _wasNearLibrary) {
      onNearLibrary!(false);
    }

    _wasNearLibrary = isNear;
  }

  void _checkBreakableCollision() {
    for (final child in game.children) {
      if (child is BreakableObject) {
        if (!child.isBroken && hitbox.overlaps(child.toRect())) {
          child.hit();
          // Bounce off and nudge outside to avoid repeated frame hits.
          velocity = -velocity * 1.5;
          if (velocity.length2 > 0) {
            position += velocity.normalized() * 8;
          }
        }
      }
    }
  }
}
