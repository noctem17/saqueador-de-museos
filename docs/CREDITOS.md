# Créditos de modelos y sonidos

## Modelos 3D (licencia CC0, dominio público)

Polo y Mostro (y Franchesca, la jefa final) son modelos cabezones que hizo un compañero del grupo; venían sin esqueleto y se les puso uno con `herramientas/rigear_chibi.py`, que también les copia las animaciones del paquete de Quaternius. El resto se descargó de [Poly Pizza](https://poly.pizza); los colores de ropa y carrocería se cambian desde el juego. Los `polo.glb` y `mostro.glb` de Quaternius se conservan porque de ellos salen las animaciones.

| Archivo | En el juego | Modelo original | Autor |
|---|---|---|---|
| `modelos/polo_chibi.glb` | Polo | Modelo del compañero, con esqueleto y animaciones de Quaternius | Compañero del grupo |
| `modelos/mostro_chibi.glb` | Mostro | Modelo del compañero, con esqueleto y animaciones de Quaternius | Compañero del grupo |
| `modelos/franchesca.glb` | Franchesca Marcos, jefa final | Modelo del compañero, con esqueleto y animaciones de Quaternius | Compañero del grupo |
| `modelos/franciacoptero.glb` | El ELIHCOTERO (Franchesca transformada) | Modelo del compañero; hélices separadas con `herramientas/exportar_helicoptero.py` | Compañero del grupo |
| `modelos/polo.glb` | Fuente de las animaciones | [Ultimate Modular Men Pack](https://poly.pizza/bundle/Ultimate-Modular-Men-Pack-ZiH8muWqwQ), personaje con buzo | Quaternius |
| `modelos/mostro.glb` | Sin usar (Mostro anterior) | Mismo paquete, Business Man | Quaternius |
| `modelos/guardia.glb` | Guardias | Mismo paquete, Casual | Quaternius |
| `modelos/policia.glb` | Policía | Mismo paquete, SWAT | Quaternius |
| `modelos/camioneta.glb` | Camioneta y carros | [SUV](https://poly.pizza/m/xsMtZhBkxL) | Poly Pizza, CC0 |
| `modelos/patrulla.glb` | Sin usar por ahora | [Police Car](https://poly.pizza/m/BwwnUrWGmV) | Poly Pizza, CC0 |
| `modelos/pistola.glb` | Pistola | [Pistol](https://poly.pizza/m/J3i9KDQ3kt) | Poly Pizza, CC0 |
| `modelos/banca.glb` | Bancas | [Bench](https://poly.pizza/m/jLxjFxFRpw) | Poly Pizza, CC0 |

## Imágenes de obras (`arte/`)

Las aportó el equipo en `aportes/obras/`. Solo se usan en el trabajo de clase, que no se publica ni se vende. **Falta anotar de dónde salió cada una.**

| Archivo | Obra | Fuente |
|---|---|---|
| `arte/violencia.jpg` | Violencia, Alejandro Obregón | PENDIENTE |
| `arte/decoracion.jpg` | Decoración de interiores, Beatriz González | PENDIENTE |
| `arte/lechuga.jpg` | La Lechuga (solo en el bolso) | PENDIENTE |
| `arte/policarpa.jpg` | Policarpa Salavarrieta marcha al suplicio | PENDIENTE |
| `arte/grabado_rojas.jpg` | Dibujo de Miguel Ángel Rojas (recortado) | PENDIENTE |
| `arte/septima_papeleta.jpg` | Logo de la Séptima Papeleta (recortado) | PENDIENTE |
| `arte/baligrafo.jpg` | El Balígrafo (solo en el bolso) | PENDIENTE |
| `arte/camiseta_lucho.jpg` | Lucho Herrera con la camiseta (solo en el bolso) | PENDIENTE |
| `arte/poporo_quimbaya.jpg` | Poporo Quimbaya (solo en el bolso) | PENDIENTE |

## Sonidos

Los archivos de `audio/` son provisionales, generados por `herramientas/generar_sonidos.py`. Para reemplazar uno, guarda el nuevo archivo con el mismo nombre en formato WAV.

Excepciones:

| Archivo | En el juego | Fuente |
|---|---|---|
| `audio/helicoptero.wav` | Hélices del ELIHCOTERO | Freesound 854493, "UH60 Black Hawk helicopter hover loop", de qubodup (licencia PENDIENTE de revisar en la página) |
| `audio/musica/jefe_final.mp3` | Pelea contra el ELIHCOTERO | "Vordt of the Boreal Valley", banda sonora de *Dark Souls III* (Motoi Sakuraba, FromSoftware). Con derechos de autor: solo va dentro del .exe para la clase; la carpeta está excluida del repositorio |
| `audio/frenazo.wav` | Frenazo de la camioneta ante Franchesca | `aportes/sonidos/olenchic--110065.mp3` (Freesound, olenchic; licencia PENDIENTE de revisar), recortado desde el segundo 3.3 |
| `audio/paso_1.wav` a `paso_4.wav` | Pasos (suena uno al azar) | `aportes/sonidos/pasos.mp3` (fuente PENDIENTE), cortado en cuatro pasos sueltos |
| `audio/musica/mostro.mp3` | Entrada de Mostro y mientras se juega con él | "AURA", de Ogryzek. Con derechos de autor: solo va dentro del .exe; la carpeta está excluida del repositorio |
