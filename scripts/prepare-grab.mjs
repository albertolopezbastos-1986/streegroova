import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { readPng, writePng } from './environment-tiles.mjs';

const root = 'assets/characters';
const copy = (source, sx, sy, w, h, target, dx, dy) => {
  assert(dx >= 0 && dy >= 0 && dx + w <= target.width && dy + h <= target.height, 'Sprite would be clipped');
  for (let y = 0; y < h; y++) source.data.copy(target.data, ((dy + y) * target.width + dx) * 4,
    ((sy + y) * source.width + sx) * 4, ((sy + y) * source.width + sx + w) * 4);
};
const blank = (width, height) => ({ width, height, data: Buffer.alloc(width * height * 4) });
const scratch = fs.mkdtempSync(path.join(os.tmpdir(), 'groova-grab-'));
try {
  const jobs = [
    { id: 'beto', motion: 'grab', source: `${root}/beto/animations/grab/source/grab-current.png`, w: 200, h: 200, columns: 4, rows: 4, sourceColumns: 4, count: 13, hold: 2, file: 'grab.png' },
    { id: 'beto', motion: 'grab_punch_01', source: `${root}/beto/animations/grab/source/grab-current.png`, w: 200, h: 200, columns: 4, rows: 4, sourceColumns: 4, count: 13, hold: null, file: 'grabpunch.png', start: 3, fps: 24, speed: 1 },
    { id: 'cami', motion: 'grab', source: `${root}/cami/animations/grab/source/grab-current.png`, w: 162, h: 245, columns: 4, rows: 4, sourceColumns: 4, count: 13, hold: 2, file: 'grab.png' },
    { id: 'cami', motion: 'grab_throw', source: `${root}/cami/animations/grab_throw/source/grabthrow-original.png`, w: 162, h: 245, columns: 3, rows: 3, sourceColumns: 3, count: 9, hold: null, release: 6, file: 'grabthrow.png' },
    { id: 'cami', motion: 'runslide', source: `${root}/cami/animations/runslide/source/runslide-original.png`, w: 162, h: 245, columns: 3, rows: 3, sourceColumns: 3, count: 9, hold: null, file: 'runslide.png', fps: 18, speed: 1 },
    ...[1, 2, 3].map(step => ({ id: 'cami', motion: `grab_punch_${String(step).padStart(2, '0')}`, source: `${root}/cami/animations/grab_punch_01/source/grabpunch-original.png`, w: 162, h: 245, columns: 3, rows: 3, sourceColumns: 3, count: 9, hold: null, file: 'grabpunch.png', start: 1, fps: 24, speed: 1 })),
  ];
  for (const job of jobs) {
    const { id, motion, w, h, columns, rows, count, hold } = job;
    const folder = `${root}/${id}/animations/${motion}`;
    const sourceFile = job.source, source = readPng(sourceFile);
    const sheet = blank(w * columns, h * rows);
    fs.mkdirSync(`${folder}/frames`, { recursive: true });
    fs.writeFileSync(`${folder}/frames/.gdignore`, '');
    const sequence = `${scratch}/${id}-${motion}`;
    fs.mkdirSync(sequence);
    for (let index = 0; index < count; index++) {
      const frame = blank(w, h);
      copy(source, index % job.sourceColumns * w, Math.floor(index / job.sourceColumns) * h, w, h, frame, 0, 0);
      const file = `${folder}/frames/${String(index).padStart(2, '0')}.png`;
      writePng(file, frame);
      copy(frame, 0, 0, w, h, sheet, index % columns * w, Math.floor(index / columns) * h);

    }
    writePng(`${folder}/${job.file}`, sheet);
    // Match runtime order: captures stop at hold; punches omit their idle frame.
    const previewLast = hold ?? count - 1;
    const playback = Array.from({ length: previewLast - (job.start ?? 0) + 1 }, (_, i) => i + (job.start ?? 0));
    const fps = job.fps ?? 20, speed = job.speed ?? 2, previewFps = fps * speed;
    const pauseFrames = Math.round(previewFps * (hold === null ? 0.2 : 0.5));
    const previewOrder = playback.concat(Array(pauseFrames).fill(previewLast));
    for (const [index, frame] of previewOrder.entries()) fs.copyFileSync(`${folder}/frames/${String(frame).padStart(2, '0')}.png`, `${sequence}/${String(index).padStart(4, '0')}.png`);
    const result = spawnSync(process.env.FFMPEG_BIN || 'ffmpeg', ['-v', 'error', '-y', '-filter_complex_threads', '1', '-framerate', String(previewFps), '-i', `${sequence}/%04d.png`, '-filter_complex', 'scale=iw*2:ih*2:flags=neighbor,split[a][b];[a]palettegen=reserve_transparent=1[p];[b][p]paletteuse=dither=none:alpha_threshold=128', '-loop', '0', `${folder}/preview.gif`], { encoding: 'utf8' });
    assert.equal(result.status, 0, result.stderr);
    fs.writeFileSync(`${folder}/frames.json`, JSON.stringify({ sheet: `${folder}/${job.file}`, source: sourceFile, source_sha256: createHash('sha256').update(fs.readFileSync(sourceFile)).digest('hex'), frame_size: [w, h], columns, rows, frames: count, indices: Array.from({ length: count }, (_, i) => i), hold_frame: hold, release_frame: job.release ?? null, runtime_fps: fps, player_speed: speed, preview_fps: previewFps, preview_indices: playback, preview_hold_seconds: pauseFrames / previewFps, gif: `${folder}/preview.gif` }, null, 2) + '\n');
    console.log(`${id}/${motion}: ${count} frames, sheet and preview saved in ${folder}`);
  }
} finally {
  fs.rmSync(scratch, { recursive: true, force: true });
}
