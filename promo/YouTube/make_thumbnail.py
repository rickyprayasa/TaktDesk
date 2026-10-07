#!/usr/bin/env python3
"""YouTube thumbnail (1280x720) for the ZYKL promo film: the phone from the
Lockdown scene on the right, the brand line large on the left.

usage: make_thumbnail.py [VIDEO] [SECONDS]
"""
import os, subprocess, sys, tempfile
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
VIDEO = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
    HERE, '..', '..', '..', 'zykl.app', 'promo', 'Video Motion Remaster', 'ZYKL_Promo_Remaster_44s_EN_Dark_16x9.mp4')
AT = sys.argv[2] if len(sys.argv) > 2 else '21.5'
W, H = 1280, 720
BG = (17, 18, 21)
BONE = (239, 236, 230)
AMBER = (255, 158, 0)
MUTED = (150, 156, 168)
MONO_B = '/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf'
MONO = '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf'


def tracked(d, xy, text, f, fill, track):
    x, y = xy
    for ch in text:
        d.text((x, y), ch, font=f, fill=fill)
        x += d.textlength(ch, font=f) + track


def main():
    with tempfile.TemporaryDirectory() as tmp:
        frame = os.path.join(tmp, 'f.png')
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-ss', AT, '-i', VIDEO, '-frames:v', '1', frame], check=True)
        base = Image.open(frame).convert('RGB').resize((W, H), Image.LANCZOS)

    img = Image.new('RGB', (W, H), BG)
    img.paste(base, (90, 0))   # nudge the phone a little further right
    # cover the frame's own copy: solid on the left, fading out before the phone
    fade = Image.new('L', (W, 1), 0)
    for x in range(W):
        fade.putpixel((x, 0), 255 if x < 720 else max(0, int(255 * (1 - (x - 720) / 110))))
    img.paste(Image.new('RGB', (W, H), BG), (0, 0), fade.resize((W, H)))
    # the frame's HUD labels sit in the top and bottom 60 px
    edge = Image.new('L', (1, H), 0)
    for y in range(H):
        edge.putpixel((0, y), 255 if y < 52 or y > H - 52 else max(0, 255 - 255 * min(y - 52, H - 52 - y) // 24))
    img.paste(Image.new('RGB', (W, H), BG), (0, 0), edge.resize((W, H)))

    d = ImageDraw.Draw(img)
    logo = Image.open(os.path.join(HERE, '..', 'Logo ZYKL', 'ZYKL_Wordmark_OnDark_transparent.png')).convert('RGBA')
    logo = logo.crop(logo.getbbox())
    logo = logo.resize((150, round(logo.height * 150 / logo.width)), Image.LANCZOS)
    img.paste(logo, (72, 66), logo)

    big = ImageFont.truetype(MONO_B, 92)
    y = 196
    for text, color in (('Quiet Time.', BONE), ('Physical', AMBER), ('Intent.', AMBER)):
        d.text((68, y), text, font=big, fill=color)
        y += 112
    tracked(d, (72, y + 26), 'POMODORO FOCUS TIMER  ·  ANDROID', ImageFont.truetype(MONO, 22), MUTED, 3)

    out = os.path.join(HERE, 'ZYKL_YouTube_Thumbnail_1280x720.jpg')
    img.save(out, quality=92, optimize=True)
    print(out, f'{os.path.getsize(out) / 1e6:.2f} MB')


if __name__ == '__main__':
    main()
