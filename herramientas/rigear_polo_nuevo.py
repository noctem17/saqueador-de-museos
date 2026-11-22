"""Le pone esqueleto y animaciones al Polo nuevo ("polopolo alta resolucion.glb").

Ese modelo llegó sin huesos, en pose T. Este script:
  1. Mide el cuerpo (entrepierna, rodillas, tobillos, hombros, codos, muñecas,
     cuello, barbilla) recorriendo la malla por rebanadas, y pone cada hueso de un
     esqueleto tipo Mixamo en su articulación.
  2. Le asigna los pesos con el método automático de Blender ("heat"). Los dedos
     tienen huesos (las animaciones los mueven) pero no deforman: la mano se mueve
     entera con la muñeca, así no se rompe.
  3. Copia las animaciones propias del Polo anterior (caminar, correr, miedo...)
     de su esqueleto al nuevo, hueso por hueso, corrigiendo que aquel tenía los
     brazos en "A" y este en "T".
  4. Guarda aportes/modelos/polo_nuevo_rigeado.glb. Después rigear_mixamo.py lo
     trata como cualquier otro modelo: le agrega las animaciones de Quaternius,
     separa la cara, lo escala y lo exporta al juego.

Uso:  blender -b --factory-startup --python herramientas/rigear_polo_nuevo.py
"""
import os

import bpy
from mathutils import Matrix, Quaternion, Vector

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODELOS = os.path.join(RAIZ, "aportes", "modelos")
NUEVO = os.path.join(MODELOS, "polopolo alta resolucion.glb")
VIEJO = os.path.join(MODELOS, "POLOlegalmente correcto.glb")
SALIDA = os.path.join(MODELOS, "polo_nuevo_rigeado.glb")


def rot(m: Matrix) -> Quaternion:
    return m.to_3x3().normalized().to_quaternion()


# ------------------------------------------------------------------ medir

