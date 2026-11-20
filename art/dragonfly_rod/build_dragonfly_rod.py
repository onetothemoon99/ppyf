# Little Dragonfly fishing rod (เบ็ดแมลงปอน้อย, RodId Dragonfly, craft-only) + blue water-lily bobber. 2026-11-20 (helpers from build_frog_rod.py)
# Run:  blender.exe -b --factory-startup -P build_dragonfly_rod.py -- <outdir>
# Units: 1 Blender unit = 1 stud. Rod is built STRAIGHT UP along Blender +Z with the hand (Roblox Handle) at the origin.
#   Sides = +-X, underside = -Y (reel), top = +Y (frog, dragonfly, line guides). Tip (lotus bud point) at z ~5.9.
#   Studio tilts it 35 deg like the other rods (same as Rod_Phoenix).
# Bobber: origin = water line, lily pad at z ~0.01, tiny frog on top; LineAttach goes on the frog's head.
# Objects are named "<Model>__<Material>"; Studio colours them from COLORS (the importer drops colours).
# Output: DragonflyRod.glb, DragonflyBobber.glb + preview_*.png
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
    "Stem": (80, 170, 200), "StemLight": (150, 215, 235), "Vein": (225, 245, 255),
    "Grip": (215, 190, 140), "GripDark": (170, 140, 95), "Cord": (70, 150, 190),
    "Leaf": (70, 160, 110), "LeafDark": (45, 120, 85),
    "Dragon": (60, 190, 205), "DragonDark": (25, 105, 135), "DragonEye": (70, 215, 130), "Eye": (20, 30, 30),
    "Wing": (205, 238, 255), "WingEdge": (120, 200, 230), "Drop": (190, 230, 255),
    "Lotus": (150, 160, 255), "LotusLight": (205, 210, 255), "LotusCore": (255, 220, 90),
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


def dragonfly(c, s, facing=(0, 0, 1), up=(0, 1, 0)):
    """Dragonfly resting with wings open. c = thorax centre, s = scale, facing = head direction, up = back direction."""
    c, f, u = Vector(c), Vector(facing).normalized(), Vector(up).normalized()
    side = f.cross(u).normalized()
    tube("Dragon", [c + f * 0.05 * s, c, c - f * 0.12 * s, c - f * 0.3 * s, c - f * 0.45 * s],
         [0.035 * s, 0.032 * s, 0.022 * s, 0.014 * s, 0.008 * s], seg=8)
    for k in (1, 3):
        sph("DragonDark", 0.024 * s, c - f * (0.1 + 0.08 * k) * s, seg=8, rings=5)
    sph("Dragon", 0.042 * s, c + f * 0.08 * s, seg=10, rings=7)
    for sx in (1, -1):
        sph("DragonEye", 0.032 * s, c + f * 0.12 * s + side * sx * 0.03 * s + u * 0.012 * s, seg=8, rings=6)
        for df, L in ((0.03, 0.36), (-0.04, 0.32)):
            tipp = c + f * df * s + side * sx * L * s
            pts = [c + f * df * s + side * sx * 0.03 * s + u * 0.01 * s, (c + tipp) / 2 + f * df * 0.3 * s + u * 0.012 * s, tipp + u * 0.008 * s]
            leaf_blade("Wing", pts, 0.12 * s, normal=u)
            sph("WingEdge", 0.018 * s, tipp + u * 0.01 * s, seg=6, rings=4)

# =================================================================== 1) DragonflyRod (straight up +Z, hand at origin)
MODEL = "DragonflyRod"
POLE_R = lambda z: 0.06 + (0.024 - 0.06) * (z - 0.6) / (5.55 - 0.6)
sph("Stem", (0.115, 0.115, 0.09), (0, 0, -0.47))
sph("LotusCore", 0.05, (0, 0, -0.56), seg=8, rings=6)
cyl("Grip", 0.11, 0.102, 0.96, (0, 0, 0.07), seg=16)
helix("GripDark", -0.38, 0.52, 0.108, 0.1, 6, 0.009)
helix("Cord", -0.38, 0.52, 0.108, 0.1, 6, 0.009, phase=math.pi)
for z in (-0.4, 0.55):
    cyl("Cord", 0.118, 0.118, 0.045, (0, 0, z), seg=16)
# lotus-stem pole: blue lower half, light blue upper half, a thin silver vein spiralling up
cyl("Stem", POLE_R(0.6), POLE_R(3.0), 2.4, (0, 0, 1.8), seg=14)
cyl("StemLight", POLE_R(3.0), POLE_R(5.55), 2.55, (0, 0, 4.275), seg=14)
cyl("Vein", POLE_R(3.0) + 0.01, POLE_R(3.0) + 0.01, 0.05, (0, 0, 3.0), seg=14)
helix("Vein", 0.65, 5.3, POLE_R(0.65) + 0.006, POLE_R(5.3) + 0.004, 4.0, 0.008, phase=0.3, n=80)
# dragonfly-wing fins at the fore-grip: 2 translucent wings each side
for sx in (1, -1):
    for dz, L, a in ((0.0, 0.62, 15), (0.12, 0.55, -10)):
        base = Vector((sx * 0.07, 0.02, 0.95 + dz))
        tipp = base + Vector((sx * L * math.cos(math.radians(a)), 0.05, L * math.sin(math.radians(a)) - 0.08))
        leaf_blade("Wing", [base, (base + tipp) / 2 + Vector((0, 0.04, 0.02)), tipp], 0.2, normal=(0, 1, 0))
        tube("WingEdge", [base, tipp], [0.01, 0.004], seg=4)
        sph("WingEdge", (0.035, 0.012, 0.025), tipp + Vector((0, 0.01, 0)), seg=8, rings=5)
