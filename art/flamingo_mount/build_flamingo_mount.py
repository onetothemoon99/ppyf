# Long-Legged Flamingo mount (ฟลามิงโกขายาว, MountId LongLegFlamingo) 2026-11-21. Plan: FLAMINGO_MOUNT.md
# Round 3 (2026-11-21): user's text: downy pale-pink body, darker pink face, pink/pale-blue/white wings, leather straps + pouches.
# Round 2 (2026-11-21): rebuilt from the user's picture (slim cream bird, raised wings, blanket + steel saddle, purple lantern).
# Run:  blender.exe -b --factory-startup -P build_flamingo_mount.py -- <outdir>
# Units: 1 Blender unit = 1 stud. Origin = ground under the saddle (= MountRoot). Head faces Blender +Y
#   (export_yup turns +Y into glTF -Z = Roblox forward). Up = +Z.
# Separate models so MountFx can move them: FlamingoBody (body, neck, head, tail), FlamingoLegL/R (pivot at the hip),
#   FlamingoWingL/R (pivot at the shoulder). Pivot points are printed as PIVOT lines for the Studio Hinge attributes.
# Objects are named "<Model>__<Material>"; Studio colours them from COLORS (the importer drops colours).
# "RiderRef" (grey seated figure) is only for the previews and is NOT exported.
# Output: Flamingo*.glb + preview_*.png
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
    "Cream": (255, 218, 222), "CreamWhite": (255, 240, 240), "PinkPale": (255, 200, 208), "FacePink": (240, 135, 160), "PaleBlue": (185, 215, 242),
    "Leather": (125, 80, 50), "LeatherDark": (90, 55, 35), "PinkWing": (250, 165, 182),
    "Coral": (240, 118, 140), "LegPink": (240, 170, 182), "Foot": (245, 190, 200), "Nail": (185, 215, 242),
    "BeakPink": (245, 175, 190), "BeakTip": (40, 34, 42), "Eye": (22, 20, 28), "EyeDark": (95, 30, 40), "PinkDeepLid": (220, 120, 145), "Shine": (255, 255, 255),
    "Navy": (45, 62, 120), "Orange": (232, 135, 55), "Teal": (60, 172, 182), "Gold": (245, 200, 80),
    "Steel": (72, 76, 88), "SteelLight": (150, 155, 168), "LanternGlass": (170, 110, 235),
    "Ref": (150, 150, 160),
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

def sph(mat, scale, loc, rot=(0, 0, 0), seg=20, rings=12):
    if isinstance(scale, (int, float)):
        scale = (scale, scale, scale)
    r = bmesh.ops.create_uvsphere(target(mat), u_segments=seg, v_segments=rings, radius=1.0, matrix=xf(loc, rot, scale))
    smooth(r["verts"])

def frame(t, normal):
    a = t.cross(normal)
    if a.length < 1e-5:
        a = t.cross(Vector((0, 1, 0)) if abs(t.y) < 0.9 else Vector((1, 0, 0)))
    a.normalize()
    b = a.cross(t).normalized()
    return a, b

def tube(mat, pts, radii, seg=14, caps=True, normal=(1, 0, 0), flat=1.0):
    """Sweep an ellipse along a polyline. radii = width per point; flat = thickness / width (1 = round)."""
    bm = target(mat)
    pts = [Vector(p) for p in pts]
    n = len(pts)
    if isinstance(radii, (int, float)):
        radii = [radii] * n
    nv = Vector(normal).normalized()
    rings = []
    for i, p in enumerate(pts):
        t = pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]
        t.normalize()
        a, b = frame(t, nv)
        w = radii[i]
        th = max(w * flat, 0.006) if flat < 1 else w
        rings.append([bm.verts.new(p + a * (math.cos(2 * math.pi * k / seg) * w) + b * (math.sin(2 * math.pi * k / seg) * th)) for k in range(seg)])
    faces = []
    for i in range(n - 1):
        r0, r1 = rings[i], rings[i + 1]
        for k in range(seg):
            f = bm.faces.new((r0[k], r0[(k + 1) % seg], r1[(k + 1) % seg], r1[k]))
            f.smooth = True
            faces.append(f)
    if caps:
        faces.append(bm.faces.new(list(reversed(rings[0]))))
        faces.append(bm.faces.new(rings[-1]))
    bmesh.ops.recalc_face_normals(bm, faces=faces)

