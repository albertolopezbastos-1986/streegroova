# Street Groova

Beat 'em up de tres niveles, original inspirado en los arcade de los 90. Hecho en Godot 4, sin dependencias ni recursos externos. Abrí `project.godot` y presioná **F6 sobre `scenes/main.tscn`** o **F5** para jugar.

Para generar la versión Web desde la terminal, como en Groova Invaders:

```sh
npm ci
npm run export
npm run build
```

`npm run dev` sirve el juego y las Functions localmente. `npm run deploy` publica y verifica el sitio una vez que reemplaces `placeholdernetlify` en `deploy.config.json` por el nombre/ID y la URL reales. El exportador usa Godot sin abrir su interfaz; requiere el motor 4.7 y sus plantillas instaladas. Si no detecta el editor, se puede indicar mediante `GODOT_BIN`. Más detalles en [PUBLICAR_NETLIFY.md](PUBLICAR_NETLIFY.md).

## Controles

Después de **Press Start** se abre la selección con tres portraits. Cambiá con A/D, flechas o mando; confirmá con **Enter / A**, o tocá un portrait y el botón **ELEGIR**. Esc / B vuelve al inicio. Por ahora los tres casilleros muestran y cargan Beto.

| Acción | Teclado | Mando |
| --- | --- | --- |
| Mover por la calle | WASD / flechas | Stick izquierdo / cruceta |
| Correr | Doble toque izquierda/derecha y mantener el segundo | Doble toque stick / cruceta y mantener |
| Golpe deslizante | J / Z mientras corrés | X mientras corrés |
| Golpear / combo de tres golpes | J / Z | X |
| Saltar | Espacio / K | A |
| Patada voladora | Golpear durante el salto | X en el aire |
| Groova Break | L / X | Y |
| Pausa | Esc / P | Start |
| Ayuda / sonido | H / M | — |

La carrera requiere dos toques hacia el mismo lado dentro de 0,28 segundos y mantener el segundo. Usa la animación de caminar y aumenta la velocidad de 170 a 300 unidades/s. Soltar o invertir la dirección termina la carrera. Atacar corriendo ejecuta un golpe deslizante con puño 1: avanza unas 65 unidades, frena progresivamente y causa 29 de daño una vez por rival y lo lanza por el aire como un agarre y lanzamiento. No activa el agarre automático durante la carrera. Por ahora todos los personajes usan esta misma animación; barridas y codazos propios quedan pendientes de sus sprites. Saltar corriendo conserva el impulso; recibir daño o usar la ulti cancela el deslizamiento.

Sin dirección, el salto es vertical. Con dirección, conserva el impulso hasta aterrizar. Los controles táctiles aparecen sólo en móviles; la vista usa una resolución de 960 × 720 (4:3) y la ventana mantiene esa proporción.

## Debug room

Desde la selección de personaje, **TAB** abre una sala de pruebas con el fondo actual, sin oleadas automáticas y con vidas infinitas. **TAB** vuelve a la selección. Los botones en pantalla hacen lo mismo que estas teclas; se pueden crear enemigos y jefes repetidamente, sin límite.

| Tecla | Acción |
| --- | --- |
| 1 / 2 / 3 | Cambiar a Beto / Cami / Alito, recuperando salud |
| 4 / 5 / 6 | Crear rival rosa / amarillo / violeta |
| 7 | Crear jefe final |
| 8 | Cargar ulti al máximo |
| 9 | Agregar una oleada aleatoria de 3 a 7 rivales |
| 0 | Matar a todos los enemigos |

Cami y Alito usan temporalmente los gráficos de Beto, indicado en pantalla, hasta que sus manifiestos y animaciones estén completos. La sala intenta cargar sus recursos propios al cambiar de personaje. Las pruebas no envían resultados al ranking.

## El nivel

Una campaña de **3 niveles de 5 oleadas cada uno** (15 en total), cada uno de **4250 unidades de largo**, con zoom **1,96875×**, un 25% menos que el anterior. Se puede retroceder hasta 700 unidades detrás del inicio de la oleada actual. La quinta oleada presenta al jefe: un clon de Beto un 25% más grande, con 390 de energía (triple del rival común de 130). Los enemigos comunes tienen 130/84/260 de energía, el doble que antes. Los turnos y rodeos del sistema de combate se mantienen.

Cada sección tiene una caja de madera y un barril que se rompen a golpes y dejan un pollo rostizado. Al acercarse por el suelo, el pollo recupera **50 de energía**; si la barra está llena, queda disponible. La comida es la única curación durante una vida: avanzar de oleada ya no cura. Una vida nueva empieza con energía completa.

