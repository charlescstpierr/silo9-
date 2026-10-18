"""Original deterministic industrial textures for SILO 9; no external sources."""
from pathlib import Path
import random
from PIL import Image, ImageDraw, ImageFilter
import numpy as np

ROOT = Path(__file__).parent
SIZE = 512
rng = random.Random(9009)
for kind, color in [('panel', (106, 149, 172)), ('deck', (55, 79, 106)), ('alloy', (122, 164, 184)), ('grate', (49, 75, 100))]:
    im = Image.new('RGB', (SIZE, SIZE), color)
    height = Image.new('L', (SIZE, SIZE), 160)
    d = ImageDraw.Draw(im)
    h = ImageDraw.Draw(height)
    if kind in ('panel', 'deck'):
        margin = 9 if kind == 'panel' else 5
        d.rectangle((0,0,511,511), outline=(24,43,62), width=margin)
        d.rectangle((margin,margin,511-margin,511-margin), outline=(159,195,207), width=2)
        d.line((margin+3,509-margin,509-margin,509-margin), fill=(28,49,69), width=4)
        h.rectangle((0,0,511,511), outline=32, width=margin)
        h.rectangle((margin,margin,511-margin,511-margin), outline=205, width=2)
        for x in (22, 489):
            for y in (22, 489):
                d.ellipse((x-7,y-7,x+7,y+7), fill=(24,43,62), outline=(135,175,195), width=2)
                d.line((x-3,y,x+3,y), fill=(106,149,172), width=2)
                h.ellipse((x-6,y-6,x+6,y+6), fill=75, outline=205, width=2)
        if kind == 'panel':
            d.rectangle((50,58,461,454), outline=(77,120,147), width=2)
            h.rectangle((50,58,461,454), outline=125, width=3)
            d.rectangle((56,60,450,63), fill=(142,186,200))
            d.rectangle((53,449,459,452), fill=(57,99,127))
            d.rectangle((75,411,160,429), fill=(212,199,158))
            for x in range(79,155,6): d.line((x,414,x,426), fill=(51,61,60), width=rng.randrange(1,4))
    elif kind == 'grate':
        for y in range(16,512,64):
            for x in range(16,512,128):
                d.rounded_rectangle((x,y,x+96,y+24), radius=3, fill=(22,40,59))
                d.line((x,y+25,x+96,y+25),fill=(95,137,165),width=2)
                h.rounded_rectangle((x,y,x+96,y+24),radius=3,fill=20)
    im.save(ROOT/f'{kind}_albedo.png', optimize=True)
    heights = np.array(height.filter(ImageFilter.GaussianBlur(0.7))).astype(float)/255
    dx = (np.roll(heights,-1,axis=1)-np.roll(heights,1,axis=1))*2.2
    dy = (np.roll(heights,-1,axis=0)-np.roll(heights,1,axis=0))*2.2
    normal = np.stack((-dx,dy,np.ones_like(dx)),axis=-1)
    normal /= np.linalg.norm(normal,axis=-1,keepdims=True)
    Image.fromarray(((normal*.5+.5)*255).astype('uint8')).save(ROOT/f'{kind}_normal.png',optimize=True)
    rough = np.clip(175 + (255 - np.array(height))*0.2,0,255).astype('uint8')
    Image.fromarray(rough).save(ROOT/f'{kind}_roughness.png',optimize=True)
print('Generated 12 original deterministic industrial texture maps.')
