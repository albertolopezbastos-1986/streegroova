import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { deploymentConfig } from './deploy-config.mjs';

export function readManifest() {
  return JSON.parse(readFileSync('web/deployment.json', 'utf8'));
}

export async function verifyDeployment(url, expected, fetcher = fetch) {
  const base = url.replace(/\/$/, '');
  const options = () => ({ cache: 'no-store', signal: AbortSignal.timeout(15000) });
  const manifest = await fetcher(`${base}/deployment.json?t=${Date.now()}`, options());
  if (!manifest.ok) throw new Error('Falta deployment.json en el sitio. Revisa que se publique web/.');
  const deployed = await manifest.json();
  if (!expected.game_sha256 || !expected.mobile_input_sha256 || deployed.game_sha256 !== expected.game_sha256 || deployed.mobile_input_sha256 !== expected.mobile_input_sha256) {
    throw new Error('La version publicada no coincide con el build local.');
  }
  const api = await fetcher(`${base}/api/scores`, options());
  if (api.status === 404) throw new Error('Faltan las Functions del ranking. Publica con npm run deploy.');
  if (!api.ok) throw new Error(`El ranking responde HTTP ${api.status}.`);
  if (!Array.isArray((await api.json()).scores)) throw new Error('Respuesta del ranking invalida.');
  const page = await fetcher(`${base}/?verify=${Date.now()}`, options());
  const html = await page.text();
  if (!page.ok || !html.includes('src="mobile-name.js"') || !/"experimentalVK"\s*:\s*true/.test(html)) {
    throw new Error('El HTML publicado no tiene el teclado para celulares actualizado.');
  }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    const url = process.argv[2] || deploymentConfig().url;
    await verifyDeployment(url, readManifest());
    console.log('Publicacion verificada: version correcta, campo de nombre y ranking accesibles.');
  } catch (error) { console.error(`Verificacion fallida: ${error.message}`); process.exitCode = 1; }
}
