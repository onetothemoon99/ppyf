# Seats for the mount gacha (2026-11-12): RiversideLog (Common), DuckFloat (Rare, floats), KrathongPavilion (Secret, floats).
# Run:  blender.exe -b --factory-startup -P build_seats.py -- <outdir>
# Units: 1 Blender unit = 1 stud, Z up. Origin = bottom centre (log) or the WATER LINE (duck, pavilion: z < 0 is under water).
# Front of every piece = -Y (Roblox -Z after import: Roblox = (-bx, bz, by)).
# Objects are named "<Model>__<Material>"; Studio colours them from COLORS (the importer drops colours).
# Output: <Model>.glb + preview_<Model>.png
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
    # log
    "Bark": (122, 84, 56), "Bark_Dark": (94, 62, 42), "Wood_Cut": (232, 200, 150), "Wood_Ring": (198, 158, 108),
    "Moss": (118, 176, 84), "Moss_Light": (160, 208, 110), "Rock": (150, 156, 166), "Rock_Dark": (118, 124, 136),
    "Shroom_Cap": (244, 150, 70), "Cream": (252, 242, 222), "Leaf": (96, 168, 78),
    "Bird": (110, 180, 240), "Bird_Belly": (250, 246, 236), "Orange": (250, 150, 50), "Black": (30, 30, 34),
    # duck
    "Duck": (255, 214, 64), "Duck_Light": (255, 236, 140), "White": (255, 255, 255), "Cheek": (255, 150, 160),
    "Float_Net": (150, 214, 244),
    # pavilion
    "Trunk_Top": (238, 232, 196), "Trunk_Ring": (206, 214, 160), "Banana_Leaf": (70, 150, 78), "Banana_Leaf_Light": (120, 190, 96),
    "Lotus": (255, 150, 190), "Lotus_Light": (255, 204, 222),
    "Post": (150, 70, 56), "Post_Dark": (112, 50, 42), "Floor": (206, 150, 100), "Floor_Dark": (176, 122, 80),
    "Roof": (226, 96, 62), "Roof_Dark": (190, 70, 50), "Gold": (246, 196, 72), "Gold_Dark": (212, 156, 48),
    "Lantern_Glow": (255, 150, 60), "Flame": (255, 200, 90), "Marigold": (255, 176, 40), "Candle": (250, 240, 214),
    "Cushion": (240, 120, 150),
}
MATS = {}
for name, rgb in COLORS.items():
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    col = tuple(lin(v) for v in rgb) + (1.0,)
    next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED").inputs["Base Color"].default_value = col
    m.diffuse_color = col
    MATS[name] = m

BM = {}  # (model, mat) -> bmesh
MODEL = "X"
def target(mat):
    assert mat in COLORS, mat
    return BM.setdefault((MODEL, mat), bmesh.new())

def xf(loc=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1)):
    S = Matrix.Diagonal((scale[0], scale[1], scale[2], 1.0))
    return Matrix.Translation(Vector(loc)) @ Euler(tuple(math.radians(a) for a in rot), 'XYZ').to_matrix().to_4x4() @ S

def box(mat, size, loc, rot=(0, 0, 0)):
    bmesh.ops.create_cube(target(mat), size=1.0, matrix=xf(loc, rot, size))

def sph(mat, scale, loc, rot=(0, 0, 0), seg=14, rings=9):
    if isinstance(scale, (int, float)):
        scale = (scale, scale, scale)
    r = bmesh.ops.create_uvsphere(target(mat), u_segments=seg, v_segments=rings, radius=1.0, matrix=xf(loc, rot, scale))
    for v in r["verts"]:
        for f in v.link_faces:
            f.smooth = True

def cyl(mat, r1, r2, depth, loc, rot=(0, 0, 0), seg=14):
    """Cone/cylinder along local Z, centred at loc. r1 = bottom radius, r2 = top radius."""
    r = bmesh.ops.create_cone(target(mat), cap_ends=True, cap_tris=False, segments=seg, radius1=r1, radius2=max(r2, 0.0001),
                              depth=depth, matrix=xf(loc, rot))
    for v in r["verts"]:
        for f in v.link_faces:
            if len(f.verts) == 4:
                f.smooth = True

