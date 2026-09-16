#!/usr/bin/env python3
"""
Procedural Audio Generator for Takt Desk 12 Curated Focus Soundscapes
Generates 16-second seamless looping 22050 Hz 16-bit mono PCM WAV files.

Track List:
TK-01: vinyl_lofi_rain.wav        - Lo-fi Rain (Rhodes chords & rain)
TK-02: vinyl_brown_noise.wav      - Deep Brown Noise (1/f² warmth)
TK-03: vinyl_library.wav          - Library Atmosphere (Acoustic room tone)
TK-04: vinyl_kyoto_bamboo.wav     - Kyoto Bamboo Stream (Bamboo trickle & moss stone)
TK-05: vinyl_campfire.wav         - Campfire Embers (Warm hearth embers, no loud bursts)
TK-06: vinyl_nordic_pines.wav     - Nordic Pine Whispers (High-altitude filtered pine wind)
TK-07: vinyl_alpine_brook.wav     - Alpine Mountain Brook (Crystalline steady brook murmur)
TK-08: vinyl_warm_tape.wav        - Warm Tape & Felt Piano (Warm analog saturation & muted chords)
TK-09: vinyl_zen_bowl.wav         - Zen Temple Bowl (Singing bowl fundamental & decaying harmonics)
TK-10: vinyl_morning_meadow.wav   - Misty Morning Meadow (Morning air dew blanket)
TK-11: vinyl_pure_white_noise.wav - Pure Focus White Noise (Flat linear reading/coding noise)
TK-12: vinyl_timber_chamber.wav   - Timber Acoustic Chamber (Dry timber room reflection)
"""

import os
import math
import random
import struct
import wave

SAMPLE_RATE = 22050
LOOP_DURATION = 16.0
FADE_DURATION = 2.0

NUM_SAMPLES = int(SAMPLE_RATE * LOOP_DURATION)
FADE_SAMPLES = int(SAMPLE_RATE * FADE_DURATION)
TOTAL_SAMPLES = NUM_SAMPLES + FADE_SAMPLES


def lowpass_filter(samples, sample_rate, cutoff):
    rc = 1.0 / (2.0 * math.pi * cutoff)
    dt = 1.0 / sample_rate
    alpha = dt / (rc + dt)
    out = [0.0] * len(samples)
    curr = 0.0
    for i, x in enumerate(samples):
        curr += alpha * (x - curr)
        out[i] = curr
    return out


def highpass_filter(samples, sample_rate, cutoff):
    rc = 1.0 / (2.0 * math.pi * cutoff)
    dt = 1.0 / sample_rate
    alpha = rc / (rc + dt)
    out = [0.0] * len(samples)
    curr = samples[0] if samples else 0.0
    prev_in = curr
    for i, x in enumerate(samples):
        curr = alpha * (curr + x - prev_in)
        prev_in = x
        out[i] = curr
    return out


def bandpass_filter(samples, sample_rate, low_cut, high_cut):
    hp = highpass_filter(samples, sample_rate, low_cut)
    return lowpass_filter(hp, sample_rate, high_cut)


def crossfade_loop(samples, num_samples, fade_samples):
    out = list(samples[:num_samples])
    for i in range(fade_samples):
        t = i / fade_samples
        gain_head = math.sin(t * math.pi / 2.0)
        gain_tail = math.cos(t * math.pi / 2.0)
        tail_val = samples[num_samples + i] if (num_samples + i) < len(samples) else 0.0
        out[i] = out[i] * gain_head + tail_val * gain_tail
    return out


def save_wav(filepath, samples, target_peak=0.75):
    max_val = max(abs(s) for s in samples) if samples else 1.0
    if max_val < 1e-6:
        max_val = 1.0
    scale = target_peak / max_val

    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with wave.open(filepath, 'wb') as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        raw_bytes = bytearray()
        for s in samples:
            val = max(-1.0, min(1.0, s * scale))
            int_sample = int(round(val * 32767.0))
            int_sample = max(-32768, min(32767, int_sample))
            raw_bytes.extend(struct.pack('<h', int_sample))
        wf.writeframes(raw_bytes)
    print(f"Generated {os.path.basename(filepath)} ({len(samples)} samples, {len(samples)/SAMPLE_RATE:.1f}s)")