def medir(pts):
    """Puntos clave del cuerpo en pose T (alto 1, mirando a -Y, pies en z=0)."""
    def rebanada(z0, z1, cond=lambda p: True):
        return [p for p in pts if z0 <= p.z < z1 and cond(p)]

    def centro_y(lista):
        return sum(p.y for p in lista) / len(lista) if lista else 0.0

    alto = max(p.z for p in pts)
    m = {}
    # Brazos: lo que queda afuera del tronco. Su altura media es la del hombro.
    brazo = [p for p in pts if abs(p.x) > 0.3]
    m["z_brazo"] = sum(p.z for p in brazo) / len(brazo)
    m["x_punta"] = max(abs(p.x) for p in pts)
    # Tronco justo debajo de las axilas: su ancho dice dónde nace el brazo.
    tronco = rebanada(m["z_brazo"] - 0.12, m["z_brazo"] - 0.08, lambda p: abs(p.x) < 0.3)
    m["x_hombro"] = max(abs(p.x) for p in tronco) - 0.035
    # Muñeca: la parte más delgada del brazo antes de la mano.
    mejor, x_mu = 9.0, m["x_punta"] - 0.1
    x = m["x_punta"] - 0.15
    while x < m["x_punta"] - 0.075:
        seccion = [p for p in pts if x <= abs(p.x) < x + 0.008]
        if seccion:
            grosor = max(p.z for p in seccion) - min(p.z for p in seccion)
            if grosor < mejor:
                mejor, x_mu = grosor, x
        x += 0.004
    m["x_muneca"] = x_mu
    m["x_codo"] = m["x_hombro"] + (m["x_muneca"] - m["x_hombro"]) * 0.53
    # Entrepierna: lo más bajo donde ya no hay hueco entre las piernas (hay malla
    # justo en el centro). Como las piernas casi se tocan, se exige que esté pegada
    # al centro, y nunca por debajo de lo normal en una persona (46 % del alto).
    z = 0.25
    while z < 0.65:
        if rebanada(z, z + 0.01, lambda p: abs(p.x) < 0.003):
            break
        z += 0.005
    m["z_entrepierna"] = max(z, 0.46)
    m["z_cadera"] = m["z_entrepierna"] + 0.045
    pierna = rebanada(0.2, 0.35, lambda p: p.x > 0)
    m["x_pierna"] = sum(p.x for p in pierna) / len(pierna)
    m["z_tobillo"] = 0.048
    m["z_rodilla"] = m["z_tobillo"] + (m["z_cadera"] - m["z_tobillo"]) * 0.52
    # Cuello: la rebanada más angosta entre los hombros y la cabeza.
    mejor, z_cu = 9.0, m["z_brazo"] + 0.05
    z = m["z_brazo"] + 0.02
    while z < alto - 0.1:
        s = rebanada(z, z + 0.008, lambda p: abs(p.x) < 0.15)
        if s:
            ancho = max(p.x for p in s) - min(p.x for p in s)
            if ancho < mejor:
                mejor, z_cu = ancho, z
        z += 0.004
    m["z_cuello"] = z_cu
    m["z_cabeza"] = z_cu + 0.02
    m["alto"] = alto
    # Profundidad (y) de cada zona, para que los huesos queden por dentro.
    m["y"] = {
        "cadera": centro_y(rebanada(m["z_cadera"] - 0.02, m["z_cadera"] + 0.02, lambda p: abs(p.x) < 0.15)),
        "pecho": centro_y(rebanada(m["z_brazo"] - 0.1, m["z_brazo"] - 0.05, lambda p: abs(p.x) < 0.15)),
        "cuello": centro_y(rebanada(z_cu - 0.01, z_cu + 0.01, lambda p: abs(p.x) < 0.1)),
        "cabeza": centro_y(rebanada(z_cu + 0.05, alto, lambda p: abs(p.x) < 0.15)),
        "rodilla": centro_y(rebanada(m["z_rodilla"] - 0.02, m["z_rodilla"] + 0.02, lambda p: p.x > 0)),
        "tobillo": centro_y(rebanada(0.03, 0.07, lambda p: p.x > 0)),
        "brazo": centro_y(brazo),
    }
    pie = rebanada(0.0, 0.04, lambda p: p.x > 0)
    m["y_punta_pie"] = min(p.y for p in pie)
    mano = [p for p in pts if abs(p.x) > m["x_muneca"]]
    m["mano_y"] = (min(p.y for p in mano), max(p.y for p in mano))
    for k, v in m.items():
        print("   ", k, round(v, 3) if isinstance(v, float) else v)
    return m


# ------------------------------------------------------------------ esqueleto

