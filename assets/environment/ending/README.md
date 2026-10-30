# Escenario del concierto final

`concert-stage.png`: imagen opaca y fija, 1448 × 1086 (4:3), vista frontal. Telones, parrilla de luces magenta/cian/violeta/ámbar, pared oscura y piso de madera despejado. No contiene personajes ni instrumentos.

Generada con la herramienta integrada `image_gen`, sin CLI. Prompt exacto en `prompt.json`.

`scenes/concert_stage.tscn` prepara el fondo al tamaño 960 × 720 sin cámara ni scroll. El nodo `Performers` permite agregar sprites por delante del fondo, con origen Y=560 para apoyar sus pies en el escenario. El script `scripts/concert_stage.gd` anima haces de luz y el cartel YOU WIN!; `Performers` queda preparado para incorporar la banda y sus instrumentos. Después de la celebración de victoria del tercer nivel, el juego hace fade out (0.65 s), negro (1 s) y fade in (0.65 s) hacia este escenario. El concierto dura 10 s completos después del fade in y luego pasa al puntaje con la misma transición. VOLVER AL INICIO permite regresar al título con fades; iniciar desde el título lleva a selección con fades.

La campaña termina siempre en el bar neón. Los dos primeros fondos se eligen sin repetir entre los otros cinco.

El concierto YOU WIN! ignora botones durante sus primeros 4 segundos visibles. Después admite una pulsación nueva de teclado, mando, ratón o pantalla táctil para pasar al puntaje con los fades habituales. Mantener una tecla, soltarla o mover el stick no omite la secuencia. Sin pulsaciones, continúa automáticamente al completar 10 segundos.
