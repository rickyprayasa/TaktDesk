#!/usr/bin/env python3
"""
Procedural Audio Generator for ZYKL / Takt Desk 12 Curated Focus Soundscapes
Generates 16-second seamless looping 22050 Hz 16-bit mono PCM WAV files.

All soundscapes are calibrated to have the same velvety, warm, soothing,
and organic acoustic character as Deep Brown Noise (TK-02).
Zero harsh sine beeps, zero digital clicks, zero abrasive TV static,
and zero metallic clipping distortion.

Track List:
TK-01: vinyl_lofi_rain.wav        - Lo-fi Rain (Warm rain bed & soft droplet wash)
TK-02: vinyl_brown_noise.wav      - Deep Brown Noise (1/f² warmth - golden standard)
TK-03: vinyl_library.wav          - Library Atmosphere (Warm acoustic room tone & calm air)
TK-04: vinyl_kyoto_bamboo.wav     - Kyoto Bamboo Stream (Gentle stream & distant wooden tap)
TK-05: vinyl_campfire.wav         - Campfire Embers (Warm hearth rumble & soft glowing embers)
TK-06: vinyl_nordic_pines.wav     - Nordic Pine Whispers (Silky high-altitude mountain wind)
TK-07: vinyl_alpine_brook.wav     - Alpine Mountain Brook (Crystalline smooth water murmur)
TK-08: vinyl_warm_tape.wav        - Warm Tape & Felt Piano (Subtle analog tape bed & warm pad)
TK-09: vinyl_zen_bowl.wav         - Zen Temple Bowl (Deep warm 108 Hz bowl & meditative swell)
TK-10: vinyl_morning_meadow.wav   - Misty Morning Meadow (Gentle sunrise dew breeze)
TK-11: vinyl_pure_white_noise.wav - Pure Focus Velvet Noise (Smooth 1/f pink noise shelf)
TK-12: vinyl_timber_chamber.wav   - Timber Acoustic Chamber (Warm wooden room resonance)
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
    """First-order lowpass filter (6 dB/octave)."""
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
    """First-order highpass filter (6 dB/octave)."""
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
    """Cascaded bandpass filter."""
    hp = highpass_filter(samples, sample_rate, low_cut)
    return lowpass_filter(hp, sample_rate, high_cut)


def generate_pink_noise(num_samples, seed=42):
    """Paul Kellet's filter method for true 1/f Pink Noise (-3 dB/octave)."""
    rng = random.Random(seed)
    b0 = b1 = b2 = b3 = b4 = b5 = b6 = 0.0
    out = [0.0] * num_samples
    for i in range(num_samples):
        white = rng.gauss(0, 0.25)
        b0 = 0.99886 * b0 + white * 0.0555179
        b1 = 0.99332 * b1 + white * 0.0750759
        b2 = 0.96900 * b2 + white * 0.1538520
        b3 = 0.86650 * b3 + white * 0.3104856
        b4 = 0.55000 * b4 + white * 0.5329522
        b5 = -0.7616 * b5 - white * 0.0168980
        out[i] = (b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362) * 0.11
        b6 = white * 0.115926
    return out


def generate_brown_noise_bed(num_samples, seed=42, leak=0.997, gain=0.05):
    """Leaky integrator for true Brownian / 1/f² noise."""
    rng = random.Random(seed)
    out = [0.0] * num_samples
    val = 0.0
    for i in range(num_samples):
        white = rng.gauss(0, 0.25)
        val = leak * val + gain * white
        out[i] = val
    return out


def crossfade_loop(samples, num_samples, fade_samples):
    """Seamless sinusoidal crossfade loop."""
    out = list(samples[:num_samples])
    for i in range(fade_samples):
        t = i / fade_samples
        gain_head = math.sin(t * math.pi / 2.0)
        gain_tail = math.cos(t * math.pi / 2.0)
        tail_val = samples[num_samples + i] if (num_samples + i) < len(samples) else 0.0
        out[i] = out[i] * gain_head + tail_val * gain_tail
    return out