def hull(mat, pts):
    bm = target(mat)
    vs = [bm.verts.new(Vector(p)) for p in pts]
    r = bmesh.ops.convex_hull(bm, input=vs)
    faces = [g for g in r["geom"] if isinstance(g, bmesh.types.BMFace)]
    bmesh.ops.recalc_face_normals(bm, faces=faces)
    junk = [v for v in vs if v.is_valid and not v.link_faces]
    if junk:
        bmesh.ops.delete(bm, geom=junk, context='VERTS')

def tube(mat, pts, radii, seg=10, closed=False, caps=True, squash=1.0):
    """Sweep a circle along a polyline. radii = one number or one per point. squash scales the ring along world Z-ish 'up'."""
    bm = target(mat)
    pts = [Vector(p) for p in pts]
    n = len(pts)
    if isinstance(radii, (int, float)):
        radii = [radii] * n
    rings = []
    up0 = Vector((0, 0, 1))
    for i, p in enumerate(pts):
        if closed:
            t = pts[(i + 1) % n] - pts[(i - 1) % n]
        else:
            t = pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]
        t.normalize()
        up = up0 if abs(t.dot(up0)) < 0.95 else Vector((0, 1, 0))
        a = t.cross(up).normalized()
        b = a.cross(t).normalized()
        ring = []
        for k in range(seg):
            ang = 2 * math.pi * k / seg
            ring.append(bm.verts.new(p + a * (math.cos(ang) * radii[i]) + b * (math.sin(ang) * radii[i] * squash)))
        rings.append(ring)
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

def circle_pts(R, z, n, phase=0.0):
    return [(R * math.cos(phase + 2 * math.pi * k / n), R * math.sin(phase + 2 * math.pi * k / n), z) for k in range(n)]

def petal(mat, ang, r0, r1, z0, z1, width, thick=0.14):
    """Pointed leaf/petal: base at radius r0 (height z0), tip at radius r1 (height z1), leaning outward."""
    c, s = math.cos(ang), math.sin(ang)
    def P(r, side, z):
        return (r * c - side * s, r * s + side * c, z)
    rm = r0 + (r1 - r0) * 0.45
    zm = z0 + (z1 - z0) * 0.4
    pts = []
    for dz in (0.0, thick):
        pts += [P(r0, -width * 0.5, z0 + dz), P(r0, width * 0.5, z0 + dz), P(rm, -width * 0.62, zm + dz), P(rm, width * 0.62, zm + dz)]
    pts += [P(r1, 0, z1), P(r1 - 0.05, 0, z1 + thick * 0.6)]
    hull(mat, pts)

# =================================================================== 1) RiversideLog  (origin = ground, log along X)
MODEL = "RiversideLog"
LOG_R, LOG_Z, LOG_L = 0.9, 0.98, 6.4
xs = [-LOG_L / 2 + LOG_L * i / 8 for i in range(9)]
rad = [0.86, 0.9, 0.93, 0.9, 0.88, 0.9, 0.94, 0.92, 0.88]
tube("Bark", [(x, 0, LOG_Z) for x in xs], rad, seg=16, caps=True)
for sx in (-1, 1):
    x = sx * LOG_L / 2
    cyl("Wood_Cut", 0.78, 0.78, 0.06, (x + sx * 0.02, 0, LOG_Z), rot=(0, 90, 0), seg=16)
    cyl("Wood_Ring", 0.5, 0.5, 0.06, (x + sx * 0.035, 0, LOG_Z), rot=(0, 90, 0), seg=16)
    cyl("Wood_Cut", 0.3, 0.3, 0.06, (x + sx * 0.05, 0, LOG_Z), rot=(0, 90, 0), seg=14)
    cyl("Wood_Ring", 0.1, 0.1, 0.06, (x + sx * 0.065, 0, LOG_Z), rot=(0, 90, 0), seg=10)
# bark bands + a knot
for x, r in ((-1.9, 0.95), (0.55, 0.93), (2.3, 0.96)):
    tube("Bark_Dark", [(x - 0.09, 0, LOG_Z), (x + 0.09, 0, LOG_Z)], r, seg=16, caps=False)
tube("Bark_Dark", [(0.2 + 0.2 * math.cos(a), -0.86 - 0.02, LOG_Z + 0.1 + 0.2 * math.sin(a)) for a in [2 * math.pi * k / 10 for k in range(10)]],
     0.07, seg=6, closed=True)
