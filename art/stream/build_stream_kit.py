# Stream dressing kit (cartoon, from the user's picture): arched wooden bridges, a rock weir with a small
# white cascade, grey river rocks, stepping stones, lily pads / lotus, fern clumps. Run:
#   blender.exe -b --factory-startup -P build_stream_kit.py -- <outdir>
# 1 unit = 1 stud, Z up, each piece built round (0,0,0) = ground / water level at its centre, front = -Y.
# Mesh objects "<Piece>__<Material>"; Studio colours them from COLORS (importer drops colours).
import bpy, bmesh, math, random, sys, os
from mathutils import Vector, Matrix, noise

OUT = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else os.path.dirname(os.path.abspath(__file__))
os.makedirs(OUT, exist_ok=True)
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o, do_unlink=True)

def lin(c):
    c = c / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

COLORS = {
    "Wood_Light": (206, 154, 98), "Wood_Mid": (170, 116, 70), "Wood_Dark": (112, 76, 48),
    "Stone_Top": (196, 200, 206), "Stone_Side": (150, 156, 166), "Stone_Shadow": (108, 114, 128),
    "Fall_White": (240, 250, 255), "Fall_Light": (170, 228, 248),
    "Pad_Light": (128, 196, 84), "Pad_Dark": (76, 150, 64), "Lotus_Pink": (246, 150, 196), "Lotus_Light": (252, 214, 230), "Lotus_Core": (250, 214, 80),
    "Fern_Light": (120, 196, 80), "Fern_Dark": (56, 134, 64),
}
MATS = {}
for name, rgb in COLORS.items():
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    col = tuple(lin(v) for v in rgb) + (1.0,)
    next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED").inputs["Base Color"].default_value = col
    m.diffuse_color = col
    MATS[name] = m

PIECE = {"name": None}
PBM = {}
def emit(mat, t, M=Matrix()):
    bm = PBM.setdefault(PIECE["name"] + "__" + mat, bmesh.new())
    for f in t.faces:
        vs = [bm.verts.new(M @ v.co) for v in f.verts]
        try:
            bm.faces.new(vs)
        except ValueError:
            pass
    t.free()

def face(mat, pts):
    bm = PBM.setdefault(PIECE["name"] + "__" + mat, bmesh.new())
    vs = [bm.verts.new(Vector(p)) for p in pts]
    try:
        bm.faces.new(vs)
    except ValueError:
        pass

def place(c, rz=0.0, rx=0.0, ry=0.0):
    return Matrix.Translation(Vector(c)) @ Matrix.Rotation(rz, 4, 'Z') @ Matrix.Rotation(ry, 4, 'Y') @ Matrix.Rotation(rx, 4, 'X')

def box(mat, c, s, rz=0.0, rx=0.0, ry=0.0):
    t = bmesh.new()
    bmesh.ops.create_cube(t, size=1.0)
    for v in t.verts:
        v.co = Vector((v.co.x * s[0], v.co.y * s[1], v.co.z * s[2]))
    emit(mat, t, place(c, rz, rx, ry))

def cyl(mat, c, r, h, n=10, r2=None, rz=0.0, rx=0.0, ry=0.0):
    t = bmesh.new()
    bmesh.ops.create_cone(t, cap_ends=True, cap_tris=False, segments=n, radius1=r, radius2=r if r2 is None else r2, depth=h)
    emit(mat, t, place(c, rz, rx, ry))

def ball(mat, c, s, sub=1):
    t = bmesh.new()
    bmesh.ops.create_icosphere(t, subdivisions=sub, radius=1.0)
    for v in t.verts:
        v.co = Vector((v.co.x * s[0], v.co.y * s[1], v.co.z * s[2]))
    emit(mat, t, Matrix.Translation(Vector(c)))

LIGHT = Vector((-0.45, -0.55, 0.75)).normalized()
STONE = ("Stone_Top", "Stone_Side", "Stone_Shadow")
def rock(c, s, rot=0.0, bevel=0.42, jitter=0.08, seed=0, seg=2):
    rnd = random.Random(seed)
    t = bmesh.new()
    bmesh.ops.create_cube(t, size=1.0)
    for v in t.verts:
        v.co = Vector((v.co.x * s[0], v.co.y * s[1], v.co.z * s[2]))
    bmesh.ops.bevel(t, geom=list(t.edges), offset=min(s) * bevel, segments=seg, profile=0.55, affect='EDGES')
    k = rnd.random() * 50
    for v in t.verts:
        v.co += v.co.normalized() * noise.noise(v.co * (1.3 / max(s)) + Vector((k, k, k))) * jitter * min(s)
    bmesh.ops.transform(t, matrix=place(c, rot), verts=t.verts)
    for f in t.faces:
        f.normal_update()
        d = f.normal.dot(LIGHT)
        mat = STONE[0] if (f.normal.z > 0.6 and d > 0.3) else (STONE[1] if d > -0.1 else STONE[2])
        face(mat, [v.co.copy() for v in f.verts])
    t.free()

