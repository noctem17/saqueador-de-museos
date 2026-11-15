"""Pone esqueleto y animaciones a un personaje 3D que viene sin huesos.

Uso (Blender en modo consola):
  blender -b --python herramientas/rigear_chibi.py -- entrada.glb modelos/polo.glb salida.glb [altura]

Qué hace:
 1. Importa el modelo (una sola malla, sin huesos) y le quita la basura que quede
    flotando debajo de los pies (por ejemplo una roca de base).
 2. Baja la cantidad de polígonos y el tamaño de las texturas para que el juego
    siga corriendo rápido.
 3. Busca las articulaciones cortando la malla en rebanadas horizontales: dónde se
    juntan las piernas (cadera), dónde se separan los brazos del torso (hombros),
    dónde es más angosto entre el torso y la cabeza (cuello).
 4. Crea un esqueleto con los mismos nombres de huesos de los personajes de
    Quaternius (Hips, Chest, UpperArm.L, Wrist.R...), para que el juego no cambie.
 5. Calcula a qué hueso pertenece cada vértice según la distancia a cada hueso.
 6. Copia las 24 animaciones de polo.glb: cada hueso nuevo apunta hacia donde
    apunta el hueso original en cada cuadro. Así funcionan aunque el cuerpo tenga
    otras proporciones (cabeza grande, brazos y piernas cortos).
"""
import sys
import bpy
import bmesh
from mathutils import Vector, Matrix, Quaternion

args = sys.argv[sys.argv.index("--") + 1:]
ENTRADA, FUENTE, SALIDA = args[0], args[1], args[2]
ALTURA = float(args[3]) if len(args) > 3 else 1.7
TRIS_MAX = 22000
TEXTURA_MAX = 1024

bpy.ops.wm.read_factory_settings(use_empty=True)


# ---------------------------------------------------------------- 1. modelo
bpy.ops.import_scene.gltf(filepath=ENTRADA)
mallas = [o for o in bpy.data.objects if o.type == 'MESH']
for o in mallas:
    o.select_set(True)
bpy.context.view_layer.objects.active = mallas[0]
if len(mallas) > 1:
    bpy.ops.object.join()
cuerpo = bpy.context.view_layer.objects.active
cuerpo.parent = None
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

# Quita lo que esté debajo de un hueco vacío cerca del piso (la "roca" de base).
me = cuerpo.data
zs = sorted(v.co.z for v in me.vertices)
zmin, zmax = zs[0], zs[-1]
alto = zmax - zmin
corte = None
paso = alto * 0.01
z = zmin
while z < zmin + alto * 0.3:
    if not any(z <= v.co.z < z + paso * 2 for v in me.vertices):
        corte = z + paso
    z += paso
if corte is not None:
    bm = bmesh.new()
    bm.from_mesh(me)
    basura = [v for v in bm.verts if v.co.z < corte]
    bmesh.ops.delete(bm, geom=basura, context='VERTS')
    bm.to_mesh(me)
    bm.free()
    print("Quitada la base debajo de z =", round(corte, 3))

# Escala a la altura pedida, con los pies en z = 0 y centrado en x/y.
zs = [v.co.z for v in me.vertices]
xs = [v.co.x for v in me.vertices]
ys = [v.co.y for v in me.vertices]
escala = ALTURA / (max(zs) - min(zs))
desplaza = Vector((-(max(xs) + min(xs)) / 2, -(max(ys) + min(ys)) / 2, -min(zs)))
for v in me.vertices:
    v.co = (v.co + desplaza) * escala

# Menos polígonos.
tris = sum(len(p.vertices) - 2 for p in me.polygons)
if tris > TRIS_MAX:
    dec = cuerpo.modifiers.new("menos", 'DECIMATE')
    dec.ratio = TRIS_MAX / tris
    bpy.ops.object.modifier_apply(modifier=dec.name)
print("Triángulos:", tris, "->", sum(len(p.vertices) - 2 for p in me.polygons))

# Texturas más chicas.
for img in bpy.data.images:
    if img.size[0] > TEXTURA_MAX:
        img.scale(TEXTURA_MAX, TEXTURA_MAX)


# ---------------------------------------------------------------- 2. medidas
verts = [v.co.copy() for v in me.vertices]
H = ALTURA


