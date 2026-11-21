# build_crop_lod.py — 2026-11-21, low-end round 3 step C1
# Rebuilds the heavy crop meshes dumped from Studio (meshdump.txt, made by an execute_luau EditableMesh dump
# of ServerStorage.CropTemplates Corn/Wheat/Watermelon Stage1/3/5, meshes with >= 700 tris),
# simplifies each one with a Decimate (collapse) modifier, keeps its single vertex colour, and exports one GLB.
# Run headless:
#   "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup -P build_crop_lod.py -- <dump> <out.glb> [ratioScale]
# Coordinates: dump = Roblox mesh space x 10000. Roblox importer maps Blender (bx,by,bz) -> Roblox (-bx, bz, by),
# so we build with bx = -rx, by = rz, bz = ry.
import bpy, sys

argv = sys.argv[sys.argv.index("--") + 1:]
DUMP, OUT = argv[0], argv[1]
SCALE = float(argv[2]) if len(argv) > 2 else 1.0

# target ratio per mesh (share of triangles kept). Thin blades keep more; bulky repeated detail keeps less.
RATIO = {
    "Corn_Stage3_leaf_green": 0.55, "Corn_Stage3_tassel_tan": 0.25, "Corn_Stage3_husk_green": 0.45,
    "Corn_Stage5_leaf_green": 0.6, "Corn_Stage5_husk_dry": 0.25, "Corn_Stage5_kernel_gold": 0.35,
    "Corn_Stage5_silk_dry": 0.4,
    "Wheat_Stage3_culm_green": 0.4, "Wheat_Stage3_leaf_green": 0.4, "Wheat_Stage5_culm_straw": 0.4,
    "Wheat_Stage5_leaf_dry": 0.4, "Wheat_Stage5_spike_gold": 0.25, "Wheat_Stage5_grain_amber": 0.25,
    "Wheat_Stage5_awn_straw": 0.3,
    "Watermelon_Stage1_leaf_green": 0.5, "Watermelon_Stage3_vine_green": 0.3, "Watermelon_Stage3_leaf_green": 0.3,
    "Watermelon_Stage5_vine_green": 0.3, "Watermelon_Stage5_leaf_green": 0.3, "Watermelon_Stage5_rind_light": 0.4,
    "Watermelon_Stage5_rind_stripe": 0.3,
    # round 2 (2026-11-21): strawberry / onion / pineapple
    "Strawberry_Stage1_leaf_green": 0.4, "Strawberry_Stage3_stem_green": 0.45, "Strawberry_Stage3_leaf_green": 0.3,
    "Strawberry_Stage5_stem_green": 0.4, "Strawberry_Stage5_leaf_green": 0.3, "Strawberry_Stage5_berry_ripe": 0.45,
    "Strawberry_Stage5_achene_gold": 0.4,
    "Onion_Stage3_leaf_green": 0.4, "Onion_Stage3_leaf_deep": 0.4, "Onion_Stage3_root_cream": 0.35,
    "Onion_Stage5_bulb_white": 0.5, "Onion_Stage5_leaf_green": 0.35, "Onion_Stage5_leaf_deep": 0.35,
    "Onion_Stage5_flower_white": 0.4, "Onion_Stage5_root_cream": 0.3,
    "Pineapple_Stage3_leaf_green": 0.45, "Pineapple_Stage3_leaf_dark": 0.45, "Pineapple_Stage3_leaf_glaucous": 0.45,
    "Pineapple_Stage3_fruit_green": 0.6, "Pineapple_Stage3_eye_green": 0.35,
    "Pineapple_Stage5_leaf_green": 0.45, "Pineapple_Stage5_leaf_dark": 0.45, "Pineapple_Stage5_leaf_glaucous": 0.45,
    "Pineapple_Stage5_fruit_gold": 0.6, "Pineapple_Stage5_eye_brown": 0.35,
}

def srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

bpy.ops.wm.read_factory_settings(use_empty=True)
lines = open(DUMP, "r").read().split("\n")
i = 0
report = []
while i < len(lines) and lines[i] != "END":
    head = lines[i].split()
    name, meshid, nv, nf = head[1], head[2], int(head[3]), int(head[4])
    pal = lines[i + 1][2:].split()
    vv = list(map(int, lines[i + 2][2:].split()))
    ff = list(map(int, lines[i + 3][2:].split()))
    i += 4
    verts = []
    for k in range(nv):
        rx, ry, rz = vv[3 * k] / 10000, vv[3 * k + 1] / 10000, vv[3 * k + 2] / 10000
        verts.append((-rx, rz, ry))
    faces = [(ff[4 * k], ff[4 * k + 1], ff[4 * k + 2]) for k in range(nf)]
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    me.update()
    flat = nv > 1.5 * nf  # source was flat-shaded (split vertices)
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    bpy.context.view_layer.objects.active = ob
    for o in bpy.context.scene.objects: o.select_set(o == ob)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.remove_doubles(threshold=0.0002)
    bpy.ops.object.mode_set(mode="OBJECT")
    ratio = min(1.0, RATIO.get(name, 0.4) * SCALE)
    mod = ob.modifiers.new("Dec", "DECIMATE")
    mod.decimate_type = "COLLAPSE"
    mod.ratio = ratio
    mod.use_collapse_triangulate = True
    bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.quads_convert_to_tris()
    bpy.ops.object.mode_set(mode="OBJECT")
    for p in ob.data.polygons: p.use_smooth = not flat
    r, g, b = [int(x) / 255 for x in pal[0].split(",")]
    col = ob.data.color_attributes.new("Col", "FLOAT_COLOR", "CORNER")
    # Roblox reads glTF COLOR_0 as sRGB, so write the sRGB values straight in (no linear conversion).
    # Upload 1 (asset 77064856899132) used srgb_to_linear and came out too dark.
    raw = (r, g, b, 1.0)
    for d in col.data: d.color = raw
    ob.data.color_attributes.active_color = col
    mat = bpy.data.materials.new(name + "_mat")
    ob.data.materials.append(mat)
    report.append(f"{name} {meshid} {nf} -> {len(ob.data.polygons)} ({'flat' if flat else 'smooth'})")

opts = dict(filepath=OUT, export_format="GLB", use_selection=False, export_apply=True, export_yup=True)
props = bpy.ops.export_scene.gltf.get_rna_type().properties.keys()
if "export_vertex_color" in props:
    opts["export_vertex_color"] = "ACTIVE"
if "export_all_vertex_colors" in props:
    opts["export_all_vertex_colors"] = False
if "export_colors" in props:
    opts["export_colors"] = True
bpy.ops.export_scene.gltf(**{k: v for k, v in opts.items() if k == "filepath" or k in props})
tot0 = sum(int(r.split()[2]) for r in report)
tot1 = sum(int(r.split()[4]) for r in report)
print("REPORT_BEGIN")
print("\n".join(report))
print(f"TOTAL {tot0} -> {tot1}")
print("REPORT_END")
