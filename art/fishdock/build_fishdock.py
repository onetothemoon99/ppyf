# Fishing shop + dock kit (cartoon, from the user's picture of a blue-roof fish shop on a wooden pier). Run:
#   blender.exe -b --factory-startup -P build_fishdock.py -- <outdir>
# Units: 1 Blender unit = 1 stud. Z up. Front of every piece faces -Y (Roblox importer: local = (-bx, bz, by),
# so Blender -Y becomes the model's LookVector). Each piece is built around (0,0,0):
#   most pieces: bottom centre at z = 0;  deck / rail / pile pieces: deck top at z = 0.
# Every mesh object is named "<Piece>__<Material>"; Studio groups them back into one Model per piece
# and colours them from COLORS (the importer drops colours to grey).
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
    "Wall_Light": (196, 220, 232), "Wall_Mid": (168, 198, 218), "Trim": (250, 248, 240),
    "Roof_Blue": (62, 118, 204), "Roof_Dark": (42, 86, 166),
    "Stone_Top": (186, 192, 200), "Stone_Side": (146, 154, 166), "Stone_Shadow": (104, 112, 128),
    "Wood_Light": (206, 156, 104), "Wood_Mid": (176, 124, 78), "Wood_Dark": (118, 80, 52),
    "Rope": (220, 196, 146), "Awning_Blue": (58, 132, 218), "Awning_White": (252, 252, 252),
    "Glass": (160, 212, 238), "Door": (126, 88, 58), "Metal_Black": (44, 46, 54), "Lamp_Glow": (255, 222, 140),
    "Leaf_Light": (126, 200, 74), "Leaf_Dark": (62, 144, 62),
    "Flower_Red": (234, 76, 76), "Flower_Yellow": (250, 212, 72), "Flower_Pink": (242, 146, 196),
    "Boat_White": (246, 246, 242), "Boat_Blue": (56, 118, 204), "Buoy_Red": (228, 66, 58),
    "Fish_Orange": (246, 150, 62), "Sign_Cream": (250, 238, 204), "Net": (92, 112, 124),
}
MATS = {}
for name, rgb in COLORS.items():
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    col = tuple(lin(v) for v in rgb) + (1.0,)
    bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = col
    m.diffuse_color = col
    MATS[name] = m

# ------------------------------------------------------------------ geometry helpers
PIECE = {"name": None}
PBM = {}
def emit(mat, t, M=Matrix()):
    """Copy every face of temp bmesh t (transformed by M) into the current piece's <mat> mesh."""
    key = PIECE["name"] + "__" + mat
    bm = PBM.setdefault(key, bmesh.new())
    for f in t.faces:
        vs = [bm.verts.new(M @ v.co) for v in f.verts]
        try:
            bm.faces.new(vs)
        except ValueError:
            pass
    t.free()

def face(mat, pts):
    key = PIECE["name"] + "__" + mat
    bm = PBM.setdefault(key, bmesh.new())
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
    """Cylinder/cone whose axis is local Z, centred at c."""
    t = bmesh.new()
    bmesh.ops.create_cone(t, cap_ends=True, cap_tris=False, segments=n, radius1=r, radius2=r if r2 is None else r2, depth=h)
    emit(mat, t, place(c, rz, rx, ry))

def ball(mat, c, s, sub=1):
    t = bmesh.new()
    bmesh.ops.create_icosphere(t, subdivisions=sub, radius=1.0)
    for v in t.verts:
        v.co = Vector((v.co.x * s[0], v.co.y * s[1], v.co.z * s[2]))
    emit(mat, t, Matrix.Translation(Vector(c)))