# branch stub with leaves
tube("Bark", [(-2.35, 0.25, 1.6), (-2.5, 0.42, 2.15), (-2.55, 0.5, 2.55)], [0.24, 0.2, 0.17], seg=10)
cyl("Wood_Cut", 0.15, 0.15, 0.04, (-2.552, 0.505, 2.57), rot=(-10, -6, 0), seg=10)
hull("Leaf", [(-2.5, 0.42, 2.2), (-2.1, 0.75, 2.5), (-1.75, 0.8, 2.42), (-2.05, 0.5, 2.3), (-2.1, 0.7, 2.56)])
hull("Leaf", [(-2.52, 0.45, 2.3), (-2.95, 0.65, 2.62), (-3.25, 0.6, 2.5), (-2.9, 0.4, 2.42), (-2.95, 0.6, 2.68)])
# moss on top (kept low so the seats stay clear at x = -1.2 / +1.5)
for (x, y, sx, sy, m) in ((-3.0, 0.1, 0.5, 0.55, "Moss"), (0.15, -0.25, 0.42, 0.4, "Moss_Light"), (0.3, 0.3, 0.5, 0.42, "Moss"),
                          (2.95, -0.1, 0.5, 0.6, "Moss"), (2.75, 0.4, 0.3, 0.3, "Moss_Light")):
    z = LOG_Z + math.sqrt(max(0.9 ** 2 - y * y, 0.01)) - 0.06
    sph(m, (sx, sy, 0.13), (x, y, z), seg=10, rings=6)
# little mushrooms at the front foot of the log
for (x, y, h, r) in ((2.2, -1.05, 0.55, 0.3), (2.65, -0.95, 0.38, 0.22), (1.85, -1.2, 0.3, 0.18)):
    cyl("Cream", r * 0.4, r * 0.32, h, (x, y, h / 2), seg=8)
    sph("Shroom_Cap", (r, r, r * 0.62), (x, y, h + r * 0.1), seg=12, rings=7)
    for k in range(4):
        a = k * 1.7 + x
        sph("Cream", r * 0.14, (x + r * 0.55 * math.cos(a), y + r * 0.55 * math.sin(a), h + r * 0.52), seg=6, rings=4)
# wedge rocks so the log does not roll
def rock(c, s, dark=False):
    cx, cy, cz = c
    pts = []
    for k in range(7):
        a = 2 * math.pi * k / 7
        pts.append((cx + s * math.cos(a) * (0.9 + 0.2 * math.sin(k * 2.3)), cy + s * 0.8 * math.sin(a), cz))
        pts.append((cx + s * 0.62 * math.cos(a + 0.4), cy + s * 0.5 * math.sin(a + 0.4), cz + s * (0.62 + 0.14 * math.cos(k * 1.9))))
    hull("Rock_Dark" if dark else "Rock", pts)
rock((-2.4, -0.95, 0), 0.55); rock((-2.0, 1.0, 0), 0.5, True); rock((2.5, 1.0, 0), 0.58); rock((-0.4, -1.0, 0), 0.4, True)
# a small bird on the stub side of the log
bx, by, bz = 2.95, 0.05, LOG_Z + 0.9 + 0.2
sph("Bird", (0.2, 0.26, 0.2), (bx, by, bz), seg=10, rings=7)
sph("Bird_Belly", (0.15, 0.17, 0.15), (bx, by - 0.1, bz - 0.04), seg=8, rings=6)
sph("Bird", 0.16, (bx, by - 0.16, bz + 0.24), seg=10, rings=7)
cyl("Orange", 0.05, 0.0, 0.14, (bx, by - 0.36, bz + 0.22), rot=(90, 0, 0), seg=6)
for sx in (-1, 1):
    sph("Black", 0.03, (bx + sx * 0.1, by - 0.28, bz + 0.28), seg=6, rings=4)
hull("Bird", [(bx - 0.08, by + 0.2, bz), (bx + 0.08, by + 0.2, bz), (bx, by + 0.5, bz + 0.14), (bx, by + 0.22, bz + 0.08)])

