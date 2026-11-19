# Dragonfly that darts around the player holding the Little Frog rod (client effect). 2026-11-19 (from build_phoenix_bird.py)
# Run:  blender.exe -b --factory-startup -P build_dragonfly.py -- <outdir>
# Units: 1 Blender unit = 1 stud. Front (beak) = -Y  (Roblox -Z = LookVector after import). Up = +Z.
# Pieces (objects "<Piece>__<Material>"): Body, WingL (+X side), WingR (-X side). Wings are built around their
#   shoulder joint; SHOULDER_L / SHOULDER_R below are written to Studio attributes so the client can flap them.
# Output: Dragonfly.glb + preview_Dragonfly.png
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
    "DFBody": (60, 190, 205), "DFDark": (25, 105, 135), "DFEye": (70, 215, 130), "Eye": (20, 30, 30),
    "Wing": (205, 238, 255), "WingEdge": (120, 200, 230), "Gold": (246, 196, 72),
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

# ------------------------------------------------------------------ body (Body piece): head at -Y, long tail toward +Y
PIECE = "Body"
for s in (1, -1):
    sph("DFEye", (0.075, 0.07, 0.07), (s * 0.055, -0.27, 0.03))                # big compound eyes
    sph("Eye", (0.02, 0.02, 0.02), (s * 0.09, -0.31, 0.06), seg=8, rings=6)   # shine dot
sph("DFBody", (0.06, 0.055, 0.055), (0, -0.21, 0.0))                          # face
sph("DFBody", (0.085, 0.12, 0.08), (0, -0.08, 0.0))                           # thorax
sph("Gold", (0.02, 0.07, 0.012), (0, -0.08, 0.075), seg=8, rings=5)           # gold stripe on the back
pts = [(0, 0.02 + 0.075 * i, -0.005 * i) for i in range(12)]
tube("DFBody", pts, [0.045 * (1 - 0.55 * i / 11) for i in range(12)], seg=8)   # abdomen
for i in range(1, 11, 2):                                                     # dark rings on the abdomen
    sph("DFDark", (0.046 * (1 - 0.55 * i / 11), 0.016, 0.046 * (1 - 0.55 * i / 11)), pts[i], seg=8, rings=5)
sph("DFDark", (0.018, 0.03, 0.018), pts[-1], seg=6, rings=4)
# ------------------------------------------------------------------ wings: front + back pair per side, hinged at the thorax
SHOULDER_L = Vector((0.07, -0.1, 0.05))
SHOULDER_R = Vector((-0.07, -0.1, 0.05))
for PIECE, sh, s in (("WingL", SHOULDER_L, 1), ("WingR", SHOULDER_R, -1)):
    for dy, L, w, ang in ((-0.03, 0.62, 0.085, -8), (0.06, 0.56, 0.095, 12)):
        a = math.radians(ang)
        c = sh + Vector((s * L * 0.5 * math.cos(a), dy + L * 0.5 * math.sin(a), 0.005))
        sph("Wing", (L * 0.5, w, 0.006), c, rot=(0, 0, s * ang), seg=16, rings=6)
        tip = sh + Vector((s * L * 0.92 * math.cos(a), dy + L * 0.92 * math.sin(a), 0.008))
        sph("WingEdge", (0.035, 0.022, 0.007), tip, rot=(0, 0, s * ang), seg=8, rings=4)   # coloured wing tip spot
        tube("WingEdge", [sh + Vector((s * 0.02, dy, 0.012)), tip], [0.006, 0.003], seg=4)   # leading vein

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
print("MODEL Dragonfly OBJECTS", len(objs), "TRIS", tri, "BBOX_MIN", tuple(round(v, 3) for v in lo), "BBOX_MAX", tuple(round(v, 3) for v in hi))
print("SHOULDER_L", tuple(SHOULDER_L), "SHOULDER_R", tuple(SHOULDER_R))
bpy.ops.object.select_all(action='DESELECT')
for ob in objs:
    ob.select_set(True)
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "Dragonfly.glb"), export_format='GLB', use_selection=True, export_apply=True, export_yup=True)

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
scn.render.filepath = os.path.join(OUT, "preview_Dragonfly.png")
bpy.ops.render.render(write_still=True)