def save_wav(filepath, samples, target_peak=0.75):
    """Normalizes to target_peak (leaving generous headroom) and saves 16-bit PCM WAV."""
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
# Track 1: TK-01 Lo-fi Rain (Warm Rain Bed & Soft Window Wash)
# ----------------------------------------------------------------------
def generate_lofi_rain():
    # 1. Deep rain rumble
    brown = generate_brown_noise_bed(TOTAL_SAMPLES, seed=1001, leak=0.996, gain=0.045)
    deep_rumble = lowpass_filter(brown, SAMPLE_RATE, 220.0)
    deep_rumble = highpass_filter(deep_rumble, SAMPLE_RATE, 25.0)

    # 2. Soft rain wash (pink noise bandpassed without harsh hiss)
    pink = generate_pink_noise(TOTAL_SAMPLES, seed=1002)
    rain_wash = bandpass_filter(pink, SAMPLE_RATE, 180.0, 780.0)
    rain_wash = lowpass_filter(rain_wash, SAMPLE_RATE, 650.0)

    # 3. Soft droplets (gentle organic low-amplitude water patter, no clicks)
    rng = random.Random(1003)
    droplets = [0.0] * TOTAL_SAMPLES
    prob = 20.0 / SAMPLE_RATE
    for idx in range(TOTAL_SAMPLES):
        if rng.random() < prob:
            f = rng.uniform(320.0, 560.0)
            amp = rng.uniform(0.04, 0.12)
            d_len = min(TOTAL_SAMPLES - idx, int(0.025 * SAMPLE_RATE))
            for k in range(d_len):
                t = k / SAMPLE_RATE
                env = math.exp(-110.0 * t) * math.sin(math.pi * (k / d_len))
                droplets[idx + k] += amp * env * math.sin(2.0 * math.pi * f * t)

    samples = [0.0] * TOTAL_SAMPLES
    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE
        swell = 0.90 + 0.10 * math.sin(2.0 * math.pi * (1.0 / 8.0) * t)
        samples[idx] = (deep_rumble[idx] * 0.55 + rain_wash[idx] * 0.40 * swell + droplets[idx] * 0.20)

    return crossfade_loop(samples, NUM_SAMPLES, FADE_SAMPLES)


# ----------------------------------------------------------------------
# Track 2: TK-02 Deep Brown Noise (1/f² Warmth - GOLDEN STANDARD)
# ----------------------------------------------------------------------
def generate_brown_noise():
    # Exact original code preserved - user confirmed this track is perfect
    random.seed(1002)
    samples = [0.0] * TOTAL_SAMPLES

    val = 0.0
    for idx in range(TOTAL_SAMPLES):
        white = random.gauss(0, 0.25)
        val = 0.997 * val + 0.05 * white
        samples[idx] = val

    filtered = lowpass_filter(samples, SAMPLE_RATE, 320.0)
    filtered = lowpass_filter(filtered, SAMPLE_RATE, 360.0)
    filtered = highpass_filter(filtered, SAMPLE_RATE, 28.0)

    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE
        breath = 0.94 + 0.06 * math.sin(2.0 * math.pi * (1.0 / 16.0) * t)
        filtered[idx] *= breath

    return crossfade_loop(filtered, NUM_SAMPLES, FADE_SAMPLES)


# ----------------------------------------------------------------------
# Track 3: TK-03 Library Atmosphere (Warm Room Tone & Serene Air)
# ----------------------------------------------------------------------
def generate_library():
    # Deep, warm, quiet room presence (zero sine tones, zero buzzing)
    brown = generate_brown_noise_bed(TOTAL_SAMPLES, seed=1003, leak=0.997, gain=0.04)
    room_tone = bandpass_filter(brown, SAMPLE_RATE, 40.0, 240.0)

    # Gentle, quiet library air flow
    pink = generate_pink_noise(TOTAL_SAMPLES, seed=1004)
    air_flow = bandpass_filter(pink, SAMPLE_RATE, 100.0, 380.0)

    samples = [0.0] * TOTAL_SAMPLES
    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE
        breathe = 0.92 + 0.08 * math.sin(2.0 * math.pi * (1.0 / 12.0) * t)
        samples[idx] = (room_tone[idx] * 0.65 + air_flow[idx] * 0.35) * breathe

    return crossfade_loop(samples, NUM_SAMPLES, FADE_SAMPLES)


