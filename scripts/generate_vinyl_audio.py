#!/usr/bin/env python3
"""
Procedural Audio Generator for Takt Desk Vinyl Ambient Sounds
Generates 16-second seamless looping 22050 Hz 16-bit mono PCM WAV files.

Tracks:
1. vinyl_campfire.wav (TK-05: Campfire Embers)
2. vinyl_forest.wav   (TK-06: Forest Canopy)
3. vinyl_cosmic.wav   (TK-07: Cosmic Drift)
4. vinyl_train.wav    (TK-08: Midnight Train)
"""

import os
import math
import random
import struct
import wave

SAMPLE_RATE = 22050
LOOP_DURATION = 16.0
FADE_DURATION = 1.5

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


def save_wav(filepath, samples, target_peak=0.80):
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
    print(f"Generated {filepath} ({len(samples)} samples, {len(samples)/SAMPLE_RATE:.2f}s)")


def generate_campfire():
    random.seed(101)
    samples = [0.0] * TOTAL_SAMPLES

    # 1. Warm low rumble (fire roar)
    white_noise = [random.gauss(0, 0.4) for _ in range(TOTAL_SAMPLES)]
    rumble = lowpass_filter(white_noise, SAMPLE_RATE, 180.0)
    rumble = lowpass_filter(rumble, SAMPLE_RATE, 220.0)

    # 2. Embers crackle & snaps (Poisson micro-snaps)
    # Average ~32 pops per second
    pop_prob = 32.0 / SAMPLE_RATE
    snap_buffer = [0.0] * TOTAL_SAMPLES

    i = 0
    while i < TOTAL_SAMPLES:
        if random.random() < pop_prob:
            snap_len = random.randint(int(0.006 * SAMPLE_RATE), int(0.025 * SAMPLE_RATE))
            freq = random.uniform(800.0, 2800.0)
            amp = random.uniform(0.2, 0.95)
            decay = random.uniform(120.0, 350.0)
            for k in range(snap_len):
                if i + k >= TOTAL_SAMPLES:
                    break
                t = k / SAMPLE_RATE
                env = math.exp(-decay * t)
                val = amp * env * math.sin(2.0 * math.pi * freq * t)
                snap_buffer[i + k] += val
            i += snap_len
        else:
            i += 1

    # 3. Soft high-frequency sizzle
    sizzle_noise = [random.gauss(0, 0.2) for _ in range(TOTAL_SAMPLES)]
    sizzle = bandpass_filter(sizzle_noise, SAMPLE_RATE, 2400.0, 5500.0)

    # Combine with flame breath modulation
    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE
        breath = 0.85 + 0.15 * math.sin(2.0 * math.pi * 0.35 * t) * math.cos(2.0 * math.pi * 0.18 * t)
        samples[idx] = (rumble[idx] * 0.85 * breath) + (snap_buffer[idx] * 0.70) + (sizzle[idx] * 0.20)

    looped = crossfade_loop(samples, NUM_SAMPLES, FADE_SAMPLES)
    return looped


def generate_forest():
    random.seed(202)
    samples = [0.0] * TOTAL_SAMPLES

    # 1. Multi-band modulated soft pink noise breeze
    white_noise = [random.gauss(0, 0.5) for _ in range(TOTAL_SAMPLES)]
    breeze_low = bandpass_filter(white_noise, SAMPLE_RATE, 150.0, 600.0)
    breeze_mid = bandpass_filter(white_noise, SAMPLE_RATE, 600.0, 1800.0)
    leaf_rustle = bandpass_filter(white_noise, SAMPLE_RATE, 2200.0, 4800.0)

    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE
        # Slow organic wind gust envelopes
        gust1 = 0.6 + 0.4 * math.sin(2.0 * math.pi * (1.0 / 8.0) * t)
        gust2 = 0.5 + 0.5 * math.sin(2.0 * math.pi * (1.0 / 16.0) * t + 1.2)
        leaf_mod = max(0.0, math.sin(2.0 * math.pi * 0.25 * t) * math.cos(2.0 * math.pi * 0.125 * t)) ** 2

        samples[idx] = (
            breeze_low[idx] * 0.55 * gust1
            + breeze_mid[idx] * 0.40 * gust2
            + leaf_rustle[idx] * 0.25 * leaf_mod
        )

    looped = crossfade_loop(samples, NUM_SAMPLES, FADE_SAMPLES)
    return looped


