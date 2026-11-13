# Ring channel water sheet v3 (2026-11-12): built from the terrain water line measured in Studio, not from a guessed centreline.
# The user saw a pale strip of plain terrain water between the old sheet edge and the plot-side bank, and a small bay with no sheet.
#   blender.exe -b --factory-startup -P build_ring_water_mask.py -- <outdir>
# Input ring_mask.txt (next to this script): one row per z, one char per x, 2-stud cells from X0/Z0 below.
#   w = terrain water at y ~4 · h = land above y 4.6 (sheet at 4.37 is hidden under it) · l = low land · o = water at another height
# Sheet = every w cell + one ring of h/l cells next to water (edge tucks under the bank / covers the shallow pale shore strip), cut at the waterfall pool outline
# (water_clip.py) so it never overlaps the pool sheet. Blender (x, y, z) = (-worldX, worldZ, up); faces point up.
import bpy, bmesh, sys, os
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else HERE
X0, Z0, S = 70, -185, 2
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o, do_unlink=True)

rows = [r.rstrip("\n") for r in open(os.path.join(HERE, "ring_mask.txt"), encoding="utf-8") if r.strip()]
H, W = len(rows), len(rows[0])
cell = lambda i, j: rows[j][i] if 0 <= j < H and 0 <= i < W else "."
keep = set()
for j in range(H):
    for i in range(W):
        if cell(i, j) == "w":
            keep.add((i, j))
for j in range(H):
    for i in range(W):
        if cell(i, j) in ("h", "l") and any(cell(i + a, j + b) == "w" for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1))):
            keep.add((i, j))

bm = bmesh.new()
verts = {}
def v(i, j):
    k = (i, j)
    if k not in verts:
        verts[k] = bm.verts.new(Vector((-(X0 + i * S), Z0 + j * S, 0.0)))
    return verts[k]
for (i, j) in keep:
    f = bm.faces.new([v(i, j), v(i + 1, j), v(i + 1, j + 1), v(i, j + 1)])
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
for f in bm.faces:
    if f.normal.z < 0:
        f.normal_flip()
# no dissolve_limit: it merged the whole ring into one face with the plot as a hole -> bad triangles (bay left uncovered)

def lin(c):
    c = c / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
mat = bpy.data.materials.new("Water_Mid"); mat.use_nodes = True
col = tuple(lin(x) for x in (64, 196, 214)) + (1.0,)
next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED").inputs["Base Color"].default_value = col
mat.diffuse_color = col
me = bpy.data.meshes.new("RingWater__Water_Mid")
bm.to_mesh(me); bm.free()
me.materials.append(mat)
ob = bpy.data.objects.new("RingWater__Water_Mid", me)
bpy.context.scene.collection.objects.link(ob)
print("CELLS", len(keep), "FACES", len(me.polygons))

sys.path.insert(0, HERE)
import water_clip
water_clip.clip_all([ob], HERE)
# triangulate so Roblox gets clean faces (ngons from dissolve)
bm = bmesh.new(); bm.from_mesh(ob.data)
bmesh.ops.triangulate(bm, faces=bm.faces)
bm.to_mesh(ob.data); bm.free()
print("TRIS", len(ob.data.polygons))

bpy.ops.object.select_all(action='DESELECT')
ob.select_set(True)
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "RingWater_One.glb"), export_format='GLB', use_selection=True, export_apply=True, export_yup=True)
