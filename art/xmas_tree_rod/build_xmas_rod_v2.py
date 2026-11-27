# Christmas rod v2 (เบ็ดคริสต์มาส, RodId XmasTree, 199 R$) — look from the user's concept picture (2026-11-27):
#   candy-cane pole, warm fairy lights, holly, gold star tip, a reindeer cub hugging the pole (Santa hat, red scarf),
#   big red bow with a gold star at the reel, gold reel with glowing snowflakes, red grip with snow cuff + gold cap,
#   snowman bobber with a Santa hat and a red/green scarf.  v1 (pine tree) = build_xmas_tree_rod.py.
# Run:  blender.exe -b --factory-startup -P build_xmas_rod_v2.py -- <outdir>
# Units: 1 Blender unit = 1 stud. Rod built STRAIGHT UP along +Z, hand (Roblox Handle) at the origin, reel underside (-Y),
#   line guides on top (+Y), reindeer on the +X side. Line point = top of the star at (0, 0, 6.16) (same as v1).
#   Bobber: origin = water line. Objects are named "<Model>__<Material>"; Studio colours them from COLORS.
#   Neon in Studio: BulbWarm, Flake, Star.
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
    "Red": (214, 30, 42), "RedDeep": (150, 16, 28), "Snow": (248, 250, 255), "Gold": (240, 186, 60), "Star": (255, 214, 80),
    "Wire": (40, 70, 40), "BulbWarm": (255, 222, 130), "Holly": (30, 120, 50), "Berry": (220, 25, 35),
    "Flake": (255, 236, 170),
    "Fur": (250, 238, 224), "FurPink": (255, 186, 186), "Antler": (150, 96, 56), "Nose": (235, 40, 45), "Eye": (50, 30, 30),
    "Scarf": (205, 30, 40), "ScarfGreen": (40, 130, 60), "Carrot": (255, 140, 40), "Coal": (30, 30, 34),
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

def sph_m(mat, M, seg=12, rings=8):
    r = bmesh.ops.create_uvsphere(target(mat), u_segments=seg, v_segments=rings, radius=1.0, matrix=M)
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

def tube(mat, pts, radii, seg=8, closed=False, caps=True, normal=(0, 0, 1), flat=1.0):
    """Sweep an ellipse along a polyline. radii = width per point; flat = thickness / width (1 = round)."""
    bm = target(mat)
    pts = [Vector(p) for p in pts]
    n = len(pts)
    if isinstance(radii, (int, float)):
        radii = [radii] * n
    nv = Vector(normal).normalized()
    rings = []
    for i, p in enumerate(pts):
        t = (pts[(i + 1) % n] - pts[(i - 1) % n]) if closed else (pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)])
        t.normalize()
        a, b = frame(t, nv)
        w = radii[i]
        th = max(w * flat, 0.005) if flat < 1 else w
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

def lathe(mat, prof, center=(0, 0, 0), seg=24, closed=True):
    """Revolve a (r, z) profile around +Z. closed = join the last profile point back to the first (a shell)."""
    bm = target(mat)
    c = Vector(center)
    rings = [[bm.verts.new(c + Vector((r * math.cos(2 * math.pi * k / seg), r * math.sin(2 * math.pi * k / seg), z))) for k in range(seg)]
             for r, z in prof]
    faces = []
    n = len(rings)
    for i in range(n if closed else n - 1):
        r0, r1 = rings[i], rings[(i + 1) % n]
        for k in range(seg):
            f = bm.faces.new((r0[k], r0[(k + 1) % seg], r1[(k + 1) % seg], r1[k]))
            f.smooth = True
            faces.append(f)
    bmesh.ops.recalc_face_normals(bm, faces=faces)

def basis(center, normal):
    z = Vector(normal).normalized()
    x = z.cross(Vector((0, 0, 1)))
    if x.length < 1e-4:
        x = z.cross(Vector((1, 0, 0)))
    x.normalize()
    y = z.cross(x).normalized()
    M = Matrix.Identity(4)
    for i in range(3):
        M[i][0], M[i][1], M[i][2], M[i][3] = x[i], y[i], z[i], Vector(center)[i]
    return M

