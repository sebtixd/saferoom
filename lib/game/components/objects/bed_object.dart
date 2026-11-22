import 'package:material_ui/material_ui.dart';
import 'package:flame/components.dart';
import '../../../core/constants/game_constants.dart';
import 'interactive_object.dart';

/// Bed object - rest and sleep
class BedObject extends InteractiveObject {
  BedObject({
    required super.position,
    super.onInteract,
  }) : super(
    size: Vector2(GameConstants.bedWidth, GameConstants.bedHeight),
  );

  @override
  Color get objectColor => const Color(0xFF4169E1); // Royal blue

  @override
  void render(Canvas canvas) {
    // Draw bed frame
    final frame = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      frame,
      Paint()..color = const Color(0xFF8B4513), // Brown frame
    );

    // Draw mattress
    final mattress = RRect.fromRectAndRadius(
      Rect.fromLTWH(4, 20, size.x - 8, size.y - 24),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      mattress,
      Paint()..color = const Color(0xFFE6E6FA), // Lavender sheets
    );

    // Draw pillow
    final pillow = RRect.fromRectAndRadius(
      Rect.fromLTWH(8, 24, size.x * 0.4, 20),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      pillow,
      Paint()..color = Colors.white,
    );

    // Draw blanket
    final blanket = Rect.fromLTWH(4, size.y * 0.5, size.x - 8, size.y * 0.3);
    canvas.drawRect(
      blanket,
      Paint()..color = const Color(0xFF4169E1).withValues(alpha: 0.8),
    );
  }
}
