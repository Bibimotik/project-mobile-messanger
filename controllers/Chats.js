'use strict';

var utils = require('../utils/writer.js');
var Chats = require('../service/ChatsService');

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
  Chats.createChat(body)
    .then(function (response) {
      utils.writeJson(res, response);
    })
    .catch(function (response) {
      utils.writeJson(res, response);
    });
};

module.exports.removeParticipant = function removeParticipant (req, res, next, chatId, userId) {
  Chats.removeParticipant(chatId, userId)
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