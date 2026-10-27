'use strict';

const express = require('express');

const app = express();
const PORT = Number(process.env.PORT || 4000);

app.use(express.json());

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'UP' });
});

app.post('/notify', (req, res) => {
  console.log(JSON.stringify({
    level: 'info',
    service: 'notifier',
    message: 'Notification reçue',
    payload: req.body,
    timestamp: new Date().toISOString()
  }));

  res.status(200).json({
    ok: true,
    message: 'Notification reçue'
  });
});

app.listen(PORT, () => {
  console.log(JSON.stringify({
    level: 'info',
    message: 'notifier started',
    port: PORT
  }));
});
