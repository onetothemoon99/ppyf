# Little Frog fishing rod (เบ็ดกบน้อย, RodId Froggy, 99 R$, same stats as NightMoth) + lily-pad bobber. 2026-11-19
# Run:  blender.exe -b --factory-startup -P build_frog_rod.py -- <outdir>
# Units: 1 Blender unit = 1 stud. Rod is built STRAIGHT UP along Blender +Z with the hand (Roblox Handle) at the origin.
#   Sides = +-X, underside = -Y (reel), top = +Y (frog, dragonfly, line guides). Tip (lotus bud point) at z ~5.9.
#   Studio tilts it 35 deg like the other rods (same as Rod_Phoenix).
# Bobber: origin = water line, lily pad at z ~0.01, tiny frog on top; LineAttach goes on the frog's head.
# Objects are named "<Model>__<Material>"; Studio colours them from COLORS (the importer drops colours).
# Output: FrogRod.glb, FrogBobber.glb + preview_*.png
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
    "Reed": (110, 190, 70), "ReedDark": (70, 150, 50), "ReedLight": (170, 220, 100),
    "FrogSkin": (185, 220, 70), "FrogSpot": (70, 145, 55), "Ribbon": (255, 140, 180), "Throat": (255, 175, 200),
    "Grip": (205, 165, 110), "GripDark": (160, 120, 75), "Cord": (90, 160, 60),
    "Frog": (120, 205, 80), "FrogBelly": (225, 245, 170), "FrogDark": (70, 150, 55), "Cheek": (255, 150, 170),
    "Eye": (30, 30, 30), "EyeWhite": (255, 255, 250), "Mouth": (200, 70, 90),
    "LilyPad": (80, 170, 70), "LilyDark": (55, 130, 55), "Lotus": (255, 150, 190), "LotusLight": (255, 210, 225),
    "LotusCore": (255, 220, 90), "Wing": (200, 235, 255), "Dragon": (80, 170, 220), "Drop": (190, 230, 255),
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

def fan_disk(mat, center, r, thick, u, v, nrm, notch=0.55, seg=26, notch_at=0.0):
    """Flat round pad with a wedge notch (lily pad). u, v = in-plane axes, nrm = pad normal. notch = wedge width (rad)."""
    bm = target(mat)
    c, u, v, nrm = Vector(center), Vector(u), Vector(v), Vector(nrm)
    a0, a1 = notch_at + notch / 2, notch_at + 2 * math.pi - notch / 2
    tops, bots = [], []
    for i in range(seg + 1):
        a = a0 + (a1 - a0) * i / seg
        p = c + (u * math.cos(a) + v * math.sin(a)) * r
        tops.append(bm.verts.new(p + nrm * thick / 2))
        bots.append(bm.verts.new(p - nrm * thick / 2))
    ct = bm.verts.new(c + nrm * thick / 2)
    cb = bm.verts.new(c - nrm * thick / 2)
    faces = []
    for i in range(seg):
        faces.append(bm.faces.new((ct, tops[i], tops[i + 1])))
        faces.append(bm.faces.new((cb, bots[i + 1], bots[i])))
        faces.append(bm.faces.new((tops[i], bots[i], bots[i + 1], tops[i + 1])))
    faces.append(bm.faces.new((ct, cb, bots[0], tops[0])))
    faces.append(bm.faces.new((ct, tops[-1], bots[-1], cb)))
    bmesh.ops.recalc_face_normals(bm, faces=faces)

def pad_veins(mat, center, r, u, v, nrm, lift, notch_at=0.0, n=7, thick=0.008):
    c, u, v, nrm = Vector(center), Vector(u), Vector(v), Vector(nrm)
    for k in range(n):
        a = notch_at + 0.5 + (2 * math.pi - 1.0) * k / (n - 1)
        d = u * math.cos(a) + v * math.sin(a)
        tube(mat, [c + nrm * lift + d * r * 0.12, c + nrm * lift + d * r * 0.85], [thick, thick * 0.4], seg=4)

def leaf_blade(mat, pts, width, normal):
    m = len(pts)
    prof = [width * max(0.15, math.sin(math.pi * min(1.0, (i / (m - 1)) * 1.1) ** 0.6) * (1 - 0.7 * i / (m - 1))) for i in range(m)]
    prof[-1] = 0.004
    tube(mat, pts, prof, seg=6, normal=normal, flat=0.12)

