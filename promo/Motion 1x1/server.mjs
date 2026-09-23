import http from 'node:http';
import { createReadStream } from 'node:fs';
import { stat } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PORT = 4344;

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.wav': 'audio/wav',
  '.mp4': 'video/mp4',
  '.webm': 'video/webm'
};

function byteRange(value, size) {
  const match = /^bytes=(\d*)-(\d*)$/.exec(value || '');
  if (!match || (!match[1] && !match[2]) || size < 1) return null;
  const start = match[1] ? Number(match[1]) : Math.max(0, size - Number(match[2]));
  const end = match[1] && match[2] ? Math.min(size - 1, Number(match[2])) : size - 1;
  return Number.isSafeInteger(start) && Number.isSafeInteger(end) && start >= 0 && start <= end && start < size ? { start, end } : null;
}

const server = http.createServer(async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Range, Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  let pathname;
  try {
    pathname = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
  } catch {
    res.writeHead(400);
    res.end('Invalid URL');
    return;
  }

  if (pathname === '/' || pathname === '') pathname = '/index.html';

  const filePath = path.join(__dirname, pathname);
  const ext = path.extname(filePath).toLowerCase();

  let fileStat;
  try {
    fileStat = await stat(filePath);
    if (fileStat.isDirectory()) {
      res.writeHead(403);
      res.end('Directory listing forbidden');
      return;
    }
  } catch (err) {
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('File not found');
    return;
  }

  const contentType = MIME[ext] || 'application/octet-stream';
  const size = fileStat.size;

  // Video Streaming with Byte Range support (Crucial for Chrome Video Seeking & Decoding!)
  if (ext === '.mp4' || ext === '.webm' || req.headers.range) {
    const range = req.headers.range ? byteRange(req.headers.range, size) : { start: 0, end: size - 1 };
    if (!range) {
      res.writeHead(416, { 'Content-Range': `bytes */${size}` });
      res.end();
      return;
    }

    const headers = {
      'Content-Type': contentType,
      'Accept-Ranges': 'bytes',
      'Content-Length': range.end - range.start + 1,
      'Content-Range': `bytes ${range.start}-${range.end}/${size}`,
      'Cache-Control': 'no-cache'
    };

    res.writeHead(req.headers.range ? 206 : 200, headers);
    if (req.method === 'HEAD') { res.end(); return; }

    const stream = createReadStream(filePath, range);
    stream.on('error', () => res.destroy());
    res.on('close', () => stream.destroy());
    stream.pipe(res);
    return;
  }

  // Regular Static File
  res.writeHead(200, {
    'Content-Type': contentType,
    'Content-Length': size,
    'Cache-Control': 'no-cache'
  });

  if (req.method === 'HEAD') { res.end(); return; }

  const stream = createReadStream(filePath);
  stream.on('error', () => res.destroy());
  res.on('close', () => stream.destroy());
  stream.pipe(res);
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`[ZYKL Studio Server] Listening on http://127.0.0.1:${PORT}`);
});
