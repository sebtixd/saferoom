import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:material_ui/material_ui.dart';

/// Types of breakable decorations the player can buy and place.
enum BreakableDecorType {
  plant(
    label: 'Potted Plant',
    description: 'A leafy plant that brightens the room.',
    icon: Icons.local_florist,
    cost: 50,
    maxHealth: 3,
    sizeX: 50,
    sizeY: 70,
  ),
  vase(
    label: 'Ceramic Vase',
    description: 'A pretty vase - handle with care.',
    icon: Icons.local_drink_outlined,
    cost: 75,
    maxHealth: 2,
    sizeX: 44,
    sizeY: 64,
  ),
  lamp(
    label: 'Table Lamp',
    description: 'A warm lamp for cozy evenings.',
    icon: Icons.lightbulb_outline,
    cost: 100,
    maxHealth: 3,
    sizeX: 46,
    sizeY: 74,
  ),
  globe(
    label: 'Mini Globe',
    description: 'Dream of places to explore.',
    icon: Icons.public,
    cost: 120,
    maxHealth: 2,
    sizeX: 52,
    sizeY: 62,
  );

  const BreakableDecorType({
    required this.label,
    required this.description,
    required this.icon,
    required this.cost,
    required this.maxHealth,
    required this.sizeX,
    required this.sizeY,
  });

  final String label;
  final String description;
  final IconData icon;
  final int cost;
  final int maxHealth;
  final double sizeX;
  final double sizeY;

  Vector2 get defaultSize => Vector2(sizeX, sizeY);

  static BreakableDecorType fromName(String? name) {
    for (final type in BreakableDecorType.values) {
      if (type.name == name) return type;
    }
    return BreakableDecorType.plant;
  }
}

/// A breakable decoration placed in the room.
///
/// The player can buy decorations in the shop, place them on the floor, and
/// accidentally break them by bumping into them. Completing all daily tasks
/// repairs every broken decoration.
class BreakableObject extends PositionComponent {
  final String id;
  final BreakableDecorType decorType;
  bool isBroken = false;
  late int health;
  double _invulnerableTimer = 0;
  void Function()? onChanged;

  BreakableObject({
    required this.id,
    required Vector2 position,
    this.decorType = BreakableDecorType.plant,
    int? health,
    this.isBroken = false,
    this.onChanged,
  }) : super(
          position: position,
          size: Vector2(decorType.sizeX, decorType.sizeY),
        ) {
    this.health = (health ?? decorType.maxHealth).clamp(0, decorType.maxHealth);
    if (this.health <= 0) {
      this.health = 0;
      isBroken = true;
    }
  }

  @override
  void render(Canvas canvas) {
    switch (decorType) {
      case BreakableDecorType.plant:
        isBroken ? _renderBrokenPlant(canvas) : _renderPlant(canvas);
      case BreakableDecorType.vase:
        isBroken ? _renderBrokenVase(canvas) : _renderVase(canvas);
      case BreakableDecorType.lamp:
        isBroken ? _renderBrokenLamp(canvas) : _renderLamp(canvas);
      case BreakableDecorType.globe:
        isBroken ? _renderBrokenGlobe(canvas) : _renderGlobe(canvas);
    }
  }

  // ── Plant ────────────────────────────────────────────────────────────────

  void _renderPlant(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final darkLeafPaint = Paint()..color = const Color(0xFF1B5E20);
    _drawLeaf(canvas, Offset(w * 0.5, h * 0.5), darkLeafPaint, 0, scale: 1.2);
    _drawLeaf(canvas, Offset(w * 0.3, h * 0.55), darkLeafPaint, -0.4, scale: 1.0);
    _drawLeaf(canvas, Offset(w * 0.7, h * 0.55), darkLeafPaint, 0.4, scale: 1.0);

    final lightLeafPaint = Paint()..color = const Color(0xFF4CAF50);
    _drawLeaf(canvas, Offset(w * 0.5, h * 0.4), lightLeafPaint, 0, scale: 1.1);
    _drawLeaf(canvas, Offset(w * 0.2, h * 0.45), lightLeafPaint, -0.5, scale: 0.9);
    _drawLeaf(canvas, Offset(w * 0.8, h * 0.45), lightLeafPaint, 0.5, scale: 0.9);

    _drawPot(canvas, body: const Color(0xFF795548), rim: const Color(0xFF4E342E));
    _drawCracks(canvas, baseY: 0.68);
  }

