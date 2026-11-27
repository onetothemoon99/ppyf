# Snow leopard pet (เสือดาวหิมะ, PetId SnowLeopard) 2026-11-27. Plan: SNOW_LEOPARD_PET.md, picture: ref_concept.png
# Chibi biped: big head, white-grey fur with dark rosettes, brown bib apron (teal trim, trowel in the pocket),
#   veggie basket on the right hip with a purple lantern under it, watering can in the right paw, left paw raised palm-up holding the crop it is planting (Studio puts that crop's held model on PIVOT HoldL),
#   long fluffy ringed tail.
# Run:  blender.exe -b --factory-startup -P build_snow_leopard.py -- <outdir>
# Units: 1 Blender unit = 1 stud (scale in Studio). Origin = ground under the feet. Faces Blender +Y (glTF -Z = Roblox forward). Up = +Z.
#   Character's right = +X (Roblox right = +X too).
# One GLB per moving part: SnowLeopardBody, Head, ArmL, ArmR, LegL, LegR, Tail. PIVOT lines = joint points for the Motor6Ds.
# Objects are named "<Model>__<Material>"; Studio colours them from COLORS (the importer drops colours).
import bpy, bmesh, math, sys, os, random
from mathutils import Vector, Matrix, Euler

OUT = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else os.path.dirname(os.path.abspath(__file__))
os.makedirs(OUT, exist_ok=True)
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o, do_unlink=True)

def lin(c):
    c = c / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

COLORS = {
    "Fur": (236, 236, 240), "FurGrey": (205, 205, 212), "Belly": (252, 252, 253), "Spot": (78, 78, 88), "SpotMid": (150, 150, 160),
    "Pink": (246, 172, 182), "Nose": (214, 118, 132), "Eye": (112, 74, 52), "Pupil": (18, 14, 14), "Shine": (255, 255, 255), "Line": (70, 55, 55),
    "Apron": (176, 120, 72), "ApronDark": (128, 84, 48), "Trim": (104, 170, 150), "Strap": (112, 72, 42), "Button": (230, 190, 90),
    "Wood": (150, 100, 60), "Steel": (160, 165, 178),
    "Basket": (196, 142, 78), "BasketDark": (142, 98, 52), "Carrot": (242, 132, 42), "Leaf": (112, 182, 82), "Cabbage": (160, 205, 110),
    "Copper": (204, 136, 74), "CopperDark": (150, 92, 50),
    "LanternMetal": (92, 82, 104), "LanternGlass": (182, 122, 242),
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

def sphn(mat, scale, loc, normal, seg=16, rings=10):
    """Ellipsoid whose local Z points along `normal` (for flat things stuck on a surface)."""
    q = Vector(normal).normalized().to_track_quat('Z', 'Y').to_matrix().to_4x4()
    M = Matrix.Translation(Vector(loc)) @ q @ Matrix.Diagonal((scale[0], scale[1], scale[2], 1.0))
    r = bmesh.ops.create_uvsphere(target(mat), u_segments=seg, v_segments=rings, radius=1.0, matrix=M)
    smooth(r["verts"])

def frame(t, normal):
    a = t.cross(normal)
    if a.length < 1e-5:
        a = t.cross(Vector((0, 1, 0)) if abs(t.y) < 0.9 else Vector((1, 0, 0)))
    a.normalize()
    return a, a.cross(t).normalized()

def tube(mat, pts, radii, seg=14, caps=True, normal=(1, 0, 0), flat=1.0):
    bm = target(mat)
    pts = [Vector(p) for p in pts]
    n = len(pts)
    if isinstance(radii, (int, float)):
        radii = [radii] * n
    nv = Vector(normal).normalized()
    rings = []
    for i, p in enumerate(pts):
        t = (pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]).normalized()
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
    a, b = Vector(a), Vector(b)
    return [a + (b - a) * (i / (n - 1)) for i in range(n)]

def cyl(mat, r1, r2, depth, loc, rot=(0, 0, 0), seg=16):
    bmesh.ops.create_cone(target(mat), cap_ends=True, segments=seg, radius1=r1, radius2=r2, depth=depth, matrix=xf(loc, rot))

