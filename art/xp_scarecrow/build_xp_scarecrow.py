# Cartoon "EXP scarecrow" (หุ่น EXP, coin tier) — red shirt + navy overalls, straw hat with a gold star,
# holds a blue sign with gold "EXP" letters. Same height class as QualityBoosterTemplate (~7.6 studs).
# Run headless:  blender.exe -b --factory-startup -P build_xp_scarecrow.py -- <outdir>
#   or inside a live Blender: exec(open(path).read())  (OUT defaults to this folder)
# Units: 1 Blender unit = 1 stud, Z up, origin = base of the pole at ground level (z = 0).
# FRONT = Blender +Y  (glTF export_yup maps +Y -> -Z = Roblox LookVector).
# Mesh objects are named "XpScarecrow__<Material>"; Studio colours them from COLORS (the importer drops colours).
import bpy, bmesh, math, sys, os
from mathutils import Vector, Matrix

try:
    HERE = os.path.dirname(os.path.abspath(__file__))
except NameError:
    HERE = r"E:\work\ppyf\art\xp_scarecrow"
OUT = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else HERE
os.makedirs(OUT, exist_ok=True)

for o in list(bpy.data.objects):
    bpy.data.objects.remove(o, do_unlink=True)
for m in list(bpy.data.meshes):
    bpy.data.meshes.remove(m)
for c in list(bpy.data.curves):
    bpy.data.curves.remove(c)

def lin(c):
    c = c / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

COLORS = {
    "Wood": (156, 104, 62), "WoodDark": (112, 72, 42),
    "Shirt": (222, 52, 52), "ShirtLight": (255, 130, 120),  # red shirt (user 2026-11-18)
    "Overall": (40, 72, 168),
    "Straw": (244, 204, 92), "StrawDark": (214, 166, 60),
    "Sack": (236, 214, 172), "Stitch": (66, 46, 36), "Cheek": (255, 150, 150),
    "HatBand": (60, 124, 232),
    "Gold": (255, 206, 48), "SignBlue": (34, 104, 222), "White": (250, 250, 250),
}
MATS = {}
for name, rgb in COLORS.items():
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    col = tuple(lin(v) for v in rgb) + (1.0,)
    next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED").inputs["Base Color"].default_value = col
    m.diffuse_color = col
    MATS[name] = m

BM = {}
def put(mat, src, matrix):
    """Copy bmesh `src` transformed by `matrix` into the bucket for `mat`."""
    dst = BM.setdefault(mat, bmesh.new())
    vmap = {}
    for v in src.verts:
        vmap[v] = dst.verts.new(matrix @ v.co)
    for f in src.faces:
        try:
            dst.faces.new([vmap[v] for v in f.verts])
        except ValueError:
            pass
    src.free()

def T(x=0, y=0, z=0):
    return Matrix.Translation((x, y, z))
def S(x, y, z):
    return Matrix.Diagonal((x, y, z, 1))
def Rx(d): return Matrix.Rotation(math.radians(d), 4, 'X')
def Ry(d): return Matrix.Rotation(math.radians(d), 4, 'Y')
def Rz(d): return Matrix.Rotation(math.radians(d), 4, 'Z')

def sphere(mat, m, seg=16, ring=10):
    b = bmesh.new(); bmesh.ops.create_uvsphere(b, u_segments=seg, v_segments=ring, radius=1.0); put(mat, b, m)
def ico(mat, m, sub=1):
    b = bmesh.new(); bmesh.ops.create_icosphere(b, subdivisions=sub, radius=1.0); put(mat, b, m)
def cyl(mat, m, r1=1.0, r2=1.0, seg=16):
    """Unit-height cone/cylinder along +Z from z=-0.5..0.5."""
    b = bmesh.new()
    bmesh.ops.create_cone(b, cap_ends=True, cap_tris=False, segments=seg, radius1=r1, radius2=r2, depth=1.0)
    put(mat, b, m)
def box(mat, m):
    b = bmesh.new(); bmesh.ops.create_cube(b, size=1.0); put(mat, b, m)
def rbox(mat, cx, cy, cz, sx, sy, sz, r):
    """Rounded box (width sx along X, thickness sy along Y, height sz along Z) via bevelled cube."""
    b = bmesh.new(); bmesh.ops.create_cube(b, size=1.0)
    bmesh.ops.scale(b, vec=(sx, sy, sz), verts=b.verts)
    bmesh.ops.bevel(b, geom=list(b.edges), offset=r, segments=2, affect='EDGES', profile=0.5)
    put(mat, b, T(cx, cy, cz))

# ------------------------------------------------------------------ pole + crossbar
cyl("Wood", T(0, 0, 2.75) @ S(0.22, 0.22, 5.5), seg=10)
cyl("WoodDark", T(0, 0, 0.12) @ S(0.42, 0.42, 0.24), r1=1.0, r2=0.7, seg=10)        # foot
cyl("Wood", T(-1.2, 0, 4.35) @ Ry(90) @ S(0.17, 0.17, 3.0), seg=10)                # crossbar (left half only; right arm is raised)

