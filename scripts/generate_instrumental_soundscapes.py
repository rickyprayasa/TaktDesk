#!/usr/bin/env python3
"""
Procedural Generator for ZYKL / Takt Desk 11 Pure Instrumental Focus Music Tracks
Generates seamless looping 22050 Hz 16-bit mono PCM WAV files.

Calibrated to the same warm, tape-saturated, monastic aesthetic as TK-08 Warm Tape & Felt Piano.
Zero speech, zero harsh percussion, zero jarring transients.
Designed strictly for deep programming, reading, and contemplative focus.
"""

import os
import math
import random
import struct
import wave

SAMPLE_RATE = 22050
LOOP_DURATION = 32.0
FADE_DURATION = 3.0

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
    hp = highpass_filter(samples, sample_rate, low_cut)
    return lowpass_filter(hp, sample_rate, high_cut)


def generate_pink_noise(num_samples, seed=42):
    rng = random.Random(seed)
    b0 = b1 = b2 = b3 = b4 = b5 = b6 = 0.0
    out = [0.0] * num_samples
    for i in range(num_samples):
        white = rng.gauss(0, 0.2)
        b0 = 0.99886 * b0 + white * 0.0555179
        b1 = 0.99332 * b1 + white * 0.0750759
        b2 = 0.96900 * b2 + white * 0.1538520
        b3 = 0.86650 * b3 + white * 0.3104856
        b4 = 0.55000 * b4 + white * 0.5329522
        b5 = -0.7616 * b5 - white * 0.0168980
        out[i] = (b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362) * 0.11
        b6 = white * 0.115926
    return out


def crossfade_loop(samples, num_samples, fade_samples):
    out = list(samples[:num_samples])
    for i in range(fade_samples):
        t = i / fade_samples
        gain_head = math.sin(t * math.pi / 2.0)
        gain_tail = math.cos(t * math.pi / 2.0)
        tail_val = samples[num_samples + i] if (num_samples + i) < len(samples) else 0.0
        out[i] = out[i] * gain_head + tail_val * gain_tail
    return out


def save_wav(filepath, samples, target_peak=0.72):
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
    print(f"Mastered: {os.path.basename(filepath)} ({len(samples)} samples, {len(samples)/SAMPLE_RATE:.1f}s)")


# ======================================================================
# 1. Monastic Rhodes & Velvet (TK-14)
# ======================================================================
def generate_rhodes_velvet():
    # Warm Rhodes 7th/9th chords: Cmaj9 -> Am9 -> Dm9 -> G13 (8 sec per chord)
    chords = [
        [130.81, 196.00, 246.94, 293.66, 329.63],  # Cmaj9
        [110.00, 164.81, 196.00, 246.94, 261.63],  # Am9
        [146.83, 220.00, 261.63, 329.63, 349.23],  # Dm9
        [98.00, 174.61, 220.00, 246.94, 329.63],   # G13
    ]
    chord_dur = LOOP_DURATION / len(chords)  # 8.0s
    samples = [0.0] * TOTAL_SAMPLES

    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE
        c_idx = int(t / chord_dur) % len(chords)
        t_in_chord = t % chord_dur

        # Rhodes tine envelope: gentle strike, long warm decay
        decay = math.exp(-0.45 * t_in_chord)
        # Slow tremolo (4.2 Hz)
        tremolo = 0.85 + 0.15 * math.sin(2.0 * math.pi * 4.2 * t)

        val = 0.0
        for f in chords[c_idx]:
            # Fundamental + 2nd harmonic (warmth) + bell overtone (3.8x with rapid decay)
            bell_decay = math.exp(-2.2 * t_in_chord)
            tone = (math.sin(2.0 * math.pi * f * t) * 0.60 +
                    math.sin(2.0 * math.pi * f * 2.0 * t) * 0.25 +
                    math.sin(2.0 * math.pi * f * 3.8 * t) * 0.15 * bell_decay)
            val += tone

        samples[idx] = val * decay * tremolo * 0.15

    # Tape saturation & lowpass filtering for warm vintage character
    tape = lowpass_filter(samples, SAMPLE_RATE, 1200.0)
    tape = lowpass_filter(tape, SAMPLE_RATE, 950.0)
    tape = highpass_filter(tape, SAMPLE_RATE, 35.0)

    # Subtle tape hiss bed
    pink = generate_pink_noise(TOTAL_SAMPLES, seed=201)
    bed = lowpass_filter(pink, SAMPLE_RATE, 280.0)
    for idx in range(TOTAL_SAMPLES):
        tape[idx] = tape[idx] * 0.85 + bed[idx] * 0.04

    return crossfade_loop(tape, NUM_SAMPLES, FADE_SAMPLES)


