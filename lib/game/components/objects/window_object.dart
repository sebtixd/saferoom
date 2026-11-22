import 'package:material_ui/material_ui.dart';
import 'package:flame/components.dart';
import '../../../core/constants/game_constants.dart';
import 'interactive_object.dart';

/// Window object - displays weather based on emotional state
class WindowObject extends InteractiveObject {
  WindowObject({
    required super.position,
    super.onInteract,
  }) : super(
    size: Vector2(GameConstants.windowWidth, GameConstants.windowHeight),
  );

  @override
  Color get objectColor => const Color(0xFF87CEEB); // Sky blue

  @override
  void render(Canvas canvas) {
    // Draw window frame
    final frame = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      frame,
      Paint()..color = const Color(0xFF8B4513), // Brown frame
    );

    // Draw window glass
    final glass = Rect.fromLTWH(
      4,
      4,
      size.x - 8,
      size.y - 8,
    );
    canvas.drawRect(
      glass,
      Paint()..color = const Color(0xFF87CEEB),
    );

    // Draw window cross
    final crossPaint = Paint()
      ..color = const Color(0xFF8B4513)
      ..strokeWidth = 4;
    
    canvas.drawLine(
      Offset(size.x / 2, 4),
      Offset(size.x / 2, size.y - 4),
      crossPaint,
    );
    canvas.drawLine(
      Offset(4, size.y / 2),
      Offset(size.x - 4, size.y / 2),
      crossPaint,
    );

    // Draw sun
    canvas.drawCircle(
      Offset(size.x * 0.7, size.y * 0.3),
      10,
      Paint()..color = const Color(0xFFFFD700),
    );
  }
}
