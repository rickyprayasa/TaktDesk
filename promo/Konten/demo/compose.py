#!/usr/bin/env python3
"""Content-pack demo video: real app capture in a phone mockup, a calm camera
that zooms only on the key moments, step captions and the app's own sounds.

usage: compose.py <clip> [--still SECONDS ...] [--cues] [--src DIR] [--out FILE]
  clip: overview | reading | coding | studying | writing | creative | languages | admin
  Frames + touches.json come from film_capture/run_content.sh.
  --still renders PNG stills instead of the video (fast framing check).
  --cues prints the capture's chapter / tap timeline (to retime SHOTS).

Camera (v3, owner feedback 2026-10-07: following every tap made viewers dizzy):
the phone stays whole and still; it zooms only for the SHOTS listed per clip,
holds still during each shot and eases in/out once. The per-tap s.cam cues in
touches.json are no longer used for the camera, only as a timing reference.
Captions come from s.rec.chapter in film_capture/content_clips_test.dart.
"""
import json, math, os, subprocess, sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '../../..'))
AUDIO = os.path.join(REPO, 'assets/audio')
OUTDIR = os.path.join(HERE, '../Konten 1/video')

W, H, FPS, SRC_FPS = 1080, 1350, 60, 30
BG = (17, 18, 21)
AMBER = (255, 158, 0)
WHITE = (244, 242, 236)
MUTED = (142, 149, 162)
LINE = (104, 83, 40)
FONT_B = '/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf'
FONT_R = '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf'
FONT_UI = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'

# Screen regions (fraction of the captured app height) a shot keeps in view.
DIAL = (0.22, 0.70)     # dial + preset row / console
DIAL_LOCK = (0.24, 0.80)  # dial down to the MONASTIC LOCKDOWN button
SLIP = (0.66, 0.98)     # print-task sheet: typed text + FEED PAPER
DISP = (0.32, 0.72)     # dispenser with the printed slips (stamping)
LOCK = (0.40, 0.98)     # lockdown: engaged dial console + hold-to-leave bar

# Key moments only: (start s, end s or None = to the end, region), in capture
# seconds (see --cues). Everything else is the whole phone, still.
CLIPS = {
    'overview': dict(kicker='[ ONE TIMER, MANY FOCUS MODES ]', l1='One timer.', l2='Every kind of focus.',
                     shots=[(0.7, 4.5, DIAL), (15.8, 17.4, SLIP), (21.2, 23.2, DISP), (24.0, None, DIAL)]),
    'reading': dict(kicker='[ FOCUS FOR READING ]', l1='Reading a book?', l2='Give it 50 minutes.',
                    shots=[(10.5, 12.0, SLIP), (13.7, None, DIAL)]),
    'coding': dict(kicker='[ FOCUS FOR CODING ]', l1='Deep in the code?', l2='Stay 50 minutes.',
                   shots=[(9.9, 11.5, SLIP), (19.2, 21.2, DISP), (22.0, None, DIAL)]),
    'studying': dict(kicker='[ FOCUS FOR STUDYING ]', l1='Assignments piling up?', l2='Try 25 minutes.',
                     shots=[(9.9, 11.0, SLIP), (18.5, 21.0, DIAL_LOCK), (21.8, 28.2, LOCK)]),
    'writing': dict(kicker='[ FOCUS FOR WRITING ]', l1='Writing something?', l2='One small goal.',
                    shots=[(1.6, 8.0, DIAL), (16.0, 17.6, SLIP), (19.3, None, DIAL)]),
    'creative': dict(kicker='[ FOCUS FOR CREATIVE WORK ]', l1='Making something?', l2='Protect the flow.',
                     shots=[(1.6, 8.0, DIAL), (23.8, 25.6, SLIP), (27.3, None, DIAL)]),
    'languages': dict(kicker='[ FOCUS FOR LANGUAGES ]', l1='Learning a language?', l2='Short, calm bursts.',
                      shots=[(11.9, 13.4, SLIP), (18.2, None, DIAL)]),
    'admin': dict(kicker='[ FOCUS FOR ADMIN ]', l1='Boring admin?', l2='Make it 15 minutes.',
                  shots=[(10.3, 12.1, SLIP), (18.2, 21.7, DISP), (22.5, None, DIAL)]),
}