# =================================================================== 2) DuckFloat  (origin = water line, head at -Y)
MODEL = "DuckFloat"
RING_R, RING_r, RING_Z = 1.95, 0.74, 0.34
tube("Duck", circle_pts(RING_R, RING_Z, 28), RING_r, seg=14, closed=True, squash=0.92)
# highlight stripe on top of the ring
tube("Duck_Light", [(RING_R * math.cos(a), RING_R * math.sin(a), RING_Z + RING_r * 0.9) for a in [math.radians(20 + 5 * k) for k in range(29)]],
     0.09, seg=6, squash=0.5)
# seat net in the hole
cyl("Float_Net", 1.3, 1.36, 0.1, (0, 0, 0.12), seg=20)
# neck + head
tube("Duck", [(0, -1.95, 0.8), (0, -2.05, 1.35), (0, -2.1, 1.8)], [0.62, 0.55, 0.6], seg=12)
HX, HY, HZ = 0, -2.15, 2.2
sph("Duck", (0.98, 0.95, 0.9), (HX, HY, HZ), seg=18, rings=12)
tube("Duck", [(0, HY + 0.1, HZ + 0.8), (0.05, HY + 0.25, HZ + 1.08), (0.0, HY + 0.5, HZ + 1.16)], [0.13, 0.1, 0.03], seg=6)
tube("Duck", [(0.1, HY + 0.15, HZ + 0.8), (0.25, HY + 0.3, HZ + 1.0), (0.3, HY + 0.52, HZ + 1.0)], [0.1, 0.08, 0.02], seg=6)
# beak, eyes, cheeks
sph("Orange", (0.5, 0.5, 0.2), (HX, HY - 0.98, HZ - 0.12), seg=12, rings=7)
sph("Orange", (0.42, 0.4, 0.13), (HX, HY - 0.93, HZ - 0.3), seg=12, rings=6)
for sx in (-1, 1):
    sph("Black", (0.14, 0.1, 0.17), (HX + sx * 0.42, HY - 0.8, HZ + 0.2), seg=10, rings=7)
    sph("White", 0.05, (HX + sx * 0.4, HY - 0.89, HZ + 0.27), seg=6, rings=4)
    sph("Cheek", (0.2, 0.08, 0.13), (HX + sx * 0.66, HY - 0.63, HZ - 0.12), rot=(0, 0, sx * 35), seg=8, rings=5)
    # wings on the ring sides
    sph("Duck_Light", (0.24, 0.95, 0.52), (sx * (RING_R + RING_r * 0.82), 0.25, RING_Z + 0.22), rot=(0, sx * -18, sx * 8), seg=12, rings=7)
    sph("Duck", (0.2, 0.6, 0.34), (sx * (RING_R + RING_r * 0.95), 0.55, RING_Z + 0.2), rot=(0, sx * -18, sx * 14), seg=10, rings=6)
# tail
hull("Duck", [(-0.5, 1.9, 0.75), (0.5, 1.9, 0.75), (-0.42, 2.45, 0.7), (0.42, 2.45, 0.7), (0, 3.1, 1.55), (0, 2.2, 1.15), (-0.3, 2.0, 1.05), (0.3, 2.0, 1.05)])

# =================================================================== 3) KrathongPavilion  (origin = water line, front -Y)
MODEL = "KrathongPavilion"
DECK_R, DECK_TOP = 4.0, 0.55
# banana-trunk raft (the krathong base)
cyl("Banana_Leaf", DECK_R, DECK_R, 1.0, (0, 0, DECK_TOP - 0.5 - 0.04), seg=28)
cyl("Trunk_Top", DECK_R - 0.12, DECK_R - 0.12, 0.06, (0, 0, DECK_TOP - 0.03), seg=28)
for r in (3.3, 2.5):
    tube("Trunk_Ring", circle_pts(r, DECK_TOP + 0.005, 28), 0.045, seg=4, closed=True, squash=0.3)
# folded banana-leaf petals round the rim (two rows) + pink lotus petals
N = 18
for k in range(N):
    a = 2 * math.pi * k / N
    petal("Banana_Leaf", a, DECK_R - 0.25, DECK_R + 1.25, 0.2, 1.3, 1.5)
    petal("Banana_Leaf_Light", a + math.pi / N, DECK_R - 0.45, DECK_R + 0.75, 0.42, 1.55, 1.25)
