# Sakura Jellyfish rod (เบ็ดแมงกะพรุนซากุระ, 199 R$, same stats as SunBee/Phoenix) + jelly bobber + 3D jellyfish fx. 2026-11-26
# Run:  blender.exe -b --factory-startup -P build_sakura_jelly.py -- <outdir>
# Units: 1 Blender unit = 1 stud.
#  SakuraJellyRod: built STRAIGHT UP along +Z, hand (Roblox Handle) at the origin, reel underside (-Y), line guides on top (+Y).
#                  Tip (line point) at (0, 0, 5.82). Studio tilts it like the other rods.
#  SakuraJellyBobber: origin = water line; dome above, tentacles below. LineAttach on the top flower (~z 0.3).
#  SakuraJelly (fx): radially symmetric, origin = bell rim centre (hinge for the tentacle sway). Pieces Bell / Arms / Tent.
# Objects are named "<Model>__<Material>"; Studio colours them from COLORS (the importer drops colours).
# Output: SakuraJellyRod.glb, SakuraJellyBobber.glb, SakuraJelly.glb + preview_*.png
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
    "PoleDeep": (214, 74, 138), "PolePink": (244, 138, 184), "PolePearl": (255, 206, 224),
    "Wrap": (150, 40, 96), "RoseGold": (232, 168, 148), "Pearl": (252, 244, 248),
    "Petal": (255, 196, 216), "PetalDeep": (246, 128, 172), "Stamen": (255, 226, 150),
    "Bell": (255, 160, 206), "Frill": (255, 120, 186), "Core": (255, 90, 170),
    "Tentacle": (255, 182, 222), "Arm": (250, 140, 196), "Eye": (60, 20, 50),
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
MODEL = "X"
def target(mat):
    assert mat in COLORS, mat
    return BM.setdefault((MODEL, mat), bmesh.new())

def xf(loc=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1)):
    S = Matrix.Diagonal((scale[0], scale[1], scale[2], 1.0))
    return Matrix.Translation(Vector(loc)) @ Euler(tuple(math.radians(a) for a in rot), 'XYZ').to_matrix().to_4x4() @ S

def smooth(verts):
    for v in verts:
        for f in v.link_faces:
            f.smooth = True

def sph(mat, scale, loc, rot=(0, 0, 0), seg=14, rings=9):
    if isinstance(scale, (int, float)):
        scale = (scale, scale, scale)
    r = bmesh.ops.create_uvsphere(target(mat), u_segments=seg, v_segments=rings, radius=1.0, matrix=xf(loc, rot, scale))
    smooth(r["verts"])

def sph_m(mat, M, seg=12, rings=8):
    r = bmesh.ops.create_uvsphere(target(mat), u_segments=seg, v_segments=rings, radius=1.0, matrix=M)
    smooth(r["verts"])

def cyl(mat, r1, r2, depth, loc, rot=(0, 0, 0), seg=14):
    r = bmesh.ops.create_cone(target(mat), cap_ends=True, cap_tris=False, segments=seg, radius1=r1, radius2=max(r2, 0.0001),
                              depth=depth, matrix=xf(loc, rot))
    for v in r["verts"]:
        for f in v.link_faces:
            if len(f.verts) == 4:
                f.smooth = True

def frame(t, normal):
    a = t.cross(normal)
    if a.length < 1e-5:
        a = t.cross(Vector((0, 1, 0)) if abs(t.y) < 0.9 else Vector((1, 0, 0)))
    a.normalize()
    b = a.cross(t).normalized()
    return a, b

def tube(mat, pts, radii, seg=8, closed=False, caps=True, normal=(0, 0, 1), flat=1.0):
    """Sweep an ellipse along a polyline. radii = width per point; flat = thickness / width (1 = round)."""
    bm = target(mat)
    pts = [Vector(p) for p in pts]
    n = len(pts)
    if isinstance(radii, (int, float)):
        radii = [radii] * n
    nv = Vector(normal).normalized()
    rings = []
    for i, p in enumerate(pts):
        t = (pts[(i + 1) % n] - pts[(i - 1) % n]) if closed else (pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)])
        t.normalize()
        a, b = frame(t, nv)
        w = radii[i]
        th = max(w * flat, 0.005) if flat < 1 else w
        rings.append([bm.verts.new(p + a * (math.cos(2 * math.pi * k / seg) * w) + b * (math.sin(2 * math.pi * k / seg) * th)) for k in range(seg)])
    faces = []
    for i in range(n if closed else n - 1):
        r0, r1 = rings[i], rings[(i + 1) % n]
        for k in range(seg):
            f = bm.faces.new((r0[k], r0[(k + 1) % seg], r1[(k + 1) % seg], r1[k]))
            f.smooth = True
            faces.append(f)
    if caps and not closed:
        faces.append(bm.faces.new(list(reversed(rings[0]))))
        faces.append(bm.faces.new(rings[-1]))
    bmesh.ops.recalc_face_normals(bm, faces=faces)