def bez(pts, n):
    """Bezier through control points (any count) sampled n times."""
    P = [Vector(p) for p in pts]
    out = []
    for i in range(n):
        t = i / (n - 1)
        Q = P[:]
        while len(Q) > 1:
            Q = [Q[j] * (1 - t) + Q[j + 1] * t for j in range(len(Q) - 1)]
        out.append(Q[0])
    return out

def lerp(a, b, n):
    return [a + (b - a) * (i / (n - 1)) for i in range(n)]

def feather(mat, base, tip, width, normal=(0, 0, 1), n=6, flat=0.3, seg=6):  # round 5: 6x6 (was 10x8) to save triangles
    """Soft rounded feather: thin at base, widest at 45%, round tip."""
    pts = lerp(Vector(base), Vector(tip), n)
    radii = [width * max(0.18, math.sin(math.pi * (0.12 + 0.8 * i / (n - 1)))) for i in range(n)]
    tube(mat, pts, radii, seg=seg, normal=normal, flat=flat)

def fluff(mat, base, direction, length, width, outward, flat=0.3):
    """Low-poly downy feather (8 sides x 6 steps) lying flat on a surface: points along `direction`, flat side faces `outward`."""
    d = Vector(direction).normalized()
    n = 6
    pts = lerp(Vector(base), Vector(base) + d * length, n)
    # downy, softly pointed: widest at 40%, soft tip (round tips looked like fish scales)
    prof = [max(0.12, 0.4 + 0.6 * (u / 0.4) if u < 0.4 else ((1 - u) / 0.6) ** 0.55) for u in [i / (n - 1) for i in range(n)]]
    tube(mat, pts, [width * p for p in prof], seg=6, normal=Vector(outward).normalized(), flat=flat)

import random
RNG = random.Random(21)   # fixed seed: same feathers every build

def ring_frame(axis):
    """Two unit vectors perpendicular to axis (for placing feathers around a tube)."""
    axis = Vector(axis).normalized()
    a = axis.cross(Vector((1, 0, 0)) if abs(axis.x) < 0.9 else Vector((0, 1, 0))).normalized()
    return a, axis.cross(a).normalized()

PIVOTS = {}

# ------------------------------------------------------------------ body + neck + head + tail (round 2: follows the user's picture)
# Picture: slim cream-white bird with a pink tint, long thin S neck, small head, pink beak with black tip bent down,
#   wings raised and spread up/back (pale coverts, pink flight feathers, coral tips), fluffy feathered thighs,
#   colourful blanket (navy/orange/teal) + dark steel saddle, purple lantern on the left side.
MODEL = "FlamingoBody"
C = Vector((0, -0.2, 4.3))
R = Vector((0.92, 1.5, 0.82))
sph("Cream", tuple(R), C)
sph("CreamWhite", (0.78, 1.2, 0.58), C + Vector((0, 0.1, -0.33)))           # soft belly
sph("Cream", (0.62, 0.7, 0.72), C + Vector((0, 1.15, 0.28)))                # chest into the neck
# tail: short pink feathers pointing back
for x, up, w, mat in ((0, 0.25, 0.3, "PinkWing"), (0.3, 0.1, 0.26, "PinkWing"), (-0.3, 0.1, 0.26, "PinkWing"),
                      (0.15, -0.05, 0.22, "Coral"), (-0.15, -0.05, 0.22, "Coral")):
    feather(mat, C + Vector((x * 0.5, -1.25, 0.1)), C + Vector((x, -2.25, 0.1 + up)), w, normal=(0, 0, 1), flat=0.25)