# ----------------------------------------------------------------------
# Track 1: TK-01 Lo-fi Rain
# ----------------------------------------------------------------------
def generate_lofi_rain():
    random.seed(1001)
    samples = [0.0] * TOTAL_SAMPLES

    # 1. Rain bed
    white_noise = [random.gauss(0, 0.4) for _ in range(TOTAL_SAMPLES)]
    rain_bed = bandpass_filter(white_noise, SAMPLE_RATE, 250.0, 4200.0)

    # 2. Droplet micro-spatters
    spatters = [0.0] * TOTAL_SAMPLES
    prob = 90.0 / SAMPLE_RATE
    for idx in range(TOTAL_SAMPLES):
        if random.random() < prob:
            freq = random.uniform(900.0, 2200.0)
            amp = random.uniform(0.1, 0.35)
            spat_len = min(TOTAL_SAMPLES - idx, int(0.03 * SAMPLE_RATE))
            for k in range(spat_len):
                t = k / SAMPLE_RATE
                spatters[idx + k] += amp * math.exp(-120.0 * t) * math.sin(2.0 * math.pi * freq * t)

    # 3. Electric Piano 4-chord progression (4.0s per chord)
    # Fmaj7 -> Em7 -> Dm9 -> Cmaj7
    chords = [
        [174.61, 220.00, 261.63, 329.63],          # Fmaj7
        [164.81, 196.00, 246.94, 293.66],          # Em7
        [146.83, 174.61, 220.00, 261.63, 329.63],  # Dm9
        [130.81, 196.00, 246.94, 329.63],          # Cmaj7
    ]
    chord_duration = 4.0
    piano = [0.0] * TOTAL_SAMPLES

    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE
        chord_idx = int(t / chord_duration) % len(chords)
        t_chord = t % chord_duration
        notes = chords[chord_idx]

        # Piano note envelope: gentle attack, long exponential decay
        env = math.exp(-0.75 * t_chord) * (1.0 - math.exp(-30.0 * t_chord))
        # Tremolo
        trem = 0.9 + 0.1 * math.sin(2.0 * math.pi * 4.5 * t)

        chord_val = 0.0
        for f in notes:
            # Fundamental + 2nd harmonic + 3rd harmonic
            tone = (
                math.sin(2.0 * math.pi * f * t) * 0.65 +
                math.sin(2.0 * math.pi * (2.0 * f) * t) * 0.25 +
                math.sin(2.0 * math.pi * (3.0 * f) * t) * 0.10
            )
            chord_val += tone

        chord_val /= len(notes)
        piano[idx] = chord_val * env * trem

    piano_filtered = lowpass_filter(piano, SAMPLE_RATE, 1600.0)

    # Combine
    for idx in range(TOTAL_SAMPLES):
        samples[idx] = rain_bed[idx] * 0.50 + spatters[idx] * 0.35 + piano_filtered[idx] * 0.55

    return crossfade_loop(samples, NUM_SAMPLES, FADE_SAMPLES)


# ----------------------------------------------------------------------
# Track 2: TK-02 Deep Brown Noise
# ----------------------------------------------------------------------
def generate_brown_noise():
    random.seed(1002)
    samples = [0.0] * TOTAL_SAMPLES

    # Leaky integrator
    val = 0.0
    for idx in range(TOTAL_SAMPLES):
        white = random.gauss(0, 0.25)
        val = 0.997 * val + 0.05 * white
        samples[idx] = val

    filtered = lowpass_filter(samples, SAMPLE_RATE, 320.0)
    filtered = lowpass_filter(filtered, SAMPLE_RATE, 360.0)
    filtered = highpass_filter(filtered, SAMPLE_RATE, 28.0)

    # Gentle breathing envelope
    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE
        breath = 0.94 + 0.06 * math.sin(2.0 * math.pi * (1.0 / 16.0) * t)
        filtered[idx] *= breath

    return crossfade_loop(filtered, NUM_SAMPLES, FADE_SAMPLES)