def lathe(mat, prof, center=(0, 0, 0), seg=24, closed=True):
    """Revolve a (r, z) profile around +Z. closed = join the last profile point back to the first (a shell)."""
    bm = target(mat)
    c = Vector(center)
    rings = [[bm.verts.new(c + Vector((r * math.cos(2 * math.pi * k / seg), r * math.sin(2 * math.pi * k / seg), z))) for k in range(seg)]
             for r, z in prof]
    faces = []
    n = len(rings)
    for i in range(n if closed else n - 1):
        r0, r1 = rings[i], rings[(i + 1) % n]
        for k in range(seg):
            f = bm.faces.new((r0[k], r0[(k + 1) % seg], r1[(k + 1) % seg], r1[k]))
            f.smooth = True
            faces.append(f)
    bmesh.ops.recalc_face_normals(bm, faces=faces)

def basis(center, normal):
    z = Vector(normal).normalized()
    x = z.cross(Vector((0, 0, 1)))
    if x.length < 1e-4:
        x = z.cross(Vector((1, 0, 0)))
    x.normalize()
    y = z.cross(x).normalized()
    M = Matrix.Identity(4)
    for i in range(3):
        M[i][0], M[i][1], M[i][2], M[i][3] = x[i], y[i], z[i], Vector(center)[i]
    return M

def flower(center, normal, size, petal="Petal", deep="PetalDeep", spin=0.0, cup=0.25):
    """Five-petal sakura blossom facing `normal`. Each petal has a darker notch tip and a pale base."""
    F = basis(center, normal)
    s = size
    for k in range(5):
        a = spin + 2 * math.pi * k / 5
        R = F @ Matrix.Rotation(a, 4, 'Z') @ Matrix.Rotation(-cup, 4, 'Y')
        sph_m(petal, R @ xf((0.5 * s, 0, 0.02 * s), (0, 0, 0), (0.5 * s, 0.34 * s, 0.07 * s)), seg=12, rings=7)
        for side in (1, -1):   # notch: two little lobes at the tip
            sph_m(deep, R @ xf((0.93 * s, side * 0.1 * s, 0.03 * s), (0, 0, side * 25), (0.1 * s, 0.07 * s, 0.05 * s)), seg=8, rings=5)
    sph_m("Stamen", F @ xf((0, 0, 0.06 * s), (0, 0, 0), (0.16 * s, 0.16 * s, 0.08 * s)), seg=10, rings=6)
    for k in range(7):
        a = spin + 2 * math.pi * k / 7
        p0 = F @ Vector((0.05 * s * math.cos(a), 0.05 * s * math.sin(a), 0.08 * s))
        p1 = F @ Vector((0.2 * s * math.cos(a), 0.2 * s * math.sin(a), 0.2 * s))
        tube("Stamen", [p0, p1], [0.012 * s / 0.15 * 0.15, 0.008], seg=4)
        sph("Stamen", 0.022 * s / 0.15, p1, seg=6, rings=4)

def bell_shell(mat, R, H, center, thick=0.06, flare=0.06, seg=28):
    """Jellyfish bell: rounded dome, rim flares out a little and curls under; open underneath."""
    outer, inner = [], []
    N = 12
    for i in range(N + 1):
        t = 0.06 + (math.pi / 2 - 0.06) * i / N
        outer.append((R * math.sin(t) * (1 + flare * (i / N) ** 3), H * math.cos(t)))
    outer.append((R * (1 + flare) * 0.99, -H * 0.06))
    for r, z in reversed(outer[:-1]):
        inner.append((max(r - thick, 0.01), z - thick * 0.7))
    lathe(mat, outer + inner, center=center, seg=seg)
    sph(mat, (R * math.sin(0.06) * 1.5, R * math.sin(0.06) * 1.5, thick * 0.6), Vector(center) + Vector((0, 0, H - thick * 0.3)), seg=10, rings=5)

