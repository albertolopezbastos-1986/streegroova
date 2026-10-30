# Sprites de Beto, Alito y Cami

**Las nuevas animaciones se preparan en [characters_20_frames](../characters_20_frames/README.md), con 20 cuadros por secuencia.** Las variantes anteriores de **40 cuadros** conservan su propia estructura en [`../characters_40_frames/`](../characters_40_frames/README.md), separada de estos sprites.

Cada personaje usa **una hoja completa por movimiento**. Godot podrá leer los cuadros directamente: no hace falta separar las imágenes ni guardar despegue, caída y aterrizaje en carpetas distintas.

```text
assets/characters/
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

Los cuadros y sus dimensiones están anotados en `beto/character.json`. **Beto ya está integrado al jugador:** usa estas hojas para quieto, caminar, tres ataques, salto, patada voladora, daño y KO. La ulti reutiliza el barrido con guitarra. Idle y walk usan las hojas de 20 cuadros de `characters_20_frames`, con índices 0–19 a 20 FPS; omiten la pose extra 20. Idle usa celdas de 200 × 200 y walk de 102 × 231, ambas en cuadrícula 5 × 5. Walk define escala `0.48` y pivote `[51, 226]` para mantener el tamaño y apoyo de Beto. El salto visual sigue la altura real del personaje.

**El primer golpe ahora usa la versión de 40 cuadros** en `../characters_40_frames/beto/animations/attack_01/firstpunch.png`, mediante una referencia desde su manifiesto. La hoja de 9 cuadros se conserva como original. Idle y walk usan las nuevas hojas de 20 cuadros; las demás animaciones conservan sus hojas anteriores.

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

## Agarre y lanzamiento de Beto

Al caminar hacia un enemigo por la misma franja y acercarse a menos de 25 unidades, Beto inicia `grab_throw` automáticamente. El rival queda inmovilizado en el cuadro **3** de `hurt`, contando desde 0. Beto reproduce los cuadros 0–8 del agarre y queda detenido en el **8** hasta elegir:

- **Golpe (J/Z o botón de golpe):** `grab_punch_01`, daño 19 y regreso al agarre. De momento reutiliza el primer golpe normal, hasta recibir la hoja dedicada.
- **Atrás + golpe:** continúa `grab_throw` desde el cuadro 9, suelta al enemigo en el 15 y lo arroja hacia atrás, con 40 de daño. Atrás es izquierda mirando a la derecha y derecha mirando a la izquierda; la orientación no cambia durante el agarre.

Un golpe de otro rival interrumpe el agarre y libera a ambos. La ulti también lo cancela. El enemigo agarrado no recibe turnos de ataque mientras esté inmovilizado. El rival arrojado usa la animación de caída, vuela, aterriza y se recupera si conserva energía.

La hoja activa es `assets/characters_20_frames/beto/animations/grab_throw/grabthrow.png`: 5 × 5 celdas de 200 × 200, índices 0–19. No se usa la celda adicional 20. Los campos `hold_frame: 8` y `release_frame: 15` del manifiesto sincronizan la mecánica. Para conectar el futuro golpe de agarre, reemplazá su alias `source_animation` por los datos de la hoja (`path`, `file`, cuadrícula, tamaño, secuencia, FPS y `active_hit_frames`), igual que cualquier ataque. El cargador también ofrece este reemplazo provisional cuando un personaje tiene `grab_throw` pero todavía no tiene su primer golpe de agarre.

El ciclo de `walk` reproduce solo los cuadros 0–16: omite los últimos tres cuadros de la secuencia (17, 18 y 19), además de la pose extra 20, para cerrar el loop. La hoja conserva sus 20 cuadros declarados.

Los tres ataques del combo se reproducen un 15% más rápido: `attack_01` a 112.444444 FPS, `attack_02` a 25.3 FPS y `attack_03` a 20.7 FPS. La duración y el contacto se calculan desde las animaciones, reduciendo la espera entre golpes.

Beto usa `characters_20_frames/beto/animations/run/run.png` al correr: cuadrícula 5 × 5, celdas 200 × 200, cuadros 1–19 a 20 FPS (se excluye permanentemente el cuadro 0 de idle). El segundo golpe del agarre usa `grab_punch_02/grabpunch2.png`: cuadrícula 5 × 5, celdas 183 × 227, cuadros 0–19 a 50 FPS (0.4 segundos), escala 0.52 y pivote [91.5, 217]. La rodilla aplica daño en los cuadros 6–13 y regresa al agarre; primer y tercer golpe conservan el reemplazo de `grab_punch_01`.

La carpeta `animations/runslide/` de Beto, Alito y Cami está preparada para la hoja del golpe durante la carrera. Colocá allí los sprites; su animación se conectará cuando esté disponible la hoja.

El golpe de carrera de Beto usa `animations/runslide/runslide.png` (600 × 600, celdas 200 × 200): cuadros 1–8 a 24 FPS, sin el idle inicial. La patada aplica daño en los cuadros 2–6 y conserva la distancia y el frenado del deslizamiento.

La comida y las armas del suelo se recogen pulsando golpe a menos de 32 unidades y en la misma franja. No se recogen al tocarlas. `pickup` usa temporalmente slide sin desplazamiento ni daño; el objeto se obtiene al 55% de la secuencia y un golpe recibido puede interrumpir la recogida. La comida queda si la vida está completa. Palos y caños aparecen en el suelo y también se pueden crear desde los botones PALO/CAÑO de debug; quedan equipados en la mano derecha al moverse, saltar, golpear, recibir daño o caer. El agarre visual sigue anclajes por cuadro detectados desde el sprite; `weapon_hand_frames` en la animación permite indicar coordenadas [x,y] exactas para futuros sprites.

El ataque armado usa `punch_weapon`, provisionalmente el primer golpe, con alcance 105 y daño 26 (palo) / 32 (caño). Las carpetas `animations/punch_weapon/` existen para Beto, Alito y Cami en los conjuntos original, 20 y 40 cuadros. Reemplazar el alias por la futura hoja permite conectar su animación propia. La recogida tiene un alias separado `pickup` para sustituir su placeholder después.