# ======================================================================
# 2. Tape Acoustic Guitar (TK-15)
# ======================================================================
def generate_acoustic_guitar():
    # Muted nylon fingerpicking pattern: Dm add9 -> Bb maj7 -> F sus2 -> C add9
    chords = [
        [146.83, 220.00, 261.63, 293.66, 329.63],  # Dm(add9)
        [116.54, 174.61, 233.08, 293.66, 349.23],  # Bbmaj7
        [174.61, 261.63, 349.23, 392.00],          # Fsus2
        [130.81, 196.00, 261.63, 293.66, 329.63],  # Cadd9
    ]
    chord_dur = LOOP_DURATION / len(chords)  # 8.0s
    samples = [0.0] * TOTAL_SAMPLES

    # Fingerpicking arpeggio notes staggered every 0.65 seconds
    arp_step = 0.65
    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE
        c_idx = int(t / chord_dur) % len(chords)
        chord = chords[c_idx]

        # Arpeggiate through strings
        arp_idx = int(t / arp_step) % len(chord)
        t_note = t % arp_step

        f = chord[arp_idx]
        decay = math.exp(-3.5 * t_note)
        # Plucked string physical harmonics
        string = (math.sin(2.0 * math.pi * f * t) * 0.55 +
                  math.sin(2.0 * math.pi * f * 2.0 * t) * 0.28 +
                  math.sin(2.0 * math.pi * f * 3.0 * t) * 0.12 +
                  math.sin(2.0 * math.pi * f * 4.0 * t) * 0.05)
        samples[idx] = string * decay * 0.22

    # Wood body resonance filter (acoustic guitar cavity ~100-800 Hz)
    body = bandpass_filter(samples, SAMPLE_RATE, 75.0, 1100.0)
    body = lowpass_filter(body, SAMPLE_RATE, 850.0)
    return crossfade_loop(body, NUM_SAMPLES, FADE_SAMPLES)


# ======================================================================
# 3. Cosmic Ambient Drift (TK-16)
# ======================================================================
def generate_ambient_drift():
    # Eno-inspired silk pad: F#m7 -> Emaj7 -> C#m7 -> B (8 sec per chord)
    chords = [
        [92.50, 138.59, 185.00, 220.00, 277.18],  # F#m7
        [82.41, 123.47, 164.81, 207.65, 246.94],  # Emaj7
        [69.30, 103.83, 138.59, 164.81, 207.65],  # C#m7
        [61.74, 92.50, 123.47, 146.83, 185.00],   # Bsus
    ]
    chord_dur = LOOP_DURATION / len(chords)
    samples = [0.0] * TOTAL_SAMPLES

    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE
        c_idx = int(t / chord_dur) % len(chords)
        t_in_chord = t % chord_dur

        # Smooth breathing swell envelope
        swell = math.sin(math.pi * (t_in_chord / chord_dur)) ** 1.8

        val = 0.0
        for f in chords[c_idx]:
            # Slightly detuned analog oscillators (chorus drift)
            o1 = math.sin(2.0 * math.pi * (f * 0.998) * t)
            o2 = math.sin(2.0 * math.pi * (f * 1.002) * t)
            o3 = math.sin(2.0 * math.pi * (f * 0.5) * t) * 0.4  # Sub-octave warmth
            val += (o1 + o2 + o3)

        samples[idx] = val * swell * 0.08

    pad = lowpass_filter(samples, SAMPLE_RATE, 360.0)
    pad = highpass_filter(pad, SAMPLE_RATE, 30.0)
    return crossfade_loop(pad, NUM_SAMPLES, FADE_SAMPLES)


# ======================================================================
# 4. Midnight Solitude Felt Piano (TK-17)
# ======================================================================
def generate_felt_piano_solo():
    # Satie / Ólafur Arnalds style slow felt upright piano in D minor
    chords = [
        [146.83, 220.00, 261.63, 349.23],  # Dm7
        [130.81, 174.61, 261.63, 349.23],  # F/C
        [116.54, 174.61, 233.08, 293.66],  # Gm/Bb
        [110.00, 164.81, 220.00, 293.66],  # Asus4
    ]
    chord_dur = LOOP_DURATION / len(chords)
    samples = [0.0] * TOTAL_SAMPLES

    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE
        c_idx = int(t / chord_dur) % len(chords)
        t_in_chord = t % chord_dur

        # Felt hammer strike with long reverberant decay
        decay = math.exp(-0.40 * t_in_chord)
        # Subtle felt noise on attack
        felt_puff = math.exp(-12.0 * t_in_chord) * 0.05

        val = 0.0
        for f in chords[c_idx]:
            val += math.sin(2.0 * math.pi * f * t) * 0.70
            val += math.sin(2.0 * math.pi * (f * 2.0) * t) * 0.22
            val += math.sin(2.0 * math.pi * (f * 3.0) * t) * 0.08

        samples[idx] = (val * decay + felt_puff) * 0.14

    piano = lowpass_filter(samples, SAMPLE_RATE, 680.0)
    piano = highpass_filter(piano, SAMPLE_RATE, 40.0)
    return crossfade_loop(piano, NUM_SAMPLES, FADE_SAMPLES)