def ell_dir(az, el):
    """az 0 = front (+Y), +90 = right (+X); el up from the horizon (degrees)."""
    a, e = math.radians(az), math.radians(el)
    return Vector((math.sin(a) * math.cos(e), math.cos(a) * math.cos(e), math.sin(e)))

def surf(C, R, az, el, k=1.0):
    u = ell_dir(az, el)
    p = Vector((R.x * u.x, R.y * u.y, R.z * u.z))
    n = Vector((p.x / R.x ** 2, p.y / R.y ** 2, p.z / R.z ** 2)).normalized()
    return C + p * k, n

def rosette(C, R, az, el, size, k=1.0):
    """Snow-leopard rosette: dark broken ring (3-4 blobs) round a grey centre, lying on the ellipsoid."""
    p, n = surf(C, R, az, el, k)
    a, b = frame(n, Vector((0, 0, 1)) if abs(n.z) < 0.9 else Vector((1, 0, 0)))
    sphn("SpotMid", (size * 0.62, size * 0.55, 0.008), p, n, seg=12, rings=6)
    start = RNG.uniform(0, 360)
    gap = RNG.uniform(50, 90)                         # open "C" ring like real rosettes
    arc = [p + (a * math.cos(math.radians(start + d)) + b * math.sin(math.radians(start + d))) * size * 0.78 * (1 + 0.12 * math.sin(math.radians(3 * d)))
           for d in range(0, int(360 - gap) + 1, 20)]
    tube("Spot", arc, size * 0.2, seg=8, normal=n, flat=0.25)

def dot(C, R, az, el, size, k=1.0):
    p, n = surf(C, R, az, el, k)
    sphn("Spot", (size, size * 0.85, 0.01), p, n, seg=10, rings=6)

RNG = random.Random(27)
PIVOTS = {}

# ------------------------------------------------------------------ body: torso, apron, basket, lantern
MODEL = "SnowLeopardBody"
TC = Vector((0, 0, 0.98))
TR = Vector((0.44, 0.38, 0.5))
sph("Fur", tuple(TR), TC)
sph("Belly", (0.34, 0.2, 0.4), TC + Vector((0, 0.14, -0.04)))
sph("Fur", (0.3, 0.28, 0.2), TC + Vector((0, 0, 0.42)))          # neck
# rosettes on the back and sides (the front is under the apron)
for i in range(16):
    az = RNG.uniform(95, 265)
    el = RNG.uniform(-35, 50)
    rosette(TC, TR, az, el, RNG.uniform(0.075, 0.1), k=1.0)

# apron: a shell over the front of the torso, solidified
def shell(mat, C, R, az0, az1, el0, el1, k, na=14, ne=10, thick=0.035):
    bm = target(mat)
    grid = [[bm.verts.new(surf(C, R, az0 + (az1 - az0) * i / (na - 1), el0 + (el1 - el0) * j / (ne - 1), k)[0])
             for j in range(ne)] for i in range(na)]
    fs = []
    for i in range(na - 1):
        for j in range(ne - 1):
            f = bm.faces.new((grid[i][j], grid[i + 1][j], grid[i + 1][j + 1], grid[i][j + 1]))
            f.smooth = True
            fs.append(f)
    bmesh.ops.recalc_face_normals(bm, faces=fs)
    bmesh.ops.solidify(bm, geom=fs, thickness=thick)
    return grid

shell("Apron", TC, TR, -62, 62, -62, 22, 1.06)                    # skirt + lower bib
shell("Apron", TC, TR, -34, 34, 22, 52, 1.06, na=8, ne=6)         # bib top
shell("Trim", TC, TR, -34, 34, 46, 54, 1.09, na=8, ne=3)          # teal embroidered band on the bib top
for az in range(-28, 29, 14):
    p, n = surf(TC, TR, az, 50, 1.11)
    sphn("Button", (0.025, 0.025, 0.012), p, n, seg=8, rings=4)
