import 'package:flame/components.dart';
import 'package:material_ui/material_ui.dart';

/// Room component - displays background and defines collision zones
class Room extends PositionComponent {
  final Vector2 screenSize;
  final String backgroundAsset;
  SpriteComponent? backgroundSprite;

  Room({
    required this.screenSize,
    this.backgroundAsset = 'room_background.png',
  }) : super(priority: 0);

  @override
  Future<void> onLoad() async {
    // CRITICAL: Room size must match screen size exactly
    size = screenSize;
    position = Vector2.zero();

    debugPrint('Room onLoad - size: $size');

    await setBackground(backgroundAsset);
  }

  Future<void> setBackground(String assetPath) async {
    try {
      final sprite = await Sprite.load(assetPath);
      if (backgroundSprite != null) {
        backgroundSprite!.sprite = sprite;
        backgroundSprite!.size = size;
      } else {
        backgroundSprite = SpriteComponent(
          sprite: sprite,
          size: size, // Fill entire room = entire screen
          position: Vector2.zero(),
        );
        add(backgroundSprite!);
      }
      debugPrint('Room background loaded: $assetPath');
    } catch (e) {
      debugPrint('ERROR loading room background: $e');
    }
  }

  @override
  void render(Canvas canvas) {
    // Only draw fallback if background failed to load
    if (backgroundSprite == null) {
      _drawFallbackRoom(canvas);
    }
    super.render(canvas);
  }
  
  /// Fallback room if image doesn't load
  void _drawFallbackRoom(Canvas canvas) {
    // Floor
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = const Color(0xFFDEB887),
    );
    
    // Top wall
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y * 0.18),
      Paint()..color = const Color(0xFF8B4513),
    );
    
    // Bottom wall
    canvas.drawRect(
      Rect.fromLTWH(0, size.y * 0.92, size.x, size.y * 0.08),
      Paint()..color = const Color(0xFF8B4513),
    );
    
    // Left wall
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x * 0.08, size.y),
      Paint()..color = const Color(0xFF8B4513),
    );
    
    // Right wall
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.92, 0, size.x * 0.08, size.y),
      Paint()..color = const Color(0xFF8B4513),
    );
  }

  /// Get ALL collision rectangles for walls and furniture
  /// These percentages are calibrated to match the background image layout
  List<Rect> getCollisionRects() {
    debugPrint('Creating collision rects for room size: $size');
    
    final rects = [
      // === WALLS ===
      // Top wall (contains window, shelves, and top decorations)
      Rect.fromLTWH(0, 0, size.x, size.y * 0.20),
      
      // Bottom wall
      Rect.fromLTWH(0, size.y * 0.90, size.x, size.y * 0.10),
      
      // Left wall (contains left-side plants)
      Rect.fromLTWH(0, 0, size.x * 0.10, size.y),
      
      // Right wall (contains right-side plants)
      Rect.fromLTWH(size.x * 0.90, 0, size.x * 0.10, size.y),
      
      // === FURNITURE AND OBJECTS ===
      // Fireplace (top center)
      Rect.fromLTWH(size.x * 0.38, size.y * 0.10, size.x * 0.24, size.y * 0.18),
      
      // Bookshelf (top right)
      Rect.fromLTWH(size.x * 0.72, size.y * 0.08, size.x * 0.18, size.y * 0.28),
      
      // Sofa (right side, mid-height)
      Rect.fromLTWH(size.x * 0.72, size.y * 0.42, size.x * 0.18, size.y * 0.22),
      
      // Desk with computer (bottom left)
      Rect.fromLTWH(size.x * 0.08, size.y * 0.65, size.x * 0.18, size.y * 0.22),
      
      // Bottom left plants
      Rect.fromLTWH(size.x * 0.04, size.y * 0.75, size.x * 0.08, size.y * 0.13),
      
      // Bottom right plants
      Rect.fromLTWH(size.x * 0.88, size.y * 0.75, size.x * 0.08, size.y * 0.13),
      
      // Center rug area furniture (if any)
      // Adjust these based on your actual background image
    ];
    
    debugPrint('Created ${rects.length} collision rectangles');
    return rects;
  }

  /// Desk interaction zone (bottom left area)
  Rect getDeskInteractionZone() {
    return Rect.fromLTWH(
      size.x * 0.05, 
      size.y * 0.55, 
      size.x * 0.25, 
      size.y * 0.35,
    );
  }

  /// Couch interaction zone (bottom right area)
  Rect getCouchInteractionZone() {
    return Rect.fromLTWH(
      size.x * 0.75, 
      size.y * 0.70, 
      size.x * 0.25, 
      size.y * 0.30,
    );
  }

  /// Library/bookshelf interaction zone (top right area, in front of bookshelf).
  Rect getLibraryInteractionZone() {
    return Rect.fromLTWH(
      size.x * 0.68,
      size.y * 0.20,
      size.x * 0.24,
      size.y * 0.30,
    );
  }
  
  /// Breakable object zone (Bottom Right, based on user coordinates [392, 759])
  Vector2 getBreakableObjectPosition() {
    // User requested ~392, 759 which is the bottom-right corner.
    // Placing it slightly inward so it's visible.
    return Vector2(size.x * 0.80, size.y * 0.80);
  }
}