# ----------------------------------------------------------------------
# Track 4: TK-04 Kyoto Bamboo Stream (Gentle Stream & Wooden Tap)
# ----------------------------------------------------------------------
def generate_kyoto_bamboo():
    # 1. Soothing water stream (warm bandpass, no harsh hiss)
    pink = generate_pink_noise(TOTAL_SAMPLES, seed=1005)
    stream = bandpass_filter(pink, SAMPLE_RATE, 140.0, 580.0)
    stream = lowpass_filter(stream, SAMPLE_RATE, 500.0)

    # 2. Warm stream bed depth
    brown = generate_brown_noise_bed(TOTAL_SAMPLES, seed=1006, leak=0.996, gain=0.035)
    bed = bandpass_filter(brown, SAMPLE_RATE, 35.0, 180.0)

    # 3. Distant hollow wooden bamboo tap at t=4.0s and t=12.0s
    taps = [0.0] * TOTAL_SAMPLES
    tap_times = [4.0, 12.0]
    for tt in tap_times:
        start_idx = int(tt * SAMPLE_RATE)
        dur = min(TOTAL_SAMPLES - start_idx, int(0.35 * SAMPLE_RATE))
        for k in range(dur):
            t = k / SAMPLE_RATE
            env = math.exp(-18.0 * t) * (1.0 - math.exp(-120.0 * t))
            tap_tone = math.sin(2.0 * math.pi * 148.0 * t) * 0.16 + math.sin(2.0 * math.pi * 296.0 * t) * 0.06
            taps[start_idx + k] += tap_tone * env

    taps_warm = lowpass_filter(taps, SAMPLE_RATE, 380.0)

    samples = [0.0] * TOTAL_SAMPLES
    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE
        swirl = 0.88 + 0.12 * math.sin(2.0 * math.pi * 0.2 * t)
        samples[idx] = stream[idx] * 0.55 * swirl + bed[idx] * 0.40 + taps_warm[idx]

    return crossfade_loop(samples, NUM_SAMPLES, FADE_SAMPLES)


# ----------------------------------------------------------------------
# Track 5: TK-05 Campfire Embers (Warm Hearth Rumble & Soft Embers)
# ----------------------------------------------------------------------
def generate_campfire():
    # 1. Deep hearth warmth & thermal body
    brown = generate_brown_noise_bed(TOTAL_SAMPLES, seed=1007, leak=0.997, gain=0.05)
    hearth = lowpass_filter(brown, SAMPLE_RATE, 190.0)
    hearth = highpass_filter(hearth, SAMPLE_RATE, 28.0)

    # 2. Soft, low-amplitude embers (warm crackle without harsh pops)
    rng = random.Random(1008)
    embers = [0.0] * TOTAL_SAMPLES
    prob = 14.0 / SAMPLE_RATE
    for idx in range(TOTAL_SAMPLES):
        if rng.random() < prob:
            amp = rng.uniform(0.04, 0.12)
            c_len = min(TOTAL_SAMPLES - idx, int(0.018 * SAMPLE_RATE))
            f = rng.uniform(360.0, 720.0)
            for k in range(c_len):
                t = k / SAMPLE_RATE
                env = math.exp(-140.0 * t) * math.sin(math.pi * (k / c_len))
                embers[idx + k] += amp * env * math.sin(2.0 * math.pi * f * t)

    embers_warm = lowpass_filter(embers, SAMPLE_RATE, 650.0)

    samples = [0.0] * TOTAL_SAMPLES
    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE
        flame_breath = 0.90 + 0.10 * math.sin(2.0 * math.pi * 0.25 * t)
        samples[idx] = hearth[idx] * 0.70 * flame_breath + embers_warm[idx] * 0.30

    return crossfade_loop(samples, NUM_SAMPLES, FADE_SAMPLES)


# ----------------------------------------------------------------------
# Track 6: TK-06 Nordic Pine Whispers (Silky Mountain Forest Wind)
# ----------------------------------------------------------------------
def generate_nordic_pines():
    # 1. Mountain breeze body (deep brown warmth)
    brown = generate_brown_noise_bed(TOTAL_SAMPLES, seed=1009, leak=0.996, gain=0.045)
    wind_body = lowpass_filter(brown, SAMPLE_RATE, 240.0)
    wind_body = highpass_filter(wind_body, SAMPLE_RATE, 30.0)

    # 2. Pine needle whisper (pink noise filtered warmly, no harsh treble)
    pink = generate_pink_noise(TOTAL_SAMPLES, seed=1010)
    needles = bandpass_filter(pink, SAMPLE_RATE, 220.0, 680.0)
    needles = lowpass_filter(needles, SAMPLE_RATE, 550.0)

    samples = [0.0] * TOTAL_SAMPLES
    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE
        gust1 = 0.65 + 0.35 * math.sin(2.0 * math.pi * (1.0 / 16.0) * t)
        gust2 = 0.60 + 0.40 * math.sin(2.0 * math.pi * (2.0 / 16.0) * t + 0.7)
        samples[idx] = wind_body[idx] * 0.60 * gust1 + needles[idx] * 0.40 * gust2

    return crossfade_loop(samples, NUM_SAMPLES, FADE_SAMPLES)


