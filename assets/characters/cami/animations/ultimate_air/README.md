# Cami — ultimate_air

Hoja original 7 × 6 de 41 cuadros (0–40), celdas de 162 × 245 px. Se excluyen del juego y del preview los cuadros con explosión 23–30. La secuencia reproduce 33 cuadros: 0–22 y 31–40. frames/ conserva los originales separados con transparencia.

Sin bucle; duración de 1.6 s sincronizada con la ulti. Impacto en la pose 22 al 59% del progreso; luego recuperación sin explosiones. Preview 2× nearest con pausa final de 0.2 s. Hereda escala relativa y pivote de Cami.

El grito impulsa a Cami 18 unidades hacia atrás respecto de su orientación y 16 hacia arriba. La curva smoothstep comienza al 40% de la ulti y termina al 76%, acelerando y frenando suavemente. El desplazamiento modifica posición y altura reales, respeta los límites del nivel y conserva el punto alcanzado al finalizar; la física normal retoma desde allí. preview-motion.gif muestra el impulso sin cuadros con explosiones.
