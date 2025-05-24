'use strict';

var utils = require('../utils/writer.js');
var User = require('../service/UserService');

module.exports.loginUser = function loginUser(req, res, next, body) {
    User.loginUser(body)
        .then(function(response) {
            utils.writeJson(res, response);
        })
        .catch(function(error) {
            utils.writeJson(res, { message: error.message }, error.status || 500);
        });
};

module.exports.logoutUser = function logoutUser(req, res, next) {
    User.logoutUser()
        .then(function(response) {
            utils.writeJson(res, response);
        })
        .catch(function(error) {
            utils.writeJson(res, { message: error.message }, error.status || 500);
        });
};

module.exports.registerUser = function registerUser(req, res, next, body) {
    User.registerUser(body)
        .then(function(response) {
            utils.writeJson(res, response, 201);
        })
        .catch(function(error) {
            utils.writeJson(res, { message: error.message }, error.status || 500);
        });
};

module.exports.searchUsers = function searchUsers(req, res, next, name, limit) {
    User.searchUsers(name, limit)
        .then(function(response) {
            utils.writeJson(res, response);
        })
        .catch(function(error) {
            utils.writeJson(res, { message: error.message }, error.status || 500);
        });
};