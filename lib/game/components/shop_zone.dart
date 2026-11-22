import 'package:flame/components.dart';
import 'package:material_ui/material_ui.dart';
import 'player.dart';

class ShopZone extends PositionComponent with HasGameReference {
  final Player player;
  final void Function(bool isInside) onProximity;
  bool _wasInside = false;

  ShopZone({
    required Vector2 position, 
    required Vector2 size, 
    required this.player,
    required this.onProximity,
  }) : super(position: position, size: size);

  @override
  void render(Canvas canvas) {
    // Hidden zone - debug only
    // canvas.drawRect(size.toRect(), Paint()..color = Colors.amber.withValues(alpha: 0.3));
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Check if player is inside
    final playerCenter = player.position;
    final isInside = toRect().contains(playerCenter.toOffset());
    
    if (isInside != _wasInside) {
      _wasInside = isInside;
      onProximity(isInside);
    }
  }
}
