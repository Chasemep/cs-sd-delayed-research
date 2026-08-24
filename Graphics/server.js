const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || 3000;
const GRAPHICS_DIR = __dirname;
const OUTPUT_DIR = path.join(__dirname, '..', 'output');

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.csv': 'text/csv; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.ico': 'image/x-icon',
  '.svg': 'image/svg+xml'
};

function scanOutputDirectory(dirPath, relativePath = '') {
  let items = [];
  try {
    const entries = fs.readdirSync(dirPath, { withFileTypes: true });
    
    // Check if current directory contains CSV files
    const csvFiles = entries
      .filter(e => e.isFile() && e.name.startsWith('agent_positions_') && e.name.endsWith('.csv'))
      .map(e => e.name);

    let hasJson = entries.some(e => e.isFile() && e.name === 'convergence_info.json');

    // Recursively check subdirectories
    let subFolders = [];
    for (const entry of entries) {
      if (entry.isDirectory()) {
        const subRelPath = relativePath ? `${relativePath}/${entry.name}` : entry.name;
        const subAbsPath = path.join(dirPath, entry.name);
        const subResult = scanOutputDirectory(subAbsPath, subRelPath);
        if (subResult.hasScenarios || subResult.csvFiles.length > 0) {
          subFolders.push(subResult);
        }
      }
    }

    return {
      name: path.basename(dirPath),
      relativePath: relativePath,
      isScenario: csvFiles.length > 0,
      csvFiles: csvFiles,
      hasConvergenceInfo: hasJson,
      hasScenarios: csvFiles.length > 0 || subFolders.length > 0,
      children: subFolders
    };
  } catch (err) {
    console.error(`Error scanning ${dirPath}:`, err);
    return { name: path.basename(dirPath), relativePath, isScenario: false, csvFiles: [], children: [] };
  }
}

const server = http.createServer((req, res) => {
  const parsedUrl = new URL(req.url, `http://${req.headers.host}`);
  const pathname = parsedUrl.pathname;

  // CORS Headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // API Endpoint: /api/scenarios
  if (pathname === '/api/scenarios') {
    const tree = scanOutputDirectory(OUTPUT_DIR);
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(tree));
    return;
  }

  // API Endpoint: /api/file?path=...
  if (pathname === '/api/file') {
    const relPath = parsedUrl.searchParams.get('path');
    if (!relPath) {
      res.writeHead(400, { 'Content-Type': 'text/plain' });
      res.end('Missing path parameter');
      return;
    }

    const safePath = path.normalize(relPath).replace(/^(\.\.[\/\\])+/, '');
    const fullFilePath = path.join(OUTPUT_DIR, safePath);

    if (!fullFilePath.startsWith(OUTPUT_DIR)) {
      res.writeHead(403, { 'Content-Type': 'text/plain' });
      res.end('Access denied');
      return;
    }

    fs.stat(fullFilePath, (err, stats) => {
      if (err || !stats.isFile()) {
        res.writeHead(404, { 'Content-Type': 'text/plain' });
        res.end('File not found');
        return;
      }

      const ext = path.extname(fullFilePath).toLowerCase();
      const mime = MIME_TYPES[ext] || 'application/octet-stream';
      res.writeHead(200, { 'Content-Type': mime });
      fs.createReadStream(fullFilePath).pipe(res);
    });
    return;
  }

  // Serve static files from Graphics/
  let reqPath = pathname === '/' ? '/index.html' : pathname;
  const safeReqPath = path.normalize(reqPath).replace(/^(\.\.[\/\\])+/, '');
  const filePath = path.join(GRAPHICS_DIR, safeReqPath);

  if (!filePath.startsWith(GRAPHICS_DIR)) {
    res.writeHead(403, { 'Content-Type': 'text/plain' });
    res.end('Forbidden');
    return;
  }

  fs.stat(filePath, (err, stats) => {
    if (err || !stats.isFile()) {
      res.writeHead(404, { 'Content-Type': 'text/html' });
      res.end('<h1>404 Not Found</h1>');
      return;
    }

    const ext = path.extname(filePath).toLowerCase();
    const mime = MIME_TYPES[ext] || 'text/plain';
    res.writeHead(200, { 'Content-Type': mime });
    fs.createReadStream(filePath).pipe(res);
  });
});

server.listen(PORT, () => {
  console.log(`====================================================`);
  console.log(` 🚀 3D Bird Flocking Visualizer Server Running!`);
  console.log(` 🌐 Open in browser: http://localhost:${PORT}`);
  console.log(`====================================================`);
});
