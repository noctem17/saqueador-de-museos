"""Prepara los modelos nuevos del equipo (esqueleto Mixamo, hechos con Tripo) para el juego.

Cada modelo trae pocas animaciones propias (caminar, correr, disparar...). El juego
usa además las del paquete de Quaternius (quieto, apuntar, morir, golpes...), así
que este script las COPIA al esqueleto Mixamo:

  1. Importa el modelo nuevo y modelos/polo.glb (esqueleto Quaternius, 24 animaciones).
  2. Para cada cuadro de cada animación de Quaternius mira hacia dónde apunta cada
     hueso en el mundo y gira el hueso equivalente del modelo nuevo igual. Antes de
     copiar, endereza los huesos del modelo nuevo para que su pose de reposo (brazos
     en "A") coincida con la de Quaternius (brazos en "T").
  3. Deja las animaciones propias con el prefijo "m_" (m_walk, m_run, m_fire...).
  4. Quita la esfera suelta, el prefijo "mixamorig:" de los huesos, lo escala a su
     altura y lo exporta a modelos/.

Uso (Blender en modo fondo, desde la carpeta del proyecto):
  blender -b --factory-startup --python herramientas/rigear_mixamo.py -- polo
  (o mostro, mostro_premium, vigilante, policia, elcacas, o "todos")
"""
import math
import os
import sys

import bpy
from mathutils import Matrix, Quaternion, Vector

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# nombre en el juego: (archivo en aportes/modelos, altura en metros)
MODELOS = {
    # El Polo nuevo llegó sin huesos: primero se corre herramientas/rigear_polo_nuevo.py.
    "polo": ("polo_nuevo_rigeado.glb", 1.7),
    "mostro": ("MOSTROremaster.glb", 1.7),
    "mostro_premium": ("MOSTROpremium.glb", 1.7),
    "elcacas": ("elCACAS.glb", 1.7),
    "vigilante": ("guarda de seguridad.glb", 1.8),
    "policia": ("policia.glb", 1.8),
}

# Modelos con la cara aparte, para pegarle una foto (ver herramientas/separar_cara.py
# y aportes/caras/cara_<nombre>.png).
CON_CARA = {"polo"}

# Hueso de Quaternius -> hueso de Mixamo (sin el prefijo "mixamorig:").
MAPA = {
    "Hips": "Hips", "Abdomen": "Spine", "Torso": "Spine1", "Chest": "Spine2",
    "Neck": "Neck",
}
# La cabeza no se copia: Quaternius la inclina hacia arriba para compensar sus
# cabezas gigantes, y en estos modelos quedaban mirando al techo. Sigue al cuello.
for q, m in (("L", "Left"), ("R", "Right")):
    MAPA.update({
        f"UpperArm.{q}": f"{m}Arm",
        f"LowerArm.{q}": f"{m}ForeArm", f"Wrist.{q}": f"{m}Hand",
        f"UpperLeg.{q}": f"{m}UpLeg", f"LowerLeg.{q}": f"{m}Leg",
    })
    for dedo in ("Index", "Middle", "Ring", "Pinky"):
        for i in (1, 2, 3):
            MAPA[f"{dedo}{i}.{q}"] = f"{m}Hand{dedo}{i}"
    for i in (1, 2, 3):
        MAPA[f"Thumb{i}.{q}"] = f"{m}HandThumb{i}"

# Para enderezar la pose de reposo hace falta la dirección de cada hueso: de su
# cabeza a la cabeza del hueso siguiente. Los extremos (cabeza, manos, pies,
# puntas de los dedos) heredan la corrección del padre.
SIGUIENTE = {
    "Hips": "Spine", "Spine": "Spine1", "Spine1": "Spine2", "Spine2": "Neck",
}
for m in ("Left", "Right"):
    SIGUIENTE.update({
        f"{m}Shoulder": f"{m}Arm", f"{m}Arm": f"{m}ForeArm", f"{m}ForeArm": f"{m}Hand",
        f"{m}UpLeg": f"{m}Leg", f"{m}Leg": f"{m}Foot",
    })
    for dedo in ("Index", "Middle", "Ring", "Pinky", "Thumb"):
        for i in (1, 2):
            SIGUIENTE[f"{m}Hand{dedo}{i}"] = f"{m}Hand{dedo}{i + 1}"
INVERSO = {v: k for k, v in MAPA.items()}


def rot(mat: Matrix) -> Quaternion:
    return mat.to_3x3().normalized().to_quaternion()


def importar(ruta: str) -> set:
    antes = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=ruta)
    return set(bpy.data.objects) - antes


