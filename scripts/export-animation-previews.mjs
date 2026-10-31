import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { createHash } from 'node:crypto';
import { spawn } from 'node:child_process';
import assert from 'node:assert/strict';
import { readPng, writePng } from './environment-tiles.mjs';

const roots = ['assets/characters', 'assets/characters_20_frames', 'assets/characters_40_frames'];
const ffmpeg = process.env.FFMPEG_BIN || '/usr/bin/ffmpeg';
const checkOnly = process.argv.includes('--check');
const hash = file => createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const slash = file => file.split(path.sep).join('/');
function walk(directory) {
  return fs.readdirSync(directory, { withFileTypes: true }).flatMap(entry => {
    const file = path.join(directory, entry.name);
    return entry.isDirectory() ? (['frames', 'source', 'portraits'].includes(entry.name) ? [] : walk(file)) : [file];
  });
}
const files = roots.flatMap(walk);
const bindings = new Map();
for (const file of files.filter(file => file.endsWith('/character.json'))) {
  const definition = JSON.parse(fs.readFileSync(file, 'utf8'));
  for (const [motion, animation] of Object.entries(definition.animations)) {
    if (animation.source_animation || !animation.file) continue;
    const source = path.resolve(path.dirname(file), animation.path || '', animation.file);
    if (!fs.existsSync(source)) continue;
    const priority = definition.status === 'integrated' ? 100 : 10;
    if (!bindings.has(source) || bindings.get(source).priority < priority) {
      bindings.set(source, { ...animation, motion, manifest: slash(file), priority });
    }
  }
}
const sources = files.filter(file => /\/animations\/[^/]+\/[^/]+\.png$/i.test(slash(file))).sort();
const knownLayouts = [];
for (const [file, animation] of bindings) {
  const [w, h] = animation.frame_size || [];
  if (!w || !h || !animation.sheet_columns || !animation.sheet_rows) continue;
  const image = readPng(file);
  if (w * animation.sheet_columns <= image.width && h * animation.sheet_rows <= image.height) {
    knownLayouts.push({ width: image.width, height: image.height, w, h, columns: animation.sheet_columns, rows: animation.sheet_rows });
  }
}
function cell(image, w, h, columns, index) {
  const data = Buffer.alloc(w * h * 4);
  const x = index % columns * w, y = Math.floor(index / columns) * h;
  for (let row = 0; row < h; row++) {
    image.data.copy(data, row * w * 4, ((y + row) * image.width + x) * 4, ((y + row) * image.width + x + w) * 4);
  }
  return { width: w, height: h, data };
}
const records = [];
for (const source of sources) {
  const before = hash(source), image = readPng(source), animation = bindings.get(path.resolve(source));
  let layout;
  if (animation?.frame_size?.every(Boolean) && animation.sheet_columns && animation.sheet_rows) {
    const [w, h] = animation.frame_size;
    if (w * animation.sheet_columns <= image.width && h * animation.sheet_rows <= image.height) {
      layout = { w, h, columns: animation.sheet_columns, rows: animation.sheet_rows };
    }
  }
  layout ||= knownLayouts.find(item => item.width === image.width && item.height === image.height);
  if (!layout && image.width % 200 === 0 && image.height % 200 === 0) {
    layout = { w: 200, h: 200, columns: image.width / 200, rows: image.height / 200 };
  }
  assert(layout, `No reliable grid for ${source}`);
  const { w, h, columns, rows } = layout;
  const directory = path.dirname(source), frames = [], empty = [];
  if (!checkOnly) {
    fs.mkdirSync(path.join(directory, 'frames'), { recursive: true });
    // These editing artifacts are not runtime textures and must not inflate the web export.
    fs.writeFileSync(path.join(directory, 'frames', '.gdignore'), '');
  }
  for (let index = 0; index < columns * rows; index++) {
    const frame = cell(image, w, h, columns, index);
    let visible = false;
    for (let p = 3; p < frame.data.length; p += 4) if (frame.data[p]) { visible = true; break; }
    if (!visible) { empty.push(index); continue; }
    const target = path.join(directory, 'frames', `${String(index).padStart(2, '0')}.png`);
    if (!checkOnly) writePng(target, frame);
    const actual = readPng(target);
    assert(actual.width === w && actual.height === h && actual.data.equals(frame.data), `Frame pixels differ: ${target}`);
    frames.push(index);
  }
  assert(frames.length, `Empty animation sheet: ${source}`);
  const motion = path.basename(directory);
  let order = animation?.frame_indices?.filter(index => frames.includes(index)) || frames.slice();
  if (!order.length) order = frames.slice();
  let fps = Number(animation?.fps || 12), playback = order.slice();
  // Keep the slower review cycles already supplied with these two new animations.
  if (motion === 'crouch') { fps = 16; playback = order.concat(order.slice().reverse()); }
  if (motion === 'pickup') fps = 16;
  const duration = order.length / fps;
  const times = animation?.frame_times;
  const durations = playback.map((_, index) => Array.isArray(times) && times.length === order.length && playback.length === order.length
    ? Math.max(0.001, ((times[index + 1] ?? 1) - times[index]) * duration) : 1 / fps);
  if (!animation?.loop && !['crouch', 'pickup'].includes(motion)) durations[durations.length - 1] += 0.2;
  records.push({ sheet: slash(source), source_sha256: before, frame_size: [w, h], columns, rows,
    frames: frames.length, indices: frames, empty_cells: empty, declared_frame_count: animation?.frame_count ?? null,
    runtime_manifest: animation?.manifest ?? null, preview_indices: playback, preview_fps: Math.min(50, fps),
    preview_durations: durations, gif: slash(path.join(directory, 'preview.gif')) });
  assert(hash(source) === before, `Original sheet changed: ${source}`);
}