# ----------------------------------------------------------------------
# Track 7: TK-07 Alpine Mountain Brook (Crystalline Smooth Murmur)
# ----------------------------------------------------------------------
def generate_alpine_brook():
    # 1. Continuous smooth mountain stream
    pink = generate_pink_noise(TOTAL_SAMPLES, seed=1011)
    stream = bandpass_filter(pink, SAMPLE_RATE, 150.0, 680.0)
    stream = lowpass_filter(stream, SAMPLE_RATE, 580.0)

    # 2. Deep stream floor
    brown = generate_brown_noise_bed(TOTAL_SAMPLES, seed=1012, leak=0.997, gain=0.04)
    floor = bandpass_filter(brown, SAMPLE_RATE, 40.0, 200.0)

    # 3. Soft liquid ripple eddies
    rng = random.Random(1013)
    ripples = [0.0] * TOTAL_SAMPLES
    prob = 18.0 / SAMPLE_RATE
    for idx in range(TOTAL_SAMPLES):
        if rng.random() < prob:
            amp = rng.uniform(0.03, 0.08)
            r_len = min(TOTAL_SAMPLES - idx, int(0.03 * SAMPLE_RATE))
            f = rng.uniform(280.0, 480.0)
            for k in range(r_len):
                t = k / SAMPLE_RATE
                env = math.sin(math.pi * (k / r_len)) ** 2
                ripples[idx + k] += amp * env * math.sin(2.0 * math.pi * f * t)

    samples = [0.0] * TOTAL_SAMPLES
    for idx in range(TOTAL_SAMPLES):
        samples[idx] = stream[idx] * 0.60 + floor[idx] * 0.35 + ripples[idx] * 0.20

    return crossfade_loop(samples, NUM_SAMPLES, FADE_SAMPLES)


# ----------------------------------------------------------------------
# Track 8: TK-08 Warm Tape & Felt Piano (Subtle Analog Tape Bed & Pad)
# ----------------------------------------------------------------------
def generate_warm_tape():
    # 1. Warm analog tape bed
    pink = generate_pink_noise(TOTAL_SAMPLES, seed=1014)
    tape_bed = lowpass_filter(pink, SAMPLE_RATE, 340.0)
    tape_bed = highpass_filter(tape_bed, SAMPLE_RATE, 35.0)

    # 2. Gentle sub-bass tape head presence (48 Hz warm bump)
    # 3. Warm ambient harmonic pad (slow, very quiet, lowpassed at 280 Hz)
    pad = [0.0] * TOTAL_SAMPLES
    chords = [
        [146.83, 174.61, 220.00],  # Dm
        [130.81, 164.81, 196.00],  # C
    ]
    chord_dur = 8.0
    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE
        c_idx = int(t / chord_dur) % len(chords)
        t_chord = t % chord_dur
        # Gentle swell envelope
        env = math.sin(math.pi * (t_chord / chord_dur)) ** 2 * 0.06
        tone = sum(math.sin(2.0 * math.pi * f * t) for f in chords[c_idx])
        pad[idx] = tone * env

    pad_warm = lowpass_filter(pad, SAMPLE_RATE, 280.0)

    samples = [0.0] * TOTAL_SAMPLES
    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE
        drift = 0.94 + 0.06 * math.sin(2.0 * math.pi * 0.2 * t)
        samples[idx] = tape_bed[idx] * 0.70 * drift + pad_warm[idx] * 0.30

    return crossfade_loop(samples, NUM_SAMPLES, FADE_SAMPLES)


