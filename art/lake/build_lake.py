# Lake surround kit (from the user's picture of the lake: grey cut-stone rim, octagonal wooden gazebo with a
# brown roof on a stone platform jutting into the water). Run:
#   blender.exe -b --factory-startup -P build_lake.py -- <outdir>
# Units: 1 Blender unit = 1 stud, Z up. Roblox importer: local = (-bx, bz, by); Blender -Y = model front.
# Pieces (each built around (0,0,0)):
#   RimStoneA/B/C : bottom centre at z = 0, long side along X
#   GazeboBase    : round stone platform, TOP at z = 0, walkway toward -Y (to the shore)
#   Gazebo        : octagonal wooden pavilion, floor top at z = 0 (sits on GazeboBase), open side toward -Y
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
    "Stone_Top": (206, 208, 212), "Stone_Side": (168, 174, 184), "Stone_Shadow": (128, 136, 150),
    "Pave": (214, 204, 186), "Pave_Dark": (184, 172, 152),
    "Wood_Light": (206, 152, 96), "Wood_Mid": (170, 116, 70), "Wood_Dark": (120, 78, 48),
    "Roof_Light": (180, 114, 62), "Roof_Dark": (136, 82, 44), "Roof_Trim": (96, 60, 36),
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

def place(c, rz=0.0, rx=0.0, ry=0.0):
    return Matrix.Translation(Vector(c)) @ Matrix.Rotation(rz, 4, 'Z') @ Matrix.Rotation(ry, 4, 'Y') @ Matrix.Rotation(rx, 4, 'X')

def box(mat, c, s, rz=0.0, rx=0.0, ry=0.0):
    t = bmesh.new()
    bmesh.ops.create_cube(t, size=1.0)
    for v in t.verts:
        v.co = Vector((v.co.x * s[0], v.co.y * s[1], v.co.z * s[2]))
    emit(mat, t, place(c, rz, rx, ry))

def cyl(mat, c, r, h, n=10, r2=None, rz=0.0):
    t = bmesh.new()
    bmesh.ops.create_cone(t, cap_ends=True, cap_tris=False, segments=n, radius1=r, radius2=r if r2 is None else r2, depth=h)
    emit(mat, t, place(c, rz))

def ball(mat, c, s, sub=1):
    t = bmesh.new()
    bmesh.ops.create_icosphere(t, subdivisions=sub, radius=1.0)
    for v in t.verts:
        v.co = Vector((v.co.x * s[0], v.co.y * s[1], v.co.z * s[2]))
    emit(mat, t, Matrix.Translation(Vector(c)))

LIGHT = Vector((-0.45, -0.55, 0.75)).normalized()
STONE = ("Stone_Top", "Stone_Side", "Stone_Shadow")
def stone(c, s, rz=0.0, seed=0, bevel=0.22, jitter=0.05):
    """Cut stone block: bevelled box, slight noise, 3 tones by facing."""
    rnd = random.Random(seed)
    t = bmesh.new()
    bmesh.ops.create_cube(t, size=1.0)
    for v in t.verts:
        v.co = Vector((v.co.x * s[0], v.co.y * s[1], v.co.z * s[2]))
    bmesh.ops.bevel(t, geom=list(t.edges), offset=min(s) * bevel, segments=2, profile=0.6, affect='EDGES')
    k = rnd.random() * 50
    for v in t.verts:
        v.co += v.co.normalized() * noise.noise(v.co * (1.4 / max(s)) + Vector((k, k, k))) * jitter * min(s)
    bmesh.ops.transform(t, matrix=place(c, rz), verts=t.verts)
    for f in t.faces:
        f.normal_update()
        d = f.normal.dot(LIGHT)
        mat = STONE[0] if (f.normal.z > 0.6 and d > 0.25) else (STONE[1] if d > -0.12 else STONE[2])
        face(mat, [v.co.copy() for v in f.verts])
    t.free()

PIECES = []
def add(name, fn):
    PIECE["name"] = name
    fn()
    PIECES.append(name)

# ------------------------------------------------------------------ rim stones (bottom at z = 0)
add("RimStoneA", lambda: stone((0, 0, 1.2), (4.4, 2.6, 2.4), seed=1))
add("RimStoneB", lambda: stone((0, 0, 1.05), (3.4, 2.3, 2.1), seed=2))
add("RimStoneC", lambda: stone((0, 0, 1.3), (5.0, 2.9, 2.6), seed=3))