def lotus(center, axis, size, petals=6, open_=0.25, core=True):
    """Pink lotus bud/flower: petals arranged around axis; open_ = how far petals lean out (0 = closed bud)."""
    c, ax = Vector(center), Vector(axis).normalized()
    side = ax.cross(Vector((1, 0, 0)))
    if side.length < 1e-3:
        side = ax.cross(Vector((0, 1, 0)))
    side.normalize()
    side2 = ax.cross(side).normalized()
    for k in range(petals):
        a = 2 * math.pi * k / petals
        d = side * math.cos(a) + side2 * math.sin(a)
        p0 = c + d * size * 0.15
        p1 = c + d * size * (0.45 + open_) + ax * size * 0.5
        p2 = c + d * size * (0.15 + open_ * 1.2) + ax * size * 1.15
        leaf_blade("Lotus" if k % 2 == 0 else "LotusLight", bez(p0, p1, p2, 7), size * 0.42, normal=d)
    if core:
        sph("LotusCore", size * 0.2, c + ax * size * 0.35, seg=8, rings=6)

def frog(center, scale, facing=(0, 1, 0), up=(0, 0, 1)):
    """Cute sitting frog. facing = where the face looks, up = frog's up."""
    c = Vector(center)
    f = Vector(facing).normalized()
    upv = Vector(up).normalized()
    sidev = f.cross(upv).normalized()
    def P(x, y, z):  # x = side, y = forward, z = up (in frog space, units of scale)
        return c + (sidev * x + f * y + upv * z) * scale
    S = scale
    sph("Frog", (0.16 * S, 0.15 * S, 0.17 * S), P(0, 0, 0))                    # body (scaled sphere is axis-aligned; ok for round)
    sph("FrogBelly", (0.1 * S, 0.1 * S, 0.12 * S), P(0, 0.08, -0.01))
    sph("Frog", (0.15 * S, 0.13 * S, 0.12 * S), P(0, 0.05, 0.19))             # head
    for sx in (1, -1):
        sph("Frog", 0.065 * S, P(sx * 0.075, 0.07, 0.29))                      # eye bulge
        sph("EyeWhite", 0.05 * S, P(sx * 0.08, 0.11, 0.305), seg=10, rings=7)
        sph("Eye", 0.028 * S, P(sx * 0.083, 0.148, 0.31), seg=8, rings=6)
        sph("EyeWhite", 0.01 * S, P(sx * 0.075, 0.168, 0.322), seg=6, rings=4)  # sparkle
        sph("Cheek", (0.03 * S, 0.012 * S, 0.02 * S), P(sx * 0.105, 0.155, 0.17), seg=8, rings=5)
        sph("Frog", (0.075 * S, 0.1 * S, 0.065 * S), P(sx * 0.13, 0.0, -0.09))  # thigh
        sph("FrogDark", (0.05 * S, 0.075 * S, 0.02 * S), P(sx * 0.1, 0.1, -0.16), seg=10, rings=6)  # foot
        for t in (-1, 0, 1):
            sph("FrogDark", 0.018 * S, P(sx * (0.1 + t * 0.03), 0.17, -0.16), seg=6, rings=4)
    smile = [P(-0.06 + 0.12 * i / 8, 0.17 - 0.02 * abs(i - 4) / 4, 0.14 - 0.025 * math.sin(math.pi * i / 8)) for i in range(9)]
    tube("Mouth", smile, 0.008 * S, seg=4)
    for (x, y, z, r) in ((0.06, -0.1, 0.25, 0.022), (-0.08, -0.12, 0.08, 0.02), (0.1, -0.1, -0.02, 0.018)):
        sph("FrogDark", (r * S, r * 0.5 * S, r * S), P(x, y, z), seg=6, rings=4)   # back spots
    return P, sidev, f, upv

# =================================================================== 1) FrogRod (straight up +Z, hand at origin)
MODEL = "FrogRod"
POLE_R = lambda z: 0.062 + (0.024 - 0.062) * (z - 0.6) / (5.55 - 0.6)

# butt: rounded reed cap with a ring of small lily leaves
sph("ReedDark", (0.115, 0.115, 0.09), (0, 0, -0.47))
for k in range(5):
    a = 2 * math.pi * k / 5
    d = Vector((math.cos(a), math.sin(a), 0))
    leaf_blade("Reed", bez(Vector((0, 0, -0.45)) + d * 0.08, Vector((0, 0, -0.55)) + d * 0.14, Vector((0, 0, -0.62)) + d * 0.12, 6), 0.05,
               normal=Vector((-d.y, d.x, 0)))
# grip: woven straw with green cord bands
cyl("Grip", 0.11, 0.102, 0.96, (0, 0, 0.07), seg=16)
helix("GripDark", -0.38, 0.52, 0.108, 0.1, 6, 0.009)
helix("GripDark", -0.38, 0.52, 0.108, 0.1, 6, 0.009, phase=math.pi)
for z in (-0.4, 0.07, 0.55):
    cyl("Cord", 0.118, 0.118, 0.045, (0, 0, z), seg=16)