def blade(base, direction, length, width, mats, droop=0.45, segs=6):
    d = Vector(direction).normalized()
    side = d.cross(Vector((0, 0, 1)))
    if side.length < 1e-3:
        side = Vector((1, 0, 0))
    side.normalize()
    rows = []
    for i in range(segs + 1):
        t = i / segs
        w = width * math.sin(math.pi * min(t * 1.05, 1.0)) ** 0.6
        p = Vector(base) + d * length * t - Vector((0, 0, 1)) * droop * length * t * t
        rows.append((p, p - side * w, p + side * w))
    for i in range(segs):
        (c0, l0, r0), (c1, l1, r1) = rows[i], rows[i + 1]
        for mat, quad in ((mats[0], [c0, l0, l1, c1]), (mats[1], [c0, c1, r1, r0])):
            face(mat, quad)
            face(mat, list(reversed(quad)))

PIECES = []
# optional 2nd arg "bridges" = build only the two bridges -> BridgeKit.glb (2026-11-11 rail re-upload)
ONLY = sys.argv[sys.argv.index("--") + 2] if "--" in sys.argv and len(sys.argv) > sys.argv.index("--") + 2 else None
def add(name, fn):
    if ONLY == "bridges" and not name.startswith("Bridge"):
        return
    PIECE["name"] = name
    fn()
    PIECES.append(name)

# ------------------------------------------------------------------ arched wooden bridge (span along X, deck ends at z = 0.25)
RAIL_POST, RAIL_TOP, RAIL_LOW = 4.2, 4.0, (2.6, 1.2)   # heights above the deck
def bridge(span, width, rise, rail=True):
    def fn():
        half = span / 2
        n = int(span / 1.1)
        def zf(x):
            return 0.25 + rise * (1 - (x / half) ** 2)
        for i in range(n):
            x0 = -half + span * i / n
            x1 = -half + span * (i + 1) / n
            xm = (x0 + x1) / 2
            ang = math.atan2(zf(x1) - zf(x0), x1 - x0)
            mat = "Wood_Light" if i % 2 == 0 else "Wood_Mid"
            box(mat, (xm, 0, zf(xm) - 0.25), (x1 - x0 + 0.04, width, 0.5), ry=-ang)
        # side beams under the deck edges
        for sy in (-1, 1):
            for i in range(n):
                x0 = -half + span * i / n
                x1 = -half + span * (i + 1) / n
                xm = (x0 + x1) / 2
                ang = math.atan2(zf(x1) - zf(x0), x1 - x0)
                box("Wood_Dark", (xm, sy * (width / 2 - 0.3), zf(xm) - 0.9), (x1 - x0 + 0.05, 0.6, 1.1), ry=-ang)
        if rail:
            # 2026-11-11 rails raised (user: "ปรับรั้วบนสะพานให้สูงขึ้นอีกนิด"): posts 3.0 -> 4.2, top rail 2.8 -> 4.0,
            # two lower rails (was one) so the side looks closed. Walls that stop players are Studio Parts (RailBlocker).
            k = int(span / 4)
            for sy in (-1, 1):
                ys = sy * (width / 2 - 0.25)
                tops = []
                for i in range(k + 1):
                    x = -half + 0.6 + (span - 1.2) * i / k
                    z = zf(x)
                    cyl("Wood_Dark", (x, ys, z + RAIL_POST / 2), 0.3, RAIL_POST, n=6)
                    cyl("Wood_Mid", (x, ys, z + RAIL_POST + 0.05), 0.36, 0.2, n=6)
                    tops.append(Vector((x, ys, z + RAIL_TOP)))
                for i in range(k):
                    a, b = tops[i], tops[i + 1]
                    m = (a + b) / 2
                    ang = math.atan2(b.z - a.z, b.x - a.x)
                    box("Wood_Mid", tuple(m), ((b - a).length + 0.1, 0.32, 0.32), ry=-ang)
                    for low in RAIL_LOW:
                        box("Wood_Light", tuple(m - Vector((0, 0, RAIL_TOP - low))), ((b - a).length + 0.1, 0.22, 0.22), ry=-ang)
        # stone abutments at both ends
        for sx in (-1, 1):
            for j, yy in enumerate((-width / 2 - 0.6, width / 2 + 0.6)):
                rock((sx * (half - 0.5), yy, 0.3), (3.2, 2.4, 2.4), rot=0.3 * sx + j, seed=11 + j + (sx > 0) * 5, seg=1)
    return fn