# neck: long thin S from the chest to the head
# Head + beak round 4 (2026-11-21, plan "แผนแก้หัวกับปาก" in FLAMINGO_MOUNT.md): the top of the neck hooks forward like "?",
#   the head is a small cream wedge tilted 25 deg down that grows out of the neck (no ball, no colour seam),
#   the beak is thick with a sharp ~50 deg kink in the middle, pale pink base, black tip, dark mouth line, small dark almond eye.
neck = bez([C + Vector((0, 1.3, 0.45)), C + Vector((0, 2.2, 1.1)), C + Vector((0, 0.7, 2.0)), C + Vector((0, 0.8, 3.2)),
            C + Vector((0, 1.25, 3.45)), C + Vector((0, 1.55, 3.25))], 22)
nr = [0.4 - 0.18 * (i / 21) for i in range(22)]
tube("Cream", neck, nr, seg=16)

# ---- feathers round 5 (2026-11-21, plan "แผนเพิ่มขน" in FLAMINGO_MOUNT.md)
# N2 lower neck: short downy feathers in overlapping rows, pointing down the neck; fewer/shorter going up, upper neck stays smooth
for row, i in enumerate((1, 2, 3, 4, 5, 6, 7)):
    p = neck[i]
    t = (neck[i + 1] - neck[i - 1]).normalized()                  # up the neck
    A, B = ring_frame(t)
    fade = 1 - row / 7
    count = 14 if row < 4 else 10
    for k in range(count):
        ang = 2 * math.pi * (k + 0.5 * (row % 2) + RNG.uniform(-0.2, 0.2)) / count
        out = A * math.cos(ang) + B * math.sin(ang)
        base = p + out * (nr[i] * 0.9)
        ln = (0.22 + 0.2 * fade) * RNG.uniform(0.85, 1.15)
        fluff("CreamWhite" if RNG.random() < 0.3 else "Cream", base, -t + out * (0.12 + 0.1 * fade), ln, 0.1 + 0.04 * fade, out, flat=0.25)
# N1 chest bib: two rings of drooping feathers round the neck base / chest, outer cream, inner pale pink
CH = C + Vector((0, 1.15, 0.28))
for layer, (n_f, z, ln, w, mat) in enumerate(((20, 0.05, 0.6, 0.16, "CreamWhite"), (18, 0.25, 0.45, 0.15, "Cream"), (15, 0.42, 0.32, 0.13, "PinkPale"))):
    for k in range(n_f):
        phi = math.radians(-115 + 230 * (k + 0.5 * layer + RNG.uniform(-0.25, 0.25)) / (n_f - 1))
        out = Vector((math.sin(phi), math.cos(phi), 0.25)).normalized()
        shrink = 1 - 0.12 * layer
        base = CH + Vector((math.sin(phi) * 0.58 * shrink, math.cos(phi) * 0.66 * shrink, z))
        fluff(mat, base, Vector((math.sin(phi) * 0.3, math.cos(phi) * 0.3, -1)), (ln + 0.06 * math.cos(phi)) * RNG.uniform(0.85, 1.15), w, out)
# N3 belly fringe: feather tips hanging along the underside (skips the girth strap at y ~ -0.2)
for sx in (1, -1):
    for y in (-1.0, -0.75, -0.5, 0.1, 0.35, 0.6, 0.85):
        base = Vector((sx * 0.5, y, 3.7 + 0.05 * abs(y)))
        out = Vector((sx, 0, -0.3))
        fluff("CreamWhite" if y > 0 else "Cream", base, Vector((sx * 0.12, -0.2, -1)), 0.4 * RNG.uniform(0.85, 1.1), 0.13, out)
for y in (-0.8, -0.45, 0.25, 0.6):
    fluff("CreamWhite", Vector((0, y, 3.45)), Vector((0, -0.2, -1)), 0.25, 0.14, Vector((0, 0, -1)), flat=0.35)