# Medidas de cada modelo, en las coordenadas del archivo original (z hacia arriba,
# x hacia el lado izquierdo del personaje). Salen de cortar la malla en rebanadas
# horizontales y ver dónde se juntan las piernas, dónde se separa el brazo, etc.
#   cadera: donde se juntan las piernas   hombro: articulación del brazo
#   mano: punta de abajo de la mano       cuello: lo más angosto bajo la cabeza
#   brazo_x / mano_x: centro del brazo arriba y de la mano   pierna_x: centro de la pierna
#   axila: (z1, x1, z2, x2) línea que separa el torso del brazo: más afuera es brazo
MEDIDAS = {
    "mostrooooo": dict(cadera=-0.63, hombro=-0.25, mano=-0.62, cuello=-0.05, brazo_x=0.38, mano_x=0.50, pierna_x=0.17, axila=(-0.33, 0.285, -0.57, 0.34)),
    "polopoloooo": dict(cadera=-0.59, hombro=-0.29, mano=-0.57, cuello=-0.05, brazo_x=0.38, mano_x=0.47, pierna_x=0.18, axila=(-0.38, 0.275, -0.55, 0.32)),
    "negrac": dict(cadera=-0.30, hombro=0.03, mano=-0.33, cuello=0.16, brazo_x=0.30, mano_x=0.44, pierna_x=0.19, axila=(-0.05, 0.205, -0.33, 0.305)),
}
nombre_archivo = ENTRADA.replace("\\", "/").split("/")[-1].rsplit(".", 1)[0]
med = MEDIDAS[nombre_archivo]


def az(z):
    return (z + desplaza.z) * escala


def ax(x):
    return (x + desplaza.x) * escala


PASO = H * 0.01
cadera = az(med["cadera"])
hombro_z = az(med["hombro"])
mano_z = az(med["mano"])
cuello = az(med["cuello"])
pierna_x = med["pierna_x"] * escala


def y_en(z0, x0=0.0, rx=1e9):
    sel = [v.y for v in verts if z0 - PASO <= v.z < z0 + PASO and abs(v.x - x0) < rx]
    return (min(sel) + max(sel)) / 2 if sel else 0.0


print(f"cadera {cadera:.2f} hombro {hombro_z:.2f} mano {mano_z:.2f} cuello {cuello:.2f} pierna_x {pierna_x:.2f}")

# Posición de cada articulación (lado izquierdo = x positivo, como en Quaternius).
yc = y_en(cadera, 0, H * 0.1)
bx, mx = med["brazo_x"] * escala, med["mano_x"] * escala
A = Vector((bx, y_en(hombro_z - H * 0.04, bx, H * 0.06), hombro_z))
B = Vector((mx, y_en(mano_z + H * 0.03, mx, H * 0.06), mano_z))
tobillo = H * 0.045
P = {}
P["Root"] = Vector((0, yc, 0))
P["Body"] = Vector((0, yc, cadera + H * 0.02))
P["Hips"] = Vector((0, yc, cadera + H * 0.03))
for nombre, f in (("Abdomen", 0.25), ("Torso", 0.5), ("Chest", 0.78)):
    zz = cadera + (hombro_z - cadera) * f
    P[nombre] = Vector((0, y_en(zz, 0, H * 0.1), zz))
P["Neck"] = Vector((0, y_en(cuello, 0, H * 0.1), cuello))
P["Head"] = Vector((0, P["Neck"].y, cuello + H * 0.02))
P["Head_fin"] = Vector((0, P["Neck"].y, H))
for lado, s in (("L", 1), ("R", -1)):
    a = Vector((A.x * s, A.y, A.z))
    b = Vector((B.x * s, B.y, B.z))
    P["Shoulder." + lado] = Vector((a.x * 0.45, a.y, a.z))
    P["UpperArm." + lado] = a
    P["LowerArm." + lado] = a.lerp(b, 0.45)
    P["Wrist." + lado] = a.lerp(b, 0.72)
    P["Mano_fin." + lado] = b
    xl = pierna_x * s
    P["UpperLeg." + lado] = Vector((xl, yc, cadera))
    P["LowerLeg." + lado] = Vector((xl, y_en(cadera * 0.5, xl, H * 0.08), (cadera + tobillo) * 0.5))
    P["Foot." + lado] = Vector((xl, y_en(tobillo, xl, H * 0.08), tobillo))
    pie = [v for v in verts if v.z < tobillo and (v.x * s) > 0]
    P["Pie_fin." + lado] = Vector((xl, min(v.y for v in pie), 0.0))


# ---------------------------------------------------------------- 3. fuente
bpy.ops.import_scene.gltf(filepath=FUENTE)
fuente = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
for o in list(bpy.data.objects):
    if o.type == 'MESH' and o != cuerpo:
        bpy.data.objects.remove(o)
mw_f = fuente.matrix_world.copy()
rest_f = {}   # hueso -> (rotación en el mundo, posición en el mundo) en reposo
for b in fuente.data.bones:
    m = mw_f @ b.matrix_local
    rest_f[b.name] = (m.to_quaternion().normalized(), m.to_translation())
