# Shared by build_stream_water.py / build_ring_water.py in "onesheet" mode (2026-11-12):
# cut away every part of a water sheet that lies inside the waterfall pool outline (POOL in build_pool_water.py v2),
# so the pool sheet and the stream / ring sheets never overlap (two see-through sheets on top of each other drew darker patches).
# Method: thicken the flat sheet, Boolean DIFFERENCE (Exact) with the pool outline as a prism, keep only the top faces, flatten to z 0.
import bpy, bmesh, os, re
from mathutils import Vector


def pool_outline(here):
    src = open(os.path.join(here, "build_pool_water.py"), encoding="utf-8").read()
    m = re.search(r"^POOL = (\[.*?\])\s*$", src, re.M | re.S)  # the list spans several lines (with # comments)
    return eval(m.group(1))


def _cutter(poly):
    bm = bmesh.new()
    vs = [bm.verts.new(Vector((-x, z, -2.0))) for x, z in poly]
    f = bm.faces.new(vs)
    res = bmesh.ops.extrude_face_region(bm, geom=[f])
    top = [g for g in res["geom"] if isinstance(g, bmesh.types.BMVert)]
    bmesh.ops.translate(bm, verts=top, vec=Vector((0, 0, 4.0)))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new("PoolCutter")
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new("PoolCutter", me)
    bpy.context.scene.collection.objects.link(ob)
    return ob


def clip(ob, poly):
    cutter = _cutter(poly)
    for o in bpy.context.scene.objects:
        o.select_set(False)
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    sol = ob.modifiers.new("Thick", "SOLIDIFY")
    sol.thickness = 0.4
    sol.offset = 0.0
    bpy.ops.object.modifier_apply(modifier=sol.name)
    cut = ob.modifiers.new("Cut", "BOOLEAN")
    cut.operation = "DIFFERENCE"
    cut.object = cutter
    cut.solver = "EXACT"
    bpy.ops.object.modifier_apply(modifier=cut.name)
    bpy.data.objects.remove(cutter, do_unlink=True)
    # keep only the upward faces of the top skin, then flatten back to the sheet plane
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    zmax = max(v.co.z for v in bm.verts)
    drop = [f for f in bm.faces if f.normal.z < 0.9 or f.calc_center_median().z < zmax - 0.01]
    bmesh.ops.delete(bm, geom=drop, context="FACES")
    for v in bm.verts:
        v.co.z = 0.0
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.01)
    bm.to_mesh(ob.data)
    bm.free()
    xs = [v.co.x for v in ob.data.vertices]
    ys = [v.co.y for v in ob.data.vertices]
    print("CLIPPED", ob.name, "CENTRE", round(-(min(xs) + max(xs)) / 2, 3), round((min(ys) + max(ys)) / 2, 3),
          "SIZE", round(max(xs) - min(xs), 2), round(max(ys) - min(ys), 2), "FACES", len(ob.data.polygons))


def clip_all(objs, here):
    poly = pool_outline(here)
    for ob in objs:
        clip(ob, poly)
