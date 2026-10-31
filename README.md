# Street Groova

Los agarres de los enemigos y jefes están desactivados. El jugador conserva sus agarres, golpes de agarre y lanzamientos contra enemigos comunes. Prueba: tests/test_enemy_grab_disabled.gd.

Todas las hojas existentes incluyen ahora una carpeta frames/ con sus cuadros PNG y un preview.gif. [Índice de animaciones y vistas previas](assets/ANIMATION_PREVIEWS.md). Las hojas originales se conservan; regenerar con node scripts/export-animation-previews.mjs y verificar con --check.

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

La carrera requiere dos toques hacia el mismo lado dentro de 0,28 segundos y mantener el segundo. Usa su animación de carrera y aumenta la velocidad de 170 a 300 unidades/s. Soltar o invertir la dirección termina la carrera. Atacar corriendo ejecuta una patada deslizante con su animación propia: avanza unas 145 unidades, frena progresivamente durante unos 0,8 segundos y causa 29 de daño una vez por rival y lo lanza por el aire como un agarre y lanzamiento. No activa el agarre automático durante la carrera. Por ahora todos los personajes usan esta misma animación; barridas y codazos propios quedan pendientes de sus sprites. Saltar corriendo conserva el impulso; recibir daño o usar la ulti cancela el deslizamiento.

Sin dirección, el salto es vertical. Con dirección, conserva el impulso hasta aterrizar. Los controles táctiles aparecen sólo en móviles; la vista usa una resolución de 960 × 640 (3:2) y la ventana mantiene esa proporción.

## Debug room

Desde la selección de personaje, **TAB** abre primero una lista de los seis escenarios. Elegí con 1–6, flechas y Enter, o clic/táctil; después entra a la sala con ese fondo, sin oleadas automáticas y con vidas infinitas. CAMBIAR ESCENARIO permite volver a la lista desde la sala. **TAB** vuelve a la selección. Los botones en pantalla hacen lo mismo que estas teclas; se pueden crear enemigos y jefes repetidamente, sin límite.

| Tecla | Acción |
| --- | --- |
| 1 / 2 / 3 | Cambiar a Beto / Cami / Alito, recuperando salud |
| 4 / 5 / 6 | Crear rival amarillo (tier 1) / rosa (tier 2) / rojo (tier 3) |
| 7 | Crear jefe final |
| 8 | Cargar ulti al máximo |
| 9 | Agregar una oleada aleatoria de 3 a 7 rivales |
| 0 | Matar a todos los enemigos |

Cami y Alito usan temporalmente los gráficos de Beto, indicado en pantalla, hasta que sus manifiestos y animaciones estén completos. La sala intenta cargar sus recursos propios al cambiar de personaje. Las pruebas no envían resultados al ranking.

## El nivel

Una campaña de **3 niveles de 5 oleadas cada uno** (15 en total), con dos primeros fondos distintos elegidos al azar y el bar neón fijo como tercer nivel. El catálogo de seis fondos incluye: barrio, puerto nocturno, bar neón, interior de tren, bosque al atardecer con komorebi y shopping. La selección se conserva durante la partida y se sortea de nuevo al empezar otra. Cada nivel es de **4250 unidades de largo**, con zoom **1,96875×**, un 25% menos que el anterior. Se puede retroceder hasta 700 unidades detrás del inicio de la oleada actual. La quinta oleada presenta al jefe: un clon de Beto un 25% más grande, con 520 de energía (doble del tier 3) y 36 de daño por golpe (tier 3: 26). Los enemigos comunes tienen 130/84/260 de energía, el doble que antes. Los turnos y rodeos del sistema de combate se mantienen.

Las cajas de madera y los barriles metálicos se rompen de un solo golpe; atacar uno cercano usa la animación de patada slide. Los suministros se intentan generar al empezar cada oleada y cada 25–40 segundos, con probabilidad del 40%, solo si falta vida y no queda otro objeto sin romper ni comida sin recoger. Dejan al azar sushi (75% de la vida máxima) o una pinta de cerveza (50%). Con vida completa, la comida queda disponible. Sus gráficos pixel art están en `assets/items/supplies.png`. La comida es la única curación durante una vida: avanzar de oleada ya no cura. Una vida nueva empieza con energía completa.