def scallops(mat, R, z, n, size, center=(0, 0, 0)):
    c = Vector(center)
    for k in range(n):
        a = 2 * math.pi * (k + 0.5) / n
        sph(mat, (size, size * 0.8, size * 0.55), c + Vector((R * math.cos(a), R * math.sin(a), z)), rot=(0, 0, math.degrees(a)), seg=8, rings=5)

def wavy(p0, length, n, amp, freq, phase, drift=(0, 0)):
    """Points hanging down from p0 with a sideways sine wave (tentacle)."""
    p0 = Vector(p0)
    out = []
    for i in range(n):
        u = i / (n - 1)
        out.append(p0 + Vector((drift[0] * u + amp * u * math.sin(freq * u * math.pi + phase),
                                drift[1] * u + amp * u * math.cos(freq * u * math.pi + phase * 1.3), -length * u)))
    return out

# =================================================================== 1) SakuraJellyRod
MODEL = "SakuraJellyRod"
POLE_R = lambda z: 0.066 + (0.025 - 0.066) * (z - 1.0) / (5.5 - 1.0)

# butt: pearl in a rose-gold cup + three short ribbon tassels (kept short, away from the leg)
cyl("RoseGold", 0.13, 0.12, 0.07, (0, 0, -0.42))
sph("RoseGold", (0.115, 0.115, 0.06), (0, 0, -0.47))
sph("Pearl", 0.085, (0, 0, -0.56), seg=14, rings=9)
for k in range(3):
    a = math.radians(-90 + (k - 1) * 40)
    pts = wavy((0.05 * math.cos(a), 0.05 * math.sin(a), -0.6), 0.32, 8, 0.05, 2.0, k * 1.7, drift=(0.08 * math.cos(a), 0.08 * math.sin(a)))
    tube("Tentacle", pts, [0.03 * (1 - 0.75 * i / 7) for i in range(8)], seg=6, flat=0.35, normal=(math.cos(a), math.sin(a), 0))

# grip: deep-pink wrap with a rose-gold spiral and a pearl bead row
cyl("Wrap", 0.115, 0.105, 0.98, (0, 0, 0.07), seg=16)
helix_pts = []
for i in range(60):
    u = i / 59
    a = 2 * math.pi * 5 * u
    r = 0.113 + (0.104 - 0.113) * u
    helix_pts.append((r * math.cos(a), r * math.sin(a), -0.38 + 0.9 * u))
tube("RoseGold", helix_pts, 0.012, seg=6)
cyl("RoseGold", 0.125, 0.125, 0.05, (0, 0, 0.58), seg=16)
cyl("Pearl", 0.12, 0.085, 0.12, (0, 0, 0.66), seg=16)

# reel (underside -Y): pearl drum, deep-pink side plates with a sakura relief, rose-gold rim, pearl crank knob
REEL = Vector((0, -0.2, 0.82))
cyl("RoseGold", 0.035, 0.035, 0.16, (0, -0.1, 0.82), rot=(90, 0, 0), seg=8)
cyl("Pearl", 0.16, 0.16, 0.12, REEL, rot=(0, 90, 0), seg=20)
for s in (1, -1):
    cyl("PoleDeep", 0.17, 0.17, 0.025, REEL + Vector((s * 0.07, 0, 0)), rot=(0, 90, 0), seg=20)
    rim = [REEL + Vector((s * 0.085, 0.165 * math.cos(2 * math.pi * i / 28), 0.165 * math.sin(2 * math.pi * i / 28))) for i in range(28)]
    tube("RoseGold", rim, 0.008, seg=5, closed=True, caps=False)
    flower(REEL + Vector((s * 0.085, 0, 0)), (s, 0, 0), 0.15, spin=0.3, cup=0.05)
tube("RoseGold", [REEL + Vector((0.1, 0, 0)), REEL + Vector((0.14, -0.08, 0.06)), REEL + Vector((0.15, -0.16, 0.1))], 0.016, seg=6)
sph("Pearl", 0.045, REEL + Vector((0.16, -0.19, 0.12)), seg=12, rings=8)

