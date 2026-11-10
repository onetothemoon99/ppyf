# Mountain dressing kit: separate rock and plant pieces in the same cartoon style as the waterfall.
# Reuses the helper functions of build_waterfall.py (same colours, rock tones, leaves). Run:
#   blender.exe -b --factory-startup -P build_mountain_kit.py -- <outdir>
# Every mesh object is named "<Piece>__<Material>"; Studio groups them back into one Model per piece.
# Each piece is built around (0,0,0) = bottom centre and then laid out on a grid for export.
import bpy, bmesh, math, random, sys, os
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else HERE
src = open(os.path.join(HERE, "build_waterfall.py"), encoding="utf-8-sig").read()
helpers = src[:src.index("# Back mass")]
helpers += src[src.index("def blob("):src.index("# White foam")]
helpers += src[src.index("# ------------------------------------------------------------------ plants"):src.index("# palms (from the picture)")]
helpers = helpers.replace('OUT = sys.argv', 'OUT_UNUSED = sys.argv')
g = {"__name__": "kit", "OUT": OUT}
exec(compile(helpers, "waterfall_helpers", "exec"), g)

PIECE = {"name": None, "off": Vector()}
PBM = {}
def face(mat, pts):
    key = PIECE["name"] + "__" + mat
    bm = PBM.setdefault(key, bmesh.new())
    vs = [bm.verts.new(Vector(p) + PIECE["off"]) for p in pts]
    try:
        bm.faces.new(vs)
    except ValueError:
        pass
g["face"] = face
rock, bush, palm, fern, big_leaves = g["rock"], g["bush"], g["palm"], g["fern"], g["big_leaves"]

def piece(name, i):
    PIECE["name"] = name
    PIECE["off"] = Vector(((i % 5) * 70.0, (i // 5) * 70.0, 0))

PIECES = []
def add(name, fn):
    piece(name, len(PIECES))
    fn()
    PIECES.append(name)

# ---- rocks (bottom at z ~ 0, sunk a little so they sit into the slope)
add("R_BoulderS", lambda: rock((0, 0, 2.5), (8, 7, 7), bevel=0.42, jitter=0.1, seed=1))
add("R_BoulderM", lambda: rock((0, 0, 4), (13, 11, 10), rot=0.3, bevel=0.4, jitter=0.1, seed=2))
def boulder_l():
    rock((0, 0, 6), (20, 16, 14), rot=0.2, bevel=0.4, jitter=0.1, seed=3)
    rock((11, -4, 3), (9, 8, 7), rot=0.7, bevel=0.42, seed=4)
add("R_BoulderL", boulder_l)
add("R_Slab", lambda: rock((0, 0, 3), (22, 13, 8), rot=0.05, bevel=0.3, seed=5))
def slab_stack():
    rock((0, 0, 4), (20, 14, 9), bevel=0.3, seed=6)
    rock((2, 1, 11), (15, 11, 7), rot=0.2, bevel=0.32, seed=7)
add("R_SlabStack", slab_stack)
def column():
    rock((0, 0, 7), (12, 11, 15), rot=0.1, bevel=0.3, seed=8)
    rock((1, 0, 19), (10, 10, 11), rot=-0.15, bevel=0.32, seed=9)
add("R_Column", column)
def column_pair():
    rock((0, 0, 9), (11, 11, 19), bevel=0.3, seed=10)
    rock((10, 1, 6), (10, 10, 13), rot=0.3, tone="dark", bevel=0.32, seed=11)
    rock((-2, -1, 21), (9, 9, 7), rot=0.5, bevel=0.38, seed=12)
add("R_ColumnPair", column_pair)
def flat_pile():
    rock((0, 0, 1.5), (12, 10, 4), rot=0.2, bevel=0.38, seed=13)
    rock((9, 4, 1.5), (9, 8, 3.5), rot=-0.4, bevel=0.38, seed=14)
    rock((-6, 6, 1.2), (7, 6, 3), rot=0.9, bevel=0.4, seed=15)
add("R_FlatPile", flat_pile)

# ---- plants (base at 0,0,0)
add("P_PalmTall", lambda: palm((0, 0, -1), (2, 0, 38), 18, n=10, seed=21, lean=2))
add("P_PalmShort", lambda: palm((0, 0, -1), (-1, 0, 22), 13, n=9, seed=22, lean=-1.5))
add("P_BushGreen", lambda: bush((0, 0, 3), 7, "green", seed=23))
add("P_BushDark", lambda: bush((0, 0, 3), 7, "dark", seed=24))
add("P_BushTeal", lambda: bush((0, 0, 3), 6, "teal", seed=25))
add("P_BigLeaves", lambda: big_leaves((0, 0, 0), 12, n=7, seed=26))
add("P_Fern", lambda: fern((0, 0, 0), 8, seed=27))

# ---- build objects
MATS = g["MATS"]
objs, tri = [], {}
for key, bm in PBM.items():
    me = bpy.data.meshes.new(key)
    bm.to_mesh(me)
    bm.free()
    me.materials.append(MATS[key.split("__")[1]])
    ob = bpy.data.objects.new(key, me)
    bpy.context.scene.collection.objects.link(ob)
    objs.append(ob)
    me.calc_loop_triangles()
    p = key.split("__")[0]
    tri[p] = tri.get(p, 0) + len(me.loop_triangles)
print("PIECES", len(PIECES), "OBJECTS", len(objs))
print("TRIS", tri)
for i, name in enumerate(PIECES):
    print("OFFSET", name, (i % 5) * 70.0, (i // 5) * 70.0)

bpy.ops.object.select_all(action='DESELECT')
for ob in objs:
    ob.select_set(True)
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "MountainKit.glb"), export_format='GLB',
                          use_selection=True, export_apply=True, export_yup=True)

scn = bpy.context.scene
scn.render.engine = 'BLENDER_WORKBENCH'
scn.display.shading.light = 'STUDIO'
scn.display.shading.color_type = 'MATERIAL'
scn.render.resolution_x, scn.render.resolution_y = 1100, 800
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
cam.data.type = 'ORTHO'
cam.data.ortho_scale = 360
scn.collection.objects.link(cam)
scn.camera = cam
cam.location = (140, -260, 200)
cam.rotation_euler = (Vector((140, 60, 10)) - cam.location).to_track_quat('-Z', 'Y').to_euler()
scn.render.filepath = os.path.join(OUT, "preview_kit.png")
bpy.ops.render.render(write_still=True)
print("DONE")