add("BridgePath", bridge(72.0, 10.0, 5.0))
add("BridgeRoad", bridge(72.0, 15.0, 4.6))

# ------------------------------------------------------------------ weir / small cascade across the stream (line along X, water flows to -Y)
def weir(length):
    def fn():
        rnd = random.Random(21)
        x = -length / 2
        while x < length / 2:
            w = rnd.uniform(2.6, 4.2)
            rock((x + w / 2, rnd.uniform(-0.4, 0.4), rnd.uniform(-0.1, 0.4)), (w, rnd.uniform(2.6, 3.4), rnd.uniform(2.2, 3.2)),
                 rot=rnd.uniform(-0.3, 0.3), seed=rnd.randint(0, 999), seg=1)
            x += w - 0.3
        # white water spilling down the front (-Y) between the rocks, in strips
        k = int(length / 3)
        for i in range(k):
            x0 = -length / 2 + length * i / k + 0.3
            x1 = -length / 2 + length * (i + 1) / k - 0.3
            mat = "Fall_White" if i % 2 == 0 else "Fall_Light"
            for j in range(3):
                t0, t1 = j / 3, (j + 1) / 3
                def P(x, t):
                    return (x, -1.2 - 2.2 * t, 1.2 - 1.9 * (t ** 1.4))
                face(mat, [P(x0, t0), P(x1, t0), P(x1, t1), P(x0, t1)])
        # foam blobs where it lands
        for i in range(int(length / 1.6)):
            x = -length / 2 + 0.8 + i * 1.6
            ball("Fall_White", (x + rnd.uniform(-0.3, 0.3), -3.8 + rnd.uniform(-0.3, 0.3), -0.55), (1.0, 0.8, 0.35))
    return fn
add("Weir", weir(56.0))

# ------------------------------------------------------------------ river rocks, stepping stone
add("RiverRockS", lambda: rock((0, 0, 0.9), (3.0, 2.6, 2.2), rot=0.4, seed=31))
add("RiverRockM", lambda: rock((0, 0, 1.4), (4.8, 4.0, 3.2), rot=-0.3, seed=32))
def rock_l():
    rock((0, 0, 1.9), (6.6, 5.2, 4.4), rot=0.2, seed=33)
    rock((3.4, -1.6, 0.9), (3.0, 2.6, 2.2), rot=0.8, seed=34)
add("RiverRockL", rock_l)
def rock_pair():
    rock((0, 0, 1.5), (5.0, 4.2, 3.4), rot=0.1, seed=35)
    rock((-3.2, 1.4, 1.0), (3.2, 2.8, 2.4), rot=-0.6, seed=36)
    rock((2.6, 2.0, 0.6), (2.0, 1.8, 1.4), rot=1.0, seed=37)
add("RiverRockCluster", rock_pair)
def rock_xl():
    rock((0, 0, 2.6), (9.0, 7.2, 6.0), rot=0.25, seed=51)
    rock((5.2, -2.6, 1.3), (4.4, 3.8, 3.0), rot=0.9, seed=52)
    rock((-4.6, 2.4, 1.0), (3.4, 3.0, 2.4), rot=-0.5, seed=53)
add("RiverRockXL", rock_xl)
add("SteppingStone", lambda: rock((0, 0, 0.1), (3.2, 2.9, 1.0), rot=0.3, bevel=0.45, seed=38))

# ------------------------------------------------------------------ lily pads + lotus (pivot at the water surface)
def pad(c, r, notch=0.5, mats=("Pad_Light", "Pad_Dark"), seed=0):
    n = 16
    a0 = notch / 2
    top = []
    for i in range(n + 1):
        a = a0 + (2 * math.pi - notch) * i / n
        top.append(Vector((c[0] + math.cos(a) * r, c[1] + math.sin(a) * r, c[2] + 0.12)))
    cen = Vector((c[0], c[1], c[2] + 0.12))
    for i in range(n):
        face(mats[0] if i % 2 == 0 else mats[1], [cen, top[i], top[i + 1]])
def lily():
    pad((0, 0, 0), 1.6)
    pad((2.6, 0.9, 0), 1.1, seed=1)
    pad((-1.6, 2.2, 0), 0.9, seed=2)
