import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, writeFileSync, readFileSync, rmSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { deploymentConfig } from '../scripts/deploy-config.mjs';
import { deployArgs } from '../scripts/deploy.mjs';
import { verifyDeployment } from '../scripts/verify-deploy.mjs';
import { runnablePath, preparePreset, findGodot } from '../scripts/export-game.mjs';

test('placeholder permits local work but cannot be used as a deploy target', () => {
  assert.throws(() => deploymentConfig('.', {}), /placeholdernetlify/);
  assert.deepEqual(deploymentConfig('.', { NETLIFY_SITE_ID: 'street-groova', DEPLOY_URL: 'https://street-groova.netlify.app/' }), {
    site: 'street-groova', url: 'https://street-groova.netlify.app'
  });
  assert.throws(() => deploymentConfig('.', { NETLIFY_SITE_ID: 'street-groova', DEPLOY_URL: 'http://street-groova.netlify.app' }), /HTTPS/);
  assert.throws(() => deploymentConfig('.', { NETLIFY_SITE_ID: 'site;bad', DEPLOY_URL: 'https://game.test' }), /nombre o ID/);
});

test('deploy selects its own site, production context, game folder and Functions', () => {
  assert.deepEqual(deployArgs('street-groova'), ['netlify-cli', 'deploy', '--build', '--prod', '--context', 'production', '--site', 'street-groova', '--dir', 'web', '--functions', 'netlify/functions']);
});

test('verification detects wrong release, missing Functions and old mobile keyboard', async () => {
  const expected = { game_sha256: 'pack', mobile_input_sha256: 'input' };
  const fetcher = (failure) => async (url) => {
    if (url.includes('deployment.json')) {
      if (failure === 'manifest') return new Response('', { status: 404 });
      return Response.json(failure === 'version' ? { ...expected, game_sha256: 'old' } : expected);
    }
    if (url.endsWith('/api/scores')) {
      if (failure === 'functions') return new Response('', { status: 404 });
      if (failure === 'storage') return new Response('', { status: 503 });
      return Response.json(failure === 'data' ? {} : { scores: [] });
    }
    return new Response(failure === 'html' ? 'old HTML' : '<script src="mobile-name.js"></script>"experimentalVK":true');
  };
  await verifyDeployment('https://game.test/', expected, fetcher());
  for (const [failure, message] of [['manifest', /deployment.json/], ['version', /no coincide/], ['functions', /Functions/], ['storage', /503/], ['data', /invalida/], ['html', /teclado/]]) {
    await assert.rejects(verifyDeployment('https://game.test', expected, fetcher(failure)), message);
  }
});

test('export preserves runtime scripts while excluding build output and enabling mobile keyboard', () => {
  const previous = process.cwd();
  const root = mkdtempSync(join(tmpdir(), 'groova-preset-'));
  try {
    process.chdir(root);
    writeFileSync('export_presets.cfg', '[preset.0]\nname="Web"\nplatform="Web"\nexclude_filter="scripts/*,web/*"\n\n[preset.0.options]\nhtml/experimental_virtual_keyboard=false\n');
    preparePreset();
    const config = readFileSync('export_presets.cfg', 'utf8');
    assert.doesNotMatch(config, /scripts\/\*/);
    assert.match(config, /node_modules\/\*/);
    assert.match(config, /html\/experimental_virtual_keyboard=true/);
    preparePreset();
    assert.equal(readFileSync('export_presets.cfg', 'utf8'), config);
    assert.equal(runnablePath('C:\\Users\\Test Folder\\Godot.exe'), process.platform === 'win32' ? 'C:\\Users\\Test Folder\\Godot.exe' : '/mnt/c/Users/Test Folder/Godot.exe');
  } finally { process.chdir(previous); rmSync(root, { recursive: true, force: true }); }
});

test('explicit missing or incompatible engine gives an actionable export error', () => {
  const before = process.env.GODOT_BIN;
  try {
    process.env.GODOT_BIN = join(tmpdir(), 'groova-engine-does-not-exist');
    assert.throws(() => findGodot(), /GODOT_BIN/);
    process.env.GODOT_BIN = process.execPath;
    assert.throws(() => findGodot(), /misma version/);
  } finally {
    if (before === undefined) delete process.env.GODOT_BIN;
    else process.env.GODOT_BIN = before;
  }
});
