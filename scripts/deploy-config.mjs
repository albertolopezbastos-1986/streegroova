import { readFileSync } from 'node:fs';

export function deploymentConfig(root = '.', env = process.env) {
  const config = JSON.parse(readFileSync(`${root}/deploy.config.json`, 'utf8'));
  const site = (env.NETLIFY_SITE_ID || config.site || '').trim();
  const url = (env.DEPLOY_URL || config.url || '').trim().replace(/\/$/, '');
  if (!site || site === 'placeholdernetlify' || !url || url.includes('placeholdernetlify')) {
    throw new Error('Todavia esta configurado placeholdernetlify. Cuando tengas el sitio, cambia site y url en deploy.config.json (o define NETLIFY_SITE_ID y DEPLOY_URL). Export y build funcionan sin una URL real.');
  }
  if (!/^[a-zA-Z0-9-]+$/.test(site)) throw new Error('site debe ser el nombre o ID del sitio Netlify.');
  const target = new URL(url);
  if (target.protocol !== 'https:' || target.pathname !== '/' || target.search || target.hash || target.username || target.password) {
    throw new Error('url debe ser el origen HTTPS del sitio, por ejemplo https://mi-juego.netlify.app.');
  }
  return { site, url: target.origin };
}
