# Christmas rod v3 (เบ็ดคริสต์มาส, RodId XmasTree) — closer to the user's concept picture (2026-11-27 round 3, plan in CHRISTMAS_TREE_ROD.md).
#   v2 = build_xmas_rod_v2.py (kept). Lower part ~1.5x bigger, real ribbon bow, bolted gold reel, trumpet gold end,
#   chibi reindeer, fat candy-cane pole bending a little at the top, big warm bulbs, big holly sprigs.
# Run:  blender.exe -b --factory-startup -P build_xmas_rod_v3.py -- <outdir> [stage]
#   stage = "lower" (grip/bow/reel only, for review) or "all" (default).
# Units: 1 Blender unit = 1 stud. Rod built along +Z, hand (Roblox Handle) at the origin, reel underside (-Y),
#   line guides on top (+Y). Objects are named "<Model>__<Material>"; Studio colours them from COLORS.
#   Neon in Studio: BulbWarm, Flake, Star.
import bpy, bmesh, math, sys, os
from mathutils import Vector, Matrix, Euler

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = ARGS[0] if ARGS else os.path.dirname(os.path.abspath(__file__))
STAGE = ARGS[1] if len(ARGS) > 1 else "all"
os.makedirs(OUT, exist_ok=True)
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o, do_unlink=True)

def lin(c):
    c = c / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

COLORS = {
    "Red": (214, 30, 42), "RedDeep": (150, 16, 28), "Snow": (248, 250, 255), "Gold": (240, 186, 60), "Star": (255, 214, 80),
    "Wire": (40, 90, 45), "BulbWarm": (255, 222, 130), "Holly": (28, 110, 45), "HollyLight": (70, 150, 70), "Berry": (220, 25, 35),
    "Flake": (255, 226, 140), "ReelFace": (120, 12, 22), "Green": (26, 80, 44),
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


def ribbon(mat, pts, width, thick, side_axis, notch=0.0, trim=None, trim_r=0.009, side_fn=None):
    """Flat ribbon swept along pts: broad face spans `width` along side_axis (made perpendicular to the path),
    3 columns across so the end can be V-notched (notch = how far the middle pulls back). trim = gold edge tubes."""
    bm = target(mat)
    pts = [Vector(p) for p in pts]
    n = len(pts)
    S = Vector(side_axis).normalized()
    rings, edges = [], ([], [])
    for i, p in enumerate(pts):
        t = (pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]).normalized()
        side = side_fn(t) if side_fn else (S - t * S.dot(t))
        side = (side - t * side.dot(t))
        side = side.normalized() if side.length > 1e-5 else t.orthogonal().normalized()
        nrm = t.cross(side).normalized()
        cols = []
        for j, u in enumerate((-0.5, 0.0, 0.5)):
            q = p + side * (u * width)
            if i == n - 1 and j == 1:
                q = q - t * notch
            cols.append((bm.verts.new(q + nrm * thick / 2), bm.verts.new(q - nrm * thick / 2)))
        rings.append(cols)
        edges[0].append(p - side * (width / 2))
        edges[1].append(p + side * (width / 2))
    faces = []
    for i in range(n - 1):
        a, b = rings[i], rings[i + 1]
        for j in range(2):
            faces.append(bm.faces.new((a[j][0], a[j + 1][0], b[j + 1][0], b[j][0])))   # top
            faces.append(bm.faces.new((a[j][1], b[j][1], b[j + 1][1], a[j + 1][1])))   # bottom
        faces.append(bm.faces.new((a[0][0], b[0][0], b[0][1], a[0][1])))               # side edges
        faces.append(bm.faces.new((a[2][0], a[2][1], b[2][1], b[2][0])))
    for r in (rings[0], rings[-1]):
        for j in range(2):
            faces.append(bm.faces.new((r[j][0], r[j][1], r[j + 1][1], r[j + 1][0])))
    for f in faces:
        f.smooth = True
    bmesh.ops.recalc_face_normals(bm, faces=faces)
    if trim:
        last = n - 1
        for e in edges:
            tube(trim, e, trim_r, seg=5)
        if notch > 0:   # trim along the V cut too
            c = rings[last][1]
            mid = (c[0].co + c[1].co) / 2
            tube(trim, [edges[0][-1], mid, edges[1][-1]], trim_r, seg=5)