# pole: deep pink -> pink -> pearl pink, rose-gold collars
for z0, z1, col in ((0.72, 2.6, "PoleDeep"), (2.6, 4.1, "PolePink"), (4.1, 5.45, "PolePearl")):
    cyl(col, POLE_R(max(z0, 1.0)), POLE_R(z1), z1 - z0, (0, 0, (z0 + z1) / 2), seg=12)
for z in (2.6, 4.1):
    cyl("RoseGold", POLE_R(z) + 0.022, POLE_R(z) + 0.022, 0.07, (0, 0, z), seg=12)
# pearl string spiralling up the pole
for i in range(26):
    u = i / 25
    z = 1.6 + 3.5 * u
    a = 0.4 + 2 * math.pi * 2.2 * u
    r = POLE_R(z) + 0.022
    sph("Pearl", 0.026 - 0.008 * u, (r * math.cos(a), r * math.sin(a), z), seg=8, rings=5)
# line guides on top (+Y)
for z in (1.9, 2.9, 3.8, 4.6, 5.2):
    r = POLE_R(z)
    cyl("RoseGold", 0.01, 0.01, 0.07, (0, r + 0.03, z), rot=(90, 0, 0), seg=6)
    tube("RoseGold", [(0.03 * math.cos(2 * math.pi * k / 12), r + 0.08, z + 0.03 * math.sin(2 * math.pi * k / 12)) for k in range(12)],
         0.008, seg=5, closed=True, caps=False)
# sakura blossoms along the pole (on the sides so they do not block the line guides)
# 2026-11-26 user: bigger blossoms on the rod (x1.6)
for z, ang, sz in ((2.15, 0, 0.26), (2.45, 200, 0.19), (3.35, 150, 0.24), (3.65, -40, 0.18), (4.45, 30, 0.21), (4.85, 210, 0.16)):
    a = math.radians(ang)
    d = Vector((math.cos(a), math.sin(a) * 0.6 - 0.3, 0.25)).normalized()
    flower(Vector((0, 0, z)) + Vector((math.cos(a), math.sin(a), 0)) * (POLE_R(z) + 0.02 + sz * 0.12), d, sz, spin=ang * 0.01)
    for side in (1, -1):   # two tiny leaves-as-petals buds next to each flower
        sph("PetalDeep", (0.035, 0.022, 0.05), Vector((0, 0, z + side * 0.13)) + Vector((math.cos(a + side * 0.6), math.sin(a + side * 0.6), 0)) * (POLE_R(z) + 0.02),
            seg=8, rings=5)

# fore-grip jellyfish: a translucent pink bell around the pole, frilled rim, short tentacle ribbons trailing toward the hand
JZ = 1.12
bell_shell("Bell", 0.34, 0.3, (0, 0, JZ), thick=0.045, flare=0.08)
scallops("Frill", 0.36, JZ - 0.03, 14, 0.045)
for k in range(4):   # glowing core (Neon in Studio): four petal-shaped gonads seen through the bell
    a = 2 * math.pi * k / 4 + 0.4
    sph("Core", (0.09, 0.05, 0.035), (0.13 * math.cos(a), 0.13 * math.sin(a), JZ + 0.16), rot=(0, 0, math.degrees(a)), seg=10, rings=6)
for k in range(8):
    a = 2 * math.pi * (k + 0.25) / 8
    p0 = (0.3 * math.cos(a), 0.3 * math.sin(a), JZ - 0.04)
    pts = wavy(p0, 0.2 + 0.06 * (k % 2), 9, 0.03, 2.5, k * 1.1, drift=(0.06 * math.cos(a), 0.06 * math.sin(a)))
    tube("Tentacle", pts, [0.02 * (1 - 0.8 * i / 8) for i in range(9)], seg=5)
flower((0, 0.02, JZ + 0.31), (0, 0.5, 1), 0.16)   # small blossom on the bell crown

# tip: sakura bud + open blossom, line comes out of the bud
TIP = Vector((0, 0, 5.5))
cyl("RoseGold", POLE_R(5.45) + 0.012, POLE_R(5.45) + 0.004, 0.06, TIP, seg=10)
flower(TIP + Vector((0, 0.04, 0.08)), (0, 0.55, 1), 0.26, spin=0.2)
sph("PetalDeep", (0.05, 0.05, 0.09), TIP + Vector((0, -0.01, 0.26)), seg=10, rings=7)
sph("Petal", (0.035, 0.035, 0.05), TIP + Vector((0, -0.01, 0.32)), seg=8, rings=5)

