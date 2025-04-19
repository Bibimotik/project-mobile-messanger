'use strict';

const db = require('../db/db');
const { sign } = require("jsonwebtoken");
const { v4: uuidv4 } = require('uuid');
const jwtSecret = process.env.JWT_SECRET;

async function initDB() {
  try {
    await db.query(`
      CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
      
      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        username VARCHAR(50) UNIQUE NOT NULL,
        password VARCHAR(100) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log('Users database initialized');
  } catch (err) {
    console.error('Database initialization error:', err);
  }
}

initDB();

exports.registerUser = async function(body) {
  const { username, password } = body;

  if (!username || !password) {
    throw { status: 400, message: 'Username and password are required' };
  }

  try {
    // Используем хешированный пароль напрямую, так как он уже хеширован на клиенте
    const userId = uuidv4();

    const result = await db.query(
        'INSERT INTO users (id, username, password) VALUES ($1, $2, $3) RETURNING id, username',
        [userId, username, password]
    );

    // Генерируем JWT токен
    const token = sign(
        {
          userId: result.rows[0].id,
          username: result.rows[0].username
        },
        jwtSecret,
        { expiresIn: '24h' }
    );

    return {
      token,
      user: {
        id: result.rows[0].id,
        username: result.rows[0].username
      }
    };

  } catch (err) {
    if (err.code === '23505') {
      throw { status: 400, message: 'Username already exists' };
    }
    console.error('Registration error:', err);
    throw { status: 500, message: 'Internal server error' };
  }
};

exports.loginUser = async function(body) {
  const { username, password } = body;

  if (!username || !password) {
    throw { status: 400, message: 'Username and password are required' };
  }

  try {
    const userResult = await db.query(
        'SELECT id, username, password FROM users WHERE username = $1',
        [username]
    );

    if (userResult.rows.length === 0) {
      throw { status: 401, message: 'Invalid credentials' };
    }

    const user = userResult.rows[0];

    // Просто сравниваем хеши напрямую, так как они уже в одинаковом формате
    if (password !== user.password) {
      throw { status: 401, message: 'Invalid credentials' };
    }

    const token = sign(
        {
          userId: user.id,
          username: user.username
        },
        jwtSecret,
        { expiresIn: '24h' }
    );

    return {
      token,
      user: {
        id: user.id,
        username: user.username
      }
    };

  } catch (err) {
    console.error('Login error:', err);
    throw {
      status: err.status || 500,
      message: err.message || 'Internal server error'
    };
  }
};

exports.logoutUser = function() {
  return new Promise(function(resolve, reject) {
    resolve();
  });
}