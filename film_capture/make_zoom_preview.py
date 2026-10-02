# Auto-zoom preview of a captured clip: camera follows the finger (from
# touches.json), eases in while touching, eases out when idle.
import json, sys, subprocess, math
from PIL import Image, ImageDraw
src, out = sys.argv[1], sys.argv[2]
meta = json.load(open(f'{src}/touches.json'))
W, H = 1080, 1350            # 4:5 feed preview
SW, SH = 1152, 2400
ff = subprocess.Popen(['ffmpeg','-v','error','-y','-f','image2pipe','-framerate','30','-c:v','png','-i','-',
                       '-c:v','libx264','-preset','medium','-crf','16','-pix_fmt','yuv420p',out], stdin=subprocess.PIPE)
cx, cy, z = SW/2, SH*0.42, 1.0
last_touch, idle = None, 99
for t in meta['touches']:
    if 'x' in t:
        last_touch = (float(t['x'])*SW, float(t['y'])*SH); idle = 0
    else:
        idle += 1
    active = last_touch is not None and idle < 25           # stay close ~0.8 s after release
    tx, ty = (last_touch if active else (SW/2, SH*0.42))
    tz = 2.1 if active else 1.0
    k = 0.10
    cx += (tx-cx)*k; cy += (ty-cy)*k; z += (tz-z)*0.07
    im = Image.open(f"{src}/{t['f']:04d}.png").convert('RGB')
    # crop window with output aspect, size by zoom (z=1 -> full width)
    cw = SW / z; ch = cw * H / W
    if ch > SH: ch = SH; cw = ch * W / H
    x0 = min(max(cx - cw/2, 0), SW - cw); y0 = min(max(cy - ch/2, 0), SH - ch)
    frame = im.crop((int(x0), int(y0), int(x0+cw), int(y0+ch))).resize((W, H), Image.LANCZOS)
    if 'x' in t:   # soft touch indicator
        px = (float(t['x'])*SW - x0) * W / cw; py = (float(t['y'])*SH - y0) * H / ch
        ov = Image.new('RGBA', (W, H), (0,0,0,0)); d = ImageDraw.Draw(ov)
        r = 34 if t['down'] else 26
        d.ellipse((px-r, py-r, px+r, py+r), fill=(255,255,255,70), outline=(255,255,255,170), width=3)
        frame = Image.alpha_composite(frame.convert('RGBA'), ov).convert('RGB')
    frame.save(ff.stdin, 'PNG', compress_level=1)
ff.stdin.close(); ff.wait()
print('ok', out)
