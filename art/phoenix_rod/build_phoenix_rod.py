# Phoenix fishing rod (เบ็ดฟีนิกซ์, 199 R$, same stats as SunBee) + fire-egg bobber. 2026-11-19
# Run:  blender.exe -b --factory-startup -P build_phoenix_rod.py -- <outdir>
# Units: 1 Blender unit = 1 stud. Rod is built STRAIGHT UP along Blender +Z with the hand (Roblox Handle) at the origin.
#   Sides = +-X (wings), underside = -Y (reel), top = +Y. Tip (beak) at z ~5.9. Studio tilts it like the other rods.
# Bobber: origin = water line, egg above (z > 0), LineAttach goes on top of the flame crest (~z 0.55).
# Objects are named "<Model>__<Material>"; Studio colours them from COLORS (the importer drops colours).
# Output: PhoenixRod.glb, PhoenixBobber.glb + preview_<Model>.png
import bpy, bmesh, math, sys, os
from mathutils import Vector, Matrix, Euler

OUT = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else os.path.dirname(os.path.abspath(__file__))
os.makedirs(OUT, exist_ok=True)
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o, do_unlink=True)

def lin(c):
    c = c / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

COLORS = {
    "PoleRed": (186, 32, 30), "PoleOrange": (236, 104, 26), "PoleGold": (250, 184, 48),
    "Gold": (246, 196, 72), "GoldDark": (196, 136, 40), "Wrap": (112, 28, 30),
    "FeatherRed": (222, 46, 36), "FeatherOrange": (255, 128, 30), "FeatherYellow": (255, 212, 70),
    "Flame": (255, 236, 150), "Head": (255, 160, 40), "Beak": (255, 222, 120),
    "Eye": (30, 18, 18), "EyeWhite": (255, 250, 240), "Ruby": (214, 20, 56),
}
MATS = {}
for name, rgb in COLORS.items():
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    col = tuple(lin(v) for v in rgb) + (1.0,)
    next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED").inputs["Base Color"].default_value = col
    m.diffuse_color = col
    MATS[name] = m

BM = {}
MODEL = "X"
def target(mat):
    assert mat in COLORS, mat
    return BM.setdefault((MODEL, mat), bmesh.new())

def xf(loc=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1)):
    S = Matrix.Diagonal((scale[0], scale[1], scale[2], 1.0))
    return Matrix.Translation(Vector(loc)) @ Euler(tuple(math.radians(a) for a in rot), 'XYZ').to_matrix().to_4x4() @ S

def smooth(verts):
    for v in verts:
        for f in v.link_faces:
            f.smooth = True

def sph(mat, scale, loc, rot=(0, 0, 0), seg=14, rings=9):
    if isinstance(scale, (int, float)):
        scale = (scale, scale, scale)
    r = bmesh.ops.create_uvsphere(target(mat), u_segments=seg, v_segments=rings, radius=1.0, matrix=xf(loc, rot, scale))
    smooth(r["verts"])

def cyl(mat, r1, r2, depth, loc, rot=(0, 0, 0), seg=14):
    r = bmesh.ops.create_cone(target(mat), cap_ends=True, cap_tris=False, segments=seg, radius1=r1, radius2=max(r2, 0.0001),
                              depth=depth, matrix=xf(loc, rot))
    for v in r["verts"]:
        for f in v.link_faces:
            if len(f.verts) == 4:
                f.smooth = True

def frame(t, normal):
    a = t.cross(normal)
    if a.length < 1e-5:
        a = t.cross(Vector((0, 1, 0)) if abs(t.y) < 0.9 else Vector((1, 0, 0)))
    a.normalize()
    b = a.cross(t).normalized()
    return a, b

