import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createHandler, submitScore, readTopScores, validateSubmission, MAX_SCORE } from '../netlify/lib/score-service.mjs';
import { MemoryStore } from './memory-store.mjs';

const id = (n) => n.toString(16).padStart(32, '0');
const payload = (n, score = n * 10) => ({ id: id(n), name: `LUCHADOR${n}`, score });
const date = () => new Date('2026-10-26T12:00:00.000Z');
const post = (body, headers = {}) => new Request('https://game.netlify.app/api/submit-score', {
  method: 'POST', headers: { 'Content-Type': 'application/json', ...headers }, body: typeof body === 'string' ? body : JSON.stringify(body)
});

test('100 jugadores simultaneos conservan todos sus resultados y el Top 10 correcto', async () => {
  const store = new MemoryStore();
  await Promise.all(Array.from({ length: 100 }, (_, i) => submitScore(store, payload(i), date)));
  assert.equal([...store.data.keys()].filter((key) => key.startsWith('submissions/')).length, 100);
  const top = await readTopScores(store);
  assert.deepEqual(top.map(({ score }) => score), [990, 980, 970, 960, 950, 940, 930, 920, 910, 900]);
  assert.equal(top[0].date, date().toISOString());
});

test('20 reintentos concurrentes de una partida producen un registro y una fecha', async () => {
  const store = new MemoryStore();
  const results = await Promise.all(Array.from({ length: 20 }, () => submitScore(store, payload(1), date)));
  assert.equal(results.filter(({ created }) => created).length, 1);
  assert.equal(store.data.size, 2);
  assert.equal((await readTopScores(store)).length, 1);
  await assert.rejects(submitScore(store, { ...payload(1), score: 20 }, date), { status: 409 });
  assert.equal((await readTopScores(store))[0].score, 10);
});

test('el reintento repara un corte entre guardado e indice sin duplicar ni cambiar fecha', async () => {
  const store = new MemoryStore();
  store.failIndexOnce = true;
  await assert.rejects(submitScore(store, payload(1), date));
  assert.equal(store.data.size, 1);
  await submitScore(store, payload(1), () => new Date('2027-01-01'));
  assert.equal((await readTopScores(store))[0].date, date().toISOString());
  assert.equal(store.data.size, 2);
});

test('empates: fecha del servidor y luego id para orden determinista', async () => {
  const store = new MemoryStore();
  await submitScore(store, payload(2, 100), () => new Date('2026-10-26T12:00:01Z'));
  await submitScore(store, payload(3, 100), date);
  await submitScore(store, payload(1, 100), date);
  assert.deepEqual((await readTopScores(store)).map(({ id: value }) => value), [id(1), id(3), id(2)]);
});

test('normalizacion, limite de nombre y puntajes validos', () => {
  assert.equal(validateSubmission({ ...payload(1), name: '  beto  ' }).name, 'BETO');
  assert.equal(validateSubmission({ ...payload(1), name: 'JOSÉ' }).name, 'JOSÉ');
  assert.equal(validateSubmission({ ...payload(1), score: 0 }).score, 0);
  assert.equal(validateSubmission({ ...payload(1), score: MAX_SCORE }).score, MAX_SCORE);
  for (const override of [{ name: '' }, { name: 'ABCDEFGHIJKLM' }, { name: '<script>' }, { name: 'A\nB' }, { score: -10 }, { score: 11 }, { score: 10.5 }, { score: '100' }, { score: MAX_SCORE + 10 }, { id: '../bad' }, { date: '2020-01-01' }]) {
    assert.throws(() => validateSubmission({ ...payload(1), ...override }), { status: 400 });
  }
});

test('API: 201 guardado, 200 reintento, GET mismo ranking y sin cache', async () => {
  const store = new MemoryStore();
  const write = createHandler('write', () => store);
  const read = createHandler('read', () => store);
  const result = await write(post(payload(1), { Origin: 'https://game.netlify.app' }));
  assert.equal(result.status, 201);
  assert.equal(result.headers.get('cache-control'), 'no-store');
  assert.equal((await write(post(payload(1)))).status, 200);
  const response = await read(new Request('https://game.netlify.app/api/scores'));
  assert.equal((await response.json()).scores[0].name, 'LUCHADOR1');
  assert.equal((await read(post(payload(1)))).status, 405);
});

test('API: rechaza origen, JSON, cuerpos enormes, formato y datos sin tocar Blobs', async () => {
  const write = createHandler('write', () => { throw new Error('No debe abrir Blobs'); });
  assert.equal((await write(post(payload(1), { Origin: 'https://otro.example' }))).status, 403);
  assert.equal((await write(post(payload(1), { 'Sec-Fetch-Site': 'cross-site' }))).status, 403);
  assert.equal((await write(post('{'))).status, 400);
  assert.equal((await write(post('x'.repeat(1025)))).status, 413);
  assert.equal((await write(post(payload(1), { 'Content-Type': 'text/plain' }))).status, 415);
  assert.equal((await write(post({ ...payload(1), score: -1 }))).status, 400);
});

test('API: errores del almacenamiento devuelven 503 sin filtrar detalles internos', async () => {
  const read = createHandler('read', () => { throw new Error('private-token'); });
  const response = await read(new Request('https://game.netlify.app/api/scores'));
  assert.equal(response.status, 503);
  assert.doesNotMatch(await response.text(), /private-token/);
});

test('cada endpoint tiene un path con rate limit y produccion se decide en runtime', async () => {
  for (const file of ['scores', 'submit-score']) {
    const module = await import(`../netlify/functions/${file}.mjs`);
    assert.ok(module.config.path[0].startsWith('/api/'));
    assert.ok(module.config.path[1].startsWith('/.netlify/functions/'));
    assert.deepEqual(module.config.rateLimit.aggregateBy, ['ip', 'domain']);
    assert.equal(module.config.rateLimit.windowSize, 60);
    assert.ok(module.config.rateLimit.windowLimit <= 60);
  }
  assert.match(readFileSync('netlify/lib/store.mjs', 'utf8'), /context\?\.deploy\?\.context/);
});
