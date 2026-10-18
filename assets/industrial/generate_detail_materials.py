"""Generate SILO 9's original seamless microdetail maps (256 px, seed 9009)."""
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).parent
SIZE = 256
rng = np.random.default_rng(9009)
y, x = np.mgrid[:SIZE, :SIZE]


def save_material(name, albedo, height, roughness, strength):
    dx = (np.roll(height, -1, axis=1) - np.roll(height, 1, axis=1)) * strength
    dy = (np.roll(height, -1, axis=0) - np.roll(height, 1, axis=0)) * strength
    normal = np.stack((-dx, dy, np.ones_like(dx)), axis=-1)
    normal /= np.linalg.norm(normal, axis=-1, keepdims=True)
    color = np.repeat(np.clip(albedo, 0, 255)[..., None], 3, axis=-1)
    for suffix, pixels in [('albedo', color), ('normal', (normal * .5 + .5) * 255),
                           ('roughness', np.clip(roughness, 0, 255))]:
        Image.fromarray(pixels.astype('uint8')).save(ROOT / f'{name}_{suffix}.png', optimize=True)


grain = rng.normal(0, 1, (SIZE, SIZE))
height = grain * .025
scratches = np.zeros((SIZE, SIZE))
for _ in range(90):
    sx, sy = rng.integers(0, SIZE, 2)
    length = int(rng.integers(3, 48))
    along = np.arange(length)
    scratches[(sy + along // 5) % SIZE, (sx + along) % SIZE] = rng.uniform(.15, .65)
height -= scratches
save_material('worn_steel', 220 + grain * 5 + scratches * 42,
              height, 165 + grain * 9 - scratches * 85, .32)
warp = np.cos(x * np.pi / 2)
weft = np.cos(y * np.pi / 2)
over = ((x // 4 + y // 4) % 2) == 0
weave = np.where(over, warp * .7 + weft * .15, weft * .7 + warp * .15)
noise = rng.normal(0, 1, (SIZE, SIZE))
save_material('weave', 229 + weave * 14 + noise * 2,
              weave * .12 + noise * .01, 226 + weave * 9 + noise * 2, .45)
print('Generated six original seamless 256x256 maps: worn_steel and weave.')
