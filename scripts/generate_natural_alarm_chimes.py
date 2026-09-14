#!/usr/bin/env python3
"""
generate_natural_alarm_chimes.py
Generates 5 authentic physical acoustic alarm chimes for ZYKL:
1. Braun Dual-Hammer Mechanical Alarm (twin bell striking clockwork)
2. Brass Desk Counter Bell (crisp high-pitch bell)
3. Tibetan Bronze Singing Bowl (warm meditative multi-modal shimmer)
4. Zen Temple Bell Gong (deep sub-resonant bronze temple gong)
5. Solid Brass Tubular Clock Chime (horological grandfather chime)

Pure standard library (math, wave, struct, random). 16-bit 44.1kHz mono PCM WAV.
"""

import math
import os
import random
import struct
import wave

SAMPLE_RATE = 44100

def write_wav(filename: str, samples: list[float]):
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    # Peak normalize to 0.92 to prevent digital clipping
    max_peak = max(abs(s) for s in samples) if samples else 1.0
    if max_peak > 0:
        gain = 0.92 / max_peak
    else:
        gain = 1.0

    packed_data = bytearray()
    for s in samples:
        val = max(-1.0, min(1.0, s * gain))
        int_val = int(val * 32767.0)
        packed_data.extend(struct.pack('<h', int_val))

    with wave.open(filename, 'wb') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(SAMPLE_RATE)
        wav_file.writeframes(packed_data)
    print(f"Generated: {filename} ({len(samples)/SAMPLE_RATE:.2f}s)")

def generate_braun_dual_hammer() -> list[float]:
    """
    Twin mechanical bell with rapid alternating hammer strikes (double strike).
    Bells pitched around 1720Hz and 1880Hz with mechanical spring attack.
    """
    duration = 1.6
    total_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * total_samples

    strikes = [
        (0.00, 1720.0, 1.0),
        (0.07, 1880.0, 0.9),
        (0.18, 1720.0, 0.95),
        (0.25, 1880.0, 0.85),
    ]

    for start_t, f0, strike_amp in strikes:
        start_idx = int(start_t * SAMPLE_RATE)
        # Modal ratios for small thin-shell alarm bell
        modes = [
            (f0 * 1.00, 1.00, 4.2),
            (f0 * 1.48, 0.55, 6.5),
            (f0 * 2.12, 0.35, 9.0),
            (f0 * 2.75, 0.20, 12.0),
            (f0 * 3.40, 0.12, 16.0),
        ]
        decay_len = total_samples - start_idx
        for i in range(decay_len):
            t = i / SAMPLE_RATE
            # Transient noise burst (first 4ms)
            transient = 0.0
            if t < 0.005:
                transient = (random.random() * 2.0 - 1.0) * math.exp(-t * 900.0) * 0.35

            val = transient
            for freq, amp, decay in modes:
                val += amp * math.sin(2.0 * math.pi * freq * t) * math.exp(-decay * t)
            samples[start_idx + i] += val * strike_amp

    return samples

def generate_brass_desk_bell() -> list[float]:
    """
    Crisp brass service counter bell with single clean striker impact.
    Fundamental at 2480Hz with distinctive brass ring & spring release.
    """
    duration = 1.8
    total_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * total_samples

    f0 = 2480.0
    # Clapper strike transient
    modes = [
        (f0 * 1.00, 1.00, 3.2),
        (f0 * 1.58, 0.60, 5.0),
        (f0 * 2.32, 0.40, 7.5),
        (f0 * 2.95, 0.25, 11.0),
        (f0 * 4.10, 0.15, 15.0),
    ]

    for i in range(total_samples):
        t = i / SAMPLE_RATE
        transient = 0.0
        if t < 0.004:
            transient = (random.random() * 2.0 - 1.0) * math.exp(-t * 1200.0) * 0.5
        val = transient
        for freq, amp, decay in modes:
            val += amp * math.sin(2.0 * math.pi * freq * t) * math.exp(-decay * t)
        samples[i] = val

    return samples