# ----------------------------------------------------------------------
# Track 3: TK-03 Library Atmosphere
# ----------------------------------------------------------------------
def generate_library():
    random.seed(1003)
    samples = [0.0] * TOTAL_SAMPLES

    # 1. Quiet air tone (subtle wooden hall resonance)
    white_noise = [random.gauss(0, 0.3) for _ in range(TOTAL_SAMPLES)]
    room_tone = bandpass_filter(white_noise, SAMPLE_RATE, 90.0, 480.0)

    # Subtle acoustic modes (hall room resonances)
    modes = [140.0, 275.0, 410.0]
    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE
        mode_val = sum(math.sin(2.0 * math.pi * m * t) * 0.025 for m in modes)
        room_tone[idx] += mode_val

    # 2. Rare soft page turns at t=4.0s, 9.0s, 14.0s
    page_times = [4.0, 9.0, 14.0]
    page_buffer = [0.0] * TOTAL_SAMPLES
    for pt in page_times:
        start_idx = int(pt * SAMPLE_RATE)
        dur = int(0.28 * SAMPLE_RATE)
        for k in range(dur):
            if start_idx + k >= TOTAL_SAMPLES:
                break
            tk = k / SAMPLE_RATE
            p_env = math.sin(math.pi * (k / dur)) ** 2
            p_noise = random.gauss(0, 0.15) * p_env
            page_buffer[start_idx + k] += p_noise

    page_filtered = bandpass_filter(page_buffer, SAMPLE_RATE, 1200.0, 3200.0)

    # Combine
    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE
        slow_air = 0.9 + 0.1 * math.sin(2.0 * math.pi * 0.125 * t)
        samples[idx] = room_tone[idx] * 0.70 * slow_air + page_filtered[idx] * 0.30

    return crossfade_loop(samples, NUM_SAMPLES, FADE_SAMPLES)


# ----------------------------------------------------------------------
# Track 4: TK-04 Kyoto Bamboo Stream
# ----------------------------------------------------------------------
def generate_kyoto_bamboo():
    random.seed(1004)
    samples = [0.0] * TOTAL_SAMPLES

    # 1. Gentle stream flow
    white_noise = [random.gauss(0, 0.35) for _ in range(TOTAL_SAMPLES)]
    stream = bandpass_filter(white_noise, SAMPLE_RATE, 350.0, 2400.0)

    # 2. Water trickle droplet pings
    trickle = [0.0] * TOTAL_SAMPLES
    prob = 35.0 / SAMPLE_RATE
    for idx in range(TOTAL_SAMPLES):
        if random.random() < prob:
            f_base = random.uniform(650.0, 1500.0)
            amp = random.uniform(0.12, 0.30)
            drop_len = min(TOTAL_SAMPLES - idx, int(0.04 * SAMPLE_RATE))
            for k in range(drop_len):
                t = k / SAMPLE_RATE
                f_inst = f_base * (1.0 + 0.25 * (1.0 - math.exp(-60.0 * t)))
                trickle[idx + k] += amp * math.exp(-85.0 * t) * math.sin(2.0 * math.pi * f_inst * t)

    # 3. Soft hollow bamboo resonance at t=3.0s, 8.5s, 14.0s
    bamboo = [0.0] * TOTAL_SAMPLES
    bamboo_times = [3.0, 8.5, 14.0]
    for bt in bamboo_times:
        start_idx = int(bt * SAMPLE_RATE)
        dur = min(TOTAL_SAMPLES - start_idx, int(0.6 * SAMPLE_RATE))
        for k in range(dur):
            t = k / SAMPLE_RATE
            b_env = math.exp(-14.0 * t) * (1.0 - math.exp(-150.0 * t))
            strike = (
                math.sin(2.0 * math.pi * 432.0 * t) * 0.60 +
                math.sin(2.0 * math.pi * 864.0 * t) * 0.30 +
                math.sin(2.0 * math.pi * 1296.0 * t) * 0.10
            )
            bamboo[start_idx + k] += strike * b_env * 0.28

    for idx in range(TOTAL_SAMPLES):
        samples[idx] = stream[idx] * 0.45 + trickle[idx] * 0.38 + bamboo[idx]

    return crossfade_loop(samples, NUM_SAMPLES, FADE_SAMPLES)