TILT = math.radians(-25)
F = Vector((0, math.cos(TILT), math.sin(TILT)))          # head forward (points forward-down)
U = Vector((0, -math.sin(TILT), math.cos(TILT)))         # head up
X = Vector((1, 0, 0))
end_dir = (neck[-1] - neck[-3]).normalized()
HEAD = neck[-1] + end_dir * 0.1                           # head centre overlaps the neck tip so it grows out of it
HR = Vector((0.25, 0.34, 0.27))                           # head radii (side, forward, up)
sph("Cream", tuple(HR), HEAD, rot=(-25, 0, 0))
print("HEAD_TOP", tuple(round(c, 3) for c in HEAD + U * HR.z))
# faint pink around the beak base and under the eye
sph("PinkPale", (0.215, 0.12, 0.2), HEAD + F * 0.2, rot=(-25, 0, 0), seg=14, rings=10)
# beak: segment A (thick, forward-down) then a sharp kink, segment B (straight down, tapers to a blunt tip)
def dir_at(deg):
    a = math.radians(deg)
    return Vector((0, math.cos(a), math.sin(a)))
B0 = HEAD + F * 0.22 + U * 0.02
dA, dB = dir_at(-35), dir_at(-85)
K = B0 + dA * 0.6
TIP = K + dB * 0.5
A_pts = lerp(B0, K, 8)
A_rad = [0.21 - 0.05 * (i / 7) for i in range(8)]          # half-height 0.21 -> 0.16 (base ~75% of head height)
FLAT = 0.72                                               # width / height (beak is flat on the sides)
tube("BeakPink", A_pts[:7], A_rad[:7], seg=16, normal=(1, 0, 0), flat=FLAT)
sph("BeakPink", (A_rad[0] * FLAT, 0.13, A_rad[0]), B0, rot=(-35, 0, 0), seg=16, rings=10)   # rounds the flat end into the face
tube("BeakTip", A_pts[6:], A_rad[6:], seg=16, normal=(1, 0, 0), flat=FLAT)  # black starts ~10% before the kink
B_pts = lerp(K, TIP, 6)
B_rad = [0.16, 0.155, 0.15, 0.14, 0.125, 0.105]             # stays broad (picture: blunt, not a spike)
tube("BeakTip", B_pts, B_rad, seg=16, normal=(1, 0, 0), flat=FLAT)
sph("BeakTip", (0.16 * FLAT, 0.17, 0.17), K, seg=16, rings=10)              # fills the outside of the kink
sph("BeakTip", (0.105 * FLAT, 0.1, 0.1), TIP, seg=12, rings=8)            # blunt rounded tip
# (round 4a: a black wedge under the beak and a white skin ring at the base looked like growths -> removed)
# dark mouth line along both sides, base -> kink, at mid height, half sunk into the beak surface
for sx in (1, -1):
    line = []
    for i in range(9):
        t = 0.08 + 0.84 * i / 8
        r = A_rad[0] + (A_rad[-1] - A_rad[0]) * t
        line.append(B0 + dA * (0.6 * t) + X * sx * (r * FLAT * 0.97))
    tube("BeakTip", line, 0.012, seg=6)
# eyes: small dark almonds near the beak base, with a thin pink lid line above
for sx in (1, -1):
    y_off, z_off = 0.08, 0.07
    side = HR.x * max(0.0, 1 - (y_off / HR.y) ** 2 - (z_off / HR.z) ** 2) ** 0.5
    e = HEAD + F * y_off + U * z_off + X * sx * (side - 0.012)
    sph("EyeDark", (0.03, 0.07, 0.045), e, rot=(-25, 0, 0), seg=14, rings=8)
    sph("Eye", (0.02, 0.035, 0.03), e + X * sx * 0.015, rot=(-25, 0, 0), seg=10, rings=6)
    sph("Shine", 0.012, e + X * sx * 0.03 + F * 0.015 + U * 0.012, seg=6, rings=4)
    lid = [e + X * sx * 0.012 + F * (0.08 * math.cos(math.radians(a))) + U * (0.05 * math.sin(math.radians(a)) + 0.005) for a in range(20, 161, 20)]
    tube("PinkDeepLid", lid, 0.012, seg=6)

