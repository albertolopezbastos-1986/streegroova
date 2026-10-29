# Sprites de Beto, Alito y Cami

Las variantes de prueba de **40 cuadros** tienen su propia estructura en [`../characters_40_frames/`](../characters_40_frames/README.md), separada de estos sprites.

Cada personaje usa **una hoja completa por movimiento**. Godot podrá leer los cuadros directamente: no hace falta separar las imágenes ni guardar despegue, caída y aterrizaje en carpetas distintas.

```text
assets/characters/
  beto/
    character.json
    animations/
      idle/idle.png
      walk/walk.png
      attack_01/firstpunch.png
      attack_02/secondpunch.png
      attack_03/thirdpunch.png
      jump/jump.png
      jump_attack/flykick.png
      hurt/damage.png
      death/ko.png
    portraits/
    extras/
    source/betopixel.png
  alito/    (las mismas carpetas, vacías)
  cami/     (las mismas carpetas, vacías)
```

## Archivos de Beto ya colocados

Se copiaron los originales de Descargas sin modificarlos ni borrarlos de su ubicación original.

| Carpeta | Archivo | Movimiento |
| --- | --- | --- |
| `idle` | `idle.png` | Quieto / guardia. |
| `walk` | `walk.png` | Caminar. |
| `attack_01` | `firstpunch.png` | Primer golpe. |
| `attack_02` | `secondpunch.png` | Segundo golpe. |
| `attack_03` | `thirdpunch.png` | Tercer golpe, con guitarra. |
| `jump` | `jump.png` | Salto completo. |
| `jump_attack` | `flykick.png` | Patada voladora. |
| `hurt` | `damage.png` | Recibir daño y recuperar la guardia. |
| `death` | `ko.png` | Caída / KO. |
| `source` | `betopixel.png` | Referencia estática original; conserva los márgenes grises. |

Las nueve hojas originales son **PNG de 600 × 600, con 3 columnas y 3 filas**. Cada celda mide **200 × 200**. El orden inicial es de izquierda a derecha y de arriba abajo:

```text
0  1  2
3  4  5
6  7  8
```

Los cuadros y sus dimensiones están anotados en `beto/character.json`. **Beto ya está integrado al jugador:** usa estas hojas para quieto, caminar, tres ataques, salto, patada voladora, daño y KO. La ulti reutiliza el barrido con guitarra. La secuencia de caminar omite el primer cuadro de guardia para evitar una pausa al repetir el ciclo. El salto visual sigue la altura real del personaje.

**El primer golpe ahora usa la versión de 40 cuadros** en `../characters_40_frames/beto/animations/attack_01/firstpunch.png`, mediante una referencia desde su manifiesto. La hoja de 9 cuadros se conserva como original. Las otras animaciones siguen usando sus hojas anteriores.

El manifiesto define la escala `0.6`, el pivote `[100, 190]`, las secuencias y los cuadros de impacto. Los ataques usan FPS para su duración; salto, daño, KO y ulti se sincronizan con los tiempos de sus estados. La ulti coloca el barrido cuando se aplica el daño global. Se conservan los PNG originales completos y se espejan al mirar a la izquierda.

## Alito y Cami

Poné sus hojas en las carpetas equivalentes. Podés conservar los nombres originales y registrar el nombre en el campo `file` de cada animación. No tienen que usar la misma cantidad de cuadros ni resolución que Beto: sus dimensiones quedan sin definir hasta recibir las imágenes.

El cargador actual reproduce hojas completas con `"format": "sheet"`. Si recibís PNG individuales, podés guardarlos numerados, por ejemplo `walk_000.png`, `walk_001.png`; habrá que añadir ese formato al cargador o armar una hoja antes de activar ese personaje.

## Activar un personaje en la selección

`roster.json` define los tres casilleros, en orden: Beto, Alito y Cami. Por ahora sólo Beto tiene `enabled: true`. Los otros dos muestran su portrait y cargan todas sus animaciones como reemplazo provisional.

Para activar Alito o Cami:

1. Colocá sus hojas en sus carpetas de animación.
2. Completá su `character.json`: `file`, `frame_size`, columnas, filas, cantidad/secuencia de cuadros y FPS para los nueve movimientos. Ajustá `scale`, `pivot_pixels` y `active_hit_frames` de sus ataques. Beto sirve de ejemplo.
3. Colocá el portrait independiente en `portraits/portrait.png`: el cargador lo usa automáticamente. Para otro nombre de archivo, indicá `portrait_file` en el manifiesto. Beto ya usa su imagen de esa carpeta en los tres casilleros provisionales. Sólo si no hay portrait disponible se recorta la hoja `idle`; `portrait_region: [x, y, ancho, alto]` define ese recorte de respaldo.
4. Cambiá `enabled` a `true` en su entrada de `roster.json` y reiniciá el juego. Reexportá para actualizar Web.

El casillero resolverá su nombre, portrait, escala y **todo su conjunto de animaciones**. No hay que cambiar `fighter.gd` ni el código de selección. Si el conjunto está incompleto, se usa Beto entero, evitando mezclar sprites de personajes distintos.

La animación `ultimate` puede tener su propia hoja o usar `source_animation` para reutilizar otra. Beto usa `attack_03`, con `impact_frame` e `impact_progress` para sincronizar el barrido. `frame_times` permite ajustar la distribución de cuadros de estados sincronizados, como su salto.

## Otras carpetas

- `portraits/`: retratos para HUD o selección de personaje.
- `extras/`: movimientos adicionales; por ejemplo, una futura `ultimate/`, correr o levantarse. Sólo se crearán carpetas nuevas cuando exista ese material.
- `source/`: originales editables, referencias y licencia del pack. Godot ignora esta carpeta para no incluir originales en el juego.

Conservá los PNG a su tamaño original y con transparencia. Si los sprites miran hacia la izquierda, anotá `"default_facing": "left"` en el manifiesto. Si hay variantes reales para ambas direcciones, se pueden organizar en subcarpetas `right/` y `left/`.

**Beto reemplaza al jugador geométrico durante la partida.** Alito y Cami siguen pendientes de sus imágenes e integración. Las carpetas antiguas `jump_start`, `jump_up`, `jump_fall` y `jump_land` se sustituyeron por `jump`; también se retiraron las carpetas opcionales que estaban vacías.
