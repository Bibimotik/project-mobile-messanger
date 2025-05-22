'use strict';

var path = require('path');
var http = require('http');
var oas3Tools = require('oas3-tools');
var serverPort = 8080;

var options = {
    routing: {
        controllers: path.join(__dirname, './controllers')
    },
    securityHandlers: {
        bearerAuth: function(req, scopes, definition) {
            const authHeader = req.headers.authorization;
            if (!authHeader) return false;
            const token = authHeader.split(' ')[1];
            if (!token) return false;
            try {
                const payload = require('jsonwebtoken').verify(token, process.env.JWT_SECRET);
                req.user = { id: payload.id || payload.userId, username: payload.username };
                return true;
            } catch (e) {
                return false;
            }
        }
    }
};

var expressAppConfig = oas3Tools.expressAppConfig(path.join(__dirname, 'api/openapi.yaml'), options);
var app = expressAppConfig.getApp();

http.createServer(app).listen(serverPort, function () {
    console.log('Your server is listening on port %d (http://localhost:%d)', serverPort, serverPort);
    console.log('Swagger-ui is available on http://localhost:%d/docs', serverPort);
});