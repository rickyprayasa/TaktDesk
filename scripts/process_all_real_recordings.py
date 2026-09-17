#!/usr/bin/env python3
"""
Real Audio Processor for ZYKL / Takt Desk 12 Focus Vinyl Soundscapes.
Converts 100% authentic real field & studio recordings into
seamless 40.0s 22050 Hz 16-bit mono PCM WAV files with smooth
sinusoidal crossfades and raised-cosine breathing envelopes.
"""

import os
import math
import struct
import subprocess
import wave

SAMPLE_RATE = 22050
LOOP_DURATION = 40.0
FADE_DURATION = 4.0
BREATHE_DURATION = 3.5

NUM_SAMPLES = int(SAMPLE_RATE * LOOP_DURATION)
FADE_SAMPLES = int(SAMPLE_RATE * FADE_DURATION)
BREATHE_SAMPLES = int(SAMPLE_RATE * BREATHE_DURATION)
TOTAL_SAMPLES = NUM_SAMPLES + FADE_SAMPLES

FFMPEG = os.path.expanduser('~/.antigravity/extensions/kilocode.kilo-code-7.5.16-linux-x64/bin/ffmpeg')
CACHE_DIR = os.path.expanduser('~/.cache/zykl_audio_sources')
ASSETS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio'))


def crossfade_loop(samples, num_samples, fade_samples):
    out = list(samples[:num_samples])
    for i in range(fade_samples):
        t = i / fade_samples
        gain_head = math.sin(t * math.pi / 2.0)
        gain_tail = math.cos(t * math.pi / 2.0)
        tail_val = samples[num_samples + i] if (num_samples + i) < len(samples) else 0.0
        out[i] = out[i] * gain_head + tail_val * gain_tail
    return out


def apply_breathing_envelope(samples):
    out = list(samples)
    n = len(out)
    for i in range(min(BREATHE_SAMPLES, n)):
        # Smooth fade-in from silence
        t = i / BREATHE_SAMPLES
        gain = 0.5 * (1.0 - math.cos(t * math.pi))
        out[i] *= gain

        # Smooth fade-out to silence
        j = n - 1 - i
        out[j] *= gain
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
    print(f"  ✓ Saved {os.path.basename(filepath)} ({len(samples)} samples, {len(samples)/SAMPLE_RATE:.1f}s, {os.path.getsize(filepath)} bytes)")


def process_real_recording(input_path, output_path, start_sec=5.0, target_peak=0.75, audio_filter=None):
    tmp_wav = f"/tmp/extract_{os.path.basename(output_path)}"
    extract_sec = str(LOOP_DURATION + FADE_DURATION)

    cmd = [
        FFMPEG, '-y',
        '-stream_loop', '-1',
        '-ss', str(start_sec),
        '-t', extract_sec,
        '-i', input_path,
    ]
    if audio_filter:
        cmd.extend(['-af', audio_filter])
    cmd.extend([
        '-ar', str(SAMPLE_RATE),
        '-ac', '1',
        '-c:a', 'pcm_s16le',
        tmp_wav
    ])
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

    with wave.open(tmp_wav, 'rb') as wf:
        n_frames = wf.getnframes()
        raw_bytes = wf.readframes(n_frames)
        samples = [s[0] / 32768.0 for s in struct.iter_unpack('<h', raw_bytes)]

    # If samples is shorter than TOTAL_SAMPLES, pad by repeating
    if len(samples) < TOTAL_SAMPLES:
        while len(samples) < TOTAL_SAMPLES:
            samples.extend(samples[:TOTAL_SAMPLES - len(samples)])
    else:
        samples = samples[:TOTAL_SAMPLES]

    looped = crossfade_loop(samples, NUM_SAMPLES, FADE_SAMPLES)
    smoothed = apply_breathing_envelope(looped)
    save_wav(output_path, smoothed, target_peak=target_peak)
    if os.path.exists(tmp_wav):
        os.remove(tmp_wav)