def loop_path(origin, s, L, H, tilt, dip, n=28):
    """Bow loop: teardrop from the knot out to the side (s = +1/-1) and back, fatter at the far end."""
    pts = []
    R = Euler((0, math.radians(-s * tilt), 0)).to_matrix()
    for i in range(n + 1):
        a = 2 * math.pi * i / n
        u = (1 - math.cos(a)) / 2                     # 0 at the knot, 1 at the far end
        x = s * L * u
        z = H * 0.5 * math.sin(a) * (0.45 + 0.75 * u)
        y = -dip * u * u
        pts.append(Vector(origin) + R @ Vector((x, y, z)))
    return pts

def leaf(center, direction, normal, length, width, mat="Holly", rib="HollyLight", thick=0.012, spikes=4):
    """Holly leaf: flat spiky outline, a little curved, with a lighter midrib."""
    bm = target(mat)
    d = Vector(direction).normalized()
    nz = Vector(normal).normalized()
    sd = nz.cross(d).normalized()
    nz = d.cross(sd).normalized()
    c = Vector(center)
    outline = []
    N = spikes * 2 + 1
    for side in (1, -1):
        rng = range(N + 1) if side == 1 else range(N, -1, -1)
        for k in rng:
            t = k / N
            w = width * 0.5 * math.sin(math.pi * t) ** 0.7
            if 0 < k < N and k % 2 == 1:
                w *= 1.28                                   # spike
                t += 0.02
            bend = 0.12 * length * (t - 0.5) ** 2           # leaf curls up at both ends
            outline.append(c + d * (t * length) + sd * (side * w) + nz * bend)
    top = [bm.verts.new(p + nz * thick / 2) for p in outline]
    bot = [bm.verts.new(p - nz * thick / 2) for p in outline]
    faces = [bm.faces.new(top), bm.faces.new(list(reversed(bot)))]
    m = len(outline)
    for i in range(m):
        faces.append(bm.faces.new((top[i], bot[i], bot[(i + 1) % m], top[(i + 1) % m])))
    bmesh.ops.recalc_face_normals(bm, faces=faces)
    tube(rib, [c + nz * (thick * 0.6 + 0.12 * length * (t - 0.5) ** 2) + d * (t * length) for t in (0.05, 0.5, 0.92)], thick * 0.55, seg=4)

def sprig(center, out, size, n_leaves=3, spin=0.0):
    """Holly sprig: 3-4 spiky leaves fanned out + 3 shiny berries."""
    F = basis(center, out)
    for k in range(n_leaves):
        a = spin + 2 * math.pi * k / n_leaves + 0.3
        d = F.to_3x3() @ Vector((math.cos(a), math.sin(a), 0.35))
        leaf(Vector(center) + d.normalized() * size * 0.08, d, F.to_3x3() @ Vector((0, 0, 1)), size, size * 0.46)
    for k in range(3):
        a = spin + 2 * math.pi * k / 3 + 1.0
        sph("Berry", size * 0.13, F @ Vector((size * 0.11 * math.cos(a), size * 0.11 * math.sin(a), size * 0.12)), seg=10, rings=8)

def snowflake2(center, normal, R, w):
    """Detailed six-arm snowflake (Flake = Neon): arms with 3 branch pairs + a hexagon ring."""
    F = basis(center, normal)
    sph_m("Flake", F @ Matrix.Diagonal((w * 3, w * 3, w * 0.9, 1.0)), seg=12, rings=6)
    tube("Flake", [F @ Vector((R * 0.34 * math.cos(math.pi / 3 * k + math.pi / 6), R * 0.34 * math.sin(math.pi / 3 * k + math.pi / 6), 0)) for k in range(6)],
         w * 0.7, seg=4, closed=True, caps=False, normal=normal)
    for k in range(6):
        a = math.pi / 3 * k
        dv = Vector((math.cos(a), math.sin(a), 0))
        tube("Flake", [F @ (dv * R * 0.12), F @ (dv * R)], w, seg=5)
        sph_m("Flake", F @ Matrix.Translation(dv * R) @ Matrix.Diagonal((w * 1.6, w * 1.6, w, 1.0)), seg=8, rings=5)
        for t, L in ((0.45, 0.3), (0.65, 0.26), (0.84, 0.17)):
            for s in (1, -1):
                b = Vector((math.cos(a + s * 0.85), math.sin(a + s * 0.85), 0))
                tube("Flake", [F @ (dv * R * t), F @ (dv * R * t + b * R * L)], w * 0.75, seg=4)

