# Aportes del equipo

Aquí va todo lo que quieran que entre al juego: fotos, imágenes, modelos, voces, música y sonidos. No hay que tocar nada más. Lo revisamos, lo convertimos si hace falta y lo pasamos a la carpeta del juego.

## Cómo subir un archivo

1. Pídanle a Noctem que los agregue como colaboradores del repositorio.
2. Entren a la subcarpeta que corresponda aquí en GitHub.
3. Pulsen **Add file → Upload files**, arrastren los archivos y pulsen **Commit changes**.
4. Avisen por el grupo qué subieron.

GitHub no deja subir por la página archivos de más de 25 MB. Si tienen uno más grande, súbanlo a Drive y dejen el enlace en un `.txt`.

**Este repositorio es público:** cualquiera puede ver lo que suban. No suban fotos con caras de personas ni datos personales.

## Dónde va cada cosa

| Carpeta | Qué va | Formato | Cuidados |
|---|---|---|---|
| `fotos-museo/` | Salas, pisos, puertas, planos dibujados | JPG o PNG. Videos en MP4 | En iPhone: Ajustes → Cámara → Formatos → **Más compatible** |
| `obras/` | Una imagen por obra | JPG o PNG | De frente, sin marco, sin reflejos. Mínimo 1000 px y máximo 2048 px en el lado más largo |
| `modelos/` | Modelos 3D | `.glb`, y también el `.blend` si lo hicieron en Blender | Lean [la guía de modelos](../docs/GUIA_MODELOS.md) antes de editar un personaje |
| `voces/` | Diálogos grabados | WAV o MP3 | Una línea por archivo, sin ruido de fondo. No usen notas de voz de WhatsApp |
| `musica/` | Música | OGG o MP3 | Digan en el nombre si es para sigilo, alarma o final |
| `sonidos/` | Disparos, pasos, puertas, etc. | WAV, u OGG o MP3 si son largos | Sin silencio al principio. Un sonido por archivo |
| `otros/` | Lo que no encaje arriba | El que sea | Expliquen qué es en un `.txt` |

## Cómo nombrar los archivos

```
para-que_descripcion_autor.extension
```

Son tres partes separadas por `_`, en minúsculas, sin tildes, sin ñ y sin espacios. Usen `-` entre palabras.

| Ejemplo | Qué dice |
|---|---|
| `mostro_voz-se-acabo-la-visita_ana.mp3` | Voz de Mostro con esa frase, grabada por Ana |
| `sala-1_foto-esquina-norte_pedro.jpg` | Foto de la sala 1 tomada por Pedro |
| `violencia_imagen-frontal_laura.jpg` | Imagen de la obra Violencia |
| `musica_sigilo-tension-baja_juan.mp3` | Música para los momentos de sigilo |
| `reemplaza-disparo_pistola-grabada_ana.wav` | Sonido para cambiar el `disparo` actual |
| `mostro_sombrero-negro_pedro.glb` | Mostro con sombrero nuevo |

Si necesitan explicar más, agreguen un `.txt` con el mismo nombre. Si bajaron el archivo de internet, pongan ahí el enlace de donde salió, para los créditos.