# ------------------------------------------------------------------ gazebo stone base (top at z = 0)
BR = 12.0          # platform radius
WALK_L, WALK_W = 16.0, 8.0
def gazebo_base():
    n = 24
    # paved top (polygon) + stone body down to z = -6
    top = [Vector((math.cos(2 * math.pi * i / n) * BR, math.sin(2 * math.pi * i / n) * BR, 0)) for i in range(n)]
    face("Pave", top)
    for i in range(n):
        a, b = top[i], top[(i + 1) % n]
        face("Stone_Side", [a, b, b - Vector((0, 0, 6)), a - Vector((0, 0, 6))])
    # paving joints: a few darker rings/lines
    for r in (4.5, 8.5):
        for i in range(n):
            a0, a1 = 2 * math.pi * i / n, 2 * math.pi * (i + 1) / n
            p = lambda a, rr: Vector((math.cos(a) * rr, math.sin(a) * rr, 0.02))
            face("Pave_Dark", [p(a0, r), p(a1, r), p(a1, r + 0.25), p(a0, r + 0.25)])
    # edge stones ring (raised kerb), gap at the walkway (toward -Y)
    m = 18
    for i in range(m):
        a = 2 * math.pi * (i + 0.5) / m
        if abs(math.atan2(math.sin(a + math.pi / 2), math.cos(a + math.pi / 2))) < 0.42:
            continue  # leave the walkway side open
        c = (math.cos(a) * (BR - 0.6), math.sin(a) * (BR - 0.6), 0.45)
        stone(c, (3.9, 1.5, 1.1), rz=a + math.pi / 2, seed=10 + i, jitter=0.03)
    # walkway slab toward -Y
    y0 = -BR + 1.0
    box("Pave", (0, y0 - WALK_L / 2, -0.15), (WALK_W, WALK_L, 0.3))
    box("Stone_Side", (0, y0 - WALK_L / 2, -3.2), (WALK_W - 0.2, WALK_L - 0.2, 5.8))
    for i in range(4):
        y = y0 - 2.0 - i * 4.0
        for sx in (-1, 1):
            stone((sx * (WALK_W / 2 + 0.2), y, 0.4), (1.3, 3.6, 1.0), seed=40 + i * 2 + (sx > 0 and 1 or 0), jitter=0.03)
add("GazeboBase", gazebo_base)

