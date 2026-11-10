# Cartoon 3-tier plaza fountain (from the user's picture: white-blue stone basin, blue water, two bowls,
# crystal-drop top, round paved plaza). Run:
#   blender.exe -b --factory-startup -P build_fountain.py -- <outdir>
# Units: 1 Blender unit = 1 stud, Z up, origin = centre of the fountain at ground level (z = 0).
# Mesh objects are named "Fountain__<Material>"; Studio colours them from COLORS (the importer drops colours).
# Roblox culls back faces: every lathe face is oriented outward from the solid (see lathe()).
import bpy, bmesh, math, random, sys, os
from mathutils import Vector

OUT = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else os.path.dirname(os.path.abspath(__file__))
os.makedirs(OUT, exist_ok=True)
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o, do_unlink=True)

def lin(c):
    c = c / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

COLORS = {
    "Stone_Top": (242, 246, 250), "Stone_Side": (208, 220, 234), "Stone_Shadow": (164, 180, 204),
    "Stone_Trim": (126, 176, 226),
    "Pave_Light": (240, 222, 196), "Pave_Mid": (226, 200, 168), "Pave_Dark": (206, 176, 142), "Pave_Grout": (178, 148, 116),
    "Water_Deep": (34, 128, 226), "Water_Mid": (64, 166, 244), "Water_Light": (140, 212, 252), "Water_White": (236, 248, 255),
    "Fall_Light": (150, 214, 252), "Fall_White": (232, 246, 255),
    "Crystal_Light": (200, 236, 255), "Crystal_Mid": (120, 190, 246),
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
def face(mat, pts):
    bm = BM.setdefault(mat, bmesh.new())
    vs = [bm.verts.new(Vector(p)) for p in pts]
    try:
        bm.faces.new(vs)
    except ValueError:
        pass

def newell(pts):
    n = Vector()
    for i in range(len(pts)):
        a, b = pts[i], pts[(i + 1) % len(pts)]
        n.x += (a.y - b.y) * (a.z + b.z)
        n.y += (a.z - b.z) * (a.x + b.x)
        n.z += (a.x - b.x) * (a.y + b.y)
    return n

LIGHT = Vector((-0.4, -0.6, 0.7)).normalized()
STONE = ("Stone_Top", "Stone_Side", "Stone_Shadow")
def tone(n, tones=STONE):
    n = n.normalized()
    if n.z > 0.65:
        return tones[0]
    return tones[1] if n.dot(LIGHT) > -0.15 else tones[2]

def put(mat, pts, want):
    """Add a face whose normal points along `want` (flips the winding if needed). mat may be a tones tuple."""
    pts = [Vector(p) for p in pts]
    n = newell(pts)
    if n.dot(want) < 0:
        pts.reverse()
        n = -n
    if n.length < 1e-9:
        return
    face(tone(n, mat) if isinstance(mat, tuple) else mat, pts)

def lathe(mat, prof, seg=40, closed=True, phase=0.0, span=2 * math.pi):
    """Revolve a profile [(r, z), ...] around Z. closed=True: the profile is a CCW polygon in the (r, z) plane
    (a solid ring); faces point out of the solid. closed=False: an open surface whose faces point along the
    profile's left normal (-dz, dr)."""
    m = len(prof)
    n_edges = m if closed else m - 1
    area = sum(prof[i][0] * prof[(i + 1) % m][1] - prof[(i + 1) % m][0] * prof[i][1] for i in range(m)) / 2
    sgn = 1 if area > 0 else -1
    for k in range(seg):
        a0, a1 = phase + span * k / seg, phase + span * (k + 1) / seg
        am = (a0 + a1) / 2
        for i in range(n_edges):
            (r0, z0), (r1, z1) = prof[i], prof[(i + 1) % m]
            dr, dz = r1 - r0, z1 - z0
            nr, nz = (dz * sgn, -dr * sgn) if closed else (-dz, dr)
            want = Vector((nr * math.cos(am), nr * math.sin(am), nz))
            pts = [(r0 * math.cos(a0), r0 * math.sin(a0), z0), (r0 * math.cos(a1), r0 * math.sin(a1), z0),
                   (r1 * math.cos(a1), r1 * math.sin(a1), z1), (r1 * math.cos(a0), r1 * math.sin(a0), z1)]
            if r0 < 1e-6:
                pts = pts[1:] if True else pts
                pts = [(0, 0, z0), (r1 * math.cos(a1), r1 * math.sin(a1), z1), (r1 * math.cos(a0), r1 * math.sin(a0), z1)]
            elif r1 < 1e-6:
                pts = [(r0 * math.cos(a0), r0 * math.sin(a0), z0), (r0 * math.cos(a1), r0 * math.sin(a1), z0), (0, 0, z1)]
            put(mat(k, i) if callable(mat) else mat, pts, want)

def disc(mat, r_in, r_out, z, seg=40, up=True):
    lathe(mat, [(r_in, z), (r_out, z)] if up else [(r_out, z), (r_in, z)], seg=seg, closed=False)

# ------------------------------------------------------------------ dimensions
R_PAVE = 30.0
R_STEP1, R_STEP2 = 17.4, 16.2
Z_STEP1, Z_STEP2 = 0.9, 1.8
R_OUT, R_IN = 15.0, 12.6           # basin wall
Z_RIM = 4.6
Z_POOL = 4.0

# ------------------------------------------------------------------ paving (rings of tiles + grout disc)
rnd = random.Random(7)
disc("Pave_Grout", 0.0, R_PAVE, 0.12, seg=48)
rings = [(R_STEP1 + 0.2, 20.2), (20.4, 23.0), (23.2, 25.9), (26.1, 28.0), (28.2, R_PAVE)]
for ri, (a, b) in enumerate(rings):
    count = int(2 * math.pi * (a + b) / 2 / 3.2)
    off = rnd.random() * 2 * math.pi
    for t in range(count):
        g = 0.09
        t0 = off + 2 * math.pi * t / count + g / ((a + b) / 2)
        t1 = off + 2 * math.pi * (t + 1) / count - g / ((a + b) / 2)
        mat = ("Pave_Light", "Pave_Mid", "Pave_Light", "Pave_Dark")[(t + ri) % 4] if ri < 4 else "Pave_Mid"
        h = 0.32 + rnd.uniform(-0.02, 0.02)
        steps = 3
        top, bot = [], []
        for s in range(steps + 1):
            th = t0 + (t1 - t0) * s / steps
            top.append((th, h))
        poly = [((a + 0.06) * math.cos(th), (a + 0.06) * math.sin(th), z) for th, z in top] + \
               [((b - 0.06) * math.cos(th), (b - 0.06) * math.sin(th), z) for th, z in reversed(top)]
        put(mat, poly, Vector((0, 0, 1)))
        # outer edge of the tile (gives the tiles a little thickness on the grout)
        for s in range(steps):
            th0, th1 = top[s][0], top[s + 1][0]
            for rr, sgn in ((b - 0.06, 1), (a + 0.06, -1)):
                p = [(rr * math.cos(th0), rr * math.sin(th0), 0.12), (rr * math.cos(th1), rr * math.sin(th1), 0.12),
                     (rr * math.cos(th1), rr * math.sin(th1), h), (rr * math.cos(th0), rr * math.sin(th0), h)]
                thm = (th0 + th1) / 2
                put("Pave_Grout", p, Vector((sgn * math.cos(thm), sgn * math.sin(thm), 0)))

# ------------------------------------------------------------------ stepped plinth + basin (solid rings, CCW in (r, z))
lathe(STONE, [(R_STEP2, 0.0), (R_STEP1, 0.0), (R_STEP1, Z_STEP1), (R_STEP2, Z_STEP1)], seg=48)
lathe(STONE, [(R_OUT + 0.4, Z_STEP1), (R_STEP2, Z_STEP1), (R_STEP2, Z_STEP2), (R_OUT + 0.4, Z_STEP2)][::-1], seg=48)
# basin wall with a bulged rim
basin = [(R_IN, Z_STEP2), (R_OUT, Z_STEP2), (R_OUT, Z_RIM - 0.9), (R_OUT + 0.5, Z_RIM - 0.6),
         (R_OUT + 0.5, Z_RIM), (R_OUT - 0.1, Z_RIM + 0.35), (R_IN + 0.1, Z_RIM + 0.35), (R_IN - 0.3, Z_RIM), (R_IN - 0.3, Z_RIM - 0.4), (R_IN, Z_RIM - 0.6)]
lathe(STONE, basin, seg=48)
# blue tile band round the basin wall
lathe("Stone_Trim", [(R_OUT - 0.05, 2.5), (R_OUT + 0.12, 2.5), (R_OUT + 0.12, 3.1), (R_OUT - 0.05, 3.1)], seg=48)
# pool floor (under the water, darker so the water reads deep)
disc("Water_Deep", 0.0, R_IN, Z_STEP2 + 0.05, seg=48)

# ------------------------------------------------------------------ pool water surface (rings) + ripples
def water_rings(rmax, z, seg=48, ripples=()):
    disc("Water_Deep", 0.0, rmax * 0.35, z, seg)
    disc("Water_Mid", rmax * 0.35, rmax * 0.75, z, seg)
    disc("Water_Light", rmax * 0.75, rmax, z, seg)
    for rr, w in ripples:
        disc("Water_White", rr - w / 2, rr + w / 2, z + 0.03, seg)
water_rings(R_IN - 0.25, Z_POOL, ripples=((10.6, 0.35), (11.6, 0.2), (5.2, 0.25)))

# ------------------------------------------------------------------ central column, middle bowl, top bowl
col = [(0.0, Z_STEP2), (3.6, Z_STEP2), (3.6, Z_STEP2 + 0.6), (2.6, Z_STEP2 + 1.0), (2.1, 4.5), (1.9, 6.5),
       (2.2, 7.4), (2.8, 7.8), (2.8, 8.3), (0.0, 8.3)]
lathe(STONE, col, seg=24)
Z_MB = 10.6       # middle bowl lip height
R_MB = 7.6
mbowl = [(0.0, 8.3), (2.4, 8.3), (4.8, 8.9), (6.6, 9.7), (R_MB, Z_MB - 0.2), (R_MB + 0.2, Z_MB + 0.2),
         (R_MB - 0.4, Z_MB + 0.45), (R_MB - 0.9, Z_MB + 0.2), (0.0, Z_MB - 0.1)]
lathe(STONE, mbowl, seg=40)
water_rings(R_MB - 0.9, Z_MB + 0.05, seg=40, ripples=((5.5, 0.25),))
lathe(STONE, [(0.0, Z_MB), (1.6, Z_MB), (1.6, Z_MB + 0.5), (1.1, Z_MB + 0.9), (1.0, 13.0), (1.4, 13.4), (0.0, 13.4)], seg=20)
Z_TB, R_TB = 14.6, 3.8
tbowl = [(0.0, 13.4), (1.6, 13.4), (3.0, 13.9), (R_TB, Z_TB - 0.1), (R_TB + 0.15, Z_TB + 0.2), (R_TB - 0.3, Z_TB + 0.4),
         (R_TB - 0.6, Z_TB + 0.2), (0.0, Z_TB)]
lathe(STONE, tbowl, seg=32)
water_rings(R_TB - 0.6, Z_TB + 0.05, seg=32)
# crystal drop on top (faceted, two tones by facet)
lathe(lambda k, i: "Crystal_Light" if k % 2 == 0 else "Crystal_Mid",
      [(0.0, Z_TB), (0.9, Z_TB), (1.25, Z_TB + 1.1), (1.0, Z_TB + 2.4), (0.45, Z_TB + 3.8), (0.0, Z_TB + 5.0)][::-1], seg=8, phase=0.2)

# ------------------------------------------------------------------ falling water sheets (outward-facing skirts)
def skirt(r_top, z_top, r_bot, z_bot, seg=40, bulge=0.6, streams=10, width=0.26):
    rows = 5
    prof = []
    for i in range(rows + 1):
        t = i / rows
        r = r_top + (r_bot - r_top) * t + bulge * math.sin(math.pi * t) * (1 - t * 0.3)
        z = z_top + (z_bot - z_top) * (t ** 1.4)
        prof.append((r, z))
    # open surface: profile goes downward, left normal (-dz, dr) points outward
    for s in range(streams):
        a = 2 * math.pi * s / streams + 0.3
        lathe(lambda k, i: "Fall_White" if k in (0, 3) else "Fall_Light", prof, seg=4, closed=False, phase=a, span=width * 2 * math.pi / streams * 1.6)
skirt(R_MB + 0.25, Z_MB + 0.1, R_MB + 1.4, Z_POOL + 0.05, bulge=0.8)
skirt(R_TB + 0.2, Z_TB + 0.2, R_TB + 0.9, Z_MB + 0.1, seg=32, bulge=0.5, streams=6, width=0.3)
# foam where the water lands
rnd = random.Random(3)
def foam_ring(r, z, n, size):
    for k in range(n):
        a = 2 * math.pi * k / n + rnd.uniform(-0.05, 0.05)
        t = bmesh.new()
        bmesh.ops.create_icosphere(t, subdivisions=1, radius=1.0)
        s = size * rnd.uniform(0.8, 1.2)
        for v in t.verts:
            v.co = Vector((v.co.x * s, v.co.y * s, v.co.z * s * 0.45)) + Vector((r * math.cos(a), r * math.sin(a), z))
        for f in t.faces:
            face("Water_White", [v.co.copy() for v in f.verts])
        t.free()
foam_ring(R_MB + 1.4, Z_POOL + 0.1, 30, 0.7)
foam_ring(R_TB + 0.9, Z_MB + 0.15, 16, 0.6)

# ------------------------------------------------------------------ build + export
objs, tri = [], 0
for mat, bm in BM.items():
    me = bpy.data.meshes.new("Fountain__" + mat)
    bm.to_mesh(me)
    bm.free()
    me.materials.append(MATS[mat])
    ob = bpy.data.objects.new("Fountain__" + mat, me)
    bpy.context.scene.collection.objects.link(ob)
    objs.append(ob)
    me.calc_loop_triangles()
    tri += len(me.loop_triangles)
allv = [v.co for ob in objs for v in ob.data.vertices]
print("OBJECTS", len(objs), "TRIS", tri)
print("BBOX_MIN", tuple(round(min(c[k] for c in allv), 4) for k in range(3)))
print("BBOX_MAX", tuple(round(max(c[k] for c in allv), 4) for k in range(3)))
bpy.ops.object.select_all(action='DESELECT')
for ob in objs:
    ob.select_set(True)
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "PlazaFountain.glb"), export_format='GLB',
                          use_selection=True, export_apply=True, export_yup=True)

scn = bpy.context.scene
scn.render.engine = 'BLENDER_WORKBENCH'
scn.display.shading.light = 'STUDIO'
scn.display.shading.color_type = 'MATERIAL'
scn.display.shading.show_backface_culling = True
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
scn.collection.objects.link(cam)
scn.camera = cam
def shot(path, loc, look, lens=35):
    scn.render.resolution_x, scn.render.resolution_y = 1000, 700
    cam.data.lens = lens
    cam.location = loc
    cam.rotation_euler = (Vector(look) - Vector(loc)).to_track_quat('-Z', 'Y').to_euler()
    scn.render.filepath = os.path.join(OUT, path)
    bpy.ops.render.render(write_still=True)
shot("preview_front.png", (0, -52, 26), (0, 0, 6))
shot("preview_close.png", (10, -26, 16), (0, 0, 8))
