# Guía para el equipo

Nadie necesita programar ni modelar. Estas son las tareas que más ayudan, de la más importante a la menos importante.

Todo se sube a la carpeta [`aportes/`](../aportes/README.md). Ahí está cómo subir los archivos, cómo nombrarlos y qué formato usar.

## 1. Fotos y plano del museo

Antes de ir, pregunten en el museo si se pueden tomar fotos.

- Dibujen en una hoja una planta por piso: salas, puertas, escaleras y baños. Las medidas pueden ser a pasos, no tienen que ser exactas.
- Tomen una foto general de cada sala desde cada esquina.
- Fotografíen pisos, paredes, puertas, barandas y el parqueadero, si se puede ver.
- Anoten qué obras hay en cada sala y dónde están las cámaras visibles.

## 2. Imágenes de las obras

Una imagen por obra, de frente y sin marco, en `aportes/obras/`:

- *Violencia*, Alejandro Obregón
- *Decoración de interiores*, Beatriz González
- *Retratos mudos*, Beatriz González
- *Mandolina*, Fernando Botero
- *Monjas muertas*, atribuido a Victorino García Romero
- *Chatarra*, Feliza Bursztyn
- *Aparato mágico*, Édgar Negret
- *La Lechuga*, José de Galaz

## 3. Voces

Graben con la grabadora del celular en un cuarto silencioso. Una línea por archivo, en `aportes/voces/`. Los diálogos están en `scripts/mision.gd`, y las razones de Mostro en `scripts/catalogo.gd`, en el campo `razon`.

- Una persona hace de Mostro: voz grave, tranquila y amenazante.
- Otra hace de Polo: voz baja, de alguien que no quiere que lo oigan.

## 4. Música y sonidos

Los sonidos actuales son provisionales. Para cambiar uno, súbanlo a `aportes/sonidos/` y digan cuál reemplaza. Pueden grabarlos o bajarlos de [Kenney](https://kenney.nl/assets/category:Audio) o [Freesound](https://freesound.org) (busquen licencia CC0):

`disparo`, `disparo_guardia`, `recarga`, `desenfundar`, `paso`, `impacto`, `carne`, `moneda`, `papel`, `descolgar`, `consola`, `alerta`, `telefono`, `alarma`, `ambiente` y `motor`.

La música va en `aportes/musica/`.

## 5. Revisar la historia

Lean `scripts/catalogo.gd` y `docs/FUENTES.md`. Si un dato está mal o el profesor enseñó otra versión, anótenlo con la fuente.

## Modelos 3D

Los personajes y carros ya usan modelos gratuitos con animaciones (ver [CREDITOS.md](CREDITOS.md)), así que no hace falta modelarlos. Para modificar uno o hacer uno nuevo, sigan la [guía de modelos](GUIA_MODELOS.md). Lo más útil sería un objeto propio del museo, como barandas, vitrinas o la escalera.