# ----------------------------------------------------------------------
# Track 5: TK-05 Campfire Embers
# ----------------------------------------------------------------------
def generate_campfire():
    random.seed(1005)
    samples = [0.0] * TOTAL_SAMPLES

    # 1. Warm low rumble / hearth glow
    white_noise = [random.gauss(0, 0.4) for _ in range(TOTAL_SAMPLES)]
    rumble = lowpass_filter(white_noise, SAMPLE_RATE, 170.0)
    rumble = lowpass_filter(rumble, SAMPLE_RATE, 210.0)

    # 2. Gentle embers crackle (clamped, no harsh pops)
    snaps = [0.0] * TOTAL_SAMPLES
    prob = 22.0 / SAMPLE_RATE
    for idx in range(TOTAL_SAMPLES):
        if random.random() < prob:
            freq = random.uniform(950.0, 2400.0)
            amp = random.uniform(0.15, 0.45)
            snap_len = min(TOTAL_SAMPLES - idx, int(0.02 * SAMPLE_RATE))
            for k in range(snap_len):
                t = k / SAMPLE_RATE
                snaps[idx + k] += amp * math.exp(-180.0 * t) * math.sin(2.0 * math.pi * freq * t)

    # 3. Soft high sizzle
    sizzle_noise = [random.gauss(0, 0.18) for _ in range(TOTAL_SAMPLES)]
    sizzle = bandpass_filter(sizzle_noise, SAMPLE_RATE, 2200.0, 4500.0)

    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE
        flame_breath = 0.88 + 0.12 * math.sin(2.0 * math.pi * 0.3 * t)
        samples[idx] = rumble[idx] * 0.75 * flame_breath + snaps[idx] * 0.45 + sizzle[idx] * 0.15

    return crossfade_loop(samples, NUM_SAMPLES, FADE_SAMPLES)


# ----------------------------------------------------------------------
# Track 6: TK-06 Nordic Pine Whispers
# ----------------------------------------------------------------------
def generate_nordic_pines():
    random.seed(1006)
    samples = [0.0] * TOTAL_SAMPLES

    white_noise = [random.gauss(0, 0.45) for _ in range(TOTAL_SAMPLES)]
    wind_low = bandpass_filter(white_noise, SAMPLE_RATE, 160.0, 520.0)
    wind_needles = bandpass_filter(white_noise, SAMPLE_RATE, 950.0, 2100.0)
    wind_high = bandpass_filter(white_noise, SAMPLE_RATE, 2400.0, 3800.0)

    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE
        # Harmonic wind swell synced to 16.0s cycle
        gust1 = 0.60 + 0.40 * math.sin(2.0 * math.pi * (1.0 / 16.0) * t)
        gust2 = 0.55 + 0.45 * math.sin(2.0 * math.pi * (2.0 / 16.0) * t + 0.8)
        sheen = 0.70 + 0.30 * math.sin(2.0 * math.pi * (1.0 / 8.0) * t + 1.5)

        samples[idx] = (
            wind_low[idx] * 0.55 * gust1 +
            wind_needles[idx] * 0.35 * gust2 +
            wind_high[idx] * 0.12 * sheen
        )

    return crossfade_loop(samples, NUM_SAMPLES, FADE_SAMPLES)


