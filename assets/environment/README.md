# Fondos y scroll

La calle conserva su imagen original, neighborhood-pixel.png (1536 × 1024). Los otros cinco escenarios se reconstruyeron como cinco imágenes completas de esa misma resolución por escenario. Se eliminaron los panoramas anteriores y sus recortes estrechos. El concierto final sigue usando su imagen fija independiente en ending/.

| Escenario | Carpeta | Imágenes |
| --- | --- | --- |
| Puerto nocturno | tiles/docks-night/ | 01.png–05.png |
| Bar neón | tiles/neon-bar/ | 01.png–05.png |
| Interior de tren | tiles/train-interior/ | 01.png–05.png |
| Bosque al atardecer | tiles/forest-golden-hour/ | 01.png–05.png |
| Shopping | tiles/shopping-mall/ | 01.png–05.png |

## Misma geometría que la calle

Todos se dibujan como imágenes completas con escala uniforme: ancho 492 y alto 328 unidades (1536 × 1024). La pantalla lógica es 960 × 640, la misma proporción 3:2 del arte. Se eliminó la división del dibujo en bandas y la repetición de una muestra del piso: el borde inferior real de la imagen coincide con el comienzo del HUD inferior (Y=614 de pantalla).

Se mantiene el filtrado nearest y el zoom 1.96875. El suelo caminable va de Y=350 a Y=427, dentro del PNG. La posición vertical del mundo se calcula para que ni la imagen ni los pies se extiendan debajo del HUD. El piso, el cordón y las fachadas conservan las proporciones de origen. Al saltar, la cámara mantiene el seguimiento vertical para que el personaje no quede oculto por el HUD superior.

Cada imagen nueva comparte 128 píxeles laterales con la siguiente. Se dibujan con un paso de 451 unidades: el solapamiento ocupa el mismo lugar del mundo y no se duplica el contenido. La quinta comparte su borde derecho con la primera, cerrando el recorrido. La calle conserva su repetición original de 492 unidades y sus juntas/decoración.

Las imágenes se crearon con image_gen integrado, usando la calle y los tramos vecinos como referencias de escala, estilo y encuadre. scripts/environment-tiles.mjs verifica 1536 × 1024, prepara las guías y conserva las franjas compartidas sin remuestreo. Los prompts y procedencia están en [tiles/prompts.json](tiles/prompts.json).

La campaña elige dos escenarios distintos entre los cinco que no son el bar; el tercero siempre es el bar. TAB permite elegir entre los seis escenarios antes de entrar a debug.

Validación: tests/test_backgrounds.gd comprueba dimensiones, cinco tramos distintos, continuidad de las franjas y cierre 5→1, además de la selección de campaña. tests/test_framing.gd verifica el encuadre.

## Prompt de la calle original

```text
Use case: stylized-concept. Asset type: production background sprite strip for an original 2D arcade beat-em-up game, to be used directly as a horizontally repeating PNG texture in Godot. Generate a wide landscape 1536 x 1024 composition. PRIMARY REQUEST: authentic, detailed 1990s 16-bit hand-placed PIXEL ART of a close sidewalk and wall of modest urban houses and one closed record shop at dusk. Strict front-facing side-scroller view, straight horizontal lines, no isometric view or vanishing point. Three adjacent facades: weathered warm brick, desaturated blue plaster, and dark burgundy storefront; doors, barred windows, shutters, drainpipes, old posters, small wall lamps. Rich but restrained 32-color-style palette with dark ink outlines, warm amber window lights, muted blue/purple shadows, tiny pixel texture, carefully clustered pixels, dithered brick and plaster wear. Crisp visible square pixels at a consistent logical resolution approximately 512 by 341 rendered at 3x, no antialiasing, no blur, no vector flat shapes, no painterly brush strokes, no photorealism. COMPOSITION IMPORTANT: the base of the building walls forms a perfectly level straight horizontal line at 83% of the image height (around y=850). The lower 14% is a continuous flat empty light gray stone sidewalk made of small rectangular paving stones, clearly walkable with no obstructions; a thin curb and a tiny sliver of dark street at the extreme bottom 3%. Fill the upper 83% with tightly framed walls, large doors and windows; no sky, no distant skyline, no broad avenue. Lower-floor doors must be around 36-40% of total image height, their bottoms on the wall base line, to match large fighting sprites. Keep door thresholds and paving level across the full strip. HORIZONTAL REPEAT: make left and right edges share matching neutral masonry and exactly the same sidewalk/curb heights and palette so this strip can repeat sideways; avoid bright cut-off details on the extreme edges. No characters, no people, no shadows of people, no fighters, no cars, no foreground poles or furniture blocking the sidewalk, no UI, no logos, no watermarks, no readable words. Blank signage is fine. This is a game-ready environment texture, not a screenshot, framed artwork, mockup or sprite sheet of multiple panels.
```
