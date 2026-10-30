# Armas pixel art

Sprites creados con image_gen integrado, con transparencia real:

- [Tablón de madera](weapon-wood.png): vetas, nudos y bordes astillados.
- [Caño gris](weapon-pipe.png): metal rayado y codo curvado en el extremo.
- [Prompts y procedencia](weapon-prompts.json).

Godot conserva las imágenes completas y usa sus límites alfa para dibujar el arma de 48 unidades de longitud. scripts/weapon_art.gd comparte el dibujo entre mano, suelo, vuelo y fragmentos de rotura, con filtrado nearest y sin fondo visible.

Daño: tablón 36, caño 42; golpes comunes 19/29. Hay una o dos apariciones naturales por nivel, en oleadas distintas elegidas al cargarlo. Las armas soltadas y las creaciones manuales de debug no consumen ni renuevan ese cupo.

Durabilidad inicial 100. Cada enemigo dañado consume 10/20/30 según tier, o 50 para el jefe. Al llegar a cero el arma se rompe. Los lanzamientos la sueltan desde la mano y la hacen girar hasta aterrizar. Recogerla conserva su desgaste.

Pruebas: tests/test_pickups_weapons.gd, tests/test_weapon_durability.gd y tests/test_weapon_spawns.gd.
