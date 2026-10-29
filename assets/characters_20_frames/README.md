# Animaciones nuevas de 20 cuadros

Beto, Alito y Cami tienen las mismas carpetas en `animations/`, incluyendo `grab_throw`, `grab_punch_01`, `grab_punch_02`, `grab_punch_03` y `run`. Colocá las nuevas hojas aquí. Cada secuencia nueva prevé índices 0–19; las medidas de cada hoja se configuran cuando esté disponible.

Beto ya usa `grab_throw/grabthrow.png`: cuadrícula 5 × 5, celdas de 200 × 200, 20 FPS, índices 0–19. Se congela en el cuadro 8 durante el agarre; al lanzar continúa en el 9 y suelta al rival en el 15. La celda adicional 20 de regreso a guardia no forma parte de la secuencia de 20 cuadros. El primer golpe de agarre reutiliza temporalmente `attack_01`; su futura hoja se registra en el manifiesto principal sin cambiar la mecánica.

`assets/characters/` sigue siendo el conjunto activo. `characters_40_frames/` conserva los originales y el primer golpe de 40 cuadros que ya estaba integrado; no se convierten arbitrariamente hojas existentes de 40 a 20 cuadros. El nuevo destino para los próximos sprites es esta carpeta de 20 cuadros. No activar en el roster estas plantillas incompletas.