# ----------------------------------------------------------------------
# Track 7: TK-07 Alpine Mountain Brook
# ----------------------------------------------------------------------
def generate_alpine_brook():
    random.seed(1007)
    samples = [0.0] * TOTAL_SAMPLES

    # Steady crystalline water flow
    white_noise = [random.gauss(0, 0.4) for _ in range(TOTAL_SAMPLES)]
    stream_mid = bandpass_filter(white_noise, SAMPLE_RATE, 280.0, 2600.0)
    stream_high = bandpass_filter(white_noise, SAMPLE_RATE, 2600.0, 4800.0)
    stream_sub = lowpass_filter(white_noise, SAMPLE_RATE, 180.0)

    # Bubbling liquid murmur
    bubbles = [0.0] * TOTAL_SAMPLES
    prob = 50.0 / SAMPLE_RATE
    for idx in range(TOTAL_SAMPLES):
        if random.random() < prob:
            freq = random.uniform(750.0, 2100.0)
            amp = random.uniform(0.1, 0.25)
            bub_len = min(TOTAL_SAMPLES - idx, int(0.025 * SAMPLE_RATE))
            for k in range(bub_len):
                t = k / SAMPLE_RATE
                bubbles[idx + k] += amp * math.exp(-90.0 * t) * math.sin(2.0 * math.pi * freq * t)

    for idx in range(TOTAL_SAMPLES):
        samples[idx] = (
            stream_mid[idx] * 0.50 +
            stream_high[idx] * 0.22 +
            stream_sub[idx] * 0.30 +
            bubbles[idx] * 0.30
        )

    return crossfade_loop(samples, NUM_SAMPLES, FADE_SAMPLES)


# ----------------------------------------------------------------------
# Track 8: TK-08 Warm Tape & Felt Piano
# ----------------------------------------------------------------------
def generate_warm_tape():
    random.seed(1008)
    samples = [0.0] * TOTAL_SAMPLES

    # Slow muted felt piano progression (4.0s per chord)
    # Dm7 -> G7sus -> Cmaj7 -> Am7
    chords = [
        [146.83, 174.61, 220.00, 261.63],          # Dm7
        [98.00, 174.61, 220.00, 261.63, 293.66],   # G7sus
        [130.81, 164.81, 196.00, 246.94],          # Cmaj7
        [110.00, 164.81, 196.00, 261.63],          # Am7
    ]
    chord_duration = 4.0
    piano = [0.0] * TOTAL_SAMPLES

    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE
        chord_idx = int(t / chord_duration) % len(chords)
        t_chord = t % chord_duration
        notes = chords[chord_idx]

        env = math.exp(-0.65 * t_chord) * (1.0 - math.exp(-25.0 * t_chord))
        # Wow / flutter
        flutter = 0.002 * math.sin(2.0 * math.pi * 0.5 * t)

        chord_val = 0.0
        for f in notes:
            f_mod = f * (1.0 + flutter)
            tone = (
                math.sin(2.0 * math.pi * f_mod * t) * 0.70 +
                math.sin(2.0 * math.pi * (2.0 * f_mod) * t) * 0.22 +
                math.sin(2.0 * math.pi * (3.0 * f_mod) * t) * 0.08
            )
            chord_val += tone

        chord_val /= len(notes)
        piano[idx] = chord_val * env

    # Muted felt piano roll-off
    piano_muted = lowpass_filter(piano, SAMPLE_RATE, 1100.0)

    # Analog tape saturation + hiss
    hiss = [random.gauss(0, 0.03) for _ in range(TOTAL_SAMPLES)]
    hiss_filtered = bandpass_filter(hiss, SAMPLE_RATE, 1000.0, 4500.0)

    for idx in range(TOTAL_SAMPLES):
        raw_mix = piano_muted[idx] * 0.85 + hiss_filtered[idx] * 0.20
        # Warm tanh analog saturation
        samples[idx] = math.tanh(1.3 * raw_mix)

    return crossfade_loop(samples, NUM_SAMPLES, FADE_SAMPLES)