# straps from the bib corners over the shoulders to the back
for sx in (1, -1):
    a, _ = surf(TC, TR, sx * 30, 50, 1.08)
    pts = [a, TC + Vector((sx * 0.27, 0.1, 0.5)), TC + Vector((sx * 0.25, -0.15, 0.48)), surf(TC, TR, sx * 150, 30, 1.06)[0]]
    tube("Strap", bez(pts, 8), 0.045, seg=8, flat=0.35, normal=(sx, 0, 0))
    sph("Button", 0.035, a, seg=8, rings=6)
# waist tie bow on the back
bow, bn = surf(TC, TR, 180, -15, 1.08)
sph("ApronDark", 0.05, bow, seg=10, rings=6)
for sx in (1, -1):
    sphn("ApronDark", (0.09, 0.045, 0.03), bow + Vector((sx * 0.08, -0.02, 0.01)), bn, seg=10, rings=6)
    tube("ApronDark", [bow, bow + Vector((sx * 0.05, -0.05, -0.18))], 0.025, seg=6, flat=0.4, normal=(0, 1, 0))
# front pocket with a little trowel
pk, pn = surf(TC, TR, -14, -28, 1.1)
sphn("ApronDark", (0.17, 0.12, 0.03), pk, pn, seg=14, rings=8)
tube("Trim", [pk + Vector((-0.16, 0.0, 0.1)), pk + Vector((0.16, 0.0, 0.1))], 0.016, seg=6)
tube("Wood", [pk + Vector((0.05, 0.03, 0.02)), pk + Vector((0.09, 0.05, 0.28))], 0.025, seg=8)
sphn("Steel", (0.05, 0.075, 0.012), pk + Vector((0.035, 0.035, -0.04)), pn, seg=10, rings=6)

# veggie basket on the right hip, satchel strap over the back to the left shoulder
BK = Vector((0.6, -0.05, 0.82))
cyl("Basket", 0.17, 0.22, 0.3, BK, seg=18)
for dz in (-0.1, 0.0, 0.1):
    r = 0.17 + 0.05 * (dz + 0.15) / 0.3
    tube("BasketDark", [BK + Vector((math.cos(math.radians(a)) * (r + 0.008), math.sin(math.radians(a)) * (r + 0.008), dz)) for a in range(0, 361, 20)], 0.014, seg=5, caps=False)
tube("BasketDark", [BK + Vector((math.cos(math.radians(a)) * 0.225, math.sin(math.radians(a)) * 0.225, 0.15)) for a in range(0, 361, 15)], 0.03, seg=6, caps=False)
sph("Cabbage", (0.12, 0.12, 0.1), BK + Vector((-0.04, -0.06, 0.17)), seg=12, rings=8)
for dx, dy, tilt in ((0.06, 0.06, 10), (0.1, -0.02, -12), (-0.02, 0.1, 18)):
    base = BK + Vector((dx, dy, 0.12))
    tipp = base + Vector((math.sin(math.radians(tilt)) * 0.1, 0, 0.22))
    tube("Carrot", [base, tipp], [0.045, 0.03], seg=10)
    for la in (-25, 0, 25):
        d = Vector((math.sin(math.radians(la + tilt)) * 0.5, 0.15 * la / 25, 1)).normalized()
        sphn("Leaf", (0.03, 0.08, 0.015), tipp + d * 0.08, Vector((0, 1, 0)), seg=8, rings=6)
strap = bez([BK + Vector((-0.05, -0.12, 0.15)), Vector((0.35, -0.42, 1.25)), Vector((-0.1, -0.4, 1.45)), Vector((-0.36, -0.05, 1.38))], 12)
tube("Strap", strap, 0.04, seg=8, flat=0.35, normal=(0, 0, 1))
# purple lantern hanging under the basket
hook = BK + Vector((0.08, 0.12, -0.15))
LN = hook + Vector((0.02, 0.04, -0.3))
tube("LanternMetal", [hook, LN + Vector((0, 0, 0.16))], 0.012, seg=5)
cyl("LanternMetal", 0.075, 0.02, 0.06, LN + Vector((0, 0, 0.13)), seg=10)
cyl("LanternGlass", 0.06, 0.06, 0.17, LN, seg=12)
for a in range(45, 360, 90):
    d = Vector((math.cos(math.radians(a)), math.sin(math.radians(a)), 0)) * 0.062
    tube("LanternMetal", [LN + d + Vector((0, 0, -0.09)), LN + d + Vector((0, 0, 0.1))], 0.01, seg=4)