def curvas(accion):
    """Curvas de una acción (Blender 5 las guarda por capas y canales)."""
    if hasattr(accion, "fcurves") and len(getattr(accion, "fcurves", [])):
        return list(accion.fcurves)
    lista = []
    for capa in getattr(accion, "layers", []):
        for tira in capa.strips:
            for bolsa in tira.channelbags:
                lista.extend(bolsa.fcurves)
    return lista


def quitar_avance(accion) -> None:
    """Las animaciones de Mixamo avanzan solas (la cadera se desplaza). En el juego
    quien mueve al personaje es el código, así que se quita ese avance: a la
    posición horizontal de la cadera se le resta la línea recta entre el primer y
    el último cuadro. Queda el vaivén, no el desplazamiento."""
    for fc in curvas(accion):
        if fc.data_path.endswith('"Hips"].location') or fc.data_path.endswith('Hips"].location'):
            if fc.array_index == 1:   # El eje Y del hueso de la cadera es el vertical.
                continue
            puntos = fc.keyframe_points
            if len(puntos) < 2:
                continue
            x0, v0 = puntos[0].co
            x1, v1 = puntos[-1].co
            for k in puntos:
                t = (k.co.x - x0) / max(x1 - x0, 1e-6)
                quitar = v0 + (v1 - v0) * t
                k.co.y -= quitar
                k.handle_left.y -= quitar
                k.handle_right.y -= quitar


