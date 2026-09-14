#!/usr/bin/env python3
"""
Master Natural Foley Generator for Takt Desk
Extracts and masters authentic, high-fidelity mechanical and physical sound effects
from genuine acoustic field recordings (clocks, mechanical switches, church bells,
typewriters, vinyl phonographs, and paper) - replacing all synthetic generated sounds.
"""

import os
import wave
import struct
import math
import subprocess

RAW_DIR = "/tmp/takt_foley_raw"
OUT_DIR = "/home/tuneeca/RSQUARE/Android/Takt Desk/assets/audio"
FFMPEG = "/home/tuneeca/RSQUARE/tools/ffmpeg"

def read_wav(path):
    with wave.open(path, "rb") as w:
        sr = w.getframerate()
        n_ch = w.getnchannels()
        frames = w.readframes(w.getnframes())
        samples = list(struct.unpack(f"<{len(frames)//2}h", frames))
        return sr, samples

def write_wav(path, sr, samples):
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        clamped = [max(-32768, min(32767, int(round(s)))) for s in samples]
        w.writeframes(struct.pack(f"<{len(clamped)}h", *clamped))
    dur_ms = len(samples) / sr * 1000
    size_kb = os.path.getsize(path) / 1024
    print(f"Mastered: {os.path.basename(path):<25} ({dur_ms:6.1f} ms, {size_kb:5.1f} KB @ {sr} Hz)")

def normalize(samples, target_peak=27000):
    max_s = max(abs(s) for s in samples) if samples else 1
    if max_s < 1:
        return samples
    factor = target_peak / max_s
    return [s * factor for s in samples]

def apply_fades(samples, sr, attack_ms=1.5, release_ms=5.0):
    attack_n = int(attack_ms * sr / 1000.0)
    release_n = int(release_ms * sr / 1000.0)
    out = list(samples)
    for i in range(min(attack_n, len(out))):
        gain = i / float(attack_n)
        out[i] *= gain
    total = len(out)
    for i in range(min(release_n, total)):
        idx = total - 1 - i
        gain = i / float(release_n)
        out[idx] *= gain
    return out