def scallops(mat, R, z, n, size, center=(0, 0, 0)):
    c = Vector(center)
    for k in range(n):
        a = 2 * math.pi * (k + 0.5) / n
        sph(mat, (size, size * 0.8, size * 0.55), c + Vector((R * math.cos(a), R * math.sin(a), z)), rot=(0, 0, math.degrees(a)), seg=8, rings=5)

def wavy(p0, length, n, amp, freq, phase, drift=(0, 0)):
    """Points hanging down from p0 with a sideways sine wave (tentacle)."""
    p0 = Vector(p0)
    out = []
    for i in range(n):
        u = i / (n - 1)
        out.append(p0 + Vector((drift[0] * u + amp * u * math.sin(freq * u * math.pi + phase),
                                drift[1] * u + amp * u * math.cos(freq * u * math.pi + phase * 1.3), -length * u)))
    return out

def star(mat, center, normal, up, R, r, depth, n=5):
    """Faceted 3D star: 2n rim points (R / r alternating) joined to a front and a back apex. First point along `up`."""
    bm = target(mat)
    c, nv = Vector(center), Vector(normal).normalized()
    u = Vector(up).normalized()
    s = u.cross(nv).normalized()
    rim = []
    for k in range(2 * n):
        a = math.pi * k / n
        rad = R if k % 2 == 0 else r
        rim.append(bm.verts.new(c + (u * math.cos(a) + s * math.sin(a)) * rad))
    F, B = bm.verts.new(c + nv * depth), bm.verts.new(c - nv * depth)
    faces = []
    for k in range(2 * n):
        v0, v1 = rim[k], rim[(k + 1) % (2 * n)]
        faces.append(bm.faces.new((F, v0, v1)))
        faces.append(bm.faces.new((B, v1, v0)))
    bmesh.ops.recalc_face_normals(bm, faces=faces)


def candy(z0, z1, rfun, turns, stripes=2, seg=24, step=0.04, frac=0.45):
    """Candy-cane tube: every quad goes to Red or Snow by a helix test (verts shared inside each colour = smooth)."""
    nz = max(2, int((z1 - z0) / step) + 1)
    zs = [z0 + (z1 - z0) * i / (nz - 1) for i in range(nz)]
    grids = {}
    for mat in ("Red", "Snow"):
        bm = target(mat)
        grids[mat] = (bm, [[bm.verts.new((rfun(z) * math.cos(2 * math.pi * k / seg), rfun(z) * math.sin(2 * math.pi * k / seg), z))
                            for k in range(seg)] for z in zs])
    for i in range(nz - 1):
        zm = (zs[i] + zs[i + 1]) / 2
        for k in range(seg):
            u = ((k + 0.5) / seg + turns * (zm - z0) / (z1 - z0)) * stripes % 1.0
            bm, g = grids["Red" if u < frac else "Snow"]
            f = bm.faces.new((g[i][k], g[i][(k + 1) % seg], g[i + 1][(k + 1) % seg], g[i + 1][k]))
            f.smooth = True
    for mat, (bm, g) in grids.items():
        loose = [v for v in bm.verts if not v.link_faces]
        bmesh.ops.delete(bm, geom=loose, context='VERTS')

def ring(mat, center, normal, R, r, seg=24, tseg=8):
    """Torus ring around `normal` (snow cuffs, brims, rims)."""
    F = basis(center, normal)
    tube(mat, [F @ Vector((R * math.cos(2 * math.pi * k / seg), R * math.sin(2 * math.pi * k / seg), 0)) for k in range(seg)],
         r, seg=tseg, closed=True, caps=False, normal=normal)

def fluff(center, normal, R, n, size):
    """Fluffy snow trim: a ring + bumps."""
    ring("Snow", center, normal, R, size * 0.75)
    F = basis(center, normal)
    for k in range(n):
        a = 2 * math.pi * (k + 0.5) / n
        sph("Snow", size, F @ Vector((R * math.cos(a), R * math.sin(a), 0)), seg=8, rings=6)

def snowflake(center, normal, R, w):
    """Six-arm snowflake (Flake = Neon in Studio)."""
    F = basis(center, normal)
    sph_m("Flake", F @ Matrix.Diagonal((w * 2.2, w * 2.2, w * 0.8, 1.0)), seg=10, rings=6)
    for k in range(6):
        a = 2 * math.pi * k / 6
        d = Vector((math.cos(a), math.sin(a), 0))
        tube("Flake", [F @ (d * 0.0), F @ (d * R)], w, seg=5)
        for t in (0.45, 0.72):
            for s in (1, -1):
                b = Vector((math.cos(a + s * 0.75), math.sin(a + s * 0.75), 0))
                tube("Flake", [F @ (d * R * t), F @ (d * R * t + b * R * 0.28)], w * 0.8, seg=4)

