'use strict';

var utils = require('../utils/writer.js');
var Messages = require('../service/MessagesService');

module.exports.deleteMessage = function deleteMessage(req, res, next, chatId, messageId) {
    const userId = req.user.id;

    Messages.deleteMessage(chatId, messageId, userId)
        .then(function(response) {
            utils.writeJson(res, response);
        })
        .catch(function(response) {
            utils.writeJson(res, response);
        });
};

module.exports.editMessage = function editMessage(req, res, next, body, chatId, messageId) {
    const userId = req.user.id;

    Messages.editMessage(chatId, messageId, userId, body.content)
        .then(function(response) {
            utils.writeJson(res, response);
        })
        .catch(function(response) {
            utils.writeJson(res, response);
        });
};

module.exports.getMessages = function getMessages(req, res, next, chatId) {
    const userId = req.user.id;

    Messages.getMessages(chatId, userId)
        .then(function(response) {
            utils.writeJson(res, response);
        })
        .catch(function(response) {
            utils.writeJson(res, response);
        });
};

module.exports.sendMessage = function sendMessage(req, res, next, body, chatId) {
    const userId = req.user.id;

    Messages.sendMessage(body, chatId, userId)
        .then(function(response) {
            utils.writeJson(res, response);
        })
        .catch(function(response) {
            utils.writeJson(res, response);
        });
};