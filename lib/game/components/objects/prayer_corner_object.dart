import 'package:material_ui/material_ui.dart';
import 'package:flame/components.dart';
import '../../../core/constants/game_constants.dart';
import 'interactive_object.dart';

/// Prayer corner object - spiritual activities
class PrayerCornerObject extends InteractiveObject {
  PrayerCornerObject({
    required super.position,
    super.onInteract,
  }) : super(
    size: Vector2.all(GameConstants.prayerCornerSize),
  );

  @override
  Color get objectColor => const Color(0xFF228B22); // Forest green

  @override
  void render(Canvas canvas) {
    // Draw prayer mat
    final mat = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.y * 0.3, size.x, size.y * 0.7),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      mat,
      Paint()..color = const Color(0xFF228B22),
    );

    // Draw mat pattern
    canvas.drawRect(
      Rect.fromLTWH(4, size.y * 0.35, size.x - 8, 4),
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );
    canvas.drawRect(
      Rect.fromLTWH(4, size.y * 0.8, size.x - 8, 4),
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );

    // Draw decorative arch (mihrab symbol)
    final archPath = Path()
      ..moveTo(size.x * 0.3, size.y * 0.25)
      ..quadraticBezierTo(
        size.x / 2,
        0,
        size.x * 0.7,
        size.y * 0.25,
      )
      ..lineTo(size.x * 0.7, size.y * 0.35)
      ..lineTo(size.x * 0.3, size.y * 0.35)
      ..close();
    
    canvas.drawPath(
      archPath,
      Paint()..color = const Color(0xFFFFD700), // Gold
    );

    // Draw crescent moon symbol
    canvas.drawCircle(
      Offset(size.x / 2, size.y * 0.15),
      6,
      Paint()..color = const Color(0xFFFFD700),
    );
    canvas.drawCircle(
      Offset(size.x / 2 + 3, size.y * 0.13),
      4,
      Paint()..color = const Color(0xFF228B22),
    );
  }
}
