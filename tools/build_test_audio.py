"""Original short mechanical sounds. Requires numpy only to rebuild, never to run the game."""
from pathlib import Path
import wave
import numpy as np
root=Path(__file__).resolve().parents[1]/'assets/audio'
rate=22050
rng=np.random.default_rng(734)
for name,seconds in [('at01_step',.31),('at01_servo',.19)]:
    t=np.arange(int(rate*seconds))/rate
    noise=rng.normal(0,1,len(t))
    noise=np.convolve(noise,np.ones(8)/8,mode='same')
    if name=='at01_step':
        sound=.30*np.sin(2*np.pi*53*t)*np.exp(-t*18)+.11*np.sin(2*np.pi*137*t)*np.exp(-t*22)+.11*noise*np.exp(-t*29)
    else:
        sound=.12*np.sin(2*np.pi*(430*t-400*t*t))*np.exp(-t*22)+.10*noise*np.exp(-t*34)
    sound*=np.minimum(1,t/.004)
    assert np.max(np.abs(sound))<1
    with wave.open(str(root/(name+'.wav')),'wb') as f:
        f.setparams((1,2,rate,0,'NONE','not compressed'))
        f.writeframes((sound*32767).astype('<i2').tobytes())
print('AT-01 mechanical sounds built')