def generate_cosmic():
    samples = [0.0] * TOTAL_SAMPLES

    # Detuned dual analog synth drone (harmonics around 55Hz, 110Hz, 165Hz)
    f0 = 55.0  # Root A1
    detune = 0.25

    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE

        # LFO pulse (0.125 Hz = exactly 2 cycles in 16 seconds)
        lfo = 0.85 + 0.15 * math.sin(2.0 * math.pi * 0.125 * t)

        # Oscillators: 55Hz detuned pair
        osc1 = math.sin(2.0 * math.pi * (f0 - detune) * t)
        osc2 = math.sin(2.0 * math.pi * (f0 + detune) * t)

        # Sub-bass: 27.5 Hz
        sub = math.sin(2.0 * math.pi * (f0 * 0.5) * t) * 0.40

        # Second harmonic: 110 Hz detuned pair
        h2a = math.sin(2.0 * math.pi * (f0 * 2.0 - 0.15) * t)
        h2b = math.sin(2.0 * math.pi * (f0 * 2.0 + 0.15) * t)
        h2 = (h2a + h2b) * 0.35

        # Third harmonic / Fifth: 165 Hz
        h3 = math.sin(2.0 * math.pi * (f0 * 3.0) * t) * 0.20

        # Fourth harmonic: 220 Hz
        h4 = math.sin(2.0 * math.pi * (f0 * 4.0) * t) * 0.10

        mix = (osc1 + osc2) * 0.45 + sub + h2 + h3 + h4
        # Warm analog saturation
        saturated = math.tanh(1.4 * mix) * lfo
        samples[idx] = saturated

    # Subtle vinyl dust floor
    random.seed(303)
    dust = [random.gauss(0, 0.02) for _ in range(TOTAL_SAMPLES)]
    dust_filtered = bandpass_filter(dust, SAMPLE_RATE, 1000.0, 4000.0)
    for idx in range(TOTAL_SAMPLES):
        samples[idx] += dust_filtered[idx] * 0.15

    looped = crossfade_loop(samples, NUM_SAMPLES, FADE_SAMPLES)
    return looped


def generate_train():
    random.seed(404)
    samples = [0.0] * TOTAL_SAMPLES

    # 120 BPM: 0.5s per beat, 2.0s per 4/4 bar
    # 8 full bars in 16.0 seconds
    bar_duration = 2.0
    total_bars = int(math.ceil(TOTAL_SAMPLES / (bar_duration * SAMPLE_RATE)))

    # Track impacts per bar:
    bogie_hits = [0.00, 0.12, 0.45, 0.57, 1.00, 1.12, 1.45, 1.57]

    rail_clicks = [0.0] * TOTAL_SAMPLES

    for bar in range(total_bars):
        bar_start_sample = int(bar * bar_duration * SAMPLE_RATE)
        for hit_offset in bogie_hits:
            hit_sample = bar_start_sample + int(hit_offset * SAMPLE_RATE)
            if hit_sample >= TOTAL_SAMPLES:
                continue

            # Metallic click + low thud
            hit_len = int(0.10 * SAMPLE_RATE)
            click_freq = random.uniform(1100.0, 1600.0)
            thud_freq = random.uniform(85.0, 130.0)
            amp_mod = random.uniform(0.7, 1.0)

            for k in range(hit_len):
                idx = hit_sample + k
                if idx >= TOTAL_SAMPLES:
                    break
                t = k / SAMPLE_RATE
                click = math.exp(-120.0 * t) * math.sin(2.0 * math.pi * click_freq * t) * 0.60
                thud = math.exp(-45.0 * t) * math.sin(2.0 * math.pi * thud_freq * t) * 0.80
                rail_clicks[idx] += (click + thud) * amp_mod

    # Continuous carriage chassis rumble
    rumble_noise = [random.gauss(0, 0.4) for _ in range(TOTAL_SAMPLES)]
    rumble = bandpass_filter(rumble_noise, SAMPLE_RATE, 50.0, 180.0)

    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE
        # Gentle hypnotic carriage sway (4 Hz wheel cadence sway)
        sway = 0.75 + 0.25 * math.sin(2.0 * math.pi * 4.0 * t)
        samples[idx] = (rumble[idx] * 0.60 * sway) + (rail_clicks[idx] * 0.50)

    looped = crossfade_loop(samples, NUM_SAMPLES, FADE_SAMPLES)
    return looped


def main():
    assets_dir = os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio')
    os.makedirs(assets_dir, exist_ok=True)

    tracks = [
        ('vinyl_campfire.wav', generate_campfire),
        ('vinyl_forest.wav', generate_forest),
        ('vinyl_cosmic.wav', generate_cosmic),
        ('vinyl_train.wav', generate_train),
    ]

    for filename, generator in tracks:
        filepath = os.path.join(assets_dir, filename)
        print(f"Synthesizing {filename}...")
        audio = generator()
        save_wav(filepath, audio)

    print("All 4 procedural vinyl ambient tracks generated successfully!")


if __name__ == '__main__':
    main()