# =================================================================== 1) XmasRod3 — lower part (grip, bow, reel)
MODEL = "XmasRod3"

# trumpet gold end: flared bell with a rolled lip (shell revolved around Z)
lathe("Gold", [(0.150, -0.50), (0.155, -0.58), (0.170, -0.66), (0.200, -0.73), (0.245, -0.79), (0.268, -0.815),
               (0.272, -0.835), (0.262, -0.85), (0.240, -0.845), (0.205, -0.82), (0.17, -0.79), (0.14, -0.76), (0.12, -0.70), (0.12, -0.52)],
      seg=36)
ring("Gold", (0, 0, -0.505), (0, 0, 1), 0.155, 0.018, seg=32, tseg=8)
ring("Gold", (0, 0, -0.62), (0, 0, 1), 0.162, 0.012, seg=32, tseg=6)

# red cuff above the bell (slightly wider at the bottom, like a stocking top) with big gold stars
lathe("Red", [(0.0, -0.5), (0.158, -0.5), (0.152, -0.36), (0.146, -0.2), (0.0, -0.2)], seg=32)
for ang in (-90, 30, 150):      # front (-Y) + two sides
    a = math.radians(ang)
    o = Vector((math.cos(a), math.sin(a), 0))
    star("Gold", Vector((0, 0, -0.34)) + o * 0.152, o, (0, 0, 1), 0.085, 0.036, 0.03)
# fluffy snow trim on top of the cuff: two staggered rows of puffs
ring("Snow", (0, 0, -0.18), (0, 0, 1), 0.15, 0.045, seg=32, tseg=8)
for row, (z, R, k0) in enumerate(((-0.2, 0.158, 0.0), (-0.155, 0.148, 0.5))):
    for k in range(16):
        a = 2 * math.pi * (k + k0) / 16
        sph("Snow", (0.05, 0.05, 0.042), (R * math.cos(a), R * math.sin(a), z), seg=10, rings=7)

# hand grip: red with thin gold bands
cyl("Red", 0.122, 0.118, 0.62, (0, 0, 0.13), seg=24)
for z in (-0.06, 0.16, 0.38):
    ring("Gold", (0, 0, z), (0, 0, 1), 0.121, 0.011, seg=28, tseg=6)
# gold collar, dark green band, gold collar (top of the handle)
cyl("Gold", 0.132, 0.132, 0.06, (0, 0, 0.47), seg=28)
ring("Gold", (0, 0, 0.44), (0, 0, 1), 0.132, 0.012, seg=28, tseg=6)
cyl("Green", 0.124, 0.118, 0.08, (0, 0, 0.54), seg=28)
cyl("Gold", 0.124, 0.105, 0.06, (0, 0, 0.61), seg=28)
ring("Gold", (0, 0, 0.64), (0, 0, 1), 0.108, 0.012, seg=28, tseg=6)

# reel (underside -Y): gold bracket, thick bolted gold rim, dark-red faces with big glowing snowflakes, red/white crank knob
REEL = Vector((0, -0.36, 0.6))
RR = 0.25
tube("Gold", [Vector((0, -0.08, 0.6)), Vector((0, -0.14, 0.6)), REEL + Vector((0, 0.17, 0.0))], 0.03, seg=8)           # bracket
cyl("Gold", 0.05, 0.05, 0.06, Vector((0, -0.1, 0.6)), rot=(90, 0, 0), seg=10)
cyl("Gold", RR - 0.02, RR - 0.02, 0.2, REEL, rot=(0, 90, 0), seg=40)                                                    # drum
for s in (1, -1):
    ring("Gold", REEL + Vector((s * 0.105, 0, 0)), (s, 0, 0), RR, 0.042, seg=44, tseg=10)                                # thick rim
    cyl("ReelFace", RR - 0.03, RR - 0.03, 0.02, REEL + Vector((s * 0.105, 0, 0)), rot=(0, 90, 0), seg=40)
    ring("Gold", REEL + Vector((s * 0.118, 0, 0)), (s, 0, 0), RR * 0.36, 0.01, seg=24, tseg=5)
    snowflake2(REEL + Vector((s * 0.12, 0, 0)), (s, 0, 0), RR * 0.78, 0.014)
    for k in range(8):                                                                                                   # bolts
        a = 2 * math.pi * (k + 0.5) / 8
        sph("Gold", (0.016, 0.022, 0.022), REEL + Vector((s * 0.145, RR * math.cos(a), RR * math.sin(a))), seg=8, rings=6)
