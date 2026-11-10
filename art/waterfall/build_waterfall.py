# Cartoon jungle waterfall (v2, laid out from the user's picture) for Roblox. Run:
#   blender.exe -b --factory-startup -P build_waterfall.py -- <outdir>
# Units: 1 Blender unit = 1 stud. Front faces -Y, Z up, z=0 = pool water level.
# Picture -> studs: x = (px - 325) * 0.25, z = (545 - py) * 0.25.
# Rocks get 3 tones per face (lit top / side / shadow) like the cartoon; leaves are two-tone and double-sided.
# Water sheets are real meshes (white / light / dark-blue bands); Roblox Beams add the motion on top.
import bpy, bmesh, math, random, sys, os
from mathutils import Vector, Matrix, noise

OUT = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else os.path.dirname(__file__)
os.makedirs(OUT, exist_ok=True)
random.seed(11)
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o, do_unlink=True)

def lin(c):
    c = c / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

COLORS = {
    "Rock_Top": (214, 182, 140), "Rock_Side": (172, 136, 100), "Rock_Shadow": (124, 94, 70), "Rock_Deep": (82, 60, 48),
    "Leaf_Light": (156, 214, 62), "Leaf_Mid": (84, 172, 48), "Leaf_Dark": (38, 124, 52), "Leaf_Deep": (22, 88, 48),
    "Teal_Light": (64, 176, 184), "Teal_Dark": (30, 112, 132),
    "Trunk": (168, 122, 72), "Trunk_Dark": (118, 84, 52), "Flower": (252, 252, 246),
    "Water_White": (242, 251, 255), "Water_Light": (176, 226, 250), "Water_Mid": (104, 184, 238), "Water_Dark": (46, 96, 196),
}
MATS = {}
for name, rgb in COLORS.items():
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    col = tuple(lin(v) for v in rgb) + (1.0,)
    m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = col
    m.diffuse_color = col
    MATS[name] = m

BM = {}
def face(mat, pts):
    bm = BM.setdefault(mat, bmesh.new())
    vs = [bm.verts.new(p) for p in pts]
    try:
        bm.faces.new(vs)
    except ValueError:
        pass

LIGHT = Vector((-0.45, -0.55, 0.75)).normalized()   # light from top-left-front, as in the picture

# ------------------------------------------------------------------ rocks
TONES = {"warm": ("Rock_Top", "Rock_Side", "Rock_Shadow"), "dark": ("Rock_Side", "Rock_Shadow", "Rock_Deep"),
         "deep": ("Rock_Shadow", "Rock_Deep", "Rock_Deep")}
def rock(c, s, rot=0.0, tone="warm", bevel=0.3, jitter=0.06, tilt=(0, 0), seg=3, seed=0):
    rnd = random.Random(seed)
    t = bmesh.new()
    bmesh.ops.create_cube(t, size=1.0)
    for v in t.verts:
        v.co = Vector((v.co.x * s[0], v.co.y * s[1], v.co.z * s[2]))
    bmesh.ops.bevel(t, geom=list(t.edges), offset=min(s) * bevel, segments=seg, profile=0.55, affect='EDGES')
    k = rnd.random() * 50
    for v in t.verts:
        v.co += v.co.normalized() * noise.noise(v.co * (1.3 / max(s)) + Vector((k, k, k))) * jitter * min(s)
    m = Matrix.Translation(Vector(c)) @ Matrix.Rotation(tilt[0], 4, 'X') @ Matrix.Rotation(tilt[1], 4, 'Y') @ Matrix.Rotation(rot, 4, 'Z')
    bmesh.ops.transform(t, matrix=m, verts=t.verts)
    top, side, shadow = TONES[tone]
    for f in t.faces:
        f.normal_update()
        d = f.normal.dot(LIGHT)
        mat = top if (f.normal.z > 0.6 and d > 0.35) else (side if d > 0.0 else shadow)
        face(mat, [v.co.copy() for v in f.verts])
    t.free()

# Back mass (fills gaps, never seen directly)
rock((10, 26, 58), (70, 30, 116), tone="deep", bevel=0.1, seed=1)
rock((-30, 18, 40), (32, 24, 80), tone="deep", bevel=0.15, seed=3)
rock((50, 16, 50), (40, 24, 96), tone="deep", bevel=0.15, seed=4)
rock((4, 8, 60), (40, 10, 100), tone="deep", bevel=0.15, seed=2)          # wet wall behind the falls