El movimiento en profundidad cubre 80 unidades (cuatro veces el recorrido anterior), abarca vereda y calle y es más lento que el horizontal. El piso visible se reparte entre baldosas y asfalto, separados por el cordón, con latas de cerveza vacías y diarios como decoración. La vista de 960 × 720 muestra más altura de las fachadas sin reducir a los personajes. La cámara conserva espacio por delante del jugador y acompaña verticalmente los saltos para mantener a Beto debajo del HUD sin cambiar su física. Los límites del nivel y los efectos se calculan con el zoom. [Ver encuadre](docs/primer-nivel.png).

- **Beto:** personaje pixel art animado con sus nueve hojas originales; 100 de energía, tres vidas, dos puños y remate con guitarra, salto y patada aérea.
- **Clon rosa:** luchador equilibrado con los sprites de Beto.
- **Clon amarillo:** rápido, con menos energía y golpes más débiles.
- **Clon violeta:** pesado, lento, resistente, con golpes fuertes y anticipación mayor.
- **Groova Break:** se carga al dar y recibir golpes. Con la barra completa, activa una pose invulnerable, oscurece la escena y daña a todos los rivales del encuentro.

Incluye pausa por pérdida de foco, efectos de impacto, breve congelación de golpes, partículas, música sintetizada, efectos de sonido, victoria, derrota, reinicio y récord local en `user://record.cfg`.

También incluye **ranking online Top 10** con nombre al finalizar la partida. Usa el sistema de Groova Invaders: Netlify Functions y registros JSON en Netlify Blobs, con almacenes propios de Street Groova. Se puede abrir con **R** o **TOP 10** en el menú. Ver [configuración y publicación en Netlify](PUBLICAR_NETLIFY.md).

Toda la interfaz usa **Press Start 2P**, la misma fuente arcade de Groova Invaders, incluido el campo de nombre del navegador. La fuente y su licencia OFL están en `assets/fonts/`; el tema global está en `assets/ui/arcade_theme.tres`.

La marca usa los mismos archivos de Invaders: ícono y pantalla de carga de Groova, y logo blanco de Groova IPA en el inicio. Los originales están en `assets/branding/`. [Ver pantalla de inicio](docs/pantalla-inicio.png).

Beto y los tres tipos de enemigos usan sprites pixel art; el escenario usa una franja de fachadas y vereda pixel art con filtrado nearest. Los clones se distinguen mediante paletas de ropa, tamaño y marcas de color. Todos pueden caminar, hacer el combo completo, saltar en avance, esquivar con salto vertical, ejecutar una patada aérea y mostrar daño y KO. **Sólo el jugador tiene ulti**; los rivales usan el golpe con guitarra como remate de alcance cercano, sin daño global. No usa sprites, personajes ni escenarios de Final Fight. Agarrar, lanzar enemigos, armas recogibles y cooperativo quedan fuera de esta versión.

El arte nuevo del escenario está en `assets/environment/neighborhood-pixel.png`; su [prompt y detalles de integración](assets/environment/README.md) quedan documentados.

Sus hojas se leen directamente: el primer puño usa la versión de **40 cuadros**, con cuadrícula de 7 × 6 y dos celdas vacías omitidas; los otros movimientos conservan las hojas de 3 × 3. La duración del primer golpe sigue siendo de unos 0,409 segundos. Los cuadros de contacto hacen daño una vez por objetivo; un golpe pulsado cerca del final de la animación se guarda brevemente para encadenar el combo. La ulti reutiliza el barrido con guitarra, con pose y golpe sincronizados con el oscurecimiento de pantalla. El salto vertical y el salto en avance conservan la física existente.

## Organización

- `assets/characters/`: carpetas para tres personajes pixel art, organizadas por animación. [Guía para colocar los sprites](assets/characters/README.md).
- `assets/characters_40_frames/`: variantes separadas de Beto, Alito y Cami para probar hojas de 40 cuadros. [Guía de la variante](assets/characters_40_frames/README.md).
- `scripts/game.gd`: escenario, oleadas, cámara, interfaz, controles, audio y ciclo de partida.
- `scripts/fighter.gd`: movimiento, animación, combate e inteligencia de los tres enemigos.
- `scripts/character_select.gd`: pantalla de selección y controles de sus tres casilleros.
- `scripts/character_catalog.gd`: carga completa del personaje elegido desde su manifiesto y resuelve casilleros pendientes a Beto.
- `scripts/character_visual.gd`: animador compartido; usa el manifiesto del personaje para sus hojas, escala, secuencias, dirección y cuadros de contacto.
- `scenes/main.tscn`: escena principal.

Validación funcional: `godot --headless --path . --script tests/smoke.gd`.

Validación de animaciones y combate de Beto: `godot --headless --path . --script tests/test_beto.gd`.

Validación de selección y carga de otros personajes: `godot --headless --path . --script tests/test_character_select.gd`.