# crank on the +X side: gold arm + red/white knob
CA = REEL + Vector((0.16, 0, 0))
cyl("Gold", 0.04, 0.04, 0.04, CA, rot=(0, 90, 0), seg=12)
tube("Gold", [CA, CA + Vector((0.02, -0.12, 0.1)), CA + Vector((0.03, -0.2, 0.16))], [0.022, 0.02, 0.02], seg=8)
K = CA + Vector((0.09, -0.2, 0.16))
cyl("Snow", 0.036, 0.036, 0.1, K, rot=(0, 90, 0), seg=14)
cyl("Red", 0.045, 0.045, 0.04, K + Vector((0.07, 0, 0)), rot=(0, 90, 0), seg=14)
sph("Red", (0.02, 0.045, 0.045), K + Vector((0.09, 0, 0)), seg=12, rings=6)

# big red ribbon bow on the front (-Y) above the reel: two folded loops + two long V-cut tails, gold edges, gold star knot
BOW = Vector((0, -0.26, 1.06))
LOOP_N = Vector((0, -1, 0.35)).normalized()   # loops face the front (-Y), leaning up a little
for s in (1, -1):
    path = loop_path(BOW + Vector((s * 0.03, 0, 0.01)), s, 0.30, 0.24, tilt=14, dip=0.06)
    ribbon("Red", path, 0.115, 0.018, side_axis=(0, 0, 1), trim="Gold",
           side_fn=lambda t: t.cross(LOOP_N) * 0.9 + LOOP_N * 0.35)   # broad face toward the viewer, slight twist
    tail = [BOW + Vector((s * 0.03, -0.02, -0.04)), BOW + Vector((s * 0.09, -0.05, -0.12)), BOW + Vector((s * 0.17, -0.08, -0.22)),
            BOW + Vector((s * 0.24, -0.09, -0.33)), BOW + Vector((s * 0.28, -0.08, -0.43))]
    ribbon("Red", tail, 0.095, 0.014, side_axis=(1, -0.25 * s, 0), notch=0.05, trim="Gold")
sph("Red", (0.065, 0.055, 0.07), BOW + Vector((0, -0.02, 0)), seg=14, rings=10)                                         # knot
ribbon("RedDeep", [BOW + Vector((0, -0.075, 0.065)), BOW + Vector((0, -0.08, 0)), BOW + Vector((0, -0.075, -0.065))], 0.07, 0.01, side_axis=(1, 0, 0))
star("Gold", BOW + Vector((0, -0.12, 0.005)), (0, -1, 0), (0, 0, 1), 0.135, 0.058, 0.04)
# holly sprig tucked behind the bow (+X side)
sprig(BOW + Vector((0.22, 0.1, 0.2)), (0.5, -0.6, 0.7), 0.17, n_leaves=3, spin=0.4)


