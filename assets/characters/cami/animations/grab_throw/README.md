# Cami — grab throw

Hoja propia `grabthrow.png`: nueve cuadros de 162 × 245 px en cuadrícula 3 × 3, conservados sin cambios desde `source/grabthrow-original.png`. `frames/` contiene los PNG individuales y `preview.gif` muestra el giro completo con una pausa final de 0,2 s.

Se reproduce al revolear (atrás + ataque durante el agarre), a 20 FPS base y 40 FPS efectivos para el jugador. Empieza en el cuadro 0, libera al enemigo en el 6, cuando Cami se da vuelta, y termina en el 8. Captura y sostén siguen usando `grab`, fijo en el cuadro 2.

Regenerar hoja, frames y preview: `node scripts/prepare-grab.mjs`.