function render(record, scratch) {
  return new Promise((resolve, reject) => {
    const directory = path.dirname(record.sheet);
    const sequence = path.join(scratch, createHash('sha256').update(record.sheet).digest('hex'));
    fs.mkdirSync(sequence);
    const total = record.preview_durations.reduce((sum, value) => sum + value, 0);
    let cursor = 0, end = record.preview_durations[0];
    for (let frame = 0; frame < Math.ceil(total * record.preview_fps - 1e-8); frame++) {
      const time = frame / record.preview_fps;
      while (cursor < record.preview_indices.length - 1 && time >= end - 1e-8) end += record.preview_durations[++cursor];
      const source = path.join(directory, 'frames', `${String(record.preview_indices[cursor]).padStart(2, '0')}.png`);
      fs.copyFileSync(source, path.join(sequence, `${String(frame).padStart(4, '0')}.png`));
    }
    const filter = 'scale=iw*2:ih*2:flags=neighbor,split[a][b];[a]palettegen=reserve_transparent=1[p];[b][p]paletteuse=dither=none:alpha_threshold=128';
    const child = spawn(ffmpeg, ['-v', 'error', '-y', '-filter_complex_threads', '1', '-framerate', String(record.preview_fps), '-i', path.join(sequence, '%04d.png'),
      '-filter_complex', filter, '-loop', '0', record.gif], { stdio: ['ignore', 'ignore', 'pipe'] });
    let errors = '';
    child.stderr.on('data', data => { errors += data; });
    child.on('error', reject);
    child.on('close', code => code === 0 ? resolve() : reject(new Error(`${record.sheet}: ${errors}`)));
  });
}
const scratch = checkOnly ? null : fs.mkdtempSync(path.join(os.tmpdir(), 'groova-previews-'));
try {
  let next = 0;
  if (!checkOnly) {
    const results = await Promise.allSettled(Array.from({ length: 3 }, async () => {
    while (next < records.length) { const record = records[next++]; await render(record, scratch); console.log(`READY ${record.sheet}: ${record.frames} frames + GIF`); }
    }));
    const failure = results.find(result => result.status === 'rejected');
    if (failure) throw failure.reason;
  }
  for (const record of records) {
    const gif = fs.readFileSync(record.gif);
    assert(gif.subarray(0, 6).toString() === 'GIF89a' && gif.readUInt16LE(6) === record.frame_size[0] * 2 && gif.readUInt16LE(8) === record.frame_size[1] * 2,
      `Invalid GIF: ${record.gif}`);
    assert(hash(record.sheet) === record.source_sha256, `Original sheet changed: ${record.sheet}`);
    if (!checkOnly) fs.writeFileSync(path.join(path.dirname(record.sheet), 'frames.json'), JSON.stringify(record, null, 2) + '\n');
  }
  if (!checkOnly) {
    fs.writeFileSync('assets/animation-previews.json', JSON.stringify({ sheets: records.length, frames: records.reduce((sum, row) => sum + row.frames, 0), records }, null, 2) + '\n');
    const table = records.map(row => `| ${row.sheet.replace('assets/', '')} | ${row.frames} | [PNG](${row.sheet.replace('assets/', '')}) | [Cuadros](${path.dirname(row.sheet).replace('assets/', '')}/frames/) | [GIF](${row.gif.replace('assets/', '')}) |`).join('\n');
    fs.writeFileSync('assets/ANIMATION_PREVIEWS.md', `# Cuadros y vistas previas\n\nCada hoja original se conserva. frames/ contiene PNG individuales con tamaño, transparencia y píxeles exactos de la celda; sus nombres mantienen el índice original. Las celdas completamente vacías se omiten. Los GIF tienen escala 2× con nearest y transparencia; siguen el orden de juego cuando está configurado. Los GIF de crouch y pickup conservan su velocidad de revisión de 16 FPS. Los cuadros PNG adicionales quedan fuera de la exportación web mediante .gdignore.\n\nAlgunas hojas guardadas en el conjunto de 40 cuadros contienen menos cuadros dibujados: se usa la cuadrícula real, sin inventar cuadros. frames.json documenta la extracción, las celdas vacías y la secuencia del GIF.\n\nRegenerar: node scripts/export-animation-previews.mjs. Verificar: node scripts/export-animation-previews.mjs --check. Requiere ffmpeg (FFMPEG_BIN permite cambiar el ejecutable).\n\n| Hoja | Cuadros | Original | Individuales | Vista previa |\n| --- | ---: | --- | --- | --- |\n${table}\n`);
  }
  console.log(`VERIFIED ${records.length} sheets, ${records.reduce((sum, row) => sum + row.frames, 0)} exact PNG frames, ${records.length} GIF previews; original sheets unchanged.`);
} finally {
  if (scratch) fs.rmSync(scratch, { recursive: true, force: true });
}
