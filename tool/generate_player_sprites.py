"""Generate the SafeRoom player's directional pixel-art sprites.

Run from the repository root:

    python3 tool/generate_player_sprites.py

The script intentionally uses a tiny logical grid (25x33) scaled 2x so every
frame is a crisp 50x65 transparent PNG, matching the player's in-game size.
All frames share one palette and the same proportions.
"""

from pathlib import Path

from PIL import Image, ImageDraw

SCALE = 2
GRID_W = 25
GRID_H = 33
OUT_DIR = Path("assets/sprites")

PALETTE = {
    "outline": "#2E1919",
    "hair_dark": "#4A3728",
    "hair_light": "#6A4C34",
    "skin": "#FFDBB4",
    "skin_shadow": "#E6B98F",
    "shirt": "#6B5CE7",
    "shirt_dark": "#5749C4",
    "shirt_light": "#8A7BEF",
    "pants": "#2C3E50",
    "pants_dark": "#1F2D3D",
    "shoes": "#552E25",
    "eye": "#1A1A1A",
    "green": "#3C532D",
    "cream": "#FFFACD",
}


def new_canvas():
    image = Image.new("RGBA", (GRID_W * SCALE, GRID_H * SCALE), (0, 0, 0, 0))
    return image, ImageDraw.Draw(image)


def rect(draw, x, y, w, h, color):
    draw.rectangle(
        (
            x * SCALE,
            y * SCALE,
            (x + w) * SCALE - 1,
            (y + h) * SCALE - 1,
        ),
        fill=PALETTE[color] if isinstance(color, str) else color,
    )


def draw_legs(draw, walk, profile=False):
    if walk:
        rect(draw, 8, 18, 4, 10, "pants_dark")
        rect(draw, 8, 23, 4, 1, "pants")
        rect(draw, 8, 28, 5, 2, "shoes")
        rect(draw, 14, 19, 4, 10, "pants")
        rect(draw, 14, 25, 4, 1, "pants_dark")
        rect(draw, 14, 29, 5, 2, "shoes")
    else:
        rect(draw, 8, 18, 4, 11, "pants")
        rect(draw, 8, 24, 4, 1, "pants_dark")
        rect(draw, 7, 29, 5, 2, "shoes")
        rect(draw, 13, 18, 4, 11, "pants")
        rect(draw, 13, 24, 4, 1, "pants_dark")
        rect(draw, 13, 29, 5, 2, "shoes")


def draw_front(walk):
    image, draw = new_canvas()
    draw_legs(draw, walk)

    # Hoodie body.
    rect(draw, 5, 10, 15, 9, "outline")
    rect(draw, 6, 11, 13, 8, "shirt")
    rect(draw, 6, 11, 2, 6, "shirt_dark")
    rect(draw, 17, 11, 2, 6, "shirt_dark")
    rect(draw, 9, 11, 7, 2, "shirt_light")
    rect(draw, 11, 13, 1, 4, "cream")
    rect(draw, 14, 13, 1, 4, "cream")
    for step in range(7):
        rect(draw, 8 + step, 12 + step, 1, 1, "green")

    # Hands swing with the walk cycle.
    hand_y = 14 if walk else 15
    rect(draw, 4, hand_y, 2, 2, "skin")
    rect(draw, 19, hand_y + (1 if walk else 0), 2, 2, "skin")

    # Head and hair.
    rect(draw, 6, 0, 13, 10, "outline")
    rect(draw, 7, 1, 11, 8, "hair_dark")
    rect(draw, 8, 4, 9, 6, "skin")
    rect(draw, 8, 3, 9, 2, "hair_dark")
    rect(draw, 8, 5, 3, 1, "hair_dark")
    rect(draw, 14, 5, 3, 1, "hair_dark")
    rect(draw, 7, 6, 1, 2, "skin_shadow")
    rect(draw, 17, 6, 1, 2, "skin_shadow")
    rect(draw, 10, 6, 1, 2, "eye")
    rect(draw, 14, 6, 1, 2, "eye")
    rect(draw, 12, 7, 1, 1, "skin_shadow")
    rect(draw, 11, 9, 3, 1, "skin_shadow")
    return image


def draw_right_profile(walk):
    image, draw = new_canvas()
    draw_legs(draw, walk, profile=True)

    # Hoodie body, back on the left, face on the right.
    rect(draw, 5, 10, 15, 9, "outline")
    rect(draw, 6, 11, 13, 8, "shirt")
    rect(draw, 6, 11, 3, 7, "shirt_dark")
    rect(draw, 16, 11, 3, 7, "shirt_light")
    rect(draw, 11, 11, 5, 2, "shirt_light")
    rect(draw, 13, 13, 1, 4, "cream")
    for step in range(7):
        rect(draw, 9 + step, 12 + step, 1, 1, "green")

    hand_y = 14 if walk else 15
    rect(draw, 18, hand_y, 2, 2, "skin")

    # Head facing screen-right.
    rect(draw, 8, 0, 12, 10, "outline")
    rect(draw, 9, 1, 10, 8, "hair_dark")
    rect(draw, 12, 4, 6, 6, "skin")
    rect(draw, 9, 3, 7, 2, "hair_dark")
    rect(draw, 9, 5, 3, 2, "hair_dark")
    rect(draw, 16, 6, 1, 2, "eye")
    rect(draw, 18, 7, 1, 1, "skin_shadow")
    rect(draw, 15, 9, 3, 1, "skin_shadow")
    return image


def draw_back(walk):
    image, draw = new_canvas()
    draw_legs(draw, walk)

    rect(draw, 5, 10, 15, 9, "outline")
    rect(draw, 6, 11, 13, 8, "shirt")
    rect(draw, 6, 11, 2, 7, "shirt_dark")
    rect(draw, 17, 11, 2, 7, "shirt_dark")
    rect(draw, 8, 10, 9, 4, "shirt_light")
    for step in range(7):
        rect(draw, 8 + step, 12 + step, 1, 1, "green")
        rect(draw, 16 - step, 12 + step, 1, 1, "green")

    hand_y = 14 if walk else 15
    rect(draw, 4, hand_y, 2, 2, "skin")
    rect(draw, 19, hand_y, 2, 2, "skin")

    # Full hair from behind, no face.
    rect(draw, 6, 0, 13, 10, "outline")
    rect(draw, 7, 1, 11, 9, "hair_dark")
    rect(draw, 8, 2, 9, 2, "hair_light")
    rect(draw, 7, 5, 2, 4, "hair_dark")
    rect(draw, 16, 5, 2, 4, "hair_dark")
    rect(draw, 11, 8, 3, 1, "hair_light")
    return image


def save(image, name):
    target = OUT_DIR / name
    image.crop((0, 0, GRID_W * SCALE, GRID_H * SCALE - 1)).save(target)
    print(f"wrote {target} ({target.stat().st_size} bytes)")


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    for walk in (False, True):
        suffix = "walk" if walk else "idle"
        save(draw_front(walk), f"player_front_{suffix}.png")

        right = draw_right_profile(walk)
        save(right, f"player_right_{suffix}.png")
        save(right.transpose(Image.Transpose.FLIP_LEFT_RIGHT), f"player_left_{suffix}.png")

        save(draw_back(walk), f"player_back_{suffix}.png")


if __name__ == "__main__":
    main()