def holly(center, out, size):
    F = basis(center, out)
    for k, a in enumerate((90, 210, 330)):
        R = F @ Matrix.Rotation(math.radians(a), 4, 'Z')
        sph_m("Holly", R @ xf((size * 0.9, 0, 0), (0, 0, 0), (size, size * 0.38, size * 0.12)), seg=12, rings=6)
        for s in (1, -1):   # little spikes on the leaf edge
            for t in (0.45, 1.05, 1.55):
                sph_m("Holly", R @ xf((size * t, s * size * 0.33, 0), (0, 0, s * 35), (size * 0.12, size * 0.1, size * 0.08)), seg=6, rings=4)
    for k in range(3):
        a = 2 * math.pi * k / 3 + 0.5
        sph("Berry", size * 0.28, F @ Vector((size * 0.2 * math.cos(a), size * 0.2 * math.sin(a), size * 0.25)), seg=10, rings=7)

# =================================================================== 1) XmasRod2
MODEL = "XmasRod2"
POLE_R = lambda z: 0.066 + (0.025 - 0.066) * (z - 1.0) / (5.5 - 1.0)

# butt: gold end cap + red cuff with snow fluff and gold stars (like the bottom of the picture)
cyl("Gold", 0.155, 0.13, 0.1, (0, 0, -0.63), seg=20)
sph("Gold", (0.155, 0.155, 0.05), (0, 0, -0.68), seg=20, rings=8)
cyl("Red", 0.135, 0.128, 0.28, (0, 0, -0.44), seg=20)
fluff((0, 0, -0.3), (0, 0, 1), 0.135, 14, 0.042)
for s in (1, -1):
    star("Gold", (s * 0.134, 0, -0.46), (s, 0, 0), (0, 0, 1), 0.065, 0.027, 0.018)

# grip: red with two thin gold bands, snow cuff on top
cyl("Red", 0.11, 0.1, 0.8, (0, 0, 0.12), seg=18)
for z in (0.02, 0.32):
    ring("Gold", (0, 0, z), (0, 0, 1), 0.108, 0.012, seg=20, tseg=6)
fluff((0, 0, 0.56), (0, 0, 1), 0.1, 12, 0.036)

# candy-cane pole + gold collars
candy(0.58, 5.45, lambda z: POLE_R(max(z, 1.0)) + 0.004, turns=4.5, seg=32, step=0.02)
for z in (2.6, 4.1):
    ring("Gold", (0, 0, z), (0, 0, 1), POLE_R(z) + 0.006, 0.014, seg=16, tseg=6)
for z in (1.9, 2.9, 3.8, 4.6, 5.2):   # line guides on top (+Y)
    r = POLE_R(z)
    cyl("Gold", 0.01, 0.01, 0.07, (0, r + 0.03, z), rot=(90, 0, 0), seg=6)
    tube("Gold", [(0.03 * math.cos(2 * math.pi * k / 12), r + 0.08, z + 0.03 * math.sin(2 * math.pi * k / 12)) for k in range(12)],
         0.008, seg=5, closed=True, caps=False)

# reel (underside -Y): gold drum, red faces with glowing snowflakes, gold rims, crank + red knob
REEL = Vector((0, -0.22, 0.82))
cyl("Gold", 0.035, 0.035, 0.16, (0, -0.1, 0.82), rot=(90, 0, 0), seg=8)
cyl("Gold", 0.18, 0.18, 0.17, REEL, rot=(0, 90, 0), seg=24)
for s in (1, -1):
    cyl("Red", 0.152, 0.152, 0.02, REEL + Vector((s * 0.09, 0, 0)), rot=(0, 90, 0), seg=24)
    ring("Gold", REEL + Vector((s * 0.096, 0, 0)), (s, 0, 0), 0.163, 0.014, seg=28, tseg=6)
    snowflake(REEL + Vector((s * 0.102, 0, 0)), (s, 0, 0), 0.11, 0.012)
