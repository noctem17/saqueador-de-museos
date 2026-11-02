# Cómo modificar un modelo

El programa es [Blender](https://www.blender.org/download/), gratis. Estos pasos se probaron con Blender 5.2 modificando a Mostro: se le puso un sombrero, se exportó y el modelo funcionó en el juego con todas sus animaciones.

## Lo que no se puede tocar

El juego busca estas cosas por su nombre. Si cambian, el personaje deja de funcionar.

- No renombren `CharacterArmature`, los huesos ni las animaciones.
- No borren huesos ni animaciones.
- No apliquen transformaciones al esqueleto (`Ctrl + A`). Que `CharacterArmature` tenga escala 100 es normal.

## Pasos

1. Abran Blender y borren el cubo inicial.
2. Vayan a **File → Import → glTF 2.0** y abran el modelo, por ejemplo `modelos/mostro.glb`.
3. Guarden de una vez con **File → Save**, como `mostro.blend`.
4. Hagan el cambio. Vean las dos formas más abajo.
5. Vayan a **File → Export → glTF 2.0**. En **Format** elijan **glTF Binary (.glb)**, dejen lo demás como está y exporten.
6. Suban el `.glb` y el `.blend` a `aportes/modelos/`, con un nombre como `mostro_sombrero-negro_pedro.glb`.

## Agregar una pieza: sombrero, barba, reloj

Es la forma más segura. La pieza es un objeto aparte, pegado a un hueso.

1. Con **Add → Mesh** creen la pieza y acomódenla sobre el personaje.
2. Hagan clic en la pieza. Luego, con `Shift`, hagan clic en el esqueleto `CharacterArmature`.
3. Pasen a **Pose Mode** y hagan clic en el hueso que la llevará, por ejemplo `Head`.
4. Pulsen `Ctrl + P` y elijan **Bone**.

Huesos útiles: `Head` (cabeza), `Chest` (pecho), `Hips` (cadera), `Wrist.L` y `Wrist.R` (muñecas).

## Cambiar la forma del personaje

Seleccionen una parte del cuerpo (`Suit_Body`, `Suit_Head`, `Suit_Legs` o `Suit_Feet`), pulsen `Tab` y muevan los vértices que ya existen.

No agreguen vértices nuevos a estas mallas: no están unidos a los huesos y se quedan quietos cuando el personaje se mueve. Lo nuevo va como pieza aparte.

## Colores

El juego repinta algunos materiales por código, así que cambiarlos en Blender no surte efecto.

| Personaje | Materiales que pinta el juego |
|---|---|
| Polo | `Skin`, `Hair`, `Eyebrows`, `Purple`, `LightBlue` |
| Mostro | `Skin`, `Hair`, `Eyebrows`, `Suit`, `Tie` |
| Guardia | `LightBrown`, `LightBlue`, `Red_Dark`, `White`, `Hair` |

Para cambiar uno de esos colores, escríbanlo en un `.txt` junto al modelo, por ejemplo "traje gris oscuro". Las piezas nuevas sí conservan el color que les pongan en Blender, si usan un material nuevo con otro nombre.

## La barba de Mostro

La barba actual la arma el código con tres esferas y de perfil se nota. Si alguien modela una barba, se pega al hueso `Head` y se quita la del código con un cambio de una línea.

## Otros modelos

Para objetos del museo, como vitrinas, barandas o escaleras:

- Usen medidas reales: en Blender, 1 unidad es 1 metro.
- Dejen el origen del objeto en el piso.
- Si tienen imágenes como textura, expórtenlas dentro del `.glb`, que es lo que hace por defecto.
- Si bajan un modelo en otro formato, como `.fbx` u `.obj`, súbanlo tal cual con sus texturas y el enlace de donde salió.
