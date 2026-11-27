# Christmas Tree rod (เบ็ดต้นคริสต์มาส, RodId XmasTree, 199 R$, same stats as SunBee) + bauble bobber + 3D gold star fx. 2026-11-27
# Run:  blender.exe -b --factory-startup -P build_xmas_tree_rod.py -- <outdir>
# Units: 1 Blender unit = 1 stud. Helpers copied from art/sakura_jelly_rod/build_sakura_jelly.py.
#  XmasTreeRod: built STRAIGHT UP along +Z, hand (Roblox Handle) at the origin, reel underside (-Y), line guides on top (+Y).
#               Line point = top of the gold star at (0, 0, 5.9). Studio tilts it like the other rods.
#  XmasTreeBobber: origin = water line; red bauble above, LineAttach on the gold loop (~z 0.42).
#  XmasStar (fx): 5-point star in the XZ plane (faces -Y / +Y), origin = star centre.
# Objects are named "<Model>__<Material>"; Studio colours them from COLORS (the importer drops colours).
# Bulb* and Star are meant to be Neon in Studio.
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
    "PineDark": (22, 84, 48), "Pine": (34, 120, 64), "PineLight": (64, 156, 84),
    "Gold": (236, 184, 62), "Star": (255, 214, 80), "Red": (206, 32, 44), "RedDeep": (140, 18, 30),
    "Snow": (246, 250, 255), "Silver": (206, 214, 226), "Wire": (28, 58, 36),
    "BulbRed": (255, 70, 70), "BulbYellow": (255, 214, 70), "BulbBlue": (70, 160, 255), "BulbGreen": (90, 240, 120),
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

BULBS = ("BulbRed", "BulbYellow", "BulbBlue", "BulbGreen")

def bulb(col, at, out, size=0.035):
    """Small fairy-light bulb sticking out along `out` from `at`, with a dark socket."""
    at, out = Vector(at), Vector(out).normalized()
    bmesh.ops.create_cone(target("Wire"), cap_ends=True, cap_tris=False, segments=8, radius1=size * 0.55, radius2=size * 0.55,
                          depth=size * 0.8, matrix=basis(at + out * size * 0.4, out))
    sph_m(col, basis(at + out * size * 1.4, out) @ Matrix.Diagonal((size * 0.75, size * 0.75, size * 1.05, 1.0)), seg=10, rings=7)

def bauble(col, top, size, cap="Gold"):
    """Christmas ornament hanging below `top`: gold cap + ball with a thin snow band."""
    top = Vector(top)
    cyl(cap, size * 0.28, size * 0.28, size * 0.22, top - Vector((0, 0, size * 0.11)), seg=10)
    c = top - Vector((0, 0, size * 0.2 + size))
    sph(col, size, c, seg=16, rings=10)
    tube("Snow", [c + Vector((size * 1.01 * math.cos(2 * math.pi * k / 20), size * 1.01 * math.sin(2 * math.pi * k / 20), 0)) for k in range(20)],
         size * 0.09, seg=5, closed=True, caps=False)

def tier(z0, h, R, n_tufts, spin=0.0):
    """One pine tier around the pole: a star-shaped cone (pointed branch tips that droop a little), dark underside,
    snow on every other branch tip."""
    bm = target("Pine")
    n2 = 2 * n_tufts
    top = bm.verts.new((0, 0, z0 + h))
    rim = []
    for k in range(n2):
        a = spin + math.pi * k / n_tufts
        outer = k % 2 == 0
        rr = R if outer else R * 0.74
        rim.append(bm.verts.new((rr * math.cos(a), rr * math.sin(a), z0 - (h * 0.12 if outer else -h * 0.05))))
    faces = [bm.faces.new((top, rim[k], rim[(k + 1) % n2])) for k in range(n2)]
    bmesh.ops.recalc_face_normals(bm, faces=faces)
    bmd = target("PineDark")
    under = bmd.verts.new((0, 0, z0 + h * 0.3))
    rim2 = [bmd.verts.new(v.co + Vector((0, 0, -0.004))) for v in rim]
    faces = [bmd.faces.new((under, rim2[(k + 1) % n2], rim2[k])) for k in range(n2)]
    bmesh.ops.recalc_face_normals(bmd, faces=faces)
    for k in range(0, n2, 4):   # snow caps on every other branch tip
        a = spin + math.pi * k / n_tufts
        rr = R * 0.8
        sph("Snow", (R * 0.17, R * 0.09, h * 0.09), (rr * math.cos(a), rr * math.sin(a), z0 + h * 0.13),
            rot=(0, -28, math.degrees(a)), seg=8, rings=5)

