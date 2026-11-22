import 'package:flame/components.dart';
import 'package:material_ui/material_ui.dart';
import 'player.dart';

enum CatState { idle, run }

class Cat extends PositionComponent {
  final Player player;
  final double speed = 80.0;
  final double followDistance = 60.0; // Distance to stop at

  late SpriteAnimation idleAnimation;
  late SpriteAnimation runAnimation;
  bool isMoving = false;
  bool faceRight = true;

  Cat({required this.player, required Vector2 position}) 
      : super(position: position, size: Vector2(32, 32), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // The cat is rendered procedurally in render(), so no sprite asset is needed.
    priority = 5; // Render above floor
  }

  @override
  void render(Canvas canvas) {
    // Custom Cat Drawing (orange kitty)
    final paint = Paint()..color = Colors.orangeAccent;
    
    // Body
    canvas.drawOval(Rect.fromLTWH(0, 10, 32, 20), paint);
    
    // Head
    canvas.drawCircle(const Offset(8, 8), 10, paint);
    
    // Ears
    final earPath = Path()
      ..moveTo(0, 0)..lineTo(6, -6)..lineTo(12, 0)..close();
    canvas.drawPath(earPath.shift(const Offset(0, 4)), paint); // Left Ear
    canvas.drawPath(earPath.shift(const Offset(8, 4)), paint); // Right Ear
    
    // Eye
    final eyePaint = Paint()..color = Colors.black;
    canvas.drawCircle(faceRight ? const Offset(12, 6) : const Offset(4, 6), 2, eyePaint);
    
    // Tail
    final tailPaint = Paint()..color = Colors.orangeAccent..strokeWidth = 3..style = PaintingStyle.stroke;
    final tailPath = Path();
    tailPath.moveTo(30, 20);
    tailPath.quadraticBezierTo(40, 10, 35, 5);
    canvas.drawPath(tailPath, tailPaint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Calculate vector to player
    final vectorToPlayer = player.position - position;
    final distance = vectorToPlayer.length;
    
    if (distance > followDistance) {
      isMoving = true;
      // Normalize and scale by speed
      vectorToPlayer.normalize();
      position += vectorToPlayer * speed * dt;
      
      // Face direction
      if (vectorToPlayer.x > 0) {
        faceRight = true;
        // transform.scale = Vector2(1, 1); // Reset flip
      } else if (vectorToPlayer.x < 0) {
        faceRight = false;
        // transform.scale = Vector2(-1, 1); // Flip horiz
      }
    } else {
      isMoving = false;
    }
  }
}