# blanket: shell over the back with stripes (gold edge / orange / teal / navy middle)
def top_point(theta, y, k):
    s = max(0.0, 1 - ((y - C.y) / R.y) ** 2) ** 0.5
    return Vector((R.x * s * math.sin(theta) * k, y, C.z + R.z * s * math.cos(theta) * k))
BANDS = [(-104, -96, "Gold"), (-96, -70, "Orange"), (-70, -60, "Teal"), (-60, -52, "Navy"), (-52, -46, "Gold"), (-46, 46, "Navy"), (46, 52, "Gold"), (52, 60, "Navy"), (60, 70, "Teal"), (70, 96, "Orange"), (96, 104, "Gold")]
Y0, Y1, NY = -1.15, 0.65, 12
for a0, a1, mat in BANDS:
    bm = target(mat)
    na = max(2, int((a1 - a0) / 4) + 1)
    grid = [[bm.verts.new(top_point(math.radians(a0 + (a1 - a0) * i / (na - 1)), Y0 + (Y1 - Y0) * j / (NY - 1), 1.05))
             for j in range(NY)] for i in range(na)]
    fs = []
    for i in range(na - 1):
        for j in range(NY - 1):
            f = bm.faces.new((grid[i][j], grid[i + 1][j], grid[i + 1][j + 1], grid[i][j + 1]))
            f.smooth = True
            fs.append(f)
    bmesh.ops.recalc_face_normals(bm, faces=fs)
    bmesh.ops.solidify(bm, geom=fs, thickness=0.06)
# little gold pattern dots on the orange bands
for sx in (1, -1):
    for y in (-0.8, -0.45, -0.1, 0.25):
        for ang in (78, 88):
            p = top_point(math.radians(sx * ang), y + (0.17 if ang == 88 else 0), 1.09)
            sph("Gold" if ang == 78 else "Teal", (0.07, 0.07, 0.07), p, seg=8, rings=6)
# steel saddle: seat, front horn, back cantle, side plates with bolts
SEAT_Y = -0.35
top = top_point(0, SEAT_Y, 1.05).z
sph("Steel", (0.62, 0.72, 0.2), (0, SEAT_Y, top + 0.1))
def bolster(y, h, r):
    pts = [Vector((0.45 * math.sin(a), y, top + 0.12 + h * math.cos(a))) for a in [math.radians(v) for v in range(-80, 81, 10)]]
    tube("Steel", pts, r, seg=12)
bolster(SEAT_Y - 0.62, 0.42, 0.15)      # back (cantle)
bolster(SEAT_Y + 0.6, 0.3, 0.13)        # front (pommel)
sph("SteelLight", 0.1, (0, SEAT_Y + 0.6, top + 0.47), seg=10, rings=8)
sph("SteelLight", 0.1, (0, SEAT_Y - 0.62, top + 0.59), seg=10, rings=8)
for sx in (1, -1):
    sph("Steel", (0.08, 0.42, 0.3), top_point(math.radians(sx * 50), SEAT_Y, 1.12), rot=(0, sx * 40, 0))
    for dy in (-0.22, 0.22):
        sph("SteelLight", 0.05, top_point(math.radians(sx * 50), SEAT_Y + dy, 1.2), seg=8, rings=6)
# leather girth strap under the belly with gold buckles (a breast strap was tried and looked like a stick on the chest)
tube("Leather", [top_point(math.radians(a), SEAT_Y + 0.15, 1.07) for a in range(95, 266, 10)], 0.09, seg=8, flat=0.4, normal=(0, 1, 0))
for sx in (1, -1):
    b = top_point(math.radians(sx * 100), SEAT_Y + 0.15, 1.1)
    sph("Gold", (0.07, 0.1, 0.1), b, seg=8, rings=6)
