# Beto: agacharse

[Vista animada](preview.gif) · [Hoja de sprites](crouch.png) · [Cuadros individuales](frames/) · [Prompts iniciales](prompts.json) · [Prompts de refinamiento](refinement-prompts.json)

Animación de 8 cuadros de 200 × 200, hoja de 800 × 400 (4 columnas, 2 filas), RGBA transparente. El cuadro 00 es el primer idle original, sin redibujar. Los otros cuadros se generaron con image_gen integrado usando el idle y las poses vecinas como referencias de identidad y estilo. Los originales generados se conservan en source/, fuera de la importación de Godot.

Se seleccionaron las poses que bajan de forma continua y se agregaron dos transiciones para suavizar la entrada y el tramo medio. La preparación usa muestreo nearest, alfa recortado y alineación de las suelas a la fila 188; el pivote sigue siendo [100, 190] y la escala 0.6. No se comprime el cuerpo para simular la flexión: las poses nuevas están dibujadas.

En el juego, estos dibujos se usan dentro de la recogida: pulsar golpe cerca de comida o un arma inicia la bajada, el agarre y la subida. C no realiza ninguna acción. S conserva el movimiento en profundidad. El GIF muestra la animación base a 16 cuadros/s para revisar los dibujos.

Regenerar la hoja desde los originales seleccionados: ejecutar scripts/prepare_crouch.gd con el argumento de usuario pack. La asignación está en assets/characters/beto/character.json. Prueba: tests/test_crouch.gd.

La recogida reutiliza estos ocho dibujos en su propia [hoja pickup](../pickup/README.md), que agrega tres cuadros bajando la mano hacia el suelo. Esta hoja se conserva como base de los primeros ocho cuadros de recogida.
