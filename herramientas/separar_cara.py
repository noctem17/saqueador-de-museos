"""Separa la cara de un modelo de Tripo para poder ponerle una foto encima.

La textura de Tripo es una sola imagen de 512 px para todo el cuerpo, con la cara
regada en pedazos: no hay forma de pegarle una foto. Este script:
  1. Toma los triángulos del frente de la cabeza (los que mueve el hueso Head y
     miran hacia adelante) y los pasa a un objeto aparte, "Cara".
  2. Les hace un mapa UV de frente, como una foto de documento: lo de arriba de la
     imagen es la frente, lo de abajo la barbilla.
  3. Copia la cara que tenía el modelo a esa imagen (horneado de Cycles) y la guarda
     en aportes/caras/cara_<nombre>.png, 1024 px.
Si la imagen ya existe (porque alguien le pegó una foto), no la pisa: la usa.

Lo llama herramientas/rigear_mixamo.py al preparar el modelo. Para ver el resultado
en Blender, sin el resto del proceso:
  blender -b --factory-startup --python herramientas/separar_cara.py -- polo
  (guarda aportes/modelos/<nombre>_cara_separada.blend)
"""
import os
import sys

import bmesh
import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CARAS = os.path.join(RAIZ, "aportes", "caras")
LADO = 1024


def ruta_imagen(nombre: str) -> str:
    return os.path.join(CARAS, "cara_%s.png" % nombre)


