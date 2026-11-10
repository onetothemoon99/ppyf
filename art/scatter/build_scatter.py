# Island scatter kit: cartoon rocks + bushes for open grass (from the user's picture: soft lavender-grey
# rounded boulders, bright round bushes with tiny flowers). Run:
#   blender.exe -b --factory-startup -P build_scatter.py -- <outdir>
# Units: 1 Blender unit = 1 stud, Z up, every piece built around (0,0,0) with its bottom centre at z = 0
# (sunk 0.4 below so it sits into the grass). Roblox importer: local = (-bx, bz, by).
# Mesh objects are named "<Piece>__<Material>"; Studio groups them back per piece and colours them from COLORS.
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
    # Studio colours (set after a look in game lighting, the sky light adds blue): 166,140,146 / 138,116,126 / 106,90,104
    "Rock_Top": (196, 188, 214), "Rock_Side": (162, 152, 186), "Rock_Shadow": (124, 114, 150),
    "Leaf_Light": (130, 204, 84), "Leaf_Mid": (92, 172, 70), "Leaf_Dark": (58, 132, 60),
    "Flower_Pink": (242, 150, 200), "Flower_White": (250, 248, 240), "Flower_Yellow": (250, 214, 80),
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
def face(mat, pts):
    key = PIECE["name"] + "__" + mat
    bm = PBM.setdefault(key, bmesh.new())
    vs = [bm.verts.new(Vector(p)) for p in pts]
    try:
        bm.faces.new(vs)
    except ValueError:
        pass

def emit(mat, t, M=Matrix()):
    for f in t.faces:
        face(mat, [M @ v.co for v in f.verts])
    t.free()

LIGHT = Vector((-0.45, -0.55, 0.75)).normalized()
ROCK = ("Rock_Top", "Rock_Side", "Rock_Shadow")
SINK = 0.4

def boulder(c, s, rz=0.0, seed=0):
    """Soft rounded boulder: bevelled box, pushed toward an ellipsoid, light noise, 3 tones by facing."""
    rnd = random.Random(seed)
    t = bmesh.new()
    bmesh.ops.create_cube(t, size=1.0)
    for v in t.verts:
        v.co = Vector((v.co.x * s[0], v.co.y * s[1], v.co.z * s[2]))
    bmesh.ops.bevel(t, geom=list(t.edges), offset=min(s) * 0.36, segments=2, profile=0.5, affect='EDGES')
    k = rnd.random() * 50
    half = Vector((s[0] / 2, s[1] / 2, s[2] / 2))
    for v in t.verts:
        n = Vector((v.co.x / half.x, v.co.y / half.y, v.co.z / half.z))
        if n.length > 0:
            e = n.normalized()
            v.co = v.co.lerp(Vector((e.x * half.x, e.y * half.y, e.z * half.z)), 0.18)  # a little rounder, still chunky
        v.co += v.co.normalized() * noise.noise(v.co * (1.6 / max(s)) + Vector((k, k, k))) * 0.13 * min(s)
        if v.co.z < -half.z * 0.55:  # flatter base
            v.co.z = -half.z * 0.55 - (v.co.z + half.z * 0.55) * 0.3
    M = Matrix.Translation(Vector(c)) @ Matrix.Rotation(rz, 4, 'Z')
    bmesh.ops.transform(t, matrix=M, verts=t.verts)
    for f in t.faces:
        f.normal_update()
        d = f.normal.dot(LIGHT)
        mat = ROCK[0] if (f.normal.z > 0.55 and d > 0.25) else (ROCK[1] if d > -0.12 else ROCK[2])
        face(mat, [v.co.copy() for v in f.verts])
    t.free()

def blob(mat, c, s, sub=2):
    t = bmesh.new()
    bmesh.ops.create_icosphere(t, subdivisions=sub, radius=1.0)
    for v in t.verts:
        v.co = Vector((v.co.x * s[0], v.co.y * s[1], v.co.z * s[2]))
    emit(mat, t, Matrix.Translation(Vector(c)))

