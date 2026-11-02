# El Encargo

Juego 3D en Godot 4.7 para la clase de historia y cultura colombiana. Polo entra de noche al Museo de Arte Miguel Urrutia para desaparecer las obras que su jefe, Mostro, no quiere que nadie vuelva a ver. La idea central: robar una obra también es una forma de censura.

## Cómo abrirlo

1. Instala [Godot 4.7.2](https://godotengine.org/download/) (versión estándar, no .NET).
2. En Godot: **Importar** y elige el archivo `project.godot`.
3. Pulsa **F5** para jugar.

## Controles

| Tecla | Acción |
|---|---|
| WASD | Moverse |
| Shift | Correr (los guardias lo oyen) |
| Ctrl o C | Agacharse |
| Q / E | Asomarse a la izquierda / derecha |
| Espacio | Saltar y avanzar diálogos |
| F (mantener) | Robar, recoger y usar |
| Tab | Agenda y bolso, donde se lee la historia de cada pieza |
| Clic / R | Disparar y recargar (solo Mostro) |
| Esc | Pausa |

## Dónde está cada cosa

- `scripts/catalogo.gd`: textos de obras y coleccionables. Las fuentes están en [docs/FUENTES.md](docs/FUENTES.md).
- `scripts/mapa_prueba.gd`: mapa provisional, definido con listas de muros, puertas y posiciones.
- `arte/`: imágenes de las obras, con el nombre del `id` de cada una (por ejemplo `violencia.jpg`).
- `modelos/` y `audio/`: modelos 3D y sonidos. Las licencias están en [docs/CREDITOS.md](docs/CREDITOS.md).
- `aportes/`: archivos que sube el equipo, antes de pasar al juego. Godot ignora esta carpeta.
- `docs/GUIA_EQUIPO.md`: qué puede aportar cada integrante.
- `docs/GUIA_MODELOS.md`: cómo modificar un modelo con Blender.
- `tests/`: prueba automática que juega la misión completa.

Para correr la prueba automática:

```
Godot_v4.7.2-stable_win64_console.exe --headless --path . --fixed-fps 60 -s tests/prueba_mision.gd
```