# ------------------------------------------------------------------ body
sphere("Shirt", T(0, 0, 3.85) @ S(1.0, 0.68, 0.95))                                 # shirt torso
sphere("Overall", T(0, 0, 3.0) @ S(0.98, 0.66, 0.78))                               # overall pants (lower)
for sx in (-1, 1):                                                                 # straps + buttons
    box("Overall", T(sx * 0.42, 0.52, 3.85) @ Rx(-12) @ S(0.22, 0.1, 1.05))
    sphere("Gold", T(sx * 0.42, 0.62, 4.28) @ S(0.11, 0.06, 0.11), 8, 6)
box("Overall", T(0, 0.55, 3.45) @ S(0.95, 0.12, 0.55))                              # bib
box("ShirtLight", T(-0.55, 0.42, 3.15) @ Rz(8) @ S(0.32, 0.36, 0.3))               # patch
# left arm: straight out along the crossbar, straw hand
cyl("Shirt", T(-1.55, 0, 4.35) @ Ry(90) @ S(0.46, 0.46, 1.6), r1=1.0, r2=0.85, seg=12)
cyl("ShirtLight", T(-2.38, 0, 4.35) @ Ry(90) @ S(0.44, 0.44, 0.12), seg=12)  # cuff
for i, (dy, dz) in enumerate(((0, 0), (0.18, 0.15), (-0.18, 0.12), (0.12, -0.17), (-0.14, -0.15))):
    mat = "Straw" if i % 2 == 0 else "StrawDark"
    cyl(mat, T(-2.75, dy, 4.35 + dz) @ Ry(-90) @ Rx(dy * 60) @ S(0.16, 0.16, 0.7), r1=1.0, r2=0.15, seg=6)
# right arm: raised 30 degrees, straw fist gripping the sign stick (user 2026-11-18: "หุ่นถือป้าย exp")
ARM_UP = 30
SH = Vector((0.8, 0.0, 4.35))
D = Vector((math.cos(math.radians(ARM_UP)), 0.0, math.sin(math.radians(ARM_UP))))
ROT = Ry(90 - ARM_UP)
c = SH + D * 0.85
cyl("Shirt", T(*c) @ ROT @ S(0.46, 0.46, 1.6), r1=1.0, r2=0.85, seg=12)
c = SH + D * 1.68
cyl("ShirtLight", T(*c) @ ROT @ S(0.44, 0.44, 0.12), seg=12)  # cuff
HAND = SH + D * 1.98 + Vector((0, 0.12, 0))
ico("Straw", T(*HAND) @ S(0.34, 0.32, 0.3), 1)                                        # fist
for i, (dx, dz) in enumerate(((0.22, 0.2), (0.28, -0.05), (0.18, -0.25))):           # straw fingers poking out
    cyl("StrawDark" if i == 1 else "Straw", T(HAND.x + dx, HAND.y + 0.05, HAND.z + dz) @ Ry(70) @ S(0.11, 0.11, 0.42), r1=1.0, r2=0.15, seg=6)
# straw sticking out under the overalls
for i, ang in enumerate(range(-150, 151, 30)):
    a = math.radians(ang + 90)
    x, y = math.cos(a) * 0.55, math.sin(a) * 0.38
    mat = "Straw" if i % 2 == 0 else "StrawDark"
    cyl(mat, T(x, y, 2.18) @ Rz(ang) @ Rx(180 + 12) @ S(0.15, 0.15, 0.6), r1=1.0, r2=0.15, seg=6)

# ------------------------------------------------------------------ head
HZ = 5.45
sphere("Sack", T(0, 0, HZ) @ S(0.95, 0.88, 0.92), 18, 12)
cyl("Stitch", T(0, 0, HZ - 0.82) @ S(0.45, 0.42, 0.12), seg=12)                     # neck tie
for sx in (-1, 1):
    sphere("Stitch", T(sx * 0.34, 0.8, HZ + 0.12) @ S(0.13, 0.08, 0.16), 10, 8)     # button eyes
    sphere("White", T(sx * 0.34 - 0.04, 0.86, HZ + 0.18) @ S(0.04, 0.03, 0.04), 6, 4)
    sphere("Cheek", T(sx * 0.58, 0.68, HZ - 0.12) @ S(0.15, 0.06, 0.1), 10, 6)
for i in range(7):                                                                 # stitched smile
    t = (i - 3) / 3.0
    x = t * 0.42
    z = HZ - 0.3 - (1 - t * t) * 0.14
    y = math.sqrt(max(0.0, 1 - (x / 0.95) ** 2 - ((z - HZ) / 0.92) ** 2)) * 0.88 + 0.01
    box("Stitch", T(x, y, z) @ Rz(0) @ Ry(math.degrees(math.atan(t * 0.6))) @ S(0.1, 0.06, 0.035))