# Crown (top, behind the upper fall) and top boulder
rock((-6, 10, 112), (22, 22, 14), rot=0.1, seed=10)
rock((12, 12, 114), (22, 22, 12), rot=-0.05, seed=11)
rock((30, 8, 116), (18, 20, 16), rot=0.2, seed=12)
rock((23, 4, 123), (15, 13, 11), rot=0.35, bevel=0.4, seed=13)           # boulder on the very top
rock((16, -2, 96), (4, 8, 34), tone="dark", bevel=0.4, seed=14)          # dark strip between the two upper streams

# Left cliff: stacked columns, top slopes from z 62 (outer) to z 100 (inner)
for i, (x, y, z, w, d, h, r, tone) in enumerate([
        (-22, -6, 88, 16, 18, 22, 0.1, "warm"), (-24, -8, 66, 18, 18, 22, -0.05, "warm"),
        (-26, -10, 44, 20, 18, 24, 0.05, "warm"), (-28, -8, 20, 22, 20, 26, -0.1, "warm"),
        (-38, -4, 80, 14, 16, 18, 0.2, "dark"), (-40, -6, 58, 16, 18, 24, -0.1, "warm"),
        (-42, -6, 34, 18, 20, 22, 0.1, "warm"), (-44, -4, 12, 18, 20, 22, 0.0, "dark"),
        (-12, -12, 50, 10, 12, 22, 0.0, "dark"), (-14, -10, 28, 8, 12, 26, 0.0, "dark")]):
    rock((x, y, z), (w, d, h), rot=r, tone=tone, seed=20 + i)

# Mid ledge (upper fall lands on it; left fall comes out under it)
rock((-12, -16, 70), (20, 16, 12), rot=0.08, seed=40)
rock((-14, -14, 60), (14, 14, 10), rot=-0.1, tone="dark", seed=41)
rock((2, -6, 72), (34, 14, 8), rot=0.0, seed=42)                           # shelf the upper fall hits

# Right cliff: tall tiers, top slopes from z 122 (inner) to z 96 (outer)
for i, (x, y, z, w, d, h, r, tone) in enumerate([
        (36, -4, 104, 18, 20, 20, 0.05, "warm"), (52, 0, 100, 18, 18, 18, -0.15, "warm"),
        (60, 2, 84, 14, 16, 22, 0.1, "dark"),
        (32, -8, 82, 16, 18, 22, -0.1, "warm"), (46, -6, 74, 18, 18, 22, 0.1, "warm"),
        (26, -12, 58, 14, 18, 22, 0.0, "dark"), (42, -10, 52, 18, 18, 24, -0.05, "warm"),
        (58, -4, 58, 14, 16, 24, 0.15, "warm"), (30, -12, 34, 18, 20, 24, 0.05, "warm"),
        (48, -10, 30, 18, 18, 24, -0.1, "warm"), (62, -4, 32, 12, 14, 22, 0.0, "dark"),
        (24, -12, 12, 16, 18, 24, 0.0, "dark"), (40, -12, 10, 18, 20, 20, 0.1, "warm"),
        (19, -10, 40, 6, 12, 60, 0.0, "deep")]):
    rock((x, y, z), (w, d, h), rot=r, tone=tone, seed=50 + i)

# Base: big round boulders left, flat stones right, a few rim stones only at the sides
for i, (x, y, z, w, d, h, r) in enumerate([
        (-62, -26, 9, 30, 24, 20, 0.35), (-44, -32, 5, 20, 18, 12, -0.2), (-72, -12, 20, 22, 20, 22, 0.1),
        (-54, -14, 24, 18, 16, 14, 0.6), (-30, -28, 2, 12, 10, 7, 0.3), (-76, -32, 3, 14, 12, 8, -0.4)]):
    rock((x, y, z), (w, d, h), rot=r, bevel=0.42, jitter=0.1, seed=80 + i)