def tube(mat, pts, radii, seg=10, closed=False, caps=True, normal=(0, 0, 1), flat=1.0):
    """Sweep an ellipse along a polyline. radii = width per point; flat = thickness / width (1 = round)."""
    bm = target(mat)
    pts = [Vector(p) for p in pts]
    n = len(pts)
    if isinstance(radii, (int, float)):
        radii = [radii] * n
    nv = Vector(normal).normalized()
    rings = []
    for i, p in enumerate(pts):
        if closed:
            t = pts[(i + 1) % n] - pts[(i - 1) % n]
        else:
            t = pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]
        t.normalize()
        a, b = frame(t, nv)
        w = radii[i]
        th = max(w * flat, 0.006) if flat < 1 else w
        rings.append([bm.verts.new(p + a * (math.cos(2 * math.pi * k / seg) * w) + b * (math.sin(2 * math.pi * k / seg) * th)) for k in range(seg)])
    faces = []
    for i in range(n if closed else n - 1):
        r0, r1 = rings[i], rings[(i + 1) % n]
        for k in range(seg):
            f = bm.faces.new((r0[k], r0[(k + 1) % seg], r1[(k + 1) % seg], r1[k]))
            f.smooth = True
            faces.append(f)
    if caps and not closed:
        faces.append(bm.faces.new(list(reversed(rings[0]))))
        faces.append(bm.faces.new(rings[-1]))
    bmesh.ops.recalc_face_normals(bm, faces=faces)

def bez(p0, p1, p2, n):
    p0, p1, p2 = Vector(p0), Vector(p1), Vector(p2)
    return [(1 - t) ** 2 * p0 + 2 * (1 - t) * t * p1 + t * t * p2 for t in [i / (n - 1) for i in range(n)]]

def feather(mat, p0, p1, p2, width, normal, n=9, flat=0.22, curl=None):
    """Flame-shaped feather: thin at the base, widest at ~40%, pointed tip; optional curl = extra end offset."""
    pts = bez(p0, p1, p2, n)
    width *= 1.35
    if curl:
        curl = Vector(curl) * 0.45
        end = Vector(p2)
        d = (end - Vector(p1)).normalized()
        pts += [end + d * 0.06 + Vector(curl) * 0.5, end + d * 0.08 + Vector(curl)]
    m = len(pts)
    prof = []
    for i in range(m):
        u = i / (m - 1)
        prof.append(width * max(0.08, math.sin(math.pi * min(1.0, u * 1.25) ** 0.8) * (1 - 0.85 * u)))
    prof[-1] = 0.004
    tube(mat, pts, prof, seg=8, normal=normal, flat=flat)

def ring(mat, z, r, thick, center=(0, 0), axis_normal=(0, 0, 1), seg=16):
    pts = [(center[0] + r * math.cos(2 * math.pi * k / seg), center[1] + r * math.sin(2 * math.pi * k / seg), z) for k in range(seg)]
    tube(mat, pts, thick, seg=6, closed=True, caps=False)

def helix(mat, z0, z1, r0, r1, turns, thick, phase=0.0, n=60):
    pts = []
    for i in range(n):
        u = i / (n - 1)
        a = phase + 2 * math.pi * turns * u
        r = r0 + (r1 - r0) * u
        pts.append((r * math.cos(a), r * math.sin(a), z0 + (z1 - z0) * u))
    tube(mat, pts, thick, seg=6)

# =================================================================== 1) PhoenixRod
MODEL = "PhoenixRod"
POLE_R = lambda z: 0.068 + (0.026 - 0.068) * (z - 1.0) / (5.5 - 1.0)

# butt: ruby in a gold knob + short tail plumes (kept short so they do not hit the leg)
sph("Gold", (0.12, 0.12, 0.1), (0, 0, -0.5))
sph("Ruby", 0.06, (0, 0, -0.6), seg=10, rings=7)
cyl("GoldDark", 0.135, 0.125, 0.06, (0, 0, -0.42))
for sx, col, L in ((0.0, "FeatherRed", 0.62), (0.32, "FeatherOrange", 0.5), (-0.32, "FeatherOrange", 0.5), (0.16, "FeatherYellow", 0.36), (-0.16, "FeatherYellow", 0.36)):
    d = Vector((sx, -0.35, -1.0)).normalized()
    p0 = Vector((0, -0.02, -0.55))
    feather(col, p0, p0 + d * L * 0.5 + Vector((sx * 0.1, -0.05, 0)), p0 + d * L, 0.085 if col == "FeatherRed" else 0.07,
            normal=(0, 1, 0.3), curl=(sx * 0.12, 0.1, 0.02))

