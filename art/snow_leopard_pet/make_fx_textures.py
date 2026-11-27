# Particle textures for the snow leopard pet (2026-11-27). Pure Python PNG writer, no Pillow.
# Run: python make_fx_textures.py -> fx_snowflake.png (white 6-arm snowflake, soft glow), fx_pawprint.png (white paw print)
# White on transparent so ParticleEmitter / Decal Color can tint them.
import zlib, struct, math, os

HERE = os.path.dirname(os.path.abspath(__file__))
N = 128

def png(path, w, h, px):
    raw = b"".join(b"\x00" + bytes(px[y * w * 4:(y + 1) * w * 4]) for y in range(h))
    def chunk(t, d):
        c = struct.pack(">I", len(d)) + t + d
        return c + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
                + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))

def seg_dist(px, py, ax, ay, bx, by):
    dx, dy = bx - ax, by - ay
    t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)))
    return math.hypot(px - (ax + t * dx), py - (ay + t * dy))

def render(alpha_fn, path):
    px = bytearray(N * N * 4)
    for y in range(N):
        for x in range(N):
            # 3x3 supersample
            a = 0.0
            for sy in range(3):
                for sx in range(3):
                    u = (x + (sx + 0.5) / 3) / N * 2 - 1
                    v = (y + (sy + 0.5) / 3) / N * 2 - 1
                    a += alpha_fn(u, v)
            a = max(0.0, min(1.0, a / 9))
            i = (y * N + x) * 4
            px[i:i + 4] = bytes((255, 255, 255, int(a * 255)))
    png(path, N, N, px)
    print("wrote", path)

# snowflake: 6 arms, 2 pairs of branches each, round centre, soft glow halo
SEGS = []
for k in range(6):
    a = math.radians(90 + 60 * k)
    d = (math.cos(a), math.sin(a))
    SEGS.append((0, 0, d[0] * 0.82, d[1] * 0.82, 0.055))
    for t, ln in ((0.38, 0.26), (0.6, 0.18)):
        cx, cy = d[0] * t, d[1] * t
        for s in (-1, 1):
            b = a + s * math.radians(55)
            SEGS.append((cx, cy, cx + math.cos(b) * ln, cy + math.sin(b) * ln, 0.04))

def snow(u, v):
    dmin = min(seg_dist(u, v, ax, ay, bx, by) - w for ax, ay, bx, by, w in SEGS)
    dmin = min(dmin, math.hypot(u, v) - 0.13)
    core = 1.0 if dmin <= 0 else max(0.0, 1 - dmin / 0.025)
    glow = 0.35 * max(0.0, 1 - math.hypot(u, v) / 0.95) ** 2
    return max(core, glow)

# paw print: big pad + 4 toes (used as a Decal on the ground, top = forward)
PADS = [(0, 0.28, 0.33, 0.27)] + [(x, y, 0.13, 0.15) for x, y in ((-0.42, -0.12), (-0.15, -0.38), (0.15, -0.38), (0.42, -0.12))]

def paw(u, v):
    best = 0.0
    for cx, cy, rx, ry in PADS:
        d = math.hypot((u - cx) / rx, (v - cy) / ry)
        best = max(best, 1.0 if d <= 1 else max(0.0, 1 - (d - 1) / 0.12))
    return best

render(snow, os.path.join(HERE, "fx_snowflake.png"))
render(paw, os.path.join(HERE, "fx_pawprint.png"))
