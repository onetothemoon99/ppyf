// Soft warm radial glow for the sky-lantern halo (BillboardGui ImageLabel). 256x256 RGBA PNG.
const zlib = require('zlib'), fs = require('fs');
const W = 256, H = 256, rows = [];
for (let y = 0; y < H; y++) {
  const row = Buffer.alloc(1 + W * 4); row[0] = 0;
  for (let x = 0; x < W; x++) {
    const dx = (x + 0.5 - W / 2) / (W / 2), dy = (y + 0.5 - H / 2) / (H / 2);
    const r = Math.min(1, Math.sqrt(dx * dx + dy * dy));
    const a = Math.pow(1 - r, 2.2);               // soft falloff to 0 at the edge
    const core = Math.pow(Math.max(0, 1 - r * 2.2), 2); // whiter centre
    row[1 + x * 4] = 255;
    row[2 + x * 4] = Math.round(170 + 70 * core);
    row[3 + x * 4] = Math.round(80 + 120 * core);
    row[4 + x * 4] = Math.round(255 * a);
  }
  rows.push(row);
}
function chunk(type, data) {
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
  const td = Buffer.concat([Buffer.from(type), data]);
  let c = ~0; for (const b of td) { c ^= b; for (let k = 0; k < 8; k++) c = (c >>> 1) ^ (0xEDB88320 & -(c & 1)); }
  const crc = Buffer.alloc(4); crc.writeUInt32BE((~c) >>> 0);
  return Buffer.concat([len, td, crc]);
}
const ihdr = Buffer.alloc(13); ihdr.writeUInt32BE(W, 0); ihdr.writeUInt32BE(H, 4); ihdr[8] = 8; ihdr[9] = 6;
fs.writeFileSync('lantern_halo.png', Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', ihdr), chunk('IDAT', zlib.deflateSync(Buffer.concat(rows))), chunk('IEND', Buffer.alloc(0))]));
console.log('ok');