# =================================================================== reindeer cub (chibi) hugging the pole above the bow
# Built facing +X with the pole axis at x = y = 0, then turned by DEER_YAW (to face between the front -Y and the +X side) and merged.
DEER_YAW = -50
MODEL = "Deer"
sph("Fur", (0.12, 0.125, 0.15), (0.17, 0, 1.5), seg=18, rings=12)                     # body
sph("Snow", (0.05, 0.085, 0.095), (0.265, 0, 1.47), seg=14, rings=10)                  # belly
sph("Fur", (0.17, 0.175, 0.16), (0.2, 0, 1.78), seg=22, rings=16)                      # big head
sph("Snow", (0.07, 0.095, 0.062), (0.345, 0, 1.725), seg=16, rings=10)                 # muzzle
sph("Nose", 0.03, (0.412, 0, 1.748), seg=12, rings=8)
tube("Eye", [(0.405, -0.022, 1.697), (0.41, 0, 1.69), (0.405, 0.022, 1.697)], 0.006, seg=4)   # little smile
for s in (1, -1):
    arc = [(0.352, s * 0.078 + 0.03 * math.cos(math.pi * i / 6), 1.815 + 0.016 * math.sin(math.pi * i / 6)) for i in range(7)]
    tube("Eye", arc, 0.0085, seg=5)                                                    # ^ ^ happy closed eyes
    sph("FurPink", (0.014, 0.038, 0.024), (0.33, s * 0.12, 1.745), seg=10, rings=6)   # cheeks
    # big ears pointing out to the sides, pink inside
    sph("Fur", (0.045, 0.12, 0.052), (0.19, s * 0.2, 1.84), rot=(s * -22, 0, 0), seg=12, rings=8)
    sph("FurPink", (0.018, 0.085, 0.03), (0.218, s * 0.205, 1.84), rot=(s * -22, 0, 0), seg=10, rings=6)
    # antlers: brown, branching out from under the hat
    tube("Antler", [(0.16, s * 0.11, 1.93), (0.13, s * 0.19, 2.05), (0.11, s * 0.23, 2.16)], [0.022, 0.019, 0.015], seg=7)
    tube("Antler", [(0.135, s * 0.17, 2.02), (0.2, s * 0.22, 2.09)], [0.016, 0.013], seg=6)
    tube("Antler", [(0.115, s * 0.215, 2.11), (0.06, s * 0.29, 2.15)], [0.014, 0.012], seg=6)
    for tip in ((0.11, s * 0.23, 2.16), (0.2, s * 0.22, 2.09), (0.06, s * 0.29, 2.15)):
        sph("Antler", 0.014, tip, seg=6, rings=4)
    # arms hug the pole (paws meet behind it), legs grip lower down
    arm = [(0.23, s * 0.13, 1.6), (0.14, s * 0.15, 1.62), (0.03, s * 0.125, 1.63), (-0.06, s * 0.085, 1.63), (-0.1, s * 0.03, 1.63)]
    tube("Fur", arm, [0.048, 0.046, 0.043, 0.04, 0.038], seg=10)
    sph("Fur", 0.042, arm[0], seg=10, rings=7)
    sph("Antler", 0.035, arm[-1], seg=8, rings=6)
    leg = [(0.16, s * 0.095, 1.38), (0.07, s * 0.125, 1.35), (-0.04, s * 0.115, 1.34), (-0.1, s * 0.045, 1.34)]
    tube("Fur", leg, [0.055, 0.052, 0.048, 0.045], seg=10)
    sph("Antler", 0.04, leg[-1], seg=8, rings=6)
# soft Santa hat: thick base that flops over to the +Y side, fluffy brim, pom
HB = Vector((0.19, 0, 1.915))
hat = [HB, HB + Vector((-0.01, 0.0, 0.1)), HB + Vector((-0.02, 0.05, 0.175)), HB + Vector((-0.02, 0.13, 0.2)), HB + Vector((-0.01, 0.205, 0.15))]
tube("Red", hat, [0.135, 0.105, 0.072, 0.048, 0.03], seg=16)
ring("Snow", HB + Vector((0, 0, 0.01)), (-0.12, 0, 1), 0.14, 0.042, seg=28, tseg=10)
for k in range(12):
    a = 2 * math.pi * k / 12
    F = basis(HB + Vector((0, 0, 0.01)), (-0.12, 0, 1))
    sph("Snow", 0.035, F @ Vector((0.142 * math.cos(a), 0.142 * math.sin(a), 0)), seg=8, rings=6)
sph("Snow", 0.048, hat[-1] + Vector((0.0, 0.02, -0.03)), seg=12, rings=8)
# knitted red scarf + two hanging ends
ring("Scarf", (0.19, 0, 1.635), (0, 0, 1), 0.125, 0.04, seg=28, tseg=10)
for off, ln in ((0.0, 0.17), (0.045, 0.13)):
    ribbon("Scarf", [(0.29, 0.07 + off, 1.62), (0.315, 0.09 + off, 1.54), (0.33, 0.1 + off, 1.62 - ln)], 0.06, 0.02, side_axis=(0, 1, 0))
    tube("RedDeep", [(0.335, 0.075 + off, 1.62 - ln + 0.02), (0.335, 0.125 + off, 1.62 - ln + 0.02)], 0.007, seg=4)

MODEL = "XmasRod3"
DR = Matrix.Rotation(math.radians(DEER_YAW), 4, 'Z')
for (mdl, mat) in [k for k in BM if k[0] == "Deer"]:
    dbm = BM.pop((mdl, mat))
    for v in dbm.verts:
        v.co = DR @ v.co
    tmp = bpy.data.meshes.new("_deer_" + mat)
    dbm.to_mesh(tmp)
    dbm.free()
    target(mat).from_mesh(tmp)
    bpy.data.meshes.remove(tmp)