# grip: wrapped red handle with a gold spiral thread
cyl("Wrap", 0.115, 0.105, 0.98, (0, 0, 0.07), seg=16)
helix("Gold", -0.38, 0.52, 0.113, 0.104, 5, 0.012)
cyl("GoldDark", 0.125, 0.125, 0.05, (0, 0, 0.58), seg=16)
cyl("Gold", 0.12, 0.085, 0.12, (0, 0, 0.66), seg=16)

# reel (underside -Y): gold drum, red side plates, flame knob
REEL = Vector((0, -0.2, 0.82))
cyl("GoldDark", 0.035, 0.035, 0.16, (0, -0.1, 0.82), rot=(90, 0, 0), seg=8)       # stem
cyl("Gold", 0.16, 0.16, 0.12, REEL, rot=(0, 90, 0), seg=18)                        # drum
cyl("PoleRed", 0.17, 0.17, 0.025, REEL + Vector((0.07, 0, 0)), rot=(0, 90, 0), seg=18)
cyl("PoleRed", 0.17, 0.17, 0.025, REEL + Vector((-0.07, 0, 0)), rot=(0, 90, 0), seg=18)
# 2026-11-19 (user): gold phoenix in relief on BOTH side plates. Disc coords: d = along Blender Y (sideways on the disc),
#   h = along Blender Z (toward the rod tip = the bird's "up"). The ruby in the middle is the bird's body.
PLATE_FACE = 0.07 + 0.0125
def P(s, d, h, lift=0.008):
    return REEL + Vector((s * (PLATE_FACE + lift), d, h))
for s in (1, -1):
    cyl("Ruby", 0.042, 0.034, 0.03, REEL + Vector((s * 0.09, 0, 0)), rot=(0, 90, 0), seg=10)       # body gem
    sph("Gold", (0.013, 0.036, 0.036), P(s, 0, 0.085))                                            # head
    cyl("GoldDark", 0.015, 0.0, 0.045, P(s, 0, 0.138), seg=6)                                      # beak (points to the tip)
    sph("Ruby", (0.007, 0.009, 0.009), P(s, 0.014, 0.092, 0.017), seg=6, rings=4)                 # eye
    feather("Gold", P(s, 0, 0.055), P(s, 0, 0.04), P(s, 0, 0.03), 0.03, normal=(1, 0, 0), n=4, flat=0.4)  # neck
    for dd, L in ((-0.012, 0.06), (0.012, 0.045)):                                                # crest
        feather("Gold", P(s, dd, 0.1), P(s, dd - 0.02, 0.125), P(s, dd - 0.045, 0.1 + L), 0.014, normal=(1, 0, 0), n=6, flat=0.4)
    for w in (1, -1):                                                                             # raised wings
        for k, (th, L, w0, mat) in enumerate(((22, 0.13, 0.026, "Gold"), (45, 0.145, 0.03, "Gold"), (70, 0.145, 0.03, "GoldDark"), (98, 0.13, 0.026, "Gold"))):
            a = math.radians(th)
            start = (w * 0.035, 0.03 - 0.012 * k)
            end = (w * L * math.sin(a), L * math.cos(a))
            ctrl = ((start[0] + end[0]) * 0.5 + w * 0.012, (start[1] + end[1]) * 0.5 - 0.02)
            feather(mat, P(s, *start), P(s, *ctrl), P(s, *end), w0, normal=(1, 0, 0), n=8, flat=0.4)
        for th, L in ((150, 0.13), (170, 0.14)):                                                   # tail plumes
            a = math.radians(th)
            feather("GoldDark", P(s, w * 0.01, -0.035), P(s, w * 0.05, -0.075), P(s, w * L * math.sin(a), L * math.cos(a)), 0.024,
                    normal=(1, 0, 0), n=7, flat=0.4)
    spiral = []
    for i in range(14):                                                                           # curled centre tail
        u = i / 13
        ang = math.radians(90 + 330 * u)
        rad = 0.045 * (1 - 0.6 * u)
        spiral.append(P(s, -rad * math.cos(ang) * 0.9, -0.085 - 0.0 * u + rad * (math.sin(ang) - 1)))
    tube("Gold", spiral, [0.009 * (1 - 0.5 * i / 13) for i in range(14)], seg=6, normal=(1, 0, 0), flat=0.7)
    rim = [P(s, 0.158 * math.cos(2 * math.pi * i / 28), 0.158 * math.sin(2 * math.pi * i / 28)) for i in range(28)]
    tube("Gold", rim, [0.007] * 28, seg=5, closed=True, caps=False)                               # gold rim
    for i in range(12):                                                                           # feather-tip notches
        a = 2 * math.pi * i / 12 + 0.26
        c, sn = math.cos(a), math.sin(a)
        sph("GoldDark", (0.008, 0.012, 0.012), P(s, 0.168 * c, 0.168 * sn, 0.004), seg=6, rings=4)
