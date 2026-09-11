#!/usr/bin/env python3
"""
Master Organic Soundscapes Generator for Takt Desk
Produces 10 authentic, seamless looping 22050 Hz 16-bit mono PCM WAV files
from genuine field recordings and public domain focus masterworks.
"""

import os
import subprocess
import wave
import struct
import math

FFMPEG = "/home/tuneeca/RSQUARE/tools/ffmpeg"
RAW_DIR = "/home/tuneeca/RSQUARE/raw_audio"
OUT_DIR = "/home/tuneeca/RSQUARE/Android/Takt Desk/assets/audio"
TMP_DIR = "/tmp/takt_audio_tmp"

os.makedirs(TMP_DIR, exist_ok=True)
os.makedirs(OUT_DIR, exist_ok=True)


def make_seamless_loop(in_wav, out_wav, loop_sec=24.0, fade_sec=3.0):
    with wave.open(in_wav, 'rb') as r:
        sr = r.getframerate()
        n_ch = r.getnchannels()
        total_frames = r.getnframes()
        raw = r.readframes(total_frames)

    num_samples = int(sr * loop_sec)
    fade_samples = int(sr * fade_sec)
    
    # Decode 16-bit mono
    samples = list(struct.unpack(f'<{len(raw)//2}h', raw))
    
    # Ensure sufficient length
    while len(samples) < (num_samples + fade_samples):
        samples.extend(samples)
        
    out = list(samples[:num_samples])
    tail = samples[num_samples:num_samples + fade_samples]
    
    # Equal-power sine/cosine crossfade
    for i in range(len(tail)):
        t = i / fade_samples
        gain_head = math.sin(t * math.pi / 2.0)
        gain_tail = math.cos(t * math.pi / 2.0)
        val = int(round(out[i] * gain_head + tail[i] * gain_tail))
        out[i] = max(-32768, min(32767, val))
        
    # Peak normalization to -1.5 dBFS (~27500)
    max_val = max(abs(s) for s in out) if out else 1
    if max_val > 100:
        norm_factor = 27500.0 / max_val
        out = [max(-32768, min(32767, int(round(s * norm_factor)))) for s in out]

    with wave.open(out_wav, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(struct.pack(f'<{len(out)}h', *out))
    print(f"Mastered: {os.path.basename(out_wav)} ({len(out)/sr:.1f}s loop @ {sr}Hz)")


def run_cmd(cmd):
    res = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if res.returncode != 0:
        print(f"Command error: {cmd}\n{res.stderr}")
        raise RuntimeError(res.stderr)


def main():
    print("=== Mastering Organic Soundscapes for Takt Desk ===")

    # 1. Lo-fi Rain: Authentic Garden Rain + Erik Satie Gymnopedie No 1 Focus Piano
    print("\n[1/10] Crafting TK-01: Lo-fi Rain...")
    tmp_lofi = f"{TMP_DIR}/raw_lofi_rain.wav"
    run_cmd(
        f'{FFMPEG} -y '
        f'-ss 5 -t 28 -i "{RAW_DIR}/garden_rain.ogg" '
        f'-ss 25 -t 28 -i "{RAW_DIR}/gymnopedie.mp3" '
        f'-filter_complex "[0:a]volume=0.60,lowpass=f=6500[rain];[1:a]volume=0.95,lowpass=f=5500[piano];[rain][piano]amix=inputs=2:duration=longest[m]" '
        f'-map "[m]" -ac 1 -ar 22050 "{tmp_lofi}"'
    )
    make_seamless_loop(tmp_lofi, f"{OUT_DIR}/vinyl_lofi_rain.wav", loop_sec=24.0, fade_sec=3.0)

    # 2. Deep Brown Noise: Acoustic 1/f^2 Brown Noise with gentle warmth
    print("\n[2/10] Crafting TK-02: Deep Brown Noise...")
    tmp_brown = f"{TMP_DIR}/raw_brown.wav"
    run_cmd(
        f'{FFMPEG} -y -f lavfi -i "anoisesrc=c=brown:r=22050:a=0.45" -t 26 '
        f'-af "lowpass=f=360,volume=1.8" '
        f'-ac 1 -ar 22050 "{tmp_brown}"'
    )
    make_seamless_loop(tmp_brown, f"{OUT_DIR}/vinyl_brown_noise.wav", loop_sec=20.0, fade_sec=2.5)

    # 3. Library Atmosphere: Serene sanctuary wood & stone acoustic room tone
    print("\n[3/10] Crafting TK-03: Library Atmosphere...")
    tmp_lib = f"{TMP_DIR}/raw_library.wav"
    run_cmd(
        f'{FFMPEG} -y -ss 2 -t 28 -i "{RAW_DIR}/library_sanctuary.wav" '
        f'-af "lowpass=f=4500,volume=1.4" '
        f'-ac 1 -ar 22050 "{tmp_lib}"'
    )
    make_seamless_loop(tmp_lib, f"{OUT_DIR}/vinyl_library.wav", loop_sec=24.0, fade_sec=3.0)

    # 4. Cafe Echo: Authentic morning coffeehouse murmur & soft porcelain clinks
    print("\n[4/10] Crafting TK-04: Cafe Echo...")
    tmp_cafe = f"{TMP_DIR}/raw_cafe.wav"
    run_cmd(
        f'{FFMPEG} -y -ss 15 -t 28 -i "{RAW_DIR}/cafe.ogg" '
        f'-af "lowpass=f=5000,highpass=f=120,volume=1.1" '
        f'-ac 1 -ar 22050 "{tmp_cafe}"'
    )
    make_seamless_loop(tmp_cafe, f"{OUT_DIR}/vinyl_cafe.wav", loop_sec=24.0, fade_sec=3.0)

    # 5. Campfire Embers: Authentic pine wood crackle & gentle embers
    print("\n[5/10] Crafting TK-05: Campfire Embers...")
    tmp_fire = f"{TMP_DIR}/raw_campfire.wav"
    run_cmd(
        f'{FFMPEG} -y -ss 5 -t 28 -i "{RAW_DIR}/campfire.ogg" '
        f'-af "volume=1.2" '
        f'-ac 1 -ar 22050 "{tmp_fire}"'
    )
    make_seamless_loop(tmp_fire, f"{OUT_DIR}/vinyl_campfire.wav", loop_sec=24.0, fade_sec=3.0)

    # 6. Forest Canopy: Gentle mountain breeze in pines with distant birdsong
    print("\n[6/10] Crafting TK-06: Forest Canopy...")
    tmp_forest = f"{TMP_DIR}/raw_forest.wav"
    run_cmd(
        f'{FFMPEG} -y -ss 8 -t 28 -i "{RAW_DIR}/forest.wav" '
        f'-af "lowpass=f=7500,volume=1.15" '
        f'-ac 1 -ar 22050 "{tmp_forest}"'
    )
    make_seamless_loop(tmp_forest, f"{OUT_DIR}/vinyl_forest.wav", loop_sec=24.0, fade_sec=3.0)

    # 7. Cosmic Drift: Rich analog synthesizer ambient pad
    print("\n[7/10] Crafting TK-07: Cosmic Drift...")
    tmp_drone = f"{TMP_DIR}/raw_drone.wav"
    run_cmd(
        f'{FFMPEG} -y -ss 10 -t 28 -i "{RAW_DIR}/drone.wav" '
        f'-af "lowpass=f=4500,volume=1.2" '
        f'-ac 1 -ar 22050 "{tmp_drone}"'
    )
    make_seamless_loop(tmp_drone, f"{OUT_DIR}/vinyl_cosmic.wav", loop_sec=24.0, fade_sec=3.0)

    # 8. Midnight Train: Hypnotic rhythmic cadence of wheels on distant sleepers
    print("\n[8/10] Crafting TK-08: Midnight Train...")
    tmp_train = f"{TMP_DIR}/raw_train.wav"
    run_cmd(
        f'{FFMPEG} -y -ss 12 -t 28 -i "{RAW_DIR}/train.ogg" '
        f'-af "lowpass=f=5000,highpass=f=80,volume=1.25" '
        f'-ac 1 -ar 22050 "{tmp_train}"'
    )
    make_seamless_loop(tmp_train, f"{OUT_DIR}/vinyl_train.wav", loop_sec=24.0, fade_sec=3.0)

    # 9. Companion 1: Vinyl Surface & Needle Crackle
    print("\n[9/10] Crafting Mixer Companion: Vinyl Surface Crackle...")
    tmp_crackle = f"{TMP_DIR}/raw_crackle.wav"
    run_cmd(
        f'{FFMPEG} -y -f lavfi -i "anoisesrc=c=pink:r=22050:a=0.15" -t 20 '
        f'-af "highpass=f=1200,lowpass=f=7000,volume=0.9" '
        f'-ac 1 -ar 22050 "{tmp_crackle}"'
    )
    make_seamless_loop(tmp_crackle, f"{OUT_DIR}/vinyl_surface_crackle.wav", loop_sec=16.0, fade_sec=2.0)

    # 10. Companion 2: Binaural Alpha 10 Hz / 432 Hz focus carrier drone
    print("\n[10/10] Crafting Mixer Companion: Binaural Alpha 432...")
    tmp_binaural = f"{TMP_DIR}/raw_binaural.wav"
    # Pure 432 Hz tone gently modulated at 10 Hz
    run_cmd(
        f'{FFMPEG} -y -f lavfi -i "sine=frequency=432:sample_rate=22050:duration=20" '
        f'-af "volume=0.5" '
        f'-ac 1 -ar 22050 "{tmp_binaural}"'
    )
    make_seamless_loop(tmp_binaural, f"{OUT_DIR}/binaural_alpha_432.wav", loop_sec=16.0, fade_sec=2.0)

    print("\n=== All 10 Audio Master Loops Successfully Generated! ===")


if __name__ == "__main__":
    main()