tube("Gold", [REEL + Vector((0.1, 0, 0)), REEL + Vector((0.15, -0.08, 0.06)), REEL + Vector((0.16, -0.16, 0.1))], 0.016, seg=6)
cyl("Red", 0.035, 0.03, 0.09, REEL + Vector((0.2, -0.19, 0.12)), rot=(0, 90, 0), seg=10)

# big red bow with a gold star, sitting on the reel side just above the reel
BOW = Vector((0, -0.13, 1.1))
for s in (1, -1):
    c = BOW + Vector((s * 0.13, 0, 0.025))
    sph("Red", (0.13, 0.055, 0.085), c, rot=(0, -s * 14, 0), seg=16, rings=10)
    Rt = Euler((0, math.radians(-s * 14), 0)).to_matrix()
    tube("Gold", [c + Rt @ Vector((0.133 * math.cos(2 * math.pi * k / 26), -0.005, 0.088 * math.sin(2 * math.pi * k / 26))) for k in range(26)],
         0.011, seg=5, closed=True, caps=False, normal=(0, 1, 0))
    tail = [BOW + Vector((s * 0.02, -0.01, -0.03)), BOW + Vector((s * 0.06, -0.02, -0.13)), BOW + Vector((s * 0.1, -0.03, -0.24)), BOW + Vector((s * 0.13, -0.03, -0.31))]
    tube("Red", tail, [0.04, 0.045, 0.05, 0.055], seg=8, flat=0.25, normal=(0, -1, 0))
sph("Red", (0.055, 0.05, 0.055), BOW + Vector((0, -0.02, 0)), seg=12, rings=8)
star("Gold", BOW + Vector((0, -0.075, 0)), (0, -1, 0), (0, 0, 1), 0.075, 0.032, 0.022)

# reindeer cub hugging the pole (+X side), Santa hat + red scarf, eyes closed in a smile
MODEL = "Deer"   # built at normal size, then scaled x DEER_SCALE around DEER_PIVOT and merged into the rod
DEER_SCALE, DEER_PIVOT = 1.3, Vector((0.0, 0.0, 1.62))
sph("Fur", (0.13, 0.12, 0.16), (0.19, 0, 1.58), seg=16, rings=10)        # body
sph("Snow", (0.06, 0.085, 0.1), (0.29, 0, 1.56), seg=12, rings=8)         # belly
sph("Fur", 0.145, (0.22, 0, 1.86), seg=18, rings=12)                       # head
sph("Snow", (0.075, 0.085, 0.058), (0.335, 0, 1.815), seg=12, rings=8)     # muzzle
sph("Nose", 0.032, (0.405, 0, 1.835), seg=10, rings=7)
for s in (1, -1):
    arc = [(0.348, s * 0.062 + 0.026 * math.cos(math.pi * i / 6), 1.892 + 0.014 * math.sin(math.pi * i / 6)) for i in range(7)]
    tube("Eye", arc, 0.007, seg=4)                                          # ^ ^ closed eyes
    sph("FurPink", (0.012, 0.03, 0.02), (0.33, s * 0.1, 1.83), seg=8, rings=5)   # cheeks
    sph("Fur", (0.035, 0.085, 0.04), (0.2, s * 0.155, 1.93), rot=(s * 20, 0, 0), seg=10, rings=6)          # ears
    sph("FurPink", (0.012, 0.06, 0.025), (0.225, s * 0.16, 1.93), rot=(s * 20, 0, 0), seg=8, rings=5)
    # antlers poking out of the hat
    tube("Antler", [(0.17, s * 0.075, 1.98), (0.16, s * 0.11, 2.06), (0.15, s * 0.14, 2.14)], [0.018, 0.016, 0.013], seg=6)
    tube("Antler", [(0.16, s * 0.11, 2.06), (0.21, s * 0.13, 2.1)], 0.012, seg=5)
    tube("Antler", [(0.152, s * 0.13, 2.11), (0.12, s * 0.17, 2.13)], 0.011, seg=5)
    # arms hug around the pole, hooves meet behind it
    arm = [(0.21, s * 0.11, 1.69), (0.12, s * 0.12, 1.68), (0.03, s * 0.1, 1.67), (-0.04, s * 0.075, 1.665), (-0.075, s * 0.03, 1.665)]
    tube("Fur", arm, [0.042, 0.04, 0.037, 0.035, 0.033], seg=8)
    sph("Antler", 0.034, arm[-1], seg=8, rings=6)
    leg = [(0.17, s * 0.08, 1.47), (0.08, s * 0.105, 1.43), (-0.02, s * 0.09, 1.41), (-0.075, s * 0.035, 1.41)]
    tube("Fur", leg, [0.048, 0.045, 0.042, 0.04], seg=8)
    sph("Antler", 0.038, leg[-1], seg=8, rings=6)
