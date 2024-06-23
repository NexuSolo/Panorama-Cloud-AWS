const express = require('express');
const app = express();
const { Pool } = require('pg');

app.get('/', (req, res) => {
  res.send('Hello World!');
});

app.listen(6263, () => {
  console.log('Server started on port 3000');
});

const pool = new Pool({
  user: 'user',
  host: 'db',
  database: 'db',
  password: 'password',
  port: 5432,
});

app.get('/test', (req, res) => {
  pool.query('SELECT * FROM user', (err, result) => {
    if (err) {
      console.error(err);
      res.status(500).json({error: 'An error occurred while fetching users'});
    } else {
      res.json(result.rows);
    }
  });
});