# crank (+X side): gold arm with a feather vane, fire-egg knob with a little flame
tube("GoldDark", [REEL + Vector((0.1, 0, 0)), REEL + Vector((0.14, -0.08, 0.06)), REEL + Vector((0.15, -0.16, 0.1))], 0.016, seg=6)
feather("Gold", REEL + Vector((0.115, -0.02, 0.0)), REEL + Vector((0.15, -0.07, 0.09)), REEL + Vector((0.155, -0.15, 0.13)), 0.03,
        normal=(1, 0, 0), n=7, flat=0.3)
KNOB = REEL + Vector((0.16, -0.19, 0.12))
sph("FeatherRed", (0.035, 0.035, 0.045), KNOB)
sph("PoleGold", (0.036, 0.036, 0.03), KNOB + Vector((0, 0, 0.018)))
feather("Flame", KNOB + Vector((0, 0, 0.04)), KNOB + Vector((0, -0.01, 0.07)), KNOB + Vector((0.01, -0.02, 0.11)), 0.02, normal=(1, 0, 0), n=6, flat=0.5)

# pole: red -> orange -> gold, tapering, gold collars between colours
for z0, z1, col in ((0.72, 2.6, "PoleRed"), (2.6, 4.1, "PoleOrange"), (4.1, 5.45, "PoleGold")):
    zc = (z0 + z1) / 2
    cyl(col, POLE_R(max(z0, 1.0)), POLE_R(z1), z1 - z0, (0, 0, zc), seg=12)
for z in (2.6, 4.1):
    cyl("Gold", POLE_R(z) + 0.022, POLE_R(z) + 0.022, 0.07, (0, 0, z), seg=12)
# flame ribbon spiralling up the pole
helix("Flame", 1.35, 4.9, 0.1, 0.05, 2.5, 0.016, phase=0.3)
# line guides on top (+Y)
for z in (1.9, 2.9, 3.8, 4.6, 5.2):
    r = POLE_R(z)
    cyl("GoldDark", 0.01, 0.01, 0.07, (0, r + 0.03, z), rot=(90, 0, 0), seg=6)
    pts = [(0.03 * math.cos(2 * math.pi * k / 12), r + 0.08, z + 0.03 * math.sin(2 * math.pi * k / 12)) for k in range(12)]
    tube("Gold", pts, 0.008, seg=5, closed=True, caps=False)

# wings at the fore-grip (2026-11-19 detail pass, user picked "A"): 3 rows like a real wing, visible from above AND below.
#   primaries (long, red body + orange flame tip) / secondaries on top (orange + yellow tip) / under-coverts below (yellow + orange tip)
#   / short gold-yellow top coverts. Every long feather has a gold shaft on both faces. Gold "wing bone" on the leading edge.
WING = 1.12
def wing_profile(w, m):
    prof = [w * max(0.1, math.sin(math.pi * min(1.0, (i / (m - 1)) * 1.25) ** 0.8) * (1 - 0.85 * i / (m - 1))) for i in range(m)]
    prof[-1] = 0.004
    return prof