# Santa hat (tip flops to the -Y side), snow brim + pom
HU = Vector((0, -math.sin(math.radians(28)), math.cos(math.radians(28))))
HB = Vector((0.21, 0.01, 1.975))
cyl("Red", 0.112, 0.006, 0.22, HB + HU * 0.11, rot=(28, 0, 0), seg=18)
ring("Snow", HB, HU, 0.112, 0.03, seg=22, tseg=8)
sph("Snow", 0.04, HB + HU * 0.225, seg=10, rings=7)
# scarf round the neck + a tail
ring("Scarf", Vector((0.215, 0, 1.745)), (0, 0, 1), 0.105, 0.032, seg=22, tseg=8)
tube("Scarf", [(0.3, 0.06, 1.74), (0.33, 0.08, 1.66), (0.345, 0.1, 1.58)], [0.04, 0.042, 0.045], seg=8, flat=0.3, normal=(1, 0, 0))
MODEL = "XmasRod2"
for (mdl, mat) in [k for k in BM if k[0] == "Deer"]:
    dbm = BM.pop((mdl, mat))
    for v in dbm.verts:
        v.co = DEER_PIVOT + (v.co - DEER_PIVOT) * DEER_SCALE
    tmp = bpy.data.meshes.new("_deer_" + mat)
    dbm.to_mesh(tmp)
    dbm.free()
    target(mat).from_mesh(tmp)
    bpy.data.meshes.remove(tmp)

# fairy-light string (warm bulbs) from above the reindeer to the tip
wire = []
N = 120
for i in range(N):
    u = i / (N - 1)
    z = 2.25 + 3.05 * u
    a = 1.2 + 2 * math.pi * 3.5 * u
    r = POLE_R(z) + 0.012
    wire.append((r * math.cos(a), r * math.sin(a), z))
tube("Wire", wire, 0.008, seg=5)
for i in range(3, N - 2, 6):
    x, y, z = wire[i]
    out = Vector((x, y, 0)).normalized()
    if out.y > 0.75:      # no bulb right under a line guide
        continue
    size = 0.045 - 0.012 * (z - 2.25) / 3.05
    cyl("Gold", size * 0.5, size * 0.5, size * 0.6, Vector((x, y, z)) + out * size * 0.4, rot=(0, 0, 0), seg=8)
    sph("BulbWarm", size, Vector((x, y, z)) + out * size * 1.2 + Vector((0, 0, -size * 0.3)), seg=10, rings=8)
# holly sprigs
holly(Vector((-POLE_R(2.45) - 0.01, 0, 2.45)), (-1, -0.3, 0.2), 0.085)
holly(Vector((POLE_R(4.25) + 0.01, 0, 4.25)), (1, -0.3, 0.2), 0.075)

# tip: gold collar + pin + big gold star (line comes out of its top point)
TIP = Vector((0, 0, 5.5))
cyl("Gold", POLE_R(5.45) + 0.012, POLE_R(5.45) + 0.004, 0.06, TIP, seg=10)
cyl("Gold", 0.02, 0.02, 0.2, TIP + Vector((0, 0, 0.12)), seg=8)
star("Star", TIP + Vector((0, 0, 0.36)), (1, 0, 0), (0, 0, 1), 0.3, 0.13, 0.08)

# =================================================================== 2) XmasBobber2 (snowman, Santa hat, red/green scarf)
MODEL = "XmasBobber2"
sph("Snow", 0.17, (0, 0, 0.08), seg=20, rings=14)
sph("Snow", 0.118, (0, 0, 0.33), seg=18, rings=12)
for s in (1, -1):
    sph("Coal", (0.018, 0.012, 0.024), (s * 0.042, -0.106, 0.36), seg=8, rings=6)
    sph("FurPink", (0.024, 0.01, 0.016), (s * 0.072, -0.092, 0.315), seg=8, rings=5)
