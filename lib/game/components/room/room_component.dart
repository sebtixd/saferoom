import 'package:flame/components.dart';
import 'package:material_ui/material_ui.dart';
import '../../../core/constants/game_constants.dart';

/// Room background component
class RoomComponent extends PositionComponent {
  late Paint _backgroundPaint;
  late Paint _floorPaint;

  RoomComponent() : super(
    size: Vector2(GameConstants.roomWidth, GameConstants.roomHeight),
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    _backgroundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFFACD), // Light yellow
          Color(0xFFE6E6FA), // Lavender
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));

    _floorPaint = Paint()..color = const Color(0xFFDEB887); // Burlywood
  }

  @override
  void render(Canvas canvas) {
    // Draw background gradient
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      _backgroundPaint,
    );

    // Draw floor (bottom third)
    final floorRect = Rect.fromLTWH(0, size.y * 0.6, size.x, size.y * 0.4);
    canvas.drawRect(floorRect, _floorPaint);

    // Draw wall line
    final wallLine = Paint()
      ..color = const Color(0xFF8B4513)
      ..strokeWidth = 4;
    canvas.drawLine(
      Offset(0, size.y * 0.6),
      Offset(size.x, size.y * 0.6),
      wallLine,
    );
  }

  /// Update room color based on emotional state
  void updateEmotionalColors(List<Color> gradientColors) {
    _backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: gradientColors,
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));
  }
}