ratio = P["Body"].z / rest_f["Body"][1].z


# ---------------------------------------------------------------- 4. esqueleto
datos = bpy.data.armatures.new("CharacterArmature")
arma = bpy.data.objects.new("CharacterArmature", datos)
bpy.context.scene.collection.objects.link(arma)
bpy.context.view_layer.objects.active = arma
bpy.ops.object.mode_set(mode='EDIT')
DEDOS = ("Index", "Middle", "Ring", "Pinky", "Thumb")


def pos_hueso(nombre):
    if nombre in P:
        return P[nombre]
    lado = nombre[-1]
    base = nombre.split(".")[0]
    if base.startswith(DEDOS):
        # Los dedos van en fila entre la muñeca y la punta de la mano.
        n = int(base[-1])
        return P["Wrist." + lado].lerp(P["Mano_fin." + lado], 0.3 + 0.17 * (n - 1))
    if base == "PT":   # Objetivos de rodilla del IK original: frente a la rodilla.
        return P["LowerLeg." + lado] + Vector((0, -0.4, 0))
    raise KeyError(nombre)


padre_nuevo = {"Foot.L": "LowerLeg.L", "Foot.R": "LowerLeg.R"}
for b in fuente.data.bones:
    eb = datos.edit_bones.new(b.name)
    rot, _ = rest_f[b.name]
    # Los huesos del brazo se giran para seguir el brazo del modelo nuevo.
    nombre = b.name
    lado = nombre[-1]
    if nombre.startswith(("UpperArm", "LowerArm", "Wrist")) or nombre.split(".")[0].startswith(DEDOS):
        dir_f = rot @ Vector((0, 1, 0))
        dir_n = (P["Mano_fin." + lado] - P["UpperArm." + lado]).normalized()
        rot = dir_f.rotation_difference(dir_n) @ rot
    m = rot.to_matrix().to_4x4()
    m.translation = pos_hueso(nombre)
    eb.head = m.translation
    eb.tail = m.translation + rot @ Vector((0, H * 0.04, 0))
    eb.matrix = m
for b in fuente.data.bones:
    eb = datos.edit_bones[b.name]
    padre = padre_nuevo.get(b.name, b.parent.name if b.parent else None)
    if padre:
        eb.parent = datos.edit_bones[padre]
bpy.ops.object.mode_set(mode='OBJECT')
rest_n = {b.name: b.matrix_local.copy() for b in datos.bones}


# ---------------------------------------------------------------- 5. pesos
SEGMENTOS = {
    "Hips": ("Hips", "Abdomen"), "Abdomen": ("Abdomen", "Torso"), "Torso": ("Torso", "Chest"),
    "Chest": ("Chest", "Neck"), "Neck": ("Neck", "Head"), "Head": ("Head", "Head_fin"),
}
for lado in ("L", "R"):
    SEGMENTOS.update({
        "Shoulder." + lado: ("Shoulder." + lado, "UpperArm." + lado),
        "UpperArm." + lado: ("UpperArm." + lado, "LowerArm." + lado),
        "LowerArm." + lado: ("LowerArm." + lado, "Wrist." + lado),
        "Wrist." + lado: ("Wrist." + lado, "Mano_fin." + lado),
        "UpperLeg." + lado: ("UpperLeg." + lado, "LowerLeg." + lado),
        "LowerLeg." + lado: ("LowerLeg." + lado, "Foot." + lado),
        "Foot." + lado: ("Foot." + lado, "Pie_fin." + lado),
    })
for b in datos.bones:
    b.use_deform = b.name in SEGMENTOS


def dist_segmento(p, a, b):
    ab = b - a
    t = max(0.0, min(1.0, (p - a).dot(ab) / max(ab.length_squared, 1e-9)))
    return (p - (a + ab * t)).length


grupos_v = {n: cuerpo.vertex_groups.new(name=n) for n in SEGMENTOS}
az1, ax1, az2, ax2 = med["axila"]
az1, az2, ax1, ax2 = az(az1), az(az2), ax1 * escala, ax2 * escala


def separa_brazo(z):
    """x a partir de la cual un vértice a esa altura ya es del brazo."""
    t = (z - az1) / (az2 - az1)
    return ax1 + (ax2 - ax1) * t


