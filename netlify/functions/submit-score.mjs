import { createHandler } from '../lib/score-service.mjs';
import { scoreStore } from '../lib/store.mjs';

export default createHandler('write', scoreStore);
export const config = {
  path: ['/api/submit-score', '/.netlify/functions/submit-score'],
  rateLimit: { windowLimit: 10, windowSize: 60, aggregateBy: ['ip', 'domain'] }
};
