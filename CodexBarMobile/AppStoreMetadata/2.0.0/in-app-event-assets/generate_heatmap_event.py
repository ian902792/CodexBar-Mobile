#!/usr/bin/env python3
"""Render deterministic App Store In-App Event concepts for Token Activity."""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parent
FONT = "/System/Library/Fonts/SFNS.ttf"
FONT_ROUNDED = "/System/Library/Fonts/SFNSRounded.ttf"
FONT_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
FONT_ROUNDED_BOLD = "/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf"


def font(size: int, bold: bool = False, rounded: bool = False) -> ImageFont.FreeTypeFont:
    if rounded and bold:
        path = FONT_ROUNDED_BOLD
    elif bold:
        path = FONT_BOLD
    elif rounded:
        path = FONT_ROUNDED
    else:
        path = FONT
    return ImageFont.truetype(path, size=size, index=0)


def linear_gradient(size: tuple[int, int], start: tuple[int, int, int], end: tuple[int, int, int]) -> Image.Image:
    width, height = size
    image = Image.new("RGB", size)
    pixels = image.load()
    for y in range(height):
        for x in range(width):
            t = (x / max(width - 1, 1)) * 0.62 + (y / max(height - 1, 1)) * 0.38
            pixels[x, y] = tuple(round(start[i] * (1 - t) + end[i] * t) for i in range(3))
    return image


def add_ambient_shapes(image: Image.Image, portrait: bool = False) -> None:
    width, height = image.size
    layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    shapes = (
        [
            (-380, -500, 900, 780, (38, 154, 255, 42)),
            (950, -300, 2300, 1050, (118, 92, 255, 44)),
            (380, 650, 1900, 1900, (58, 216, 209, 34)),
        ]
        if not portrait
        else [
            (-500, -360, 850, 980, (38, 154, 255, 45)),
            (470, 140, 1450, 1150, (121, 96, 255, 44)),
            (-350, 1050, 900, 2250, (58, 216, 209, 38)),
        ]
    )
    for box in shapes:
        draw.ellipse(box[:4], fill=box[4])
    image.paste(layer, (0, 0), layer)


