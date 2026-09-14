#!/usr/bin/env python3
"""
Procedural Natural Organic Foley Generator for Vinyl Disc Load to Platter.
Generates authentic physical acoustic sound of placing a 12" vinyl disc onto
a turntable platter (spindle collar contact, felt slipmat impact, air dispersion,
and velvet fiber damping).
"""

import math
import os
import random
import struct
import wave

SAMPLE_RATE = 44100
DURATION = 0.22  # 220 ms
NUM_SAMPLES = int(SAMPLE_RATE * DURATION)
OUT_PATH = "assets/audio/foley_disc_load.wav"


def generate_natural_disc_load(out_path=OUT_PATH):
    random.seed(42)

    # 1. Generate filtered Gaussian noise for organic felt / air cushion texture
    raw_noise = [random.gauss(0, 1.0) for _ in range(NUM_SAMPLES)]
    # 2-pole low-pass filter at ~650 Hz for warm acoustic air/felt whoosh
    rc = 1.0 / (2.0 * math.pi * 650.0)
    dt = 1.0 / SAMPLE_RATE
    alpha = dt / (rc + dt)
    filtered_noise = [0.0] * NUM_SAMPLES
    curr = 0.0
    for i, x in enumerate(raw_noise):
        curr += alpha * (x - curr)
        filtered_noise[i] = curr

    samples = []
    for i in range(NUM_SAMPLES):
        t = i / SAMPLE_RATE

        # 1. Soft air displacement as disc approaches platter (smooth swell peaking at t=0.055)
        air_env = math.exp(-((t - 0.055) / 0.032) ** 2)
        air = filtered_noise[i] * air_env * 0.25

        # 2. Spindle center hole guide contact (t0 = 0.035s)
        spindle = 0.0
        if t >= 0.035:
            ts = t - 0.035
            # Gentle dual-frequency damped click (brass collar guide: 950 Hz & 1480 Hz)
            sp_env = math.exp(-ts / 0.008)  # very quick 8ms decay
            spindle = (
                0.28 * math.sin(2 * math.pi * 950 * ts)
                + 0.18 * math.sin(2 * math.pi * 1480 * ts)
            ) * sp_env

        # 3. Vinyl Landing on Felt Mat Impact (t0 = 0.055s)
        impact = 0.0
        if t >= 0.055:
            ti = t - 0.055
            # Low felt mat cushion resonance (warm 115 Hz body with fast damping 28ms)
            mat_thud = 0.58 * math.sin(2 * math.pi * 115 * ti) * math.exp(-ti / 0.028)
            # Vinyl plate flex harmonic (380 Hz with 16ms damping)
            plate_flex = 0.32 * math.sin(2 * math.pi * 380 * ti) * math.exp(-ti / 0.016)
            # Secondary rim settle bounce (very soft micro-settle at 7ms later)
            settle_t = ti - 0.007
            settle = 0.0
            if settle_t > 0:
                settle = 0.20 * math.sin(2 * math.pi * 210 * settle_t) * math.exp(-settle_t / 0.020)

            # Velvet/felt fiber compression friction (short burst of low-passed noise)
            mat_friction = filtered_noise[i] * math.exp(-ti / 0.035) * 0.30

            impact = mat_thud + plate_flex + settle + mat_friction

        sample = air + spindle + impact
        samples.append(sample)

    # Smooth moving average (3-tap window) to remove any harsh digital transients
    smoothed = []
    for i in range(len(samples)):
        p = samples[i - 1] if i > 0 else samples[i]
        c = samples[i]
        n = samples[i + 1] if i < len(samples) - 1 else samples[i]
        smoothed.append(0.25 * p + 0.50 * c + 0.25 * n)

    # Normalize to safe peak
    max_v = max(abs(s) for s in smoothed) or 1.0
    target_peak = 0.82
    norm_samples = [s * (target_peak / max_v) for s in smoothed]

    # Apply smooth attack (3ms) and release fade (25ms)
    fade_in = int(0.003 * SAMPLE_RATE)
    fade_out = int(0.025 * SAMPLE_RATE)
    for i in range(fade_in):
        norm_samples[i] *= (i / fade_in)
    for i in range(fade_out):
        idx = len(norm_samples) - 1 - i
        norm_samples[idx] *= (i / fade_out)

    # Pack to 16-bit PCM
    pcm = bytearray()
    for s in norm_samples:
        clamped = max(-32767, min(32767, int(round(s * 32767))))
        pcm.extend(struct.pack('<h', clamped))

    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with wave.open(out_path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        w.writeframes(pcm)

    print(f"Generated natural {out_path}: {len(pcm)} bytes, duration: {len(norm_samples)/SAMPLE_RATE:.3f} s")


if __name__ == "__main__":
    generate_natural_disc_load()
