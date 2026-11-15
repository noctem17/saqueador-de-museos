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


def guardar(nombre, muestras, pico_final=0.9):
    """pico_final: qué tan fuerte queda el archivo (0.9 = casi al máximo)."""
    pico = max(0.001, max(abs(m) for m in muestras))
    datos = b"".join(struct.pack("<h", int(max(-1, min(1, m / pico * pico_final)) * 32000)) for m in muestras)
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


def paso_suave():
    """Zapato sobre madera: talón sordo y punta más suave, con ataque gradual.
    Usa su propio generador al azar para no cambiar los demás sonidos."""
    azar = random.Random(11)
    largo = n(0.2)

    def golpe(inicio, fuerza, decae, brillo):
        crudo = []
        for i in range(largo):
            k = i - inicio
            if k < 0:
                crudo.append(0.0)
                continue
            subida = min(1.0, k / n(0.006))   # 6 ms de subida: sin chasquido.
            crudo.append(azar.uniform(-1, 1) * fuerza * subida * math.exp(-k / (TASA * decae)))
        return filtro(filtro(crudo, brillo), brillo)

    talon = golpe(0, 1.0, 0.022, 0.05)
    punta = golpe(n(0.05), 0.45, 0.03, 0.09)
    roce = golpe(n(0.01), 0.12, 0.06, 0.35)
    return [a + b + c for a, b, c in zip(talon, punta, roce)]


def lluvia():
    """Bucle de lluvia: siseo suave y gotas sueltas. Las puntas se funden para
    que no se note el corte al repetirse."""
    azar = random.Random(21)
    largo = n(4.0)
    siseo = filtro(filtro([azar.uniform(-1, 1) for _ in range(largo)], 0.35), 0.5)
    gotas = [0.0] * largo
    for _ in range(260):
        ini = azar.randrange(largo)
        fuerza = azar.uniform(0.2, 0.8)
        f = azar.uniform(1800, 4200)
        for k in range(n(0.012)):
            if ini + k < largo:
                gotas[ini + k] += math.sin(2 * math.pi * f * k / TASA) * fuerza * math.exp(-k / (TASA * 0.003))
    mezcla = [a * 0.7 + b * 0.35 for a, b in zip(siseo, gotas)]
    cruce = n(0.4)
    for i in range(cruce):
        t = i / cruce
        mezcla[i] = mezcla[i] * t + mezcla[largo - cruce + i] * (1 - t)
    return mezcla[:largo - cruce]


def trueno():
    """Crujido inicial y retumbo largo y grave."""
    azar = random.Random(31)
    largo = n(4.5)
    crujido = filtro([azar.uniform(-1, 1) * math.exp(-i / (TASA * 0.12)) for i in range(largo)], 0.3)
    retumbo = filtro(filtro([azar.uniform(-1, 1) for _ in range(largo)], 0.02), 0.05)
    salida = []
    for i in range(largo):
        t = i / TASA
        sube = min(1.0, t / 0.15)
        olas = 0.6 + 0.4 * math.sin(2 * math.pi * 1.3 * t) * math.sin(2 * math.pi * 0.45 * t)
        salida.append(crujido[i] * 0.5 + retumbo[i] * 9.0 * sube * olas * math.exp(-t / 1.6))
    return salida


def frenazo():
    """Llantas chillando sobre el asfalto mojado."""
    azar = random.Random(41)
    largo = n(1.7)
    salida = []
    fase = 0.0
    for i in range(largo):
        t = i / TASA
        f = 1900 + 120 * math.sin(2 * math.pi * 7 * t) - 500 * t
        fase += f / TASA
        env = min(1.0, t / 0.05) * (1.0 if t < 1.2 else max(0.0, 1 - (t - 1.2) / 0.5))
        salida.append((math.sin(2 * math.pi * fase) * 0.5 + azar.uniform(-1, 1) * 0.35) * env)
    return filtro(salida, 0.6)


def pose():
    """Golpe de pose de superhéroe: un zumbido que sube y un golpe grave."""
    azar = random.Random(51)
    largo = n(0.55)
    salida = []
    fase = 0.0
    for i in range(largo):
        t = i / TASA
        zumbido = 0.0
        if t < 0.18:
            f = 300 + 2400 * (t / 0.18) ** 2
            fase += f / TASA
            zumbido = (math.sin(2 * math.pi * fase) * 0.3 + azar.uniform(-1, 1) * 0.4) * (t / 0.18)
        golpe = 0.0
        if t >= 0.18:
            k = t - 0.18
            golpe = (math.sin(2 * math.pi * (70 + 60 * math.exp(-k * 30)) * k) * 1.2 + azar.uniform(-1, 1) * 0.5 * math.exp(-k * 40)) * math.exp(-k * 7)
        salida.append(zumbido + golpe)
    return filtro(salida, 0.5)


