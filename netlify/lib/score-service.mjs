export const MAX_SCORE = 9_999_990;
const BODY_LIMIT = 1024;
const ID_PATTERN = /^[a-f0-9]{32}$/;

class HttpError extends Error {
  constructor(status, message) { super(message); this.status = status; }
}

function json(data, status = 200, headers = {}) {
  return Response.json(data, { status, headers: { 'Cache-Control': 'no-store', ...headers } });
}

export function validateSubmission(body) {
  if (!body || typeof body !== 'object' || Array.isArray(body)) throw new HttpError(400, 'Datos invalidos.');
  if (Object.keys(body).some((key) => !['id', 'name', 'score'].includes(key))) throw new HttpError(400, 'Campos invalidos.');
  if (typeof body.id !== 'string' || !ID_PATTERN.test(body.id)) throw new HttpError(400, 'Partida invalida.');
  if (typeof body.name !== 'string') throw new HttpError(400, 'Nombre invalido.');
  const name = body.name.normalize('NFC').trim().toUpperCase();
  if ([...name].length < 1 || [...name].length > 12 || !/^[\p{L}\p{N} _.-]+$/u.test(name)) {
    throw new HttpError(400, 'Nombre: 1 a 12 letras, numeros, espacios, punto, guion o guion bajo.');
  }
  if (!Number.isSafeInteger(body.score) || body.score < 0 || body.score > MAX_SCORE || body.score % 10 !== 0) {
    throw new HttpError(400, 'Puntuacion invalida.');
  }
  return { id: body.id, name, score: body.score };
}

async function readBody(request) {
  if (!/^application\/json(?:\s*;|$)/i.test(request.headers.get('content-type') || '')) {
    throw new HttpError(415, 'Se requiere JSON.');
  }
  if (Number(request.headers.get('content-length')) > BODY_LIMIT) throw new HttpError(413, 'Solicitud demasiado grande.');
  const reader = request.body?.getReader();
  if (!reader) throw new HttpError(400, 'Faltan datos.');
  const chunks = [];
  let size = 0;
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    size += value.byteLength;
    if (size > BODY_LIMIT) {
      await reader.cancel();
      throw new HttpError(413, 'Solicitud demasiado grande.');
    }
    chunks.push(value);
  }
  try { return JSON.parse(Buffer.concat(chunks).toString('utf8')); }
  catch { throw new HttpError(400, 'JSON invalido.'); }
}

function indexKey(entry) {
  // La clave contiene el orden, asi GET solo descarga los diez registros finales.
  const inverted = String(MAX_SCORE - entry.score).padStart(7, '0');
  return `rank/${inverted}/${entry.date}/${entry.id}`;
}

export async function submitScore(store, body, now = () => new Date()) {
  const proposed = validateSubmission(body);
  const key = `submissions/${proposed.id}`;
  let entry = await store.get(key, { type: 'json' });
  let created = false;
  if (entry === null) {
    const candidate = { ...proposed, date: now().toISOString() };
    const result = await store.setJSON(key, candidate, { onlyIfNew: true });
    created = result.modified;
    // Leer el ganador tambien comprueba que la escritura se haya persistido.
    entry = await store.get(key, { type: 'json' });
  }
  if (!entry) throw new Error('No se pudo confirmar la escritura.');
  if (entry.name !== proposed.name || entry.score !== proposed.score) {
    throw new HttpError(409, 'Esta partida ya fue registrada con otros datos.');
  }
  // Repetible: repara un corte entre el registro y el indice sin duplicar nada.
  const rankKey = indexKey(entry);
  await store.setJSON(rankKey, entry, { onlyIfNew: true });
  if (await store.get(rankKey, { type: 'json' }) === null) throw new Error('Indice no confirmado.');
  return { entry, created };
}

export async function readTopScores(store) {
  // list pagina automaticamente. No se sobrescribe un "top10.json" compartido.
  const { blobs } = await store.list({ prefix: 'rank/' });
  const keys = blobs.map(({ key }) => key).sort().slice(0, 10);
  const scores = await Promise.all(keys.map((key) => store.get(key, { type: 'json' })));
  if (scores.some((entry) => entry === null)) throw new Error('Lectura incompleta.');
  return scores;
}

export function createHandler(kind, getStore) {
  return async (request, context) => {
    const method = kind === 'read' ? 'GET' : 'POST';
    if (request.method !== method) return json({ error: 'Metodo no permitido.' }, 405, { Allow: method });
    try {
      if (kind === 'write') {
        const origin = request.headers.get('origin');
        if ((origin && origin !== new URL(request.url).origin) || request.headers.get('sec-fetch-site') === 'cross-site') {
          throw new HttpError(403, 'Origen no permitido.');
        }
        const body = await readBody(request);
        // Validar antes de abrir Blobs evita operaciones para solicitudes invalidas.
        validateSubmission(body);
        const { entry, created } = await submitScore(getStore(context), body);
        return json({ entry }, created ? 201 : 200);
      }
      return json({ scores: await readTopScores(getStore(context)) });
    } catch (error) {
      if (error instanceof HttpError) return json({ error: error.message }, error.status);
      console.error('Ranking storage operation failed:', error.message);
      return json({ error: 'Ranking temporalmente no disponible. Reintenta.' }, 503);
    }
  };
}