cyl("LanternMetal", 0.07, 0.07, 0.03, LN + Vector((0, 0, -0.1)), seg=10)
PIVOTS["Lantern"] = LN
PIVOTS["Basket"] = BK

# ------------------------------------------------------------------ head
MODEL = "SnowLeopardHead"
NECK = TC + Vector((0, 0, 0.42))
PIVOTS["Neck"] = NECK
HC = Vector((0, 0.04, 1.86))
HR = Vector((0.63, 0.5, 0.47))
sph("Fur", tuple(HR), HC, seg=28, rings=18)
for sx in (1, -1):                                                # fluffy cheek ruff
    sph("Fur", (0.2, 0.2, 0.18), HC + Vector((sx * 0.48, 0.1, -0.2)), seg=14, rings=10)
    sph("Belly", (0.14, 0.12, 0.12), HC + Vector((sx * 0.56, 0.12, -0.28)), seg=12, rings=8)
# muzzle puffs, chin, nose, mouth
MZ = HC + Vector((0, 0.46, -0.14))
for sx in (1, -1):
    sph("Belly", (0.14, 0.11, 0.1), MZ + Vector((sx * 0.1, 0, 0)), seg=14, rings=10)
sph("Belly", (0.12, 0.1, 0.08), MZ + Vector((0, -0.02, -0.12)), seg=12, rings=8)
sph("Nose", (0.075, 0.05, 0.045), MZ + Vector((0, 0.09, 0.08)), seg=12, rings=8)
for sx in (1, -1):
    tube("Line", bez([MZ + Vector((0, 0.11, 0.03)), MZ + Vector((sx * 0.02, 0.13, -0.05)), MZ + Vector((sx * 0.09, 0.11, -0.04))], 6), 0.011, seg=6)
    for dz in (0.0, -0.04):                                     # whisker dots
        for dx in (0.07, 0.13):
            sph("Spot", 0.012, MZ + Vector((sx * dx, 0.1 - dx * 0.4, dz)), seg=6, rings=4)
# big shiny eyes
for sx in (1, -1):
    p, n = surf(HC, HR, sx * 24, 6, 0.985)
    sphn("Eye", (0.13, 0.155, 0.05), p, n, seg=20, rings=12)
    sphn("Pupil", (0.08, 0.1, 0.04), p + n * 0.02, n, seg=16, rings=10)
    sphn("Shine", (0.045, 0.05, 0.02), p + n * 0.045 + Vector((sx * 0.03, 0, 0.06)), n, seg=10, rings=6)
    sphn("Shine", (0.02, 0.02, 0.012), p + n * 0.045 + Vector((-sx * 0.035, 0, -0.06)), n, seg=8, rings=4)
    lid = [surf(HC, HR, sx * (24 + 11 * math.cos(math.radians(a))), 6 + 11 * math.sin(math.radians(a)), 1.012)[0] for a in range(10, 171, 20)]
    tube("Line", lid, 0.014, seg=6)
    # pink blush under the eye
    q, qn = surf(HC, HR, sx * 38, -18, 0.99)
    sphn("Pink", (0.1, 0.06, 0.02), q, qn, seg=12, rings=6)
# ears: rounded, dark back rim, pink inside
for sx in (1, -1):
    p, n = surf(HC, HR, sx * 52, 42, 0.95)
    up = Vector((sx * 0.6, 0.05, 1)).normalized()
    E = p + up * 0.09
    fn = Vector((sx * 0.25, 1, 0.1))
    sphn("FurGrey", (0.13, 0.135, 0.06), E, fn, seg=16, rings=10)
    sphn("Spot", (0.13, 0.135, 0.04), E + Vector((0, -0.025, 0)), fn, seg=16, rings=10)
    sphn("Pink", (0.075, 0.08, 0.03), E + Vector((0, 0.035, -0.015)), fn, seg=12, rings=8)
    sphn("Fur", (0.05, 0.035, 0.025), E + Vector((0, 0.05, -0.06)), Vector((0, 1, 0)), seg=8, rings=6)