def armar_esqueleto(m):
    """Esqueleto con los nombres de Mixamo, cada hueso en su articulación."""
    datos = bpy.data.armatures.new("Esqueleto")
    arm = bpy.data.objects.new("Esqueleto", datos)
    bpy.context.scene.collection.objects.link(arm)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    eb = datos.edit_bones
    y = m["y"]

    def hueso(nombre, cabeza, cola, padre=None, deforma=True):
        b = eb.new(nombre)
        b.head = Vector(cabeza)
        b.tail = Vector(cola)
        b.roll = 0.0
        if padre:
            b.parent = eb[padre]
            b.use_connect = False
        b.use_deform = deforma
        return b

    zc, zb, zcu, zca = m["z_cadera"], m["z_brazo"], m["z_cuello"], m["z_cabeza"]
    # Columna: de la cadera al cuello, en cuatro tramos como Mixamo.
    tramos = [zc, zc + (zcu - zc) * 0.12, zc + (zcu - zc) * 0.33, zc + (zcu - zc) * 0.6, zcu]
    ys = [y["cadera"], y["cadera"], (y["cadera"] + y["pecho"]) / 2, y["pecho"], y["cuello"]]
    nombres = ["Hips", "Spine", "Spine1", "Spine2"]
    for i, n in enumerate(nombres):
        hueso(n, (0, ys[i], tramos[i]), (0, ys[i + 1], tramos[i + 1]), nombres[i - 1] if i else None)
    hueso("Neck", (0, y["cuello"], zcu), (0, y["cabeza"], zca), "Spine2")
    hueso("Head", (0, y["cabeza"], zca), (0, y["cabeza"], m["alto"] * 0.99), "Neck")
    hueso("HeadTop_End", (0, y["cabeza"], m["alto"] * 0.99), (0, y["cabeza"], m["alto"] * 0.99 + 0.05), "Head", False)

    for lado, s in (("Left", 1), ("Right", -1)):
        # Brazo (en pose T: todo horizontal hacia ±x).
        yb = y["brazo"]
        hueso(f"{lado}Shoulder", (s * 0.03, yb, zb + 0.015), (s * m["x_hombro"], yb, zb), "Spine2")
        hueso(f"{lado}Arm", (s * m["x_hombro"], yb, zb), (s * m["x_codo"], yb, zb), f"{lado}Shoulder")
        hueso(f"{lado}ForeArm", (s * m["x_codo"], yb, zb), (s * m["x_muneca"], yb, zb), f"{lado}Arm")
        largo_mano = m["x_punta"] - m["x_muneca"]
        hueso(f"{lado}Hand", (s * m["x_muneca"], yb, zb), (s * (m["x_muneca"] + largo_mano * 0.45), yb, zb), f"{lado}ForeArm")
        # Dedos: no deforman (la mano se mueve entera), pero existen para las animaciones.
        y0, y1 = m["mano_y"]
        base_x = m["x_muneca"] + largo_mano * 0.45
        seg = largo_mano * 0.55 / 3.0
        for k, dedo in enumerate(("Index", "Middle", "Ring", "Pinky")):
            yd = y0 + (y1 - y0) * (0.2 + 0.2 * k)
            for i in (1, 2, 3, 4):
                x0 = base_x + seg * (i - 1)
                padre = f"{lado}Hand" if i == 1 else f"{lado}Hand{dedo}{i - 1}"
                hueso(f"{lado}Hand{dedo}{i}", (s * x0, yd, zb), (s * (x0 + seg), yd, zb), padre, False)
        for i in (1, 2, 3, 4):
            x0 = m["x_muneca"] + largo_mano * 0.1 * i
            padre = f"{lado}Hand" if i == 1 else f"{lado}HandThumb{i - 1}"
            hueso(f"{lado}HandThumb{i}", (s * x0, y0 + 0.01 - 0.008 * i, zb - 0.01), (s * (x0 + largo_mano * 0.1), y0 - 0.008 * i, zb - 0.012), padre, False)
        # Pierna.
        xp = s * m["x_pierna"]
        hueso(f"{lado}UpLeg", (xp, y["cadera"], zc - 0.035), (xp, y["rodilla"], m["z_rodilla"]), "Hips")
        hueso(f"{lado}Leg", (xp, y["rodilla"], m["z_rodilla"]), (xp, y["tobillo"], m["z_tobillo"]), f"{lado}UpLeg")
        y_bola = y["tobillo"] + (m["y_punta_pie"] - y["tobillo"]) * 0.72
        hueso(f"{lado}Foot", (xp, y["tobillo"], m["z_tobillo"]), (xp, y_bola, 0.015), f"{lado}Leg")
        hueso(f"{lado}ToeBase", (xp, y_bola, 0.015), (xp, m["y_punta_pie"], 0.012), f"{lado}Foot")
        hueso(f"{lado}Toe_End", (xp, m["y_punta_pie"], 0.012), (xp, m["y_punta_pie"] - 0.03, 0.012), f"{lado}ToeBase", False)
    bpy.ops.object.mode_set(mode="OBJECT")
    return arm


# ------------------------------------------------------------------ animaciones