# pouches: a big one on the RIGHT flank, a small one on the left behind the lantern
def pouch(sx, y, w, h, d):
    c = top_point(math.radians(sx * 88), y, 1.14)
    sph("Leather", (d, w, h), c, seg=14, rings=10)
    sph("LeatherDark", (d * 1.08, w * 1.02, h * 0.45), c + Vector((sx * 0.02, 0, h * 0.62)), seg=14, rings=8)   # flap
    sph("Gold", 0.05, c + Vector((sx * d * 1.02, 0, h * 0.25)), seg=8, rings=6)                              # clasp
pouch(1, -0.5, 0.38, 0.32, 0.17)
pouch(-1, -0.75, 0.25, 0.22, 0.13)
# purple lantern hanging on the LEFT side (Roblox left = -X), in front of the rider's leg
hook = top_point(math.radians(-62), 0.35, 1.12)
lan = hook + Vector((-0.12, 0.05, -0.75))
tube("Steel", [hook, hook + Vector((-0.1, 0.02, -0.3)), lan + Vector((0, 0, 0.42))], 0.03, seg=6)
sph("Steel", (0.17, 0.17, 0.06), lan + Vector((0, 0, 0.34)), seg=10, rings=6)
bmesh.ops.create_cone(target("Steel"), cap_ends=True, segments=10, radius1=0.17, radius2=0.04, depth=0.16, matrix=xf(lan + Vector((0, 0, 0.42))))
bmesh.ops.create_cone(target("LanternGlass"), cap_ends=True, segments=12, radius1=0.15, radius2=0.15, depth=0.5, matrix=xf(lan + Vector((0, 0, 0.06))))
for ang in range(0, 360, 90):
    d = Vector((math.cos(math.radians(ang + 45)), math.sin(math.radians(ang + 45)), 0)) * 0.155
    tube("Steel", [lan + d + Vector((0, 0, -0.2)), lan + d + Vector((0, 0, 0.32))], 0.022, seg=5)
sph("Steel", (0.17, 0.17, 0.06), lan + Vector((0, 0, -0.22)), seg=10, rings=6)
PIVOTS["Lantern"] = lan + Vector((0, 0, 0.06))

# ------------------------------------------------------------------ wings: raised and spread up/back (pivot = shoulder)
for side, sx in (("L", -1), ("R", 1)):   # Roblox left = -X (Blender X stays X)
    MODEL = "FlamingoWing" + side
    sh = C + Vector((sx * 0.72, -0.35, 0.5))
    PIVOTS[MODEL] = sh
    wrist = sh + Vector((sx * 0.5, -0.55, 1.15))
    tip = sh + Vector((sx * 0.85, -1.75, 2.25))
    edge = bez([sh, wrist, tip], 16)
    tube("Cream", edge, [0.2 - 0.12 * (i / 15) for i in range(16)], seg=10)
    nrm = (1, 0, 0)
    # flight feathers: inner ones hang back/down, outer ones (primaries) sweep back and a little up
    n = 18
    for i in range(n):
        t = i / (n - 1)
        p = edge[min(15, int(round(t * 15)))]
        L = 1.05 + 1.0 * t
        d = Vector((sx * 0.06, -0.7 - 0.2 * t, -0.75 + 0.95 * t)).normalized()
        feather("PaleBlue" if t > 0.85 else ("Coral" if t > 0.55 else "PinkWing"), p, p + d * L, 0.24 + 0.04 * t, normal=nrm, flat=0.2)
    # pale coverts over the feather roots (three rows, shortest on top)
    for row, (ln, w, mat) in enumerate(((0.8, 0.22, "PinkWing"), (0.6, 0.2, "PaleBlue"), (0.38, 0.18, "CreamWhite"))):
        for i in range(12):
            t = i / 11
            p = edge[min(15, int(round(t * 13)))] + Vector((sx * (0.04 + 0.035 * row), 0, 0))
            d = Vector((0, -0.7 - 0.2 * t, -0.75 + 0.8 * t)).normalized()
            feather(mat, p, p + d * (ln + 0.3 * t), w, normal=nrm, flat=0.25)

