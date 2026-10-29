import { spawnSync } from 'node:child_process';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { checkWeb } from './check-web.mjs';
import { deploymentConfig } from './deploy-config.mjs';
import { verifyDeployment, readManifest } from './verify-deploy.mjs';

export function deployArgs(site) {
  return ['netlify-cli', 'deploy', '--build', '--prod', '--context', 'production', '--site', site, '--dir', 'web', '--functions', 'netlify/functions'];
}

export async function deploy() {
  const target = deploymentConfig();
  checkWeb();
  // cmd.exe is only used for npx.cmd on Windows; site is restricted to letters,
  // digits and hyphens, and all other arguments are fixed literals.
  const result = spawnSync(process.platform === 'win32' ? 'npx.cmd' : 'npx', deployArgs(target.site), {
    stdio: 'inherit', shell: process.platform === 'win32'
  });
  if (result.error || result.status !== 0) throw new Error(result.error?.message || `Netlify termino con codigo ${result.status}.`);
  await verifyDeployment(target.url, readManifest());
  console.log(`Publicacion verificada: ${target.url}`);
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try { await deploy(); } catch (error) { console.error(`Deploy fallido: ${error.message}`); process.exitCode = 1; }
}