for i, (x, y, z, w, d, h, r) in enumerate([
        (30, -28, 2, 18, 14, 6, 0.1), (46, -30, 3, 20, 16, 6, -0.2), (62, -24, 4, 18, 16, 8, 0.3),
        (54, -38, 1, 12, 10, 4, 0.5), (38, -40, 0.5, 10, 8, 3, -0.3), (70, -36, 1.5, 10, 9, 4, 0.2),
        (24, -38, 0.5, 7, 6, 2.5, 0.8)]):
    rock((x, y, z), (w, d, h), rot=r, bevel=0.38, jitter=0.08, seed=90 + i)
for i, (x, y) in enumerate([(-40, -44), (-50, -40), (-60, -42), (-30, -42), (78, -30), (66, -44)]):
    rock((x, y, 0.4), (random.uniform(3.5, 5.5), random.uniform(3, 4.5), 2.4), rot=random.uniform(0, 3), bevel=0.45, seed=100 + i)

# ------------------------------------------------------------------ water sheets
WATER_BANDS = [("Water_Dark", 0.07), ("Water_Mid", 0.07), ("Water_Light", 0.14), ("Water_White", 0.12),
               ("Water_Light", 0.12), ("Water_White", 0.1), ("Water_Light", 0.12), ("Water_Mid", 0.08),
               ("Water_White", 0.06), ("Water_Mid", 0.06), ("Water_Dark", 0.06)]
def fall_sheet(cx, w_top, w_bot, path, bands=WATER_BANDS, shift_bot=0.0):
    """path = [(y, z), ...] from the top (behind the lip) to the bottom. Faces point -Y."""
    n = len(path)
    tot = sum(b[1] for b in bands)
    for i in range(n - 1):
        for j in (i, i + 1):
            pass
        t0, t1 = i / (n - 1), (i + 1) / (n - 1)
        w0, w1 = w_top + (w_bot - w_top) * t0, w_top + (w_bot - w_top) * t1
        c0, c1 = cx + shift_bot * t0, cx + shift_bot * t1
        acc = 0.0
        for mat, frac in bands:
            a, b = acc / tot, (acc + frac) / tot
            acc += frac
            p = [(c0 - w0 / 2 + w0 * a, path[i][0], path[i][1]), (c0 - w0 / 2 + w0 * b, path[i][0], path[i][1]),
                 (c1 - w1 / 2 + w1 * b, path[i + 1][0], path[i + 1][1]), (c1 - w1 / 2 + w1 * a, path[i + 1][0], path[i + 1][1])]
            face(mat, list(reversed(p)))   # wind so the face points -Y (front); Roblox culls back faces

def arc_path(y0, ztop, ylip, zlip, ybot, zbot, steps=10):
    pts = [(y0, ztop - 0.5), ((y0 + ylip) / 2, ztop + 0.8), (ylip, zlip)]
    for k in range(1, steps + 1):
        t = k / steps
        pts.append((ylip + (ybot - ylip) * (t ** 0.6), zlip + (zbot - zlip) * t))
    return pts

# Upper fall: two streams over the top lip, landing on the shelf at z 76
fall_sheet(4.5, 21, 22, arc_path(6, 110, -1.5, 108, -4, 76.5))
fall_sheet(23, 11, 12, arc_path(6, 111, -1.5, 109, -4, 76.5),
           bands=[("Water_Dark", 0.1), ("Water_Light", 0.25), ("Water_White", 0.25), ("Water_Light", 0.25), ("Water_Dark", 0.15)])
# Lower main fall: from the shelf down to the pool, fanning out
fall_sheet(1.5, 30, 40, arc_path(-6, 76.5, -14, 75, -21, 0.5, steps=14), shift_bot=-1.5)
# Lower left fall (comes out under the mid ledge)
fall_sheet(-24, 13, 19, arc_path(-12, 60, -18, 59, -24, 0.5, steps=10), shift_bot=-2,
           bands=[("Water_Dark", 0.08), ("Water_Light", 0.25), ("Water_White", 0.3), ("Water_Light", 0.22), ("Water_Mid", 0.15)])

def blob(mat, c, s, seed=0):
    rnd = random.Random(seed)
    t = bmesh.new()
    bmesh.ops.create_icosphere(t, subdivisions=1, radius=1.0)
    for v in t.verts:
        v.co = Vector((v.co.x * s[0], v.co.y * s[1], v.co.z * s[2])) * rnd.uniform(0.9, 1.1)
        v.co += Vector(c)
    for f in t.faces:
        face(mat, [v.co.copy() for v in f.verts])
    t.free()