El movimiento en profundidad cubre 77 unidades, abarca vereda y calle y es más lento que el horizontal. El piso conserva las proporciones de baldosas, cordón y asfalto del PNG, con latas de cerveza vacías y diarios como decoración. La vista de 960 × 640 coincide con el formato 3:2 de los fondos. Cada imagen se dibuja completa, con una sola escala y sin repetir tiras del piso para llenar la pantalla. La cámara deja margen hacia la dirección de movimiento (izquierda o derecha), cambia de encuadre suavemente y conserva ese margen al detenerse. También conserva espacio por delante del jugador y acompaña verticalmente los saltos para mantener a Beto debajo del HUD sin cambiar su física. El borde derecho de la cámara queda limitado por la línea de la zona bloqueada; avanza cuando se despeja la oleada. Los límites del nivel y los efectos se calculan con el zoom. [Ver encuadre](docs/primer-nivel.png).

- **Beto:** personaje pixel art animado con sus nueve hojas originales; 100 de energía, tres vidas, dos puños y remate con guitarra, salto y patada aérea.
- **Tier 1 amarillo:** 130 de vida, 16 de daño, velocidad 79; voladora y slide no lanzan al jugador. Tamaño estándar; futuro alien punki.
- **Tier 2 rosa:** 84 de vida, 10 de daño, velocidad 96; la voladora lanza, el slide no. Tamaño 94%; favorece voladoras (intervalo 5.6 s) sobre slides (9 s). Futura mujer alien.
- **Tier 3 rojo:** 260 de vida, 26 de daño, velocidad 53; ambos especiales lanzan. Escala 1.113 (5% más que su anterior 1.06); salta poco (16 s) y favorece slide (8 s). Futuro grandote.
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

En Android, iPhone y iPad se detecta el dispositivo al iniciar (también en la versión Web). La vista mantiene el escenario de 960 × 640 y agrega una franja inferior de 180 unidades para los controles, sin cubrir el piso. En escritorio no se muestra esta franja.

- Palanca analógica multidireccional a la izquierda, con diagonales, zona muerta y retorno al centro al soltar. Doble toque hacia el mismo lado y mantener permite correr.
- Botones **PEGAR**, **SALTAR** y **ULTI** a la derecha, con multitouch para combinar movimiento y acciones. El aro de ulti muestra su carga.
- Botón **PAUSA / SEGUIR** en el centro. Cambiar de pantalla, cancelar un toque o mandar la app al fondo libera los controles.
- Selección por toque y botones para volver o entrar al debug room sin teclado. El debug room tiene un botón para volver a selección.

Validación de palanca, multitouch, carrera y limpieza de controles: `godot --headless --path . --script tests/test_mobile_controls.gd`.

## Campaña de tres niveles

Los tres niveles repiten por ahora el escenario, las cinco oleadas y el jefe del nivel 1. El HUD indica el nivel y la oleada. Al superar los niveles 1 y 2 se muestra **STAGE CLEAR** con luces arcade durante 3,5 segundos y se carga automáticamente la primera oleada del siguiente nivel. Se conservan personaje, salud, vidas, carga de ulti, puntos y el identificador de la partida; se reinician la cámara, los enemigos, las cajas, los barriles y la comida del escenario.

Al superar el nivel 3 aparece **CONGRATULATIONS!** con confeti y una celebración de cinco segundos. El personaje usa `jump` como animación provisional de victoria; agregar una animación opcional `victory` al manifiesto la reemplaza automáticamente. Después se abre el ranking con el puntaje acumulado de los tres niveles. El debug room no participa de la progresión de campaña.

Validación de las 15 oleadas, intermedios, continuidad y victoria final: `godot --headless --path . --script tests/test_campaign.gd`.

