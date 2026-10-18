import argparse
import io
import json
from pathlib import Path
import re
import subprocess
import time
from PIL import Image, ImageGrab

parser = argparse.ArgumentParser()
parser.add_argument('--image', type=Path)
parser.add_argument('--display', default=':100')
parser.add_argument('--energy', type=int)
parser.add_argument('--timeout', type=float, default=15)
parser.add_argument('--save', default='observation')
args = parser.parse_args()
out = Path(__file__).resolve().parent
started = time.monotonic()
while True:
    screen = Image.open(args.image) if args.image else ImageGrab.grab(bbox=(0, 0, 1280, 720), xdisplay=args.display)
    crop = screen.crop((140, 595, 375, 628)).resize((940, 132)).convert('RGB')
    crop.putdata([(0, 0, 0) if g > 130 and b > 130 and r < g * .85 else (255, 255, 255) for r, g, b in crop.get_flattened_data()])
    buffer = io.BytesIO()
    crop.save(buffer, format='PNG')
    result = subprocess.run(['tesseract', 'stdin', 'stdout', '--psm', '7'], input=buffer.getvalue(), capture_output=True, check=True)
    words = result.stdout.decode()
    energy = re.search(r'NERGIE\s+(\d+)\s*/\s*(\d+)', words, re.I)
    value = int(energy.group(1)) if energy else None
    ready = value is not None and (args.energy is None or value == args.energy)
    if ready or args.image or time.monotonic() - started >= args.timeout:
        screen.save(out / (args.save + '.png'))
        receipt = {'ready': ready, 'energy': value, 'ocr': words, 'elapsed_s': round(time.monotonic() - started, 3), 'source': str(args.image) if args.image else 'native X11 screenshot'}
        (out / (args.save + '.json')).write_text(json.dumps(receipt, indent=2) + '\n')
        print(json.dumps(receipt))
        raise SystemExit(0 if ready else 1)
    time.sleep(.4)
