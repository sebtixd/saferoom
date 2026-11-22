import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:material_ui/material_ui.dart';
import '../../../core/constants/game_constants.dart';

/// Player character component
class PlayerComponent extends PositionComponent with DragCallbacks {
  late Paint _bodyPaint;
  late Paint _shadowPaint;
  
  Vector2? _targetPosition;
  final double _speed = GameConstants.characterSpeed;

  PlayerComponent({
    required Vector2 position,
  }) : super(
    position: position,
    size: Vector2.all(GameConstants.characterSize),
    anchor: Anchor.center,
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    _bodyPaint = Paint()..color = const Color(0xFF6B5CE7);
    _shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Move towards target position
    if (_targetPosition != null) {
      final direction = _targetPosition! - position;
      if (direction.length > 5) {
        position += direction.normalized() * _speed * dt;
      } else {
        _targetPosition = null;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Draw shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y - 5),
        width: size.x * 0.8,
        height: size.y * 0.2,
      ),
      _shadowPaint,
    );

    // Draw body (simple circle for now)
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2 - 4,
      _bodyPaint,
    );

    // Draw face
    final facePaint = Paint()..color = Colors.white;
    
    // Eyes
    canvas.drawCircle(
      Offset(size.x / 3, size.y / 3),
      4,
      facePaint,
    );
    canvas.drawCircle(
      Offset(size.x * 2 / 3, size.y / 3),
      4,
      facePaint,
    );

    // Smile
    final smilePath = Path()
      ..moveTo(size.x / 3, size.y / 2)
      ..quadraticBezierTo(
        size.x / 2,
        size.y * 0.7,
        size.x * 2 / 3,
        size.y / 2,
      );
    canvas.drawPath(
      smilePath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    position += event.localDelta;
    _clampToRoom();
  }

  /// Move to a specific position
  void moveTo(Vector2 target) {
    _targetPosition = target;
  }

  void _clampToRoom() {
    final halfSize = size.x / 2;
    position.x = position.x.clamp(halfSize, GameConstants.roomWidth - halfSize);
    position.y = position.y.clamp(halfSize, GameConstants.roomHeight - halfSize);
  }
}