# 2026-11-19 (user: the green reed looked like the Bamboo rod) -> frog-skin pole: lime-yellow, dark green spots, NO nodes,
#   a pink ribbon spiralling up, and 3 small lily pads on short stems instead of reed leaves.
import random
random.seed(11)
cyl("FrogSkin", POLE_R(0.6), POLE_R(5.55), 5.55 - 0.6, (0, 0, (0.6 + 5.55) / 2), seg=14)
for i in range(38):                                                   # frog spots: flat round patches lying on the skin
    z = random.uniform(0.7, 5.4)
    a = random.uniform(0, 2 * math.pi)
    r = POLE_R(z)
    sr = r * random.uniform(0.9, 1.35)
    d = Vector((math.cos(a), math.sin(a), 0))
    sph("FrogSpot", (r * 0.32, sr, sr * random.uniform(1.0, 1.5)), Vector((0, 0, z)) + d * (r * 0.8), rot=(0, 0, math.degrees(a)), seg=10, rings=6)
helix("Ribbon", 0.62, 5.3, POLE_R(0.62) + 0.012, POLE_R(5.3) + 0.01, 5.5, 0.019, phase=0.6, n=90)
for z, a in ((1.7, 0.3), (2.9, 2.6), (4.1, 4.8)):                     # mini lily pads on stems
    r = POLE_R(z)
    d = Vector((math.cos(a), math.sin(a), 0))
    base = Vector((0, 0, z)) + d * r
    tip = base + d * 0.12 + Vector((0, 0, 0.06))
    tube("Cord", [base, base + d * 0.06 + Vector((0, 0, 0.01)), tip], 0.012, seg=5)
    up = Vector((0, 0, 1))
    side = d.cross(up).normalized()
    nrm = (up * 0.45 + d * 0.9 + side * 0.3).normalized()
    u2 = side
    v2 = nrm.cross(side).normalized()
    fan_disk("LilyPad", tip + nrm * 0.01, 0.13, 0.018, u2, v2, nrm, notch=0.6, notch_at=-math.pi / 2)
    pad_veins("LilyDark", tip + nrm * 0.01, 0.13, u2, v2, nrm, 0.011, n=5, thick=0.007)
# line guides (top +Y)
for z in (1.9, 2.8, 3.6, 4.4, 5.1):
    r = POLE_R(z)
    pts = [(0.028 * math.cos(2 * math.pi * k / 10), r + 0.06, z + 0.028 * math.sin(2 * math.pi * k / 10)) for k in range(10)]
    tube("ReedDark", pts, 0.007, seg=4, closed=True, caps=False)
    cyl("ReedDark", 0.008, 0.008, 0.05, (0, r + 0.025, z), rot=(90, 0, 0), seg=5)
# the frog: sits on the top side (+Y) just above the grip, hugging the pole, face looking up/out (+Y)
FROG_C = Vector((0, POLE_R(0.95) + 0.12, 0.95))
P, sidev, fwd, upv = frog(FROG_C, 1.0)
# 2026-11-19 throat sac (own MeshPart "Throat"): the client puffs it up every few seconds and sends out music notes
sph("Throat", (0.042, 0.03, 0.03), P(0, 0.155, 0.075), seg=12, rings=8)
for sx in (1, -1):    # arms wrap round the pole to the underside
    arm = bez(P(sx * 0.12, 0.02, 0.08), Vector((sx * 0.1, 0.0, 1.04)), Vector((sx * 0.05, -0.07, 1.0)), 7)
    tube("Frog", arm, [0.035, 0.034, 0.032, 0.03, 0.028, 0.027, 0.027], seg=8)
    sph("FrogDark", (0.03, 0.03, 0.025), Vector((sx * 0.04, -0.075, 1.0)), seg=8, rings=6)
# reel (underside -Y): lily-pad side plates on a reed drum, lotus knob
REEL = Vector((0, -0.2, 0.82))
cyl("ReedDark", 0.035, 0.035, 0.16, (0, -0.1, 0.82), rot=(90, 0, 0), seg=8)
cyl("ReedDark", 0.13, 0.13, 0.12, REEL, rot=(0, 90, 0), seg=16)
for s in (1, -1):
    c = REEL + Vector((s * 0.075, 0, 0))
    fan_disk("LilyPad", c, 0.165, 0.022, (0, 0, 1), (0, 1, 0), (1, 0, 0), notch=0.6, notch_at=math.pi / 2)
    pad_veins("LilyDark", c, 0.165, (0, 0, 1), (0, 1, 0), (s, 0, 0), 0.012, notch_at=math.pi / 2)
    sph("Drop", 0.018, c + Vector((s * 0.018, 0.05, -0.06)), seg=8, rings=5)