def preparar(nombre: str) -> None:
    archivo, altura = MODELOS[nombre]
    bpy.ops.wm.read_factory_settings(use_empty=True)

    # --- Modelo nuevo ---
    nuevos = importar(os.path.join(RAIZ, "aportes", "modelos", archivo))
    for o in list(nuevos):
        if o.type == "MESH" and not o.vertex_groups:   # La esfera suelta de Tripo.
            bpy.data.objects.remove(o)
    arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    arm.name = "Esqueleto"
    for b in arm.data.bones:
        b.name = b.name.replace("mixamorig:", "")
    if nombre in CON_CARA:
        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
        import separar_cara
        malla = next(o for o in bpy.data.objects if o.type == "MESH" and o.vertex_groups)
        separar_cara.separar(malla, nombre, "Head")
    propias = [a for a in bpy.data.actions]
    for a in propias:
        a.name = "m_" + a.name.replace(".001", "")
        quitar_avance(a)

    # --- Quaternius ---
    q_objs = importar(os.path.join(RAIZ, "modelos", "polo.glb"))
    q_arm = next(o for o in q_objs if o.type == "ARMATURE")
    q_acciones = [a for a in bpy.data.actions if a not in propias]

    mw = arm.matrix_world
    mw_rot = rot(mw)
    huesos = arm.data.bones
    pose = arm.pose.bones

    # Reposo en el mundo de ambos esqueletos.
    def reposo_m(n):
        return rot(mw @ huesos[n].matrix_local)

    def cabeza_m(n):
        return mw @ huesos[n].head_local

    def reposo_q(n):
        return rot(q_arm.matrix_world @ q_arm.data.bones[n].matrix_local)

    def cabeza_q(n):
        return q_arm.matrix_world @ q_arm.data.bones[n].head_local

    # Corrección de reposo por hueso (gira la dirección Mixamo a la de Quaternius).
    correccion: dict[str, Quaternion] = {}

    # Solo se enderezan los brazos (de la "A" de Mixamo a la "T" de Quaternius).
    # Columna, clavículas, piernas y pies conservan la postura natural del modelo:
    # al enderezarlos, los hombros quedaban encogidos y las puntas de los pies
    # apuntando a la canilla. Por eso tampoco se copian las clavículas ni los pies.
    def es_brazo(n):
        return any(n.startswith(l + parte) for l in ("Left", "Right") for parte in ("Arm", "ForeArm", "Hand"))

    def calcular_correccion(b):
        n = b.name
        if not es_brazo(n):
            correccion[n] = Quaternion()
        elif n in INVERSO and n in SIGUIENTE and SIGUIENTE[n] in huesos and INVERSO.get(SIGUIENTE[n]):
            d_m = cabeza_m(SIGUIENTE[n]) - cabeza_m(n)
            d_q = cabeza_q(INVERSO[SIGUIENTE[n]]) - cabeza_q(INVERSO[n])
            correccion[n] = d_m.rotation_difference(d_q)
        else:
            correccion[n] = correccion[b.parent.name] if b.parent else Quaternion()
        for h in b.children:
            calcular_correccion(h)

    raices = [b for b in huesos if b.parent is None]
    for r in raices:
        calcular_correccion(r)

    alto_cadera_m = cabeza_m("Hips").z
    alto_cadera_q = cabeza_q("Hips").z
    escala_mov = alto_cadera_m / alto_cadera_q

    orden = []   # Padres antes que hijos.

    def recorrer(b):
        orden.append(b)
        for h in b.children:
            recorrer(h)

    for r in raices:
        recorrer(r)

    escena = bpy.context.scene
    q_arm.animation_data_create()
    arm.animation_data_create()
    for qa in q_acciones:
        corto = qa.name.split("|")[-1]
        q_arm.animation_data.action = qa
        if q_arm.animation_data.action_slot is None and len(qa.slots):
            q_arm.animation_data.action_slot = qa.slots[0]
        nueva = bpy.data.actions.new(corto)
        nueva.use_fake_user = True
        arm.animation_data.action = nueva
        ini, fin = (int(x) for x in qa.frame_range)
        previo: dict[str, Quaternion] = {}
        enderezar = None   # Giro para que la animación empiece de frente.
        for f in range(ini, fin + 1):
            escena.frame_set(f)
            if enderezar is None:
                # Quaternius usa una postura de tres cuartos (el cuerpo girado ~45°).
                # Se quita ese giro inicial de la cadera, para que quede de frente.
                d_cadera = rot(q_arm.matrix_world @ q_arm.pose.bones["Hips"].matrix) @ reposo_q("Hips").inverted()
                lado = d_cadera @ Vector((1, 0, 0))
                enderezar = Quaternion((0, 0, 1), -math.atan2(lado.y, lado.x))
            pose_arm: dict[str, Quaternion] = {}   # Rotación en espacio del esqueleto.
            for b in orden:
                n = b.name
                r_local = rot(b.matrix_local)
                if n in INVERSO:
                    qn = INVERSO[n]
                    q_ahora = rot(q_arm.matrix_world @ q_arm.pose.bones[qn].matrix)
                    delta = q_ahora @ reposo_q(qn).inverted()
                    mundo = enderezar @ delta @ correccion[n] @ reposo_m(n)
                    pose_arm[n] = mw_rot.inverted() @ mundo
                else:
                    if b.parent:
                        pose_arm[n] = pose_arm[b.parent.name] @ rot(b.parent.matrix_local).inverted() @ r_local
                    else:
                        pose_arm[n] = r_local
                if b.parent:
                    base = pose_arm[b.parent.name] @ rot(b.parent.matrix_local).inverted() @ r_local
                else:
                    base = r_local
                basis = base.inverted() @ pose_arm[n]
                if n in previo and previo[n].dot(basis) < 0.0:
                    basis.negate()
                previo[n] = basis.copy()
                pb = pose[n]
                pb.rotation_mode = "QUATERNION"
                pb.rotation_quaternion = basis
                if n in INVERSO:
                    pb.keyframe_insert("rotation_quaternion", frame=f)
            # Cadera: se mueve como la de Quaternius, a la escala de este modelo.
            pb_q = q_arm.pose.bones["Hips"]
            mov_mundo = enderezar @ ((q_arm.matrix_world @ pb_q.head - cabeza_q("Hips")) * escala_mov)
            objetivo = cabeza_m("Hips") + mov_mundo
            b = huesos["Hips"]
            en_arm = mw.inverted() @ objetivo
            pose["Hips"].location = b.matrix_local.to_3x3().normalized().inverted() @ (en_arm - b.head_local)
            pose["Hips"].keyframe_insert("location", frame=f)
        print("  copiada", corto, ini, fin)

    # Fuera Quaternius.
    for o in q_objs:
        bpy.data.objects.remove(o)
    for a in q_acciones:
        bpy.data.actions.remove(a)
    arm.animation_data.action = None
    for pb in pose:
        pb.rotation_quaternion = Quaternion()
        pb.location = Vector()
    for a in bpy.data.actions:
        a.use_fake_user = True

    # Altura.
    arm.scale = Vector((1, 1, 1)) * altura
    salida = os.path.join(RAIZ, "modelos", nombre + "_mx.glb")
    bpy.ops.export_scene.gltf(
        filepath=salida,
        export_format="GLB",
        export_animation_mode="ACTIONS",
        export_anim_single_armature=True,
        export_reset_pose_bones=True,
        export_apply=False,
        export_yup=True,
    )
    print("LISTO", salida, "acciones:", sorted(a.name for a in bpy.data.actions))


if __name__ == "__main__":
    pedido = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "todos"
    for n in (MODELOS if pedido == "todos" else [pedido]):
        print("==", n)
        preparar(n)
