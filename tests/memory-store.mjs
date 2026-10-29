// Doble del contrato de Blobs con inserciones condicionales atomicas.
export class MemoryStore {
  data = new Map();
  failIndexOnce = false;
  async get(key) { return structuredClone(this.data.get(key) ?? null); }
  async setJSON(key, value, options = {}) {
    await new Promise((resolve) => setImmediate(resolve));
    if (key.startsWith('rank/') && this.failIndexOnce) {
      this.failIndexOnce = false;
      throw new Error('Simulated index outage');
    }
    if (options.onlyIfNew && this.data.has(key)) return { modified: false };
    this.data.set(key, structuredClone(value));
    return { modified: true, etag: key };
  }
  async list({ prefix }) {
    return { blobs: [...this.data.keys()].filter((key) => key.startsWith(prefix)).reverse().map((key) => ({ key })) };
  }
}