# ----------------------------------------------------------------------
# Track 9: TK-09 Zen Temple Bowl (Deep Warm 108 Hz Singing Bowl)
# ----------------------------------------------------------------------
def generate_zen_bowl():
    # Deep warm fundamental at 108 Hz (rich, calm sub-octave, zero high sibilance)
    brown = generate_brown_noise_bed(TOTAL_SAMPLES, seed=1015, leak=0.997, gain=0.035)
    bed = lowpass_filter(brown, SAMPLE_RATE, 160.0)

    bowl = [0.0] * TOTAL_SAMPLES
    f0 = 108.0
    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE
        # Meditative 16-second breathing envelope
        breath = math.sin(math.pi * (t / LOOP_DURATION)) ** 2
        # Pure warm fundamental + gentle 2nd harmonic
        tone = (math.sin(2.0 * math.pi * f0 * t) * 0.18 +
                math.sin(2.0 * math.pi * (f0 * 2.0) * t) * 0.06)
        bowl[idx] = tone * (0.4 + 0.6 * breath)

    bowl_warm = lowpass_filter(bowl, SAMPLE_RATE, 320.0)

    samples = [0.0] * TOTAL_SAMPLES
    for idx in range(TOTAL_SAMPLES):
        samples[idx] = bed[idx] * 0.45 + bowl_warm[idx] * 0.55

    return crossfade_loop(samples, NUM_SAMPLES, FADE_SAMPLES)


# ----------------------------------------------------------------------
# Track 10: TK-10 Misty Morning Meadow (Gentle Sunrise Dew Breeze)
# ----------------------------------------------------------------------
def generate_morning_meadow():
    # Warm, silky dawn air breeze (pink noise lowpassed warmly)
    pink = generate_pink_noise(TOTAL_SAMPLES, seed=1016)
    dawn_air = bandpass_filter(pink, SAMPLE_RATE, 90.0, 480.0)
    dawn_air = lowpass_filter(dawn_air, SAMPLE_RATE, 420.0)

    brown = generate_brown_noise_bed(TOTAL_SAMPLES, seed=1017, leak=0.996, gain=0.03)
    earth = lowpass_filter(brown, SAMPLE_RATE, 150.0)

    samples = [0.0] * TOTAL_SAMPLES
    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE
        swell = 0.90 + 0.10 * math.sin(2.0 * math.pi * (1.0 / 16.0) * t)
        samples[idx] = (dawn_air[idx] * 0.65 + earth[idx] * 0.35) * swell

    return crossfade_loop(samples, NUM_SAMPLES, FADE_SAMPLES)


# ----------------------------------------------------------------------
# Track 11: TK-11 Pure Focus Velvet Noise (Smooth 1/f Pink Noise Shelf)
# ----------------------------------------------------------------------
def generate_pure_white_noise():
    # True Velvet Pink Noise (1/f) - gentle, smooth, soothing focus shelf
    pink = generate_pink_noise(TOTAL_SAMPLES, seed=1018)
    # Gentle lowpass shelf at 680 Hz to eliminate harsh high-frequency sizzle completely
    velvet = lowpass_filter(pink, SAMPLE_RATE, 680.0)
    velvet = highpass_filter(velvet, SAMPLE_RATE, 35.0)

    return crossfade_loop(velvet, NUM_SAMPLES, FADE_SAMPLES)


# ----------------------------------------------------------------------
# Track 12: TK-12 Timber Acoustic Chamber (Warm Wooden Room Tone)
# ----------------------------------------------------------------------
def generate_timber_chamber():
    # Warm acoustic room tone with natural wood warmth (zero metallic comb filters)
    brown = generate_brown_noise_bed(TOTAL_SAMPLES, seed=1019, leak=0.997, gain=0.045)
    timber = bandpass_filter(brown, SAMPLE_RATE, 45.0, 260.0)
    timber = lowpass_filter(timber, SAMPLE_RATE, 220.0)

    pink = generate_pink_noise(TOTAL_SAMPLES, seed=1020)
    wood_air = bandpass_filter(pink, SAMPLE_RATE, 110.0, 320.0)

    samples = [0.0] * TOTAL_SAMPLES
    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE
        breathe = 0.92 + 0.08 * math.sin(2.0 * math.pi * (1.0 / 16.0) * t)
        samples[idx] = (timber[idx] * 0.65 + wood_air[idx] * 0.35) * breathe

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

    print("=== Generating 12 Calibrated Velvet Vinyl Focus Soundscapes ===")
    for filename, generator in tracks:
        filepath = os.path.join(assets_dir, filename)
        print(f"Synthesizing {filename}...")
        audio = generator()
        save_wav(filepath, audio)

    print("\nAll 12 vinyl soundscapes successfully generated!")


if __name__ == '__main__':
    main()
