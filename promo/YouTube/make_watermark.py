#!/usr/bin/env python3
"""YouTube video watermark: a ZYKL logo on a transparent 150x150 PNG, with a
soft shadow so it stays readable on light frames.

usage: make_watermark.py [wordmark|tagline]   (default: wordmark)
"""
import os, sys
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
VARIANTS = {
    'wordmark': ('ZYKL_Wordmark_OnDark_transparent.png', 'ZYKL_YouTube_Watermark_150.png'),
    'tagline': ('ZYKL_Logo_Tagline_QuietTime_OnDark_transparent.png', 'ZYKL_YouTube_Watermark_150_Tagline.png'),
}
variant = sys.argv[1] if len(sys.argv) > 1 else 'wordmark'
src_name, out_name = VARIANTS[variant]
SRC = os.path.join(HERE, '..', 'Logo ZYKL', src_name)
SIZE, SCALE = 150, 4          # draw at 4x, downsample once
MARGIN = 8                    # px per side at final size

mark = Image.open(SRC).convert('RGBA')
mark = mark.crop(mark.getbbox())
big = SIZE * SCALE
w = big - 2 * MARGIN * SCALE
mark = mark.resize((w, round(mark.height * w / mark.width)), Image.LANCZOS)
x, y = (big - mark.width) // 2, (big - mark.height) // 2

canvas = Image.new('RGBA', (big, big), (0, 0, 0, 0))
shadow = Image.new('RGBA', (big, big), (0, 0, 0, 0))
shadow.paste((10, 10, 12, 150), (x, y + 2 * SCALE), mark.getchannel('A'))
canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(3 * SCALE)))
canvas.alpha_composite(mark, (x, y))

out = canvas.resize((SIZE, SIZE), Image.LANCZOS)
path = os.path.join(HERE, out_name)
out.save(path, optimize=True)
print(path, out.size, f'{os.path.getsize(path) / 1024:.1f} KB')