def humo():
    """Estallido de humo: soplido fuerte que se apaga despacio."""
    azar = random.Random(61)
    largo = n(2.2)
    crudo = [azar.uniform(-1, 1) * min(1.0, i / n(0.03)) * math.exp(-i / (TASA * 0.6)) for i in range(largo)]
    grave = [math.sin(2 * math.pi * 45 * i / TASA) * math.exp(-i / (TASA * 0.35)) for i in range(largo)]
    return [a * 0.8 + b for a, b in zip(filtro(filtro(crudo, 0.12), 0.2), grave)]


def explosion():
    """Explosión grande: estallido seco y retumbo que se apaga."""
    azar = random.Random(71)
    largo = n(2.4)
    estallido = filtro([azar.uniform(-1, 1) * math.exp(-i / (TASA * 0.08)) for i in range(largo)], 0.4)
    retumbo = filtro(filtro([azar.uniform(-1, 1) * math.exp(-i / (TASA * 0.7)) for i in range(largo)], 0.03), 0.06)
    golpe = [math.sin(2 * math.pi * (38 + 40 * math.exp(-i / (TASA * 0.1))) * i / TASA) * math.exp(-i / (TASA * 0.4)) for i in range(largo)]
    return [a * 0.9 + b * 7.0 + c * 0.9 for a, b, c in zip(estallido, retumbo, golpe)]


def cohete():
    """Salida del cohete: golpe hueco y siseo que se aleja."""
    azar = random.Random(81)
    largo = n(1.3)
    salida = []
    for i in range(largo):
        t = i / TASA
        golpe = math.sin(2 * math.pi * 60 * t) * math.exp(-t * 18)
        siseo = azar.uniform(-1, 1) * min(1.0, t / 0.02) * math.exp(-t * 2.2)
        salida.append(golpe * 1.2 + siseo * 0.7)
    return filtro(salida, 0.35)


def misil():
    """Misil que viene: silbido que baja de tono."""
    azar = random.Random(91)
    largo = n(1.6)
    salida = []
    fase = 0.0
    for i in range(largo):
        t = i / TASA
        f = 1500 - 700 * (t / 1.6)
        fase += f / TASA
        env = min(1.0, t / 0.3)
        salida.append((math.sin(2 * math.pi * fase) * 0.5 + azar.uniform(-1, 1) * 0.15) * env)
    return filtro(salida, 0.5)


def principal():
    DESTINO.mkdir(exist_ok=True)
    guardar("disparo", disparo(False))
    guardar("disparo_guardia", disparo(True))

    guardar("recarga", mezclar(clic(n(0.05), n(0.9), 1500), clic(n(0.45), n(0.9), 1100), clic(n(0.7), n(0.9), 1900)))
    guardar("desenfundar", mezclar(clic(n(0.03), n(0.3), 1300), clic(n(0.17), n(0.3), 1900)))

    for _ in range(n(0.14)):   # Gasta el azar del paso viejo: así los demás sonidos no cambian.
        ruido()
    guardar("paso", paso_suave(), 0.45)
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

    # Escena de la carretera (cada uno con su propio azar: no cambia los anteriores).
    guardar("lluvia", lluvia(), 0.5)
    guardar("trueno", trueno(), 0.9)
    # frenazo.wav ya no se genera: es una grabación (ver docs/CREDITOS.md).
    guardar("pose", pose(), 0.8)
    guardar("humo", humo(), 0.85)
    guardar("explosion", explosion(), 0.95)
    guardar("cohete", cohete(), 0.85)
    guardar("misil", misil(), 0.6)


if __name__ == "__main__":
    import sys
    if "--solo" in sys.argv:
        # Solo los nombrados, p. ej.:  --solo lluvia trueno
        for nombre in sys.argv[sys.argv.index("--solo") + 1:]:
            guardar(nombre, globals()[nombre](), {"lluvia": 0.5, "frenazo": 0.7, "pose": 0.8, "humo": 0.85, "explosion": 0.95, "cohete": 0.85, "misil": 0.6}.get(nombre, 0.9))
        raise SystemExit
    principal()
    print("Sonidos en", DESTINO.resolve())