# ----------------------------------------------------------------------
# Track 9: TK-09 Zen Temple Bowl
# ----------------------------------------------------------------------
def generate_zen_bowl():
    samples = [0.0] * TOTAL_SAMPLES

    # Singing bowl fundamental at 216 Hz + harmonic overtones
    # Two gentle strikes at t=0.5s and t=8.5s (8.0s decay cycle)
    f0 = 216.0
    strikes = [0.5, 8.5]

    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE

        # Continuous sustained singing bowl hum (rim friction)
        sustained = (
            math.sin(2.0 * math.pi * f0 * t) * 0.25 +
            math.sin(2.0 * math.pi * (f0 + 0.6) * t) * 0.15 +
            math.sin(2.0 * math.pi * (f0 * 2.76) * t) * 0.10
        )

        strike_val = 0.0
        for st in strikes:
            if t >= st:
                ts = t - st
                env = math.exp(-0.35 * ts) * (1.0 - math.exp(-80.0 * ts))
                # Acoustic beating between close modes
                s_tone = (
                    math.sin(2.0 * math.pi * f0 * ts) * 0.40 +
                    math.sin(2.0 * math.pi * (f0 + 0.75) * ts) * 0.30 +
                    math.sin(2.0 * math.pi * (f0 * 2.76) * ts) * 0.20 +
                    math.sin(2.0 * math.pi * (f0 * 5.40) * ts) * 0.08 +
                    math.sin(2.0 * math.pi * (f0 * 8.93) * ts) * 0.02
                )
                strike_val += s_tone * env

        samples[idx] = sustained + strike_val

    # Very subtle air presence
    random.seed(1009)
    air = [random.gauss(0, 0.02) for _ in range(TOTAL_SAMPLES)]
    air_filtered = bandpass_filter(air, SAMPLE_RATE, 200.0, 1800.0)
    for idx in range(TOTAL_SAMPLES):
        samples[idx] += air_filtered[idx]

    return crossfade_loop(samples, NUM_SAMPLES, FADE_SAMPLES)


# ----------------------------------------------------------------------
# Track 10: TK-10 Misty Morning Meadow
# ----------------------------------------------------------------------
def generate_morning_meadow():
    random.seed(1010)
    samples = [0.0] * TOTAL_SAMPLES

    # 1. Soft morning air tone
    white_noise = [random.gauss(0, 0.25) for _ in range(TOTAL_SAMPLES)]
    air_tone = bandpass_filter(white_noise, SAMPLE_RATE, 120.0, 1200.0)

    # 2. Quiet fifth drone (C3 130.81 Hz + G3 196.00 Hz)
    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE
        breath = 0.85 + 0.15 * math.sin(2.0 * math.pi * (1.0 / 16.0) * t)
        drone = (
            math.sin(2.0 * math.pi * 130.81 * t) * 0.05 +
            math.sin(2.0 * math.pi * 196.00 * t) * 0.035
        )
        air_tone[idx] = air_tone[idx] * breath + drone

    # 3. Delicate dew drop ticks at t=2.0s, 6.0s, 10.0s, 14.0s
    dew_times = [2.0, 6.0, 10.0, 14.0]
    dew_buffer = [0.0] * TOTAL_SAMPLES
    for dt in dew_times:
        start_idx = int(dt * SAMPLE_RATE)
        dur = min(TOTAL_SAMPLES - start_idx, int(0.02 * SAMPLE_RATE))
        for k in range(dur):
            t = k / SAMPLE_RATE
            drop = math.exp(-150.0 * t) * math.sin(2.0 * math.pi * 1850.0 * t) * 0.15
            dew_buffer[start_idx + k] += drop

    for idx in range(TOTAL_SAMPLES):
        samples[idx] = air_tone[idx] * 0.75 + dew_buffer[idx]

    return crossfade_loop(samples, NUM_SAMPLES, FADE_SAMPLES)


