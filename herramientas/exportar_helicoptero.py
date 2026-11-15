"""Exporta el helicóptero de Franchesca (aportes/modelos/FRANCIACOPTERO.blend) para Godot.

Uso: blender -b aportes/modelos/FRANCIACOPTERO.blend --python herramientas/exportar_helicoptero.py -- FOTO.png SALIDA.glb

El modelo viene en una sola malla. Para que las hélices giren en el juego se separan
en dos objetos ("Helice" y "HeliceCola") con su centro en el eje de giro; el resto
queda como "Cuerpo". La foto de la trompa se empaqueta dentro del .glb.
"""
import sys
import bpy
from mathutils import Vector

FOTO, SALIDA = sys.argv[sys.argv.index("--") + 1:]
img = bpy.data.images["franciesita.png"]
img.filepath = FOTO
img.reload()
img.pack()

o = bpy.data.objects["default Cube"]
bpy.ops.object.select_all(action='DESELECT')
bpy.context.view_layer.objects.active = o
o.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.mesh.separate(type='LOOSE')
bpy.ops.object.mode_set(mode='OBJECT')
partes = list(bpy.context.selected_objects)


def caja(p):
    ws = [p.matrix_world @ v.co for v in p.data.vertices]
    return Vector((min(w.x for w in ws), min(w.y for w in ws), min(w.z for w in ws))), Vector((max(w.x for w in ws), max(w.y for w in ws), max(w.z for w in ws)))


helice, cola, cuerpo = [], [], []
for p in partes:
    mn, mx = caja(p)
    if mn.z >= 1.7:                      # Aspas y buje de arriba.
        helice.append(p)
    elif mn.x > 0.05 and mn.y > 5.5:     # Hélice chica al lado de la cola.
        cola.append(p)
    else:
        cuerpo.append(p)


def juntar(lista, nombre, eje):
    bpy.ops.object.select_all(action='DESELECT')
    for p in lista:
        p.select_set(True)
    bpy.context.view_layer.objects.active = lista[0]
    if len(lista) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    obj.name = nombre
    if eje is not None:
        bpy.context.scene.cursor.location = eje
        bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    return obj


juntar(helice, "Helice", Vector((0.0, -0.9, 1.85)))
juntar(cola, "HeliceCola", Vector((0.13, 6.71, 0.43)))
juntar(cuerpo, "Cuerpo", None)
print("PARTES", len(helice), len(cola), len(cuerpo))
bpy.ops.object.select_all(action='DESELECT')
for n in ("Helice", "HeliceCola", "Cuerpo"):
    bpy.data.objects[n].select_set(True)
bpy.ops.export_scene.gltf(filepath=SALIDA, export_format='GLB', use_selection=True)
print("EXPORTADO", SALIDA)