def bush(r, seed, lobes=6, flowers=(), nflowers=0):
    """Round cartoon bush: dark core + lighter lobes on top/sides + optional tiny flowers."""
    rnd = random.Random(seed)
    base = r * 0.75 - SINK
    blob("Leaf_Dark", (0, 0, base), (r, r, r * 0.78))
    for i in range(lobes):
        a = 2 * math.pi * i / lobes + rnd.uniform(-0.35, 0.35)
        rr = r * rnd.uniform(0.5, 0.62)
        p = (math.cos(a) * r * 0.55, math.sin(a) * r * 0.55, base + r * rnd.uniform(0.15, 0.45))
        blob("Leaf_Mid" if i % 2 else "Leaf_Light", p, (rr, rr, rr * 0.82))
    blob("Leaf_Light", (rnd.uniform(-0.2, 0.2) * r, rnd.uniform(-0.2, 0.2) * r, base + r * 0.55), (r * 0.62, r * 0.62, r * 0.5))
    for i in range(nflowers):
        a = rnd.uniform(0, 2 * math.pi)
        el = rnd.uniform(0.25, 1.1)
        p = Vector((math.cos(a) * math.cos(el), math.sin(a) * math.cos(el), math.sin(el)))
        pos = Vector((p.x * r * 0.98, p.y * r * 0.98, base + p.z * r * 0.92 + 0.1))
        fm = flowers[i % len(flowers)]
        fs = r * 0.17
        blob(fm, pos, (fs, fs, fs * 0.7), sub=1)
        blob("Flower_Yellow", pos + p * fs * 0.6, (fs * 0.4, fs * 0.4, fs * 0.4), sub=1)

PIECES = []
def add(name, fn):
    PIECE["name"] = name
    fn()
    PIECES.append(name)

# rocks (bottom at z = -SINK)
add("RockSingle", lambda: boulder((0, 0, 2.2 - SINK), (6.0, 5.0, 4.6), rz=0.3, seed=11))
def rock_pair():   # like the picture: a big boulder with a slightly smaller one leaning on its side
    boulder((-1.4, 0.3, 2.7 - SINK), (7.0, 6.0, 5.6), rz=0.2, seed=21)
    boulder((3.4, -0.8, 2.1 - SINK), (5.2, 4.6, 4.4), rz=-0.5, seed=22)
add("RockPair", rock_pair)
def rock_cluster():
    boulder((0, 0, 1.4 - SINK), (3.6, 3.2, 2.9), rz=0.1, seed=31)
    boulder((2.6, 1.4, 1.0 - SINK), (2.6, 2.3, 2.1), rz=0.8, seed=32)
    boulder((-2.2, 1.6, 0.8 - SINK), (2.1, 1.9, 1.7), rz=-0.6, seed=33)
add("RockCluster", rock_cluster)

# bushes
add("BushSmall", lambda: bush(1.7, 41, lobes=5))
add("BushBig", lambda: bush(2.8, 42, lobes=7))
add("BushFlower", lambda: bush(2.3, 43, lobes=6, flowers=("Flower_Pink", "Flower_White", "Flower_Pink"), nflowers=16))

# ------------------------------------------------------------------ build objects (grid)
GRID = 16.0
COLS = 3
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
print("PIECES", len(PIECES), "OBJECTS", len(objs))
print("TRIS", tri, "TOTAL", sum(tri.values()))
for i, name in enumerate(PIECES):
    print("OFFSET", name, (i % COLS) * GRID, (i // COLS) * GRID)

bpy.ops.object.select_all(action='DESELECT')
for ob in objs:
    ob.select_set(True)
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "IslandScatterKit.glb"), export_format='GLB',
                          use_selection=True, export_apply=True, export_yup=True)

# ------------------------------------------------------------------ preview
scn = bpy.context.scene
scn.render.engine = 'BLENDER_WORKBENCH'
scn.display.shading.light = 'STUDIO'
scn.display.shading.color_type = 'MATERIAL'
scn.display.shading.show_backface_culling = True
scn.world = bpy.data.worlds.new("W") if scn.world is None else scn.world
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
cam.data.type = 'ORTHO'
scn.collection.objects.link(cam)
scn.camera = cam
scn.render.resolution_x, scn.render.resolution_y = 1100, 760
cam.data.ortho_scale = 44
cx, cy = GRID, GRID / 2
cam.location = (cx - 22, cy - 40, 30)
cam.rotation_euler = (Vector((cx, cy, 1.5)) - Vector(cam.location)).to_track_quat('-Z', 'Y').to_euler()
scn.render.filepath = os.path.join(OUT, "preview_kit.png")
bpy.ops.render.render(write_still=True)
