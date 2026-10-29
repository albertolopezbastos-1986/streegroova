import { createHandler } from '../lib/score-service.mjs';
import { scoreStore } from '../lib/store.mjs';

export default createHandler('read', scoreStore);
export const config = {
  path: ['/api/scores', '/.netlify/functions/scores'],
  rateLimit: { windowLimit: 60, windowSize: 60, aggregateBy: ['ip', 'domain'] }
};