for k in range(12):
    a = 2 * math.pi * (k + 0.5) / 12
    petal("Lotus" if k % 2 == 0 else "Lotus_Light", a, DECK_R - 0.75, DECK_R + 0.05, 0.56, 1.25, 0.95, thick=0.1)
# wooden floor
FL = 2.75  # half size of the floor
box("Floor", (FL * 2, FL * 2, 0.22), (0, 0, DECK_TOP + 0.11))
for i in range(-3, 4):
    box("Floor_Dark", (0.06, FL * 2 - 0.1, 0.03), (i * 0.76, 0, DECK_TOP + 0.225))
box("Post_Dark", (FL * 2 + 0.14, 0.14, 0.26), (0, FL, DECK_TOP + 0.13)); box("Post_Dark", (FL * 2 + 0.14, 0.14, 0.26), (0, -FL, DECK_TOP + 0.13))
box("Post_Dark", (0.14, FL * 2 + 0.14, 0.26), (FL, 0, DECK_TOP + 0.13)); box("Post_Dark", (0.14, FL * 2 + 0.14, 0.26), (-FL, 0, DECK_TOP + 0.13))
# posts
PX, POST_H = 2.45, 4.7
Z0 = DECK_TOP + 0.22
for sx in (-1, 1):
    for sy in (-1, 1):
        x, y = sx * PX, sy * PX
        cyl("Post", 0.2, 0.18, POST_H, (x, y, Z0 + POST_H / 2), seg=10)
        cyl("Gold", 0.3, 0.24, 0.26, (x, y, Z0 + 0.13), seg=10)
        cyl("Gold", 0.24, 0.3, 0.24, (x, y, Z0 + POST_H - 0.12), seg=10)
# railings: back and both sides (front open)
def rail(p0, p1):
    p0, p1 = Vector(p0), Vector(p1)
    for z in (1.05, 0.5):
        tube("Post_Dark", [p0 + Vector((0, 0, Z0 + z)), p1 + Vector((0, 0, Z0 + z))], 0.07, seg=6)
    for i in range(1, 6):
        p = p0.lerp(p1, i / 6)
        cyl("Gold", 0.05, 0.05, 0.55, (p.x, p.y, Z0 + 0.78), seg=6)
rail((-PX, PX, 0), (PX, PX, 0)); rail((-PX, -PX, 0), (-PX, PX, 0)); rail((PX, -PX, 0), (PX, PX, 0))
# bench at the back with cushions (2 seats, facing -Y)
BENCH_Y, BENCH_TOP = 1.45, Z0 + 1.25
box("Post", (4.2, 1.3, 0.16), (0, BENCH_Y, BENCH_TOP - 0.2))
for sx in (-1, 1):
    box("Post_Dark", (0.2, 1.1, BENCH_TOP - 0.28 - Z0), (sx * 1.85, BENCH_Y, Z0 + (BENCH_TOP - 0.28 - Z0) / 2))
    sph("Cushion", (0.85, 0.58, 0.14), (sx * 1.0, BENCH_Y, BENCH_TOP - 0.06), seg=12, rings=6)
# beams under the roof
RZ = Z0 + POST_H
for sy in (-1, 1):
    box("Post_Dark", (PX * 2 + 0.9, 0.22, 0.24), (0, sy * PX, RZ + 0.1))
    box("Post_Dark", (0.22, PX * 2 + 0.9, 0.24), (sy * PX, 0, RZ + 0.1))
# lower hip roof (frustum) with gold edge, then steep upper gable roof (ridge along X)
E1, E2 = 3.75, 2.05
z1, z2 = RZ + 0.2, RZ + 1.5
hull("Roof", [(sx * E1, sy * E1, z1) for sx in (-1, 1) for sy in (-1, 1)] + [(sx * E1, sy * E1, z1 + 0.14) for sx in (-1, 1) for sy in (-1, 1)]
     + [(sx * E2, sy * E2, z2) for sx in (-1, 1) for sy in (-1, 1)])
for sy in (-1, 1):
    box("Gold", (E1 * 2 + 0.12, 0.14, 0.2), (0, sy * E1, z1 + 0.06)); box("Gold", (0.14, E1 * 2 + 0.12, 0.2), (sy * E1, 0, z1 + 0.06))
