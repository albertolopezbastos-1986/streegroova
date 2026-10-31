# Recoger del suelo

[Vista animada](preview.gif) · [Hoja](pickup.png) · [Cuadros individuales](frames/) · [Prompts](prompts.json) · [Refinamiento del agarre](refinement-prompt.json)

Hoja RGBA de 800 × 600, cuadrícula 4 × 3 y 11 cuadros de 200 × 200. Los primeros ocho reutilizan los dibujos de crouch; los tres últimos, creados con image_gen integrado, bajan el mismo brazo, abren la mano y cierran los dedos junto al piso. Las botas conservan el apoyo y el pivote [100,190]. Los originales generados se conservan en source/, excluida de la importación de Godot.

La acción reproduce 0–10 y 10–0 a 48 cuadros/s: dura aproximadamente 0.458 s. El objeto se obtiene al 50%, mientras la mano está en el cuadro de contacto 10. Después retira el brazo y se levanta. Sirve tanto para comida como para armas y para la recogida ocasional de los enemigos. Los anclajes de la palma acompañan las armas al recogerlas.

La recogida se inicia con golpe cerca de comida o un arma. No existe agachado independiente con C. Preparación: scripts/prepare_pickup.gd con el argumento pack. Pruebas: tests/test_pickup_reach.gd y tests/test_pickups_weapons.gd.
