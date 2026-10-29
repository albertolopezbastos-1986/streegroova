import { existsSync, readFileSync, readdirSync, statSync, copyFileSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';

export function checkWeb(root = '.') {
  const web = join(root, 'web');
  for (const name of ['index.html', 'index.js', 'index.wasm', 'index.pck']) {
    if (!existsSync(join(web, name)) || statSync(join(web, name)).size === 0) {
      throw new Error(`Falta web/${name}. Ejecuta npm run export para generar la version Web.`);
    }
  }
  const files = (directory) => readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const path = join(directory, entry.name);
    return entry.isDirectory() ? files(path) : [path];
  });
  const assets = existsSync(join(root, 'assets')) ? files(join(root, 'assets')).filter((file) => /\.(ttf|otf|tres|png|svg|jpg|webp|json|gdshader)$/.test(file)) : [];
  const sources = [join(root, 'project.godot'), join(root, 'export_presets.cfg'), ...assets, ...files(join(root, 'scripts')).filter((file) => file.endsWith('.gd')), ...files(join(root, 'scenes')).filter((file) => file.endsWith('.tscn'))];
  const packTime = statSync(join(web, 'index.pck')).mtimeMs;
  if (sources.some((file) => statSync(file).mtimeMs > packTime)) {
    throw new Error('La exportacion Web esta desactualizada. Ejecuta npm run export y despues npm run build.');
  }
  let html = readFileSync(join(web, 'index.html'), 'utf8');
  if (!html.includes('index.js') || !/"experimentalVK"\s*:\s*true/.test(html)) {
    throw new Error('HTML incorrecto o teclado virtual deshabilitado. Reexporta usando el preset Web incluido.');
  }
  copyFileSync(join(root, 'scripts/mobile-name.js'), join(web, 'mobile-name.js'));
  copyFileSync(join(root, 'assets/fonts/PressStart2P-Regular.ttf'), join(web, 'arcade-name.ttf'));
  if (!html.includes('src="mobile-name.js"')) {
    if (!html.includes('</head>')) throw new Error('Falta </head> en la exportacion HTML.');
    html = html.replace('</head>', '<script src="mobile-name.js" defer></script>\n</head>');
    writeFileSync(join(web, 'index.html'), html);
  }
  writeFileSync(join(web, 'deployment.json'), JSON.stringify({
    built_at: new Date().toISOString(),
    game_sha256: createHash('sha256').update(readFileSync(join(web, 'index.pck'))).digest('hex'),
    mobile_input_sha256: createHash('sha256').update(readFileSync(join(web, 'mobile-name.js'))).digest('hex')
  }));
  console.log('Exportacion Web lista. Netlify empaquetara las Functions del ranking.');
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try { checkWeb(); } catch (error) { console.error(error.message); process.exitCode = 1; }
}