# =================================================================== 1) XmasTreeRod
MODEL = "XmasTreeRod"
POLE_R = lambda z: 0.066 + (0.025 - 0.066) * (z - 1.0) / (5.5 - 1.0)

# butt: red bauble in a gold cup
cyl("Gold", 0.13, 0.12, 0.07, (0, 0, -0.42))
sph("Gold", (0.115, 0.115, 0.06), (0, 0, -0.47))
sph("Red", 0.1, (0, 0, -0.58), seg=16, rings=10)
tube("Snow", [(0.101 * math.cos(2 * math.pi * k / 20), 0.101 * math.sin(2 * math.pi * k / 20), -0.58) for k in range(20)], 0.009, seg=5, closed=True, caps=False)
sph("Gold", 0.025, (0, 0, -0.69), seg=8, rings=5)

# grip: candy-cane wrap (red with two white spiral stripes)
cyl("Red", 0.115, 0.105, 0.98, (0, 0, 0.07), seg=16)
for off in (0.0, math.pi):
    pts = []
    for i in range(60):
        u = i / 59
        a = off + 2 * math.pi * 3 * u
        r = 0.116 + (0.106 - 0.116) * u
        pts.append((r * math.cos(a), r * math.sin(a), -0.38 + 0.9 * u))
    tube("Snow", pts, 0.03, seg=6, flat=0.35, normal=(0, 0, 1))
cyl("Gold", 0.125, 0.125, 0.05, (0, 0, 0.58), seg=16)
cyl("PineDark", 0.12, 0.085, 0.12, (0, 0, 0.66), seg=16)

# reel (underside -Y): red drum, green plates with a gold star, snow rim, gold crank + red knob
REEL = Vector((0, -0.2, 0.82))
cyl("Gold", 0.035, 0.035, 0.16, (0, -0.1, 0.82), rot=(90, 0, 0), seg=8)
cyl("Red", 0.16, 0.16, 0.12, REEL, rot=(0, 90, 0), seg=20)
for s in (1, -1):
    cyl("PineDark", 0.17, 0.17, 0.025, REEL + Vector((s * 0.07, 0, 0)), rot=(0, 90, 0), seg=20)
    rim = [REEL + Vector((s * 0.085, 0.165 * math.cos(2 * math.pi * i / 28), 0.165 * math.sin(2 * math.pi * i / 28))) for i in range(28)]
    tube("Snow", rim, 0.012, seg=5, closed=True, caps=False)
    star("Gold", REEL + Vector((s * 0.085, 0, 0)), (s, 0, 0), (0, 0, 1), 0.12, 0.05, 0.02)
tube("Gold", [REEL + Vector((0.1, 0, 0)), REEL + Vector((0.14, -0.08, 0.06)), REEL + Vector((0.15, -0.16, 0.1))], 0.016, seg=6)
sph("Red", 0.045, REEL + Vector((0.16, -0.19, 0.12)), seg=12, rings=8)

# pole: dark pine -> pine -> light pine, gold collars
for z0, z1, col in ((0.72, 2.6, "PineDark"), (2.6, 4.1, "Pine"), (4.1, 5.45, "PineLight")):
    cyl(col, POLE_R(max(z0, 1.0)), POLE_R(z1), z1 - z0, (0, 0, (z0 + z1) / 2), seg=12)