def separar(malla, nombre: str, hueso_cabeza: str = "Head"):
    """Devuelve el objeto nuevo con la cara. `malla` debe tener los grupos de huesos."""
    grupo = malla.vertex_groups.get(hueso_cabeza)
    if grupo is None:
        raise RuntimeError("La malla no tiene el grupo " + hueso_cabeza)
    peso = {}
    for v in malla.data.vertices:
        for g in v.groups:
            if g.group == grupo.index:
                peso[v.index] = g.weight
    mundo = malla.matrix_world
    # Hacia dónde mira el modelo: del centro de la cabeza a los vértices más
    # salidos del frente (la nariz). En los modelos de Tripo es -Y.
    adelante = Vector((0, -1, 0))
    cabeza = [mundo @ malla.data.vertices[i].co for i, w in peso.items() if w > 0.5]
    centro = sum(cabeza, Vector()) / len(cabeza)
    alto_cabeza = max(p.z for p in cabeza) - min(p.z for p in cabeza)
    # Para descartar lo que queda escondido detrás (dentro de la boca, el fondo de
    # los ojos): solo entra un triángulo si, mirando desde el frente, es lo primero
    # que se ve.
    puntos = [mundo @ v.co for v in malla.data.vertices]
    arbol = BVHTree.FromPolygons(puntos, [tuple(p.vertices) for p in malla.data.polygons])
    caras = []
    for p in malla.data.polygons:
        if not all(peso.get(i, 0.0) > 0.5 for i in p.vertices):
            continue
        normal = (mundo.to_3x3() @ p.normal).normalized()
        pos = mundo @ p.center
        # Del frente, sin la coronilla ni la nuca.
        if normal.dot(adelante) > 0.2 and (pos - centro).dot(adelante) > 0.0 and pos.z < centro.z + alto_cabeza * 0.42:
            _, _, indice, _ = arbol.ray_cast(pos + adelante * 1.0, -adelante)
            if indice == p.index:
                caras.append(p.index)
    print("  cara: %d triángulos de %d" % (len(caras), len(malla.data.polygons)))

    # Separar.
    bpy.ops.object.select_all(action="DESELECT")
    malla.select_set(True)
    bpy.context.view_layer.objects.active = malla
    bpy.ops.object.mode_set(mode="EDIT")
    bm = bmesh.from_edit_mesh(malla.data)
    bm.faces.ensure_lookup_table()
    for f in bm.faces:
        f.select_set(False)
    for i in caras:
        bm.faces[i].select_set(True)
    bmesh.update_edit_mesh(malla.data)
    bpy.ops.mesh.separate(type="SELECTED")
    bpy.ops.object.mode_set(mode="OBJECT")
    cara = [o for o in bpy.context.selected_objects if o != malla][0]
    cara.name = "Cara"

    # UV de frente.
    uv_original = cara.data.uv_layers[0].name
    foto = cara.data.uv_layers.new(name="Foto")
    pts = [cara.matrix_world @ v.co for v in cara.data.vertices]
    xs = [p.x for p in pts]
    zs = [p.z for p in pts]
    tam = max(max(xs) - min(xs), max(zs) - min(zs)) * 1.1
    cx = (max(xs) + min(xs)) * 0.5
    cz = (max(zs) + min(zs)) * 0.5
    for bucle in cara.data.loops:
        p = cara.matrix_world @ cara.data.vertices[bucle.vertex_index].co
        foto.data[bucle.index].uv = ((p.x - cx) / tam + 0.5, (p.z - cz) / tam + 0.5)

    # Material propio.
    original = cara.data.materials[0]
    textura_original = next(n.image for n in original.node_tree.nodes if n.type == "TEX_IMAGE")
    os.makedirs(CARAS, exist_ok=True)
    ruta = ruta_imagen(nombre)
    if not os.path.exists(ruta):
        _hornear(cara, textura_original, uv_original, foto.name, ruta)
    imagen = bpy.data.images.load(ruta, check_existing=True)
    mat = bpy.data.materials.new("Cara")
    mat.use_nodes = True
    nodos = mat.node_tree.nodes
    bsdf = nodos["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 0.9
    tex = nodos.new("ShaderNodeTexImage")
    tex.image = imagen
    mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    cara.data.materials.clear()
    cara.data.materials.append(mat)
    # Solo queda el UV de frente.
    cara.data.uv_layers.remove(cara.data.uv_layers[uv_original])
    cara.data.uv_layers.active = cara.data.uv_layers["Foto"]
    return cara


def _hornear(cara, textura, uv_original, uv_foto, ruta):
    """Copia la cara que ya tenía el modelo a la imagen nueva, con el UV de frente."""
    escena = bpy.context.scene
    motor = escena.render.engine
    escena.render.engine = "CYCLES"
    escena.cycles.device = "CPU"
    escena.cycles.samples = 1
    destino = bpy.data.images.new("cara_horneada", LADO, LADO)
    mat = bpy.data.materials.new("hornear")
    mat.use_nodes = True
    n = mat.node_tree.nodes
    n.clear()
    uv = n.new("ShaderNodeUVMap")
    uv.uv_map = uv_original
    tex = n.new("ShaderNodeTexImage")
    tex.image = textura
    emi = n.new("ShaderNodeEmission")
    sal = n.new("ShaderNodeOutputMaterial")
    l = mat.node_tree.links
    l.new(uv.outputs["UV"], tex.inputs["Vector"])
    l.new(tex.outputs["Color"], emi.inputs["Color"])
    l.new(emi.outputs["Emission"], sal.inputs["Surface"])
    objetivo = n.new("ShaderNodeTexImage")
    objetivo.image = destino
    n.active = objetivo
    cara.data.materials.clear()
    cara.data.materials.append(mat)
    cara.data.uv_layers.active = cara.data.uv_layers[uv_foto]
    bpy.ops.object.select_all(action="DESELECT")
    cara.select_set(True)
    bpy.context.view_layer.objects.active = cara
    bpy.ops.object.bake(type="EMIT", margin=16)
    destino.filepath_raw = ruta
    destino.file_format = "PNG"
    destino.save()
    escena.render.engine = motor
    print("  cara horneada en", ruta)


if __name__ == "__main__":
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import rigear_mixamo
    nombre = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "polo"
    archivo = rigear_mixamo.MODELOS[nombre][0]
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.join(RAIZ, "aportes", "modelos", archivo))
    for o in list(bpy.data.objects):
        if o.type == "MESH" and not o.vertex_groups:
            bpy.data.objects.remove(o)
    malla = next(o for o in bpy.data.objects if o.type == "MESH")
    separar(malla, nombre, "mixamorig:Head")
    salida = os.path.join(RAIZ, "aportes", "modelos", nombre + "_cara_separada.blend")
    bpy.ops.wm.save_as_mainfile(filepath=salida)
    print("LISTO", salida)
