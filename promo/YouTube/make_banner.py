#!/usr/bin/env python3
"""YouTube channel banner for ZYKL (2560x1440, safe area 1546x423 centred).

usage: make_banner.py [--guides]   (--guides also writes a copy with the
TV / desktop / all-devices crop boxes drawn, for checking only)
"""
import math, os, sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
LOGO = os.path.join(HERE, '..', 'Logo ZYKL')
W, H = 2560, 1440
SAFE = (507, 508, 2053, 931)          # visible on every device
DESK = (0, 508, 2560, 931)            # desktop strip (full width)
BG = (17, 18, 21)
AMBER = (217, 155, 89)                # TaktColors.filamentAmber
SIGNAL = (255, 158, 0)
BONE = (239, 236, 230)
MUTED = (142, 149, 162)
TICK = (70, 74, 82)
MONO = '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf'
MONO_B = '/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf'


def font(p, s):
    return ImageFont.truetype(p, s)


def tracked(d, xy, text, f, fill, track):
    x, y = xy
    for ch in text:
        d.text((x, y), ch, font=f, fill=fill)
        x += d.textlength(ch, font=f) + track
    return x


def tracked_width(d, text, f, track):
    return sum(d.textlength(c, font=f) + track for c in text) - track


def background():
    bg = Image.new('RGB', (W, H), BG)
    glow = Image.new('L', (W, H), 0)
    ImageDraw.Draw(glow).ellipse((W / 2 - 900, H / 2 - 420, W / 2 + 900, H / 2 + 420), fill=34)
    glow = glow.filter(ImageFilter.GaussianBlur(220))
    bg.paste(Image.new('RGB', (W, H), (60, 52, 40)), (0, 0), glow)
    noise = Image.effect_noise((W, H), 10).point(lambda p: max(0, p - 118) // 7)
    bg.paste(Image.new('RGB', (W, H), (255, 255, 255)), (0, 0), noise)
    return bg


def dial_scale(d, y):
    """Escapement scale on the desktop-only sides of the strip (never behind the copy)."""
    gap = 70
    sides = ((110, SAFE[0] - gap), (SAFE[2] + gap, W - 110))
    f = font(MONO, 20)
    for side, (x0, x1) in enumerate(sides):
        n = 20
        d.line((x0, y, x1, y), fill=TICK, width=2)
        for i in range(n + 1):
            x = x0 + (x1 - x0) * i / n
            major = i % 5 == 0
            h = 26 if major else 12
            d.line((x, y - h, x, y), fill=(96, 100, 108) if major else TICK, width=3 if major else 2)
            if major:
                lab = f'{i + side * 40:02d}' if side else f'{i:02d}'
                d.text((x - d.textlength(lab, font=f) / 2, y + 12), lab, font=f, fill=(88, 92, 100))
    # needle resting at 15 on the left scale (first quarter of a cycle)
    x0, x1 = sides[0]
    nx = x0 + (x1 - x0) * 15 / 20
    d.line((nx, y - 58, nx, y + 4), fill=SIGNAL, width=4)
    d.ellipse((nx - 7, y - 65, nx + 7, y - 51), fill=SIGNAL)


def circle_avatar(size):
    im = Image.open(os.path.join(LOGO, 'ZYKL_Avatar_Clock_dark_1080.png')).convert('RGBA')
    # the avatar sits on a dark square: keep only the round instrument
    im = im.crop((60, 60, 1020, 1020)).resize((size, size), Image.LANCZOS)
    mask = Image.new('L', (size * 4, size * 4), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, size * 4 - 1, size * 4 - 1), fill=255)
    im.putalpha(mask.resize((size, size), Image.LANCZOS))
    return im


def main():
    img = background()
    d = ImageDraw.Draw(img)
    sx0, sy0, sx1, sy1 = SAFE
    cy = (sy0 + sy1) // 2
    dial_scale(d, cy + 40)

    # all-devices block: avatar + logo + two lines, all inside the safe area
    logo = Image.open(os.path.join(LOGO, 'ZYKL_Logo_PomodoroFocusTimer_OnDark_transparent.png')).convert('RGBA')
    logo = logo.crop(logo.getbbox())
    lw = 560
    logo = logo.resize((lw, round(logo.height * lw / logo.width)), Image.LANCZOS)
    f1, f2 = font(MONO_B, 32), font(MONO, 22)
    gap1, gap2 = 40, 18
    block_h = logo.height + gap1 + 32 + gap2 + 22
    av = 290
    block_w = av + 100 + max(lw, round(tracked_width(d, 'ANALOG FOCUS INSTRUMENT FOR ANDROID  ·  ZYKL.APP', f2, 3)))
    bx = (W - block_w) // 2
    top = cy - block_h // 2

    shadow = Image.new('L', (W, H), 0)
    ImageDraw.Draw(shadow).ellipse((bx, cy - av // 2 + 20, bx + av, cy + av // 2 + 20), fill=150)
    img.paste(Image.new('RGB', (W, H), (0, 0, 0)), (0, 0), shadow.filter(ImageFilter.GaussianBlur(26)))
    a = circle_avatar(av)
    img.paste(a, (bx, cy - av // 2), a)

    lx = bx + av + 100
    img.paste(logo, (lx, top), logo)
    d = ImageDraw.Draw(img)
    y = top + logo.height + gap1
    tracked(d, (lx, y), 'Quiet Time. Physical Intent.', f1, BONE, 1.5)
    tracked(d, (lx, y + 32 + gap2), 'ANALOG FOCUS INSTRUMENT FOR ANDROID  ·  ZYKL.APP', f2, MUTED, 3)
    assert sx0 < bx and lx + block_w - av - 100 < sx1 and sy0 < top and top + block_h < sy1, 'outside safe area'

    # TV-only frame marks (outside the desktop strip)
    for cx, cyy in ((60, 60), (W - 61, 60), (60, H - 61), (W - 61, H - 61)):
        pts = [(cx + 12 * math.cos(math.pi / 3 * i + math.pi / 6), cyy + 12 * math.sin(math.pi / 3 * i + math.pi / 6)) for i in range(6)]
        d.polygon(pts, outline=(104, 83, 40))
    d.rectangle((40, 40, W - 41, H - 41), outline=(70, 58, 34), width=2)

    out = os.path.join(HERE, 'ZYKL_YouTube_Banner_2560x1440.png')
    img.save(out, optimize=True)
    print(out, f'{os.path.getsize(out) / 1e6:.2f} MB')

    if '--guides' in sys.argv:
        g = img.copy()
        gd = ImageDraw.Draw(g)
        gd.rectangle(DESK, outline=(0, 160, 255), width=4)
        gd.rectangle(SAFE, outline=(255, 60, 60), width=4)
        gd.text((SAFE[0] + 8, SAFE[1] + 6), 'ALL DEVICES 1546x423', font=font(MONO_B, 22), fill=(255, 60, 60))
        gd.text((DESK[0] + 8, DESK[1] + 6), 'DESKTOP 2560x423', font=font(MONO_B, 22), fill=(0, 160, 255))
        g.save(os.path.join(HERE, 'banner_guides_preview.png'))


if __name__ == '__main__':
    main()