# ----------------------------------------------------------------------
# Track 11: TK-11 Pure Focus White Noise
# ----------------------------------------------------------------------
def generate_pure_white_noise():
    random.seed(1011)

    # Gaussian white noise with psychoacoustic band limiting
    white_noise = [random.gauss(0, 0.35) for _ in range(TOTAL_SAMPLES)]
    shaped = bandpass_filter(white_noise, SAMPLE_RATE, 55.0, 8500.0)

    return crossfade_loop(shaped, NUM_SAMPLES, FADE_SAMPLES)


# ----------------------------------------------------------------------
# Track 12: TK-12 Timber Acoustic Chamber
# ----------------------------------------------------------------------
def generate_timber_chamber():
    random.seed(1012)
    samples = [0.0] * TOTAL_SAMPLES

    # Dry timber room tone with wooden resonance modes
    white_noise = [random.gauss(0, 0.3) for _ in range(TOTAL_SAMPLES)]
    room = bandpass_filter(white_noise, SAMPLE_RATE, 80.0, 850.0)

    # Wood resonance peaks (95 Hz, 160 Hz, 280 Hz, 440 Hz, 680 Hz)
    modes = [95.0, 160.0, 280.0, 440.0, 680.0]
    weights = [0.04, 0.035, 0.025, 0.018, 0.01]

    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE
        mode_val = sum(math.sin(2.0 * math.pi * m * t) * w for m, w in zip(modes, weights))
        room[idx] += mode_val

    # Multi-tap wood boundary reflection delay
    delays = [int(0.015 * SAMPLE_RATE), int(0.028 * SAMPLE_RATE), int(0.045 * SAMPLE_RATE)]
    decay_factors = [0.25, 0.18, 0.10]
    refl = list(room)
    for d, decay in zip(delays, decay_factors):
        for idx in range(d, TOTAL_SAMPLES):
            refl[idx] += room[idx - d] * decay

    filtered_refl = lowpass_filter(refl, SAMPLE_RATE, 950.0)

    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE
        breath = 0.92 + 0.08 * math.sin(2.0 * math.pi * 0.0625 * t)
        samples[idx] = filtered_refl[idx] * 0.65 * breath

    return crossfade_loop(samples, NUM_SAMPLES, FADE_SAMPLES)


# ----------------------------------------------------------------------
# Main Execution
# ----------------------------------------------------------------------
def main():
    assets_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio'))
    os.makedirs(assets_dir, exist_ok=True)

    tracks = [
        ('vinyl_lofi_rain.wav', generate_lofi_rain),
        ('vinyl_brown_noise.wav', generate_brown_noise),
        ('vinyl_library.wav', generate_library),
        ('vinyl_kyoto_bamboo.wav', generate_kyoto_bamboo),
        ('vinyl_campfire.wav', generate_campfire),
        ('vinyl_nordic_pines.wav', generate_nordic_pines),
        ('vinyl_alpine_brook.wav', generate_alpine_brook),
        ('vinyl_warm_tape.wav', generate_warm_tape),
        ('vinyl_zen_bowl.wav', generate_zen_bowl),
        ('vinyl_morning_meadow.wav', generate_morning_meadow),
        ('vinyl_pure_white_noise.wav', generate_pure_white_noise),
        ('vinyl_timber_chamber.wav', generate_timber_chamber),
    ]

    print("=== Generating 12 Curated Vinyl Focus Soundscapes ===")
    for filename, generator in tracks:
        filepath = os.path.join(assets_dir, filename)
        print(f"Synthesizing {filename}...")
        audio = generator()
        save_wav(filepath, audio)

    print("\nAll 12 vinyl soundscapes successfully generated!")


if __name__ == '__main__':
    main()
