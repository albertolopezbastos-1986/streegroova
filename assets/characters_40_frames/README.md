# Prueba anterior de animaciones de 40 cuadros

**El nuevo destino es [`characters_20_frames`](../characters_20_frames/README.md): las próximas animaciones serán de 20 cuadros.** Esta carpeta conserva los archivos anteriores y el primer golpe activo de 40 cuadros. La nueva hoja `grabthrow.png` se copió a la estructura de 20 y se integró desde allí.

Estas carpetas están separadas de las versiones que usa el juego:

```text
assets/characters_40_frames/
  beto/
    character.json
    animations/
      idle/idle.png
      walk/walk.png
      run/
      grab_throw/
      grab_punch_01/
      grab_punch_02/
      grab_punch_03/
      attack_01/firstpunch.png
      attack_02/secondpunch.png
      attack_03/thirdpunch.png
      jump/jump.png
      jump_attack/flykick.png
      hurt/damage.png
      death/ko.png
    portraits/
    extras/
    source/
  alito/    (misma estructura)
  cami/     (misma estructura)
```

Las carpetas de imágenes están vacías: colocá allí las **nuevas versiones de 40 cuadros**, una hoja PNG completa por movimiento. Podés usar los mismos nombres que en las versiones anteriores porque están en otra ubicación. Los nombres del árbol son los que esperan las plantillas; si conservás otros nombres, actualizaremos el campo `file`.

- Preferí PNG transparente, sin agrandar ni recortar previamente los cuadros.
- Una cuadrícula de **8 columnas × 5 filas** es una opción cómoda para 40 cuadros; también sirve otra distribución. Anotá columnas, filas y tamaño de cada celda cuando los conozcas.
- El orden previsto es de izquierda a derecha y de arriba abajo.
- `character.json` ya tiene las secuencias de 0 a 39; las dimensiones y la cuadrícula quedan pendientes hasta ver las imágenes.
- Los 24 FPS de las plantillas son orientativos. Antes de probar se ajustarán duración y cuadros de impacto: tener más imágenes no debería hacer más lentos los golpes por accidente.
- La ulti reutiliza `attack_03`, como ahora. Si tenés una animación de ulti independiente, ponela en `extras/ultimate/` para conectarla después.
- Si tenés PNG individuales en vez de una hoja, podés guardarlos numerados (`idle_000.png` a `idle_039.png`) en la carpeta del movimiento. Antes de activarlos habrá que adaptar el cargador o preparar una hoja.
- Los editables y las referencias van en `source/`, que Godot ignora; los retratos van en `portraits/`.

**El primer golpe de Beto ya está activo:** su manifiesto principal referencia `beto/animations/attack_01/firstpunch.png` de esta carpeta. Tiene 7 columnas × 6 filas, cuadros de 200 × 200 y reproduce los índices 0–39; las celdas 40 y 41 están vacías y se omiten. Los cuadros de impacto son 13–22. Usa aproximadamente 97,78 FPS para conservar los 0,409 segundos del golpe anterior. La reproducción se ajusta al tiempo real; en una pantalla de 60 Hz no se dibujarán los 40 cuadros en cada golpe.

El resto del juego sigue usando las animaciones de `assets/characters/`. No se activó el conjunto incompleto de 40 cuadros. Cuando esté completo se podrá probar cambiando la ruta `definition` del personaje en `assets/characters/roster.json`, por ejemplo a `res://assets/characters_40_frames/beto/character.json`, y reexportando Web. No cambies la ruta antes de completar y revisar las hojas.

## Nuevos movimientos: correr y agarres

Carpetas preparadas para Beto, Alito y Cami dentro de `animations/`:

| Carpeta | Movimiento |
| --- | --- |
| `grab_throw/` | Agarrar y lanzar. |
| `grab_punch_01/` | Primer golpe durante el agarre. |
| `grab_punch_02/` | Segundo golpe durante el agarre. |
| `grab_punch_03/` | Tercer golpe durante el agarre. |
| `run/` | Correr. |

Colocá una hoja PNG por movimiento en su carpeta, conservando el tamaño original y la transparencia. Estas carpetas también existen en la otra estructura de personajes (originales / 40 cuadros). Son espacios para recibir los sprites: los movimientos y sus metadatos se integrarán cuando estén las imágenes.

La carpeta `animations/runslide/` de Beto, Alito y Cami está preparada para la hoja del golpe durante la carrera. Colocá allí los sprites; su animación se conectará cuando esté disponible la hoja.

Las carpetas `animations/punch_weapon/` de Beto, Alito y Cami están preparadas para el golpe con palo o caño. El juego usa un alias provisional del primer golpe hasta recibir las hojas.

Los tres personajes tienen las carpetas animations/crouch/ y animations/ultimate_air/. La hoja activa de agacharse de Beto tiene 8 cuadros y vive en assets/characters/beto/animations/crouch/. Las carpetas de ulti aérea están listas para recibir sprites propios.
