# Animaciones nuevas de 20 cuadros

Beto, Alito y Cami tienen las mismas carpetas en `animations/`, incluyendo `grab_throw`, `grab_punch_01`, `grab_punch_02`, `grab_punch_03` y `run`. Colocá las nuevas hojas aquí. Cada secuencia nueva prevé índices 0–19; las medidas de cada hoja se configuran cuando esté disponible.

Beto ya usa `grab_throw/grabthrow.png`: cuadrícula 5 × 5, celdas de 200 × 200, 20 FPS, índices 0–19. Se congela en el cuadro 8 durante el agarre; al lanzar continúa en el 9 y suelta al rival en el 15. La celda adicional 20 de regreso a guardia no forma parte de la secuencia de 20 cuadros. El primer golpe de agarre reutiliza temporalmente `attack_01`; su futura hoja se registra en el manifiesto principal sin cambiar la mecánica.

`assets/characters/` sigue siendo el conjunto activo. `characters_40_frames/` conserva los originales y el primer golpe de 40 cuadros que ya estaba integrado; no se convierten arbitrariamente hojas existentes de 40 a 20 cuadros. El nuevo destino para los próximos sprites es esta carpeta de 20 cuadros. No activar en el roster estas plantillas incompletas.

Beto también usa `idle/idle.png` (1000 × 1000, celdas 200 × 200) y `walk/walk.png` (510 × 1155, celdas 102 × 231). Ambas hojas tienen cuadrícula 5 × 5 y reproducen los cuadros 0–19 a 20 FPS, omitiendo la pose extra 20. Walk usa escala `0.48` y pivote `[51, 226]`; el renderizador permite escala y pivote por animación.

El ciclo de `walk` reproduce solo los cuadros 0–16: omite los últimos tres cuadros de la secuencia (17, 18 y 19), además de la pose extra 20, para cerrar el loop. La hoja conserva sus 20 cuadros declarados.

Beto usa `characters_20_frames/beto/animations/run/run.png` al correr: cuadrícula 5 × 5, celdas 200 × 200, cuadros 1–19 a 20 FPS (se excluye permanentemente el cuadro 0 de idle). El segundo golpe del agarre usa `grab_punch_02/grabpunch2.png`: cuadrícula 5 × 5, celdas 183 × 227, cuadros 0–19 a 50 FPS (0.4 segundos), escala 0.52 y pivote [91.5, 217]. La rodilla aplica daño en los cuadros 6–13 y regresa al agarre; primer y tercer golpe conservan el reemplazo de `grab_punch_01`.

La carpeta `animations/runslide/` de Beto, Alito y Cami está preparada para la hoja del golpe durante la carrera. Colocá allí los sprites; su animación se conectará cuando esté disponible la hoja.

Las carpetas `animations/punch_weapon/` de Beto, Alito y Cami están preparadas para el golpe con palo o caño. El juego usa un alias provisional del primer golpe hasta recibir las hojas.