# head spots: small dots on the forehead and crown, rosettes on the back of the head
for az, el, s in ((0, 38, 0.035), (-10, 46, 0.03), (10, 46, 0.03), (-20, 34, 0.028), (20, 34, 0.028), (0, 52, 0.03),
                  (-30, 46, 0.03), (30, 46, 0.03), (-6, 60, 0.035), (8, 66, 0.035), (-52, 20, 0.035), (52, 20, 0.035),
                  (-62, 4, 0.03), (62, 4, 0.03)):
    dot(HC, HR, az, el, s, k=1.002)
for i in range(9):
    rosette(HC, HR, RNG.uniform(110, 250), RNG.uniform(-10, 60), RNG.uniform(0.07, 0.09), k=1.003)

# ------------------------------------------------------------------ arms
SH = {1: TC + Vector((0.36, 0.02, 0.3)), -1: TC + Vector((-0.36, 0.02, 0.3))}
# right arm (+X): forward and down, holding the watering can
MODEL = "SnowLeopardArmR"
PIVOTS["ShoulderR"] = SH[1]
EL = SH[1] + Vector((0.14, 0.12, -0.24))
PW = SH[1] + Vector((0.12, 0.36, -0.34))
tube("Fur", bez([SH[1], EL, PW], 8), [0.15, 0.14, 0.13, 0.13, 0.125, 0.12, 0.12, 0.12], seg=14)
sph("Belly", (0.12, 0.13, 0.11), PW, seg=14, rings=10)
rosette(EL, Vector((0.13, 0.13, 0.13)), 90, 20, 0.05, k=1.0)
CAN = PW + Vector((0.08, 0.2, -0.18))
cyl("Copper", 0.15, 0.13, 0.24, CAN, seg=20)
tube("CopperDark", [CAN + Vector((math.cos(math.radians(a)) * 0.13, math.sin(math.radians(a)) * 0.13, 0.12)) for a in range(0, 361, 15)], 0.018, seg=6, caps=False)
tube("CopperDark", [CAN + Vector((math.cos(math.radians(a)) * 0.152, math.sin(math.radians(a)) * 0.152, -0.08)) for a in range(0, 361, 15)], 0.014, seg=6, caps=False)
tube("CopperDark", bez([CAN + Vector((-0.02, -0.12, 0.1)), CAN + Vector((-0.03, -0.24, 0.3)), CAN + Vector((0, -0.05, 0.28)), CAN + Vector((0, 0.02, 0.12))], 10), 0.022, seg=8)
spout = bez([CAN + Vector((0.09, 0.08, -0.04)), CAN + Vector((0.25, 0.22, 0.02)), CAN + Vector((0.34, 0.32, 0.16))], 8)
tube("Copper", spout, [0.035, 0.033, 0.03, 0.028, 0.027, 0.026, 0.025, 0.025], seg=10)
sp_dir = (spout[-1] - spout[-2]).normalized()
rose = spout[-1] + sp_dir * 0.04
bmesh.ops.create_cone(target("CopperDark"), cap_ends=True, segments=12, radius1=0.035, radius2=0.07, depth=0.08,
                      matrix=Matrix.Translation(rose) @ sp_dir.to_track_quat('Z', 'Y').to_matrix().to_4x4())
PIVOTS["Can"] = CAN

