'use strict';

const db = require("../db/db");
const { v4: uuidv4 } = require('uuid');

function isValidUUID(uuid) {
  const regex = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  return regex.test(uuid);
}

exports.sendMessage = function(body, chatId, userId) {
  return new Promise(async function(resolve, reject) {
    try {
      const { content } = body;

      if (!isValidUUID(chatId) || !isValidUUID(userId)) {
        reject({ status: 400, message: 'Invalid ID format' });
        return;
      }

      const isParticipant = await db.query(
          'SELECT id FROM chat_participants WHERE chat_id = $1 AND user_id = $2',
          [chatId, userId]
      );

      if (isParticipant.rows.length === 0) {
        reject({ status: 403, message: 'User is not a participant of this chat' });
        return;
      }

      if (!content || content.trim().length === 0) {
        reject({ status: 400, message: 'Message content cannot be empty' });
        return;
      }

      const messageId = uuidv4();

      const result = await db.query(
          `INSERT INTO messages (id, chat_id, user_id, content) 
         VALUES ($1, $2, $3, $4) 
         RETURNING id, chat_id as "chatId", user_id as "senderId", content as text, created_at as timestamp`,
          [messageId, chatId, userId, content]
      );

      resolve({
        status: 201,
        message: 'Message sent successfully',
        data: result.rows[0]
      });
    } catch (err) {
      reject({ status: 500, message: err.message });
    }
  });
};

exports.getMessages = function(chatId, userId) {
  return new Promise(async function(resolve, reject) {
    try {
      if (!isValidUUID(chatId) || !isValidUUID(userId)) {
        reject({ status: 400, message: 'Invalid ID format' });
        return;
      }

      const isParticipant = await db.query(
          'SELECT id FROM chat_participants WHERE chat_id = $1 AND user_id = $2',
          [chatId, userId]
      );

      if (isParticipant.rows.length === 0) {
        reject({ status: 403, message: 'Access denied' });
        return;
      }

      const result = await db.query(
          `SELECT 
          m.id, 
          m.user_id as "senderId", 
          m.chat_id as "chatId", 
          m.content as text, 
          m.created_at as timestamp
         FROM messages m
         WHERE m.chat_id = $1
         ORDER BY m.created_at DESC
         LIMIT 100`,
          [chatId]
      );

      resolve(result.rows);
    } catch (err) {
      reject({ status: 500, message: err.message });
    }
  });
};

exports.deleteMessage = function(chatId, messageId, userId) {
  return new Promise(async function(resolve, reject) {
    try {
      if (!isValidUUID(chatId) || !isValidUUID(messageId) || !isValidUUID(userId)) {
        reject({ status: 400, message: 'Invalid ID format' });
        return;
      }

      const message = await db.query(
          `SELECT user_id FROM messages WHERE id = $1 AND chat_id = $2`,
          [messageId, chatId]
      );

      if (message.rows.length === 0) {
        reject({ status: 404, message: 'Message not found' });
        return;
      }

      if (message.rows[0].user_id !== userId) {
        reject({ status: 403, message: 'You can only delete your own messages' });
        return;
      }

      await db.query(
          'DELETE FROM messages WHERE id = $1',
          [messageId]
      );

      resolve({ status: 200, message: 'Message deleted successfully' });
    } catch (err) {
      reject({ status: 500, message: err.message });
    }
  });
};

exports.editMessage = function(chatId, messageId, userId, newContent) {
  return new Promise(async function(resolve, reject) {
    try {
      if (!isValidUUID(chatId) || !isValidUUID(messageId) || !isValidUUID(userId)) {
        reject({ status: 400, message: 'Invalid ID format' });
        return;
      }

      if (!newContent || newContent.trim().length === 0) {
        reject({ status: 400, message: 'Message content cannot be empty' });
        return;
      }

      const message = await db.query(
          `SELECT user_id FROM messages WHERE id = $1 AND chat_id = $2`,
          [messageId, chatId]
      );

      if (message.rows.length === 0) {
        reject({ status: 404, message: 'Message not found' });
        return;
      }

      if (message.rows[0].user_id !== userId) {
        reject({ status: 403, message: 'You can only edit your own messages' });
        return;
      }

      const result = await db.query(
          `UPDATE messages SET content = $1 
         WHERE id = $2 
         RETURNING id, chat_id as "chatId", user_id as "senderId", content as text, created_at as timestamp`,
          [newContent, messageId]
      );

      resolve({
        status: 200,
        message: 'Message updated successfully',
        data: result.rows[0]
      });
    } catch (err) {
      reject({ status: 500, message: err.message });
    }
  });
};