# ------------------------------------------------------------------ legs (pivot = hip). Joint juts BACK like a real flamingo.
for side, sx in (("L", -1), ("R", 1)):
    MODEL = "FlamingoLeg" + side
    hip = C + Vector((sx * 0.42, -0.05, -0.45))
    knee = Vector((sx * 0.42, -0.6, 1.95))
    ankle = Vector((sx * 0.42, -0.25, 0.2))
    PIVOTS[MODEL] = hip
    PIVOTS[MODEL + "_Knee"] = knee
    sph("Cream", (0.3, 0.38, 0.6), hip + Vector((0, -0.08, -0.25)))         # feathered thigh
    # L1 thigh: two soft layers of feathers flaring down/out (replaces the 5 tooth-like spikes)
    TC = hip + Vector((0, -0.08, -0.25))
    for layer, (n_f, z, ln, w, mat) in enumerate(((10, -0.42, 0.42, 0.16, "CreamWhite"), (8, -0.2, 0.34, 0.15, "Cream"))):
        for k in range(n_f):
            a = 2 * math.pi * (k + 0.5 * layer) / n_f
            out = Vector((math.cos(a), math.sin(a), 0))
            base = TC + Vector((math.cos(a) * 0.26, math.sin(a) * 0.33, z))
            fluff(mat, base, out * 0.2 + Vector((0, 0, -1)), ln * RNG.uniform(0.9, 1.15), w * 0.82, out + Vector((0, 0, -0.15)))
    tube("LegPink", lerp(hip + Vector((0, 0, -0.4)), knee, 6), 0.11, seg=12)
    sph("LegPink", 0.13, knee, seg=14, rings=10)                         # L2: plain small joint, no white ball
    tube("LegPink", lerp(knee, ankle, 6), [0.11, 0.105, 0.1, 0.1, 0.095, 0.095], seg=12)
    # L3 feather "boots": 3 rings round the shin from 0.35 below the knee to the ankle, longer and flaring more going down
    s_dir = (ankle - knee).normalized()
    A, B = ring_frame(s_dir)
    shin = (ankle - knee).length
    # rings overlap (each covers the top of the next) so they read as one shaggy boot, not stacked skirts
    for r_i, (dist, n_f, ln, flare, w, mat) in enumerate(((0.4, 11, 0.5, 8, 0.11, "CreamWhite"), (0.72, 12, 0.55, 14, 0.115, "PinkPale"),
                                                         (1.02, 13, 0.6, 22, 0.12, "CreamWhite"))):
        p = knee + s_dir * dist
        for k in range(n_f):
            ang = 2 * math.pi * (k + 0.5 * r_i + RNG.uniform(-0.2, 0.2)) / n_f
            out = A * math.cos(ang) + B * math.sin(ang)
            f = math.radians(flare + RNG.uniform(-5, 5))
            d = (s_dir * math.cos(f) + out * math.sin(f)).normalized()
            base = p + out * 0.09
            L = ln * RNG.uniform(0.85, 1.1)
            fluff(mat, base, d, L, w, out)
            if r_i == 2:                                                  # pale-blue tips on the bottom ring
                fluff("PaleBlue", base + d * (L * 0.55), d, L * 0.4, w * 0.75, out + d * 0.2)
    # L4 toes: chunkier, pale-blue pointed claws
    for ang in (-30, 0, 30):
        d = Vector((math.sin(math.radians(ang)), math.cos(math.radians(ang)), 0))
        toe_end = ankle + d * 0.6 + Vector((0, 0, -0.12))
        tube("Foot", [ankle + Vector((0, 0, -0.07)), toe_end], [0.1, 0.07], seg=8)
        tube("Nail", [toe_end - d * 0.02, toe_end + d * 0.13 + Vector((0, 0, -0.05))], [0.055, 0.012], seg=8)
    web = target("Foot")
    vs = [web.verts.new(ankle + Vector((0, 0, -0.1)))]
    for ang in (-30, -15, 0, 15, 30):
        d = Vector((math.sin(math.radians(ang)), math.cos(math.radians(ang)), 0))
        vs.append(web.verts.new(ankle + d * (0.55 if ang % 30 == 0 else 0.42) + Vector((0, 0, -0.13))))
    fs = [web.faces.new((vs[0], vs[i], vs[i + 1])) for i in range(1, 5)]
    bmesh.ops.solidify(web, geom=fs, thickness=0.04)