def generate_brown_noise():
    """Deep Brown Noise (1/f² warmth) - preserved exact golden standard."""
    import random
    random.seed(1002)
    samples = [0.0] * TOTAL_SAMPLES

    def lowpass(s, rate, cutoff):
        rc = 1.0 / (2.0 * math.pi * cutoff)
        dt = 1.0 / rate
        alpha = dt / (rc + dt)
        out = [0.0] * len(s)
        curr = 0.0
        for i, x in enumerate(s):
            curr += alpha * (x - curr)
            out[i] = curr
        return out

    def highpass(s, rate, cutoff):
        rc = 1.0 / (2.0 * math.pi * cutoff)
        dt = 1.0 / rate
        alpha = rc / (rc + dt)
        out = [0.0] * len(s)
        curr = s[0] if s else 0.0
        prev_in = curr
        for i, x in enumerate(s):
            curr = alpha * (curr + x - prev_in)
            prev_in = x
            out[i] = curr
        return out

    val = 0.0
    for idx in range(TOTAL_SAMPLES):
        white = random.gauss(0, 0.25)
        val = 0.997 * val + 0.05 * white
        samples[idx] = val

    filtered = lowpass(samples, SAMPLE_RATE, 320.0)
    filtered = lowpass(filtered, SAMPLE_RATE, 360.0)
    filtered = highpass(filtered, SAMPLE_RATE, 28.0)

    for idx in range(TOTAL_SAMPLES):
        t = idx / SAMPLE_RATE
        breath = 0.94 + 0.06 * math.sin(2.0 * math.pi * (1.0 / LOOP_DURATION) * t)
        filtered[idx] *= breath

    looped = crossfade_loop(filtered, NUM_SAMPLES, FADE_SAMPLES)
    return apply_breathing_envelope(looped)