# Real app mapping (MainActivity.FOLEY_ASSETS). springButton / stepperPrint have
# no sound on the device either, so they stay silent here.
FOLEY = {
    'dialClick': ('foley_dial_click.wav', 0.9), 'inkStamp': ('foley_ink_stamp.wav', 1.0),
    'paperTear': ('foley_paper_tear.wav', 1.0), 'stylusDrop': ('foley_stylus_drop.wav', 1.0),
    'stylusStop': ('foley_stylus_stop.wav', 1.0), 'drawerSlide': ('foley_drawer_slide.wav', 0.9),
    'drawerLatch': ('foley_drawer_latch.wav', 0.9), 'discLoad': ('foley_disc_load.wav', 1.0),
    'switchClick': ('foley_switch_click.wav', 0.9), 'bellChime': ('alarm_braun_bell.wav', 0.8),
}

# Layout (canvas px)
DEVICE_H = 880          # device height at rest
ANCHOR = (540, 728)     # where the camera centre lands on the canvas
MX = 84                 # text margin (matches the slides)
INTRO, OUTRO = 1.2, 2.8 # seconds of opening / closing around the capture
# Camera
BAND = 700              # canvas px of clear space between the copy scrims
ZMAX = 1.55             # never closer than this
LEAD = 0.35             # start moving this long before a shot's start
MOVE = 1.0              # seconds per camera move (smootherstep)
MERGE = 1.6             # shots closer than this glide into each other directly
ICON = os.path.join(REPO, 'assets/images/zykl_icon.png')


def font(path, size):
    return ImageFont.truetype(path, size)


def tracked(d, xy, text, f, fill, track=0.0):
    """Text with letter spacing (PIL has none)."""
    x, y = xy
    for ch in text:
        d.text((x, y), ch, font=f, fill=fill)
        x += d.textlength(ch, font=f) + track
    return x


def track_names():
    """VinylTrack index -> asset file, parsed from the Dart source."""
    import re
    src = open(os.path.join(REPO, 'lib/features/vinyl/domain/vinyl_track.dart')).read()
    out = {}
    for m in re.finditer(r"index:\s*(\d+),.*?assetPath:\s*'assets/audio/([^']+)'", src, re.S):
        out[int(m.group(1))] = m.group(2)
    return out