# ------------------------------------------------------------------ gazebo (floor top z = 0)
GR = 7.6           # post ring radius
POST_H = 8.6
def gazebo():
    n = 8
    ang = [2 * math.pi * (i + 0.5) / n - math.pi / 2 for i in range(n)]   # posts; side 0 faces -Y (open)
    P = [Vector((math.cos(a) * GR, math.sin(a) * GR, 0)) for a in ang]
    # floor: octagon deck + planks
    fl = [Vector((math.cos(a) * (GR + 0.9), math.sin(a) * (GR + 0.9), 0.0)) for a in ang]
    face("Wood_Light", [v + Vector((0, 0, 0.35)) for v in fl])
    for i in range(n):
        a, b = fl[i], fl[(i + 1) % n]
        face("Wood_Dark", [a + Vector((0, 0, 0.35)), b + Vector((0, 0, 0.35)), b, a])
    for k in range(-6, 7):
        x = k * 1.25
        half = math.sqrt(max(0.0, (GR * 0.95) ** 2 - x * x))
        if half > 0.5:
            box("Wood_Mid", (x, 0, 0.36), (0.08, 2 * half, 0.02))
    # posts
    for p in P:
        cyl("Wood_Mid", p + Vector((0, 0, 0.35 + POST_H / 2)), 0.42, POST_H, n=8)
        cyl("Wood_Dark", p + Vector((0, 0, 0.6)), 0.6, 0.5, n=8)
    # railings on 7 sides (side between P[n-1] and P[0] = front, open)
    for i in range(n):
        a, b = P[i], P[(i + 1) % n]
        mid = (a + b) / 2
        d = b - a
        rz = math.atan2(d.y, d.x)
        if i == n - 1:
            continue
        for z, th in ((1.6, 0.28), (3.0, 0.32)):
            box("Wood_Light", (mid.x, mid.y, z), (d.length, 0.32, th), rz=rz)
        for k in range(1, 5):
            q = a.lerp(b, k / 5)
            box("Wood_Mid", (q.x, q.y, 2.2), (0.18, 0.18, 1.5), rz=rz)
        # bench inside
        inner = mid * 0.86
        box("Wood_Light", (inner.x, inner.y, 1.5), (d.length * 0.8, 1.1, 0.25), rz=rz)
    # top beams
    for i in range(n):
        a, b = P[i], P[(i + 1) % n]
        mid, d = (a + b) / 2, b - a
        box("Wood_Dark", (mid.x, mid.y, POST_H + 0.1), (d.length + 0.6, 0.55, 0.6), rz=math.atan2(d.y, d.x))
    # roof: stacked octagonal frustum bands (shingles), wide eaves
    z0 = POST_H + 0.4
    rings = [(GR + 3.4, z0), (GR + 1.9, z0 + 1.6), (GR + 0.3, z0 + 3.2), (GR - 1.6, z0 + 4.6), (GR - 3.8, z0 + 5.8), (0.5, z0 + 7.0)]
    def oct_pts(r, z):
        return [Vector((math.cos(a) * r, math.sin(a) * r, z)) for a in ang]
    for j in range(len(rings) - 1):
        (r0, za), (r1, zb) = rings[j], rings[j + 1]
        A, B = oct_pts(r0, za), oct_pts(r1, zb)
        mat = "Roof_Light" if j % 2 == 0 else "Roof_Dark"
        for i in range(n):
            face(mat, [A[i], A[(i + 1) % n], B[(i + 1) % n], B[i]])
    # eave underside + trim edge
    E = oct_pts(rings[0][0], rings[0][1])
    face("Wood_Dark", list(reversed(oct_pts(rings[0][0], rings[0][1] - 0.01))))
    for i in range(n):
        a, b = E[i], E[(i + 1) % n]
        face("Roof_Trim", [a, b, b - Vector((0, 0, 0.5)), a - Vector((0, 0, 0.5))])
    # ridge ribs
    for i in range(n):
        rod_a = Vector((math.cos(ang[i]) * rings[0][0], math.sin(ang[i]) * rings[0][0], rings[0][1] + 0.1))
        rod_b = Vector((0, 0, rings[-1][1] + 0.1))
        d = rod_b - rod_a
        q = Vector((0, 0, 1)).rotation_difference(d.normalized())
        t = bmesh.new()
        bmesh.ops.create_cone(t, cap_ends=True, cap_tris=False, segments=5, radius1=0.22, radius2=0.22, depth=d.length)
        emit("Roof_Trim", t, Matrix.Translation((rod_a + rod_b) / 2) @ q.to_matrix().to_4x4())
    # finial
    cyl("Wood_Dark", (0, 0, rings[-1][1] + 0.6), 0.5, 1.2, n=8, r2=0.3)
    ball("Roof_Trim", (0, 0, rings[-1][1] + 1.5), (0.6, 0.6, 0.6))
add("Gazebo", gazebo)

# ------------------------------------------------------------------ build objects
GRID = 34.0
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

bpy.ops.object.select_all(action='DESELECT')
for ob in objs:
    ob.select_set(True)
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "LakeKit.glb"), export_format='GLB',
                          use_selection=True, export_apply=True, export_yup=True)

# ------------------------------------------------------------------ preview: gazebo on its base + stones
scn = bpy.context.scene
scn.render.engine = 'BLENDER_WORKBENCH'
scn.display.shading.light = 'STUDIO'
scn.display.shading.color_type = 'MATERIAL'
scn.display.shading.show_backface_culling = True
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
cam.data.type = 'ORTHO'
scn.collection.objects.link(cam)
scn.camera = cam
def shot(path, loc, look, scale, rx=1000, ry=760):
    scn.render.resolution_x, scn.render.resolution_y = rx, ry
    cam.data.ortho_scale = scale
    cam.location = loc
    cam.rotation_euler = (Vector(look) - Vector(loc)).to_track_quat('-Z', 'Y').to_euler()
    scn.render.filepath = os.path.join(OUT, path)
    bpy.ops.render.render(write_still=True)
gi = PIECES.index("Gazebo")
gx, gy = (gi % COLS) * GRID, (gi // COLS) * GRID
shot("preview_gazebo.png", (gx - 30, gy - 40, 28), (gx, gy, 5), 40)
shot("preview_kit.png", (GRID - 50, GRID / 2 - 90, 70), (GRID, GRID / 2, 0), 110)
