'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { createServer } = require('../src/server');

async function withServer(fn) {
  const server = createServer();
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const { port } = server.address();
  try {
    await fn(`http://127.0.0.1:${port}`);
  } finally {
    await new Promise((resolve, reject) => server.close((err) => err ? reject(err) : resolve()));
  }
}

test('GET /health retourne 200 et status ok', async () => {
  await withServer(async (baseUrl) => {
    const response = await fetch(`${baseUrl}/health`);
    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), { status: 'ok' });
    assert.equal(response.headers.get('x-content-type-options'), 'nosniff');
  });
});

test('GET /api/info retourne les informations du service', async () => {
  await withServer(async (baseUrl) => {
    const response = await fetch(`${baseUrl}/api/info`);
    assert.equal(response.status, 200);
    const body = await response.json();
    assert.equal(body.name, 'app-matt');
    assert.equal(body.version, '1.0.0');
  });
});

test('une route inconnue retourne 404', async () => {
  await withServer(async (baseUrl) => {
    const response = await fetch(`${baseUrl}/missing`);
    assert.equal(response.status, 404);
    assert.deepEqual(await response.json(), { error: 'Not Found' });
  });
});