for sx in (-1, 1):
    for sy in (-1, 1):
        tube("Gold_Dark", [(sx * E1, sy * E1, z1 + 0.16), (sx * E2, sy * E2, z2 + 0.03)], 0.08, seg=6)
        # corner hooks (hang hong)
        tube("Gold", [(sx * E1, sy * E1, z1 + 0.1), (sx * (E1 + 0.3), sy * (E1 + 0.3), z1 + 0.25), (sx * (E1 + 0.45), sy * (E1 + 0.45), z1 + 0.6)],
             [0.1, 0.08, 0.02], seg=6)
# roof tile rows on the lower roof
for i in range(1, 4):
    t = i / 4
    e, z = E1 + (E2 - E1) * t, z1 + (z2 - z1) * t + 0.1
    for sy in (-1, 1):
        box("Roof_Dark", (e * 2, 0.07, 0.07), (0, sy * e, z)); box("Roof_Dark", (0.07, e * 2, 0.07), (sy * e, 0, z))
G_X, G_Y = 2.3, 1.75
z3 = z2 + 2.0
hull("Roof", [(sx * G_X, sy * G_Y, z2 - 0.02) for sx in (-1, 1) for sy in (-1, 1)] + [(sx * G_X, sy * G_Y, z2 + 0.12) for sx in (-1, 1) for sy in (-1, 1)]
     + [(-G_X, 0, z3), (G_X, 0, z3)])
tube("Gold", [(-G_X - 0.1, 0, z3 + 0.03), (G_X + 0.1, 0, z3 + 0.03)], 0.1, seg=6)
for sx in (-1, 1):
    # gable boards + chofa finial
    hull("Gold", [(sx * (G_X + 0.02), -G_Y - 0.1, z2 + 0.02), (sx * (G_X + 0.14), -G_Y - 0.1, z2 + 0.02), (sx * (G_X + 0.02), 0, z3 + 0.14),
                  (sx * (G_X + 0.14), 0, z3 + 0.14), (sx * (G_X + 0.02), -G_Y + 0.12, z2 + 0.02), (sx * (G_X + 0.14), -G_Y + 0.12, z2 + 0.02),
                  (sx * (G_X + 0.02), 0, z3 - 0.1), (sx * (G_X + 0.14), 0, z3 - 0.1)])
    hull("Gold", [(sx * (G_X + 0.02), G_Y + 0.1, z2 + 0.02), (sx * (G_X + 0.14), G_Y + 0.1, z2 + 0.02), (sx * (G_X + 0.02), 0, z3 + 0.14),
                  (sx * (G_X + 0.14), 0, z3 + 0.14), (sx * (G_X + 0.02), G_Y - 0.12, z2 + 0.02), (sx * (G_X + 0.14), G_Y - 0.12, z2 + 0.02),
                  (sx * (G_X + 0.02), 0, z3 - 0.1), (sx * (G_X + 0.14), 0, z3 - 0.1)])
    hull("Lotus_Light", [(sx * (G_X - 0.02), -G_Y + 0.3, z2 + 0.14), (sx * (G_X - 0.02), G_Y - 0.3, z2 + 0.14), (sx * (G_X - 0.02), 0, z3 - 0.3),
                         (sx * (G_X + 0.04), -G_Y + 0.3, z2 + 0.14), (sx * (G_X + 0.04), G_Y - 0.3, z2 + 0.14), (sx * (G_X + 0.04), 0, z3 - 0.3)])
    tube("Gold", [(sx * (G_X + 0.08), 0, z3 + 0.05), (sx * (G_X + 0.3), 0, z3 + 0.45), (sx * (G_X + 0.32), 0, z3 + 0.95), (sx * (G_X + 0.1), 0, z3 + 1.35)],
         [0.13, 0.11, 0.08, 0.02], seg=6)
# marigold garlands along the front and side eaves
def garland(p0, p1, sag=0.45, n=11):
    p0, p1 = Vector(p0), Vector(p1)
    for i in range(n):
        t = i / (n - 1)
        p = p0.lerp(p1, t) - Vector((0, 0, sag * math.sin(math.pi * t)))
        sph("Marigold" if i % 2 == 0 else "Lotus", 0.13, p, seg=6, rings=4)