  void _renderBrokenPlant(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    _drawShards(canvas, const Color(0xFF5D4037));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.92), width: w * 0.6, height: h * 0.15),
      Paint()..color = const Color(0xFF3E2723),
    );
    final leafPaint = Paint()..color = const Color(0xFF2E7D32);
    _drawLeaf(canvas, Offset(w * 0.2, h * 0.92), leafPaint, 1.2);
    _drawLeaf(canvas, Offset(w * 0.8, h * 0.88), leafPaint, -1.0);
    _drawLeaf(canvas, Offset(w * 0.5, h * 0.85), leafPaint, 1.57);
  }

  // ── Vase ─────────────────────────────────────────────────────────────────

  void _renderVase(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final body = Paint()..color = const Color(0xFF5DADE2);
    final accent = Paint()..color = const Color(0xFF1A5276);
    final path = Path()
      ..moveTo(w * 0.35, h * 0.18)
      ..quadraticBezierTo(w * 0.5, h * 0.14, w * 0.65, h * 0.18)
      ..quadraticBezierTo(w * 0.88, h * 0.42, w * 0.72, h * 0.68)
      ..quadraticBezierTo(w * 0.62, h * 0.82, w * 0.65, h * 0.95)
      ..lineTo(w * 0.35, h * 0.95)
      ..quadraticBezierTo(w * 0.38, h * 0.82, w * 0.28, h * 0.68)
      ..quadraticBezierTo(w * 0.12, h * 0.42, w * 0.35, h * 0.18)
      ..close();
    canvas.drawPath(path, body);
    canvas.drawRect(Rect.fromLTWH(w * 0.32, h * 0.15, w * 0.36, h * 0.06), accent);
    canvas.drawRect(Rect.fromLTWH(w * 0.28, h * 0.55, w * 0.44, h * 0.05),
        Paint()..color = Colors.white.withValues(alpha: 0.35));
    canvas.drawRect(Rect.fromLTWH(w * 0.38, h * 0.28, w * 0.07, h * 0.45),
        Paint()..color = Colors.white.withValues(alpha: 0.18));
    _drawCracks(canvas, baseY: 0.4);
  }

  void _renderBrokenVase(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final shard = Paint()..color = const Color(0xFF5DADE2);
    for (final r in [
      Rect.fromLTWH(w * 0.15, h * 0.78, w * 0.22, h * 0.12),
      Rect.fromLTWH(w * 0.45, h * 0.82, w * 0.18, h * 0.10),
      Rect.fromLTWH(w * 0.62, h * 0.75, w * 0.2, h * 0.13),
    ]) {
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), shard);
    }
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.93), width: w * 0.7, height: h * 0.1),
      Paint()..color = const Color(0xFF1A5276).withValues(alpha: 0.5),
    );
  }

  // ── Lamp ─────────────────────────────────────────────────────────────────

  void _renderLamp(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    // Shade
    final shade = Path()
      ..moveTo(w * 0.28, h * 0.08)
      ..lineTo(w * 0.72, h * 0.08)
      ..lineTo(w * 0.86, h * 0.42)
      ..lineTo(w * 0.14, h * 0.42)
      ..close();
    canvas.drawPath(shade, Paint()..color = const Color(0xFFFFE082));
    canvas.drawPath(
      shade,
      Paint()
        ..color = const Color(0xFFF9A825)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Glow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.3), width: w * 0.45, height: h * 0.18),
      Paint()..color = const Color(0xFFFFF9C4).withValues(alpha: 0.5),
    );
    // Stem
    canvas.drawRect(Rect.fromLTWH(w * 0.46, h * 0.42, w * 0.08, h * 0.32),
        Paint()..color = const Color(0xFF8D6E63));
    // Base
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.22, h * 0.74, w * 0.56, h * 0.1),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF5D4037),
    );
    canvas.drawRect(Rect.fromLTWH(w * 0.28, h * 0.84, w * 0.44, h * 0.08),
        Paint()..color = const Color(0xFF4E342E));
    _drawCracks(canvas, baseY: 0.08, color: Colors.brown.shade800);
  }

  void _renderBrokenLamp(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    _drawShards(canvas, const Color(0xFFF9A825));
    canvas.drawRect(Rect.fromLTWH(w * 0.2, h * 0.86, w * 0.6, h * 0.08),
        Paint()..color = const Color(0xFF5D4037));
    canvas.drawLine(Offset(w * 0.5, h * 0.86), Offset(w * 0.4, h * 0.72),
        Paint()..color = const Color(0xFF8D6E63)..strokeWidth = 3);
  }

  // ── Globe ────────────────────────────────────────────────────────────────

  void _renderGlobe(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final center = Offset(w * 0.5, h * 0.38);
    final radius = w * 0.34;
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFF42A5F5));
    // Continents
    final land = Paint()..color = const Color(0xFF66BB6A);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.42, h * 0.32), width: w * 0.22, height: h * 0.18),
      land,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.62, h * 0.48), width: w * 0.16, height: h * 0.14),
      land,
    );
    // Meridian / equator
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(Offset(w * 0.16, h * 0.38), Offset(w * 0.84, h * 0.38), line);
    canvas.drawArc(
      Rect.fromCenter(center: center, width: radius * 1.2, height: radius * 2),
      -math.pi / 2,
      math.pi,
      false,
      line,
    );
    // Stand
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.4), width: w * 0.82, height: h * 0.7),
      -0.2,
      math.pi + 0.4,
      false,
      Paint()
        ..color = const Color(0xFF8D6E63)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawRect(Rect.fromLTWH(w * 0.46, h * 0.74, w * 0.08, h * 0.12),
        Paint()..color = const Color(0xFF6D4C41));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.28, h * 0.86, w * 0.44, h * 0.08),
          const Radius.circular(3)),
      Paint()..color = const Color(0xFF5D4037),
    );
    _drawCracks(canvas, baseY: 0.2, color: Colors.white70);
  }

  void _renderBrokenGlobe(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    _drawShards(canvas, const Color(0xFF42A5F5));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.28, h * 0.86, w * 0.44, h * 0.08),
          const Radius.circular(3)),
      Paint()..color = const Color(0xFF5D4037),
    );
    final land = Paint()..color = const Color(0xFF66BB6A);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.3, h * 0.8), width: w * 0.16, height: h * 0.08),
      land,
    );
  }

  // ── Shared helpers ───────────────────────────────────────────────────────

  void _drawPot(
    Canvas canvas, {
    required Color body,
    required Color rim,
  }) {
    final w = size.x;
    final h = size.y;
    final potPath = Path()
      ..moveTo(w * 0.25, h)
      ..lineTo(w * 0.75, h)
      ..lineTo(w * 0.85, h * 0.65)
      ..lineTo(w * 0.15, h * 0.65)
      ..close();
    canvas.drawPath(potPath, Paint()..color = body);
    canvas.drawRect(Rect.fromLTWH(w * 0.15, h * 0.65, w * 0.70, h * 0.12), Paint()..color = rim);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.25, h * 0.7, w * 0.1, h * 0.2),
      Paint()..color = Colors.white.withValues(alpha: 0.2),
    );
  }

  void _drawShards(Canvas canvas, Color color) {
    final w = size.x;
    final h = size.y;
    final shardPaint = Paint()..color = color;
    final path1 = Path()
      ..moveTo(w * 0.2, h * 0.9)
      ..lineTo(w * 0.4, h * 0.8)
      ..lineTo(w * 0.3, h * 0.95)
      ..close();
    final path2 = Path()
      ..moveTo(w * 0.6, h * 0.85)
      ..lineTo(w * 0.8, h * 0.9)
      ..lineTo(w * 0.7, h * 0.98)
      ..close();
    canvas.drawPath(path1, shardPaint);
    canvas.drawPath(path2, shardPaint);
  }

  void _drawCracks(Canvas canvas, {required double baseY, Color? color}) {
    if (health >= decorType.maxHealth) return;
    final w = size.x;
    final h = size.y;
    final crackPaint = Paint()
      ..color = color ?? Colors.black45
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final crackPath = Path()
      ..moveTo(w * 0.3, h * baseY)
      ..lineTo(w * 0.42, h * (baseY + 0.1))
      ..lineTo(w * 0.35, h * (baseY + 0.2));
    canvas.drawPath(crackPath, crackPaint);

    if (health <= decorType.maxHealth - 2) {
      final crackPath2 = Path()
        ..moveTo(w * 0.62, h * (baseY + 0.05))
        ..lineTo(w * 0.72, h * (baseY + 0.15));
      canvas.drawPath(crackPath2, crackPaint);
    }
  }

  void _drawLeaf(Canvas canvas, Offset pos, Paint paint, double angle, {double scale = 1.0}) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);
    canvas.scale(scale);
    // Draw a nice leaf shape
    final path = Path();
    path.moveTo(0, 0); // Stem
    path.quadraticBezierTo(-10, -10, 0, -30); // Left curve
    path.quadraticBezierTo(10, -10, 0, 0);  // Right curve
    path.close();
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_invulnerableTimer > 0) {
      _invulnerableTimer = math.max(0, _invulnerableTimer - dt);
    }
  }

  void hit() {
    if (isBroken || _invulnerableTimer > 0) return;
    health--;
    _invulnerableTimer = 0.6;
    if (health <= 0) {
      health = 0;
      isBroken = true;
    }
    onChanged?.call();
  }

  void reset() {
    final changed = isBroken || health != decorType.maxHealth;
    isBroken = false;
    health = decorType.maxHealth;
    _invulnerableTimer = 0;
    if (changed) onChanged?.call();
  }

  Map<String, dynamic> toStateMap() {
    return {
      'id': id,
      'type': decorType.name,
      'x': position.x,
      'y': position.y,
      'isBroken': isBroken,
      'health': health,
    };
  }

  static BreakableObject fromStateMap(Map<dynamic, dynamic> map) {
    final type = BreakableDecorType.fromName(map['type'] as String?);
    final x = (map['x'] as num?)?.toDouble() ?? 0;
    final y = (map['y'] as num?)?.toDouble() ?? 0;
    return BreakableObject(
      id: (map['id'] as String?) ?? 'decor-${DateTime.now().millisecondsSinceEpoch}',
      position: Vector2(x, y),
      decorType: type,
      isBroken: map['isBroken'] == true,
      health: (map['health'] as num?)?.toInt(),
    );
  }
}
