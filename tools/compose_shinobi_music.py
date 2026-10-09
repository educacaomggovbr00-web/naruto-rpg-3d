#!/usr/bin/env python3
"""Compose original short instrumental loops; no sampled recordings."""
from pathlib import Path
import math
import struct
import wave
RATE = 22050
ROOT = Path(__file__).resolve().parents[1] / 'assets/audio/original'
SCORES = {
    'exploration': ([57, 60, 64, 67, 64, 60, 59, 55, 57, 62, 65, 69, 65, 62, 60, 55], .42, .18),
    'battle': ([45, 57, 60, 64, 43, 55, 59, 62, 41, 53, 57, 60, 43, 55, 62, 59], .25, .27),
    'boss': ([38, 50, 53, 57, 38, 50, 56, 57, 36, 48, 51, 55, 37, 49, 52, 56], .22, .32),
}
for name, (notes, beat, percussion) in SCORES.items():
    samples = []
    for n in range(round(RATE * beat * len(notes))):
        t = n / RATE
        index = min(int(t / beat), len(notes) - 1)
        local = t - index * beat
        frequency = 440 * 2 ** ((notes[index] - 69) / 12)
        envelope = min(local * 100, 1) * math.exp(-local * 8)
        tone = envelope * (math.sin(t * frequency * math.tau) + .22 * math.sin(t * frequency * math.tau * 2))
        bass = math.sin(t * frequency * .5 * math.tau) * .14 * math.exp(-local * 4)
        drum = math.sin(90 * local * math.tau * math.exp(-local * 15)) * math.exp(-local * 35) * percussion if index % 2 == 0 else 0
        samples.append(round(max(-1, min(1, (tone * .22 + bass + drum))) * 32767))
    ROOT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(ROOT / (name + '.wav')), 'wb') as out:
        out.setparams((1, 2, RATE, len(samples), 'NONE', 'not compressed'))
        out.writeframes(struct.pack('<' + 'h' * len(samples), *samples))