# straw hair tufts at the sides
for sx in (-1, 1):
    for k in range(3):
        cyl("Straw" if k != 1 else "StrawDark", T(sx * 0.85, -0.1 + k * 0.12, HZ + 0.35 - k * 0.12) @ Ry(sx * (70 + k * 10)) @ S(0.13, 0.13, 0.5), r1=1.0, r2=0.15, seg=6)

# ------------------------------------------------------------------ hat
HB = HZ + 0.62
cyl("Straw", T(0, 0, HB) @ Rx(-6) @ S(1.65, 1.65, 0.12), seg=24)                    # brim (tilted a bit forward)
cyl("StrawDark", T(0, 0, HB - 0.07) @ Rx(-6) @ S(1.67, 1.67, 0.04), seg=24)        # brim underside rim
cyl("Straw", T(0, -0.05, HB + 0.48) @ S(0.82, 0.82, 0.9), r1=1.0, r2=0.8, seg=20)  # crown
cyl("HatBand", T(0, -0.05, HB + 0.18) @ S(0.85, 0.85, 0.24), seg=20)               # band
# gold star on the band, facing +Y
star = bmesh.new()
pts = []
for k in range(10):
    r = 0.36 if k % 2 == 0 else 0.15
    a = math.radians(90 + k * 36)
    pts.append(star.verts.new((math.cos(a) * r, math.sin(a) * r, 0)))
f = star.faces.new(pts)
ext = bmesh.ops.extrude_face_region(star, geom=[f])
for v in (g for g in ext["geom"] if isinstance(g, bmesh.types.BMVert)):
    v.co.z = 0.1
bmesh.ops.recalc_face_normals(star, faces=star.faces)
put("Gold", star, T(0, 0.82, HB + 0.2) @ Rx(-90))

# ------------------------------------------------------------------ EXP sign (held up in the right hand, faces +Y)
SX, SY = HAND.x, HAND.y + 0.08       # stick runs through the fist
STICK_BOT, STICK_TOP = HAND.z - 0.7, HAND.z + 1.0
cyl("Wood", T(SX, SY - 0.08, (STICK_BOT + STICK_TOP) / 2) @ S(0.09, 0.09, STICK_TOP - STICK_BOT), seg=8)
SZ = STICK_TOP + 0.45                 # sign centre
rbox("Gold", SX, SY, SZ, 2.3, 0.16, 1.15, 0.12)                                    # gold frame
rbox("SignBlue", SX, SY + 0.05, SZ, 2.05, 0.14, 0.92, 0.1)                         # blue face
for sx in (-1, 1):                                                                 # nails
    sphere("WoodDark", T(SX + sx * 0.95, SY + 0.1, SZ + 0.4) @ S(0.07, 0.05, 0.07), 6, 4)

# text "EXP" (extruded, faces +Y)
cu = bpy.data.curves.new("ExpText", 'FONT')
cu.body = "x1.5"  # user 2026-11-18: sign reads x1.5 (was "EXP")
cu.align_x = 'CENTER'
cu.align_y = 'CENTER'
cu.extrude = 0.06
cu.size = 0.78
try:
    cu.font = bpy.data.fonts.load(r"C:\Windows\Fonts\arialbd.ttf", check_existing=True)
except Exception:
    pass
cu.space_character = 1.05
tob = bpy.data.objects.new("ExpText", cu)
bpy.context.scene.collection.objects.link(tob)
dg = bpy.context.evaluated_depsgraph_get()
me = tob.evaluated_get(dg).to_mesh()
tb = bmesh.new(); tb.from_mesh(me)
tob.evaluated_get(dg).to_mesh_clear()
bpy.data.objects.remove(tob, do_unlink=True)
bmesh.ops.triangulate(tb, faces=tb.faces)
put("Gold", tb, T(SX, SY + 0.18, SZ - 0.02) @ Rz(180) @ Rx(90))
for (x, z) in ((-0.88, SZ + 0.32), (0.86, SZ - 0.3)):                              # sparkle dots
    sphere("White", T(SX + x, SY + 0.14, z) @ S(0.06, 0.03, 0.06), 6, 4)

# ------------------------------------------------------------------ build + export
objs, tri = [], 0
for mat, bm in BM.items():
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new("XpScarecrow__" + mat)
    bm.to_mesh(me)
    bm.free()
    me.materials.append(MATS[mat])
    ob = bpy.data.objects.new("XpScarecrow__" + mat, me)
    bpy.context.scene.collection.objects.link(ob)
    objs.append(ob)
    me.calc_loop_triangles()
    tri += len(me.loop_triangles)
allv = [v.co for ob in objs for v in ob.data.vertices]
print("OBJECTS", len(objs), "TRIS", tri)
print("BBOX_MIN", tuple(round(min(c[k] for c in allv), 3) for k in range(3)))
print("BBOX_MAX", tuple(round(max(c[k] for c in allv), 3) for k in range(3)))
bpy.ops.object.select_all(action='DESELECT')
for ob in objs:
    ob.select_set(True)
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "XpScarecrow.glb"), export_format='GLB',
                          use_selection=True, export_apply=True, export_yup=True)
print("EXPORTED", os.path.join(OUT, "XpScarecrow.glb"))
