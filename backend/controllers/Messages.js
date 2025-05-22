'use strict';

var utils = require('../utils/writer.js');
var Messages = require('../service/MessagesService');

const jwt = require('jsonwebtoken');

function getUserIdFromToken(req, res) {
    try {
        const token = req.headers.authorization?.split(' ')[1];
        if (!token) throw new Error('No token');
        const user = jwt.verify(token, process.env.JWT_SECRET);
        return user.id || user.userId;
    } catch (e) {
        utils.writeJson(res, { message: 'User is not authenticated or token is invalid', error: e.message, headers: req.headers }, 401);
        return null;
    }
}

module.exports.deleteMessage = function deleteMessage(req, res, next, chatId, messageId) {
    const userId = getUserIdFromToken(req, res);
    if (!userId) return;
    Messages.deleteMessage(chatId, messageId, userId)
        .then(function(response) {
            utils.writeJson(res, response);
        })
        .catch(function(response) {
            utils.writeJson(res, response);
        });
};

module.exports.editMessage = function editMessage(req, res, next, body, chatId, messageId) {
    const userId = getUserIdFromToken(req, res);
    if (!userId) return;
    Messages.editMessage(chatId, messageId, userId, body.content)
        .then(function(response) {
            utils.writeJson(res, response);
        })
        .catch(function(response) {
            utils.writeJson(res, response);
        });
};

module.exports.getMessages = function getMessages(req, res, next, chatId) {
    const userId = getUserIdFromToken(req, res);
    if (!userId) return;
    Messages.getMessages(chatId, userId)
        .then(function(response) {
            utils.writeJson(res, response);
        })
        .catch(function(response) {
            utils.writeJson(res, response);
        });
};

module.exports.sendMessage = function sendMessage(req, res, next, body, chatId) {
    const userId = getUserIdFromToken(req, res);
    if (!userId) return;
    Messages.sendMessage(body, chatId, userId)
        .then(function(response) {
            utils.writeJson(res, response);
        })
        .catch(function(response) {
            utils.writeJson(res, response);
        });
};