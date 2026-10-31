import fs from 'node:fs';
import zlib from 'node:zlib';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

export const WIDTH = 1536, HEIGHT = 1024, OVERLAP = 128;
export const ids = ['docks-night', 'neon-bar', 'train-interior', 'forest-golden-hour', 'shopping-mall'];

export function readPng(file) {
  const png = fs.readFileSync(file), width = png.readUInt32BE(16), height = png.readUInt32BE(20);
  const channels = png[25] === 6 ? 4 : png[25] === 2 ? 3 : 0;
  if (png[24] !== 8 || !channels || png[28] !== 0) throw Error(`Unsupported PNG: ${file}`);
  const chunks = [];
  for (let p = 8; p < png.length;) {
    const n = png.readUInt32BE(p);
    if (png.toString('ascii', p + 4, p + 8) === 'IDAT') chunks.push(png.subarray(p + 8, p + 8 + n));
    p += n + 12;
  }
  const raw = zlib.inflateSync(Buffer.concat(chunks)), stride = width * channels;
  const pixels = Buffer.alloc(width * height * channels);
  const paeth = (a, b, c) => { const p = a + b - c, x = Math.abs(p - a), y = Math.abs(p - b), z = Math.abs(p - c); return x <= y && x <= z ? a : y <= z ? b : c; };
  for (let y = 0; y < height; y++) {
    const filter = raw[y * (stride + 1)];
    for (let x = 0; x < stride; x++) {
      const i = y * stride + x, a = x >= channels ? pixels[i - channels] : 0, b = y ? pixels[i - stride] : 0, c = y && x >= channels ? pixels[i - stride - channels] : 0;
      const prediction = [0, a, b, Math.floor((a + b) / 2), paeth(a, b, c)][filter];
      if (prediction === undefined) throw Error('Invalid PNG filter');
      pixels[i] = (raw[y * (stride + 1) + x + 1] + prediction) & 255;
    }
  }
  const data = Buffer.alloc(width * height * 4, 255);
  for (let p = 0; p < width * height; p++) {
    pixels.copy(data, p * 4, p * channels, p * channels + channels);
  }
  return { width, height, data };
}

export function writePng(file, image) {
  const { width, height, data } = image;
  const crc = bytes => { let c = 0xffffffff; for (const value of bytes) { c ^= value; for (let j = 0; j < 8; j++) c = (c >>> 1) ^ ((c & 1) ? 0xedb88320 : 0); } return (c ^ 0xffffffff) >>> 0; };
  const chunk = (type, bytes) => { const t = Buffer.from(type), n = Buffer.alloc(4), c = Buffer.alloc(4); n.writeUInt32BE(bytes.length); c.writeUInt32BE(crc(Buffer.concat([t, bytes]))); return Buffer.concat([n, t, bytes, c]); };
  const header = Buffer.alloc(13); header.writeUInt32BE(width); header.writeUInt32BE(height, 4); header[8] = 8; header[9] = 6;
  const raw = Buffer.alloc(height * (width * 4 + 1));
  for (let y = 0; y < height; y++) data.copy(raw, y * (width * 4 + 1) + 1, y * width * 4, (y + 1) * width * 4);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', header), chunk('IDAT', zlib.deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]));
}

function copyStrip(from, to, sourceX, targetX, width) {
  for (let y = 0; y < HEIGHT; y++) from.data.copy(to.data, (y * WIDTH + targetX) * 4, (y * WIDTH + sourceX) * 4, (y * WIDTH + sourceX + width) * 4);
}

const [command, id, numberText, source, floorText] = process.argv.slice(2);
if (command && process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  if (!ids.includes(id)) throw Error('Unknown environment');
  const number = Number(numberText), tile = n => `assets/environment/tiles/${id}/${String(n).padStart(2, '0')}.png`;
  if (number < 1 || number > 5) throw Error('Expected tile 1–5');
  if (command === 'guide') {
    const guide = readPng('assets/environment/neighborhood-pixel.png');
    copyStrip(readPng(tile(number - 1)), guide, WIDTH - OVERLAP, 0, OVERLAP);
    if (number === 5) copyStrip(readPng(tile(1)), guide, 0, WIDTH - OVERLAP, OVERLAP);
    writePng(`.godot/environment-guides/${id}/${number}.png`, guide);
  } else if (command === 'accept') {
    const image = readPng(source);
    if (image.width !== WIDTH || image.height !== HEIGHT) throw Error(`Wrong dimensions: ${id}/${number}: ${image.width}x${image.height}; expected ${WIDTH}x${HEIGHT}`);
    const sourceFloor = Number(floorText ?? 748), shift = 748 - sourceFloor;
    if (shift) {
      const original = Buffer.from(image.data);
      for (let y = 0; y < HEIGHT; y++) {
        const sourceY = Math.max(0, Math.min(HEIGHT - 1, y - shift));
        original.copy(image.data, y * WIDTH * 4, sourceY * WIDTH * 4, (sourceY + 1) * WIDTH * 4);
      }
    }
    // Keep the exact overlap supplied to the image editor; no rescaling or mirroring.
    if (number > 1) copyStrip(readPng(tile(number - 1)), image, WIDTH - OVERLAP, 0, OVERLAP);
    if (number === 5) copyStrip(readPng(tile(1)), image, 0, WIDTH - OVERLAP, OVERLAP);
    writePng(tile(number), image);
    process.stdout.write(`${id}/${number}: ${WIDTH}x${HEIGHT}, no resampling, vertical framing ${shift}px, overlap ${OVERLAP}\n`);
  } else throw Error('Expected guide or accept');
}
