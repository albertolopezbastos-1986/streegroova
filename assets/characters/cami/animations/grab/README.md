# Cami — grab

Hoja actual de 648 × 980 px: 13 cuadros en cuadrícula 4 × 4, con celdas 162 × 245. `source/grab-current.png` conserva el original y `grab.png` es idéntico píxel a píxel. `frames/` contiene los 13 PNG individuales y `preview.gif` reproduce 0 → 1 → 2 y mantiene el cuadro 2.

El juego captura con los cuadros 0–2 y queda fijo en el 2 al sostener al rival. El revoleo usa la hoja propia `../grab_throw/grabthrow.png`, con liberación en el cuadro 6; los tres golpes de agarre usan la hoja propia compartida de rodillazo, omitiendo el cuadro 0. La hoja hereda el tamaño y pivote normales de Cami.

Regenerar: `node scripts/prepare-grab.mjs`. Las hojas `grab-original.png` y `grab-repaired.png` conservan las versiones anteriores, fuera de la animación actual.
