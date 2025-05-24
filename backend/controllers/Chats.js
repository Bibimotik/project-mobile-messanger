'use strict';

var utils = require('../utils/writer.js');
var Chats = require('../service/ChatsService');

const jwt = require('jsonwebtoken');

function getUserIdFromToken(req, res) {
    try {
        const token = req.headers.authorization?.split(' ')[1];
        if (!token) throw new Error('No token');
        const user = jwt.verify(token, process.env.JWT_SECRET);
        console.log('JWT payload:', user);
        return user.id || user.userId;
    } catch (e) {
        console.error('Token verification error:', e);
        utils.writeJson(res, { message: 'User is not authenticated or token is invalid', error: e.message, headers: req.headers }, 401);
        return null;
    }
}

module.exports.addParticipant = function addParticipant (req, res, next, body, chatId) {
  Chats.addParticipant(body, chatId)
    .then(function (response) {
      utils.writeJson(res, response);
    })
    .catch(function (response) {
      utils.writeJson(res, response);
    });
};

module.exports.chatsGET = function chatsGET (req, res, next, limit) {
  Chats.chatsGET(limit)
    .then(function (response) {
      utils.writeJson(res, response);
    })
    .catch(function (response) {
      utils.writeJson(res, response);
    });
};

module.exports.createChat = function createChat (req, res, next, body) {
  const userId = getUserIdFromToken(req, res);
  if (!userId) return;
  const newBody = { ...body, userId };
  Chats.createChat(newBody)
    .then(function (response) {
      utils.writeJson(res, response);
    })
    .catch(function (response) {
      utils.writeJson(res, response);
    });
};

module.exports.removeParticipant = function removeParticipant (req, res, next, chatId, userId) {
  const currentUserId = getUserIdFromToken(req, res);
  if (!currentUserId) return;

  Chats.removeParticipant(userId, chatId, currentUserId)
    .then(function (response) {
      utils.writeJson(res, response);
    })
    .catch(function (response) {
      utils.writeJson(res, response);
    });
};

module.exports.getUserChats = function(req, res, next, limit, userId) {
    console.log('Controller received - userId:', userId, 'limit:', limit);

    if (!userId) {
        console.error('UserId is missing!');
        return utils.writeJson(res, { status: 400, message: 'User ID is required' });
    }

    Chats.getUserChats(userId, limit)
        .then(function (response) {
            utils.writeJson(res, response);
        })
        .catch(function (response) {
            utils.writeJson(res, response);
        });
};

module.exports.getChatParticipants = function(req, res, next, chatId) {
    Chats.getChatParticipants(chatId)
        .then(function(response) {
            utils.writeJson(res, response);
        })
        .catch(function(response) {
            utils.writeJson(res, response);
        });
};

module.exports.deleteChat = function deleteChat(req, res, next, chatId) {
  const userId = getUserIdFromToken(req, res);
  if (!userId) return;
  Chats.deleteChat(chatId, userId)
    .then(function(response) {
      utils.writeJson(res, response);
    })
    .catch(function(response) {
      utils.writeJson(res, response);
    });
};

module.exports.editChat = function editChat(req, res, next, body, chatId) {
  const userId = getUserIdFromToken(req, res);
  if (!userId) return;
  
  Chats.editChat(chatId, userId, body)
    .then(function(response) {
      utils.writeJson(res, response);
    })
    .catch(function(response) {
      utils.writeJson(res, response);
    });
};