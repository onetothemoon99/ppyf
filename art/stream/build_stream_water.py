# Turquoise water sheet for the widened stream (Roblox terrain water colour is global, so the stream gets its own
# see-through sheet laid over the terrain water). Run:
#   blender.exe -b --factory-startup -P build_stream_water.py -- <outdir>
# Authored straight in world coordinates: Blender (x, y, z) = (-worldX, worldZ, up). The Roblox importer maps a mesh
# to local (-bx, bz, by), so the MeshPart's local axes equal world axes when placed with an identity rotation.
# Faces point up (+Z Blender = +Y Roblox). Each mesh's world centre is printed as CENTRE name x z for placement.
import bpy, bmesh, math, sys, os
from mathutils import Vector

OUT = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else os.path.dirname(os.path.abspath(__file__))
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o, do_unlink=True)

def lin(c):
    c = c / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
COLORS = {"Water_Mid": (64, 196, 214), "Water_Light": (150, 228, 238), "Water_Edge": (196, 240, 244)}
MATS = {}
for n, rgb in COLORS.items():
    m = bpy.data.materials.new(n); m.use_nodes = True
    col = tuple(lin(v) for v in rgb) + (1.0,)
    next(x for x in m.node_tree.nodes if x.type == "BSDF_PRINCIPLED").inputs["Base Color"].default_value = col
    m.diffuse_color = col
    MATS[n] = m

# centreline (world x, z) and half width of the carved channel (same as Studio _G.StreamLine)
PTS = [(404, 38), (362, 76), (324, 106), (290, 120), (250, 118), (210, 114), (170, 108), (130, 104), (95, 100), (60, 96), (25, 94), (-5, 93), (-35, 92), (-58, 92)]
HW = [35, 33, 32, 30, 28, 28, 27, 27, 27, 26, 26, 26, 26, 25]
INSET = 1.5          # sheet edge 1.5 inside the grass line
END_R = 25

def catmull(p0, p1, p2, p3, t):
    t2, t3 = t * t, t * t * t
    return 0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3)

P = [Vector(p) for p in PTS]
samples, widths = [], []
for i in range(len(P) - 1):
    p0 = P[i - 1] if i > 0 else P[i]
    p3 = P[i + 2] if i + 2 < len(P) else P[i + 1]
    n = max(2, int((P[i + 1] - P[i]).length / 2.0))
    for k in range(n):
        t = k / n
        samples.append(catmull(p0, P[i], P[i + 1], p3, t))
        widths.append(HW[i] + (HW[i + 1] - HW[i]) * t - INSET)
samples.append(P[-1]); widths.append(HW[-1] - INSET)

BM = {}
def face(mat, pts):
    bm = BM.setdefault(mat, bmesh.new())
    vs = [bm.verts.new(Vector((-p[0], p[1], 0.0))) for p in pts]   # world (x, z) → Blender (-x, z, 0)
    # keep the face pointing up: Newell normal z must be > 0
    nz = 0.0
    for a in range(len(vs)):
        b = (a + 1) % len(vs)
        nz += (vs[a].co.x - vs[b].co.x) * (vs[a].co.y + vs[b].co.y)
    if nz < 0:
        vs.reverse()
    try:
        bm.faces.new(vs)
    except ValueError:
        pass

FR = [-1.0, -0.82, -0.45, 0.45, 0.82, 1.0]      # cross-section offsets (fraction of half width)
BAND = ["Water_Edge", "Water_Light", "Water_Mid", "Water_Light", "Water_Edge"]
rows = []
for i, p in enumerate(samples):
    a = samples[max(i - 1, 0)]; b = samples[min(i + 1, len(samples) - 1)]
    d = (b - a); d.normalize()
    nrm = Vector((-d.y, d.x))
    rows.append([p + nrm * widths[i] * f for f in FR])
for i in range(len(rows) - 1):
    for j in range(len(FR) - 1):
        face(BAND[j], [rows[i][j], rows[i][j + 1], rows[i + 1][j + 1], rows[i + 1][j]])
# round end pool at the last point: rings at the same band fractions
c = P[-1]
dlast = (P[-1] - P[-2]); dlast.normalize()
start = math.atan2(-dlast.x, dlast.y)      # angle of the left normal
segs = 24
fr_r = [1.0, 0.82, 0.45]
mats_r = ["Water_Edge", "Water_Light", "Water_Mid"]
r_end = END_R - INSET
for k in range(segs):
    a0 = start + math.pi * k / segs
    a1 = start + math.pi * (k + 1) / segs
    for j in range(3):
        ro, ri = r_end * fr_r[j], (r_end * fr_r[j + 1] if j < 2 else 0.0)
        po0 = c + Vector((math.cos(a0), math.sin(a0))) * ro
        po1 = c + Vector((math.cos(a1), math.sin(a1))) * ro
        if ri > 0:
            pi0 = c + Vector((math.cos(a0), math.sin(a0))) * ri
            pi1 = c + Vector((math.cos(a1), math.sin(a1))) * ri
            face(mats_r[j], [po0, po1, pi1, pi0])
        else:
            face(mats_r[j], [po0, po1, c])