def wing_feather(body, tip, p0, p1, p2, w, curl=None, shaft=True, flat=0.22, n=10):
    pts = bez(p0, p1, p2, n)
    if curl:
        e = Vector(p2); d = (e - Vector(p1)).normalized(); c = Vector(curl)
        pts += [e + d * 0.05 + c * 0.5, e + d * 0.07 + c]
    m = len(pts)
    prof = wing_profile(w, m)
    cut, tip0 = int(m * 0.62), int(m * 0.46)
    bp = prof[:cut + 1]; bp[-1] = max(0.006, bp[-1] * 0.35)
    tube(body, pts[:cut + 1], bp, seg=6, normal=(0, 1, 0), flat=flat)              # red/orange body, ends inside the tip piece
    tp = [r * 0.97 for r in prof[tip0:]]; tp[0] = max(0.006, tp[0] * 0.5)
    tube(tip, pts[tip0:], tp, seg=6, normal=(0, 1, 0), flat=flat * 1.08)          # flame-coloured tip
    if shaft:
        nv = Vector((0, 1, 0))
        for side in (1, -1):
            sp, sr = [], []
            for i in range(1, int(m * 0.8)):
                t = (pts[min(i + 1, m - 1)] - pts[i - 1]).normalized()
                a = t.cross(nv).normalized()
                b = a.cross(t).normalized()
                th = max(prof[i] * flat * (1.08 if i >= tip0 else 1.0), 0.006)
                sp.append(pts[i] + b * side * (th + 0.002))
                sr.append(0.0065 * (1 - 0.6 * i / m))
            tube("Gold", sp, sr, seg=3)
for s in (1, -1):
    base = Vector((s * 0.07, 0.02, WING))
    def dirv(ang):
        a = math.radians(ang)
        return Vector((s * math.cos(a), 0.0, -math.sin(a)))
    # primaries
    for ang, L in ((10, 0.98), (24, 1.05), (38, 1.02), (52, 0.95), (66, 0.84), (80, 0.7)):
        d = dirv(ang)
        p0 = base
        wing_feather("FeatherRed", "FeatherOrange" if ang % 28 else "FeatherYellow", p0, p0 + d * L * 0.5 + Vector((0, 0.04, 0.06)),
                     p0 + d * L + Vector((0, 0.12, 0.1)), 0.13, curl=(0, 0.06, 0.05))
    # secondaries on top
    for ang, L in ((17, 0.68), (31, 0.72), (45, 0.7), (59, 0.64), (73, 0.55)):
        d = dirv(ang)
        p0 = base + Vector((0, 0.04, -0.02))
        wing_feather("FeatherOrange", "FeatherYellow", p0, p0 + d * L * 0.5 + Vector((0, 0.05, 0.05)), p0 + d * L + Vector((0, 0.15, 0.08)), 0.11)
    # under-coverts below (seen when the rod is held up)
    for ang, L in ((20, 0.58), (38, 0.6), (56, 0.55), (74, 0.46)):
        d = dirv(ang)
        p0 = base + Vector((0, -0.035, -0.02))
        wing_feather("FeatherYellow", "FeatherOrange", p0, p0 + d * L * 0.5 + Vector((0, -0.01, 0.04)), p0 + d * L + Vector((0, 0.06, 0.07)), 0.1)
    # short top coverts (no shaft)
    for ang, L in ((14, 0.38), (32, 0.4), (50, 0.38), (68, 0.32)):
        d = dirv(ang)
        p0 = base + Vector((0, 0.07, -0.01))
        wing_feather("FeatherYellow", "Gold", p0, p0 + d * L * 0.5 + Vector((0, 0.03, 0.03)), p0 + d * L + Vector((0, 0.08, 0.05)), 0.09, shaft=False)
    # small flame licks between primaries
    for ang in (31, 59):
        d = dirv(ang)
        p0 = base + d * 0.55 + Vector((0, 0.09, 0.07))
        feather("Flame", p0, p0 + d * 0.12 + Vector((0, 0.05, 0.04)), p0 + d * 0.2 + Vector((0, 0.1, 0.12)), 0.025, normal=(0, 1, 0), n=6, flat=0.5)
    # gold wing bone on the leading edge + ruby beads
    bone = bez(base + Vector((0, 0.05, 0.02)), base + dirv(4) * 0.3 + Vector((0, 0.1, 0.07)), base + dirv(10) * 0.62 + Vector((0, 0.13, 0.1)), 9)
    tube("Gold", bone, [0.024 * (1 - 0.6 * i / 8) for i in range(9)], seg=6)
    for i in (3, 6):
        sph("Ruby", 0.018, bone[i] + Vector((0, 0.018, 0)), seg=8, rings=5)
    sph("FeatherRed", (0.1, 0.07, 0.12), base + Vector((-s * 0.03, 0.0, 0.0)))   # wing root
    sph("Ruby", (0.02, 0.035, 0.035), base + Vector((s * 0.06, 0.02, 0.0)), seg=8, rings=6)   # root gem