# ======================================================================
# 5. Modular Arp & Clockwork (TK-18)
# ======================================================================
def generate_modular_clockwork():
    # Hypnotic 5-note pentatonic analog clockwork: C3, Eb3, F3, G3, Bb3, C4
    scale = [130.81, 155.56, 174.61, 196.00, 233.08, 261.63]
    step_dur = 0.50  # 120 BPM 8th notes
    samples = [0.0] * TOTAL_SAMPLES

    # Analog sequence pattern
    pattern = [0, 2, 3, 1, 4, 3, 5, 2, 0, 3, 4, 1, 2, 5, 3, 1]
    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE
        step_idx = int(t / step_dur) % len(pattern)
        note_idx = pattern[step_idx]
        t_step = t % step_dur

        f = scale[note_idx]
        decay = math.exp(-7.0 * t_step)
        tone = math.sin(2.0 * math.pi * f * t) * 0.65 + math.sin(2.0 * math.pi * (f * 2.0) * t) * 0.25
        samples[idx] = tone * decay * 0.20

    # Warm analog tape echo simulation
    echo = [0.0] * TOTAL_SAMPLES
    delay_samples = int(0.25 * SAMPLE_RATE)
    for idx in range(TOTAL_SAMPLES):
        prev = echo[idx - delay_samples] if idx >= delay_samples else 0.0
        echo[idx] = samples[idx] + prev * 0.35

    filtered = lowpass_filter(echo, SAMPLE_RATE, 750.0)
    filtered = highpass_filter(filtered, SAMPLE_RATE, 45.0)
    return crossfade_loop(filtered, NUM_SAMPLES, FADE_SAMPLES)


# ======================================================================
# 6. Lo-fi Tape Guitar & Vinyl (TK-19)
# ======================================================================
def generate_tape_guitar():
    # Warm hollowbody jazz chords: Gmaj7 -> Bm7 -> Em9 -> Cmaj7 (8s each)
    chords = [
        [98.00, 146.83, 185.00, 220.00, 246.94],  # Gmaj7
        [123.47, 185.00, 220.00, 246.94, 293.66], # Bm7
        [82.41, 123.47, 164.81, 196.00, 246.94],  # Em9
        [130.81, 164.81, 196.00, 246.94, 293.66], # Cmaj7
    ]
    chord_dur = LOOP_DURATION / len(chords)
    samples = [0.0] * TOTAL_SAMPLES

    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE
        c_idx = int(t / chord_dur) % len(chords)
        t_in_chord = t % chord_dur

        # Strum decay
        decay = math.exp(-0.55 * t_in_chord)
        # Gentle tube vibrato
        vibrato = math.sin(2.0 * math.pi * 3.8 * t) * 0.004

        val = 0.0
        for i, f in enumerate(chords[c_idx]):
            strum_delay = i * 0.025
            if t_in_chord >= strum_delay:
                td = t_in_chord - strum_delay
                note_decay = math.exp(-0.70 * td)
                freq = f * (1.0 + vibrato)
                tone = math.sin(2.0 * math.pi * freq * t) * 0.55 + math.sin(2.0 * math.pi * freq * 2.0 * t) * 0.30
                val += tone * note_decay

        samples[idx] = val * 0.16

    guitar = lowpass_filter(samples, SAMPLE_RATE, 850.0)
    guitar = highpass_filter(guitar, SAMPLE_RATE, 55.0)
    return crossfade_loop(guitar, NUM_SAMPLES, FADE_SAMPLES)