# White foam where the water lands
for i in range(16):
    x = random.uniform(-20, 22)
    blob("Water_White", (x, random.uniform(-26, -19), random.uniform(0, 2.5)), (random.uniform(3, 5.5), random.uniform(2.5, 4), random.uniform(1.5, 2.8)), seed=200 + i)
for i in range(7):
    blob("Water_White", (random.uniform(-34, -16), random.uniform(-28, -22), random.uniform(0, 2)), (random.uniform(2.5, 4), 2.5, 1.6), seed=230 + i)
for i in range(8):
    blob("Water_White", (random.uniform(-6, 30), random.uniform(-9, -6), 76.5 + random.uniform(0, 1.5)), (random.uniform(2.5, 4), 2.5, 1.5), seed=250 + i)

# ------------------------------------------------------------------ plants
def leaf(base, direction, length, width, mats=("Leaf_Light", "Leaf_Mid"), droop=0.4, segs=8, jag=0.0, roll=0.25):
    d = Vector(direction).normalized()
    side = d.cross(Vector((0, 0, 1)))
    if side.length < 1e-3:
        side = Vector((1, 0, 0))
    side.normalize()
    up = side.cross(d).normalized()
    rows = []
    for i in range(segs + 1):
        t = i / segs
        w = width * (math.sin(math.pi * min(t * 1.05, 1.0)) ** 0.6)
        if jag and i % 2 == 1:
            w *= (1 - jag)
        p = Vector(base) + d * length * t - Vector((0, 0, 1)) * droop * length * t * t
        rows.append((p, p - side * w + up * roll * w, p + side * w + up * roll * w))
    for i in range(segs):
        (c0, l0, r0), (c1, l1, r1) = rows[i], rows[i + 1]
        for mat, quad in ((mats[0], [c0, l0, l1, c1]), (mats[1], [c0, c1, r1, r0])):
            face(mat, quad)
            face(mat, list(reversed(quad)))        # double-sided

def palm(base, top, crown, n=9, seed=0, lean=0.0):
    rnd = random.Random(seed)
    base, top = Vector(base), Vector(top)
    segs, sides = 12, 7
    bend = Vector((lean, 0, 0))
    pts = [base.lerp(top, i / segs) + bend * math.sin(math.pi * i / segs) for i in range(segs + 1)]
    for i in range(segs):
        r0 = crown * 0.075 * (1.0 - 0.35 * i / segs)
        r1 = crown * 0.075 * (1.0 - 0.35 * (i + 1) / segs)
        mat = "Trunk" if i % 2 == 0 else "Trunk_Dark"
        for k in range(sides):
            a0, a1 = 2 * math.pi * k / sides, 2 * math.pi * (k + 1) / sides
            q = [pts[i] + Vector((math.cos(a0) * r0 * 1.1, math.sin(a0) * r0 * 1.1, 0)),
                 pts[i] + Vector((math.cos(a1) * r0 * 1.1, math.sin(a1) * r0 * 1.1, 0)),
                 pts[i + 1] + Vector((math.cos(a1) * r1, math.sin(a1) * r1, 0)),
                 pts[i + 1] + Vector((math.cos(a0) * r1, math.sin(a0) * r1, 0))]
            face(mat, q)
    for i in range(n):
        a = 2 * math.pi * i / n + rnd.uniform(-0.15, 0.15)
        rise = rnd.uniform(0.35, 1.0)
        leaf(top, (math.cos(a), math.sin(a) * 0.8, rise), crown * rnd.uniform(0.85, 1.1), crown * 0.25,
             mats=("Leaf_Light", "Leaf_Mid") if i % 2 else ("Leaf_Mid", "Leaf_Dark"), droop=0.75, segs=12, jag=0.35)
    for i in range(3):
        a = 2 * math.pi * i / 3
        blob("Trunk_Dark", top + Vector((math.cos(a) * 1.3, math.sin(a) * 1.3 - 0.5, -1.4)), (1.1, 1.1, 1.2), seed=seed + i)