# =================================================================== pole (fat candy cane, bends a little toward -Y near the top), lights, holly, guides, star
# Everything above the handle is written in "straight" coordinates (x, y, z) and mapped onto the bent centreline by bendp().
Z0, ZB, ZE = 0.64, 3.3, 4.95          # pole start, bend start, pole end (straight-z); shorter than v2 to match the picture
RB = 2.7                              # bend radius: 1.65 studs of arc = ~35 degrees
POLE_R3 = lambda z: 0.105 + (0.05 - 0.105) * (min(max(z, Z0), ZE) - Z0) / (ZE - Z0)

def pole_frame(z):
    if z <= ZB:
        return Vector((0, 0, z)), Vector((0, 0, 1)), Vector((1, 0, 0)), Vector((0, 1, 0))
    th = (z - ZB) / RB
    pos = Vector((0, -RB * (1 - math.cos(th)), ZB + RB * math.sin(th)))
    T = Vector((0, -math.sin(th), math.cos(th)))
    X = Vector((1, 0, 0))
    return pos, T, X, T.cross(X)

def bendp(p):
    pos, T, X, Y = pole_frame(p[2])
    return pos + X * p[0] + Y * p[1]

def bendv(v, z):
    pos, T, X, Y = pole_frame(z)
    return X * v[0] + Y * v[1] + T * v[2]