class Device:
    """Phone mockup around the captured screen, built once at source resolution."""

    def __init__(self, first: Image.Image, pr: float):
        self.sw, self.sh = first.size
        u = pr                          # 1 logical px in source pixels
        self.sb = round(30 * u)         # status bar
        self.bz = round(13 * u)         # bezel
        self.pad = round(60 * u)        # room for shadow + side keys
        r_in = round(38 * u)
        self.ox = self.pad + self.bz
        self.oy = self.pad + self.bz
        dw = self.sw + 2 * self.bz
        dh = self.sh + self.sb + 2 * self.bz
        self.size = (dw + 2 * self.pad, dh + 2 * self.pad)
        self.body = (self.pad, self.pad, self.pad + dw, self.pad + dh)
        base = Image.new('RGBA', self.size, (0, 0, 0, 0))
        # soft shadow
        sh = Image.new('L', self.size, 0)
        ImageDraw.Draw(sh).rounded_rectangle(
            (self.pad, self.pad + 18 * u, self.pad + dw, self.pad + dh + 18 * u), r_in + self.bz, fill=150)
        sh = sh.filter(ImageFilter.GaussianBlur(26 * u))
        base.paste(Image.new('RGBA', self.size, (0, 0, 0, 255)), (0, 0), sh)
        d = ImageDraw.Draw(base)
        # side keys
        kx = self.pad + dw - 2 * u
        d.rounded_rectangle((kx, self.pad + 150 * u, kx + 5 * u, self.pad + 205 * u), 2 * u, fill=(44, 46, 52))
        d.rounded_rectangle((kx, self.pad + 240 * u, kx + 5 * u, self.pad + 330 * u), 2 * u, fill=(44, 46, 52))
        # frame: metal rim, then black glass bezel
        R = r_in + self.bz
        d.rounded_rectangle(self.body, R, fill=(58, 61, 68))
        x0, y0, x1, y1 = self.body
        d.rounded_rectangle((x0 + 2 * u, y0 + 2 * u, x1 - 2 * u, y1 - 2 * u), R - 2 * u, fill=(28, 30, 34))
        d.rounded_rectangle((x0 + 4 * u, y0 + 4 * u, x1 - 4 * u, y1 - 4 * u), R - 4 * u, fill=(6, 6, 8))
        self.base = base
        # screen mask
        self.mask = Image.new('L', (self.sw, self.sh + self.sb), 0)
        ImageDraw.Draw(self.mask).rounded_rectangle((0, 0, self.sw - 1, self.sh + self.sb - 1), r_in, fill=255)
        # status bar in the app's own background colour
        appbg = first.convert('RGB').getpixel((self.sw // 2, 2))
        sbar = Image.new('RGB', (self.sw, self.sb), appbg)
        sd = ImageDraw.Draw(sbar)
        fu = font(FONT_UI, round(12.5 * u))
        sd.text((24 * u, self.sb / 2), '9:41', font=fu, fill=(236, 236, 236), anchor='lm')
        cx, cy = self.sw / 2, self.sb / 2 + 1 * u
        sd.ellipse((cx - 6 * u, cy - 6 * u, cx + 6 * u, cy + 6 * u), fill=(0, 0, 0))
        sd.ellipse((cx - 2.2 * u, cy - 2.2 * u, cx + .2 * u, cy + .2 * u), fill=(24, 30, 44))
        # battery, wifi, signal (right side)
        bx = self.sw - 24 * u
        sd.rounded_rectangle((bx - 22 * u, cy - 5.5 * u, bx - 2 * u, cy + 5.5 * u), 2.5 * u, outline=(236, 236, 236), width=max(1, round(1.2 * u)))
        sd.rectangle((bx - 1.5 * u, cy - 2 * u, bx, cy + 2 * u), fill=(236, 236, 236))
        sd.rounded_rectangle((bx - 20 * u, cy - 3.5 * u, bx - 7 * u, cy + 3.5 * u), 1.2 * u, fill=(236, 236, 236))
        wx = bx - 40 * u
        for i, rr in enumerate((9, 6, 3)):
            sd.arc((wx - rr * u, cy - rr * u + 3 * u, wx + rr * u, cy + rr * u + 3 * u), 225, 315,
                   fill=(236, 236, 236), width=max(1, round(1.6 * u)))
        sd.ellipse((wx - 1.2 * u, cy + 1.8 * u, wx + 1.2 * u, cy + 4.2 * u), fill=(236, 236, 236))
        gx = wx - 30 * u
        for i in range(4):
            hh = (3 + i * 2.2) * u
            sd.rectangle((gx + i * 4 * u, cy + 5 * u - hh, gx + i * 4 * u + 2.4 * u, cy + 5 * u), fill=(236, 236, 236))
        self.sbar = sbar
        self._cache = (None, None)

    def compose(self, idx, frame_path):
        if self._cache[0] == idx:
            return self._cache[1]
        scr = Image.new('RGB', (self.sw, self.sh + self.sb))
        scr.paste(self.sbar, (0, 0))
        scr.paste(Image.open(frame_path).convert('RGB'), (0, self.sb))
        dev = self.base.copy()
        dev.paste(scr, (self.ox, self.oy), self.mask)
        self._cache = (idx, dev)
        return dev

    def screen_pt(self, u, v):
        """Screen fraction (of the captured app area) -> device-image px."""
        return (self.ox + u * self.sw, self.oy + self.sb + v * self.sh)

    @property
    def center(self):
        x0, y0, x1, y1 = self.body
        return ((x0 + x1) / 2, (y0 + y1) / 2)


def ease(t):
    t = min(1.0, max(0.0, t))
    return t * t * (3 - 2 * t)


def build_overlay(cfg):
    ov = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    # scrims so the zoomed device slides under the copy
    top = Image.new('L', (1, H), 0)
    for y in range(H):
        if y < 300:
            a = 255
        elif y < 380:
            a = int(255 * (1 - ease((y - 300) / 80)))
        elif y > 1130:
            a = int(255 * ease((y - 1130) / 70)) if y < 1200 else 255
        else:
            a = 0
        top.putpixel((0, y), a)
    ov.paste(Image.new('RGBA', (W, H), BG + (255,)), (0, 0), top.resize((W, H)))
    d = ImageDraw.Draw(ov)
    # slide frame + corner marks
    d.rectangle((36, 36, W - 37, H - 37), outline=LINE, width=2)
    for cx, cy in ((57, 57), (W - 58, 57), (57, H - 58), (W - 58, H - 58)):
        pts = [(cx + 8 * math.cos(math.pi / 3 * i + math.pi / 6), cy + 8 * math.sin(math.pi / 3 * i + math.pi / 6)) for i in range(6)]
        d.polygon(pts, outline=LINE)
        d.ellipse((cx - 3, cy - 3, cx + 3, cy + 3), outline=LINE)
    def layer(draw):
        im = Image.new('RGBA', (W, H), (0, 0, 0, 0))
        draw(ImageDraw.Draw(im))
        return im
    fh = font(FONT_B, 60)
    kicker = layer(lambda d: tracked(d, (MX, 92), cfg['kicker'], font(FONT_B, 22), AMBER, 4.5))
    l1 = layer(lambda d: d.text((MX, 140), cfg['l1'], font=fh, fill=WHITE))
    l2 = layer(lambda d: d.text((MX, 214), cfg['l2'], font=fh, fill=AMBER))

    def foot(d):
        x = tracked(d, (MX, 1268), 'ZYKL', font(FONT_B, 34), WHITE, 9)
        tracked(d, (x + 22, 1281), '// QUIET TIME. PHYSICAL INTENT.', font(FONT_R, 17), MUTED, 3)
    return dict(base=ov, kicker=kicker, l1=l1, l2=l2, foot=layer(foot), end=end_card())


def end_card():
    im = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    icon = Image.open(ICON).convert('RGBA').resize((236, 236), Image.LANCZOS)
    im.paste(icon, ((W - 236) // 2, 380), icon)

    def centered(y, text, f, fill, track):
        w = sum(d.textlength(c, font=f) + track for c in text) - track
        tracked(d, ((W - w) / 2, y), text, f, fill, track)
    centered(668, 'ZYKL', font(FONT_B, 92), WHITE, 26)
    centered(790, 'POMODORO FOCUS TIMER', font(FONT_B, 24), MUTED, 6)
    centered(860, 'Quiet Time. Physical Intent.', font(FONT_B, 34), AMBER, 0)
    centered(1010, 'zykl.app', font(FONT_R, 28), WHITE, 3)
    return im


def fade(layer, a, dy=0):
    """Layer with its alpha scaled by a (0..1), shifted dy px."""
    if a >= 1 and dy == 0:
        return layer
    out = Image.new('RGBA', layer.size, (0, 0, 0, 0))
    if a <= 0:
        return out
    l = layer.copy()
    l.putalpha(l.getchannel('A').point(lambda p: int(p * a)))
    out.paste(l, (0, int(round(dy))))
    return out


def draw_chapter(img, chapter, alpha, rise):
    if not chapter or alpha <= 0:
        return
    num, label, value = (chapter.split('|') + ['', ''])[:3]
    layer = Image.new('RGBA', (W, 90), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    fk, fv = font(FONT_B, 24), font(FONT_B, 32)
    x = tracked(d, (0, 4), f'{num} // {label.upper()}', fk, AMBER, 3)
    d.text((0, 40), value, font=fv, fill=WHITE)
    a = layer.getchannel('A').point(lambda p: int(p * alpha))
    layer.putalpha(a)
    img.paste(layer, (MX, int(1152 + rise)), layer)


def load_meta(src):
    meta = json.load(open(os.path.join(src, 'touches.json')))
    return meta['touches']


def smoother(t):
    t = min(1.0, max(0.0, t))
    return t * t * t * (t * (6 * t - 15) + 10)


def shot_cam(dev, region):
    """(cx, cy, zoom) that frames a screen region between the scrims."""
    v0, v1 = region
    body_h = dev.body[3] - dev.body[1]
    screen_px = dev.sh * DEVICE_H / body_h          # app height on canvas at zoom 1
    z = min(ZMAX, BAND / ((v1 - v0) * screen_px))
    cx, cy = dev.screen_pt(0.5, (v0 + v1) / 2)
    return (cx, cy, max(1.0, z))


def camera_track(dev, shots, total_out):
    """Per output frame (cx, cy, zoom): whole phone, plus a few held shots."""
    full = (*dev.center, 1.0)
    switches = []                                   # (time, target)
    for i, (t0, t1, region) in enumerate(shots):
        switches.append((max(0.0, t0 - LEAD), shot_cam(dev, region)))
        if t1 is None:
            break
        nxt = shots[i + 1][0] - LEAD if i + 1 < len(shots) else None
        if nxt is None or nxt - t1 >= MERGE:
            switches.append((t1, full))
    out, cur, frm, to, since = [], full, full, full, 0.0
    si = 0
    for k in range(total_out):
        t = k / FPS
        while si < len(switches) and switches[si][0] <= t:
            frm, to, since = cur, switches[si][1], switches[si][0]
            si += 1
        q = smoother((t - since) / MOVE)
        z = frm[2] * (to[2] / frm[2]) ** q          # zoom eases geometrically
        cur = (frm[0] + (to[0] - frm[0]) * q, frm[1] + (to[1] - frm[1]) * q, z)
        out.append(cur)
    return out


def print_cues(touches):
    prev_ch, prev_cam = 0, 0
    for x in touches:
        t = (x['f'] - 1) / SRC_FPS
        if x.get('ch') != prev_ch:
            print(f'{t:5.1f}  == {x.get("ch")}')
            prev_ch = x.get('ch')
        if x.get('cam') != prev_cam:
            c = x.get('cam')
            print(f'{t:5.1f}     tap/cue ' + (f'u={c[0]:.2f} v={c[1]:.2f}' if c else 'none'))
            prev_cam = c


def render_frame(dev, ov, bgimg, cam, idx, frame_path, chapter_state, fx=None):
    """fx: opening/closing parameters (alphas and device offset); None = normal."""
    fx = fx or {}
    cx, cy, z = cam
    s = DEVICE_H / (dev.body[3] - dev.body[1]) * z * fx.get('dscale', 1.0)
    dev_a, dev_dy = fx.get('dev', 1.0), fx.get('dev_dy', 0.0)
    img = bgimg.copy()
    devimg = dev.compose(idx, frame_path)
    # canvas rect covered by the device image, clipped to the canvas
    dw, dh = devimg.size
    X0 = ANCHOR[0] + (0 - cx) * s
    Y0 = ANCHOR[1] + (0 - cy) * s + dev_dy
    X1, Y1 = X0 + dw * s, Y0 + dh * s
    cx0, cy0 = max(0, math.ceil(X0)), max(0, math.ceil(Y0))
    cx1, cy1 = min(W, math.floor(X1)), min(H, math.floor(Y1))
    if cx1 > cx0 and cy1 > cy0:
        box = (max(0.0, (cx0 - X0) / s), max(0.0, (cy0 - Y0) / s),
               min(dw, (cx1 - X0) / s), min(dh, (cy1 - Y0) / s))
        part = devimg.resize((cx1 - cx0, cy1 - cy0), Image.BICUBIC, box=box)
        if dev_a < 1:
            part.putalpha(part.getchannel('A').point(lambda p: int(p * dev_a)))
        if dev_a > 0:
            img.paste(part, (cx0, cy0), part)
    img = Image.alpha_composite(img, ov['base'])
    for key, dk in (('kicker', 0), ('l1', 18), ('l2', 18)):
        a = fx.get(key, 1.0)
        img = Image.alpha_composite(img, fade(ov[key], a, dk * (1 - a) if fx.get('rise') else 0))
    img = Image.alpha_composite(img, fade(ov['foot'], fx.get('foot', 1.0)))
    ch, a, rise = chapter_state
    draw_chapter(img, ch, a * fx.get('chap', 1.0), rise)
    if fx.get('end', 0) > 0:
        img = Image.alpha_composite(img, fade(ov['end'], fx['end'], 14 * (1 - fx['end'])))
    return img.convert('RGB')


def seg(t, a, b):
    return ease((t - a) / (b - a))


def timeline(k, total, cams, chaps, dev):
    """Output frame k -> (cam, app frame index, chapter state, fx)."""
    ni, no = int(INTRO * FPS), int(OUTRO * FPS)
    if k < ni:                                   # opening
        t = k / FPS
        e = 1 - (1 - min(1, max(0, (t - .3) / .85))) ** 3
        fx = dict(rise=True, kicker=seg(t, 0, .35), l1=seg(t, .1, .55), l2=seg(t, .25, .7),
                  dev=seg(t, .3, .8), dev_dy=140 * (1 - e), dscale=.94 + .06 * e, chap=0.0)
        return cams[0], 0, (None, 0, 0), fx
    k -= ni
    if k < total:
        return cams[k], k * SRC_FPS // FPS, chaps[k], None
    t = (k - total) / FPS                        # closing
    cx, cy, z = cams[-1]
    q = seg(t, 0, .9)
    c0x, c0y = dev.center
    cam = (cx + (c0x - cx) * q, cy + (c0y - cy) * q, z + (1 - z) * q)
    out = seg(t, .55, 1.15)
    fx = dict(dev=1 - out, dev_dy=-40 * out, dscale=1 - .1 * out, chap=1 - seg(t, 0, .35),
              kicker=1 - out, l1=1 - out, l2=1 - out, foot=1 - out, end=seg(t, .95, 1.6))
    return cam, (total - 1) * SRC_FPS // FPS, chaps[-1], fx


def chapter_states(touches, total_out):
    """Fade/rise the caption on each chapter change."""
    out, cur, prev, since = [], None, None, 99.0
    for k in range(total_out):
        t = touches[min(len(touches) - 1, k * SRC_FPS // FPS)]
        ch = t.get('ch')
        if ch != cur:
            prev, cur, since = cur, ch, 0.0
        since += 1 / FPS
        fade = 0.28
        if since < fade and prev:      # old caption out
            out.append((prev, 1 - ease(since / fade), -8 * ease(since / fade)))
        elif since < 2 * fade:
            q = ease((since - fade) / fade) if prev else ease(since / (2 * fade))
            out.append((cur, q, 12 * (1 - q)))
        else:
            out.append((cur, 1.0, 0.0))
    return out


def background():
    bg = Image.new('RGBA', (W, H), BG + (255,))
    glow = Image.new('L', (W, H), 0)
    ImageDraw.Draw(glow).ellipse((W / 2 - 520, 380, W / 2 + 520, 1100), fill=26)
    glow = glow.filter(ImageFilter.GaussianBlur(140))
    bg.paste(Image.new('RGBA', (W, H), (52, 48, 40, 255)), (0, 0), glow)
    noise = Image.effect_noise((W, H), 9).point(lambda p: max(0, min(255, p - 128 + 10)))
    bg.paste(Image.new('RGBA', (W, H), (255, 255, 255, 255)), (0, 0), noise.point(lambda p: p // 8))
    return bg


def mix_audio(touches, dur, wav, shift=0.0, sting=None):
    names = track_names()
    cues, amb = [], []
    for t in touches:
        for e in t.get('sfx', []):
            at = (t['f'] - 1) / SRC_FPS + shift
            if e.startswith('ambient:'):
                amb.append((at, e.split(':')[1]))
            elif e in FOLEY:
                cues.append((at, *FOLEY[e]))
    if sting is not None:
        cues.append((sting, 'alarm_braun_bell.wav', 0.42))
    inputs, parts, n = [], [], 0
    for at, f, g in cues:
        inputs += ['-i', os.path.join(AUDIO, f)]
        parts.append(f'[{n}:a]aformat=sample_rates=48000:channel_layouts=stereo,volume={g},adelay={int(at*1000)}:all=1[c{n}]')
        n += 1
    for i, (at, idx) in enumerate(amb):
        if idx == 'stop':
            continue
        end = next((a for a, _ in amb[i + 1:]), dur)
        length = end - at
        inputs += ['-stream_loop', '-1', '-i', os.path.join(AUDIO, names[int(idx)])]
        fo = 0.25 if end < dur else 1.0
        parts.append(f'[{n}:a]aformat=sample_rates=48000:channel_layouts=stereo,atrim=0:{length + 0.25:.3f},'
                     f'afade=t=in:d=0.35,afade=t=out:st={max(0, length + 0.25 - fo):.3f}:d={fo},volume=0.62,'
                     f'adelay={int(at*1000)}:all=1[c{n}]')
        n += 1
    graph = ';'.join(parts) + ';' + ''.join(f'[c{i}]' for i in range(n)) + \
        f'amix=inputs={n}:normalize=0:duration=longest,apad,atrim=0:{dur:.3f},' \
        f'afade=t=out:st={dur - 1.6:.3f}:d=1.6,loudnorm=I=-16:TP=-1.5:LRA=11[out]'
    subprocess.run(['ffmpeg', '-v', 'error', '-y', *inputs, '-filter_complex', graph, '-map', '[out]',
                    '-ar', '48000', wav], check=True)


def main():
    args = sys.argv[1:]
    clip = args[0]
    cfg = CLIPS[clip]
    src = os.path.expanduser(f'~/.cache/zykl-film/content/{clip}')
    out = os.path.join(OUTDIR, f'ZYKL_Demo_{clip.capitalize()}_4x5.mp4')
    stills = []
    i = 1
    while i < len(args):
        if args[i] == '--src':
            src = os.path.expanduser(args[i + 1]); i += 2
        elif args[i] == '--out':
            out = args[i + 1]; i += 2
        elif args[i] == '--cues':
            print_cues(load_meta(src)); return
        elif args[i] == '--still':
            i += 1
            while i < len(args) and not args[i].startswith('--'):
                stills.append(float(args[i])); i += 1
        else:
            sys.exit(f'unknown arg {args[i]}')
    touches = load_meta(src)
    first = Image.open(os.path.join(src, '0001.png'))
    pr = first.size[0] / 384
    dev = Device(first, pr)
    overlay = build_overlay(cfg)
    bg = background()
    total = len(touches) * FPS // SRC_FPS
    cams = camera_track(dev, cfg['shots'], total)
    chaps = chapter_states(touches, total)
    fp = lambda i: os.path.join(src, f'{min(len(touches), i + 1):04d}.png')
    full = total + int(INTRO * FPS) + int(OUTRO * FPS)

    def frame(k):
        cam, idx, chap, fx = timeline(k, total, cams, chaps, dev)
        return render_frame(dev, overlay, bg, cam, idx, fp(idx), chap, fx)
    if stills:
        os.makedirs(os.path.dirname(out) or '.', exist_ok=True)
        for sec in stills:
            p = f'{os.path.splitext(out)[0]}_still_{sec:05.2f}.png'
            frame(min(full - 1, int(sec * FPS))).save(p)
            print(p)
        return
    os.makedirs(os.path.dirname(out), exist_ok=True)
    dur = full / FPS
    wav = os.path.splitext(out)[0] + '.wav'
    mix_audio(touches, dur, wav, shift=INTRO, sting=INTRO + total / FPS + 0.95)
    tmp = os.path.splitext(out)[0] + '.video.mp4'
    ff = subprocess.Popen(['ffmpeg', '-v', 'error', '-y', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-s', f'{W}x{H}',
                           '-r', str(FPS), '-i', '-', '-c:v', 'libx264', '-preset', 'slow', '-crf', '17',
                           '-pix_fmt', 'yuv420p', '-movflags', '+faststart', tmp], stdin=subprocess.PIPE)
    for k in range(full):
        ff.stdin.write(frame(k).tobytes())
        if k % 120 == 0:
            print(f'{k}/{full}', flush=True)
    ff.stdin.close()
    ff.wait()
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', tmp, '-i', wav, '-c:v', 'copy', '-c:a', 'aac', '-b:a', '192k',
                    '-shortest', '-movflags', '+faststart', out], check=True)
    os.remove(tmp)
    os.remove(wav)
    print('DONE', out, f'{dur:.2f}s')


if __name__ == '__main__':
    main()