gz = z1 - 0.12
garland((-PX, -E1 + 0.1, gz), (0, -E1 + 0.1, gz)); garland((0, -E1 + 0.1, gz), (PX, -E1 + 0.1, gz))
garland((-E1 + 0.1, -PX, gz), (-E1 + 0.1, PX, gz), n=15); garland((E1 - 0.1, -PX, gz), (E1 - 0.1, PX, gz), n=15)
# hanging lanterns at the four roof corners (LanternGlow = separate neon mesh)
for sx in (-1, 1):
    for sy in (-1, 1):
        x, y = sx * (E1 - 0.25), sy * (E1 - 0.25)
        cyl("Post_Dark", 0.025, 0.025, 0.6, (x, y, z1 - 0.3), seg=5)
        cyl("Gold", 0.16, 0.2, 0.1, (x, y, z1 - 0.62), seg=8)
        sph("Lantern_Glow", (0.36, 0.36, 0.42), (x, y, z1 - 1.05), seg=10, rings=7)
        cyl("Gold", 0.2, 0.14, 0.1, (x, y, z1 - 1.48), seg=8)
        cyl("Roof", 0.04, 0.02, 0.4, (x, y, z1 - 1.72), seg=5)
# small krathongs with candles on the two front corners of the floor + a big lotus offering in front
def mini_krathong(c, r=0.42):
    cx, cy, cz = c
    cyl("Banana_Leaf", r, r * 0.9, 0.16, (cx, cy, cz + 0.08), seg=10)
    for k in range(8):
        a = 2 * math.pi * k / 8
        hull("Banana_Leaf_Light" if k % 2 else "Banana_Leaf",
             [(cx + r * 0.6 * math.cos(a - 0.3), cy + r * 0.6 * math.sin(a - 0.3), cz + 0.12),
              (cx + r * 0.6 * math.cos(a + 0.3), cy + r * 0.6 * math.sin(a + 0.3), cz + 0.12),
              (cx + r * 1.25 * math.cos(a), cy + r * 1.25 * math.sin(a), cz + 0.42),
              (cx + r * 0.9 * math.cos(a), cy + r * 0.9 * math.sin(a), cz + 0.16)])
        sph("Marigold", r * 0.2, (cx + r * 0.5 * math.cos(a + 0.4), cy + r * 0.5 * math.sin(a + 0.4), cz + 0.22), seg=6, rings=4)
    cyl("Candle", r * 0.14, r * 0.14, 0.42, (cx, cy, cz + 0.36), seg=6)
    sph("Flame", (r * 0.14, r * 0.14, r * 0.28), (cx, cy, cz + 0.66), seg=6, rings=5)
mini_krathong((-1.9, -2.1, Z0)); mini_krathong((1.9, -2.1, Z0))
mini_krathong((0, -3.35, DECK_TOP), r=0.5)
# lotus buds at the back corners of the raft
for (x, y) in ((-2.9, 2.2), (2.9, 2.2), (-3.2, -1.2), (3.2, -1.2)):
    for k in range(6):
        a = 2 * math.pi * k / 6
        hull("Lotus" if k % 2 else "Lotus_Light",
             [(x + 0.1 * math.cos(a - 0.5), y + 0.1 * math.sin(a - 0.5), DECK_TOP), (x + 0.1 * math.cos(a + 0.5), y + 0.1 * math.sin(a + 0.5), DECK_TOP),
              (x + 0.34 * math.cos(a), y + 0.34 * math.sin(a), DECK_TOP + 0.3), (x + 0.16 * math.cos(a), y + 0.16 * math.sin(a), DECK_TOP + 0.62)])
    sph("Marigold", 0.1, (x, y, DECK_TOP + 0.2), seg=6, rings=4)

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
scn.display.shading.show_backface_culling = True
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
scn.collection.objects.link(cam)
scn.camera = cam

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
    scn.render.resolution_x, scn.render.resolution_y = 1000, 800
    cam.data.lens = 40
    cam.location = mid + Vector((-0.55, -1.0, 0.5)).normalized() * size * 1.35
    cam.rotation_euler = (mid - cam.location).to_track_quat('-Z', 'Y').to_euler()
    scn.render.filepath = os.path.join(OUT, "preview_" + model + ".png")
    bpy.ops.render.render(write_still=True)