def candy_bent(z0, z1, rfun, turns, stripes=2, seg=32, step=0.02, frac=0.45):
    nz = max(2, int((z1 - z0) / step) + 1)
    zs = [z0 + (z1 - z0) * i / (nz - 1) for i in range(nz)]
    grids = {}
    for mat in ("Red", "Snow"):
        bm = target(mat)
        grids[mat] = (bm, [[bm.verts.new(bendp((rfun(z) * math.cos(2 * math.pi * k / seg), rfun(z) * math.sin(2 * math.pi * k / seg), z)))
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

if STAGE == "all":
    candy_bent(Z0, ZE, POLE_R3, turns=3.0, seg=32, step=0.02)
    # end cap of the pole under the tip collar
    pos, T, X, Y = pole_frame(ZE)
    sph_m("Snow", basis(pos, T) @ Matrix.Diagonal((POLE_R3(ZE), POLE_R3(ZE), 0.02, 1.0)), seg=16, rings=6)

    # line guides on top (+Y side of the pole)
    for z in (1.95, 2.75, 3.45, 4.1, 4.65):
        r = POLE_R3(z)
        pos, T, X, Y = pole_frame(z)
        tube("Gold", [pos + Y * r * 0.8, pos + Y * (r + 0.06)], 0.011, seg=6)
        tube("Gold", [pos + Y * (r + 0.1) + (X * math.cos(2 * math.pi * k / 14) + T * math.sin(2 * math.pi * k / 14)) * 0.035 for k in range(14)],
             0.009, seg=5, closed=True, caps=False)

    # loose green light-string with big warm bulbs (denser toward the top)
    N = 160
    wire = []
    for i in range(N):
        u = i / (N - 1)
        z = 2.25 + (ZE - 0.08 - 2.25) * u
        a = 0.6 + 2 * math.pi * 3.2 * u
        r = POLE_R3(z) + 0.035 + 0.02 * math.sin(u * math.pi * 9)
        wire.append((r * math.cos(a), r * math.sin(a), z))
    tube("Wire", [bendp(p) for p in wire], 0.011, seg=6)
    k, last, acc = 3, None, 0.0
    while k < N - 2:
        x, y, z = wire[k]
        if last is not None:
            acc += (Vector(wire[k]) - Vector(wire[k - 1])).length
        gap = 0.3 if z < 3.3 else 0.22            # spacing along the wire (denser toward the top)
        if last is not None and acc < gap:
            k += 1
            continue
        out = Vector((x, y, 0)).normalized()
        if out.y < 0.7:                                   # not right under a line guide
            size = 0.062 - 0.016 * (z - 2.25) / (ZE - 2.25)
            sock = (x + out.x * size * 0.35, y + out.y * size * 0.35, z - size * 0.2)
            bulb_c = (x + out.x * size * 1.0, y + out.y * size * 1.0, z - size * 0.75)
            cyl_dir = bendv(Vector((out.x, out.y, -0.6)).normalized(), z)
            cm = basis(bendp(sock), cyl_dir)
            bmesh.ops.create_cone(target("Gold"), cap_ends=True, cap_tris=False, segments=10, radius1=size * 0.45, radius2=size * 0.4,
                                  depth=size * 0.55, matrix=cm)
            sph("BulbWarm", size, bendp(bulb_c), seg=14, rings=10)
            last, acc = k, 0.0
        k += 1

    # big holly sprig half-way up (-X / front side)
    zh = 2.95
    pos, T, X, Y = pole_frame(zh)
    sprig(pos - X * (POLE_R3(zh) + 0.01) - Y * 0.03, (-X * 1.0 - Y * 0.5 + T * 0.3), 0.19, n_leaves=4, spin=0.2)

    # tip: gold collar + pin + big gold star; the fishing line comes out of the star's top point
    def along(dz):
        return bendp((0, 0, ZE + dz))
    pos, T, X, Y = pole_frame(ZE)
    ring("Gold", along(0.02), T, POLE_R3(ZE) + 0.012, 0.02, seg=20, tseg=8)
    tube("Gold", [along(0.0), along(0.04), along(0.26)], [0.045, 0.03, 0.024], seg=10)
    pt, Tt, Xt, Yt = pole_frame(ZE + 0.26)
    SN = (Xt - Yt).normalized()                            # face turned 45 deg: readable from the side and the front
    STAR_C = pt + Tt * 0.24
    star("Star", STAR_C, SN, Tt, 0.36, 0.155, 0.1)
    star("Gold", STAR_C, SN, Tt, 0.2, 0.085, 0.125)        # raised gold centre on both faces
    T = Tt
    LINE_TIP = STAR_C + T * 0.36
    print("LINE_TIP", tuple(round(v, 4) for v in LINE_TIP), "TIP_DIR", tuple(round(v, 4) for v in T))

# =================================================================== bobber: snowman (big head, soft Santa hat, striped knit scarf)
if STAGE == "all":
    MODEL = "XmasBobber3"
    sph("Snow", (0.17, 0.17, 0.155), (0, 0, 0.06), seg=22, rings=16)
    sph("Snow", 0.14, (0, 0, 0.315), seg=22, rings=16)
    for s in (1, -1):
        sph("Coal", (0.019, 0.012, 0.028), (s * 0.048, -0.127, 0.345), seg=10, rings=7)
        sph("Snow", 0.006, (s * 0.048 + 0.006, -0.139, 0.355), seg=6, rings=4)
        sph("FurPink", (0.026, 0.01, 0.018), (s * 0.085, -0.11, 0.3), seg=10, rings=6)
    tube("Coal", [(0.05 * math.sin(a), -0.133 + 0.01 * (1 - math.cos(a)), 0.285 - 0.022 * math.cos(a)) for a in [math.radians(-55 + 11 * i) for i in range(11)]],
         0.0065, seg=5)                                                                  # smile
    cyl("Carrot", 0.027, 0.003, 0.1, (0, -0.18, 0.32), rot=(90, 0, 0), seg=12)
    for z in (0.13, 0.05):
        sph("Coal", 0.018, (0, -math.sqrt(max(0.17 ** 2 - ((z - 0.06) / 0.155 * 0.17) ** 2, 0)) - 0.004, z), seg=8, rings=6)
    # striped knit scarf: alternating red / green bands round the neck + a striped hanging end
    NS = 16
    for k in range(NS):
        a0, a1 = 2 * math.pi * k / NS, 2 * math.pi * (k + 1) / NS
        pts = [(0.135 * math.cos(a0 + (a1 - a0) * t / 3), 0.135 * math.sin(a0 + (a1 - a0) * t / 3), 0.205) for t in range(4)]
        tube("Scarf" if k % 2 == 0 else "ScarfGreen", pts, 0.038, seg=8)
    tail = [Vector((0.08, -0.115, 0.2)), Vector((0.1, -0.15, 0.14)), Vector((0.115, -0.165, 0.08)), Vector((0.125, -0.17, 0.02)), Vector((0.13, -0.17, -0.03))]
    for k in range(4):
        ribbon("Scarf" if k % 2 == 0 else "ScarfGreen", [tail[k], tail[k + 1]], 0.075, 0.022, side_axis=(1, 0.3, 0),
               notch=0.0)
    # soft Santa hat flopping to the +X side, fluffy brim + pom
    HB2 = Vector((0, 0, 0.43))
    hat = [HB2, HB2 + Vector((0, 0.01, 0.1)), HB2 + Vector((0.04, 0.01, 0.17)), HB2 + Vector((0.12, 0.0, 0.19)), HB2 + Vector((0.19, -0.01, 0.13))]
    tube("Red", hat, [0.125, 0.095, 0.065, 0.042, 0.026], seg=16)
    ring("Snow", HB2, (0, 0, 1), 0.13, 0.038, seg=28, tseg=10)
    for k in range(12):
        a = 2 * math.pi * k / 12
        sph("Snow", 0.032, HB2 + Vector((0.132 * math.cos(a), 0.132 * math.sin(a), 0)), seg=8, rings=6)
    sph("Snow", 0.045, hat[-1] + Vector((0.015, 0, -0.03)), seg=12, rings=8)
    print("BOBBER_LINE_ATTACH", tuple(round(v, 4) for v in (HB2 + Vector((0.02, 0.01, 0.185)))))
    MODEL = "XmasRod3"

# stub of the pole for context while reviewing
if STAGE in ("lower", "deer"):
    candy(0.64, 2.4, lambda z: 0.105 - 0.01 * (z - 0.64), turns=1.2, seg=32, step=0.02)

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
scn.display.shading.show_cavity = True
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
scn.collection.objects.link(cam)
scn.camera = cam

for model, objs in by_model.items():
    tri = 0
    for ob in objs:
        ob.data.calc_loop_triangles()
        tri += len(ob.data.loop_triangles)
        print("  OBJ", ob.name, len(ob.data.loop_triangles))
    print("MODEL", model, "OBJECTS", len(objs), "TRIS", tri)
    if STAGE == "all":
        bpy.ops.object.select_all(action='DESELECT')
        for ob in objs:
            ob.select_set(True)
        bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, model + ".glb"), export_format='GLB',
                                  use_selection=True, export_apply=True, export_yup=True)

def shot(name, focus, vdir, dist, lens=50, res=(900, 900), only=None):
    for o in bpy.data.objects:
        o.hide_render = (o is not cam) and (only is not None and not o.name.startswith(only))
    scn.render.resolution_x, scn.render.resolution_y = res
    cam.data.lens = lens
    cam.location = Vector(focus) + Vector(vdir).normalized() * dist
    cam.rotation_euler = (Vector(focus) - cam.location).to_track_quat('-Z', 'Y').to_euler()
    scn.render.filepath = os.path.join(OUT, "preview_%s.png" % name)
    bpy.ops.render.render(write_still=True)

if STAGE == "all":
    shot("all_side", (0, -0.3, 2.6), (1.0, -0.3, 0.1), 9.0, lens=50, res=(800, 1100), only="XmasRod3__")
    shot("all_front", (0, -0.3, 2.6), (0.45, -1.0, 0.2), 9.0, lens=50, res=(800, 1100), only="XmasRod3__")
    shot("all_top", bendp((0, 0, 4.2)), (0.8, -0.8, 0.2), 2.8, only="XmasRod3__")
    shot("all_mid", (0, -0.2, 2.6), (0.6, -1.0, 0.2), 2.8, only="XmasRod3__")
    shot("bobber", (0, 0, 0.3), (0.35, -1.0, 0.25), 1.6, only="XmasBobber3__")
if STAGE == "deer":
    dv = Vector((math.cos(math.radians(DEER_YAW)), math.sin(math.radians(DEER_YAW)), 0))
    shot("deer_face", dv * 0.2 + Vector((0, 0, 1.72)), dv + Vector((0, 0, 0.15)), 1.6, only="XmasRod3__")
    shot("deer_34", dv * 0.2 + Vector((0, 0, 1.7)), Vector((0.3, -1.0, 0.25)), 1.9, only="XmasRod3__")
    shot("deer_front", (0, -0.15, 0.9), (0.45, -1.0, 0.25), 4.0, only="XmasRod3__")
    shot("deer_side", (0, -0.15, 0.9), (1.0, -0.2, 0.15), 4.0, only="XmasRod3__")
if STAGE == "lower":
    shot("lower_front", (0, -0.15, 0.35), (0.45, -1.0, 0.25), 3.2, only="XmasRod3__")
    shot("lower_side", (0, -0.15, 0.35), (1.0, -0.35, 0.15), 3.2, only="XmasRod3__")
    shot("lower_bow", (0, -0.2, 0.9), (0.3, -1.0, 0.15), 1.6, only="XmasRod3__")
    shot("lower_reel", (0.1, -0.34, 0.74), (1.0, -0.5, 0.2), 1.3, only="XmasRod3__")