## Impactos en vuelo y opciones de agarre

Un cuerpo lanzado por grab-and-throw o golpe deslizante puede golpear a varios enemigos durante su vuelo. Cada impacto causa 20 de daño y lanza al enemigo alcanzado, pero estos lanzamientos secundarios no golpean a terceros. También ocurre si el jugador sale volando y choca contra enemigos. Se respetan la profundidad del escenario, las alturas y la protección de recuperación; un KO puede seguir golpeando mientras su cuerpo está en el aire.

Durante un agarre, **golpe** permite pegar hasta tres veces, usando `attack_01` por ahora. Los primeros dos golpes vuelven al cuadro de agarre; el tercero lanza hacia adelante, **sin efecto cadena**. Cada golpe causa 19 de daño. **Atrás + golpe** sigue siendo el lanzamiento normal. **Salto** abandona el agarre y salta, sin golpear ni lanzar al rival.

Si un enemigo te agarra, cinco pulsaciones nuevas de **golpe, salto o direcciones** permiten zafarte. Se pueden combinar; mantener un botón o dirección no suma más pulsaciones. Dejar de pulsar durante 0,8 segundos reinicia el progreso. Al escapar recibís una protección breve y el captor queda momentáneamente aturdido. El indicador **ZAFATE!** muestra el progreso. Funciona con teclado, mando y controles mobile.

Validación: `godot --headless --path . --script tests/test_flight_grapple.gd`.

Los cuerpos lanzados conservan el impulso horizontal durante toda la caída, incluso si el impacto fue letal. El lanzamiento sale a 380 unidades/s y la fricción del piso los frena al aterrizar; los sobrevivientes esperan a detenerse antes de levantarse. El puñetazo deslizante conserva sus cuadros de contacto originales y sostiene su último cuadro durante la frenada extendida.

El agarre del jugador llega al cuadro de sujeción al doble de velocidad y la fase de lanzamiento se reproduce al doble de velocidad, manteniendo el cuadro real de liberación. Pulsar atrás + golpe durante la captura guarda la orden para lanzar en cuanto termine de agarrar; los tiempos del agarre enemigo se conservan para permitir zafarse.

Validación de tiers y bloqueo de cámara: `godot --headless --path . --script tests/test_enemy_tiers.gd`.

## Escape de agarres

Soltarse requiere nuevas pulsaciones: tier 1, 3; tier 2, 6; tier 3, 9; jefe, 18. Mantener una tecla o pulsar varios botones a la vez no multiplica el esfuerzo. El tiempo de espera antes de actuar es 0.6/0.4/0.3 segundos para tiers 1/2/3 y 0.18 para el jefe; el progreso se pierde tras 0.9/0.75/0.6 segundos sin pulsar (jefe: 0.45). El jefe puede dar hasta dos golpes durante un agarre antes de arrojar: golpe de agarre 30 de daño y lanzamiento 55, frente a 19/40 de un rival normal. Sigue siendo posible escapar, pero exige pulsaciones rápidas y continuas.

Validación: `godot --headless --path . --script tests/test_grip_tiers.gd`.

Los enemigos, incluido el jefe, no reciben invulnerabilidad al levantarse: pueden recibir daño o volver a ser lanzados durante esa animación. El jugador conserva su protección de recuperación. El jefe usa ataques un 25% más rápidos que la velocidad base, anticipación de 0.16 s, menos pausa entre golpes y descansos de 0.2–0.35 s entre turnos. Persigue a 105 unidades/s y puede esquivar lateralmente un golpe cercano durante 0.18 s, con 1.6 s entre esquivas; la esquiva no concede invulnerabilidad. Validación: `godot --headless --path . --script tests/test_boss_aggression.gd`.

Los cinco escenarios nuevos tienen cinco imágenes distintas de 1536 × 1024, con el mismo encuadre, escala y división del piso que la calle original. El scroll recorre 1–2–3–4–5 y vuelve al 1 mediante franjas compartidas, sin reflejar ni comprimir panoramas. Archivos y geometría: [assets/environment](assets/environment/README.md).