for k in range(5):   # coal smile
    a = math.radians(-50 + 25 * k)
    sph("Coal", 0.009, (0.045 * math.sin(a), -0.113, 0.3 - 0.016 * math.cos(a)), seg=6, rings=4)
cyl("Carrot", 0.024, 0.003, 0.09, (0, -0.155, 0.335), rot=(90, 0, 0), seg=10)
for z in (0.16, 0.08):   # buttons
    sph("Coal", 0.017, (0, -math.sqrt(0.17 ** 2 - (z - 0.08) ** 2) - 0.004, z), seg=8, rings=5)
# scarf: alternating red / green blocks round the neck + a striped tail
NS = 14
for k in range(NS):
    a0, a1 = 2 * math.pi * k / NS, 2 * math.pi * (k + 1) / NS
    pts = [(0.118 * math.cos(a0 + (a1 - a0) * t / 3), 0.118 * math.sin(a0 + (a1 - a0) * t / 3), 0.225) for t in range(4)]
    tube("Scarf" if k % 2 == 0 else "ScarfGreen", pts, 0.032, seg=8)
tail = [(0.07, -0.1, 0.225), (0.1, -0.12, 0.17), (0.12, -0.135, 0.11), (0.13, -0.14, 0.06)]
for k in range(3):
    seg_pts = [Vector(tail[k]), Vector(tail[k + 1])]
    tube("Scarf" if k % 2 == 0 else "ScarfGreen", seg_pts, 0.04, seg=8, flat=0.3, normal=(0, -1, 0))
# Santa hat, tip flops back (+Y)
BU = Vector((0, math.sin(math.radians(22)), math.cos(math.radians(22))))
BB = Vector((0, 0.0, 0.43))
cyl("Red", 0.104, 0.006, 0.2, BB + BU * 0.1, rot=(-22, 0, 0), seg=18)
ring("Snow", BB, BU, 0.104, 0.028, seg=22, tseg=8)
sph("Snow", 0.036, BB + BU * 0.205, seg=10, rings=7)

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

scn = bpy.context.scene
scn.render.engine = 'BLENDER_WORKBENCH'
scn.display.shading.light = 'STUDIO'
scn.display.shading.color_type = 'MATERIAL'
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
scn.collection.objects.link(cam)
scn.camera = cam

VIEWS = {"XmasRod2": [("side", Vector((1.0, -0.6, 0.15))), ("back", Vector((-1.0, -0.4, 0.15)))],
         "XmasBobber2": [("front", Vector((0.35, -1.0, 0.3)))]}
for model, objs in by_model.items():
    tri = 0
    for ob in objs:
        ob.data.calc_loop_triangles()
        tri += len(ob.data.loop_triangles)
        print("  OBJ", ob.name, len(ob.data.loop_triangles))
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
    for vname, vdir in VIEWS[model]:
        scn.render.resolution_x, scn.render.resolution_y = (700, 1000) if model == "XmasRod2" else (800, 800)
        cam.data.lens = 40
        cam.location = mid + vdir.normalized() * size * 1.25
        cam.rotation_euler = (mid - cam.location).to_track_quat('-Z', 'Y').to_euler()
        scn.render.filepath = os.path.join(OUT, "preview_%s_%s.png" % (model, vname))
        bpy.ops.render.render(write_still=True)

for o in bpy.data.objects:
    o.hide_render = not (o.name.startswith("XmasRod2__") or o is cam)
for vname, vdir, focus, dist in (("reindeer", Vector((1.0, -0.45, 0.15)), Vector((0.15, 0, 1.72)), 1.3),
                                 ("reel", Vector((0.55, -1.0, 0.2)), Vector((0, -0.15, 0.95)), 1.3),
                                 ("butt", Vector((1.0, -0.5, 0.2)), Vector((0, 0, -0.2)), 1.3),
                                 ("tip", Vector((0.8, -0.6, 0.2)), Vector((0, 0, 4.9)), 2.0)):
    scn.render.resolution_x, scn.render.resolution_y = 800, 800
    cam.data.lens = 50
    cam.location = focus + vdir.normalized() * dist
    cam.rotation_euler = (focus - cam.location).to_track_quat('-Z', 'Y').to_euler()
    scn.render.filepath = os.path.join(OUT, "preview_XmasRod2_%s.png" % vname)
    bpy.ops.render.render(write_still=True)
