"""ElevenLabs score + cinematic SFX for the ZYKL v4 film.

The API key is read from ../../../11labs.md (git-ignored) and never printed.
usage:
  python3 generate_audio.py sfx            # all sound effects missing in ./sfx
  python3 generate_audio.py music [N]      # N score variants (default 2) from the composition plan
Costs (Starter, 2026): music ~900 credits/min, SFX ~200 credits each.
"""
import json, os, sys, urllib.request, urllib.error

HERE = os.path.dirname(os.path.abspath(__file__))
KEY = open(os.path.join(HERE, '..', '..', '..', '11labs.md')).read().strip()
API = 'https://api.elevenlabs.io/v1'

def post(path, body, out):
    req = urllib.request.Request(f'{API}{path}', data=json.dumps(body).encode(),
                                 headers={'xi-api-key': KEY, 'Content-Type': 'application/json'})
    try:
        with urllib.request.urlopen(req, timeout=600) as r:
            data = r.read()
    except urllib.error.HTTPError as e:
        print('  HTTP', e.code, e.read()[:400].decode(errors='replace'))
        return False
    open(out, 'wb').write(data)
    print(f'  -> {os.path.relpath(out, HERE)} ({len(data) // 1024} KB)')
    return True

# ---------------------------------------------------------------- score
# Sections mirror STORYBOARD.md (82 s). Instrumental, modern-classical,
# felt piano + warm analog pads; the app's own world, made cinematic.
GLOBAL_POS = ['cinematic modern classical', 'felt piano', 'warm analog synth pads', 'soft tape saturation',
              'intimate', 'premium product film', 'instrumental']
GLOBAL_NEG = ['vocals', 'lyrics', 'choir', 'EDM drop', 'trap', 'aggressive distorted guitar', 'cheesy corporate ukulele']
SECTIONS = [
    ('Noise', 5000, ['tense', 'glitchy digital stutters', 'rising dissonant pulse', 'ends in an abrupt cut to silence'], ['melodic']),
    ('Question', 4000, ['near silence', 'one sustained felt piano note', 'distant clock tick', 'breath'], ['drums', 'bass']),
    ('Reveal', 5000, ['warm swelling pad', 'soft low impact on the downbeat', 'hopeful major chord bloom'], ['drums']),
    ('Boot', 5000, ['delicate mechanical ticking rhythm', 'music-box like piano motif', 'anticipation'], ['heavy drums']),
    ('Rhythm', 6000, ['felt piano ostinato enters', 'soft brushed kit', 'upright bass', '84 bpm', 'calm but propulsive'], ['busy']),
    ('Crown', 12000, ['motif develops', 'precise plucked strings like gears', 'gentle build', 'playful focus'], ['loud']),
    ('Lockdown', 9000, ['drums drop out', 'held low pad', 'slow tension swell', 'release on the last beat'], ['percussive']),
    ('Craft', 8000, ['groove returns', 'tactile percussion', 'warm piano chords', 'confident'], ['harsh']),
    ('Vinyl', 7000, ['lo-fi warmth', 'vinyl texture', 'piano melody blooms', 'nostalgic'], ['modern synth lead']),
    ('Editions', 5000, ['shimmering lift', 'strings join', 'elegant'], ['heavy']),
    ('Insight', 7000, ['resolving harmony', 'warm and assured', 'piano and strings'], ['tense']),
    ('Manifesto', 4000, ['four clear accented beats', 'quiet confidence'], ['busy']),
    ('Outro', 5000, ['final warm chord', 'long ring-out', 'gentle ending'], ['abrupt ending']),
]
assert sum(s[1] for s in SECTIONS) == 82000

def music(n):
    plan = {
        'positive_global_styles': GLOBAL_POS,
        'negative_global_styles': GLOBAL_NEG,
        'sections': [{'section_name': name, 'duration_ms': ms, 'positive_local_styles': pos,
                      'negative_local_styles': neg, 'lines': []} for name, ms, pos, neg in SECTIONS],
    }
    os.makedirs(os.path.join(HERE, 'music'), exist_ok=True)
    for i in range(1, n + 1):
        out = os.path.join(HERE, 'music', f'score_v{i}.mp3')
        if os.path.exists(out):
            print('skip', out); continue
        print(f'score variant {i}')
        post('/music?output_format=mp3_44100_192', {
            'composition_plan': plan, 'model_id': 'music_v1', 'respect_sections_durations': True,
            'seed': 1000 + i,
        }, out)

# ---------------------------------------------------------------- SFX
# UI sounds come from the app's own foley (assets/audio/foley_*.wav); these are the
# cinematic layers around them.
SFX = {
    'whoosh_soft_1': ('soft airy cinematic whoosh, smooth transition, no harsh noise', 1.2),
    'whoosh_soft_2': ('gentle velvet swish transition, slow air movement', 1.4),
    'whoosh_soft_3': ('subtle reverse air swell into a soft cut', 1.0),
    'impact_low': ('deep soft cinematic sub impact with warm tail, premium', 2.5),
    'riser_tension_5s': ('slow building tension riser, filtered strings and air, five seconds, ends abruptly', 5.0),
    'riser_short': ('short airy riser into a reveal', 1.5),
    'implode': ('digital notifications imploding into a single point, suction, then silence', 1.5),
    'notif_swarm': ('dense swarm of overlapping phone notification pings and buzzes, chaotic', 4.0),
    'crown_detent': ('small precise metal watch crown pulled out, crisp mechanical detent click', 0.6),
    'ratchet_wind': ('fine mechanical watch winding ratchet, rapid tiny clicks, high quality foley', 1.6),
    'latch_heavy': ('heavy solid mechanical latch locking, satisfying metal clunk', 0.8),
    'release_spring': ('mechanical spring release with soft metallic ring', 1.0),
    'room_tone': ('quiet warm studio room tone, very soft air, no hum', 10.0),
    'chime_outro': ('single warm brass desk bell chime with long natural decay', 3.5),
}

def sfx():
    d = os.path.join(HERE, 'sfx'); os.makedirs(d, exist_ok=True)
    for name, (text, dur) in SFX.items():
        out = os.path.join(d, f'{name}.mp3')
        if os.path.exists(out):
            print('skip', name); continue
        print('sfx', name)
        post('/sound-generation?output_format=mp3_44100_192',
             {'text': text, 'duration_seconds': dur, 'prompt_influence': 0.55}, out)

if __name__ == '__main__':
    what = sys.argv[1] if len(sys.argv) > 1 else ''
    if what == 'sfx': sfx()
    elif what == 'music': music(int(sys.argv[2]) if len(sys.argv) > 2 else 2)
    else: print(__doc__)