El cierre del tercer nivel conserva los cinco segundos de celebración y luego hace fade al concierto frontal con YOU WIN! y luces animadas durante diez segundos. Después hace fade al puntaje; VOLVER AL INICIO regresa al título. Estas transiciones y título→selección usan 0.65 s de fade out, 1 s en negro y 0.65 s de fade in. La selección tiene sonido al cambiar/confirmar personaje y borde alternando blanco/menta (más rápido al confirmar). Validación: `godot --headless --path . --script tests/test_screen_flow.gd`.

El concierto YOU WIN! ignora botones durante sus primeros 4 segundos visibles. Después admite una pulsación nueva de teclado, mando, ratón o pantalla táctil para pasar al puntaje con los fades habituales. Mantener una tecla, soltarla o mover el stick no omite la secuencia. Sin pulsaciones, continúa automáticamente al completar 10 segundos.

El escenario Calle original vuelve a usar `neighborhood-pixel.png`, su ancho de repetición de 492 unidades, fachadas, vereda, cordón, asfalto, juntas y decoración; el PNG se dibuja completo con escala uniforme. Los otros cinco escenarios conservan sus recorridos conectados.

La comida y las armas del suelo se recogen pulsando golpe a menos de 32 unidades y en la misma franja. No se recogen al tocarlas. `pickup` usa la animación de agacharse, con bajada y subida, sin desplazamiento ni daño; el objeto se obtiene al 50% de la secuencia, con la mano abajo y un golpe recibido puede interrumpir la recogida. La comida queda si la vida está completa. Palos y caños aparecen en el suelo y también se pueden crear desde los botones PALO/CAÑO de debug; quedan equipados en la mano derecha durante las animaciones hasta recibir un lanzamiento. El agarre visual sigue anclajes por cuadro detectados desde el sprite; `weapon_hand_frames` en la animación permite indicar coordenadas [x,y] exactas para futuros sprites.

El ataque armado usa `punch_weapon`, provisionalmente el primer golpe, con alcance 105 y daño 36 (tablón) / 42 (caño), superior a los golpes comunes de 19/29. Las carpetas `animations/punch_weapon/` existen para Beto, Alito y Cami en los conjuntos original, 20 y 40 cuadros. Reemplazar el alias por la futura hoja permite conectar su animación propia. La recogida usa una hoja `pickup` propia: ocho cuadros de bajada y tres nuevos extendiendo la mano al piso, seguidos de la vuelta en sentido inverso.

STAGE CLEAR usa un panel al 65% del tamaño anterior, desplazado hacia arriba y con menos oscurecimiento; el personaje también festeja entre niveles. Validación de recogidas y armas: `godot --headless --path . --script tests/test_pickups_weapons.gd`.

Cada arma empieza con 100 puntos de durabilidad. Cada enemigo efectivamente dañado consume 10/20/30 puntos según su tier, o 50 si es el jefe. Fallar o golpear un blanco protegido no consume durabilidad. A cero se rompe en dos fragmentos animados y deja de causar daño. Un golpe que lanza al jugador hace caer el arma desde su mano, con varios giros antes de aterrizar; entonces puede recogerse con su durabilidad restante. Los golpes comunes no la sueltan. El HUD muestra la durabilidad equipada. Validación: `godot --headless --path . --script tests/test_weapon_durability.gd`.

Las armas naturales aparecen en una o dos oleadas distintas elegidas al iniciar cada nivel, con un máximo total de dos por nivel. Recogerlas, romperlas o soltarlas no repone ese cupo. Los botones de debug permiten crear armas para pruebas. Los sprites transparentes de tablón y caño gris curvado se comparten entre el suelo, la mano, el vuelo y la rotura. Arte creado con image_gen integrado; archivos y prompts: assets/items/weapon-wood.png, weapon-pipe.png y weapon-prompts.json. Validación del cupo: tests/test_weapon_spawns.gd.

