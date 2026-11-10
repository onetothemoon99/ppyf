# Activity-plaza market props (cartoon, from the user's picture: striped stalls, flower cart, balloons, fruit crates,
# potted plants). Run:  blender.exe -b --factory-startup -P build_plaza_kit.py -- <outdir>
# 1 unit = 1 stud, Z up, every piece bottom-centre at (0,0,0), front faces -Y (Roblox LookVector).
# Mesh objects "<Piece>__<Material>"; Studio colours them from COLORS.
import bpy, bmesh, math, random, sys, os
from mathutils import Vector, Matrix

OUT = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else os.path.dirname(os.path.abspath(__file__))
os.makedirs(OUT, exist_ok=True)
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o, do_unlink=True)

def lin(c):
    c = c / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

COLORS = {
    "Wood_Light": (214, 166, 112), "Wood_Mid": (180, 128, 80), "Wood_Dark": (120, 82, 54),
    "Awning_Red": (232, 86, 86), "Awning_Blue": (78, 150, 226), "Awning_Green": (110, 190, 110), "Awning_White": (252, 250, 244),
    "Cloth_Cream": (250, 238, 210), "Metal_Black": (50, 50, 58),
    "Fruit_Red": (226, 60, 60), "Fruit_Orange": (246, 150, 50), "Fruit_Yellow": (248, 212, 70), "Fruit_Green": (120, 196, 70),
    "Leaf_Light": (126, 200, 74), "Leaf_Dark": (62, 144, 62),
    "Flower_Pink": (244, 140, 196), "Flower_White": (252, 248, 250), "Flower_Yellow": (250, 214, 72), "Flower_Red": (234, 76, 76),
    "Pot_Terracotta": (206, 112, 74), "Pot_Rim": (226, 140, 100),
    "Balloon_Pink": (246, 128, 180), "Balloon_Blue": (100, 170, 246), "Balloon_Yellow": (250, 214, 80),
    "Balloon_Green": (120, 210, 130), "Balloon_Purple": (180, 130, 230), "String": (240, 240, 240),
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

def rod(mat, a, b, r, n=6):
    a, b = Vector(a), Vector(b)
    d = b - a
    q = Vector((0, 0, 1)).rotation_difference(d.normalized())
    t = bmesh.new()
    bmesh.ops.create_cone(t, cap_ends=True, cap_tris=False, segments=n, radius1=r, radius2=r, depth=d.length)
    emit(mat, t, Matrix.Translation((a + b) / 2) @ q.to_matrix().to_4x4())

def wheel(c, r, axis_x=True):
    """Upright wheel; axle along X (axis_x) or along Y."""
    if axis_x:
        cyl("Wood_Dark", c, r, 0.35, n=14, ry=math.pi / 2)
        cyl("Wood_Light", c, r * 0.3, 0.45, n=8, ry=math.pi / 2)
        for k in range(4):
            box("Wood_Light", c, (0.18, r * 1.8, 0.2), rx=k * math.pi / 4)
    else:
        cyl("Wood_Dark", c, r, 0.35, n=14, rx=math.pi / 2)
        cyl("Wood_Light", c, r * 0.3, 0.45, n=8, rx=math.pi / 2)
        for k in range(4):
            box("Wood_Light", c, (r * 1.8, 0.18, 0.2), ry=k * math.pi / 4)

def fruit_pile(c, w, d, mats, rows=2, seed=0):
    rnd = random.Random(seed)
    for i in range(int(w / 0.75)):
        for j in range(int(d / 0.75)):
            for k in range(rows):
                if k == 1 and (i + j) % 2:
                    continue
                x = c[0] - w / 2 + 0.4 + i * 0.75 + rnd.uniform(-0.08, 0.08)
                y = c[1] - d / 2 + 0.4 + j * 0.75
                ball(mats[(i + j + k) % len(mats)], (x, y, c[2] + 0.35 + k * 0.5), (0.38, 0.38, 0.36))

PIECES = []
def add(name, fn):
    PIECE["name"] = name
    fn()
    PIECES.append(name)

# ------------------------------------------------------------------ market stall with striped awning
def stall(stripe):
    def fn():
        W, D = 9.0, 5.0
        box("Wood_Mid", (0, 0, 1.6), (W, D, 0.35))                     # counter top
        box("Wood_Dark", (0, -D / 2 + 0.2, 0.75), (W, 0.3, 1.5))       # front panel
        box("Cloth_Cream", (0, -D / 2 - 0.02, 0.95), (W - 0.6, 0.12, 0.9))
        for sx in (-1, 1):
            box("Wood_Dark", (sx * (W / 2 - 0.2), 0, 0.8), (0.3, D, 1.6))
            for sy in (-1, 1):
                box("Wood_Dark", (sx * (W / 2 - 0.25), sy * (D / 2 - 0.25), 3.5), (0.4, 0.4, 7.0))
        box("Wood_Dark", (0, D / 2 - 0.2, 1.4), (W, 0.3, 2.8))
        # fruit trays on the counter
        for i, mats in enumerate((["Fruit_Red", "Fruit_Green"], ["Fruit_Orange", "Fruit_Yellow"], ["Fruit_Yellow", "Fruit_Red"])):
            x = -W / 3 + i * W / 3
            box("Wood_Light", (x, -0.6, 1.95), (2.6, 2.2, 0.35))
            fruit_pile((x, -0.6, 1.95), 2.2, 1.8, mats, seed=i)
        # awning: striped slope + scalloped edge
        n = 8
        depth, z0, z1 = D + 1.6, 7.4, 6.0
        ang = math.atan2(z0 - z1, depth)
        L = math.hypot(depth, z0 - z1)
        for s in range(n):
            x = -W / 2 - 0.2 + (W + 0.4) * (s + 0.5) / n
            mat = stripe if s % 2 == 0 else "Awning_White"
            box(mat, (x, D / 2 - depth / 2 + 0.3, (z0 + z1) / 2), ((W + 0.4) / n + 0.02, L, 0.2), rx=ang)
            cyl(mat, (x, D / 2 - depth + 0.25, z1 - 0.35), (W + 0.4) / n / 2, 0.15, n=8, rx=math.pi / 2)
        # sign board on top
        box("Wood_Mid", (0, D / 2 - 0.3, 8.3), (4.6, 0.3, 1.4))
        box("Cloth_Cream", (0, D / 2 - 0.5, 8.3), (4.0, 0.1, 1.0))
        # crates in front
        for k, x in enumerate((-3.2, 3.3)):
            box("Wood_Light", (x, -D / 2 - 1.2, 0.6), (1.8, 1.4, 1.2), rz=0.1 * (k * 2 - 1))
            fruit_pile((x, -D / 2 - 1.2, 1.1), 1.5, 1.0, ["Fruit_Red", "Fruit_Orange"] if k else ["Fruit_Green", "Fruit_Yellow"], rows=1, seed=10 + k)
    return fn
add("StallRed", stall("Awning_Red"))
add("StallBlue", stall("Awning_Blue"))
add("StallGreen", stall("Awning_Green"))

# ------------------------------------------------------------------ flower cart
def flower_cart():
    box("Wood_Mid", (0, 0, 2.0), (6.0, 3.2, 0.4))
    for sx in (-1, 1):
        box("Wood_Light", (0, sx * 1.55, 2.7), (6.0, 0.2, 1.1))
        box("Wood_Light", (sx * 2.95, 0, 2.7), (0.2, 3.2, 1.1))
    wheel((-1.3, -1.85, 1.3), 1.3, axis_x=False)
    wheel((-1.3, 1.85, 1.3), 1.3, axis_x=False)
    box("Wood_Dark", (2.6, 0, 1.0), (0.35, 0.35, 2.0))
    for sy in (-1, 1):
        rod("Wood_Dark", (2.9, sy * 1.2, 2.2), (5.6, sy * 1.0, 2.0), 0.14)
    rnd = random.Random(3)
    fl = ["Flower_Pink", "Flower_White", "Flower_Yellow", "Flower_Red"]
    for i in range(6):
        for j in range(3):
            x, y = -2.3 + i * 0.92, -0.95 + j * 0.95
            cyl("Pot_Terracotta", (x, y, 2.55), 0.36, 0.7, n=8, r2=0.42)
            ball("Leaf_Dark", (x, y, 3.1), (0.45, 0.45, 0.35))
            ball(fl[(i + j) % 4], (x + rnd.uniform(-0.1, 0.1), y, 3.4), (0.36, 0.36, 0.3))
    # small striped umbrella
    rod("Wood_Dark", (-2.4, 0, 2.2), (-2.4, 0, 6.8), 0.1)
    for k in range(8):
        a0, a1 = k * math.pi / 4, (k + 1) * math.pi / 4
        mat = "Awning_Red" if k % 2 == 0 else "Awning_White"
        t = bmesh.new()
        vs = [t.verts.new(Vector((-2.4, 0, 7.2))), t.verts.new(Vector((-2.4 + 2.6 * math.cos(a0), 2.6 * math.sin(a0), 6.0))),
              t.verts.new(Vector((-2.4 + 2.6 * math.cos(a1), 2.6 * math.sin(a1), 6.0)))]
        t.faces.new(vs)
        t2 = bmesh.new()
        vs2 = [t2.verts.new(v.co.copy()) for v in reversed(vs)]
        t2.faces.new(vs2)
        emit(mat, t)
        emit(mat, t2)
add("FlowerCart", flower_cart)

# ------------------------------------------------------------------ balloon bundle on a weighted post
def balloons():
    cyl("Wood_Dark", (0, 0, 0.3), 0.8, 0.6, n=10)
    rod("Wood_Dark", (0, 0, 0.6), (0, 0, 4.2), 0.12)
    cols = ["Balloon_Pink", "Balloon_Blue", "Balloon_Yellow", "Balloon_Green", "Balloon_Purple", "Balloon_Pink", "Balloon_Blue"]
    rnd = random.Random(5)
    for i, c in enumerate(cols):
        a = 2 * math.pi * i / len(cols)
        r = 0 if i == 0 else rnd.uniform(1.0, 1.6)
        top = Vector((math.cos(a) * r, math.sin(a) * r, 8.4 + rnd.uniform(-0.6, 0.8) + (1.0 if i == 0 else 0)))
        rod("String", (0, 0, 4.2), top - Vector((0, 0, 1.0)), 0.035, n=4)
        ball(c, top, (0.85, 0.85, 1.05), sub=2)
        cyl(c, top - Vector((0, 0, 1.08)), 0.18, 0.25, n=6, r2=0.05)
add("Balloons", balloons)

# ------------------------------------------------------------------ fruit crates stack, barrel of flowers, potted shrub
def fruit_crates():
    for k, (x, y, z, rz, mats) in enumerate(((-1.0, 0, 0, 0.05, ["Fruit_Red", "Fruit_Green"]), (1.0, 0.1, 0, -0.08, ["Fruit_Orange", "Fruit_Yellow"]),
                                            (0, 0.1, 1.3, 0.2, ["Fruit_Yellow", "Fruit_Red"]))):
        box("Wood_Light", (x, y, z + 0.6), (1.9, 1.5, 1.2), rz=rz)
        box("Wood_Dark", (x, y - 0.76, z + 0.6), (1.9, 0.06, 0.25), rz=rz)
        fruit_pile((x, y, z + 1.1), 1.6, 1.1, mats, rows=1, seed=20 + k)
add("FruitCrates", fruit_crates)

def flower_barrel():
    cyl("Wood_Mid", (0, 0, 0.9), 1.1, 1.8, n=12, r2=1.25)
    for z in (0.35, 1.45):
        cyl("Metal_Black", (0, 0, z), 1.18 + z * 0.06, 0.16, n=12)
    ball("Leaf_Dark", (0, 0, 2.0), (1.15, 1.15, 0.6))
    rnd = random.Random(7)
    fl = ["Flower_Pink", "Flower_White", "Flower_Yellow"]
    for i in range(9):
        a = 2 * math.pi * i / 9
        r = 0.4 if i % 3 == 0 else 0.85
        ball(fl[i % 3], (math.cos(a) * r, math.sin(a) * r, 2.35 + rnd.uniform(0, 0.2)), (0.32, 0.32, 0.26))
add("FlowerBarrel", flower_barrel)

def potted_shrub():
    cyl("Pot_Terracotta", (0, 0, 0.8), 0.9, 1.6, n=12, r2=1.15)
    cyl("Pot_Rim", (0, 0, 1.65), 1.25, 0.25, n=12)
    ball("Leaf_Dark", (0, 0, 2.9), (1.3, 1.3, 1.3))
    for i in range(5):
        a = 2 * math.pi * i / 5
        ball("Leaf_Light", (math.cos(a) * 0.7, math.sin(a) * 0.7, 3.2), (0.75, 0.75, 0.7))
    for i in range(5):
        a = 2 * math.pi * i / 5 + 0.6
        ball("Flower_Pink", (math.cos(a) * 1.1, math.sin(a) * 1.1, 3.4), (0.25, 0.25, 0.22))
add("PottedShrub", potted_shrub)

# ------------------------------------------------------------------ build + export
GRID, COLS = 18.0, 4
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
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "PlazaKit.glb"), export_format='GLB', use_selection=True, export_apply=True, export_yup=True)

scn = bpy.context.scene
scn.render.engine = 'BLENDER_WORKBENCH'
scn.display.shading.light = 'STUDIO'
scn.display.shading.color_type = 'MATERIAL'
scn.display.shading.show_backface_culling = True
scn.render.resolution_x, scn.render.resolution_y = 1100, 800
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
cam.data.type = 'ORTHO'
cam.data.ortho_scale = 70
scn.collection.objects.link(cam)
scn.camera = cam
cx, cy = (COLS - 1) * GRID / 2, ((len(PIECES) - 1) // COLS) * GRID / 2
cam.location = (cx - 20, cy - 70, 45)
cam.rotation_euler = (Vector((cx, cy, 3)) - cam.location).to_track_quat('-Z', 'Y').to_euler()
scn.render.filepath = os.path.join(OUT, "preview_kit.png")
bpy.ops.render.render(write_still=True)