# left arm (-X): raised, palm up. 2026-11-27 user: hold the crop being planted (changes per crop) instead of a fixed carrot.
#   The paw is a cupped palm; PIVOT HoldL = where the crop's held model sits. "PreviewHeld" (a tomato) is preview-only, not exported.
MODEL = "SnowLeopardArmL"
PIVOTS["ShoulderL"] = SH[-1]
EL = SH[-1] + Vector((-0.2, 0.14, -0.05))
PW = SH[-1] + Vector((-0.16, 0.32, 0.22))
tube("Fur", bez([SH[-1], EL, PW], 8), [0.15, 0.14, 0.13, 0.13, 0.125, 0.12, 0.12, 0.12], seg=14)
sph("Belly", (0.13, 0.13, 0.08), PW + Vector((0, 0.02, 0.03)), seg=14, rings=10)          # flat upturned palm
sph("Pink", (0.06, 0.05, 0.02), PW + Vector((0, 0.03, 0.1)), seg=10, rings=6)            # paw pad
for dx in (-0.07, 0.0, 0.07):                                                              # fingers curl up round the item
    sph("Belly", (0.04, 0.04, 0.05), PW + Vector((dx, 0.12, 0.08)), seg=8, rings=6)
sph("Belly", (0.04, 0.04, 0.05), PW + Vector((0.11, 0.02, 0.08)), seg=8, rings=6)          # thumb
rosette(EL, Vector((0.13, 0.13, 0.13)), -90, 20, 0.05, k=1.0)
HOLD = PW + Vector((0, 0.03, 0.2))
PIVOTS["HoldL"] = HOLD
MODEL = "PreviewHeld"
sph("Carrot", 0.13, HOLD, seg=16, rings=10)
sph("Leaf", (0.07, 0.07, 0.03), HOLD + Vector((0, 0, 0.12)), seg=10, rings=6)

# ------------------------------------------------------------------ legs (pivot = hip)
for side, sx in (("L", -1), ("R", 1)):
    MODEL = "SnowLeopardLeg" + side
    hip = Vector((sx * 0.22, 0.0, 0.62))
    PIVOTS["Hip" + side] = hip
    ank = Vector((sx * 0.24, 0.02, 0.16))
    sph("Fur", (0.2, 0.22, 0.24), hip + Vector((0, 0, -0.08)), seg=16, rings=10)
    tube("Fur", lerp(hip, ank, 6), [0.18, 0.17, 0.16, 0.15, 0.145, 0.14], seg=14)
    sph("Belly", (0.16, 0.24, 0.11), Vector((sx * 0.25, 0.1, 0.1)), seg=16, rings=10)
    for dx in (-0.07, 0.0, 0.07):
        sph("Belly", (0.05, 0.05, 0.045), Vector((sx * 0.25 + dx, 0.31, 0.08)), seg=8, rings=6)
    rosette(hip + Vector((0, 0, -0.12)), Vector((0.2, 0.22, 0.24)), sx * 100, 0, 0.06, k=1.0)
    dot(ank + Vector((0, 0, 0.12)), Vector((0.15, 0.15, 0.15)), sx * 70, 0, 0.03, k=1.0)

# ------------------------------------------------------------------ tail (pivot = base): long, thick, curls up on the right, dark rings
MODEL = "SnowLeopardTail"
TB = TC + Vector((0, -0.34, -0.36))
PIVOTS["Tail"] = TB
tail = bez([TB, TB + Vector((0.05, -0.55, -0.35)), TB + Vector((0.55, -0.9, 0.0)), TB + Vector((0.6, -0.55, 0.75)), TB + Vector((0.42, -0.4, 0.95))], 34)
tr = [0.14 + 0.08 * min(1, i / 10) - (0.17 * ((i - 28) / 5) ** 1.6 if i > 28 else 0) for i in range(34)]
tube("Fur", tail[:29], tr[:29], seg=18)
tube("Spot", tail[28:], tr[28:], seg=18)                            # dark tip, tapers to a round end
sph("Spot", tr[-1], tail[-1], seg=14, rings=10)
for i in range(5, 28, 3):                                           # rosettes along the tail, two or three round it
    t = (tail[i + 1] - tail[i - 1]).normalized()
    a, b = frame(t, Vector((0, 0, 1)))
    for k in range(3):
        ang = math.radians(120 * k + 50 * i)
        nrm = a * math.cos(ang) + b * math.sin(ang)
        q = tail[i] + nrm * tr[i]
        qa, qb = frame(nrm, t)
        size = 0.06
        arc = [q + (qa * math.cos(math.radians(d)) + qb * math.sin(math.radians(d))) * size * 0.78 for d in range(0, 291, 30)]
        tube("Spot", arc, size * 0.22, seg=8, normal=nrm, flat=0.25)

