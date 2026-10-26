'use strict';

const http = require('node:http');

const PORT = Number(process.env.PORT || 3000);

function createServer() {
  return http.createServer((req, res) => {
    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('Cache-Control', 'no-store');

    if (req.method === 'GET' && req.url === '/health') {
      res.writeHead(200);
      return res.end(JSON.stringify({ status: 'ok' }));
    }

    if (req.method === 'GET' && req.url === '/api/info') {
      res.writeHead(200);
      return res.end(JSON.stringify({
        name: 'app-matt',
        version: '1.0.0',
        message: 'API opérationnelle',
        environment: process.env.NODE_ENV || 'development'
      }));
    }

    res.writeHead(404);
    return res.end(JSON.stringify({ error: 'Not Found' }));
  });
}

if (require.main === module) {
  const server = createServer();
  server.listen(PORT, '0.0.0.0', () => {
    console.log(`app-matt écoute sur le port ${PORT}`);
  });
}

module.exports = { createServer };