# =================================================================== 2) SakuraJellyBobber (mini jellyfish)
MODEL = "SakuraJellyBobber"
bell_shell("Bell", 0.22, 0.24, (0, 0, 0.02), thick=0.04, flare=0.1)
scallops("Frill", 0.235, 0.0, 12, 0.035)
for k in range(4):
    a = 2 * math.pi * k / 4 + 0.4
    sph("Core", (0.07, 0.04, 0.03), (0.08 * math.cos(a), 0.08 * math.sin(a), 0.14), rot=(0, 0, math.degrees(a)), seg=10, rings=6)
sph("Core", 0.05, (0, 0, 0.1), seg=10, rings=6)
for k in range(8):
    a = 2 * math.pi * (k + 0.5) / 8
    pts = wavy((0.17 * math.cos(a), 0.17 * math.sin(a), -0.01), 0.32 + 0.06 * (k % 2), 8, 0.03, 2.2, k)
    tube("Tentacle", pts, [0.018 * (1 - 0.8 * i / 7) for i in range(8)], seg=5)
for k in range(3):   # frilly oral arms in the middle
    a = 2 * math.pi * k / 3
    pts = wavy((0.03 * math.cos(a), 0.03 * math.sin(a), 0.02), 0.26, 8, 0.03, 2.5, k * 2.1)
    tube("Arm", pts, [0.035 * (1 - 0.6 * i / 7) for i in range(8)], seg=6, flat=0.3, normal=(math.cos(a), math.sin(a), 0))
flower((0, 0, 0.255), (0, 0, 1), 0.1, cup=0.35)
# two little eyes so it reads as cute from the player's side (-Y)
for s in (1, -1):
    sph("Eye", (0.022, 0.012, 0.028), (s * 0.07, -0.19, 0.1), seg=8, rings=6)

# =================================================================== 3) SakuraJelly (3D fx that floats with the holder)
# Pieces: Bell (shell, frill, core, crown blossom) / Arms (4 frilly oral arms) / Tent (12 thin tentacles). Hinge = origin.
R, H = 1.0, 0.9
MODEL = "Bell"
bell_shell("Bell", R, H, (0, 0, 0), thick=0.08, flare=0.1, seg=36)
scallops("Frill", R * 1.08, -0.04, 22, 0.1)
for k in range(4):
    a = 2 * math.pi * k / 4 + 0.785
    sph("Core", (0.3, 0.17, 0.08), (0.34 * math.cos(a), 0.34 * math.sin(a), 0.48), rot=(0, 0, math.degrees(a)), seg=14, rings=8)
sph("Core", (0.16, 0.16, 0.1), (0, 0, 0.5), seg=12, rings=7)
for k in range(8):   # faint radial canals on the inside of the dome
    a = 2 * math.pi * k / 8
    pts = [(r * math.cos(a), r * math.sin(a), H * math.cos(math.asin(min(0.99, r / R))) - 0.1) for r in (0.2, 0.45, 0.7, 0.88)]
    tube("Frill", pts, 0.018, seg=4)
flower((0, 0, H + 0.02), (0, 0, 1), 0.36, cup=0.3, spin=0.3)
for s in (1, -1):   # cute eyes on the front (-Y) so it reads from far away
    sph("Eye", (0.075, 0.045, 0.1), (s * 0.3, -0.895, 0.34), rot=(-20, 0, s * -18), seg=10, rings=7)
    sph("Pearl", (0.028, 0.016, 0.032), (s * 0.3 + 0.025, -0.94, 0.38), seg=6, rings=4)
MODEL = "Arms"
for k in range(4):
    a = 2 * math.pi * k / 4 + 0.785
    pts = wavy((0.12 * math.cos(a), 0.12 * math.sin(a), 0.05), 1.9, 14, 0.14, 3.0, k * 1.6, drift=(0.15 * math.cos(a), 0.15 * math.sin(a)))
    tube("Arm", pts, [0.12 * (1 - 0.7 * i / 13) for i in range(14)], seg=8, flat=0.3, normal=(math.cos(a), math.sin(a), 0))
