import ctypes
import json
import time
from pathlib import Path
from PIL import ImageGrab

OUT = Path(__file__).resolve().parent
X = ctypes.CDLL('libX11.so.6')
T = ctypes.CDLL('libXtst.so.6')
X.XOpenDisplay.argtypes = [ctypes.c_char_p]
X.XOpenDisplay.restype = ctypes.c_void_p
X.XStringToKeysym.argtypes = [ctypes.c_char_p]
X.XStringToKeysym.restype = ctypes.c_ulong
X.XKeysymToKeycode.argtypes = [ctypes.c_void_p, ctypes.c_ulong]
X.XKeysymToKeycode.restype = ctypes.c_uint
X.XFlush.argtypes = [ctypes.c_void_p]
X.XCloseDisplay.argtypes = [ctypes.c_void_p]
T.XTestFakeKeyEvent.argtypes = [ctypes.c_void_p, ctypes.c_uint, ctypes.c_int, ctypes.c_ulong]
T.XTestFakeButtonEvent.argtypes = [ctypes.c_void_p, ctypes.c_uint, ctypes.c_int, ctypes.c_ulong]
T.XTestFakeMotionEvent.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_ulong]
T.XTestFakeRelativeMotionEvent.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_ulong]
D = X.XOpenDisplay(b':100')
assert D
START = time.monotonic()
SAVE = OUT / 'user-data/godot/app_userdata/SILO 9 — LA DESCENTE/silo9-save.json'

def note(event, **values):
    with (OUT / 'events.jsonl').open('a') as stream:
        stream.write(json.dumps(dict(event=event, seconds=time.monotonic()-START, **values))+'\n')

def key(name, down):
    code = X.XKeysymToKeycode(D, X.XStringToKeysym(name.encode()))
    assert code
    T.XTestFakeKeyEvent(D, code, down, 0)
    X.XFlush(D)
    note('key', name=name, down=down)

def tap(name, duration=.08):
    key(name, True)
    time.sleep(duration)
    key(name, False)

def button(number, down):
    T.XTestFakeButtonEvent(D, number, down, 0)
    X.XFlush(D)
    note('button', number=number, down=down)

def shoot(duration=.015):
    button(1, True)
    time.sleep(duration)
    button(1, False)

def look(dx,dy):
    T.XTestFakeRelativeMotionEvent(D, dx, dy, 0)
    X.XFlush(D)
    note('relative_motion', dx=dx, dy=dy)

def capture(name):
    ImageGrab.grab(bbox=(0,0,1280,720),xdisplay=':100').save(OUT/(name+'.png'))
    note('capture', name=name)

def save(name):
    previous = SAVE.stat().st_mtime_ns if SAVE.exists() else 0
    tap('F5')
    deadline = time.monotonic()+10
    while time.monotonic()<deadline:
        if SAVE.exists() and SAVE.stat().st_mtime_ns != previous:
            data=json.loads(SAVE.read_text())
            (OUT/(name+'.json')).write_text(json.dumps(data,indent=2)+'\n')
            note('saved',name=name,ammo=data['ammo'],energy=data['energy'],cells=data['cells'],health=data['health'])
            return data
        time.sleep(.15)
    raise AssertionError('Native F5 did not update save')


def move_cursor(x, y):
    T.XTestFakeMotionEvent(D, -1, x, y, 0)
    X.XFlush(D)
    note("absolute_ui_motion", x=x, y=y)

def click_ui(x, y):
    move_cursor(x, y)
    time.sleep(.15)
    button(1, True)
    time.sleep(.15)
    button(1, False)

def scroll_ui(steps):
    for i in range(abs(steps)):
        button(5 if steps > 0 else 4, True)
        button(5 if steps > 0 else 4, False)
        time.sleep(.08)