Validación de zoom, cámara, saltos y límites de la vereda: `godot --headless --path . --script tests/test_framing.gd`.

Validación de clones, combos, saltos, patadas aéreas y bloqueo de ulti: `godot --headless --path . --script tests/test_enemies.gd`.

### Coordinación de los rivales

`scripts/combat_director.gd` distribuye posiciones a ambos lados del jugador y reserva turnos para atacar. Normalmente entra un rival con anticipación y combo; después descansa entre 1,2 y 2 segundos y deja una pausa de 0,35–0,65 segundos entre turnos. Cada 6–10 segundos puede intervenir un segundo rival durante un turno activo; nunca hay más de dos reservas. Saltar para atacar también requiere turno. Los demás rodean por otra franja de la vereda y esperan a distancia. El sistema libera turnos ante daño, KO o ulti y adapta los flancos cerca de los límites del escenario.

`tests/test_combat_director.gd` simula un minuto de pelea con tres rivales y verifica rodeo real, rotación, predominio de ataques individuales, intervenciones y límites de concurrencia.

### Agarre y lanzamiento

Beto agarra automáticamente al caminar hasta quedar pegado a un enemigo de frente y en la misma franja. Se inmoviliza en el cuadro 8 de `grab_throw` y el rival en el cuadro 3 de daño. Golpe solo hace el primer golpe de agarre (hoja provisional del primer puñetazo); atrás + golpe completa el lanzamiento hacia atrás. Un golpe recibido o la ulti liberan el agarre. Las nuevas hojas de 20 cuadros van en `assets/characters_20_frames/{beto,alito,cami}/animations/`; los originales anteriores se conservan. Ver `assets/characters/README.md` para cuadros y configuración, y `tests/test_grapple.gd` para controles de agarre, daño, lanzamiento e interrupción.

Validación de carrera y golpe deslizante: `godot --headless --path . --script tests/test_running.gd`.

Los enemigos también pueden agarrar y lanzar al jugador de cerca, o avisar con `!`, correr y ejecutar un golpe deslizante. Estas acciones requieren un turno del director de combate y tienen una espera de cinco segundos entre intentos especiales. Los lanzamientos y deslizamientos usan la misma trayectoria de caída: animación de derrota, aterrizaje y recuperación si queda salud. La recuperación dura 0,4 segundos y usa `jump` temporalmente, sin un salto físico. Se puede agregar la animación opcional `get_up` al manifiesto de cada personaje para reemplazarla; por ahora no se necesita ese recurso. Durante la caída y al levantarse hay protección para evitar lanzamientos encadenados; un golpe letal conserva el KO y el sistema de vidas habitual.

Validación de lanzamientos, derribos, recuperación e IA: `godot --headless --path . --script tests/test_knockdown.gd`.

## Controles mobile

En Android, iPhone y iPad se detecta el dispositivo al iniciar (también en la versión Web). La vista mantiene el escenario de 960 × 720 y agrega una franja inferior de 180 unidades para los controles, sin cubrir el piso. En escritorio no se muestra esta franja.

- Palanca analógica multidireccional a la izquierda, con diagonales, zona muerta y retorno al centro al soltar. Doble toque hacia el mismo lado y mantener permite correr.
- Botones **PEGAR**, **SALTAR** y **ULTI** a la derecha, con multitouch para combinar movimiento y acciones. El aro de ulti muestra su carga.
- Botón **PAUSA / SEGUIR** en el centro. Cambiar de pantalla, cancelar un toque o mandar la app al fondo libera los controles.
- Selección por toque y botones para volver o entrar al debug room sin teclado. El debug room tiene un botón para volver a selección.

Validación de palanca, multitouch, carrera y limpieza de controles: `godot --headless --path . --script tests/test_mobile_controls.gd`.

## Campaña de tres niveles

Los tres niveles repiten por ahora el escenario, las cinco oleadas y el jefe del nivel 1. El HUD indica el nivel y la oleada. Al superar los niveles 1 y 2 se muestra **STAGE CLEAR** con luces arcade durante 3,5 segundos y se carga automáticamente la primera oleada del siguiente nivel. Se conservan personaje, salud, vidas, carga de ulti, puntos y el identificador de la partida; se reinician la cámara, los enemigos, las cajas, los barriles y la comida del escenario.

Al superar el nivel 3 aparece **CONGRATULATIONS!** con confeti y una celebración de cinco segundos. El personaje usa `jump` como animación provisional de victoria; agregar una animación opcional `victory` al manifiesto la reemplaza automáticamente. Después se abre el ranking con el puntaje acumulado de los tres niveles. El debug room no participa de la progresión de campaña.

Validación de las 15 oleadas, intermedios, continuidad y victoria final: `godot --headless --path . --script tests/test_campaign.gd`.
