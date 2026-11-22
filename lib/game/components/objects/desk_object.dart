import 'package:material_ui/material_ui.dart';
import 'package:flame/components.dart';
import '../../../core/constants/game_constants.dart';
import 'interactive_object.dart';

/// Desk object - opens notebook and AI assistant
class DeskObject extends InteractiveObject {
  DeskObject({
    required super.position,
    super.onInteract,
  }) : super(
    size: Vector2(GameConstants.deskWidth, GameConstants.deskHeight),
  );

  @override
  Color get objectColor => const Color(0xFF8B4513); // Saddle brown

  @override
  IconData get objectIcon => Icons.desk;

  @override
  void render(Canvas canvas) {
    // Draw desk top
    final deskTop = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y * 0.3),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      deskTop,
      Paint()..color = const Color(0xFF8B4513),
    );

    // Draw desk body
    final deskBody = Rect.fromLTWH(
      size.x * 0.1,
      size.y * 0.3,
      size.x * 0.8,
      size.y * 0.7,
    );
    canvas.drawRect(
      deskBody,
      Paint()..color = const Color(0xFFA0522D),
    );

    // Draw notebook on desk
    final notebook = Rect.fromLTWH(
      size.x * 0.2,
      -size.y * 0.15,
      size.x * 0.3,
      size.y * 0.25,
    );
    canvas.drawRect(
      notebook,
      Paint()..color = const Color(0xFF4169E1),
    );
  }
}
