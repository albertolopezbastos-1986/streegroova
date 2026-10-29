# Street Groova

Primer nivel de un beat 'em up original inspirado en los arcade de los 90. Hecho en Godot 4, sin dependencias ni recursos externos. Abrí `project.godot` y presioná **F6 sobre `scenes/main.tscn`** o **F5** para jugar.

Para generar la versión Web desde la terminal, como en Groova Invaders:

```sh
npm ci
npm run export
npm run build
```

`npm run dev` sirve el juego y las Functions localmente. `npm run deploy` publica y verifica el sitio una vez que reemplaces `placeholdernetlify` en `deploy.config.json` por el nombre/ID y la URL reales. El exportador usa Godot sin abrir su interfaz; requiere el motor 4.7 y sus plantillas instaladas. Si no detecta el editor, se puede indicar mediante `GODOT_BIN`. Más detalles en [PUBLICAR_NETLIFY.md](PUBLICAR_NETLIFY.md).

## Controles

| Acción | Teclado | Mando |
| --- | --- | --- |
| Mover por la calle | WASD / flechas | Stick izquierdo / cruceta |
| Golpear / combo de tres golpes | J / Z | X |
| Saltar | Espacio / K | A |
| Patada voladora | Golpear durante el salto | X en el aire |
| Groova Break | L / X | Y |
| Pausa | Esc / P | Start |
| Ayuda / sonido | H / M | — |

Sin dirección, el salto es vertical. Con dirección, conserva el impulso hasta aterrizar. Los controles táctiles aparecen al tocar la pantalla; el tamaño de ventana mantiene la proporción 16:9.

## El nivel

Tres encuentros a lo largo de una calle nocturna con desplazamiento de cámara y edificios en parallax. No son tres niveles: es el **primer nivel**, dividido en tres rondas. Para avanzar hay que eliminar la ronda y caminar hacia la derecha. Cada transición recupera 25 de energía.

- **Axel:** 100 de energía, tres vidas, combo de puños y remate con patada, salto y patada aérea.
- **Rival rosa:** luchador equilibrado.
- **Rival amarillo:** rápido, con menos energía y golpes más débiles.
- **Rival violeta:** pesado, lento, resistente, con golpes fuertes y anticipación mayor.
- **Groova Break:** se carga al dar y recibir golpes. Con la barra completa, activa una pose invulnerable, oscurece la escena y daña a todos los rivales del encuentro.

Incluye pausa por pérdida de foco, efectos de impacto, breve congelación de golpes, partículas, música sintetizada, efectos de sonido, victoria, derrota, reinicio y récord local en `user://record.cfg`.

También incluye **ranking online Top 10** con nombre al finalizar la partida. Usa el sistema de Groova Invaders: Netlify Functions y registros JSON en Netlify Blobs, con almacenes propios de Street Groova. Se puede abrir con **R** o **TOP 10** en el menú. Ver [configuración y publicación en Netlify](PUBLICAR_NETLIFY.md).

Toda la interfaz usa **Press Start 2P**, la misma fuente arcade de Groova Invaders, incluido el campo de nombre del navegador. La fuente y su licencia OFL están en `assets/fonts/`; el tema global está en `assets/ui/arcade_theme.tres`.

La marca usa los mismos archivos de Invaders: ícono y pantalla de carga de Groova, y logo blanco de Groova IPA en el inicio. Los originales están en `assets/branding/`. [Ver pantalla de inicio](docs/pantalla-inicio.png).

Los personajes y el escenario están dibujados y animados con código: es una primera versión jugable con arte geométrico propio. No usa sprites, personajes ni escenarios de Final Fight. Agarrar, lanzar enemigos, armas y cooperativo quedan fuera de esta versión.

## Organización

- `scripts/game.gd`: escenario, oleadas, cámara, interfaz, controles, audio y ciclo de partida.
- `scripts/fighter.gd`: movimiento, animación, combate e inteligencia de los tres enemigos.
- `scenes/main.tscn`: escena principal.

Validación funcional: `godot --headless --path . --script tests/smoke.gd`.
