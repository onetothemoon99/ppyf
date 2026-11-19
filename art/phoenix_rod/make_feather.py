# Fire-feather particle texture for the Phoenix rod aura (falling feathers). Pure Python PNG writer, no Pillow.
# Run: python make_feather.py  -> fire_feather.png (256x256 RGBA)
import zlib, struct, math, os

W = H = 256
px = bytearray(W * H * 4)

def mix(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))

CORE, MID, EDGE = (255, 244, 170), (255, 150, 40), (215, 40, 25)
for y in range(H):
    v = y / (H - 1)                       # 0 = tip (top), 1 = quill (bottom)
    # vane half-width: pointed tip, widest at ~40%, narrow near the quill; slight S-curve
    half = 0.25 * math.sin(math.pi * min(1.0, (v / 0.92)) ** 1.6) * (1.0 - 0.2 * v)
    cx = 0.5 + 0.06 * math.sin(v * math.pi * 1.3)
    for x in range(W):
        u = x / (W - 1)
        d = abs(u - cx)
        i = (y * W + x) * 4
        a = 0.0
        col = (0, 0, 0)
        if v < 0.92 and half > 0.002 and d < half:
            r = d / half                      # 0 at shaft, 1 at edge
            # barbs: diagonal stripes, plus a flame-like ragged edge
            barb = 0.5 + 0.5 * math.sin((v * 40 + r * 9) * (1 if u > cx else -1) + r * 3)
            edge = 1.0 - max(0.0, (r - 0.78 - 0.12 * barb) / 0.22)
            if edge > 0:
                col = mix(CORE, MID, min(1, r * 2.2)) if r < 0.45 else mix(MID, EDGE, min(1, (r - 0.45) / 0.4))
                col = mix(col, CORE, 0.25 * (1 - v))  # brighter toward the tip
                shade = 0.85 + 0.15 * barb
                col = tuple(c * shade for c in col)
                a = min(1.0, edge) * (0.95 if r < 0.85 else 0.8)
        # shaft
        if d < 0.012 and v < 0.99:
            col, a = (255, 236, 190), 1.0
        px[i:i + 4] = bytes((int(min(255, col[0])), int(min(255, col[1])), int(min(255, col[2])), int(a * 255)))

def png(path, w, h, data):
    raw = b"".join(b"\x00" + bytes(data[y * w * 4:(y + 1) * w * 4]) for y in range(h))
    def chunk(t, d):
        c = struct.pack(">I", len(d)) + t + d
        return c + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
                + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))

png(os.path.join(os.path.dirname(os.path.abspath(__file__)), "fire_feather.png"), W, H, px)
print("ok")