MODEL = "Tent"
for k in range(12):
    a = 2 * math.pi * (k + 0.5) / 12
    L = 2.4 + 0.4 * (k % 3)
    pts = wavy((0.92 * math.cos(a), 0.92 * math.sin(a), -0.02), L, 16, 0.12, 3.5, k * 0.9, drift=(-0.25 * math.cos(a), -0.25 * math.sin(a)))
    tube("Tentacle", pts, [0.04 * (1 - 0.85 * i / 15) for i in range(16)], seg=5)

# ------------------------------------------------------------------ build + export
FX = ("Bell", "Arms", "Tent")
by_model = {}
for (model, mat), bm in BM.items():
    me = bpy.data.meshes.new(model + "__" + mat)
    bm.to_mesh(me)
    bm.free()
    me.materials.append(MATS[mat])
    ob = bpy.data.objects.new(model + "__" + mat, me)
    bpy.context.scene.collection.objects.link(ob)
    by_model.setdefault("SakuraJelly" if model in FX else model, []).append(ob)

scn = bpy.context.scene
scn.render.engine = 'BLENDER_WORKBENCH'
scn.display.shading.light = 'STUDIO'
scn.display.shading.color_type = 'MATERIAL'
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
scn.collection.objects.link(cam)
scn.camera = cam

VIEWS = {"SakuraJellyRod": [("side", Vector((1.0, -0.35, 0.15))), ("top", Vector((0.25, 1.0, 0.35)))],
         "SakuraJellyBobber": [("side", Vector((0.8, -1.0, 0.45)))],
         "SakuraJelly": [("front", Vector((0.3, -1.0, 0.35))), ("below", Vector((0.4, -0.6, -0.6)))]}
for model, objs in by_model.items():
    tri = 0
    for ob in objs:
        ob.data.calc_loop_triangles()
        tri += len(ob.data.loop_triangles)
        print("  OBJ", ob.name, len(ob.data.loop_triangles))
    allv = [v.co for ob in objs for v in ob.data.vertices]
    lo = Vector(tuple(min(c[k] for c in allv) for k in range(3)))
    hi = Vector(tuple(max(c[k] for c in allv) for k in range(3)))
    print("MODEL", model, "OBJECTS", len(objs), "TRIS", tri, "BBOX_MIN", tuple(round(v, 3) for v in lo), "BBOX_MAX", tuple(round(v, 3) for v in hi))
    bpy.ops.object.select_all(action='DESELECT')
    for o in bpy.data.objects:
        o.hide_render = o not in objs and o is not cam
    for ob in objs:
        ob.select_set(True)
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, model + ".glb"), export_format='GLB',
                              use_selection=True, export_apply=True, export_yup=True)
    size = (hi - lo).length
    mid = (lo + hi) / 2
    for vname, vdir in VIEWS[model]:
        scn.render.resolution_x, scn.render.resolution_y = (700, 1000) if model == "SakuraJellyRod" else (800, 800)
        cam.data.lens = 40
        cam.location = mid + vdir.normalized() * size * 1.25
        cam.rotation_euler = (mid - cam.location).to_track_quat('-Z', 'Y').to_euler()
        scn.render.filepath = os.path.join(OUT, "preview_%s_%s.png" % (model, vname))
        bpy.ops.render.render(write_still=True)

# close-ups: reel, fore-grip jellyfish, tip blossom
for o in bpy.data.objects:
    o.hide_render = not (o.name.startswith("SakuraJellyRod__") or o is cam)
for vname, vdir, focus, dist in (("reel", Vector((1.0, -0.3, 0.1)), REEL, 1.1), ("jelly", Vector((0.6, -1.0, 0.3)), Vector((0, 0, 1.05)), 1.8),
                                 ("tip", Vector((0.8, -0.6, 0.2)), Vector((0, 0, 5.55)), 1.2)):
    scn.render.resolution_x, scn.render.resolution_y = 800, 800
    cam.data.lens = 50
    cam.location = focus + vdir.normalized() * dist
    cam.rotation_euler = (focus - cam.location).to_track_quat('-Z', 'Y').to_euler()
    scn.render.filepath = os.path.join(OUT, "preview_SakuraJellyRod_%s.png" % vname)
    bpy.ops.render.render(write_still=True)
