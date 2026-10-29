import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, utimesSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { checkWeb } from '../scripts/check-web.mjs';

test('build rejects missing, stale and invalid exports; accepts a complete export', () => {
  const root = mkdtempSync(join(tmpdir(), 'groova-web-'));
  try {
    for (const dir of ['web', 'scripts', 'scenes', 'assets/fonts']) mkdirSync(join(root, dir), { recursive: true });
    writeFileSync(join(root, 'assets/fonts/PressStart2P-Regular.ttf'), 'font fixture');
    assert.throws(() => checkWeb(root), /Falta/);
    for (const file of ['project.godot', 'export_presets.cfg', 'scripts/game.gd', 'scenes/main.tscn']) writeFileSync(join(root, file), 'source');
    for (const file of ['index.js', 'index.wasm', 'index.pck', 'index.html']) writeFileSync(join(root, 'web', file), 'export');
    const pack = join(root, 'web', 'index.pck');
    utimesSync(pack, 1, 1);
    assert.throws(() => checkWeb(root), /desactualizada/);
    utimesSync(pack, new Date(), new Date(Date.now() + 1000));
    assert.throws(() => checkWeb(root), /HTML incorrecto/);
    writeFileSync(join(root, 'scripts/mobile-name.js'), '// native mobile input');
    writeFileSync(join(root, 'web/index.html'), '<head><script src="index.js"></script>"experimentalVK":true</head>');
    assert.doesNotThrow(() => checkWeb(root));
    const first = JSON.parse(readFileSync(join(root, 'web/deployment.json'), 'utf8'));
    assert.match(first.game_sha256, /^[a-f0-9]{64}$/);
    assert.match(first.mobile_input_sha256, /^[a-f0-9]{64}$/);
    checkWeb(root);
    const html = readFileSync(join(root, 'web/index.html'), 'utf8');
    assert.equal(html.match(/src="mobile-name.js"/g).length, 1);
    writeFileSync(join(root, 'scripts/mobile-name.js'), '// changed mobile input');
    checkWeb(root);
    const second = JSON.parse(readFileSync(join(root, 'web/deployment.json'), 'utf8'));
    assert.equal(second.game_sha256, first.game_sha256);
    assert.notEqual(second.mobile_input_sha256, first.mobile_input_sha256);
  } finally { rmSync(root, { recursive: true, force: true }); }
});