def bush(c, r, tone="green", n=26, seed=0):
    rnd = random.Random(seed)
    c = Vector(c)
    r *= 1.3
    pal = {"green": [("Leaf_Light", "Leaf_Mid"), ("Leaf_Mid", "Leaf_Dark")],
           "dark": [("Leaf_Mid", "Leaf_Dark"), ("Leaf_Dark", "Leaf_Deep")],
           "teal": [("Teal_Light", "Teal_Dark")]}[tone]
    blob(pal[-1][1], c - Vector((0, -r * 0.05, r * 0.3)), (r * 0.35, r * 0.3, r * 0.25), seed=seed + 500)
    for i in range(n):
        a = rnd.uniform(0, 2 * math.pi)
        e = rnd.uniform(-0.15, 1.1)
        d = Vector((math.cos(a) * math.cos(e), math.sin(a) * math.cos(e) * 0.7 - 0.35, math.sin(e)))
        leaf(c, d, r * rnd.uniform(0.75, 1.15), r * (0.14 if tone == "teal" else 0.3), mats=pal[i % len(pal)],
             droop=0.35, segs=6, jag=0.3 if tone != "teal" else 0.0)

def big_leaves(base, size, n=6, seed=0):
    rnd = random.Random(seed)
    for i in range(n):
        a = math.pi * (0.1 + 0.8 * i / max(1, n - 1)) + rnd.uniform(-0.2, 0.2)
        d = (math.cos(a), -math.sin(a) * 0.8 - 0.2, rnd.uniform(0.3, 1.1))
        leaf(base, d, size * rnd.uniform(0.8, 1.1), size * 0.3, mats=("Leaf_Light", "Leaf_Mid") if i % 2 else ("Leaf_Mid", "Leaf_Dark"),
             droop=0.35, segs=8, jag=0.0, roll=0.15)

def fern(base, size, n=10, seed=0, mats=("Leaf_Light", "Leaf_Mid")):
    rnd = random.Random(seed)
    for i in range(n):
        a = 2 * math.pi * i / n + rnd.uniform(-0.3, 0.3)
        leaf(base, (math.cos(a), math.sin(a) * 0.7 - 0.2, rnd.uniform(0.5, 1.3)), size * rnd.uniform(0.8, 1.1), size * 0.19,
             mats=mats if i % 2 else ("Leaf_Mid", "Leaf_Dark"), droop=0.5, segs=8, jag=0.5)

def vine(top, length, seed=0, mats=("Leaf_Mid", "Leaf_Dark")):
    rnd = random.Random(seed)
    top = Vector(top)
    for i in range(int(length / 2.0)):
        p = top - Vector((rnd.uniform(-0.5, 0.5), 0.5, i * 2.0))
        for s in (-1, 1):
            leaf(p, (s, -0.6, -0.2), 1.9, 0.8, mats=mats, droop=0.2, segs=3, roll=0.1)

def flower(c, r=1.6):
    c = Vector(c)
    for k in range(5):
        a = 2 * math.pi * k / 5
        leaf(c, (math.cos(a), -0.6, math.sin(a) * 0.7 + 0.2), r, r * 0.5, mats=("Flower", "Flower"), droop=0.0, segs=3, roll=0.1)
    blob("Leaf_Light", c + Vector((0, -0.6, 0)), (0.4, 0.4, 0.4))

# palms (from the picture)
palm((-44, -18, 29), (-39, -24, 101), 22, n=10, seed=1, lean=3)          # tall left
palm((-50, -24, 24), (-58, -28, 62), 16, n=9, seed=2, lean=-2)           # short left
palm((38, -26, 8), (42, -30, 38), 19, n=10, seed=3, lean=2)              # big right
palm((56, -20, 14), (57, -22, 50), 12, n=8, seed=4)                      # small right

# crown greenery
for i, (x, y, z, r, tone) in enumerate([(-18, -2, 120, 12, "green"), (-4, 4, 121, 11, "green"), (8, 6, 122, 10, "dark"),
                                        (34, 6, 126, 10, "green"), (46, 2, 116, 12, "green"), (58, -2, 106, 10, "dark"),
                                        (-12, 0, 112, 10, "dark")]):
    bush((x, y, z), r, tone, seed=300 + i)
for i, (x, y, z, s) in enumerate([(-24, -4, 124, 12), (2, 2, 126, 11), (18, 6, 130, 10), (40, 4, 128, 11), (60, -2, 114, 10)]):
    fern((x, y, z), s, seed=320 + i)
