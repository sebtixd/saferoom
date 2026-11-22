import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:material_ui/material_ui.dart';

/// Base class for interactive objects in the room
abstract class InteractiveObject extends PositionComponent with TapCallbacks {
  final VoidCallback? onInteract;
  late Paint _basePaint;
  late Paint _highlightPaint;
  bool _isHighlighted = false;

  InteractiveObject({
    required Vector2 position,
    required Vector2 size,
    this.onInteract,
  }) : super(
    position: position,
    size: size,
    anchor: Anchor.center,
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _basePaint = Paint()..color = objectColor;
    _highlightPaint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
  }

  /// Override to provide object-specific color
  Color get objectColor => Colors.white;

  /// Override to provide object-specific icon
  IconData get objectIcon => Icons.help_outline;

  @override
  void render(Canvas canvas) {
    // Draw base shape
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(8),
    );
    canvas.drawRRect(rect, _basePaint);

    // Draw highlight if active
    if (_isHighlighted) {
      canvas.drawRRect(rect, _highlightPaint);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    _isHighlighted = true;
  }

  @override
  void onTapUp(TapUpEvent event) {
    _isHighlighted = false;
    onInteract?.call();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _isHighlighted = false;
  }
}
