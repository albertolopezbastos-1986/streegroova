import { existsSync, readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { resolve, join, dirname } from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

export function runnablePath(value) {
  if (process.platform !== 'win32' && /^[a-z]:[\\/]/i.test(value)) {
    return `/mnt/${value[0].toLowerCase()}/${value.slice(3).replaceAll('\\', '/')}`;
  }
  return value;
}

export function forGodot(path, windowsEngine) {
  if (!windowsEngine || process.platform === 'win32') return path;
  const converted = spawnSync('wslpath', ['-w', path], { encoding: 'utf8' });
  if (converted.status !== 0 || !converted.stdout.trim()) throw new Error(`No se pudo convertir la ruta para Godot de Windows: ${path}`);
  return converted.stdout.trim();
}

export function findGodot() {
  const explicit = process.env.GODOT_BIN;
  const metadataPath = '.godot/editor/project_metadata.cfg';
  const metadata = existsSync(metadataPath) ? readFileSync(metadataPath, 'utf8').match(/^executable_path="([^"]+)"/m)?.[1] : null;
  const candidates = explicit ? [explicit] : [metadata, 'godot', 'godot4'].filter(Boolean);
  const features = readFileSync('project.godot', 'utf8').match(/config\/features=PackedStringArray\("(\d+\.\d+)"/)?.[1];
  for (let command of candidates) {
    command = runnablePath(command);
    // La variante console permite esperar y recibir errores desde una terminal.
    if (/\.exe$/i.test(command) && !/_console\.exe$/i.test(command)) {
      const consoleCommand = command.replace(/\.exe$/i, '_console.exe');
      if (existsSync(consoleCommand)) command = consoleCommand;
    }
    const result = spawnSync(command, ['--version'], { encoding: 'utf8', timeout: 15000 });
    const version = result.stdout?.trim().match(/\d+\.\d+\.\d+[^\s]*/)?.[0];
    if (result.status === 0 && version) {
      if (features && !version.startsWith(`${features}.`)) {
        if (explicit) throw new Error(`GODOT_BIN apunta a Godot ${version}, pero el proyecto usa ${features}. Usa la misma version del editor y sus plantillas.`);
        continue;
      }
      return { command, version, windowsEngine: /\.exe$/i.test(command) };
    }
    if (explicit) throw new Error(`No se pudo ejecutar GODOT_BIN=${explicit}. ${result.error?.message || result.stderr || result.stdout || 'Revisa la ruta y los permisos.'}`);
  }
  throw new Error('No se encontro un Godot compatible. Abri el proyecto una vez en tu editor para detectar su ruta, agrega godot al PATH o define GODOT_BIN con la ruta del ejecutable.');
}

export function preparePreset() {
  let config = readFileSync('export_presets.cfg', 'utf8');
  const section = config.match(/\[preset\.(\d+)\]\s*\n(?:(?!\n\[)[\s\S])*?name="Web"(?:(?!\n\[)[\s\S])*/);
  if (!section || !section[0].includes('platform="Web"')) throw new Error('Falta el preset Web en export_presets.cfg. Agregalo desde Proyecto > Exportar una sola vez.');
  const ignored = ['web/*', 'netlify/*', 'node_modules/*', 'tests/*', 'docs/*', 'package*.json', 'deploy.config.json'];
  const existing = section[0].match(/^exclude_filter="([^"]*)"/m)?.[1]?.split(',').filter((value) => value && value !== 'scripts/*') || [];
  const exclusions = [...new Set([...existing, ...ignored])].join(',');
  const updated = /^exclude_filter=/m.test(section[0])
    ? section[0].replace(/^exclude_filter="[^"]*"/m, `exclude_filter="${exclusions}"`)
    : `${section[0]}\nexclude_filter="${exclusions}"\n`;
  config = config.replace(section[0], updated).replace(/^html\/experimental_virtual_keyboard=false$/m, 'html/experimental_virtual_keyboard=true');
  if (config !== readFileSync('export_presets.cfg', 'utf8')) writeFileSync('export_presets.cfg', config);
}

function run(command, args) {
  const result = spawnSync(command, args, { stdio: 'inherit' });
  if (result.error || result.status !== 0) {
    throw new Error(result.error?.message || `Godot termino con codigo ${result.status}. Revisa el error anterior; si faltan plantillas, instalalas para la misma version del motor.`);
  }
}

export function exportGame() {
  if (!existsSync('project.godot')) throw new Error('Ejecuta npm run export desde la carpeta del proyecto.');
  const engine = findGodot();
  console.log(`Exportando con Godot ${engine.version}\n${engine.command}`);
  preparePreset();
  mkdirSync('web', { recursive: true });
  writeFileSync('web/.gdignore', '');
  const project = forGodot(process.cwd(), engine.windowsEngine);
  const output = forGodot(resolve('web/index.html'), engine.windowsEngine);
  // Importar primero asegura que los recursos nuevos esten disponibles.
  run(engine.command, ['--headless', '--path', project, '--editor', '--import', '--quit']);
  run(engine.command, ['--headless', '--path', project, '--export-release', 'Web', output]);
  const checker = join(dirname(fileURLToPath(import.meta.url)), 'check-web.mjs');
  run(process.execPath, [checker]);
  console.log('Exportacion terminada. Ejecuta npm run dev para probarla localmente.');
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try { exportGame(); } catch (error) {
    console.error(`No se pudo exportar: ${error.message}`);
    process.exitCode = 1;
  }
}