for v in cuerpo.data.vertices:
    p = v.co
    if p.z > cuello + H * 0.03:
        grupos_v["Head"].add([v.index], 1.0, 'REPLACE')
        continue
    candidatos = []
    for n, (a, b) in SEGMENTOS.items():
        lado = n[-1] if "." in n else ""
        if lado == "L" and p.x < -H * 0.01 or lado == "R" and p.x > H * 0.01:
            continue
        es_brazo = n.startswith(("UpperArm", "LowerArm", "Wrist"))
        es_pierna = n.startswith(("UpperLeg", "LowerLeg", "Foot"))
        # Lo que está afuera del torso y abajo del hombro es brazo.
        if mano_z - PASO < p.z < hombro_z - PASO * 3 and abs(p.x) > separa_brazo(p.z):
            if not es_brazo:
                continue
        elif es_brazo and p.z < hombro_z - PASO * 3 and abs(p.x) <= separa_brazo(p.z):
            continue
        if es_pierna and p.z > cadera + H * 0.06:
            continue
        d = dist_segmento(p, P[a], P[b])
        candidatos.append((1.0 / (d + H * 0.01) ** 6, n))
    candidatos.sort(reverse=True)
    candidatos = candidatos[:3]
    total = sum(w for w, _ in candidatos)
    for w, n in candidatos:
        grupos_v[n].add([v.index], w / total, 'REPLACE')

cuerpo.parent = arma
mod = cuerpo.modifiers.new("Armature", 'ARMATURE')
mod.object = arma


# ---------------------------------------------------------------- 6. animaciones
orden = []


def recorrer(b):
    orden.append(b.name)
    for h in b.children:
        recorrer(h)


for b in datos.bones:
    if b.parent is None:
        recorrer(b)
fuente.animation_data_create()
arma.animation_data_create()
for b in arma.pose.bones:
    b.rotation_mode = 'QUATERNION'
acciones = [a for a in bpy.data.actions]
escena = bpy.context.scene
for acc in acciones:
    fuente.animation_data.action = acc
    if acc.slots and fuente.animation_data.action_slot is None:
        fuente.animation_data.action_slot = acc.slots[0]
    nueva = bpy.data.actions.new(acc.name)
    nueva.use_fake_user = True
    arma.animation_data.action = nueva
    ini, fin = int(acc.frame_range[0]), int(acc.frame_range[1])
    for f in range(ini, fin + 1):
        escena.frame_set(f)
        pose = {}   # hueso -> matriz en el mundo (sin escala)
        for n in orden:
            pb_f = fuente.pose.bones[n]
            mf = mw_f @ pb_f.matrix
            rot = mf.to_quaternion().normalized()
            hueso = datos.bones[n]
            if hueso.parent is None or n == "Body":
                if n == "Body":
                    pos = P["Body"] + (mf.to_translation() - rest_f["Body"][1]) * ratio
                else:
                    pos = rest_n[n].to_translation()
            else:
                padre = hueso.parent.name
                rel = rest_n[padre].inverted() @ rest_n[n]
                pos = (pose[padre] @ rel).to_translation()
            # Cada hueso nuevo toma el mismo giro en el mundo que el original: así
            # apunta hacia el mismo lado aunque en reposo estuviera girado (brazos).
            m = rot.to_matrix().to_4x4()
            m.translation = pos
            pose[n] = m
        for n in orden:
            hueso = datos.bones[n]
            pb = arma.pose.bones[n]
            if hueso.parent is None:
                base = rest_n[n].inverted() @ pose[n]
            else:
                padre = hueso.parent.name
                base = (rest_n[padre].inverted() @ rest_n[n]).inverted() @ (pose[padre].inverted() @ pose[n])
            pb.matrix_basis = base
            pb.keyframe_insert("location", frame=f)
            pb.keyframe_insert("rotation_quaternion", frame=f)
    print("Animación", acc.name, ini, fin)

# Quita lo que no se exporta.
for acc in acciones:
    bpy.data.actions.remove(acc)
for o in list(bpy.data.objects):
    if o not in (arma, cuerpo):
        bpy.data.objects.remove(o)
for acc in bpy.data.actions:
    acc.name = acc.name.rsplit(".", 1)[0] if acc.name[-4:-3] == "." else acc.name
arma.name = "CharacterArmature"
datos.name = "CharacterArmature"
print("OBJETOS", [o.name for o in bpy.data.objects], [a.name for a in bpy.data.actions][:3])
arma.animation_data.action = bpy.data.actions.get("CharacterArmature|Idle")
escena.frame_set(0)

bpy.ops.object.select_all(action='DESELECT')
arma.select_set(True)
cuerpo.select_set(True)
bpy.ops.export_scene.gltf(filepath=SALIDA, export_format='GLB', use_selection=True,
        export_animations=True, export_animation_mode='ACTIONS', export_image_format='JPEG',
        export_jpeg_quality=88)
print("EXPORTADO", SALIDA)
