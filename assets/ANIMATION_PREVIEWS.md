# Cuadros y vistas previas

Cada hoja original se conserva. frames/ contiene PNG individuales con tamaño, transparencia y píxeles exactos de la celda; sus nombres mantienen el índice original. Las celdas completamente vacías se omiten. Los GIF tienen escala 2× con nearest y transparencia; siguen el orden de juego cuando está configurado. Los GIF de crouch y pickup conservan su velocidad de revisión de 16 FPS. Los cuadros PNG adicionales quedan fuera de la exportación web mediante .gdignore.

Algunas hojas guardadas en el conjunto de 40 cuadros contienen menos cuadros dibujados: se usa la cuadrícula real, sin inventar cuadros. frames.json documenta la extracción, las celdas vacías y la secuencia del GIF.

Regenerar: node scripts/export-animation-previews.mjs. Verificar: node scripts/export-animation-previews.mjs --check. Requiere ffmpeg (FFMPEG_BIN permite cambiar el ejecutable).

| Hoja | Cuadros | Original | Individuales | Vista previa |
| --- | ---: | --- | --- | --- |
| characters/beto/animations/attack_01/firstpunch.png | 9 | [PNG](characters/beto/animations/attack_01/firstpunch.png) | [Cuadros](characters/beto/animations/attack_01/frames/) | [GIF](characters/beto/animations/attack_01/preview.gif) |
| characters/beto/animations/attack_02/secondpunch.png | 9 | [PNG](characters/beto/animations/attack_02/secondpunch.png) | [Cuadros](characters/beto/animations/attack_02/frames/) | [GIF](characters/beto/animations/attack_02/preview.gif) |
| characters/beto/animations/attack_03/thirdpunch.png | 9 | [PNG](characters/beto/animations/attack_03/thirdpunch.png) | [Cuadros](characters/beto/animations/attack_03/frames/) | [GIF](characters/beto/animations/attack_03/preview.gif) |
| characters/beto/animations/crouch/crouch.png | 8 | [PNG](characters/beto/animations/crouch/crouch.png) | [Cuadros](characters/beto/animations/crouch/frames/) | [GIF](characters/beto/animations/crouch/preview.gif) |
| characters/beto/animations/death/ko.png | 9 | [PNG](characters/beto/animations/death/ko.png) | [Cuadros](characters/beto/animations/death/frames/) | [GIF](characters/beto/animations/death/preview.gif) |
| characters/beto/animations/hurt/damage.png | 9 | [PNG](characters/beto/animations/hurt/damage.png) | [Cuadros](characters/beto/animations/hurt/frames/) | [GIF](characters/beto/animations/hurt/preview.gif) |
| characters/beto/animations/idle/idle.png | 9 | [PNG](characters/beto/animations/idle/idle.png) | [Cuadros](characters/beto/animations/idle/frames/) | [GIF](characters/beto/animations/idle/preview.gif) |
| characters/beto/animations/jump/jump.png | 9 | [PNG](characters/beto/animations/jump/jump.png) | [Cuadros](characters/beto/animations/jump/frames/) | [GIF](characters/beto/animations/jump/preview.gif) |
| characters/beto/animations/jump_attack/flykick.png | 9 | [PNG](characters/beto/animations/jump_attack/flykick.png) | [Cuadros](characters/beto/animations/jump_attack/frames/) | [GIF](characters/beto/animations/jump_attack/preview.gif) |
| characters/beto/animations/pickup/pickup.png | 11 | [PNG](characters/beto/animations/pickup/pickup.png) | [Cuadros](characters/beto/animations/pickup/frames/) | [GIF](characters/beto/animations/pickup/preview.gif) |
| characters/beto/animations/runslide/runslide.png | 9 | [PNG](characters/beto/animations/runslide/runslide.png) | [Cuadros](characters/beto/animations/runslide/frames/) | [GIF](characters/beto/animations/runslide/preview.gif) |
| characters/beto/animations/walk/walk.png | 9 | [PNG](characters/beto/animations/walk/walk.png) | [Cuadros](characters/beto/animations/walk/frames/) | [GIF](characters/beto/animations/walk/preview.gif) |
| characters_20_frames/beto/animations/grab_punch_02/grabpunch2.png | 21 | [PNG](characters_20_frames/beto/animations/grab_punch_02/grabpunch2.png) | [Cuadros](characters_20_frames/beto/animations/grab_punch_02/frames/) | [GIF](characters_20_frames/beto/animations/grab_punch_02/preview.gif) |
| characters_20_frames/beto/animations/grab_throw/grabthrow.png | 21 | [PNG](characters_20_frames/beto/animations/grab_throw/grabthrow.png) | [Cuadros](characters_20_frames/beto/animations/grab_throw/frames/) | [GIF](characters_20_frames/beto/animations/grab_throw/preview.gif) |
| characters_20_frames/beto/animations/idle/idle.png | 21 | [PNG](characters_20_frames/beto/animations/idle/idle.png) | [Cuadros](characters_20_frames/beto/animations/idle/frames/) | [GIF](characters_20_frames/beto/animations/idle/preview.gif) |
| characters_20_frames/beto/animations/run/run.png | 21 | [PNG](characters_20_frames/beto/animations/run/run.png) | [Cuadros](characters_20_frames/beto/animations/run/frames/) | [GIF](characters_20_frames/beto/animations/run/preview.gif) |
| characters_20_frames/beto/animations/walk/walk.png | 21 | [PNG](characters_20_frames/beto/animations/walk/walk.png) | [Cuadros](characters_20_frames/beto/animations/walk/frames/) | [GIF](characters_20_frames/beto/animations/walk/preview.gif) |
| characters_40_frames/beto/animations/attack_01/firstpunch.png | 41 | [PNG](characters_40_frames/beto/animations/attack_01/firstpunch.png) | [Cuadros](characters_40_frames/beto/animations/attack_01/frames/) | [GIF](characters_40_frames/beto/animations/attack_01/preview.gif) |
| characters_40_frames/beto/animations/grab_throw/grabthrow.png | 21 | [PNG](characters_40_frames/beto/animations/grab_throw/grabthrow.png) | [Cuadros](characters_40_frames/beto/animations/grab_throw/frames/) | [GIF](characters_40_frames/beto/animations/grab_throw/preview.gif) |
| characters_40_frames/beto/animations/idle/idle.png | 21 | [PNG](characters_40_frames/beto/animations/idle/idle.png) | [Cuadros](characters_40_frames/beto/animations/idle/frames/) | [GIF](characters_40_frames/beto/animations/idle/preview.gif) |
| characters_40_frames/beto/animations/walk/walk.png | 21 | [PNG](characters_40_frames/beto/animations/walk/walk.png) | [Cuadros](characters_40_frames/beto/animations/walk/frames/) | [GIF](characters_40_frames/beto/animations/walk/preview.gif) |
