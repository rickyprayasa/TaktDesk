import math, struct, wave, os

SAMPLE_RATE = 22050
DURATION = 1.8
NUM_SAMPLES = int(SAMPLE_RATE * DURATION)
out_path = "assets/audio/foley_bell_chime.wav"

samples = []
for i in range(NUM_SAMPLES):
    t = i / SAMPLE_RATE
    decay = math.exp(-3.5 * t)
    # Fundamental 880Hz + harmonic overtone 1764Hz + transient strike 2640Hz
    s1 = math.sin(2 * math.pi * 880.0 * t) * decay
    s2 = 0.45 * math.sin(2 * math.pi * 1764.0 * t) * math.exp(-5.0 * t)
    s3 = 0.20 * math.sin(2 * math.pi * 2640.0 * t) * math.exp(-12.0 * t)
    # Initial hammer transient
    strike = (0.25 * (1.0 - t / 0.04) if t < 0.04 else 0.0)
    sample = (s1 + s2 + s3 + strike) * 0.75
    sample = max(-1.0, min(1.0, sample))
    samples.append(int(sample * 32767.0))

os.makedirs("assets/audio", exist_ok=True)
with wave.open(out_path, "w") as f:
    f.setnchannels(1)
    f.setsampwidth(2)
    f.setframerate(SAMPLE_RATE)
    f.writeframes(struct.pack(f"<{len(samples)}h", *samples))
print(f"Generated {out_path}")
