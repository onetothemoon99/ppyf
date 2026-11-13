# Turquoise water sheet for the narrow left channel round the oval plot (same look as the main stream sheet).
# Faces point up (+Z Blender = +Y Roblox). Each mesh's world centre is printed as CENTRE name x z for placement.
import bpy, bmesh, math, sys, os
from mathutils import Vector

OUT = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else os.path.dirname(os.path.abspath(__file__))
# 2026-11-12: "onesheet" after <outdir> = every band in one welded mesh (Water_Mid) -> <Name>_One.glb. Separate band MeshParts left dotted dark seams in Roblox.
ONE = "onesheet" in sys.argv
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
PTS = [(384, -38), (376, -48), (362, -56), (350, -72), (338, -94), (326, -114), (314, -128), (302, -138), (290, -144), (278, -148), (266, -151), (254, -148), (242, -146), (230, -140), (218, -131), (206, -122), (194, -105), (182, -83), (170, -80), (158, -81)]
HW = [10, 9, 12, 16, 18, 14, 12, 10, 8, 8, 9, 8, 10, 10, 11, 12, 17, 19, 16, 13]
INSET = 0.8          # sheet edge 1.5 inside the grass line
END_R = 13

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
    bm = BM.setdefault("Water_Mid" if ONE else mat, bmesh.new())
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
objs = []
for mat, bm in BM.items():
    me = bpy.data.meshes.new("RingWater__" + mat)
    if ONE: bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.01)
    bm.to_mesh(me); bm.free()
    me.materials.append(MATS[mat])
    ob = bpy.data.objects.new("RingWater__" + mat, me)
    bpy.context.scene.collection.objects.link(ob)
    objs.append(ob)
    xs = [v.co.x for v in me.vertices]; ys = [v.co.y for v in me.vertices]
    print("CENTRE", mat, round(-(min(xs) + max(xs)) / 2, 3), round((min(ys) + max(ys)) / 2, 3), "SIZE", round(max(xs) - min(xs), 2), round(max(ys) - min(ys), 2))
if ONE:  # 2026-11-12: cut away what lies inside the waterfall pool (no double sheets in front of the waterfall)
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import water_clip
    water_clip.clip_all(objs, os.path.dirname(os.path.abspath(__file__)))
bpy.ops.object.select_all(action='DESELECT')
for ob in objs:
    ob.select_set(True)
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "RingWater" + ("_One" if ONE else "") + ".glb"), export_format='GLB', use_selection=True, export_apply=True, export_yup=True)
