#!/usr/bin/env python3
"""
Real Acoustic Instrumental Soundscape Processor for ZYKL (Drawer 2: TK-07 .. TK-12)
100% Authentic Studio Acoustic Instrumental Recordings:
  - TK-07: Warm Tape & Felt Piano (Real Felt Piano on Analog Tape)
  - TK-08: Monastic Bach Cello (John Michel - J.S. Bach Cello Suite No. 1 Prelude)
  - TK-09: Tape Acoustic Guitar (Carlo Alberto Boni - Francisco Tárrega Recuerdos de la Alhambra)
  - TK-10: Debussy Clair de Lune (Acoustic Concert Grand Piano)
  - TK-11: Midnight Solitude Piano (Erik Satie - Gnossienne No. 1 Acoustic Upright)
  - TK-12: Zen Bronze Singing Bowl (Authentic Tibetan Singing Bowl Harmonics)

All tracks are converted to seamless 40.0s 22050 Hz 16-bit mono linear PCM WAVs
using equal-power sinusoidal crossfading with ZERO volume dips at loop boundaries.
"""

import os
import math
import struct
import subprocess
import wave

SAMPLE_RATE = 22050
LOOP_DURATION = 40.0
FADE_DURATION = 4.0

NUM_SAMPLES = int(SAMPLE_RATE * LOOP_DURATION)
FADE_SAMPLES = int(SAMPLE_RATE * FADE_DURATION)
TOTAL_SAMPLES = NUM_SAMPLES + FADE_SAMPLES

FFMPEG = '/home/tuneeca/RSQUARE/tools/ffmpeg'
CACHE_DIR = os.path.expanduser('~/.cache/zykl_audio_sources')
ASSETS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio'))


def crossfade_loop(samples, num_samples, fade_samples):
    """
    Constant-power equal-energy sinusoidal crossfade.
    Blends the tail (num_samples .. num_samples + fade_samples) into the head (0 .. fade_samples).
    At the loop boundary, out[num_samples - 1] connects continuously to out[0] with ZERO discontinuity.
    """
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
    size_kb = os.path.getsize(filepath) / 1024
    print(f"  ✓ Processed {os.path.basename(filepath)} ({len(samples)/SAMPLE_RATE:.1f}s, {size_kb:.1f} KB, peak={target_peak:.2f})")


