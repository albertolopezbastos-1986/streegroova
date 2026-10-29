import { getStore } from '@netlify/blobs';

export function scoreStore(context) {
  // Almacen del sitio, no del deploy: conserva el ranking en futuras publicaciones.
  // Los previews y netlify dev nunca escriben en el ranking de produccion.
  const production = context?.deploy?.context === 'production';
  return getStore({ name: production ? 'street-groova-world-v1' : 'street-groova-test-v1', consistency: 'strong' });
}