bush((52, -6, 114), 10, "teal", seed=340)              # teal plant top right
bush((-20, -10, 94), 10, "teal", seed=341)             # teal plant left of the upper fall
bush((-16, -8, 104), 11, "dark", seed=342)             # dark green column left of the upper fall
bush((-22, -12, 82), 10, "dark", seed=343)
bush((-30, -14, 66), 9, "green", seed=344)
# right side lush clumps
bush((36, -12, 94), 14, "green", seed=350)
bush((48, -10, 84), 12, "green", seed=351)
bush((28, -14, 74), 9, "dark", seed=352)
big_leaves((24, -18, 54), 18, n=7, seed=353)           # big tropical leaves mid right
bush((-10, -20, 78), 5, "green", seed=354)             # small plant on the mid ledge
# base
bush((-46, -26, 26), 10, "green", seed=360)
bush((-36, -30, 13), 8, "dark", seed=361)
bush((-24, -32, 6), 5, "green", seed=362)
fern((-58, -22, 32), 10, seed=363)
fern((34, -34, 6), 10, seed=364)
bush((58, -30, 9), 8, "green", seed=365)
big_leaves((30, -32, 4), 9, n=5, seed=366)
for p in [(30, -36, 12), (35, -37, 10), (40, -35, 13), (27, -36, 8)]:
    flower(p)
vine((-14, -10, 100), 22, seed=370)
vine((-26, -12, 78), 16, seed=371)
vine((54, -8, 110), 20, seed=372, mats=("Teal_Light", "Teal_Dark"))
vine((44, -12, 92), 22, seed=373)
vine((28, -14, 70), 14, seed=374)

# ------------------------------------------------------------------ build + export
objs = []
for mat, bm in BM.items():
    me = bpy.data.meshes.new(mat)
    bm.to_mesh(me)
    bm.free()
    me.materials.append(MATS[mat])
    ob = bpy.data.objects.new(mat, me)
    bpy.context.scene.collection.objects.link(ob)
    objs.append(ob)
tri = {}
for ob in objs:
    ob.data.calc_loop_triangles()
    tri[ob.name] = len(ob.data.loop_triangles)
print("TRIS", tri, "TOTAL", sum(tri.values()), "MAX", max(tri.values()))
allv = [v.co for ob in objs for v in ob.data.vertices]
print("BOUNDS", [round(min(v[i] for v in allv), 2) for i in range(3)], [round(max(v[i] for v in allv), 2) for i in range(3)])
fl = [v.co for v in bpy.data.objects["Flower"].data.vertices]
print("FLOWER_CENTER", [round((min(v[i] for v in fl) + max(v[i] for v in fl)) / 2, 2) for i in range(3)])

bpy.ops.object.select_all(action='DESELECT')
for ob in objs:
    ob.select_set(True)
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "JungleWaterfall.glb"), export_format='GLB',
                          use_selection=True, export_apply=True, export_yup=True)

# ------------------------------------------------------------------ preview (pool plane is render-only)
me = bpy.data.meshes.new("Pool")
me.from_pydata([(-85, -70, 0.1), (85, -70, 0.1), (85, 0, 0.1), (-85, 0, 0.1)], [], [(0, 1, 2, 3)])
pm = bpy.data.materials.new("PoolMat")
pm.diffuse_color = (lin(70), lin(190), lin(220), 1)
me.materials.append(pm)
bpy.context.scene.collection.objects.link(bpy.data.objects.new("Pool", me))
scn = bpy.context.scene
scn.render.engine = 'BLENDER_WORKBENCH'
scn.display.shading.light = 'STUDIO'
scn.display.shading.color_type = 'MATERIAL'
scn.display.shading.show_cavity = False
scn.display.shading.show_shadows = False
scn.render.resolution_x, scn.render.resolution_y = 900, 900
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
cam.data.lens = 50
scn.collection.objects.link(cam)
scn.camera = cam
for tag, loc in [("front", (-60, -300, 75)), ("ground", (0, -220, 25))]:
    cam.location = loc
    cam.rotation_euler = (Vector((0, 0, 60)) - Vector(loc)).to_track_quat('-Z', 'Y').to_euler()
    scn.render.filepath = os.path.join(OUT, f"preview_{tag}.png")
    bpy.ops.render.render(write_still=True)
print("DONE")
