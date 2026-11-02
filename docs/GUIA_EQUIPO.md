# Guía para el equipo

Nadie necesita programar ni modelar. Estas son las tareas que más ayudan, de la más importante a la menos importante.

## 1. Fotos y plano del museo

Antes de ir, pregunten en el museo si se pueden tomar fotos.

- Dibujen en una hoja una planta por piso: salas, puertas, escaleras y baños. Las medidas pueden ser a pasos, no tienen que ser exactas.
- Tomen una foto general de cada sala desde cada esquina.
- Fotografíen pisos, paredes, puertas, barandas y el parqueadero, si se puede ver.
- Anoten qué obras hay en cada sala y dónde están las cámaras visibles.

## 2. Imágenes de las obras

Una imagen por obra, de frente y sin marco, en JPG o PNG, guardada en la carpeta `arte/` con exactamente este nombre:

| Obra | Archivo |
|---|---|
| Violencia, Alejandro Obregón | `violencia.jpg` |
| Decoración de interiores, Beatriz González | `decoracion.jpg` |
| Retratos mudos, Beatriz González | `retratos_mudos.jpg` |
| Mandolina, Fernando Botero | `mandolina.jpg` |
| Monjas muertas, atribuido a Victorino García Romero | `monjas.jpg` |

El juego las usa solo, no hay que cambiar nada más.

## 3. Voces

Graben con el celular en un cuarto silencioso. Una línea por archivo, en MP3 o WAV. Los diálogos están en `scripts/mision.gd`, y las razones de Mostro en `scripts/catalogo.gd`, en el campo `razon`.

- Una persona hace de Mostro: voz grave, tranquila y amenazante.
- Otra hace de Polo: voz baja, de alguien que no quiere que lo oigan.
- Nombres de archivo: `mostro_01.mp3`, `mostro_02.mp3`, `polo_01.mp3`, y así sucesivamente.

## 4. Sonidos

Los sonidos actuales son provisionales. Para cambiar uno, guarden el nuevo como WAV en `audio/` con el mismo nombre. Pueden grabarlos o bajarlos de [Kenney](https://kenney.nl/assets/category:Audio) o [Freesound](https://freesound.org) (busquen licencia CC0):

`disparo`, `disparo_guardia`, `recarga`, `desenfundar`, `paso`, `impacto`, `carne`, `moneda`, `papel`, `descolgar`, `consola`, `alerta`, `telefono`, `alarma`, `ambiente` y `motor`.

## 5. Revisar la historia

Lean `scripts/catalogo.gd` y `docs/FUENTES.md`. Si un dato está mal o el profesor enseñó otra versión, anótenlo con la fuente.

## Modelos 3D

Los personajes y carros ya usan modelos gratuitos con animaciones (ver [CREDITOS.md](CREDITOS.md)), así que no hace falta modelarlos. Si alguien quiere intentarlo, el programa es [Blender](https://www.blender.org/), que es gratis, y el formato de entrega es `.glb`. Lo más útil sería un objeto propio del museo, como barandas, vitrinas o la escalera.