sph("Ruby", (0.06, 0.04, 0.06), (0, 0.075, WING), seg=10, rings=7)               # gem on top of the wing root
ring("Gold", WING, POLE_R(1.0) + 0.04, 0.02)

# phoenix head at the tip (beak = rod tip)
HEAD = Vector((0, 0.03, 5.6))
sph("Head", (0.16, 0.16, 0.18), HEAD)
cyl("Beak", 0.06, 0.0, 0.24, HEAD + Vector((0, -0.02, 0.24)), seg=10)
sph("FeatherYellow", (0.11, 0.1, 0.08), HEAD + Vector((0, -0.07, 0.07)))        # cheek / throat
for s in (1, -1):
    sph("EyeWhite", (0.035, 0.05, 0.05), HEAD + Vector((s * 0.125, 0.04, 0.06)), seg=10, rings=7)
    sph("Eye", (0.03, 0.035, 0.035), HEAD + Vector((s * 0.145, 0.045, 0.07)), seg=8, rings=6)
# crest: 3 flame feathers sweeping up and back
for k, (dx, col, L) in enumerate(((0.0, "FeatherRed", 0.75), (0.07, "FeatherOrange", 0.6), (-0.07, "FeatherOrange", 0.6))):
    p0 = HEAD + Vector((dx, 0.12, 0.02))
    feather(col, p0, p0 + Vector((dx, 0.25, -0.05)), p0 + Vector((dx * 2, 0.3 + 0.1 * (k == 0), -L * 0.6)), 0.075, normal=(1, 0, 0),
            curl=(0, 0.08, 0.02))
feather("Flame", HEAD + Vector((0, 0.14, 0.0)), HEAD + Vector((0, 0.28, -0.02)), HEAD + Vector((0, 0.34, -0.2)), 0.045, normal=(1, 0, 0), flat=0.4)
# neck ruff
for k in range(8):
    a = 2 * math.pi * k / 8
    d = Vector((math.cos(a), math.sin(a), 0))
    p0 = Vector((0, 0.02, 5.48)) + d * 0.08
    feather("FeatherRed" if k % 2 == 0 else "FeatherOrange", p0, p0 + d * 0.1 + Vector((0, 0, -0.1)), p0 + d * 0.16 + Vector((0, 0, -0.32)), 0.06,
            normal=Vector((-d.y, d.x, 0)), n=7)

# =================================================================== 2) PhoenixBobber (fire egg)
MODEL = "PhoenixBobber"
EGG = Vector((0, 0, 0.16))
sph("FeatherRed", (0.19, 0.19, 0.24), EGG, seg=18, rings=12)
# gold upper shell (slightly larger cap) + orange flame band
sph("PoleGold", (0.195, 0.195, 0.2), EGG + Vector((0, 0, 0.07)), seg=18, rings=12)
for k in range(9):
    a = 2 * math.pi * k / 9
    d = Vector((math.cos(a), math.sin(a), 0))
    p0 = EGG + d * 0.185 + Vector((0, 0, -0.06))
    feather("FeatherOrange", p0, p0 + d * 0.03 + Vector((0, 0, 0.08)), p0 + d * 0.01 + Vector((0, 0, 0.18)), 0.06,
            normal=d, n=7, flat=0.3)
ring("Gold", 0.1, 0.197, 0.014, seg=20)
for k in range(4):
    a = 2 * math.pi * k / 4 + 0.4
    sph("Ruby", (0.03, 0.03, 0.03), (0.198 * math.cos(a), 0.198 * math.sin(a), 0.1), seg=8, rings=6)
# flame crest on top
TOP = EGG + Vector((0, 0, 0.25))
for k, (dx, dy, col, L) in enumerate(((0, 0, "FeatherYellow", 0.28), (0.07, 0.02, "FeatherOrange", 0.2), (-0.07, 0.02, "FeatherOrange", 0.2),
                                       (0.0, -0.07, "FeatherRed", 0.18), (0.0, 0.08, "FeatherRed", 0.18))):
    p0 = TOP + Vector((dx * 0.4, dy * 0.4, -0.03))
    feather(col, p0, p0 + Vector((dx, dy, L * 0.5)), p0 + Vector((dx * 1.6, dy * 1.6, L)), 0.06, normal=(1, 0, 0) if dy == 0 else (0, 1, 0),
            n=7, flat=0.45, curl=(dx * 0.4, dy * 0.4, 0.02))