# ------------------------------------------------------------------ rider reference (preview only)
MODEL = "RiderRef"
SEAT = top + 0.2
print("SEAT_TOP", round(SEAT, 3))
sph("Ref", (0.55, 0.4, 0.6), (0, SEAT_Y, SEAT + 0.55))
tube("Ref", [Vector((0, SEAT_Y, SEAT + 0.5)), Vector((0, SEAT_Y, SEAT + 1.9))], 0.5, seg=12)
sph("Ref", 0.55, (0, SEAT_Y, SEAT + 2.5))
for sx in (1, -1):
    tube("Ref", [Vector((sx * 0.35, SEAT_Y + 0.2, SEAT + 0.3)), Vector((sx * 0.95, SEAT_Y + 0.8, SEAT - 0.3)), Vector((sx * 0.95, SEAT_Y + 0.9, SEAT - 1.2))], 0.2, seg=8)

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

for k, v in PIVOTS.items():
    print("PIVOT", k, tuple(round(c, 3) for c in v))

scn = bpy.context.scene
scn.render.engine = 'BLENDER_WORKBENCH'
scn.display.shading.light = 'STUDIO'
scn.display.shading.color_type = 'MATERIAL'
scn.render.film_transparent = False
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
scn.collection.objects.link(cam)
scn.camera = cam

allv_all = []
for model, objs in by_model.items():
    tri = 0
    for ob in objs:
        ob.data.calc_loop_triangles()
        tri += len(ob.data.loop_triangles)
    allv = [v.co for ob in objs for v in ob.data.vertices]
    lo = Vector(tuple(min(c[k] for c in allv) for k in range(3)))
    hi = Vector(tuple(max(c[k] for c in allv) for k in range(3)))
    big = max(objs, key=lambda o: len(o.data.loop_triangles))
    print("BIGGEST", big.name, len(big.data.loop_triangles))
    print("MODEL", model, "OBJECTS", len(objs), "TRIS", tri, "BBOX_MIN", tuple(round(v, 3) for v in lo), "BBOX_MAX", tuple(round(v, 3) for v in hi))
    if model == "RiderRef":
        continue
    allv_all += allv
    bpy.ops.object.select_all(action='DESELECT')
    for ob in objs:
        ob.select_set(True)
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, model + ".glb"), export_format='GLB',
                              use_selection=True, export_apply=True, export_yup=True)

lo = Vector(tuple(min(c[k] for c in allv_all) for k in range(3)))
hi = Vector(tuple(max(c[k] for c in allv_all) for k in range(3)))
print("WHOLE BBOX_MIN", tuple(round(v, 3) for v in lo), "BBOX_MAX", tuple(round(v, 3) for v in hi))
mid = (lo + hi) / 2
size = (hi - lo).length
VIEWS = [("side", Vector((-1.0, 0.05, 0.12)), False), ("front", Vector((-0.55, 1.0, 0.3)), False), ("picture", Vector((-1.0, 0.35, 0.2)), False),
         ("back", Vector((-0.45, -1.0, 0.45)), False), ("rider", Vector((0.5, -1.0, 0.3)), True)]
for vname, vdir, rider in VIEWS:
    for o in bpy.data.objects:
        if o is cam:
            continue
        o.hide_render = o.name.startswith("RiderRef") and not rider
    scn.render.resolution_x, scn.render.resolution_y = 900, 900
    cam.data.lens = 45
    f = mid + Vector((0, 0, 0.6 if rider else 0))
    cam.location = f + vdir.normalized() * size * 1.35
    cam.rotation_euler = (f - cam.location).to_track_quat('-Z', 'Y').to_euler()
    scn.render.filepath = os.path.join(OUT, "preview_Flamingo_%s.png" % vname)
    bpy.ops.render.render(write_still=True)
