"""Pasa los sonidos que manda el equipo (aportes/) a audio/, recortados y a buen volumen.

Usa el módulo de audio de Blender (no hace falta instalar nada). Uso:
  blender -b --factory-startup --python herramientas/preparar_audios.py

Cada fila: origen, destino (sin extensión; sale .wav), desde (s), hasta (s, None = al
final), volumen máximo (0-1; None = no tocar), desvanecer al final (s).
La música se copia tal cual en MP3 (COPIAR), porque pesa menos.
"""
import os
import shutil

import aud
import numpy as np

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
S = os.path.join(RAIZ, "aportes", "sonidos")
M = os.path.join(RAIZ, "aportes", "musica")
A = os.path.join(RAIZ, "audio")

RECORTAR = [
    # El archivo trae dos lanzamientos; se usa el primero (1.0 s a 4.4 s).
    ("sonido de misil.mp3", "misil", 0.95, 4.4, 0.8, 0.8),
    ("854493__qubodup__uh60-black-hawk-helicopter-hover-loop-1.wav", "helicoptero", 0.0, None, 0.9, 0.0),
    ("recarga lanzacohetes.mp3", "recarga_cohete", 0.0, None, 0.85, 0.1),
    ("gun reload.mp3", "recarga", 0.0, None, 0.85, 0.1),
    ("cristal rompiendose.wav", "cristal", 0.0, None, 0.8, 0.3),
    ("701326__sef7__walkie-talkie-famous-beep.wav", "radio", 0.0, None, 0.7, 0.0),
    ("476740__cjdeets__shotscifipowerdown.wav", "apagon", 0.0, None, 0.8, 0.2),
    ("476741__cjdeets__shotscifipowerdownbuildshorthighs.wav", "mecanismo", 0.0, None, 0.8, 0.3),
]

COPIAR = [
    ("conexion.mp3", "conexion.mp3"),            # Sala de la espada y sala del MAMBO.
]

# Estos dos dicen .mp3 pero en realidad son M4A (audio de celular), que Godot no
# lee: se convierten a OGG.
CONVERTIR = [
    ("obreas de arte1.mp3", "obra_robada"),      # Al robar una obra de la lista.
    ("obras de arte2.mp3", "bolso"),             # Con la agenda / el bolso abierto.
]


def recortar(origen, destino, desde, hasta, pico, desvanecer):
    s = aud.Sound(os.path.join(S, origen))
    tasa = int(s.specs[0])
    datos = s.data()   # muestras x canales
    ini = int(desde * tasa)
    fin = len(datos) if hasta is None else int(hasta * tasa)
    datos = datos[ini:fin].copy()
    if pico:
        maximo = float(np.abs(datos).max())
        if maximo > 0:
            datos *= pico / maximo
    if desvanecer > 0:
        n = min(len(datos), int(desvanecer * tasa))
        datos[-n:] *= np.linspace(1.0, 0.0, n)[:, None]
    salida = aud.Sound.buffer(datos.astype(np.float32), tasa)
    ruta = os.path.join(A, destino + ".wav")
    salida.write(ruta, rate=tasa, channels=datos.shape[1], format=aud.FORMAT_S16,
                 container=aud.CONTAINER_WAV, codec=aud.CODEC_PCM)
    print("listo", ruta, round(len(datos) / tasa, 2), "s")


for fila in RECORTAR:
    recortar(*fila)
for origen, destino in COPIAR:
    shutil.copyfile(os.path.join(M, origen), os.path.join(A, destino))
    print("copiado", destino)
# Voz de Elcacas cuando sale de la oscuridad.
shutil.copyfile(os.path.join(S, "dialogo el cacas.mp3"), os.path.join(A, "elcacas_voz.mp3"))
print("copiado elcacas_voz.mp3")
for origen, destino in CONVERTIR:
    s = aud.Sound(os.path.join(M, origen))
    ruta = os.path.join(A, destino + ".ogg")
    s.write(ruta, rate=int(s.specs[0]), channels=int(s.specs[1]), format=aud.FORMAT_FLOAT32,
            container=aud.CONTAINER_OGG, codec=aud.CODEC_VORBIS, bitrate=160000)
    print("convertido", ruta)