def main():
    print("=== Mastering Natural Organic Foley for Takt Desk ===")
    os.makedirs(OUT_DIR, exist_ok=True)

    # 1. foley_dial_click.wav: Real Escapement Clock Tick (Detik Jam)
    # Source: grandfather.wav at t=0.62102s
    print("\n[1/7] Mastering foley_dial_click.wav (Natural clock escapement tick)...")
    sr, grand_samples = read_wav(f"{RAW_DIR}/grandfather.wav")
    peak_idx = int(0.62102 * sr)
    start_idx = peak_idx - int(0.0015 * sr) # 1.5ms pre-peak
    dur_samples = int(0.048 * sr)          # 48ms duration
    tick_samples = grand_samples[start_idx : start_idx + dur_samples]
    tick_samples = apply_fades(tick_samples, sr, attack_ms=1.0, release_ms=8.0)
    tick_samples = normalize(tick_samples, target_peak=27000)
    write_wav(f"{OUT_DIR}/foley_dial_click.wav", sr, tick_samples)

    # 2. foley_switch_click.wav: Real Mechanical Switch / Push-Button Click (Tombol Jam)
    # Source: switch_click.wav at t=0.06728s layered with mechanical_tack.wav
    print("\n[2/7] Mastering foley_switch_click.wav (Natural tactile switch click)...")
    sr_sw, sw_samples = read_wav(f"{RAW_DIR}/switch_click.wav")
    sw_peak = int(0.06728 * sr_sw)
    sw_start = sw_peak - int(0.003 * sr_sw)
    sw_dur = int(0.095 * sr_sw)
    switch_slice = sw_samples[sw_start : sw_start + sw_dur]
    
    sr_tack, tack_samples = read_wav(f"{RAW_DIR}/mechanical_tack.wav")
    tack_peak = int(0.11222 * sr_tack)
    tack_start = tack_peak - int(0.002 * sr_tack)
    tack_slice = tack_samples[tack_start : tack_start + sw_dur]
    
    # Layer 70% switch + 45% tactile tack impulse
    combined_switch = []
    for i in range(len(switch_slice)):
        tack_val = tack_slice[i] if i < len(tack_slice) else 0
        combined_switch.append(switch_slice[i] * 0.70 + tack_val * 0.45)
    combined_switch = apply_fades(combined_switch, sr_sw, attack_ms=1.5, release_ms=12.0)
    combined_switch = normalize(combined_switch, target_peak=27500)
    write_wav(f"{OUT_DIR}/foley_switch_click.wav", sr_sw, combined_switch)

    # 3. foley_bell_chime.wav: Pure Acoustic Bronze Bell Chime (Suara Alarm)
    # Source: bell_chime.wav at t=0.30376s (Samariter Church Bell III strike tone)
    print("\n[3/7] Mastering foley_bell_chime.wav (Pure acoustic bronze bell chime)...")
    sr_bell, bell_samples = read_wav(f"{RAW_DIR}/bell_chime.wav")
    bell_peak = int(0.30376 * sr_bell)
    bell_start = bell_peak - int(0.0025 * sr_bell) # 2.5ms before strike
    bell_dur = int(3.20 * sr_bell)                 # 3.20s natural ring decay
    bell_slice = bell_samples[bell_start : bell_start + bell_dur]
    bell_slice = apply_fades(bell_slice, sr_bell, attack_ms=2.0, release_ms=450.0)
    bell_slice = normalize(bell_slice, target_peak=28500)
    write_wav(f"{OUT_DIR}/foley_bell_chime.wav", sr_bell, bell_slice)

    # 4. foley_paper_tear.wav: Real Textured Paper Tear
    # Source: paper_pages.wav at t=13.8432s
    print("\n[4/7] Mastering foley_paper_tear.wav (Authentic paper tear friction)...")
    sr_p, p_samples = read_wav(f"{RAW_DIR}/paper_pages.wav")
    p_peak = int(13.8432 * sr_p)
    p_start = p_peak - int(0.040 * sr_p)
    p_dur = int(0.240 * sr_p)
    paper_slice = p_samples[p_start : p_start + p_dur]
    paper_slice = apply_fades(paper_slice, sr_p, attack_ms=3.0, release_ms=15.0)
    paper_slice = normalize(paper_slice, target_peak=26000)
    write_wav(f"{OUT_DIR}/foley_paper_tear.wav", sr_p, paper_slice)

    # 5. foley_ink_stamp.wav: Mechanical Typewriter Ribbon / Rubber Ink Stamp
    # Source: typewriter.wav at t=14.0403s
    print("\n[5/7] Mastering foley_ink_stamp.wav (Heavy mechanical stamp punch)...")
    sr_tw, tw_samples = read_wav(f"{RAW_DIR}/typewriter.wav")
    tw_peak = int(14.0403 * sr_tw)
    tw_start = tw_peak - int(0.003 * sr_tw)
    tw_dur = int(0.160 * sr_tw)
    stamp_slice = tw_samples[tw_start : tw_start + tw_dur]
    stamp_slice = apply_fades(stamp_slice, sr_tw, attack_ms=2.0, release_ms=18.0)
    stamp_slice = normalize(stamp_slice, target_peak=27000)
    write_wav(f"{OUT_DIR}/foley_ink_stamp.wav", sr_tw, stamp_slice)

    # 6. foley_stylus_drop.wav: Real Vinyl Needle Landing & Groove Engagement
    # Source: phonograph_lead_in.wav around t=2.9051s
    print("\n[6/7] Mastering foley_stylus_drop.wav (Authentic turntable needle drop)...")
    sr_ph, ph_samples = read_wav(f"{RAW_DIR}/phonograph_lead_in.wav")
    ph_peak = int(2.9051 * sr_ph)
    ph_start = ph_peak - int(0.005 * sr_ph)
    ph_dur = int(0.350 * sr_ph)
    stylus_drop_slice = ph_samples[ph_start : ph_start + ph_dur]
    stylus_drop_slice = apply_fades(stylus_drop_slice, sr_ph, attack_ms=3.0, release_ms=35.0)
    stylus_drop_slice = normalize(stylus_drop_slice, target_peak=26500)
    write_wav(f"{OUT_DIR}/foley_stylus_drop.wav", sr_ph, stylus_drop_slice)

    # 7. foley_stylus_stop.wav: Needle Tonearm Liftoff
    print("\n[7/7] Mastering foley_stylus_stop.wav (Turntable tonearm liftoff)...")
    # Liftoff transient with subtle mechanical friction release
    stop_dur = int(0.180 * sr_ph)
    stop_slice = list(stylus_drop_slice[:stop_dur])
    # Reverse envelope for clean liftoff
    for i in range(len(stop_slice)):
        gain = 1.0 - (i / float(len(stop_slice))) ** 1.8
        stop_slice[i] *= gain
    stop_slice = apply_fades(stop_slice, sr_ph, attack_ms=1.5, release_ms=15.0)
    stop_slice = normalize(stop_slice, target_peak=24000)
    write_wav(f"{OUT_DIR}/foley_stylus_stop.wav", sr_ph, stop_slice)

    print("\n=== All 7 Natural Foley Assets Mastered Successfully! ===")

if __name__ == "__main__":
    main()