# ======================================================================
# 7. Aether Chamber Strings (TK-20)
# ======================================================================
def generate_chamber_strings():
    # Muted string quartet chords: Dm -> Gm -> Bbmaj7 -> Am (8s each)
    chords = [
        [73.42, 110.00, 146.83, 220.00],   # Cello/Viola Dm
        [98.00, 146.83, 196.00, 233.08],   # Gm
        [116.54, 174.61, 233.08, 293.66],  # Bbmaj7
        [110.00, 164.81, 220.00, 261.63],  # Am
    ]
    chord_dur = LOOP_DURATION / len(chords)
    samples = [0.0] * TOTAL_SAMPLES

    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE
        c_idx = int(t / chord_dur) % len(chords)
        t_in_chord = t % chord_dur

        # Slow bowing envelope
        bow = math.sin(math.pi * (t_in_chord / chord_dur)) ** 1.5
        vibrato = math.sin(2.0 * math.pi * 5.2 * t) * 0.006

        val = 0.0
        for f in chords[c_idx]:
            freq = f * (1.0 + vibrato)
            # Rich string harmonic series
            tone = (math.sin(2.0 * math.pi * freq * t) * 0.50 +
                    math.sin(2.0 * math.pi * freq * 2.0 * t) * 0.28 +
                    math.sin(2.0 * math.pi * freq * 3.0 * t) * 0.14 +
                    math.sin(2.0 * math.pi * freq * 4.0 * t) * 0.08)
            val += tone

        samples[idx] = val * bow * 0.11

    strings = lowpass_filter(samples, SAMPLE_RATE, 620.0)
    strings = highpass_filter(strings, SAMPLE_RATE, 35.0)
    return crossfade_loop(strings, NUM_SAMPLES, FADE_SAMPLES)


# ======================================================================
# 8. Vintage Wurlitzer 200A (TK-21)
# ======================================================================
def generate_wurlitzer_reeds():
    # Warm electric reed chords: Ebmaj7 -> Cm7 -> Fm7 -> Bb7 (8s each)
    chords = [
        [155.56, 196.00, 233.08, 293.66],  # Ebmaj7
        [130.81, 155.56, 196.00, 233.08],  # Cm7
        [174.61, 207.65, 261.63, 311.13],  # Fm7
        [116.54, 146.83, 174.61, 207.65],  # Bb7
    ]
    chord_dur = LOOP_DURATION / len(chords)
    samples = [0.0] * TOTAL_SAMPLES

    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE
        c_idx = int(t / chord_dur) % len(chords)
        t_in_chord = t % chord_dur

        decay = math.exp(-0.48 * t_in_chord)
        # Characteristic Wurlitzer vibrato tremolo (5.8 Hz)
        trem = 0.82 + 0.18 * math.sin(2.0 * math.pi * 5.8 * t)

        val = 0.0
        for f in chords[c_idx]:
            # Reed harmonics: odd harmonics dominate
            tone = (math.sin(2.0 * math.pi * f * t) * 0.55 +
                    math.sin(2.0 * math.pi * f * 3.0 * t) * 0.25 +
                    math.sin(2.0 * math.pi * f * 5.0 * t) * 0.10)
            val += tone

        samples[idx] = val * decay * trem * 0.15

    wurl = lowpass_filter(samples, SAMPLE_RATE, 950.0)
    wurl = highpass_filter(wurl, SAMPLE_RATE, 45.0)
    return crossfade_loop(wurl, NUM_SAMPLES, FADE_SAMPLES)


# ======================================================================
# 9. Moog Analog Warmth & Bass (TK-22)
# ======================================================================
def generate_moog_harmony():
    # Deep grounding 32' Moog bass drone + 5th harmonics in D
    # Chords: D -> A -> Bm -> G (8s each)
    roots = [73.42, 55.00, 61.74, 49.00]  # D2, A1, B1, G1
    fifths = [110.00, 82.41, 92.50, 73.42]
    tenths = [185.00, 138.59, 146.83, 123.47]

    chord_dur = LOOP_DURATION / len(roots)
    samples = [0.0] * TOTAL_SAMPLES

    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE
        c_idx = int(t / chord_dur) % len(roots)
        t_in_chord = t % chord_dur

        f_root = roots[c_idx]
        f_fifth = fifths[c_idx]
        f_tenth = tenths[c_idx]

        swell = 0.88 + 0.12 * math.sin(2.0 * math.pi * (1.0 / chord_dur) * t_in_chord)

        # Pure warm analog sub + soft saw emulation
        sub = math.sin(2.0 * math.pi * f_root * t) * 0.60
        harm = math.sin(2.0 * math.pi * f_fifth * t) * 0.25 + math.sin(2.0 * math.pi * f_tenth * t) * 0.15

        samples[idx] = (sub + harm) * swell * 0.22

    bass = lowpass_filter(samples, SAMPLE_RATE, 280.0)
    bass = highpass_filter(bass, SAMPLE_RATE, 25.0)
    return crossfade_loop(bass, NUM_SAMPLES, FADE_SAMPLES)


