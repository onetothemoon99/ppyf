# Waterfall pool cover only (v2, 2026-11-11). Same layout rules as build_stream_water.py:
#   blender.exe -b --factory-startup -P build_pool_water.py -- <outdir>
# Blender (x, y, z) = (-worldX, worldZ, up); faces point up. Prints CENTRE name x z for placement.
# v2: the west side (150..210 deg from the pool centre) was re-measured to the terrain water line, 1.5 inside.
# v1 stopped at x ~381 there (the rocks), which left a wedge of plain terrain water uncovered.
import bpy, bmesh, sys, os
from mathutils import Vector

OUT = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else os.path.dirname(os.path.abspath(__file__))
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o, do_unlink=True)

def lin(c):
    c = c / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
MATS = {}
for n in ("Water_Mid", "Water_Light"):
    m = bpy.data.materials.new(n); m.use_nodes = True
    col = tuple(lin(v) for v in (64, 196, 214)) + (1.0,)
    next(x for x in m.node_tree.nodes if x.type == "BSDF_PRINCIPLED").inputs["Base Color"].default_value = col
    m.diffuse_color = col
    MATS[n] = m

POOL_C = Vector((425.0, -5.0))
POOL = [(471.5,-5.0), (470.3,-1.0), (477.7,4.3), (475.7,8.6), (474.3,13.0), (471.7,16.8), (467.9,19.8), (466.4,24.0),
        (466.0,29.4), (463.5,33.5), (461.3,38.3), (458.6,42.9), (455.8,48.3), (451.8,52.6), (446.7,54.7), (441.7,57.3),
        (436.5,60.5), (431.4,68.2), (425.0,75.5), (417.4,82.2), (409.8,81.2), (402.1,80.5), (394.7,78.2), (387.6,75.2),
        (380.8,71.6), (374.2,67.5), (368.1,62.8), (362.4,57.6), (357.2,51.9), (352.5,45.8),
        # re-measured west side, 150..210 deg every 5
        (345.8,40.7), (349.3,30.3), (350.3,22.2), (349.7,15.2), (349.7,8.3), (349.8,1.6), (350.0,-5.0),
        (349.8,-11.6), (349.7,-18.3), (349.7,-25.2), (349.8,-32.4), (349.3,-40.3), (349.2,-48.8),
        (352.5,-55.8), (357.2,-61.9), (371.6,-58.4), (382.3,-55.9), (386.3,-60.3), (388.2,-68.7), (391.4,-77.1),
        (395.4,-86.3), (402.1,-90.5), (409.6,-92.2), (417.3,-93.2), (425.0,-93.5), (432.0,-85.2), (437.2,-74.4),
        (441.4,-66.3), (446.7,-64.7), (451.0,-60.7), (454.8,-56.5), (458.6,-52.9), (460.0,-46.7), (462.8,-42.8),
        (465.2,-38.7), (466.4,-34.0), (467.0,-29.2), (469.9,-25.9), (473.4,-22.6), (474.7,-18.3), (477.7,-14.3), (477.3,-9.6)]

BM = {}
def face(mat, pts):
    bm = BM.setdefault(mat, bmesh.new())
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
    face("Water_Light", [a, b, bi, ai])
    face("Water_Mid", [ai, bi, POOL_C])

objs = []
for mat, bm in BM.items():
    me = bpy.data.meshes.new("PoolWater__" + mat)
    bm.to_mesh(me); bm.free()
    me.materials.append(MATS[mat])
    ob = bpy.data.objects.new("PoolWater__" + mat, me)
    bpy.context.scene.collection.objects.link(ob)
    objs.append(ob)
    xs = [v.co.x for v in me.vertices]; ys = [v.co.y for v in me.vertices]
    print("CENTRE", "Pool_" + mat, round(-(min(xs) + max(xs)) / 2, 3), round((min(ys) + max(ys)) / 2, 3),
          "SIZE", round(max(xs) - min(xs), 2), round(max(ys) - min(ys), 2))
bpy.ops.object.select_all(action='DESELECT')
for ob in objs:
    ob.select_set(True)
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "PoolWater.glb"), export_format='GLB', use_selection=True,
                          export_apply=True, export_yup=True)
