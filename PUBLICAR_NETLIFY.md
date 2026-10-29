# Ranking online y publicación en Netlify

Se reutiliza el sistema de Groova Invaders: Godot envía JSON a Netlify Functions y las funciones guardan las partidas en **Netlify Blobs**. Un JSON dentro de la carpeta estática del juego no recibe escrituras de los visitantes.

## Cómo funciona

- Al ganar o perder, ingresás tu nombre y elegís **GUARDAR ONLINE**.
- El nombre tiene un máximo de 12 caracteres y se recuerda para la próxima partida.
- La pantalla muestra el Top 10 compartido. También se abre con **R** o el botón **TOP 10** del menú inicial.
- Cada partida tiene un identificador aleatorio. Los reintentos conservan nombre, puntaje e identificador; no generan filas duplicadas.
- Si falla la conexión, se puede reintentar o volver a jugar. El récord local sigue guardándose en `user://record.cfg`. El envío pendiente se conserva durante esa pantalla; no hay una cola de envíos que sobreviva a cerrar o reiniciar el juego.
- En celular se usa el mismo puente de campo HTML de Invaders para abrir el teclado al tocar el nombre.

Ejemplo de registro persistido:

```json
{
  "id": "0123456789abcdef0123456789abcdef",
  "name": "BETO",
  "score": 12500,
  "date": "2026-10-29T12:00:00.000Z"
}
```

Los datos van a un almacén del sitio, que persiste entre publicaciones:

| Entorno | Almacén |
| --- | --- |
| Producción | `street-groova-world-v1` |
| Desarrollo y previews | `street-groova-test-v1` |

No se accede a los almacenes de Invaders. En Blobs se mantiene un registro por partida y un índice para consultar el Top 10, en lugar de sobrescribir un archivo compartido cuando varios jugadores envían a la vez. Los empates se ordenan por fecha del servidor y luego por identificador.

## Exportar y hacer build desde la terminal

El flujo es el mismo de Groova Invaders. Desde la carpeta del proyecto:

```sh
npm ci
npm run export
npm run build
```

- **`npm run export`** detecta Godot, importa los recursos sin abrir la interfaz, exporta en modo release con el preset Web a `web/index.html` y valida el resultado.
- **`npm run build`** valida la exportación, copia el campo de nombre para celulares y genera `web/deployment.json` con las huellas SHA-256 del juego y del campo HTML.
- **`npm run dev`** permite probar juego y API localmente.
- **`npm run deploy`** hace build, publica juego y Functions en producción y verifica lo publicado.
- **`npm run verify:deploy`** vuelve a comprobar versión, funciones de ranking y campo de nombre sin publicar de nuevo.

Export y build funcionan sin cuenta Netlify y sin una URL real. No hace falta abrir el diálogo de exportación de Godot. El motor y sus plantillas de exportación deben estar instalados y ser de la misma versión. El proyecto usa Godot 4.7; el script rechaza motores de otra rama.

El exportador busca la ruta del editor en `.godot/editor/project_metadata.cfg` y luego `godot` o `godot4` en PATH. También acepta una ruta explícita, con espacios incluidos:

```powershell
# PowerShell, si no se detecta automáticamente:
$env:GODOT_BIN = 'C:\ruta\a\Godot_v4.7.2-stable_win64_console.exe'
npm run export
```

```sh
# Linux / WSL:
GODOT_BIN="/ruta/a/godot" npm run export
```

En WSL se convierten automáticamente las rutas de Windows y se usa la variante `_console.exe` cuando está disponible. No se modifica el destino de exportación que puedas tener abierto en el editor: la salida del script siempre es `web/index.html`.

El build rechaza exportaciones ausentes o anteriores a los scripts y las escenas. Después de modificar el juego, ejecutá otra vez **`npm run export`**. El build de Netlify valida archivos ya exportados; no instala ni ejecuta Godot en el servidor.

## Probar localmente

```sh
npm run dev
```

Abrí `http://localhost:8888`. Netlify CLI puede pedir iniciar sesión y vincular un sitio para usar sus servicios. Probar el HTML con un servidor estático simple no ejecuta las Functions del ranking.

En el editor de Godot, la API apunta por defecto a `http://localhost:8888`. Para apuntar una versión de escritorio al sitio publicado, agregá en `project.godot`:

```ini
[ranking]
api_base_url="https://TU-SITIO.netlify.app"
```

En Web, con esa opción vacía, se usa automáticamente el dominio donde está alojado el juego. No agregues tokens ni credenciales de Netlify al juego.

## Configurar el sitio y publicar

`deploy.config.json` contiene el destino provisional solicitado:

```json
{
  "site": "placeholdernetlify",
  "url": "https://placeholdernetlify.netlify.app"
}
```

Este placeholder no crea ni reserva un sitio. Mientras siga así, `npm run deploy` muestra qué falta configurar y termina antes de invocar Netlify. Se puede seguir exportando, haciendo build y probando localmente.

Cuando tengas un sitio para Street Groova, reemplazá `site` por su nombre o ID y `url` por su URL HTTPS real. Alternativamente, usá las variables `NETLIFY_SITE_ID` y `DEPLOY_URL`. La configuración del deploy no cambia la API del juego: en Web el ranking sigue usando el dominio donde se aloja.

Luego ejecutá:

```sh
npx netlify-cli login
npm run export
npm run build
npm run deploy
```

Si el sitio todavía no existe, crealo desde Netlify o con `npx netlify-cli sites:create`. El deploy usa `--site` con el destino configurado, `--prod`, `--context production`, `--dir web` y `--functions netlify/functions`. No depende de la vinculación que tengas con Invaders ni crea un sitio automáticamente.

Después del deploy se verifica que el manifiesto remoto coincida con el build local, que `/api/scores` responda y que el HTML incluya el teclado para celulares. Para repetir sólo esa comprobación:

```sh
npm run verify:deploy
# También admite una URL explícita:
npm run verify:deploy -- https://mi-juego.netlify.app
```

El comando publica **`web/` y las Functions**. Arrastrar únicamente la carpeta Web a Netlify no instala las Functions del ranking. `web/` está ignorada por Git: este flujo publica los archivos exportados desde tu máquina; para publicación automática desde Git haría falta incluir la exportación o automatizar Godot en CI.

## Comprobar la publicación

1. Abrí `https://TU-SITIO.netlify.app/api/scores`: debe devolver `{"scores": [...]}`.
2. Jugá una partida, ingresá tu nombre y guardá el puntaje. Debe aparecer **PUNTAJE GUARDADO ONLINE**.
3. Abrí el juego en otro navegador o dispositivo y consultá el Top 10.
4. Volvé a publicar y comprobá que los resultados sigan presentes. Los registros se pueden inspeccionar en la sección Blobs del sitio en Netlify.

El backend valida formato, puntaje, origen y tamaño del pedido, y configura límites de solicitudes. Como en Invaders, el puntaje lo calcula el cliente: esto es un ranking arcade, no una validación antitrampas de la partida.

## Pruebas

```sh
npm test
godot --headless --path . --script tests/test_online.gd
godot --headless --path . --script tests/smoke.gd
```

Las pruebas de backend usan un almacén en memoria con escrituras condicionales; no escriben en Netlify. Verifican concurrencia, reintentos, recuperación de fallos, orden del Top 10, validación y respuestas HTTP. Las de Godot verifican el cliente JSON y el formulario. La conexión real a Blobs se verifica después de publicar.

Documentación oficial: [Netlify Blobs](https://docs.netlify.com/build/data-and-storage/netlify-blobs/) , [exportación por línea de comandos](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html) y [exportación Web de Godot](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html).