for z in (2.6, 4.1):
    cyl("Gold", POLE_R(z) + 0.022, POLE_R(z) + 0.022, 0.07, (0, 0, z), seg=12)
# line guides on top (+Y)
for z in (1.9, 2.9, 3.8, 4.6, 5.2):
    r = POLE_R(z)
    cyl("Gold", 0.01, 0.01, 0.07, (0, r + 0.03, z), rot=(90, 0, 0), seg=6)
    tube("Gold", [(0.03 * math.cos(2 * math.pi * k / 12), r + 0.08, z + 0.03 * math.sin(2 * math.pi * k / 12)) for k in range(12)],
         0.008, seg=5, closed=True, caps=False)

# fairy-light string spiralling up the pole with coloured bulbs
wire, bi = [], 0
N = 140
for i in range(N):
    u = i / (N - 1)
    z = 1.75 + 3.6 * u
    a = 2 * math.pi * 4.5 * u
    r = POLE_R(z) + 0.012
    wire.append((r * math.cos(a), r * math.sin(a), z))
tube("Wire", wire, 0.009, seg=5)
for i in range(4, N - 2, 6):
    x, y, z = wire[i]
    out = Vector((x, y, 0)).normalized()
    if out.y > 0.75:      # no bulb right under a line guide
        continue
    bulb(BULBS[bi % 4], (x, y, z), out + Vector((0, 0, -0.25)), size=0.036 - 0.01 * (z - 1.75) / 3.6)
    bi += 1

# ornaments hanging off the pole sides
for z, ang, col, sz in ((2.3, 0, "Red", 0.075), (2.95, 180, "Gold", 0.065), (3.55, 20, "BulbBlue", 0.06), (4.25, 200, "Silver", 0.055), (4.8, -10, "Red", 0.05)):
    a = math.radians(ang)
    side = Vector((math.cos(a), math.sin(a) * 0.5 - 0.35, 0)).normalized()
    at = Vector((0, 0, z)) + side * (POLE_R(z) + 0.01)
    tube("Gold", [at, at + side * 0.04 + Vector((0, 0, -0.02))], 0.007, seg=4)
    bauble(col, at + side * 0.05 + Vector((0, 0, -0.02)), sz)

# fore-grip mini Christmas tree: three snowy tiers around the pole, baubles + bulbs
JZ = 1.12
TIERS = ((JZ, 0.32, 0.38, 9, 0.0), (JZ + 0.24, 0.29, 0.3, 8, 0.3), (JZ + 0.46, 0.27, 0.21, 7, 0.6))
for z0, h, R, n, sp in TIERS:
    tier(z0, h, R, n, sp)
for k, (t, col, a) in enumerate(((0, "Red", 0.3), (0, "Gold", 2.4), (0, "BulbBlue", 4.5), (1, "Silver", 1.3), (1, "Red", 3.6), (2, "Gold", 5.4))):
    z0, h, R = TIERS[t][:3]
    bauble(col, (R * 0.9 * math.cos(a), R * 0.9 * math.sin(a), z0 + 0.02), 0.05 if t == 0 else 0.042)
for k in range(9):
    a = 2 * math.pi * k / 9 + 0.9
    z0, h, R = TIERS[k % 3][:3]
    rr = R * 0.7
    p = Vector((rr * math.cos(a), rr * math.sin(a), z0 + h * (1 - rr / R)))
    bulb(BULBS[k % 4], p, Vector((math.cos(a), math.sin(a), 0.9)), size=0.03)

# tip: gold collar + big gold star (line comes out of its top point)
TIP = Vector((0, 0, 5.5))
cyl("Gold", POLE_R(5.45) + 0.012, POLE_R(5.45) + 0.004, 0.06, TIP, seg=10)
cyl("Gold", 0.02, 0.02, 0.2, TIP + Vector((0, 0, 0.12)), seg=8)
star("Star", TIP + Vector((0, 0, 0.36)), (1, 0, 0), (0, 0, 1), 0.3, 0.13, 0.08)