def draw_heatmap(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], seed: int, active_fraction: float) -> None:
    x0, y0, x1, y1 = box
    cols, rows = 26, 7
    gap = max(4, round((x1 - x0) * 0.008))
    cell = min((x1 - x0 - gap * (cols - 1)) // cols, (y1 - y0 - gap * (rows - 1)) // rows)
    rng = random.Random(seed)
    palette = [(220, 231, 246), (177, 216, 255), (111, 187, 255), (51, 154, 250), (8, 122, 255)]
    for col in range(cols):
        for row in range(rows):
            x = x0 + col * (cell + gap)
            y = y0 + row * (cell + gap)
            progress = (col * rows + row) / (cols * rows)
            if progress < 1 - active_fraction:
                fill = (244, 247, 252)
                outline = (211, 221, 235)
            else:
                wave = (math.sin(col * 1.67 + row * 0.71) + 1) / 2
                level = min(4, max(1, round(wave * 3.2 + rng.random() * 0.9)))
                fill = palette[level]
                outline = None
            radius = max(3, cell // 5)
            draw.rounded_rectangle((x, y, x + cell, y + cell), radius=radius, fill=fill, outline=outline, width=2)


def heatmap_share_card(width: int) -> Image.Image:
    height = round(width * 520 / 390)
    scale = width / 1170
    card = Image.new("RGB", (width, height), (250, 252, 255))
    overlay = Image.new("RGBA", card.size, (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    od.ellipse((width * 0.42, -height * 0.08, width * 1.08, height * 0.58), fill=(0, 122, 255, 18))
    od.ellipse((-width * 0.3, height * 0.58, width * 0.55, height * 1.18), fill=(66, 209, 204, 14))
    card.paste(overlay, (0, 0), overlay)
    draw = ImageDraw.Draw(card)
    p = round(66 * scale)
    blue = (10, 132, 255)
    secondary = (118, 126, 140)
    draw.text((p, round(56 * scale)), "Token Activity", font=font(round(64 * scale), bold=True), fill=(16, 20, 28))
    draw.text((p, round(132 * scale)), "Past Year · All Providers", font=font(round(36 * scale)), fill=secondary)
    icon_x = width - p - round(66 * scale)
    icon_y = round(55 * scale)
    draw.rounded_rectangle((icon_x, icon_y, icon_x + round(62 * scale), icon_y + round(62 * scale)), radius=round(12 * scale), outline=blue, width=round(7 * scale))
    for c in range(3):
        for r in range(3):
            cx = icon_x + round((12 + c * 18) * scale)
            cy = icon_y + round((12 + r * 18) * scale)
            draw.rounded_rectangle((cx, cy, cx + round(10 * scale), cy + round(10 * scale)), radius=round(2 * scale), fill=blue)

    draw.text((p, round(238 * scale)), "≥155,203,462", font=font(round(108 * scale), bold=True, rounded=True), fill=(5, 8, 14))
    draw.text((p, round(360 * scale)), "Recorded tokens", font=font(round(38 * scale)), fill=secondary)

    metric_y = round(438 * scale)
    metric_h = round(190 * scale)
    metric_gap = round(30 * scale)
    metric_w = (width - p * 2 - metric_gap) // 2
    for index, (title, value) in enumerate((("Active Days", "160"), ("Peak Day", "1.8M"))):
        x = p + index * (metric_w + metric_gap)
        draw.rounded_rectangle((x, metric_y, x + metric_w, metric_y + metric_h), radius=round(34 * scale), fill=(236, 241, 248))
        draw.text((x + round(34 * scale), metric_y + round(26 * scale)), title, font=font(round(34 * scale)), fill=secondary)
        draw.text((x + round(34 * scale), metric_y + round(82 * scale)), value, font=font(round(64 * scale), bold=True, rounded=True), fill=(9, 13, 20))

    label_font = font(round(23 * scale), bold=True)
    first_top = round(716 * scale)
    block_height = round(260 * scale)
    draw.text((p, first_top - round(42 * scale)), "SEP 2025", font=label_font, fill=secondary)
    draw.text((width - p - round(120 * scale), first_top - round(42 * scale)), "MAR 2026", font=label_font, fill=secondary)
    draw_heatmap(draw, (p, first_top, width - p, first_top + block_height), seed=11, active_fraction=0.12)
    second_top = first_top + block_height + round(82 * scale)
    draw.text((p, second_top - round(42 * scale)), "MAR 2026", font=label_font, fill=secondary)
    draw.text((width - p - round(122 * scale), second_top - round(42 * scale)), "SEP 2026", font=label_font, fill=secondary)
    draw_heatmap(draw, (p, second_top, width - p, second_top + block_height), seed=27, active_fraction=0.88)

    legend_y = second_top + block_height + round(50 * scale)
    draw.text((p, legend_y), "Less", font=font(round(25 * scale)), fill=secondary)
    for i, color in enumerate(((177, 216, 255), (111, 187, 255), (51, 154, 250), (8, 122, 255))):
        x = p + round((75 + i * 42) * scale)
        draw.rounded_rectangle((x, legend_y, x + round(28 * scale), legend_y + round(28 * scale)), radius=round(6 * scale), fill=color)
    draw.text((p + round(255 * scale), legend_y), "More", font=font(round(25 * scale)), fill=secondary)
    message = "Missing history is not zero."
    message_width = draw.textlength(message, font=font(round(25 * scale)))
    draw.text((width - p - message_width, legend_y), message, font=font(round(25 * scale)), fill=secondary)

    divider_y = height - round(192 * scale)
    draw.line((p, divider_y, width - p, divider_y), fill=(215, 222, 233), width=max(1, round(2 * scale)))
    draw.text((p, divider_y + round(40 * scale)), "CodexBar", font=font(round(42 * scale), bold=True), fill=(14, 18, 26))
    draw.text((p, divider_y + round(98 * scale)), "Your AI activity, at a glance", font=font(round(29 * scale)), fill=secondary)
    return card


def paste_card(canvas: Image.Image, card: Image.Image, xy: tuple[int, int], radius: int, rotate: float = 0) -> None:
    mask = Image.new("L", card.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, card.width - 1, card.height - 1), radius=radius, fill=255)
    rgba = card.convert("RGBA")
    rgba.putalpha(mask)
    if rotate:
        rgba = rgba.rotate(rotate, resample=Image.Resampling.BICUBIC, expand=True)
    shadow = Image.new("RGBA", rgba.size, (0, 0, 0, 0))
    shadow.putalpha(rgba.getchannel("A").filter(ImageFilter.GaussianBlur(radius=28)))
    dark = Image.new("RGBA", rgba.size, (18, 53, 104, 78))
    dark.putalpha(shadow.getchannel("A").point(lambda value: round(value * 0.36)))
    canvas.paste(dark, (xy[0] + 12, xy[1] + 28), dark)
    canvas.paste(rgba, xy, rgba)


def event_card() -> Image.Image:
    image = linear_gradient((1920, 1080), (248, 252, 255), (218, 234, 255))
    add_ambient_shapes(image)
    draw = ImageDraw.Draw(image)
    for index in range(9):
        opacity = 34 + index * 10
        x = 910 + index * 58
        y = 110 + (index % 3) * 58
        draw.rounded_rectangle((x, y, x + 38, y + 38), radius=9, fill=(10, 132, 255, opacity))
    card = heatmap_share_card(650)
    paste_card(image, card, (1190, 65), radius=38, rotate=1.5)
    return image


def event_detail() -> Image.Image:
    image = linear_gradient((1080, 1920), (242, 249, 255), (210, 229, 255))
    add_ambient_shapes(image, portrait=True)
    draw = ImageDraw.Draw(image, "RGBA")
    for col in range(7):
        for row in range(5):
            x = 70 + col * 78
            y = 175 + row * 78
            level = (col * 5 + row * 3) % 4
            draw.rounded_rectangle((x, y, x + 48, y + 48), radius=11, fill=(10, 132, 255, 36 + level * 26))
    card = heatmap_share_card(820)
    paste_card(image, card, (130, 275), radius=45)
    return image


def composite_preview(card_media: Image.Image) -> Image.Image:
    preview = card_media.copy()
    veil = Image.new("RGBA", preview.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(veil)
    draw.text((90, 760), "MAJOR UPDATE", font=font(34, bold=True), fill=(74, 88, 110))
    draw.text((90, 824), "Token Activity Heatmaps", font=font(68, bold=True), fill=(9, 16, 29))
    draw.text((90, 932), "See a year of AI activity", font=font(44), fill=(66, 78, 99))
    preview.paste(veil, (0, 0), veil)
    return preview


def main() -> None:
    ROOT.mkdir(parents=True, exist_ok=True)
    card = event_card()
    detail = event_detail()
    preview = composite_preview(card)
    for name, image in (
        ("draft-heatmap-event-card.png", card),
        ("draft-heatmap-event-detail.png", detail),
        ("draft-heatmap-event-card-preview.png", preview),
    ):
        image.save(ROOT / name, format="PNG", optimize=True)


if __name__ == "__main__":
    main()
