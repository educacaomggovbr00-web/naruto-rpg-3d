#!/usr/bin/env python3
"""Original short elemental SFX, deterministic synthesis without samples."""
from pathlib import Path
import wave
import numpy as np
ROOT = Path(__file__).resolve().parents[1]
RATE = 22050

def main():
    rng = np.random.default_rng(1047)
    for name, duration in [('fire',.65),('lightning',.52),('water',.60)]:
        t = np.arange(round(RATE*duration))/RATE
        noise = rng.uniform(-1,1,len(t))
        env = np.minimum(t*60,1)*np.power(np.maximum(0,1-t/duration),1.3)
        if name == 'fire':
            filtered = np.convolve(noise,np.ones(11)/11,mode='same')
            sound = filtered*1.2 + np.sin(2*np.pi*(110*t-55*t*t))*.22
        elif name == 'lightning':
            chirp = np.sin(2*np.pi*(1400*t+900*t*t))*np.sin(t*190)
            sound = noise*.18 + chirp*.28 + np.sin(t*2*np.pi*72)*.1
        else:
            filtered = np.convolve(noise,np.ones(7)/7,mode='same')
            sound = filtered*.8 + np.sin(2*np.pi*(420*t+np.sin(t*23)*.7))*.18
        pcm = np.clip(sound*env,-.85,.85)
        path = ROOT/'assets/audio/original'/('jutsu_'+name+'.wav')
        with wave.open(str(path),'wb') as out:
            out.setparams((1,2,RATE,len(t),'NONE','not compressed'))
            out.writeframes((pcm*32767).astype('<i2').tobytes())
if __name__ == '__main__': main()