objs = []
for mat, bm in BM.items():
    me = bpy.data.meshes.new("StreamWater__" + mat)
    bm.to_mesh(me); bm.free()
    me.materials.append(MATS[mat])
    ob = bpy.data.objects.new("StreamWater__" + mat, me)
    bpy.context.scene.collection.objects.link(ob)
    objs.append(ob)
    xs = [v.co.x for v in me.vertices]; ys = [v.co.y for v in me.vertices]
    print("CENTRE", mat, round(-(min(xs) + max(xs)) / 2, 3), round((min(ys) + max(ys)) / 2, 3),
          "SIZE", round(max(xs) - min(xs), 2), round(max(ys) - min(ys), 2), "FACES", len(me.polygons))
bpy.ops.object.select_all(action='DESELECT')
for ob in objs:
    ob.select_set(True)
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "StreamWater.glb"), export_format='GLB', use_selection=True, export_apply=True, export_yup=True)

scn = bpy.context.scene
scn.render.engine = 'BLENDER_WORKBENCH'
scn.display.shading.light = 'FLAT'
scn.display.shading.color_type = 'MATERIAL'
scn.display.shading.show_backface_culling = True
scn.render.resolution_x, scn.render.resolution_y = 1000, 800
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
cam.data.type = 'ORTHO'; cam.data.ortho_scale = 400
scn.collection.objects.link(cam); scn.camera = cam
cam.location = (-226, 95, 300)
cam.rotation_euler = (0, 0, 0)
scn.render.filepath = os.path.join(OUT, "preview_water.png")
bpy.ops.render.render(write_still=True)

# ------------------------------------------------------------------ waterfall pool cover (separate meshes, placed a hair lower)
# Pool edge measured in Studio every 5 deg from (425, -5), 1.5 studs inside the water line.
POOL_C = Vector((425.0, -5.0))
POOL = [(471.5,-5.0), (470.3,-1.0), (477.7,4.3), (475.7,8.6), (474.3,13.0), (471.7,16.8), (467.9,19.8), (466.4,24.0), (466.0,29.4), (463.5,33.5), (461.3,38.3), (458.6,42.9), (455.8,48.3), (451.8,52.6), (446.7,54.7), (441.7,57.3), (436.5,60.5), (431.4,68.2), (425.0,75.5), (417.4,82.2), (409.8,81.2), (402.1,80.5), (394.7,78.2), (387.6,75.2), (380.8,71.6), (374.2,67.5), (368.1,62.8), (362.4,57.6), (357.2,51.9), (352.5,45.8), (366.5,28.8), (379.2,16.3), (391.6,7.1), (394.6,3.2), (393.0,0.6), (381.7,-1.2), (381.5,-5.0), (381.7,-8.8), (381.2,-12.7), (381.1,-16.8), (381.3,-20.9), (381.0,-25.5), (381.3,-30.2), (352.5,-55.8), (357.2,-61.9), (371.6,-58.4), (382.3,-55.9), (386.3,-60.3), (388.2,-68.7), (391.4,-77.1), (395.4,-86.3), (402.1,-90.5), (409.6,-92.2), (417.3,-93.2), (425.0,-93.5), (432.0,-85.2), (437.2,-74.4), (441.4,-66.3), (446.7,-64.7), (451.0,-60.7), (454.8,-56.5), (458.6,-52.9), (460.0,-46.7), (462.8,-42.8), (465.2,-38.7), (466.4,-34.0), (467.0,-29.2), (469.9,-25.9), (473.4,-22.6), (474.7,-18.3), (477.7,-14.3), (477.3,-9.6)]
BM2 = {}
def face2(mat, pts):
    bm = BM2.setdefault(mat, bmesh.new())
    vs = [bm.verts.new(Vector((-p[0], p[1], 0.0))) for p in pts]
    nz = 0.0
    for a in range(len(vs)):
        b = (a + 1) % len(vs)
        nz += (vs[a].co.x - vs[b].co.x) * (vs[a].co.y + vs[b].co.y)
    if nz < 0:
        vs.reverse()
    try:
        bm.faces.new(vs)
    except ValueError:
        pass
PP = [Vector(p) for p in POOL]
for i in range(len(PP)):
    a, b = PP[i], PP[(i + 1) % len(PP)]
    ai, bi = POOL_C + (a - POOL_C) * 0.8, POOL_C + (b - POOL_C) * 0.8
    face2("Water_Light", [a, b, bi, ai])
    face2("Water_Mid", [ai, bi, POOL_C])
objs2 = []
for mat, bm in BM2.items():
    me = bpy.data.meshes.new("PoolWater__" + mat)
    bm.to_mesh(me); bm.free()
    me.materials.append(MATS[mat])
    ob = bpy.data.objects.new("PoolWater__" + mat, me)
    bpy.context.scene.collection.objects.link(ob)
    objs2.append(ob)
    xs = [v.co.x for v in me.vertices]; ys = [v.co.y for v in me.vertices]
    print("CENTRE", "Pool_" + mat, round(-(min(xs) + max(xs)) / 2, 3), round((min(ys) + max(ys)) / 2, 3), "SIZE", round(max(xs) - min(xs), 2), round(max(ys) - min(ys), 2))
bpy.ops.object.select_all(action='DESELECT')
for ob in objs + objs2:
    ob.select_set(True)
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "StreamWater.glb"), export_format='GLB', use_selection=True, export_apply=True, export_yup=True)
cam.location = (-260, 40, 300)
scn.render.filepath = os.path.join(OUT, "preview_water.png")
bpy.ops.render.render(write_still=True)