# =================================================================== 2) XmasTreeBobber (red Christmas bauble)
MODEL = "XmasTreeBobber"
BC = Vector((0, 0, 0.1))
sph("Red", 0.22, BC, seg=20, rings=14)
for z, w in ((0.0, 0.03), (0.09, 0.018), (-0.09, 0.018)):
    rz = math.sqrt(max(0.22 ** 2 - z ** 2, 0)) * 1.01
    tube("Gold" if z == 0 else "Snow", [BC + Vector((rz * math.cos(2 * math.pi * k / 28), rz * math.sin(2 * math.pi * k / 28), z)) for k in range(28)],
         w, seg=6, closed=True, caps=False)
for k in range(8):   # snow dots between the bands
    for z in (0.15, -0.15):
        a = 2 * math.pi * k / 8 + (0.4 if z < 0 else 0)
        rz = math.sqrt(0.22 ** 2 - z ** 2)
        sph("Snow", 0.022, BC + Vector((math.cos(a) * rz, math.sin(a) * rz, z)), seg=6, rings=4)
cyl("Gold", 0.065, 0.06, 0.08, BC + Vector((0, 0, 0.245)), seg=12)
tube("Gold", [BC + Vector((0.035 * math.cos(2 * math.pi * k / 14), 0, 0.31 + 0.035 * math.sin(2 * math.pi * k / 14))) for k in range(14)],
     0.009, seg=5, closed=True, caps=False)

# =================================================================== 3) XmasStar (3D fx that spins above the holder's head)
MODEL = "XmasStar"
star("Star", (0, 0, 0), (0, -1, 0), (0, 0, 1), 1.0, 0.42, 0.26)
star("Gold", (0, 0, 0), (0, -1, 0), (0, 0, 1), 0.55, 0.23, 0.33)   # raised gold inner star on both faces

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

VIEWS = {"XmasTreeRod": [("side", Vector((1.0, -0.35, 0.15))), ("top", Vector((0.25, 1.0, 0.35)))],
         "XmasTreeBobber": [("side", Vector((0.8, -1.0, 0.45)))],
         "XmasStar": [("front", Vector((0.3, -1.0, 0.2)))]}
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
    for vname, vdir in VIEWS[model]:
        scn.render.resolution_x, scn.render.resolution_y = (700, 1000) if model == "XmasTreeRod" else (800, 800)
        cam.data.lens = 40
        cam.location = mid + vdir.normalized() * size * 1.25
        cam.rotation_euler = (mid - cam.location).to_track_quat('-Z', 'Y').to_euler()
        scn.render.filepath = os.path.join(OUT, "preview_%s_%s.png" % (model, vname))
        bpy.ops.render.render(write_still=True)

# close-ups: reel, fore-grip tree, tip star
for o in bpy.data.objects:
    o.hide_render = not (o.name.startswith("XmasTreeRod__") or o is cam)
for vname, vdir, focus, dist in (("reel", Vector((1.0, -0.3, 0.1)), REEL, 1.1), ("tree", Vector((0.6, -1.0, 0.3)), Vector((0, 0, 1.3)), 1.8),
                                 ("tip", Vector((0.8, -0.6, 0.2)), Vector((0, 0, 5.4)), 1.6)):
    scn.render.resolution_x, scn.render.resolution_y = 800, 800
    cam.data.lens = 50
    cam.location = focus + vdir.normalized() * dist
    cam.rotation_euler = (focus - cam.location).to_track_quat('-Z', 'Y').to_euler()
    scn.render.filepath = os.path.join(OUT, "preview_XmasTreeRod_%s.png" % vname)
    bpy.ops.render.render(write_still=True)

