# Small flying fire phoenix that orbits the player holding the Phoenix rod (client effect). 2026-11-19
# Run:  blender.exe -b --factory-startup -P build_phoenix_bird.py -- <outdir>
# Units: 1 Blender unit = 1 stud. Front (beak) = -Y  (Roblox -Z = LookVector after import). Up = +Z.
# Pieces (objects "<Piece>__<Material>"): Body, WingL (+X side), WingR (-X side). Wings are built around their
#   shoulder joint; SHOULDER_L / SHOULDER_R below are written to Studio attributes so the client can flap them.
# Output: PhoenixBird.glb + preview_PhoenixBird.png
import bpy, bmesh, math, sys, os
from mathutils import Vector, Matrix, Euler

OUT = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else os.path.dirname(os.path.abspath(__file__))
os.makedirs(OUT, exist_ok=True)
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o, do_unlink=True)

def lin(c):
    c = c / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

COLORS = {
    "FeatherRed": (222, 46, 36), "FeatherOrange": (255, 128, 30), "FeatherYellow": (255, 212, 70),
    "Flame": (255, 236, 150), "Head": (255, 160, 40), "Beak": (255, 222, 120), "Eye": (30, 18, 18), "Gold": (246, 196, 72),
}
MATS = {}
for name, rgb in COLORS.items():
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    col = tuple(lin(v) for v in rgb) + (1.0,)
    next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED").inputs["Base Color"].default_value = col
    m.diffuse_color = col
    MATS[name] = m

BM = {}
PIECE = "Body"
def target(mat):
    assert mat in COLORS, mat
    return BM.setdefault((PIECE, mat), bmesh.new())

def xf(loc=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1)):
    S = Matrix.Diagonal((scale[0], scale[1], scale[2], 1.0))
    return Matrix.Translation(Vector(loc)) @ Euler(tuple(math.radians(a) for a in rot), 'XYZ').to_matrix().to_4x4() @ S

def sph(mat, scale, loc, rot=(0, 0, 0), seg=12, rings=8):
    if isinstance(scale, (int, float)):
        scale = (scale, scale, scale)
    r = bmesh.ops.create_uvsphere(target(mat), u_segments=seg, v_segments=rings, radius=1.0, matrix=xf(loc, rot, scale))
    for v in r["verts"]:
        for f in v.link_faces:
            f.smooth = True

def cone(mat, r1, depth, loc, rot, seg=8):
    bmesh.ops.create_cone(target(mat), cap_ends=True, cap_tris=True, segments=seg, radius1=r1, radius2=0.0001, depth=depth, matrix=xf(loc, rot))

def tube(mat, pts, radii, seg=8, normal=(0, 0, 1), flat=1.0):
    bm = target(mat)
    pts = [Vector(p) for p in pts]
    n = len(pts)
    nv = Vector(normal).normalized()
    rings = []
    for i, p in enumerate(pts):
        t = (pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]).normalized()
        a = t.cross(nv)
        if a.length < 1e-5:
            a = t.cross(Vector((1, 0, 0)))
        a.normalize()
        b = a.cross(t).normalized()
        w = radii[i]
        th = max(w * flat, 0.004)
        rings.append([bm.verts.new(p + a * (math.cos(2 * math.pi * k / seg) * w) + b * (math.sin(2 * math.pi * k / seg) * th)) for k in range(seg)])
    faces = []
    for i in range(n - 1):
        r0, r1 = rings[i], rings[i + 1]
        for k in range(seg):
            f = bm.faces.new((r0[k], r0[(k + 1) % seg], r1[(k + 1) % seg], r1[k]))
            f.smooth = True
            faces.append(f)
    faces.append(bm.faces.new(list(reversed(rings[0]))))
    faces.append(bm.faces.new(rings[-1]))
    bmesh.ops.recalc_face_normals(bm, faces=faces)

def bez(p0, p1, p2, n):
    p0, p1, p2 = Vector(p0), Vector(p1), Vector(p2)
    return [(1 - t) ** 2 * p0 + 2 * (1 - t) * t * p1 + t * t * p2 for t in [i / (n - 1) for i in range(n)]]

def feather(mat, p0, p1, p2, width, normal, n=8, flat=0.25):
    pts = bez(p0, p1, p2, n)
    prof = [width * max(0.1, math.sin(math.pi * min(1.0, (i / (n - 1)) * 1.2) ** 0.8) * (1 - 0.8 * i / (n - 1))) for i in range(n)]
    prof[-1] = 0.004
    tube(mat, pts, prof, normal=normal, flat=flat)

# ------------------------------------------------------------------ body (Body piece)
PIECE = "Body"
sph("FeatherRed", (0.17, 0.3, 0.17), (0, 0.02, 0))                       # torso, long along Y
sph("FeatherYellow", (0.13, 0.22, 0.11), (0, -0.02, -0.07))               # belly
sph("Head", (0.13, 0.13, 0.13), (0, -0.3, 0.13))                          # head
cone("Beak", 0.045, 0.16, (0, -0.47, 0.11), (90, 0, 0))                   # beak points -Y
for s in (1, -1):
    sph("Eye", 0.028, (s * 0.1, -0.37, 0.17), seg=8, rings=6)
