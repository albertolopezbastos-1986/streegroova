# Cami — attack_03

Se reproducen los 33 cuadros originales del 8 al 40 a 34 FPS. La cuadrícula sigue siendo 7 × 6, ahora con celdas de 324 × 325 px y pivote [162, 281]. El arte original se desplaza [81, 40] sin escalar: los cuadros sin reparación conservan sus píxeles originales.

Se completaron únicamente los bordes recortados de los cuadros 18–26 y 28–32. El 27 ya estaba completo. La ampliación transparente permite alojar las partes faltantes. La escala del personaje no cambia. Impacto en cuadros 16–19; salto visual de 48 unidades y retroceso real de 41.4 durante cuadros 15–33.

source/ conserva la hoja original, la entrada y salida de la edición generativa, el mapa de cuadros y las reparaciones individuales. Se usó la herramienta integrada image_gen para completar extremidades y pelo fuera del recorte original, manteniendo pose, estilo pixel art y fondo transparente; después se restauraron todos los píxeles originales dentro del recorte y se eliminaron fragmentos nuevos desconectados.

frames/ contiene los 41 cuadros separados. preview.gif y preview-motion.gif empiezan en 8; el segundo muestra el salto y retroceso.

Se eliminaron el destello y las chispas de los cuadros 17–20. La zona de la pierna oculta por el destello fue reconstruida con image_gen, alineada con los originales y limitada a la zona del efecto. source/no-impact-input.png y no-impact-generated.png conservan la entrada y salida. Los demás cuadros no cambiaron.