En debug, O abre el menú de objetos: barril, caja, tablón y caño. Se elige con clic/touch, flechas y Enter, o 1–4; O/Esc cierra. El combate se detiene mientras está abierto. También hay botones directos de caja y barril en la barra debug. Cada caja o barril destruido entrega al azar sushi o cerveza.

Con un arma equipada, pulsar salto y golpe juntos la lanza hacia adelante. Tolera pulsar salto apenas después del golpe, antes de la ventana de impacto. El arma gira, respeta la franja de profundidad y detecta impactos entre frames; el primer enemigo golpeado sale volando, el arma deja de avanzar y cae al piso. Conserva el desgaste y puede romperse en ese impacto. Un lanzamiento fallido aterriza sin consumir durabilidad.

Los enemigos pueden recoger armas cercanas: evalúan la oportunidad cada 12–20 segundos, con 20% de probabilidad, cuando el jugador está a más de 90 unidades. Buscan durante un máximo de tres segundos y usan la misma animación de recogida. Armados hacen 50% más de daño, gastan 10 puntos por impacto al jugador y sueltan el arma si salen volando o mueren. Las recogidas no generan armas adicionales. Prueba: tests/test_weapon_throw_items.gd.

Los enemigos armados también pueden lanzar hacia el jugador: comprueban la oportunidad cada 6–12 segundos, con 35% de probabilidad, desde 100–260 unidades y en la misma franja. Cualquier arma lanzada puede alcanzar al jugador o a otro enemigo, excluyendo a quien la lanzó. Al primer impacto deja de avanzar y cae; si llega al borde visible de la pantalla también se detiene y queda en el piso, sin gastar durabilidad por ese choque.

El retroceso se limita continuamente a 240 unidades desde el mayor avance de cámara, también en debug; el avance de debug sigue siendo indefinido. Los enemigos permanecen dentro de la profundidad caminable y los límites físicos del nivel. La cámara no los desplaza: si quedan detrás del área visible vuelven corriendo a 360 unidades/s, sin convertir esa carrera en un ataque slide. Prueba: tests/test_weapon_edges_bounds.gd.

El tablón lanzado consume 50 puntos de durabilidad al impactar contra cualquier personaje. Con 100 puntos resiste dos impactos lanzados; el segundo lo rompe. Sus golpes en la mano conservan el desgaste por tier.

Los jefes no pueden ser agarrados. Reciben daño de patadas, slides, armas lanzadas y cuerpos en vuelo, pero esos impactos no los lanzan; sólo la ulti puede hacerlos salir volando. Un arma lanzada que golpea a un jefe igualmente se detiene y consume durabilidad. Prueba: tests/test_boss_launch_immunity.gd.

Atajo de prueba: 0 (también numérico) completa el nivel actual con celebración, cartel y cuenta regresiva normales. Se habilita con la propiedad exportada `enable_level_skip` del nodo principal, activada por defecto; al desactivarla la tecla no salta niveles. En debug, 0 conserva su función de matar enemigos sin completar un nivel. Prueba: tests/test_level_skip.gd.

La animación base de agacharse tiene ocho cuadros, con el primero tomado del idle original y los siguientes creados con image_gen. El jugador sólo se agacha al pulsar golpe cerca de comida o de un arma para recogerla. No hay tecla de agachado independiente. [Sprites, GIF y prompts](assets/characters/beto/animations/crouch/README.md). Prueba: tests/test_crouch.gd.

La recogida de comida y armas usa ahora los dibujos de agacharse: baja, obtiene el objeto y vuelve a levantarse. Los conjuntos original, 20 y 40 tienen carpetas crouch y ultimate_air para Beto, Alito y Cami. La ulti aérea sigue usando el alias provisional hasta recibir su hoja dedicada.

La recogida completa el gesto con tres cuadros nuevos de la mano bajando, abriendo los dedos y cerrándolos junto al suelo. El contacto obtiene el objeto al 50% de la secuencia; después se retira el brazo y Beto se levanta. [Animación y prompts](assets/characters/beto/animations/pickup/README.md).