def process_instrumental_track(input_path, output_filename, start_sec=2.0, target_peak=0.75, audio_filter=None):
    tmp_wav = f"/tmp/extract_{output_filename}"
    extract_sec = str(LOOP_DURATION + FADE_DURATION)

    cmd = [
        FFMPEG, '-y',
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

    if len(samples) < TOTAL_SAMPLES:
        while len(samples) < TOTAL_SAMPLES:
            samples.extend(samples[:TOTAL_SAMPLES - len(samples)])
    else:
        samples = samples[:TOTAL_SAMPLES]

    looped = crossfade_loop(samples, NUM_SAMPLES, FADE_SAMPLES)
    out_path = os.path.join(ASSETS_DIR, output_filename)
    save_wav(out_path, looped, target_peak=target_peak)

    if os.path.exists(tmp_wav):
        os.remove(tmp_wav)


def main():
    print("=== Processing Drawer 2: 10 Authentic Studio Acoustic Instrumental Recordings ===")
    print(f"Target format: {LOOP_DURATION}s @ {SAMPLE_RATE} Hz 16-bit mono linear PCM (equal-power loop)")

    # 1. TK-11: Warm Tape & Felt Piano (Real felt piano recording on reel-to-reel tape)
    print("\nProcessing TK-11: Warm Tape & Felt Piano (Authentic Analog Tape Piano)...")
    process_instrumental_track(
        os.path.join(CACHE_DIR, 'vinyl_warm_tape.raw'),
        'vinyl_warm_tape.wav',
        start_sec=2.0,
        target_peak=0.72
    )

    # 2. TK-12: Monastic Bach Cello (John Michel - J.S. Bach Cello Suite No. 1 in G major: Prelude)
    print("\nProcessing TK-12: Monastic Bach Cello (Authentic Acoustic Solo Cello)...")
    process_instrumental_track(
        os.path.join(CACHE_DIR, 'vinyl_bach_cello.raw'),
        'vinyl_rhodes_velvet.wav',
        start_sec=1.0,
        target_peak=0.75
    )

    # 3. TK-13: Tape Acoustic Guitar (Carlo Alberto Boni - Francisco Tárrega: Recuerdos de la Alhambra)
    print("\nProcessing TK-13: Tape Acoustic Guitar (Authentic Nylon Classical Guitar)...")
    process_instrumental_track(
        os.path.join(CACHE_DIR, 'vinyl_classical_guitar.raw'),
        'vinyl_acoustic_guitar.wav',
        start_sec=2.0,
        target_peak=0.72
    )

    # 4. TK-14: Debussy Clair de Lune (Concert Grand Piano Solo)
    print("\nProcessing TK-14: Debussy Clair de Lune (Authentic Concert Grand Piano)...")
    process_instrumental_track(
        os.path.join(CACHE_DIR, 'vinyl_debussy_clair.raw'),
        'vinyl_ambient_drift.wav',
        start_sec=0.0,
        target_peak=0.82
    )

    # 5. TK-15: Midnight Solitude Piano (Erik Satie - Gnossienne No. 1 Upright Solo)
    print("\nProcessing TK-15: Midnight Solitude Piano (Authentic Muted Upright Piano)...")
    process_instrumental_track(
        os.path.join(CACHE_DIR, 'vinyl_satie_gnossienne.raw'),
        'vinyl_felt_piano_solo.wav',
        start_sec=2.0,
        target_peak=0.75
    )

    # 6. TK-16: Zen Bronze Singing Bowl (Authentic Tibetan Singing Bowl Harmonics)
    print("\nProcessing TK-16: Zen Bronze Singing Bowl (Authentic Tibetan Bowl & Bell Harmonics)...")
    process_instrumental_track(
        os.path.join(CACHE_DIR, 'vinyl_tibetan_bowl.raw'),
        'vinyl_modular_clockwork.wav',
        start_sec=0.0,
        target_peak=0.68
    )

    # 7. TK-17: Goldberg Variations Aria (Kimiko Ishizaka - J.S. Bach on Bösendorfer Imperial Grand)
    print("\nProcessing TK-17: Goldberg Variations Aria (Authentic Bösendorfer Imperial Concert Grand)...")
    process_instrumental_track(
        os.path.join(CACHE_DIR, 'vinyl_goldberg_aria.raw'),
        'vinyl_goldberg_aria.wav',
        start_sec=1.0,
        target_peak=0.78
    )

    # 8. TK-18: Chopin Nocturne Op. 9 No. 2 (Frank Levy on Steinway Concert Grand)
    print("\nProcessing TK-18: Chopin Nocturne in Eb Major (Authentic Steinway Concert Grand)...")
    process_instrumental_track(
        os.path.join(CACHE_DIR, 'vinyl_chopin_nocturne.raw'),
        'vinyl_chopin_nocturne.wav',
        start_sec=2.0,
        target_peak=0.75
    )

    # 9. TK-19: Spanish Romance Classical Guitar (Authentic Spanish Nylon Classical Guitar)
    print("\nProcessing TK-19: Spanish Romance (Authentic Spanish Nylon Classical Guitar)...")
    process_instrumental_track(
        os.path.join(CACHE_DIR, 'vinyl_spanish_romance.raw'),
        'vinyl_spanish_romance.wav',
        start_sec=1.5,
        target_peak=0.74
    )

    # 10. TK-20: Chamber String Quartet Adagio (Musopen String Quartet - Beethoven Op. 18 No. 6 Adagio)
    print("\nProcessing TK-20: Chamber String Quartet Adagio (Authentic Acoustic String Quartet)...")
    process_instrumental_track(
        os.path.join(CACHE_DIR, 'vinyl_chamber_quartet.raw'),
        'vinyl_chamber_quartet.wav',
        start_sec=4.0,
        target_peak=0.76
    )

    print("\n✓ All 10 Drawer 2 authentic studio acoustic instrumental tracks processed successfully!")


if __name__ == '__main__':
    main()
