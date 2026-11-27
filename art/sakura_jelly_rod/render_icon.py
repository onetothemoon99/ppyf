# Product icon for the Sakura Jellyfish rod (Developer Product image, 512x512 PNG). 2026-11-26 (copied from art/phoenix_rod/render_icon.py)
# Run: blender.exe -b --factory-startup -P render_icon.py -- <outdir> [gift]
#   gift = also put a red gift box with a gold ribbon in the corner (for the "send to a friend" product)
import bpy, math, sys, os
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = args[0] if args else os.path.dirname(os.path.abspath(__file__))
GIFT = "gift" in args
HERE = os.path.dirname(os.path.abspath(__file__))
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o, do_unlink=True)

def imp(name):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=os.path.join(HERE, name))
    objs = [o for o in bpy.data.objects if o not in before]
    root = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(root)
    for o in objs:
        if o.parent is None:
            o.parent = root
    return root, objs

def lin(c):
    c = c / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

def mat(name, rgb, emit=0.0, rough=0.45, metal=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    col = tuple(lin(v) for v in rgb) + (1.0,)
    b.inputs["Base Color"].default_value = col
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    if emit > 0:
        b.inputs["Emission Color"].default_value = col
        b.inputs["Emission Strength"].default_value = emit
    return m

# glow / metal tweaks on the imported materials (names come from the build script)
TWEAK = {"Core": dict(emit=5.0), "Bell": dict(emit=0.5, rough=0.15), "Frill": dict(emit=0.4), "Tentacle": dict(emit=0.35),
         "RoseGold": dict(metal=0.85, rough=0.3), "Pearl": dict(rough=0.12, metal=0.2), "Stamen": dict(emit=0.5), "Eye": dict(rough=0.2)}

rod, rod_objs = imp("SakuraJellyRod.glb")
bob, bob_objs = imp("SakuraJellyBobber.glb")
for o in rod_objs + bob_objs:
    for slot in o.material_slots:
        m = slot.material
        if not m or not m.use_nodes:
            continue
        key = m.name.split(".")[0]
        b = next((n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
        t = TWEAK.get(key)
        if b and t:
            if "emit" in t:
                b.inputs["Emission Color"].default_value = b.inputs["Base Color"].default_value
                b.inputs["Emission Strength"].default_value = t["emit"]
            if "metal" in t:
                b.inputs["Metallic"].default_value = t["metal"]
            if "rough" in t:
                b.inputs["Roughness"].default_value = t["rough"]

# rod diagonal: tip top-right, handle bottom-left; camera looks along +Y
rod.rotation_euler = (0, math.radians(40), 0)
rod.location = (-1.85, 0, -2.0)
bob.scale = (2.6, 2.6, 2.6)
bob.location = (2.05, -0.5, -2.35)
bob.rotation_euler = (0, 0, math.radians(20))

# background: radial warm glow on a plane behind
bg = bpy.data.meshes.new("BG")
bpy.ops.mesh.primitive_plane_add(size=30, location=(0, 6, 0), rotation=(math.radians(90), 0, 0))
plane = bpy.context.active_object
m = bpy.data.materials.new("BGMat")
m.use_nodes = True
nt = m.node_tree
for n in list(nt.nodes):
    nt.nodes.remove(n)
out = nt.nodes.new("ShaderNodeOutputMaterial")
em = nt.nodes.new("ShaderNodeEmission")
ramp = nt.nodes.new("ShaderNodeValToRGB")
grad = nt.nodes.new("ShaderNodeTexGradient")
grad.gradient_type = 'SPHERICAL'
mapping = nt.nodes.new("ShaderNodeMapping")
coord = nt.nodes.new("ShaderNodeTexCoord")
mapping.inputs["Scale"].default_value = (0.16, 0.16, 0.16)
mapping.inputs["Location"].default_value = (0, 0, 0)
nt.links.new(coord.outputs["Object"], mapping.inputs["Vector"])
nt.links.new(mapping.outputs["Vector"], grad.inputs["Vector"])
nt.links.new(grad.outputs["Fac"], ramp.inputs["Fac"])
ramp.color_ramp.elements[0].color = (lin(45), lin(10), lin(45), 1)
ramp.color_ramp.elements[1].color = (lin(255), lin(190), lin(225), 1)
ramp.color_ramp.elements[1].position = 0.92
mid = ramp.color_ramp.elements.new(0.55)
mid.color = (lin(190), lin(60), lin(130), 1)
nt.links.new(ramp.outputs["Color"], em.inputs["Color"])
em.inputs["Strength"].default_value = 1.0
nt.links.new(em.outputs["Emission"], out.inputs["Surface"])
plane.data.materials.append(m)

# sparks: small glowing spheres scattered
import random
random.seed(7)
spark = mat("Spark", (255, 170, 60), emit=4.0)
for i in range(22):
    x, z = random.uniform(-3.8, 3.8), random.uniform(-3.8, 3.8)
    if abs(x - z * 0.9) < 0.6:  # keep off the rod line
        continue
    r = random.uniform(0.02, 0.05)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=(x, 2.5, z), segments=8, ring_count=6)
    bpy.context.active_object.data.materials.append(spark)

if GIFT:
    red = mat("GiftRed", (220, 40, 50), rough=0.4)
    gold = mat("GiftGold", (250, 200, 70), rough=0.25, metal=0.8)
    c = Vector((-2.35, -0.6, 2.35))
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=c)
    box = bpy.context.active_object
    box.scale = (1.3, 1.3, 1.1)
    box.data.materials.append(red)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=c + Vector((0, 0, 0.62)))
    lid = bpy.context.active_object
    lid.scale = (1.45, 1.45, 0.28)
    lid.data.materials.append(red)
    for sx, sy in ((0.24, 1.47), (1.47, 0.24)):
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=c + Vector((0, 0, 0.08)))
        rb = bpy.context.active_object
        rb.scale = (sx, sy, 1.34)
        rb.data.materials.append(gold)
    for ang in (35, -35):
        bpy.ops.mesh.primitive_torus_add(major_radius=0.32, minor_radius=0.09, location=c + Vector((math.sin(math.radians(ang)) * 0.3, 0, 1.0)),
                                         rotation=(math.radians(90), math.radians(ang), 0))
        bpy.context.active_object.data.materials.append(gold)
    for o in (box, lid):
        o.rotation_euler = (0, 0, math.radians(18))