# ======================================================================
# 10. Kalimba & Crystal Chords (TK-23)
# ======================================================================
def generate_kalimba_crystal():
    # Peacefully resonant steel tines in Eb pentatonic
    tines = [155.56, 174.61, 207.65, 233.08, 261.63, 311.13, 349.23]
    samples = [0.0] * TOTAL_SAMPLES

    # Staggered contemplative notes every 1.2s
    rng = random.Random(888)
    note_times = []
    curr_t = 0.5
    while curr_t < TOTAL_SAMPLES / SAMPLE_RATE:
        note_times.append((curr_t, rng.choice(tines)))
        curr_t += rng.uniform(0.9, 1.6)

    for nt, f in note_times:
        start_idx = int(nt * SAMPLE_RATE)
        dur = min(TOTAL_SAMPLES - start_idx, int(4.0 * SAMPLE_RATE))
        for k in range(dur):
            t = k / SAMPLE_RATE
            decay = math.exp(-1.4 * t)
            # Inharmonic tine overtone: ~2.76x
            tone = (math.sin(2.0 * math.pi * f * t) * 0.70 +
                    math.sin(2.0 * math.pi * f * 2.76 * t) * 0.25 +
                    math.sin(2.0 * math.pi * f * 5.4 * t) * 0.05 * math.exp(-6.0 * t))
            samples[start_idx + k] += tone * decay * 0.18

    # Wooden kalimba box resonance
    box = bandpass_filter(samples, SAMPLE_RATE, 110.0, 1400.0)
    box = lowpass_filter(box, SAMPLE_RATE, 980.0)
    return crossfade_loop(box, NUM_SAMPLES, FADE_SAMPLES)


# ======================================================================
# 11. Nocturne in F Minor (TK-24)
# ======================================================================
def generate_nocturne_harmonics():
    # Contemplative Chopin / Satie nocturnal piano chords in F minor: Fm9 -> Bbm7 -> Eb7 -> Abmaj7 (8s each)
    chords = [
        [87.31, 130.81, 174.61, 207.65, 261.63],   # Fm9
        [116.54, 174.61, 207.65, 261.63, 311.13],  # Bbm7
        [77.78, 116.54, 155.56, 196.00, 233.08],   # Eb7
        [103.83, 155.56, 207.65, 261.63, 311.13],  # Abmaj7
    ]
    chord_dur = LOOP_DURATION / len(chords)
    samples = [0.0] * TOTAL_SAMPLES

    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE
        c_idx = int(t / chord_dur) % len(chords)
        t_in_chord = t % chord_dur

        decay = math.exp(-0.42 * t_in_chord)
        # Slower nocturnal swell
        val = 0.0
        for f in chords[c_idx]:
            tone = (math.sin(2.0 * math.pi * f * t) * 0.65 +
                    math.sin(2.0 * math.pi * f * 2.0 * t) * 0.25 +
                    math.sin(2.0 * math.pi * f * 3.0 * t) * 0.10)
            val += tone

        samples[idx] = val * decay * 0.15

    nocturne = lowpass_filter(samples, SAMPLE_RATE, 650.0)
    nocturne = highpass_filter(nocturne, SAMPLE_RATE, 35.0)
    return crossfade_loop(nocturne, NUM_SAMPLES, FADE_SAMPLES)


def main():
    assets_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio'))
    os.makedirs(assets_dir, exist_ok=True)

    tracks = [
        ('vinyl_rhodes_velvet.wav', generate_rhodes_velvet),
        ('vinyl_acoustic_guitar.wav', generate_acoustic_guitar),
        ('vinyl_ambient_drift.wav', generate_ambient_drift),
        ('vinyl_felt_piano_solo.wav', generate_felt_piano_solo),
        ('vinyl_modular_clockwork.wav', generate_modular_clockwork),
        ('vinyl_tape_guitar.wav', generate_tape_guitar),
        ('vinyl_chamber_strings.wav', generate_chamber_strings),
        ('vinyl_wurlitzer_reeds.wav', generate_wurlitzer_reeds),
        ('vinyl_moog_harmony.wav', generate_moog_harmony),
        ('vinyl_kalimba_crystal.wav', generate_kalimba_crystal),
        ('vinyl_nocturne_harmonics.wav', generate_nocturne_harmonics),
    ]

    print("=== Generating 11 Calibrated Pure Instrumental Focus Music Tracks ===")
    for filename, generator in tracks:
        filepath = os.path.join(assets_dir, filename)
        print(f"Synthesizing {filename}...")
        audio = generator()
        save_wav(filepath, audio)

    print("\nAll 11 pure instrumental tracks successfully mastered!")


if __name__ == '__main__':
    main()