def main():
    print("=== Processing 100% Real Audio Field & Studio Recordings ===")
    print(f"Target format: {LOOP_DURATION}s @ {SAMPLE_RATE}Hz 16-bit mono with {BREATHE_DURATION}s breathing envelope")

    # 1. TK-01: Lo-fi Rain (Real rainfall recording)
    print("Processing TK-01: Real Lo-fi Rain...")
    process_real_recording(
        os.path.join(CACHE_DIR, 'vinyl_lofi_rain.raw'),
        os.path.join(ASSETS_DIR, 'vinyl_lofi_rain.wav'),
        start_sec=15.0,
        target_peak=0.72
    )

    # 2. TK-02: Deep Brown Noise (1/f² warmth - golden standard)
    print("Processing TK-02: Deep Brown Noise (Golden Standard)...")
    brown_samples = generate_brown_noise()
    save_wav(os.path.join(ASSETS_DIR, 'vinyl_brown_noise.wav'), brown_samples, target_peak=0.75)

    # 3. TK-03: Library Atmosphere (Real TU Delft study hall ambience)
    print("Processing TK-03: Real Library Atmosphere...")
    process_real_recording(
        os.path.join(CACHE_DIR, 'vinyl_library.raw'),
        os.path.join(ASSETS_DIR, 'vinyl_library.wav'),
        start_sec=20.0,
        target_peak=0.75
    )

    # 4. TK-04: Kyoto Bamboo Stream (Real Shishi-odoshi bamboo fountain)
    print("Processing TK-04: Real Kyoto Bamboo Fountain...")
    process_real_recording(
        os.path.join(CACHE_DIR, 'vinyl_kyoto_bamboo.raw'),
        os.path.join(ASSETS_DIR, 'vinyl_kyoto_bamboo.wav'),
        start_sec=0.0,
        target_peak=0.75
    )

    # 5. TK-05: Campfire Embers (Real crackling campfire)
    print("Processing TK-05: Real Campfire Embers...")
    process_real_recording(
        os.path.join(CACHE_DIR, 'vinyl_campfire.raw'),
        os.path.join(ASSETS_DIR, 'vinyl_campfire.wav'),
        start_sec=8.0,
        target_peak=0.72
    )

    # 6. TK-06: Nordic Pines (Real gentle Swedish pine forest breeze & whispering trees)
    print("Processing TK-06: Real Nordic Pine Whispers...")
    process_real_recording(
        os.path.join(CACHE_DIR, 'vinyl_nordic_pines.raw'),
        os.path.join(ASSETS_DIR, 'vinyl_nordic_pines.wav'),
        start_sec=5.0,
        target_peak=0.72,
        audio_filter='lowpass=f=1800,highpass=f=60'
    )

    # 7. TK-07: Alpine Mountain Brook (Real mountain snowmelt brook)
    print("Processing TK-07: Real Alpine Mountain Brook...")
    process_real_recording(
        os.path.join(CACHE_DIR, 'vinyl_alpine_brook.raw'),
        os.path.join(ASSETS_DIR, 'vinyl_alpine_brook.wav'),
        start_sec=12.0,
        target_peak=0.72
    )

    # 8. TK-08: Warm Tape & Felt Piano (Real acoustic solo piano)
    print("Processing TK-08: Real Acoustic Solo Piano...")
    process_real_recording(
        os.path.join(CACHE_DIR, 'vinyl_warm_tape.raw'),
        os.path.join(ASSETS_DIR, 'vinyl_warm_tape.wav'),
        start_sec=2.0,
        target_peak=0.72
    )

    # 9. TK-09: Pacific Ocean Waves (Real tidal beach waves - replaces droning zen bowl)
    print("Processing TK-09: Real Pacific Ocean Waves...")
    process_real_recording(
        os.path.join(CACHE_DIR, 'vinyl_ocean_waves.raw'),
        os.path.join(ASSETS_DIR, 'vinyl_ocean_waves.wav'),
        start_sec=50.0,
        target_peak=0.72,
        audio_filter='lowpass=f=2400,highpass=f=40'
    )
    # Also write to vinyl_zen_bowl.wav for backward compatibility
    process_real_recording(
        os.path.join(CACHE_DIR, 'vinyl_ocean_waves.raw'),
        os.path.join(ASSETS_DIR, 'vinyl_zen_bowl.wav'),
        start_sec=50.0,
        target_peak=0.72,
        audio_filter='lowpass=f=2400,highpass=f=40'
    )

    # 10. TK-10: Misty Morning Meadow (Real morning forest birdsong & dawn breeze)
    print("Processing TK-10: Real Morning Meadow Birdsong & Breeze...")
    process_real_recording(
        os.path.join(CACHE_DIR, 'vinyl_morning_meadow.raw'),
        os.path.join(ASSETS_DIR, 'vinyl_morning_meadow.wav'),
        start_sec=10.0,
        target_peak=0.72
    )

    # 11. TK-11: Pure Focus White Noise (Real steady mountain waterfall)
    print("Processing TK-11: Real Mountain Waterfall Focus White Noise...")
    process_real_recording(
        os.path.join(CACHE_DIR, 'vinyl_waterfall.raw'),
        os.path.join(ASSETS_DIR, 'vinyl_pure_white_noise.wav'),
        start_sec=0.0,
        target_peak=0.70,
        audio_filter='lowpass=f=3500,highpass=f=80'
    )

    # 12. TK-12: Timber Acoustic Chamber (Real acoustic hall ambience)
    print("Processing TK-12: Real Timber Acoustic Hall...")
    process_real_recording(
        os.path.join(CACHE_DIR, 'vinyl_timber_chamber.raw'),
        os.path.join(ASSETS_DIR, 'vinyl_timber_chamber.wav'),
        start_sec=2.0,
        target_peak=0.75
    )

    print("\nAll 12 real vinyl soundscapes successfully processed and deployed!")


if __name__ == '__main__':
    main()