add("LilyPads", lily)
def lotus():
    pad((0, 0, 0), 1.7)
    pad((2.4, -1.0, 0), 1.0, seed=3)
    base = Vector((0.2, 0.1, 0.25))
    for ring, (n, L, up, mat) in enumerate(((7, 1.1, 0.5, "Lotus_Pink"), (6, 0.8, 0.95, "Lotus_Light"))):
        for i in range(n):
            a = 2 * math.pi * i / n + ring * 0.4
            blade(base, (math.cos(a), math.sin(a), up), L, 0.42, (mat, mat), droop=-0.05, segs=4)
    ball("Lotus_Core", base + Vector((0, 0, 0.25)), (0.3, 0.3, 0.2))
add("Lotus", lotus)

# ------------------------------------------------------------------ fern clump / reeds on the bank
def fern():
    rnd = random.Random(41)
    for i in range(11):
        a = 2 * math.pi * i / 11 + rnd.uniform(-0.2, 0.2)
        blade((0, 0, 0.1), (math.cos(a), math.sin(a), rnd.uniform(0.6, 1.4)), rnd.uniform(2.6, 3.6), 0.55,
              ("Fern_Light", "Fern_Dark") if i % 2 else ("Fern_Dark", "Fern_Light"), droop=0.5)
add("FernClump", fern)
def reeds():
    rnd = random.Random(42)
    for i in range(14):
        a = rnd.uniform(0, 2 * math.pi); r = rnd.uniform(0, 1.0)
        b = Vector((math.cos(a) * r, math.sin(a) * r, 0))
        blade(b, (rnd.uniform(-0.2, 0.2), rnd.uniform(-0.2, 0.2), 1), rnd.uniform(3.0, 4.6), 0.18, ("Fern_Light", "Fern_Dark"), droop=0.05, segs=4)
add("Reeds", reeds)

# ------------------------------------------------------------------ build + export
GRID, COLS = 84.0, 4
objs, tri = [], {}
for key, bm in PBM.items():
    p = key.split("__")[0]
    i = PIECES.index(p)
    off = Vector(((i % COLS) * GRID, (i // COLS) * GRID, 0))
    for v in bm.verts:
        v.co += off
    me = bpy.data.meshes.new(key)
    bm.to_mesh(me)
    bm.free()
    me.materials.append(MATS[key.split("__")[1]])
    ob = bpy.data.objects.new(key, me)
    bpy.context.scene.collection.objects.link(ob)
    objs.append(ob)
    me.calc_loop_triangles()
    tri[p] = tri.get(p, 0) + len(me.loop_triangles)
allv = [v.co for ob in objs for v in ob.data.vertices]
print("PIECES", len(PIECES), "OBJECTS", len(objs), "TRIS", tri, "TOTAL", sum(tri.values()))
print("BBOX_MIN", tuple(round(min(c[k] for c in allv), 4) for k in range(3)))
print("BBOX_MAX", tuple(round(max(c[k] for c in allv), 4) for k in range(3)))
for i, name in enumerate(PIECES):
    print("OFFSET", name, (i % COLS) * GRID, (i // COLS) * GRID)
bpy.ops.object.select_all(action='DESELECT')
for ob in objs:
    ob.select_set(True)
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "BridgeKit.glb" if ONLY == "bridges" else "StreamKit.glb"), export_format='GLB', use_selection=True, export_apply=True, export_yup=True)

scn = bpy.context.scene
scn.render.engine = 'BLENDER_WORKBENCH'
scn.display.shading.light = 'STUDIO'
scn.display.shading.color_type = 'MATERIAL'
scn.display.shading.show_backface_culling = True
scn.render.resolution_x, scn.render.resolution_y = 1100, 800
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
cam.data.type = 'ORTHO'
cam.data.ortho_scale = 230
scn.collection.objects.link(cam)
scn.camera = cam
cx, cy = (COLS - 1) * GRID / 2, ((len(PIECES) - 1) // COLS) * GRID / 2
cam.location = (cx - 40, cy - 200, 140)
cam.rotation_euler = (Vector((cx, cy, 0)) - cam.location).to_track_quat('-Z', 'Y').to_euler()
scn.render.filepath = os.path.join(OUT, "preview_kit.png")
bpy.ops.render.render(write_still=True)
cam.data.ortho_scale = 60
cam.location = (-20, -45, 25)
cam.rotation_euler = (Vector((0, 0, 2)) - cam.location).to_track_quat('-Z', 'Y').to_euler()
scn.render.filepath = os.path.join(OUT, "preview_bridge.png")
bpy.ops.render.render(write_still=True)
