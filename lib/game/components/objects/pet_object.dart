import 'dart:math';
import 'package:material_ui/material_ui.dart';
import 'package:flame/components.dart';
import '../../../core/constants/game_constants.dart';
import 'interactive_object.dart';

/// Pet object - emotional companion
class PetObject extends InteractiveObject {
  bool _isHappy = true;
  double _animationTime = 0;

  PetObject({
    required super.position,
    super.onInteract,
  }) : super(
    size: Vector2.all(GameConstants.petSize),
  );

  @override
  Color get objectColor => const Color(0xFFFF8C00); // Dark orange

  @override
  void update(double dt) {
    super.update(dt);
    _animationTime += dt;
  }

  @override
  void render(Canvas canvas) {
    // Bounce animation
    final bounce = _isHappy ? (1 + 0.05 * sin(_animationTime * 3)) : 1.0;
    
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.scale(bounce, bounce);
    canvas.translate(-size.x / 2, -size.y / 2);

    // Draw body
    canvas.drawOval(
      Rect.fromLTWH(0, size.y * 0.3, size.x, size.y * 0.6),
      Paint()..color = const Color(0xFFFF8C00),
    );

    // Draw head
    canvas.drawCircle(
      Offset(size.x / 2, size.y * 0.3),
      size.x * 0.35,
      Paint()..color = const Color(0xFFFF8C00),
    );

    // Draw ears
    final earPaint = Paint()..color = const Color(0xFFCD5C00);
    canvas.drawOval(
      Rect.fromLTWH(size.x * 0.1, 0, size.x * 0.25, size.y * 0.3),
      earPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.x * 0.65, 0, size.x * 0.25, size.y * 0.3),
      earPaint,
    );

    // Draw eyes
    final eyePaint = Paint()..color = Colors.black;
    canvas.drawCircle(
      Offset(size.x * 0.35, size.y * 0.25),
      3,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(size.x * 0.65, size.y * 0.25),
      3,
      eyePaint,
    );

    // Draw nose
    canvas.drawCircle(
      Offset(size.x / 2, size.y * 0.35),
      4,
      Paint()..color = Colors.black,
    );

    // Draw mouth (happy or sad)
    if (_isHappy) {
      final smilePath = Path()
        ..moveTo(size.x * 0.35, size.y * 0.4)
        ..quadraticBezierTo(
          size.x / 2,
          size.y * 0.5,
          size.x * 0.65,
          size.y * 0.4,
        );
      canvas.drawPath(
        smilePath,
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Draw tail
    final tailPath = Path()
      ..moveTo(size.x, size.y * 0.5)
      ..quadraticBezierTo(
        size.x * 1.2,
        size.y * 0.3 + 5 * sin(_animationTime * 5),
        size.x * 1.1,
        size.y * 0.2,
      );
    canvas.drawPath(
      tailPath,
      Paint()
        ..color = const Color(0xFFFF8C00)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();
  }

  void setHappiness(bool isHappy) {
    _isHappy = isHappy;
  }
}
