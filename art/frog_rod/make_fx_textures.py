# Particle textures for the Little Frog rod aura (2026-11-19). Pure Python PNG writer, no Pillow.
# Run: python make_fx_textures.py  -> fx_bubble.png (rainbow soap bubble), fx_note.png (white music note), fx_ripple.png (white ring)
import zlib, struct, math, os, colorsys

HERE = os.path.dirname(os.path.abspath(__file__))

def png(path, w, h, px):
    raw = b"".join(b"\x00" + bytes(px[y * w * 4:(y + 1) * w * 4]) for y in range(h))
    def chunk(t, d):
        c = struct.pack(">I", len(d)) + t + d
        return c + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
                + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))

def canvas(n):
    return bytearray(n * n * 4)

def put(px, n, x, y, rgb, a):
    i = (y * n + x) * 4
    a0 = px[i + 3] / 255.0
    na = a + a0 * (1 - a)
    if na <= 0:
        return
    for k in range(3):
        px[i + k] = int(min(255, (rgb[k] * a + px[i + k] * a0 * (1 - a)) / na))
    px[i + 3] = int(min(255, na * 255))

def smooth(e0, e1, x):
    t = max(0.0, min(1.0, (x - e0) / (e1 - e0)))
    return t * t * (3 - 2 * t)

N = 128
# --- bubble: thin rainbow rim, faint body, white highlight
px = canvas(N)
for y in range(N):
    for x in range(N):
        u, v = (x + 0.5) / N * 2 - 1, (y + 0.5) / N * 2 - 1
        r = math.hypot(u, v)
        if r > 1:
            continue
        ang = math.atan2(v, u)
        hue = (ang / (2 * math.pi) + 0.5 + 0.15 * r) % 1.0
        rr, gg, bb = colorsys.hsv_to_rgb(hue, 0.35, 1.0)
        rim = smooth(0.62, 0.9, r) * (1 - smooth(0.94, 1.0, r))
        a = 0.08 + 0.75 * rim
        put(px, N, x, y, (rr * 255, gg * 255, bb * 255), a)
        hl = math.hypot(u + 0.38, v + 0.4)
        if hl < 0.22:
            put(px, N, x, y, (255, 255, 255), 0.9 * (1 - smooth(0.08, 0.22, hl)))
png(os.path.join(HERE, "fx_bubble.png"), N, N, px)

# --- music note (eighth note), white, soft edge
px = canvas(N)
def dist_ellipse(x, y, cx, cy, rx, ry, rot):
    c, s = math.cos(rot), math.sin(rot)
    dx, dy = x - cx, y - cy
    ex, ey = (dx * c + dy * s) / rx, (-dx * s + dy * c) / ry
    return math.hypot(ex, ey)
for y in range(N):
    for x in range(N):
        a = 0.0
        d = dist_ellipse(x, y, 48, 96, 20, 14, -0.45)                     # note head
        a = max(a, 1 - smooth(0.85, 1.0, d))
        if 63 <= x <= 71 and 24 <= y <= 94:                                # stem
            a = max(a, 1.0 - smooth(0.0, 1.0, max(0, abs(x - 67) - 3)))
        fx = (x - 67) / 30.0                                               # flag: curved band from the stem top
        if 0 <= fx <= 1:
            yc = 24 + 34 * fx ** 1.3 + 6 * math.sin(fx * math.pi)
            th = 11 * (1 - 0.6 * fx)
            a = max(a, 1 - smooth(th * 0.6, th, abs(y - yc)))
        if a > 0:
            put(px, N, x, y, (255, 255, 255), a)
png(os.path.join(HERE, "fx_note.png"), N, N, px)

# --- ripple ring
px = canvas(N)
for y in range(N):
    for x in range(N):
        u, v = (x + 0.5) / N * 2 - 1, (y + 0.5) / N * 2 - 1
        r = math.hypot(u, v)
        a = (1 - smooth(0.0, 0.07, abs(r - 0.85))) * 0.95 + (1 - smooth(0.0, 0.05, abs(r - 0.62))) * 0.4
        if a > 0.003:
            put(px, N, x, y, (255, 255, 255), min(1, a))
png(os.path.join(HERE, "fx_ripple.png"), N, N, px)
print("ok")

# --- white lotus petal (tinted pink in Studio): pointed oval with a soft centre line
px = canvas(N)
for y in range(N):
    for x in range(N):
        v = (y + 0.5) / N                  # 0 = tip (top), 1 = base
        u = (x + 0.5) / N * 2 - 1
        half = 0.55 * math.sin(math.pi * min(1.0, v / 0.95) ** 0.7) * (1 - 0.25 * v)
        if v < 0.95 and half > 0.01 and abs(u) < half:
            r = abs(u) / half
            a = (1 - smooth(0.75, 1.0, r)) * (1 - smooth(0.9, 0.95, v))
            shade = 255 - 35 * (1 - r) * 0.4 - 25 * v
            put(px, N, x, y, (shade, shade, shade), a)
png(os.path.join(HERE, "fx_petal.png"), N, N, px)
print("petal ok")