# lights + camera
scn = bpy.context.scene
for name, loc, energy, col in (("Key", (-3, -6, 5), 1600, (1, 0.92, 0.8)), ("Rim", (4, 3, 3), 600, (1, 0.55, 0.8)), ("Fill", (3, -6, -2), 600, (1, 0.85, 0.7))):
    L = bpy.data.lights.new(name, 'AREA')
    L.energy, L.size, L.color = energy, 4, col
    lo = bpy.data.objects.new(name, L)
    lo.location = loc
    lo.rotation_euler = (Vector((0, 0, 0)) - Vector(loc)).to_track_quat('-Z', 'Y').to_euler()
    scn.collection.objects.link(lo)
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
cam.data.type = 'ORTHO'
cam.data.ortho_scale = 7.6
cam.location = (0, -12, 0)
cam.rotation_euler = (math.radians(90), 0, 0)
scn.collection.objects.link(cam)
scn.camera = cam

engines = [i.identifier for i in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
scn.render.engine = next((e for e in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE") if e in engines), "CYCLES")
print("ENGINE", scn.render.engine)
try:
    scn.eevee.use_bloom = True
except Exception:
    pass
try:
    scn.view_settings.view_transform = 'AgX'
    scn.view_settings.look = 'AgX - Punchy'
except Exception:
    try:
        scn.view_settings.view_transform = 'Filmic'
    except Exception:
        pass
scn.render.resolution_x = scn.render.resolution_y = 512
scn.render.film_transparent = False
scn.render.image_settings.file_format = 'PNG'
scn.render.filepath = os.path.join(OUT, "icon_SakuraJellyRod_gift.png" if GIFT else "icon_SakuraJellyRod.png")
bpy.ops.render.render(write_still=True)
print("WROTE", scn.render.filepath)