# ------------------------------------------------------------------ build + export
by_model = {}
for (model, mat), bm in BM.items():
    me = bpy.data.meshes.new(model + "__" + mat)
    bm.to_mesh(me)
    bm.free()
    me.materials.append(MATS[mat])
    ob = bpy.data.objects.new(model + "__" + mat, me)
    bpy.context.scene.collection.objects.link(ob)
    by_model.setdefault(model, []).append(ob)

import json
objinfo = {}
for objs in by_model.values():
    for ob in objs:
        vs = [v.co for v in ob.data.vertices]
        lo = [min(c[k] for c in vs) for k in range(3)]
        hi = [max(c[k] for c in vs) for k in range(3)]
        objinfo[ob.name] = [round((lo[k] + hi[k]) / 2, 4) for k in range(3)] + [round(hi[k] - lo[k], 4) for k in range(3)]
with open(os.path.join(OUT, "objects_bbox.json"), "w") as fh:
    json.dump(objinfo, fh)
for k, v in PIVOTS.items():
    print("PIVOT", k, tuple(round(c, 3) for c in v))

allv_all = []
total = 0
for model, objs in by_model.items():
    tri = 0
    for ob in objs:
        ob.data.calc_loop_triangles()
        tri += len(ob.data.loop_triangles)
    total += tri
    allv = [v.co for ob in objs for v in ob.data.vertices]
    allv_all += allv
    lo = Vector(tuple(min(c[k] for c in allv) for k in range(3)))
    hi = Vector(tuple(max(c[k] for c in allv) for k in range(3)))
    print("MODEL", model, "OBJECTS", len(objs), "TRIS", tri, "BBOX_MIN", tuple(round(v, 3) for v in lo), "BBOX_MAX", tuple(round(v, 3) for v in hi))
    if model == "PreviewHeld":
        continue
    bpy.ops.object.select_all(action='DESELECT')
    for ob in objs:
        ob.select_set(True)
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, model + ".glb"), export_format='GLB',
                              use_selection=True, export_apply=True, export_yup=True)
print("TOTAL_TRIS", total)

scn = bpy.context.scene
scn.render.engine = 'BLENDER_WORKBENCH'
scn.display.shading.light = 'STUDIO'
scn.display.shading.color_type = 'MATERIAL'
scn.display.shading.show_cavity = True
scn.render.film_transparent = False
scn.world = scn.world or bpy.data.worlds.new("W")
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
scn.collection.objects.link(cam)
scn.camera = cam
lo = Vector(tuple(min(c[k] for c in allv_all) for k in range(3)))
hi = Vector(tuple(max(c[k] for c in allv_all) for k in range(3)))
print("WHOLE BBOX_MIN", tuple(round(v, 3) for v in lo), "BBOX_MAX", tuple(round(v, 3) for v in hi))
mid = (lo + hi) / 2
size = (hi - lo).length
VIEWS = [("front", Vector((0, 1, 0.12))), ("picture", Vector((-0.45, 1, 0.18))), ("side", Vector((1, 0.1, 0.1))),
         ("back", Vector((0.35, -1, 0.35))), ("face", Vector((0, 1, 0.05)))]
for vname, vdir in VIEWS:
    scn.render.resolution_x, scn.render.resolution_y = 800, 800
    cam.data.lens = 50
    f = mid if vname != "face" else Vector((0, 0.3, 1.8))
    dist = size * 1.25 if vname != "face" else 2.6
    cam.location = f + vdir.normalized() * dist
    cam.rotation_euler = (f - cam.location).to_track_quat('-Z', 'Y').to_euler()
    scn.render.filepath = os.path.join(OUT, "preview_%s.png" % vname)
    bpy.ops.render.render(write_still=True)