feather("Flame", TOP + Vector((0, 0, -0.02)), TOP + Vector((0, 0, 0.12)), TOP + Vector((0.02, 0, 0.22)), 0.035, normal=(1, 0, 0), n=6, flat=0.6)

# ------------------------------------------------------------------ build + export (one GLB per model)
by_model = {}
for (model, mat), bm in BM.items():
    me = bpy.data.meshes.new(model + "__" + mat)
    bm.to_mesh(me)
    bm.free()
    me.materials.append(MATS[mat])
    ob = bpy.data.objects.new(model + "__" + mat, me)
    bpy.context.scene.collection.objects.link(ob)
    by_model.setdefault(model, []).append(ob)

scn = bpy.context.scene
try:
    scn.render.engine = 'BLENDER_WORKBENCH'
except TypeError as e:
    print("engine", e)
scn.display.shading.light = 'STUDIO'
scn.display.shading.color_type = 'MATERIAL'
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
scn.collection.objects.link(cam)
scn.camera = cam

VIEWS = {"PhoenixRod": [("side", Vector((1.0, -0.35, 0.15))), ("top", Vector((0.25, 1.0, 0.35)))],
         "PhoenixBobber": [("side", Vector((0.8, -1.0, 0.45)))]}
for model, objs in by_model.items():
    tri = 0
    for ob in objs:
        ob.data.calc_loop_triangles()
        tri += len(ob.data.loop_triangles)
    allv = [v.co for ob in objs for v in ob.data.vertices]
    lo = Vector(tuple(min(c[k] for c in allv) for k in range(3)))
    hi = Vector(tuple(max(c[k] for c in allv) for k in range(3)))
    for ob in objs:
        print("  OBJ", ob.name, len(ob.data.loop_triangles))
    print("MODEL", model, "OBJECTS", len(objs), "TRIS", tri, "BBOX_MIN", tuple(round(v, 3) for v in lo), "BBOX_MAX", tuple(round(v, 3) for v in hi))
    bpy.ops.object.select_all(action='DESELECT')
    for o in bpy.data.objects:
        o.hide_render = o not in objs and o is not cam
    for ob in objs:
        ob.select_set(True)
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, model + ".glb"), export_format='GLB',
                              use_selection=True, export_apply=True, export_yup=True)
    size = (hi - lo).length
    mid = (lo + hi) / 2
    for vname, vdir in VIEWS[model]:
        scn.render.resolution_x, scn.render.resolution_y = (700, 1000) if model == "PhoenixRod" else (800, 800)
        cam.data.lens = 40
        cam.location = mid + vdir.normalized() * size * 1.25
        cam.rotation_euler = (mid - cam.location).to_track_quat('-Z', 'Y').to_euler()
        scn.render.filepath = os.path.join(OUT, "preview_%s_%s.png" % (model, vname))
        bpy.ops.render.render(write_still=True)

# close-up of the reel (bird relief) for checking
for o in bpy.data.objects:
    o.hide_render = not (o.name.startswith("PhoenixRod__") or o is cam)
for vname, vdir, focus, dist in (("reel_out", Vector((1.0, -0.25, 0.1)), REEL, 1.1), ("reel_in", Vector((-1.0, -0.25, 0.1)), REEL, 1.1),
                                 ("wing_top", Vector((0.15, 1.0, 0.35)), Vector((0, 0.05, 0.8)), 3.4), ("wing_under", Vector((0.15, -1.0, 0.25)), Vector((0, 0.05, 0.8)), 3.4)):
    scn.render.resolution_x, scn.render.resolution_y = 800, 800
    cam.data.lens = 50
    cam.location = focus + vdir.normalized() * dist
    cam.rotation_euler = (focus - cam.location).to_track_quat('-Z', 'Y').to_euler()
    scn.render.filepath = os.path.join(OUT, "preview_PhoenixRod_%s.png" % vname)
    bpy.ops.render.render(write_still=True)