cyl("Cord", POLE_R(0.95) + 0.03, POLE_R(0.95) + 0.03, 0.06, (0, 0, 0.98), seg=14)
# reel (underside -Y): drum + open blue water lilies on lily-pad side plates, lily-bud knob
REEL = Vector((0, -0.2, 0.82))
cyl("Stem", 0.035, 0.035, 0.16, (0, -0.1, 0.82), rot=(90, 0, 0), seg=8)
cyl("GripDark", 0.12, 0.12, 0.12, REEL, rot=(0, 90, 0), seg=16)
for s in (1, -1):
    c = REEL + Vector((s * 0.07, 0, 0))
    fan_disk("Leaf", c, 0.16, 0.02, (0, 0, 1), (0, 1, 0), (1, 0, 0), notch=0.5, notch_at=math.pi / 2)
    lotus(c + Vector((s * 0.012, 0, 0)), (s, 0, 0), 0.13, petals=8, open_=0.75)
tube("Stem", [REEL + Vector((0.1, 0, 0)), REEL + Vector((0.13, -0.08, 0.05)), REEL + Vector((0.14, -0.15, 0.09))], 0.014, seg=6)
lotus(REEL + Vector((0.14, -0.17, 0.1)), (0.3, -0.6, 0.5), 0.07, petals=6, open_=0.1, core=False)
# line guides (top +Y)
for z in (1.9, 2.8, 3.6, 4.4, 5.1):
    r = POLE_R(z)
    pts = [(0.028 * math.cos(2 * math.pi * k / 10), r + 0.06, z + 0.028 * math.sin(2 * math.pi * k / 10)) for k in range(10)]
    tube("Vein", pts, 0.007, seg=4, closed=True, caps=False)
    cyl("Vein", 0.008, 0.008, 0.05, (0, r + 0.025, z), rot=(90, 0, 0), seg=5)
# the signature dragonfly resting on top of the pole near the tip (wings open)
dragonfly((0, POLE_R(4.75) + 0.05, 4.75), 1.25, facing=(0, 0, 1), up=(0, 1, 0))
# tip: small blue lotus bud
cyl("StemLight", POLE_R(5.55), 0.03, 0.1, (0, 0, 5.6), seg=10)
lotus((0, 0, 5.62), (0, 0, 1), 0.2, petals=6, open_=0.05, core=False)
cyl("LotusLight", 0.012, 0.0, 0.08, (0, 0, 5.86), seg=6)

# =================================================================== 2) DragonflyBobber (open blue water lily + small dragonfly; origin = water line)
MODEL = "DragonflyBobber"
fan_disk("Leaf", (0, 0, 0.01), 0.27, 0.024, (1, 0, 0), (0, 1, 0), (0, 0, 1), notch=0.55, notch_at=-math.pi / 2)
pad_veins("LeafDark", (0, 0, 0.01), 0.27, (1, 0, 0), (0, 1, 0), (0, 0, 1), 0.014, notch_at=-math.pi / 2, n=9, thick=0.009)
lotus((0, 0, 0.03), (0, 0, 1), 0.2, petals=10, open_=0.7)
lotus((0, 0, 0.05), (0, 0, 1), 0.14, petals=8, open_=0.3)
sph("Drop", (0.02, 0.02, 0.014), (0.18, 0.1, 0.03), seg=8, rings=5)
dragonfly((0.0, -0.02, 0.27), 0.8, facing=(0, -1, 0), up=(0, 0, 1))

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

VIEWS = {"DragonflyRod": [("side", Vector((1.0, -0.35, 0.15)), None, None), ("top", Vector((0.25, 1.0, 0.35)), None, None),
                     ("grip", Vector((0.35, 1.0, 0.3)), Vector((0, 0.05, 1.0)), 2.2), ("reel", Vector((1.0, -0.4, 0.1)), Vector((0, -0.2, 0.82)), 1.1),
                     ("tip", Vector((0.6, 1.0, 0.3)), Vector((0, 0.1, 4.9)), 2.2)],
         "DragonflyBobber": [("side", Vector((0.8, -1.0, 0.7)), None, None)]}
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
        scn.render.resolution_x, scn.render.resolution_y = (700, 1000) if (model == "DragonflyRod" and focus is None) else (800, 800)
        cam.data.lens = 40 if focus is None else 50
        cam.location = f + vdir.normalized() * dd
        cam.rotation_euler = (f - cam.location).to_track_quat('-Z', 'Y').to_euler()
        scn.render.filepath = os.path.join(OUT, "preview_%s_%s.png" % (model, vname))
        bpy.ops.render.render(write_still=True)
