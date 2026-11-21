# preview_crop_lod.py: render original (left) vs simplified (right) for each crop stage group.
#   blender -b --factory-startup -P preview_crop_lod.py -- CropOrig.glb CropLod.glb <outdir>
import bpy, sys, math, mathutils
argv = sys.argv[sys.argv.index("--") + 1:]
ORIG, LOD, OUTDIR = argv
bpy.ops.wm.read_factory_settings(use_empty=True)

def load(path, tag):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    objs = [o for o in bpy.data.objects if o not in before and o.type == "MESH"]
    for o in objs: o["tag"] = tag
    return objs

orig = load(ORIG, "orig")
lod = load(LOD, "lod")
groups = {}
for o in orig + lod:
    key = "_".join(o.name.split(".")[0].split("_")[:2])  # Corn_Stage5
    groups.setdefault(key, {"orig": [], "lod": []})[o["tag"]].append(o)

scene = bpy.context.scene
for eng in ("BLENDER_WORKBENCH", "BLENDER_WORKBENCH_NEXT"):
    try:
        scene.render.engine = eng
        break
    except TypeError:
        pass
scene.display.shading.color_type = "VERTEX"
scene.display.shading.light = "STUDIO"
scene.render.resolution_x, scene.render.resolution_y = 1200, 600
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
scene.collection.objects.link(cam)
scene.camera = cam

for key, g in groups.items():
    for o in bpy.data.objects:
        if o.type == "MESH": o.hide_render = True
    pts = []
    for side, dx in (("orig", -1), ("lod", 1)):
        objs = g[side]
        mn = mathutils.Vector((1e9,) * 3); mx = mathutils.Vector((-1e9,) * 3)
        for o in objs:
            for c in o.bound_box:
                w = o.matrix_world @ mathutils.Vector(c)
                mn = mathutils.Vector(map(min, mn, w)); mx = mathutils.Vector(map(max, mx, w))
        size = max((mx - mn).length, 0.01)
        g[side + "_size"] = size
    size = max(g["orig_size"], g["lod_size"])
    for side, dx in (("orig", -0.6), ("lod", 0.6)):
        for o in g[side]:
            o.hide_render = False
            o.location.x += dx * size
    cam.location = (0, -2.2 * size, 0.9 * size)
    cam.rotation_euler = (math.radians(72), 0, 0)
    scene.render.filepath = f"{OUTDIR}/preview_{key}.png"
    bpy.ops.render.render(write_still=True)
    for side, dx in (("orig", -0.6), ("lod", 0.6)):
        for o in g[side]: o.location.x -= dx * size
print("PREVIEW_DONE", list(groups))
