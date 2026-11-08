# El Encargo

Juego 3D en Godot 4.7 para la clase de historia y cultura colombiana. Polo entra de noche al Museo Nacional de Colombia, el antiguo Panóptico, donde están en préstamo unas obras del Museo de Arte Miguel Urrutia. Su jefe, Mostro, quiere que nadie las vuelva a ver. La idea central: robar una obra también es una forma de censura.

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
- `scripts/mapa_museo_nacional.gd`: el Museo Nacional con sus tres pisos, la cruz del Panóptico, la muralla con garitas, la fachada y los jardines de la entrada.
- `scripts/mapa.gd`: herramientas comunes de los mapas. Junta las piezas en pocas mallas para que el juego vaya rápido. `scripts/mapa_prueba.gd` es el mapa viejo, de respaldo.
- `shaders/bloques.gdshader`: dibuja la piedra, la madera y las baldosas sin usar imágenes.
- `arte/`: imágenes de las obras, con el nombre del `id` de cada una (por ejemplo `violencia.jpg`).
- `modelos/` y `audio/`: modelos 3D y sonidos. Las licencias están en [docs/CREDITOS.md](docs/CREDITOS.md).
- `aportes/`: archivos que sube el equipo, antes de pasar al juego. Godot ignora esta carpeta.
- `docs/GUIA_EQUIPO.md`: qué puede aportar cada integrante.
- `docs/GUIA_MODELOS.md`: cómo modificar un modelo con Blender.
- `tests/`: prueba automática que juega la misión completa, y `vistas_museo.tscn`, que saca fotos del mapa en `capturas/`.

Para correr la prueba automática:

```
Godot_v4.7.2-stable_win64_console.exe --headless --path . --fixed-fps 60 -s tests/prueba_mision.gd
```
