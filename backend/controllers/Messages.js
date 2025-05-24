'use strict';

var utils = require('../utils/writer.js');
var Messages = require('../service/MessagesService');

const jwt = require('jsonwebtoken');

function getUserIdFromToken(req, res) {
    try {
        const token = req.headers.authorization?.split(' ')[1];
        console.log('Authorization header:', req.headers.authorization);
        console.log('Extracted token:', token);
        
        if (!token) throw new Error('No token');
        const user = jwt.verify(token, process.env.JWT_SECRET);
        console.log('Decoded JWT payload:', user);
        
        const userId = user.id || user.userId;
        console.log('Extracted userId:', userId);
        
        return userId;
    } catch (e) {
        console.error('Token verification error:', e);
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
    console.log('getMessages called with:', { chatId });
    const userId = getUserIdFromToken(req, res);
    console.log('Extracted userId in getMessages:', userId);
    
    if (!userId) return;
    
    Messages.getMessages(chatId, userId)
        .then(function(response) {
            utils.writeJson(res, response);
        })
        .catch(function(response) {
            console.error('Error in getMessages controller:', response);
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