def copiar_animaciones(origen, acciones, destino):
    """Copia acciones de un esqueleto Mixamo a otro con los mismos nombres de hueso.
    Igual que en rigear_mixamo.py: cada hueso gira en el mundo lo mismo que su
    equivalente; solo los brazos se enderezan de la "A" del viejo a la "T" del nuevo."""
    escena = bpy.context.scene
    hd, ho = destino.data.bones, origen.data.bones
    md, mo = destino.matrix_world, origen.matrix_world
    # Todos los huesos que tienen los dos, menos los dedos y las puntas.
    dedos = ("Index", "Middle", "Ring", "Pinky", "Thumb")
    comunes = [b.name for b in hd if b.name in ho and not any(d in b.name for d in dedos) and not b.name.endswith("_End")]

    def cab(arm, n):
        return arm.matrix_world @ arm.data.bones[n].head_local

    siguiente = {"LeftArm": "LeftForeArm", "LeftForeArm": "LeftHand", "RightArm": "RightForeArm", "RightForeArm": "RightHand",
                 "LeftShoulder": "LeftArm", "RightShoulder": "RightArm"}
    corr = {}
    for n in comunes:
        if n in siguiente:
            d_d = cab(destino, siguiente[n]) - cab(destino, n)
            d_o = cab(origen, siguiente[n]) - cab(origen, n)
            corr[n] = d_d.rotation_difference(d_o)
    for n in ("LeftHand", "RightHand"):
        corr[n] = corr[n.replace("Hand", "ForeArm")]
    orden = []

    def recorrer(b):
        orden.append(b)
        for h in b.children:
            recorrer(h)

    for b in hd:
        if b.parent is None:
            recorrer(b)
    escala = cab(destino, "Hips").z / cab(origen, "Hips").z
    origen.animation_data_create()
    destino.animation_data_create()
    for acc in acciones:
        origen.animation_data.action = acc
        if origen.animation_data.action_slot is None and len(acc.slots):
            origen.animation_data.action_slot = acc.slots[0]
        nueva = bpy.data.actions.new(acc.name.replace("m_", ""))
        nueva.use_fake_user = True
        destino.animation_data.action = nueva
        ini, fin = (int(x) for x in acc.frame_range)
        previo = {}
        for f in range(ini, fin + 1):
            escena.frame_set(f)
            pose = {}
            for b in orden:
                n = b.name
                r_local = rot(b.matrix_local)
                base = pose[b.parent.name] @ rot(b.parent.matrix_local).inverted() @ r_local if b.parent else r_local
                if n in comunes:
                    delta = rot(mo @ origen.pose.bones[n].matrix) @ rot(mo @ ho[n].matrix_local).inverted()
                    pose[n] = rot(md).inverted() @ (delta @ corr.get(n, Quaternion()) @ rot(md @ b.matrix_local))
                else:
                    pose[n] = base
                basis = base.inverted() @ pose[n]
                if n in previo and previo[n].dot(basis) < 0:
                    basis.negate()
                previo[n] = basis.copy()
                pb = destino.pose.bones[n]
                pb.rotation_mode = "QUATERNION"
                pb.rotation_quaternion = basis
                if n in comunes:
                    pb.keyframe_insert("rotation_quaternion", frame=f)
            mov = (mo @ origen.pose.bones["Hips"].head - cab(origen, "Hips")) * escala
            b = hd["Hips"]
            en_arm = md.inverted() @ (cab(destino, "Hips") + mov)
            destino.pose.bones["Hips"].location = b.matrix_local.to_3x3().normalized().inverted() @ (en_arm - b.head_local)
            destino.pose.bones["Hips"].keyframe_insert("location", frame=f)
        print("  copiada", nueva.name, ini, fin)


# ------------------------------------------------------------------ pesos

