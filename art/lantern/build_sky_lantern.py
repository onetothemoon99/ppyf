# Sky lantern (โคมลอย) for the night beach scene, shaped like real paper lanterns: a tall 4-sided paper
# box, wider at the top, slightly puffed, closed top, open bottom (the flame shows from below).
# Run:  blender.exe -b --factory-startup -P build_sky_lantern.py -- <outdir>
# 1 unit = 1 stud, Z up, bottom ring at z = 0, centred on X/Y. Paper is double-sided (Roblox culls back faces).
# Output: SkyLanternGlow.glb (one mesh "Paper") + preview.png
import bpy, bmesh, math, sys, os
from mathutils import Vector

OUT = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else os.path.dirname(os.path.abspath(__file__))
os.makedirs(OUT, exist_ok=True)
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o, do_unlink=True)

H = 1.7          # height
B = 0.50         # half-width at the bottom
T = 0.68         # half-width at the top
PUFF = 0.07      # side bulge at mid height
RINGS = 8        # vertical rings
SIDE_SEG = 4     # segments per side (lets the puff curve across the face)

def half_width(k):
    return B + (T - B) * k + PUFF * math.sin(math.pi * k)

bm = bmesh.new()
rings = []
for r in range(RINGS + 1):
    k = r / RINGS
    hw = half_width(k)
    z = H * k
    ring = []
    corners = [(-1, -1), (1, -1), (1, 1), (-1, 1)]
    for s in range(4):
        (x0, y0), (x1, y1) = corners[s], corners[(s + 1) % 4]
        for j in range(SIDE_SEG):
            t = j / SIDE_SEG
            x, y = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
            # puff the middle of each face outward a little
            mid = math.sin(math.pi * t)
            nx, ny = (y1 - y0), -(x1 - x0)  # outward normal of this side (corners go CCW from above)
            nl = math.hypot(nx, ny)
            nx, ny = nx / nl, ny / nl
            bulge = 0.05 * mid * math.sin(math.pi * k) * 2
            ring.append(bm.verts.new((x * hw + nx * bulge, y * hw + ny * bulge, z)))
    rings.append(ring)
n = len(rings[0])
for r in range(RINGS):
    for i in range(n):
        a, b = rings[r][i], rings[r][(i + 1) % n]
        c, d = rings[r + 1][(i + 1) % n], rings[r + 1][i]
        bm.faces.new((a, b, c, d))
# closed top (slightly domed)
top_c = bm.verts.new((0, 0, H + 0.08))
for i in range(n):
    bm.faces.new((rings[-1][i], rings[-1][(i + 1) % n], top_c))
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
# double-sided: copy every face reversed
for f in list(bm.faces):
    vs = [bm.verts.new(v.co) for v in reversed(f.verts)]
    bm.faces.new(vs)
me = bpy.data.meshes.new("Paper")
bm.to_mesh(me)
bm.free()
obj = bpy.data.objects.new("Paper", me)
bpy.context.collection.objects.link(obj)
mat = bpy.data.materials.new("Paper")
mat.use_nodes = True
bsdf = next(nd for nd in mat.node_tree.nodes if nd.type == "BSDF_PRINCIPLED")
bsdf.inputs["Base Color"].default_value = (1.0, 0.45, 0.12, 1)
me.materials.append(mat)
for p in me.polygons:
    p.use_smooth = False

bpy.ops.object.select_all(action="DESELECT")
obj.select_set(True)
bpy.context.view_layer.objects.active = obj
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "SkyLanternGlow.glb"), export_format="GLB", use_selection=True)

# preview render
cam_data = bpy.data.cameras.new("Cam")
cam = bpy.data.objects.new("Cam", cam_data)
bpy.context.collection.objects.link(cam)
cam.location = (0, -4.5, 0.4)
cam.rotation_euler = (math.radians(82), 0, 0)
bpy.context.scene.camera = cam
light = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
light.rotation_euler = (math.radians(50), 0, math.radians(30))
bpy.context.collection.objects.link(light)
sc = bpy.context.scene
sc.render.resolution_x, sc.render.resolution_y = 400, 400
try:
    sc.render.engine = "BLENDER_WORKBENCH"
except TypeError:
    pass
sc.render.filepath = os.path.join(OUT, "preview.png")
bpy.ops.render.render(write_still=True)
print("DONE", os.path.join(OUT, "SkyLanternGlow.glb"))