def torus(mats, c, R, r, n=16, m=6, rx=math.pi / 2, rz=0.0, split=4):
    """Torus in local XY (rotated by rx so it stands up), colour bands alternate every n/split segments."""
    M = place(c, rz, rx)
    for i in range(n):
        a0, a1 = 2 * math.pi * i / n, 2 * math.pi * (i + 1) / n
        mat = mats[(i * split // n) % len(mats)]
        for j in range(m):
            b0, b1 = 2 * math.pi * j / m, 2 * math.pi * (j + 1) / m
            def p(a, b):
                return M @ Vector(((R + r * math.cos(b)) * math.cos(a), (R + r * math.cos(b)) * math.sin(a), r * math.sin(b)))
            face(mat, [p(a0, b0), p(a1, b0), p(a1, b1), p(a0, b1)])

def rod(mat, a, b, r, n=6):
    """Cylinder from point a to point b."""
    a, b = Vector(a), Vector(b)
    d = b - a
    q = Vector((0, 0, 1)).rotation_difference(d.normalized())
    t = bmesh.new()
    bmesh.ops.create_cone(t, cap_ends=True, cap_tris=False, segments=n, radius1=r, radius2=r, depth=d.length)
    emit(mat, t, Matrix.Translation((a + b) / 2) @ q.to_matrix().to_4x4())

def rope(a, b, sag, r=0.12, segs=6, mat="Rope"):
    a, b = Vector(a), Vector(b)
    pts = [a.lerp(b, i / segs) - Vector((0, 0, sag * math.sin(math.pi * i / segs))) for i in range(segs + 1)]
    for i in range(segs):
        rod(mat, pts[i], pts[i + 1], r, n=5)

LIGHT = Vector((-0.45, -0.55, 0.75)).normalized()
STONE = ("Stone_Top", "Stone_Side", "Stone_Shadow")
def rock(c, s, rot=0.0, bevel=0.35, jitter=0.08, seed=0, seg=2):
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

def leafball(c, r, seed=0, flowers=()):
    rnd = random.Random(seed)
    c = Vector(c)
    ball("Leaf_Dark", c, (r, r, r * 0.8))
    for i in range(5):
        a = 2 * math.pi * i / 5 + rnd.uniform(-0.3, 0.3)
        p = c + Vector((math.cos(a) * r * 0.55, math.sin(a) * r * 0.55, r * rnd.uniform(0.1, 0.45)))
        ball("Leaf_Light", p, (r * 0.55, r * 0.55, r * 0.45))
    for i, fm in enumerate(flowers):
        a = 2 * math.pi * i / max(1, len(flowers)) + 0.4
        ball(fm, c + Vector((math.cos(a) * r * 0.7, math.sin(a) * r * 0.7 - 0.2, r * 0.6)), (0.32, 0.32, 0.28), sub=1)

PIECES = []
def add(name, fn):
    PIECE["name"] = name
    fn()
    PIECES.append(name)

# ================================================================== shop house
W, D = 22.0, 15.0          # footprint x / y
BASE, EAVE, RIDGE = 2.4, 13.5, 22.0
def shop():
    hw, hd = W / 2, D / 2
    # stone plinth + stones on the front and sides
    box("Stone_Side", (0, 0, BASE / 2), (W + 1.2, D + 1.2, BASE))
    box("Stone_Top", (0, 0, BASE + 0.15), (W + 1.6, D + 1.6, 0.3))
    rnd = random.Random(5)
    x = -hw - 0.2
    while x < hw:
        w = rnd.uniform(1.6, 2.6)
        rock((x + w / 2, -hd - 0.65, 1.0 + rnd.uniform(-0.2, 0.2)), (w, 0.9, rnd.uniform(1.2, 1.8)), seed=rnd.randint(0, 999), seg=1)
        x += w + 0.1
    for sx in (-1, 1):
        y = -hd
        while y < hd:
            w = rnd.uniform(1.6, 2.6)
            rock((sx * (hw + 0.65), y + w / 2, 1.0), (0.9, w, rnd.uniform(1.2, 1.7)), seed=rnd.randint(0, 999), seg=1)
            y += w + 0.1
    # plank walls (horizontal boards, two tones)
    z, i = BASE, 0
    while z < EAVE - 0.01:
        h = min(1.25, EAVE - z)
        mat = "Wall_Light" if i % 2 == 0 else "Wall_Mid"
        box(mat, (0, -hd + 0.25, z + h / 2), (W, 0.5, h))
        box(mat, (0, hd - 0.25, z + h / 2), (W, 0.5, h))
        box(mat, (-hw + 0.25, 0, z + h / 2), (0.5, D, h))
        box(mat, (hw - 0.25, 0, z + h / 2), (0.5, D, h))
        z += h
        i += 1
    for sx in (-1, 1):
        for sy in (-1, 1):
            box("Trim", (sx * (hw - 0.1), sy * (hd - 0.1), (BASE + EAVE) / 2), (0.9, 0.9, EAVE - BASE))
    box("Trim", (0, -hd - 0.05, EAVE - 0.3), (W + 0.4, 0.7, 0.6))
    box("Trim", (0, hd + 0.05, EAVE - 0.3), (W + 0.4, 0.7, 0.6))
    # gables (front / back triangles)
    for sy in (-1, 1):
        A, B, C = Vector((-hw, sy * hd, EAVE)), Vector((hw, sy * hd, EAVE)), Vector((0, sy * hd, RIDGE))
        if sy < 0:
            face("Wall_Light", [A, B, C])
        else:
            face("Wall_Light", [B, A, C])
    # roof: tile strips on two slopes (left / right), ridge runs front-to-back so the gable faces the front
    over = 1.8
    run = hw + over
    rise = RIDGE - EAVE
    L = math.hypot(run, rise + 0.6)
    ang = math.atan2(rise + 0.6, run)
    rows = 8
    for sx in (-1, 1):
        for r in range(rows):
            t0 = r / rows
            # strip centre along the slope from the eave (t=0) to the ridge (t=1)
            cx = sx * (run * (1 - t0 - 0.5 / rows))
            cz = EAVE - 0.6 + (rise + 0.6) * (t0 + 0.5 / rows) + 0.35
            mat = "Roof_Blue" if r % 2 == 0 else "Roof_Dark"
            box(mat, (cx, 0, cz), (L / rows * 1.25, D + 3.0, 0.7), ry=sx * ang)
    box("Roof_Dark", (0, 0, RIDGE + 0.5), (1.4, D + 3.4, 1.0))
    # gable edge boards (white) along both roof edges, front and back
    for sy in (-1, 1):
        for sx in (-1, 1):
            box("Trim", (sx * run / 2, sy * (hd + 1.55), EAVE + (rise + 0.6) / 2 + 0.2), (L + 0.4, 0.4, 0.7), ry=sx * ang)
    # chimney (stone) on the back slope
    box("Stone_Side", (6.5, 3.2, RIDGE - 1.5), (2.4, 2.4, 6.0))
    box("Stone_Top", (6.5, 3.2, RIDGE + 1.6), (3.0, 3.0, 0.5))
    # door (right of the front) with frame, glass, step, lamp
    dx = 6.0
    box("Trim", (dx, -hd - 0.15, BASE + 4.1), (4.8, 0.4, 8.2))
    box("Door", (dx, -hd - 0.3, BASE + 3.8), (3.8, 0.4, 7.6))
    box("Glass", (dx, -hd - 0.55, BASE + 5.8), (2.2, 0.2, 2.2))
    box("Trim", (dx, -hd - 0.6, BASE + 5.8), (0.25, 0.2, 2.2))
    ball("Metal_Black", (dx + 1.3, -hd - 0.65, BASE + 3.6), (0.25, 0.25, 0.25))
    box("Wood_Mid", (dx, -hd - 1.3, BASE - 0.3), (5.4, 2.2, 0.6))
    box("Metal_Black", (dx + 3.4, -hd - 0.6, BASE + 7.9), (0.2, 1.0, 0.2))
    cyl("Metal_Black", (dx + 3.4, -hd - 1.1, BASE + 7.2), 0.55, 0.3)
    box("Lamp_Glow", (dx + 3.4, -hd - 1.1, BASE + 6.3), (0.8, 0.8, 1.2))
    cyl("Metal_Black", (dx + 3.4, -hd - 1.1, BASE + 5.6), 0.5, 0.25)
    # hanging sign above the door (text added in Studio)
    box("Wood_Dark", (dx, -hd - 0.4, BASE + 9.4), (0.2, 0.8, 0.2))
    box("Wood_Mid", (dx, -hd - 0.6, BASE + 9.3), (5.2, 0.35, 1.6))
    box("Sign_Cream", (dx, -hd - 0.8, BASE + 9.3), (4.6, 0.1, 1.15))
    # big shop window with counter (left of the front)
    wx, ww = -4.0, 10.0
    box("Trim", (wx, -hd - 0.12, BASE + 5.6), (ww + 1.0, 0.35, 5.6))
    box("Glass", (wx, -hd - 0.3, BASE + 5.8), (ww, 0.3, 4.8))
    for k in (-1, 0, 1):
        box("Trim", (wx + k * ww / 3 + (ww / 6 if k else 0) * 0, -hd - 0.45, BASE + 5.8), (0.3, 0.2, 4.8))
    box("Trim", (wx, -hd - 0.45, BASE + 5.8), (ww, 0.2, 0.3))
    box("Wood_Mid", (wx, -hd - 1.0, BASE + 3.0), (ww + 1.6, 2.0, 0.5))      # counter
    box("Wood_Dark", (wx, -hd - 0.6, BASE + 1.4), (ww + 1.0, 1.2, 2.8))
    # striped awning over the window
    stripes = 11
    aw = ww + 2.0
    depth, z0, z1 = 4.2, BASE + 9.6, BASE + 8.0
    aang = math.atan2(z0 - z1, depth)
    alen = math.hypot(depth, z0 - z1)
    for s in range(stripes):
        sx = wx - aw / 2 + aw * (s + 0.5) / stripes
        mat = "Awning_Blue" if s % 2 == 0 else "Awning_White"
        box(mat, (sx, -hd - depth / 2, (z0 + z1) / 2), (aw / stripes + 0.02, alen, 0.25), rx=aang)
        # scallop on the front edge
        cyl(mat, (sx, -hd - depth - 0.05, z1 - 0.35), aw / stripes / 2, 0.2, n=8, rx=math.pi / 2)
    box("Awning_Blue", (wx, -hd - 0.25, z0 + 0.15), (aw, 0.5, 0.4))
    # side windows with shutters
    for sx in (-1, 1):
        cx = sx * (hw + 0.15)
        box("Trim", (cx, 0, BASE + 6.2), (0.35, 4.0, 4.0))
        box("Glass", (cx + sx * 0.12, 0, BASE + 6.2), (0.2, 3.2, 3.2))
        box("Trim", (cx + sx * 0.2, 0, BASE + 6.2), (0.2, 0.25, 3.2))
        for sh in (-1, 1):
            box("Awning_Blue", (cx + sx * 0.1, sh * 2.9, BASE + 6.2), (0.25, 1.6, 4.0))
        box("Wood_Mid", (cx + sx * 0.7, 0, BASE + 3.8), (1.2, 4.6, 0.9))
        for k in range(4):
            ball(("Flower_Red", "Flower_Yellow", "Flower_Pink", "Flower_Red")[k], (cx + sx * 0.8, -1.7 + k * 1.15, BASE + 4.6), (0.45, 0.45, 0.4))
    # round fish badge on the front gable
    gy = -hd - 0.35
    cyl("Awning_Blue", (0, gy, EAVE + 3.6), 3.0, 0.4, n=20, rx=math.pi / 2)
    cyl("Sign_Cream", (0, gy - 0.25, EAVE + 3.6), 2.5, 0.3, n=20, rx=math.pi / 2)
    ball("Awning_Blue", (-0.3, gy - 0.45, EAVE + 3.6), (1.4, 0.25, 0.8))
    face("Awning_Blue", [(1.0, gy - 0.5, EAVE + 3.6), (2.0, gy - 0.5, EAVE + 2.8), (2.0, gy - 0.5, EAVE + 4.4)])
    face("Awning_Blue", [(1.0, gy - 0.5, EAVE + 3.6), (2.0, gy - 0.5, EAVE + 4.4), (2.0, gy - 0.5, EAVE + 2.8)])
    ball("Trim", (-1.1, gy - 0.6, EAVE + 3.8), (0.25, 0.1, 0.25))
add("Shop", shop)

# ================================================================== dock pieces (deck top at z = 0)
def deck_panel(length=8.0, width=8.0):
    def fn():
        n = 5
        pw = width / n
        for i in range(n):
            y = -width / 2 + pw * (i + 0.5)
            mat = "Wood_Light" if i % 2 == 0 else "Wood_Mid"
            box(mat, (0, y, -0.3), (length - 0.05, pw - 0.15, 0.6))
        for sx in (-1, 1):
            box("Wood_Dark", (sx * (length / 2 - 1.0), 0, -1.0), (0.8, width, 0.9))
    return fn
add("Deck8", deck_panel())
add("Deck8x4", deck_panel(8.0, 4.0))

def pile():
    cyl("Wood_Dark", (0, 0, -8.0), 0.7, 18.0, n=8)
    cyl("Wood_Mid", (0, 0, 1.15), 0.75, 0.3, n=8)
    cyl("Rope", (0, 0, 0.5), 0.78, 0.35, n=8)
add("Pile", pile)

def rail8():
    cyl("Wood_Dark", (0, 0, 1.8), 0.4, 3.6, n=8)
    cyl("Wood_Mid", (0, 0, 3.7), 0.48, 0.25, n=8)
    rope((0, 0, 3.2), (8, 0, 3.2), 0.9)
    rope((0, 0, 1.8), (8, 0, 1.8), 0.6)
add("Rail8", rail8)

def post():
    cyl("Wood_Dark", (0, 0, 1.8), 0.4, 3.6, n=8)
    cyl("Wood_Mid", (0, 0, 3.7), 0.48, 0.25, n=8)
add("RailPost", post)

def stairs():
    # 4 steps going down toward -Y, top step flush with the deck (z = 0)
    for k in range(4):
        box("Wood_Light" if k % 2 == 0 else "Wood_Mid", (0, -1.0 - k * 1.6, -0.3 - k * 0.9), (6.0, 1.7, 0.5))
    for sx in (-1, 1):
        box("Wood_Dark", (sx * 3.1, -3.4, -1.8), (0.5, 7.4, 0.8), rx=-0.5)
add("Stairs", stairs)

def bollard():
    cyl("Wood_Dark", (0, 0, 1.1), 0.75, 2.2, n=10)
    cyl("Wood_Mid", (0, 0, 2.3), 0.85, 0.3, n=10)
    torus(["Rope"], (0, 0, 1.3), 0.85, 0.22, n=12, m=5, rx=0.0)
    torus(["Rope"], (0, 0, 1.75), 0.82, 0.22, n=12, m=5, rx=0.0)
add("Bollard", bollard)

# ================================================================== seawall stones
add("StoneS", lambda: rock((0, 0, 1.6), (3.6, 3.2, 3.2), rot=0.3, seed=31))
add("StoneM", lambda: rock((0, 0, 2.3), (5.4, 4.4, 4.6), rot=-0.2, seed=32))
def stone_l():
    rock((0, 0, 2.8), (7.0, 5.4, 5.6), rot=0.1, seed=33)
    rock((3.6, -1.4, 1.6), (3.4, 3.0, 3.2), rot=0.6, seed=34)
add("StoneL", stone_l)
def stone_row():
    rnd = random.Random(35)
    x = -8.0
    while x < 8.0:
        w = rnd.uniform(3.0, 4.4)
        rock((x + w / 2, rnd.uniform(-0.4, 0.4), rnd.uniform(1.9, 2.4)), (w, rnd.uniform(3.4, 4.2), rnd.uniform(3.8, 4.8)),
             rot=rnd.uniform(-0.2, 0.2), seed=rnd.randint(0, 999))
        x += w - 0.2
add("StoneRow", stone_row)

# ================================================================== props
def barrel():
    cyl("Wood_Mid", (0, 0, 0.6), 1.15, 1.2, n=12, r2=1.35)
    cyl("Wood_Mid", (0, 0, 1.7), 1.35, 1.0, n=12)
    cyl("Wood_Mid", (0, 0, 2.8), 1.35, 1.2, n=12, r2=1.15)
    cyl("Wood_Light", (0, 0, 3.42), 1.05, 0.06, n=12)
    for z in (0.45, 1.7, 2.95):
        cyl("Metal_Black", (0, 0, z), 1.36 if z == 1.7 else 1.28, 0.22, n=12)
add("Barrel", barrel)

def crate_at(c, s=3.0, rz=0.0):
    M = place(c, rz)
    def b(mat, p, sz):
        t = bmesh.new()
        bmesh.ops.create_cube(t, size=1.0)
        for v in t.verts:
            v.co = Vector((v.co.x * sz[0], v.co.y * sz[1], v.co.z * sz[2]))
        emit(mat, t, M @ Matrix.Translation(Vector(p)))
    h = s / 2
    b("Wood_Light", (0, 0, h), (s - 0.1, s - 0.1, s - 0.1))
    e = 0.35
    for sx in (-1, 1):
        for sy in (-1, 1):
            b("Wood_Dark", (sx * (h - e / 2), sy * (h - e / 2), h), (e, e, s))
        for sz_ in (0, 1):
            b("Wood_Dark", (sx * (h - e / 2), 0, e / 2 + sz_ * (s - e)), (e, s, e))
            b("Wood_Dark", (0, sx * (h - e / 2), e / 2 + sz_ * (s - e)), (s, e, e))
    t = bmesh.new()
    bmesh.ops.create_cube(t, size=1.0)
    for v in t.verts:
        v.co = Vector((v.co.x * s * 1.3, v.co.y * 0.3, v.co.z * 0.35))
    emit("Wood_Mid", t, M @ Matrix.Translation(Vector((0, -h, h))) @ Matrix.Rotation(math.pi / 4, 4, 'Y'))
add("Crate", lambda: crate_at((0, 0, 0)))
def crate_stack():
    crate_at((-1.6, 0, 0), 3.0, 0.1)
    crate_at((1.6, 0.2, 0), 3.0, -0.08)
    crate_at((0, 0.1, 3.0), 2.6, 0.3)
add("CrateStack", crate_stack)

def fish_blob(c, d, mat, L=1.6):
    c, d = Vector(c), Vector(d).normalized()
    q = Vector((1, 0, 0)).rotation_difference(d)
    t = bmesh.new()
    bmesh.ops.create_icosphere(t, subdivisions=1, radius=1.0)
    for v in t.verts:
        v.co = Vector((v.co.x * L * 0.5, v.co.y * L * 0.18, v.co.z * L * 0.25))
    emit(mat, t, Matrix.Translation(c) @ q.to_matrix().to_4x4())
    tail = c - d * L * 0.55
    side = d.cross(Vector((0, 1, 0))) if abs(d.y) < 0.9 else Vector((0, 0, 1))
    side.normalize()
    p1, p2 = tail - d * L * 0.3 + side * L * 0.25, tail - d * L * 0.3 - side * L * 0.25
    face(mat, [tail, p1, p2])
    face(mat, [tail, p2, p1])

def basket():
    cyl("Wood_Light", (0, 0, 0.8), 1.3, 1.6, n=12, r2=1.7)
    for z in (0.3, 0.9, 1.5):
        cyl("Wood_Mid", (0, 0, z), 1.35 + z * 0.24, 0.15, n=12)
    for i, (mat, d) in enumerate((("Fish_Orange", (0.3, -0.4, 1)), ("Boat_Blue", (-0.5, 0.2, 1)), ("Fish_Orange", (0.6, 0.5, 0.8)), ("Stone_Side", (-0.2, -0.6, 0.9)))):
        fish_blob((d[0] * 0.8, d[1] * 0.8, 1.7), d, mat)
add("FishBasket", basket)

def rod_rack():
    for sx in (-1, 1):
        rod("Wood_Dark", (sx * 2.6, -0.8, 0), (sx * 2.6, 0, 4.6), 0.22)
        rod("Wood_Dark", (sx * 2.6, 0.8, 0), (sx * 2.6, 0, 4.6), 0.22)
    box("Wood_Mid", (0, 0, 4.4), (5.8, 0.5, 0.4))
    box("Wood_Mid", (0, -0.45, 1.0), (5.8, 0.3, 0.3))
    for k in range(4):
        x = -1.9 + k * 1.25
        rod("Wood_Light", (x, -0.9, 0.2), (x + 0.2, 0.5, 8.4), 0.12)
        cyl("Metal_Black", (x + 0.02, -0.75, 1.8), 0.32, 0.25, n=8, ry=math.pi / 2)
        rod("Rope", (x + 0.2, 0.5, 8.4), (x + 0.1, 0.0, 6.5), 0.03, n=4)
add("RodRack", rod_rack)

def lamppost():
    cyl("Metal_Black", (0, 0, 0.3), 0.9, 0.6, n=10)
    cyl("Metal_Black", (0, 0, 6.0), 0.25, 11.0, n=8)
    cyl("Metal_Black", (0, 0, 11.6), 0.6, 0.3, n=8)
    box("Lamp_Glow", (0, 0, 12.6), (1.2, 1.2, 1.6))
    for sx in (-1, 1):
        for sy in (-1, 1):
            box("Metal_Black", (sx * 0.62, sy * 0.62, 12.6), (0.15, 0.15, 1.7))
    cyl("Metal_Black", (0, 0, 13.7), 1.1, 0.7, n=4, r2=0.15, rz=math.pi / 4)
    ball("Metal_Black", (0, 0, 14.15), (0.2, 0.2, 0.2))
add("Lamppost", lamppost)

def flowerbox():
    box("Wood_Mid", (0, 0, 0.8), (6.0, 2.0, 1.6))
    box("Wood_Dark", (0, 0, 1.55), (6.3, 2.3, 0.25))
    box("Wood_Dark", (0, 0, 1.45), (5.6, 1.6, 0.1))
    rnd = random.Random(41)
    fl = ["Flower_Red", "Flower_Yellow", "Flower_Pink"]
    for i in range(6):
        x = -2.4 + i * 0.96
        ball("Leaf_Dark" if i % 2 else "Leaf_Light", (x, rnd.uniform(-0.3, 0.3), 2.0), (0.7, 0.6, 0.55))
        ball(fl[i % 3], (x + rnd.uniform(-0.2, 0.2), -0.3, 2.55), (0.38, 0.38, 0.3))
add("FlowerBox", flowerbox)

add("Bush", lambda: leafball((0, 0, 1.6), 2.0, seed=51, flowers=("Flower_Pink", "Flower_Yellow", "Flower_Red")))
add("BushSmall", lambda: leafball((0, 0, 1.0), 1.3, seed=52))

def rowboat():
    L, Wb, H = 14.0, 5.2, 2.2
    n = 14
    prof = [(-1.0, 1.0), (-0.92, 0.55), (-0.6, 0.15), (0.0, 0.0), (0.6, 0.15), (0.92, 0.55), (1.0, 1.0)]
    def sec(i, scale=1.0, lift=0.0):
        t = i / n
        y = -L / 2 + L * t
        w = Wb / 2 * (math.sin(math.pi * t) ** 0.55) * scale
        sheer = H + 0.6 * (abs(t - 0.5) * 2) ** 2
        return [Vector((px * w, y, lift + (pz * sheer) * (1 if scale == 1 else 0.98) + (0.15 if scale != 1 else 0))) for px, pz in prof]
    outer = [sec(i) for i in range(n + 1)]
    inner = [sec(i, 0.9, 0.12) for i in range(n + 1)]
    for i in range(n):
        for j in range(len(prof) - 1):
            mat = "Boat_Blue" if j in (0, len(prof) - 2) else "Boat_White"
            face(mat, [outer[i][j], outer[i + 1][j], outer[i + 1][j + 1], outer[i][j + 1]])
            face("Wood_Light", [inner[i][j + 1], inner[i + 1][j + 1], inner[i + 1][j], inner[i][j]])
        # gunwale strips joining outer and inner rims
        for j in (0, len(prof) - 1):
            a, b, c2, d = outer[i][j], outer[i + 1][j], inner[i + 1][j], inner[i][j]
            face("Wood_Mid", [a, d, c2, b] if j == 0 else [a, b, c2, d])
    for y in (-2.6, 0.6, 3.6):
        box("Wood_Mid", (0, y, 1.5), (Wb * 0.85 * math.sin(math.pi * (y / L + 0.5)) ** 0.55, 1.0, 0.25))
    for sx in (-1, 1):
        rod("Wood_Light", (sx * 1.6, -3.0, 1.9), (sx * 0.9, 4.5, 1.6), 0.14)
        box("Wood_Light", (sx * 0.85, 5.0, 1.58), (0.18, 1.6, 0.5))
add("Rowboat", rowboat)

def buoy():
    t = bmesh.new()
    bmesh.ops.create_uvsphere(t, u_segments=12, v_segments=8, radius=1.0)
    top = bmesh.new(); bot = bmesh.new()
    for f in t.faces:
        cz = f.calc_center_median().z
        tgt = top if cz > 0 else bot
        vs = [tgt.verts.new(v.co.copy()) for v in f.verts]
        tgt.faces.new(vs)
    t.free()
    emit("Buoy_Red", top, Matrix.Translation((0, 0, 1.0)))
    emit("Awning_White", bot, Matrix.Translation((0, 0, 1.0)))
    cyl("Buoy_Red", (0, 0, 2.3), 0.18, 0.8, n=6)
    ball("Lamp_Glow", (0, 0, 2.8), (0.25, 0.25, 0.25))
add("Buoy", buoy)

def lifering_post():
    cyl("Wood_Dark", (0, 0, 2.5), 0.35, 5.0, n=8)
    torus(["Buoy_Red", "Awning_White"], (0, -0.55, 3.3), 1.25, 0.38, n=16, m=6, split=8)
add("LifeRingPost", lifering_post)

def netpile():
    rnd = random.Random(61)
    for i in range(5):
        ball("Net", (rnd.uniform(-1.2, 1.2), rnd.uniform(-0.8, 0.8), 0.45), (1.4, 1.1, 0.5))
    for i in range(4):
        a = i * 1.7
        ball("Buoy_Red" if i % 2 else "Flower_Yellow", (math.cos(a) * 1.5, math.sin(a) * 1.0, 0.75), (0.35, 0.35, 0.35))
add("NetPile", netpile)

def bench():
    box("Wood_Light", (0, 0, 1.6), (6.0, 1.8, 0.35))
    box("Wood_Mid", (0, 0.75, 2.7), (6.0, 0.3, 1.2), rx=-0.15)
    for sx in (-1, 1):
        box("Wood_Dark", (sx * 2.5, 0, 0.75), (0.4, 1.6, 1.5))
        box("Wood_Dark", (sx * 2.5, 0.8, 2.0), (0.35, 0.3, 2.4))
add("Bench", bench)

def fence8():
    for x in (0.0, 8.0):
        cyl("Wood_Dark", (x, 0, 1.8), 0.32, 3.6, n=7)
        ball("Wood_Dark", (x, 0, 3.65), (0.34, 0.34, 0.2))
    box("Wood_Mid", (4.0, 0, 2.9), (8.0, 0.25, 0.45), ry=0.03)
    box("Wood_Mid", (4.0, 0, 1.5), (8.0, 0.25, 0.45), ry=-0.03)
add("Fence8", fence8)

def sign_post():
    cyl("Wood_Dark", (0, 0, 3.5), 0.3, 7.0, n=7)
    box("Wood_Mid", (0, -0.35, 5.6), (6.4, 0.35, 2.2))
    box("Sign_Cream", (0, -0.55, 5.6), (5.8, 0.1, 1.7))
    fish_blob((2.4, -0.62, 6.5), (1, 0, 0), "Awning_Blue", L=1.2)
add("SignPost", sign_post)

# ================================================================== build objects (laid out on a grid)
GRID = 34.0
COLS = 6
objs, tri = [], {}
for key, bm in PBM.items():
    p = key.split("__")[0]
    i = PIECES.index(p)
    off = Vector(((i % COLS) * GRID, (i // COLS) * GRID, 0))
    for v in bm.verts:
        v.co += off
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces) if False else None
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
allv = [v.co for ob in objs for v in ob.data.vertices]
print("BBOX_MIN", tuple(round(min(c[k] for c in allv), 4) for k in range(3)))
print("BBOX_MAX", tuple(round(max(c[k] for c in allv), 4) for k in range(3)))
print("TRIS", tri, "TOTAL", sum(tri.values()))
for i, name in enumerate(PIECES):
    print("OFFSET", name, (i % COLS) * GRID, (i // COLS) * GRID)

bpy.ops.object.select_all(action='DESELECT')
for ob in objs:
    ob.select_set(True)
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "FishDockKit.glb"), export_format='GLB',
                          use_selection=True, export_apply=True, export_yup=True)

# ------------------------------------------------------------------ previews
scn = bpy.context.scene
scn.render.engine = 'BLENDER_WORKBENCH'
scn.display.shading.light = 'STUDIO'
scn.display.shading.color_type = 'MATERIAL'
scn.display.shading.show_backface_culling = True
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
cam.data.type = 'ORTHO'
scn.collection.objects.link(cam)
scn.camera = cam
def shot(path, loc, look, scale, rx=1100, ry=800):
    scn.render.resolution_x, scn.render.resolution_y = rx, ry
    cam.data.ortho_scale = scale
    cam.location = loc
    cam.rotation_euler = (Vector(look) - Vector(loc)).to_track_quat('-Z', 'Y').to_euler()
    scn.render.filepath = os.path.join(OUT, path)
    bpy.ops.render.render(write_still=True)
cx, cy = (COLS - 1) * GRID / 2, ((len(PIECES) - 1) // COLS) * GRID / 2
shot("preview_kit.png", (cx - 60, cy - 220, 160), (cx, cy, 0), 190)
shot("preview_shop.png", (-30, -60, 30), (0, 0, 9), 40, 900, 800)