# crest: flame feathers up and back
for dx, col, L in ((0, "FeatherRed", 0.42), (0.05, "FeatherOrange", 0.32), (-0.05, "FeatherOrange", 0.32)):
    p0 = Vector((dx, -0.3, 0.24))
    feather(col, p0, p0 + Vector((dx, 0.05, 0.2)), p0 + Vector((dx * 2, L * 0.7, L * 0.55)), 0.07, normal=(1, 0, 0))
feather("Flame", Vector((0, -0.29, 0.25)), Vector((0, -0.25, 0.4)), Vector((0, -0.1, 0.48)), 0.04, normal=(1, 0, 0), flat=0.5)
# tail: long trailing plumes (+Y), fanning and curling up at the ends
for k, (ang, col, L, w) in enumerate(((0, "FeatherRed", 1.05, 0.1), (16, "FeatherOrange", 0.92, 0.09), (-16, "FeatherOrange", 0.92, 0.09),
                                       (30, "FeatherYellow", 0.75, 0.08), (-30, "FeatherYellow", 0.75, 0.08))):
    a = math.radians(ang)
    d = Vector((math.sin(a), math.cos(a), 0))
    p0 = Vector((0, 0.26, 0.02))
    feather(col, p0, p0 + d * L * 0.55 + Vector((0, 0, -0.06)), p0 + d * L + Vector((0, 0, 0.18)), w, normal=(0, 0, 1))
# gold "eye" spots at the long tail tips
for ang, L in ((0, 1.05), (16, 0.92), (-16, 0.92)):
    a = math.radians(ang)
    sph("Gold", (0.035, 0.035, 0.02), Vector((0, 0.26, 0.02)) + Vector((math.sin(a), math.cos(a), 0)) * L * 0.8 + Vector((0, 0, 0.1)), seg=8, rings=6)

# ------------------------------------------------------------------ wings (built around the shoulder, spread along +-X)
SHOULDER_L = Vector((0.12, -0.04, 0.08))
SHOULDER_R = Vector((-0.12, -0.04, 0.08))
for PIECE, sh, s in (("WingL", SHOULDER_L, 1), ("WingR", SHOULDER_R, -1)):
    sph("FeatherRed", (0.08, 0.13, 0.05), sh + Vector((s * 0.05, 0.02, 0)))
    for layer, col, scale, w, dz in ((0, "FeatherRed", 1.0, 0.11, 0.0), (1, "FeatherOrange", 0.72, 0.1, 0.02), (2, "FeatherYellow", 0.45, 0.08, 0.04)):
        for ang, L in ((8, 0.85), (25, 0.9), (42, 0.8), (60, 0.62)):
            a = math.radians(ang)
            d = Vector((s * math.cos(a), math.sin(a), 0))           # outward and back
            p0 = sh + Vector((0, 0, dz))
            p1 = p0 + d * L * scale * 0.5 + Vector((0, -0.03, 0.05))
            p2 = p0 + d * L * scale + Vector((0, 0.04, 0.1 + 0.03 * layer))
            feather(col, p0, p1, p2, w, normal=(0, 0, 1))

# ------------------------------------------------------------------ export
objs = []
for (piece, mat), bm in BM.items():
    me = bpy.data.meshes.new(piece + "__" + mat)
    bm.to_mesh(me)
    bm.free()
    me.materials.append(MATS[mat])
    ob = bpy.data.objects.new(piece + "__" + mat, me)
    bpy.context.scene.collection.objects.link(ob)
    objs.append(ob)
tri = 0
for ob in objs:
    ob.data.calc_loop_triangles()
    tri += len(ob.data.loop_triangles)
allv = [v.co for ob in objs for v in ob.data.vertices]
lo = Vector(tuple(min(c[k] for c in allv) for k in range(3)))
hi = Vector(tuple(max(c[k] for c in allv) for k in range(3)))
print("MODEL PhoenixBird OBJECTS", len(objs), "TRIS", tri, "BBOX_MIN", tuple(round(v, 3) for v in lo), "BBOX_MAX", tuple(round(v, 3) for v in hi))
print("SHOULDER_L", tuple(SHOULDER_L), "SHOULDER_R", tuple(SHOULDER_R))
bpy.ops.object.select_all(action='DESELECT')
for ob in objs:
    ob.select_set(True)
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "PhoenixBird.glb"), export_format='GLB', use_selection=True, export_apply=True, export_yup=True)

scn = bpy.context.scene
scn.render.engine = 'BLENDER_WORKBENCH'
scn.display.shading.light = 'STUDIO'
scn.display.shading.color_type = 'MATERIAL'
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
scn.collection.objects.link(cam)
scn.camera = cam
mid = (lo + hi) / 2
size = (hi - lo).length
scn.render.resolution_x, scn.render.resolution_y = 900, 700
cam.data.lens = 40
cam.location = mid + Vector((-0.8, -1.0, 0.9)).normalized() * size * 1.3
cam.rotation_euler = (mid - cam.location).to_track_quat('-Z', 'Y').to_euler()
scn.render.filepath = os.path.join(OUT, "preview_PhoenixBird.png")
bpy.ops.render.render(write_still=True)
