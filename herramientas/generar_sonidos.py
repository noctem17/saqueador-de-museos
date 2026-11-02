"""Genera sonidos provisionales en audio/. Se reemplazan grabando encima con el mismo nombre.

Ejecutar desde la raíz del proyecto:  python herramientas/generar_sonidos.py
"""
import math
import random
import struct
import wave
from pathlib import Path

TASA = 22050
DESTINO = Path("audio")
random.seed(7)


def guardar(nombre, muestras):
    pico = max(0.001, max(abs(m) for m in muestras))
    datos = b"".join(struct.pack("<h", int(max(-1, min(1, m / pico * 0.9)) * 32000)) for m in muestras)
    with wave.open(str(DESTINO / f"{nombre}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(TASA)
        w.writeframes(datos)


def n(segundos):
    return int(TASA * segundos)


def ruido():
    return random.uniform(-1, 1)


def seno(f, t):
    return math.sin(2 * math.pi * f * t)


def filtro(muestras, a):
    """Paso bajo sencillo: a pequeño = sonido más apagado."""
    salida, y = [], 0.0
    for m in muestras:
        y += a * (m - y)
        salida.append(y)
    return salida


def disparo(grave):
    largo = n(0.45)
    golpe = [ruido() * math.exp(-i / (TASA * 0.035)) for i in range(largo)]
    golpe = filtro(golpe, 0.5 if not grave else 0.22)
    cuerpo = [seno(95 * math.exp(-i / (TASA * 0.08)) + 45, i / TASA) * math.exp(-i / (TASA * 0.1)) for i in range(largo)]
    cola = filtro([ruido() * 0.25 * math.exp(-i / (TASA * 0.16)) for i in range(largo)], 0.12)
    return [g + 0.8 * c + k for g, c, k in zip(golpe, cuerpo, cola)]


def clic(t_ini, total, f=2400):
    return [
        seno(f, i / TASA) * math.exp(-(i - t_ini) / (TASA * 0.006)) + ruido() * 0.3 * math.exp(-(i - t_ini) / (TASA * 0.004))
        if i >= t_ini else 0.0
        for i in range(total)
    ]


def mezclar(*pistas):
    largo = max(len(p) for p in pistas)
    return [sum(p[i] for p in pistas if i < len(p)) for i in range(largo)]


def principal():
    DESTINO.mkdir(exist_ok=True)
    guardar("disparo", disparo(False))
    guardar("disparo_guardia", disparo(True))

    guardar("recarga", mezclar(clic(n(0.05), n(0.9), 1500), clic(n(0.45), n(0.9), 1100), clic(n(0.7), n(0.9), 1900)))
    guardar("desenfundar", mezclar(clic(n(0.03), n(0.3), 1300), clic(n(0.17), n(0.3), 1900)))

    guardar("paso", filtro([ruido() * math.exp(-i / (TASA * 0.03)) for i in range(n(0.14))], 0.1))
    guardar("impacto", filtro([ruido() * math.exp(-i / (TASA * 0.015)) for i in range(n(0.12))], 0.6))
    guardar("carne", filtro([ruido() * math.exp(-i / (TASA * 0.05)) + seno(120, i / TASA) * math.exp(-i / (TASA * 0.07)) for i in range(n(0.2))], 0.2))

    guardar("moneda", [(seno(2100, i / TASA) + 0.6 * seno(3170, i / TASA) + 0.3 * seno(4400, i / TASA)) * math.exp(-i / (TASA * 0.14)) for i in range(n(0.6))])
    guardar("papel", filtro([ruido() * math.sin(math.pi * i / n(0.25)) for i in range(n(0.25))], 0.8))
    guardar("descolgar", mezclar(
        filtro([ruido() * 0.5 * math.sin(math.pi * i / n(0.5)) for i in range(n(0.5))], 0.15),
        filtro([ruido() * math.exp(-max(0, i - n(0.45)) / (TASA * 0.05)) * (1 if i > n(0.45) else 0) for i in range(n(0.7))], 0.1),
    ))
    guardar("consola", [seno(f, i / TASA) * 0.6 for f, dur in ((900, 0.09), (1300, 0.09), (700, 0.2)) for i in range(n(dur))])
    guardar("alerta", [seno(1400, i / TASA) * (0.5 + 0.5 * seno(14, i / TASA)) * math.exp(-i / (TASA * 0.3)) for i in range(n(0.5))])

    # Timbre de teléfono: dos tonos altos alternados, una vez.
    guardar("telefono", [(seno(1000, i / TASA) + seno(1280, i / TASA)) * (1 if seno(24, i / TASA) > 0 else 0.15) * min(1, (n(1.1) - i) / 900) for i in range(n(1.1))])

    # Bucles.
    largo = n(2.0)
    guardar("alarma", [seno(620 + 330 * (1 if i < largo / 2 else 0), i / TASA) * 0.7 + 0.25 * seno(1860, i / TASA) * (1 if i % n(0.5) < n(0.3) else 0.3) for i in range(largo)])
    largo = n(6.0)
    ambiente = filtro([ruido() for _ in range(largo)], 0.02)
    guardar("ambiente", [a * 1.5 + 0.15 * seno(55, i / TASA) + 0.08 * seno(82.5, i / TASA) for i, a in enumerate(ambiente)])
    largo = n(3.5)
    motor = []
    fase = 0.0
    for i in range(largo):
        t = i / largo
        f = 60 + 150 * t
        fase += f / TASA
        motor.append(((fase % 1) * 2 - 1) * (0.5 + 0.5 * t) * min(1, t * 12))
    guardar("motor", filtro(motor, 0.25))


if __name__ == "__main__":
    principal()
    print("Sonidos en", DESTINO.resolve())