tube("ReedDark", [REEL + Vector((0.1, 0, 0)), REEL + Vector((0.13, -0.08, 0.05)), REEL + Vector((0.14, -0.15, 0.09))], 0.014, seg=6)
lotus(REEL + Vector((0.14, -0.17, 0.1)), (0.3, -0.6, 0.5), 0.07, petals=6, open_=0.35)
# dragonfly resting on the top of the pole
DF = Vector((0, POLE_R(3.3) + 0.05, 3.3))
tube("Dragon", [DF + Vector((0, 0, 0.1)), DF, DF + Vector((0, 0.005, -0.16)), DF + Vector((0, 0.01, -0.26))], [0.022, 0.02, 0.012, 0.006], seg=6)
sph("Dragon", 0.03, DF + Vector((0, 0, 0.12)), seg=8, rings=6)
for sx in (1, -1):
    sph("Eye", 0.014, DF + Vector((sx * 0.018, 0.012, 0.14)), seg=6, rings=4)
    for dz, L in ((0.05, 0.2), (0.0, 0.17)):
        sph("Wing", (L, 0.004, 0.035), DF + Vector((sx * L * 0.95, 0.01, dz)), rot=(0, sx * (8 if dz else -8), 0), seg=10, rings=6)
# tip: pink lotus bud (the line leaves from its point)
cyl("FrogSkin", POLE_R(5.55), 0.03, 0.1, (0, 0, 5.6), seg=10)
for k in range(4):
    a = 2 * math.pi * k / 4 + 0.4
    d = Vector((math.cos(a), math.sin(a), 0))
    leaf_blade("Reed", bez(Vector((0, 0, 5.62)) + d * 0.02, Vector((0, 0, 5.66)) + d * 0.07, Vector((0, 0, 5.7)) + d * 0.08, 5), 0.035, normal=d)
lotus((0, 0, 5.62), (0, 0, 1), 0.2, petals=6, open_=0.05, core=False)
cyl("LotusLight", 0.012, 0.0, 0.08, (0, 0, 5.86), seg=6)

# =================================================================== 2) FrogBobber (lily pad + tiny frog; origin = water line)
MODEL = "FrogBobber"
fan_disk("LilyPad", (0, 0, 0.012), 0.3, 0.028, (1, 0, 0), (0, 1, 0), (0, 0, 1), notch=0.55, notch_at=-math.pi / 2)
pad_veins("LilyDark", (0, 0, 0.012), 0.3, (1, 0, 0), (0, 1, 0), (0, 0, 1), 0.016, notch_at=-math.pi / 2, n=9, thick=0.01)
for (x, y, r) in ((0.15, 0.12, 0.022), (-0.17, 0.05, 0.016), (0.05, -0.18, 0.018)):
    sph("Drop", (r, r, r * 0.7), (x, y, 0.035), seg=8, rings=5)
lotus((-0.16, -0.12, 0.03), (0, 0, 1), 0.09, petals=6, open_=0.4)
frog((0.03, 0.06, 0.16), 0.75, facing=(0, -1, 0), up=(0, 0, 1))

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
scn.render.engine = 'BLENDER_WORKBENCH'
scn.display.shading.light = 'STUDIO'
scn.display.shading.color_type = 'MATERIAL'
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
scn.collection.objects.link(cam)
scn.camera = cam

VIEWS = {"FrogRod": [("side", Vector((1.0, -0.35, 0.15)), None, None), ("top", Vector((0.25, 1.0, 0.35)), None, None),
                     ("frog", Vector((0.35, 1.0, 0.2)), Vector((0, 0.15, 1.0)), 1.6), ("reel", Vector((1.0, -0.4, 0.1)), Vector((0, -0.2, 0.82)), 1.1),
                     ("tip", Vector((0.6, 1.0, 0.2)), Vector((0, 0.05, 5.0)), 2.6)],
         "FrogBobber": [("side", Vector((0.8, -1.0, 0.6)), None, None)]}
for model, objs in by_model.items():
    tri = 0
    for ob in objs:
        ob.data.calc_loop_triangles()
        tri += len(ob.data.loop_triangles)
    allv = [v.co for ob in objs for v in ob.data.vertices]
    lo = Vector(tuple(min(c[k] for c in allv) for k in range(3)))
    hi = Vector(tuple(max(c[k] for c in allv) for k in range(3)))
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
    for vname, vdir, focus, dist in VIEWS[model]:
        f = focus if focus is not None else mid
        dd = dist if dist is not None else size * 1.25
        scn.render.resolution_x, scn.render.resolution_y = (700, 1000) if (model == "FrogRod" and focus is None) else (800, 800)
        cam.data.lens = 40 if focus is None else 50
        cam.location = f + vdir.normalized() * dd
        cam.rotation_euler = (f - cam.location).to_track_quat('-Z', 'Y').to_euler()
        scn.render.filepath = os.path.join(OUT, "preview_%s_%s.png" % (model, vname))
        bpy.ops.render.render(write_still=True)
