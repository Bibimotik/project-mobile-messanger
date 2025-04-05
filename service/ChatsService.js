'use strict';

const db = require("../db/db");
const { v4: uuidv4 } = require('uuid');

function isValidUUID(uuid) {
  if (typeof uuid !== 'string') {
    console.log('Invalid UUID type:', typeof uuid);
    return false;
  }

  const regex = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  const isValid = regex.test(uuid);

  if (!isValid) {
    console.log('UUID validation failed for:', uuid);
  }

  return isValid;
}

async function initDB() {
  try {
    await db.query(`
      CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
      
      CREATE TABLE IF NOT EXISTS chats (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        name VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS chat_participants (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        chat_id UUID REFERENCES chats(id) ON DELETE CASCADE,
        user_id UUID NOT NULL,
        joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(chat_id, user_id)
      );

      CREATE TABLE IF NOT EXISTS messages (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        chat_id UUID REFERENCES chats(id) ON DELETE CASCADE,
        user_id UUID NOT NULL,
        content TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log('Chats database initialized');
  } catch (err) {
    console.error('Database initialization error:', err);
  }
}

initDB();

exports.createChat = function(body) {
  return new Promise(async function(resolve, reject) {
    try {
      const { name, userId } = body;

      if (!name || !userId) {
        reject({ status: 400, message: 'Name and userId are required' });
        return;
      }

      const chatId = uuidv4();

      await db.query('BEGIN');

      await db.query(
          'INSERT INTO chats (id, name) VALUES ($1, $2)',
          [chatId, name]
      );

      await db.query(
          'INSERT INTO chat_participants (chat_id, user_id) VALUES ($1, $2)',
          [chatId, userId]
      );

      await db.query('COMMIT');

      resolve({
        status: 201,
        message: 'Chat created successfully',
        chatId: chatId
      });
    } catch (err) {
      await db.query('ROLLBACK');
      reject({ status: 500, message: err.message });
    }
  });
};

exports.addParticipant = function(body, chatId) {
  return new Promise(async function(resolve, reject) {
    try {
      const { userId } = body;

      if (!isValidUUID(chatId)) {
        reject({ status: 400, message: 'Invalid chat ID format' });
        return;
      }

      const chatExists = await db.query(
          'SELECT id FROM chats WHERE id = $1',
          [chatId]
      );

      if (chatExists.rows.length === 0) {
        reject({ status: 404, message: 'Chat not found' });
        return;
      }

      const alreadyParticipant = await db.query(
          'SELECT id FROM chat_participants WHERE chat_id = $1 AND user_id = $2',
          [chatId, userId]
      );

      if (alreadyParticipant.rows.length > 0) {
        reject({ status: 400, message: 'User is already a participant' });
        return;
      }

      await db.query(
          'INSERT INTO chat_participants (chat_id, user_id) VALUES ($1, $2)',
          [chatId, userId]
      );

      resolve({ status: 200, message: 'Participant added successfully' });
    } catch (err) {
      reject({ status: 500, message: err.message });
    }
  });
}

exports.chatsGET = function(limit) {
  return new Promise(async function(resolve, reject) {
    try {
      const result = await db.query(
          `SELECT c.id, c.name, c.created_at, 
         (SELECT content FROM messages WHERE chat_id = c.id ORDER BY created_at DESC LIMIT 1) as last_message
         FROM chats c
         ORDER BY c.created_at DESC
         LIMIT $1`,
          [limit || 10]
      );

      const chats = result.rows.map(chat => ({
        id: chat.id,
        name: chat.name,
        lastMessage: chat.last_message || '',
        createdAt: chat.created_at
      }));

      resolve(chats);
    } catch (err) {
      reject({ status: 500, message: err.message });
    }
  });
}

exports.removeParticipant = function(chatId, userId) {
  return new Promise(async function(resolve, reject) {
    try {
      const participantExists = await db.query(
          'SELECT id FROM chat_participants WHERE chat_id = $1 AND user_id = $2',
          [chatId, userId]
      );

      if (participantExists.rows.length === 0) {
        reject({ status: 404, message: 'Participant not found in this chat' });
        return;
      }

      await db.query(
          'DELETE FROM chat_participants WHERE chat_id = $1 AND user_id = $2',
          [chatId, userId]
      );

      resolve({ status: 200, message: 'Participant removed successfully' });
    } catch (err) {
      reject({ status: 500, message: err.message });
    }
  });
}

exports.getUserChats = function(userId, limit) {
  return new Promise(async function(resolve, reject) {
    try {
      if (!isValidUUID(userId)) {
        reject({ status: 400, message: 'Invalid user ID format' });
        return;
      }

      const result = await db.query(
          `SELECT c.id, c.name, c.created_at,
                  (SELECT content FROM messages WHERE chat_id = c.id ORDER BY created_at DESC LIMIT 1) as last_message
                 FROM chats c
                   JOIN chat_participants cp ON c.id = cp.chat_id
                 WHERE cp.user_id = $1
                 ORDER BY c.created_at DESC
             LIMIT $2`,
          [userId, limit || 10]
      );

      const chats = result.rows.map(chat => ({
        id: chat.id,
        name: chat.name,
        lastMessage: chat.last_message || '',
        createdAt: chat.created_at
      }));

      resolve(chats);
    } catch (err) {
      console.error('Database error:', err);
      reject({
        status: 500,
        message: 'Database operation failed',
        detail: err.message
      });
    }
  });
}