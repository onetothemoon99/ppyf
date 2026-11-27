# Snowflake particle texture for the Christmas rod aura (white, transparent background, 128x128). 2026-11-27
# Run: python make_snowflake.py   -> snowflake.png next to this file. Pure Python (no PIL).
import math, os, struct, zlib

N = 128
C = (N - 1) / 2
R = N * 0.46

segs = []
for k in range(6):
    a = math.pi / 2 + 2 * math.pi * k / 6
    d = (math.cos(a), math.sin(a))
    segs.append(((C, C), (C + d[0] * R, C + d[1] * R), 4.2))
    for t, L in ((0.42, 0.3), (0.7, 0.22)):
        p = (C + d[0] * R * t, C + d[1] * R * t)
        for s in (1, -1):
            b = (math.cos(a + s * 0.8), math.sin(a + s * 0.8))
            segs.append((p, (p[0] + b[0] * R * L, p[1] + b[1] * R * L), 3.2))

def dist(px, py, a, b):
    ax, ay = a; bx, by = b
    vx, vy = bx - ax, by - ay
    t = max(0.0, min(1.0, ((px - ax) * vx + (py - ay) * vy) / (vx * vx + vy * vy)))
    return math.hypot(px - (ax + vx * t), py - (ay + vy * t))

rows = []
for y in range(N):
    row = bytearray([0])
    for x in range(N):
        cov = 0.0
        for a, b, w in segs:
            cov = max(cov, min(1.0, max(0.0, w / 2 + 0.75 - dist(x, y, a, b)) / 1.5))
        cov = max(cov, min(1.0, max(0.0, 7.5 - math.hypot(x - C, y - C)) / 1.5))   # centre dot
        row += bytes((255, 255, 255, int(255 * cov)))
    rows.append(bytes(row))

def chunk(t, d):
    return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)

png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", N, N, 8, 6, 0, 0, 0)) \
    + chunk(b"IDAT", zlib.compress(b"".join(rows), 9)) + chunk(b"IEND", b"")
open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "snowflake.png"), "wb").write(png)
print("ok")