def generate_tibetan_bowl() -> list[float]:
    """
    Hand-hammered Himalayan bronze singing bowl.
    Warm fundamental (261.6 Hz - Middle C) with gentle beating shimmer and rich sustained overtones.
    """
    duration = 3.6
    total_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * total_samples

    f0 = 261.63  # C4
    # Multi-modal Bessel modes with acoustic beating (split modes from hand-hammer asymmetry)
    modes = [
        # Fundamental split mode creating ~1.8 Hz beating
        (f0 * 1.000, 0.90, 0.70, 0.0),
        (f0 * 1.007, 0.85, 0.70, 0.5),
        # Second modal pair ~688 Hz
        (f0 * 2.630, 0.50, 1.10, 0.0),
        (f0 * 2.645, 0.45, 1.10, 0.8),
        # Third modal pair ~1240 Hz
        (f0 * 4.740, 0.25, 1.80, 0.0),
        (f0 * 4.760, 0.20, 1.80, 1.2),
        # High shimmer
        (f0 * 7.150, 0.10, 2.50, 0.0),
    ]

    for i in range(total_samples):
        t = i / SAMPLE_RATE
        # Padded soft mallet strike (smoother, darker attack)
        attack_env = min(1.0, t / 0.008)
        val = 0.0
        for freq, amp, decay, phase in modes:
            val += amp * math.sin(2.0 * math.pi * freq * t + phase) * math.exp(-decay * t)
        samples[i] = val * attack_env

    return samples

def generate_zen_gong() -> list[float]:
    """
    Deep resonant bronze temple bell / gong.
    Deep 110Hz fundamental (A2) with swelling acoustic bloom and long meditative tail.
    """
    duration = 4.2
    total_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * total_samples

    f0 = 110.0  # A2 deep gong
    modes = [
        (f0 * 1.00, 1.00, 0.55, 0.0),
        (f0 * 1.01, 0.80, 0.55, 0.4),  # Beating sub-bass
        (f0 * 2.05, 0.55, 0.85, 0.0),
        (f0 * 3.12, 0.40, 1.20, 0.0),
        (f0 * 4.45, 0.25, 1.70, 0.0),
        (f0 * 5.80, 0.15, 2.40, 0.0),
        (f0 * 7.90, 0.08, 3.20, 0.0),
    ]

    for i in range(total_samples):
        t = i / SAMPLE_RATE
        # Heavy cloth mallet attack
        attack_env = min(1.0, t / 0.012)
        val = 0.0
        for freq, amp, decay, phase in modes:
            val += amp * math.sin(2.0 * math.pi * freq * t + phase) * math.exp(-decay * t)
        samples[i] = val * attack_env

    return samples

def generate_tubular_chime() -> list[float]:
    """
    Horological solid brass tubular chime (grandfather clock bell).
    Clear longitudinal and Euler-Bernoulli beam modes: f0 = 587.33 Hz (D5).
    """
    duration = 3.2
    total_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * total_samples

    f0 = 587.33  # D5
    # Beam modes for suspended tubular metal chime
    modes = [
        (f0 * 1.00, 1.00, 0.85),
        (f0 * 2.76, 0.50, 1.60),
        (f0 * 5.40, 0.28, 2.50),
        (f0 * 8.93, 0.12, 4.00),
    ]

    for i in range(total_samples):
        t = i / SAMPLE_RATE
        # Precision solenoid hammer strike
        transient = 0.0
        if t < 0.003:
            transient = (random.random() * 2.0 - 1.0) * math.exp(-t * 1500.0) * 0.4
        val = transient
        for freq, amp, decay in modes:
            val += amp * math.sin(2.0 * math.pi * freq * t) * math.exp(-decay * t)
        samples[i] = val

    return samples

def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    audio_dir = os.path.join(base_dir, 'assets', 'audio')

    generators = {
        'alarm_braun_bell.wav': generate_braun_dual_hammer,
        'alarm_desk_bell.wav': generate_brass_desk_bell,
        'alarm_tibetan_bowl.wav': generate_tibetan_bowl,
        'alarm_zen_gong.wav': generate_zen_gong,
        'alarm_tubular_chime.wav': generate_tubular_chime,
    }

    for filename, gen_fn in generators.items():
        out_path = os.path.join(audio_dir, filename)
        samples = gen_fn()
        write_wav(out_path, samples)

    print("All 5 acoustic natural alarm chimes generated successfully.")

if __name__ == '__main__':
    main()