def pesar(malla, arm):
    """Pesos automáticos ("heat") de Blender. La malla de Tripo viene partida en
    pedazos por las costuras de la textura y así el cálculo falla, entonces se
    calcula sobre una copia soldada y agrandada (el método también falla con
    cosas muy pequeñas) y después se le pasan los pesos a la original por cercanía."""
    import bmesh
    copia = malla.copy()
    copia.data = malla.data.copy()
    bpy.context.scene.collection.objects.link(copia)
    bm = bmesh.new()
    bm.from_mesh(copia.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0008)
    bm.to_mesh(copia.data)
    bm.free()
    # Agrandar 10 veces los dos (y volver después).
    for o in (copia, arm):
        o.scale = (10, 10, 10)
    bpy.context.view_layer.update()
    bpy.ops.object.select_all(action="DESELECT")
    copia.select_set(True)
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")
    sin = sum(1 for v in copia.data.vertices if not any(g.weight > 0.01 for g in v.groups))
    print("  copia soldada: %d vértices, %d sin peso" % (len(copia.data.vertices), sin))
    for o in (copia, arm):
        o.scale = (1, 1, 1)
    bpy.context.view_layer.update()
    # Pasar los pesos a la malla original.
    for g in copia.vertex_groups:
        malla.vertex_groups.new(name=g.name)
    mod = malla.modifiers.new("pesos", "DATA_TRANSFER")
    mod.object = copia
    mod.use_vert_data = True
    mod.data_types_verts = {"VGROUP_WEIGHTS"}
    mod.vert_mapping = "NEAREST"
    # Se compara en las coordenadas propias de la malla (iguales en la copia y en la
    # original): la copia quedó colgada del esqueleto y su tamaño en el mundo cambió.
    mod.use_object_transform = False
    mod.layers_vgroup_select_src = "ALL"
    mod.layers_vgroup_select_dst = "NAME"
    bpy.ops.object.select_all(action="DESELECT")
    malla.select_set(True)
    bpy.context.view_layer.objects.active = malla
    bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.data.objects.remove(copia)
    rellenar_sin_peso(malla)
    malla.parent = arm
    am = malla.modifiers.new("Esqueleto", "ARMATURE")
    am.object = arm


def rellenar_sin_peso(malla):
    """Piezas sueltas (cordones de la capucha, botones...) a las que el cálculo no
    llega: toman los pesos del vértice con peso más cercano."""
    from mathutils.kdtree import KDTree
    con, sin = [], []
    for v in malla.data.vertices:
        (con if any(g.weight > 0.01 for g in v.groups) else sin).append(v)
    arbol = KDTree(len(con))
    for i, v in enumerate(con):
        arbol.insert(v.co, i)
    arbol.balance()
    for v in sin:
        _, i, _ = arbol.find(v.co)
        for g in con[i].groups:
            malla.vertex_groups[g.group].add([v.index], g.weight, "REPLACE")
    print("  rellenados %d vértices sin peso" % len(sin))


# ------------------------------------------------------------------ principal

def principal():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    antes = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=NUEVO)
    malla = next(o for o in set(bpy.data.objects) - antes if o.type == "MESH")
    malla.name = "Polo"
    # Aplica cualquier transformación para medir en metros reales.
    bpy.ops.object.select_all(action="DESELECT")
    malla.select_set(True)
    bpy.context.view_layer.objects.active = malla
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    pts = [v.co.copy() for v in malla.data.vertices]
    print("  midiendo el cuerpo:")
    m = medir(pts)
    arm = armar_esqueleto(m)
    pesar(malla, arm)
    sin_peso = sum(1 for v in malla.data.vertices if not any(g.weight > 0.01 for g in v.groups))
    print("  vértices sin peso:", sin_peso, "de", len(malla.data.vertices))

    # El Polo anterior y sus animaciones.
    antes = set(bpy.data.objects)
    acciones_antes = set(bpy.data.actions)
    bpy.ops.import_scene.gltf(filepath=VIEJO)
    viejos = set(bpy.data.objects) - antes
    viejo = next(o for o in viejos if o.type == "ARMATURE")
    for b in viejo.data.bones:
        b.name = b.name.replace("mixamorig:", "")
    suyas = [a for a in bpy.data.actions if a not in acciones_antes]
    for a in suyas:
        a.name = "m_" + a.name.replace(".001", "")
    copiar_animaciones(viejo, suyas, arm)
    for o in viejos:
        bpy.data.objects.remove(o)
    for a in suyas:
        bpy.data.actions.remove(a)
    arm.animation_data.action = None
    for pb in arm.pose.bones:
        pb.rotation_quaternion = Quaternion()
        pb.location = Vector()
    bpy.ops.export_scene.gltf(filepath=SALIDA, export_format="GLB", export_animation_mode="ACTIONS",
                              export_anim_single_armature=True, export_reset_pose_bones=True, export_yup=True)
    print("LISTO", SALIDA, sorted(a.name for a in bpy.data.actions))


principal()
