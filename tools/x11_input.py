"""Send bounded native input to the local Xvfb playtest window."""
import argparse
import ctypes
import time

parser = argparse.ArgumentParser()
parser.add_argument("action", choices=["key", "click", "move"])
parser.add_argument("value")
parser.add_argument("--duration", type=float, default=0.1)
parser.add_argument("--display", default=":97")
args = parser.parse_args()
x11 = ctypes.CDLL("libX11.so.6")
xtest = ctypes.CDLL("libXtst.so.6")
x11.XOpenDisplay.argtypes = [ctypes.c_char_p]
x11.XOpenDisplay.restype = ctypes.c_void_p
x11.XStringToKeysym.argtypes = [ctypes.c_char_p]
x11.XStringToKeysym.restype = ctypes.c_ulong
x11.XKeysymToKeycode.argtypes = [ctypes.c_void_p, ctypes.c_ulong]
x11.XKeysymToKeycode.restype = ctypes.c_uint
x11.XFlush.argtypes = [ctypes.c_void_p]
x11.XCloseDisplay.argtypes = [ctypes.c_void_p]
xtest.XTestFakeKeyEvent.argtypes = [ctypes.c_void_p, ctypes.c_uint, ctypes.c_int, ctypes.c_ulong]
xtest.XTestFakeButtonEvent.argtypes = [ctypes.c_void_p, ctypes.c_uint, ctypes.c_int, ctypes.c_ulong]
xtest.XTestFakeMotionEvent.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_ulong]
display = x11.XOpenDisplay(args.display.encode())
if not display:
    raise SystemExit("X display unavailable")
try:
    if args.action == "key":
        code = x11.XKeysymToKeycode(display, x11.XStringToKeysym(args.value.encode()))
        if not code:
            raise SystemExit("Unknown key")
        xtest.XTestFakeKeyEvent(display, code, 1, 0)
        x11.XFlush(display)
        time.sleep(min(max(args.duration, 0.01), 30))
        xtest.XTestFakeKeyEvent(display, code, 0, 0)
    else:
        x, y = map(int, args.value.split(","))
        xtest.XTestFakeMotionEvent(display, -1, x, y, 0)
        if args.action == "click":
            xtest.XTestFakeButtonEvent(display, 1, 1, 0)
            xtest.XTestFakeButtonEvent(display, 1, 0, 0)
    x11.XFlush(display)
finally:
    x11.XCloseDisplay(display)
