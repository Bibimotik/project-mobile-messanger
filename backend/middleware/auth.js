const jwt = require('jsonwebtoken');

module.exports = (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader) {
            return res.status(401).json({
                message: 'Authorization header is missing',
                details: 'Expected header: Authorization: Bearer <token>'
            });
        }
        const token = authHeader.split(' ')[1];
        if (!token) {
            return res.status(401).json({
                message: 'Bearer token is missing in Authorization header',
                header: authHeader
            });
        }
        let payload;
        try {
            payload = jwt.verify(token, process.env.JWT_SECRET);
        } catch (err) {
            return res.status(401).json({
                message: 'Invalid token',
                token,
                error: err.message
            });
        }
        console.log('JWT payload:', payload); // Диагностика
        if (!payload.id && !payload.userId) {
            return res.status(401).json({
                message: 'Token payload does not contain id or userId',
                payload
            });
        }
        req.user = { id: payload.id || payload.userId, username: payload.username };
        next();
    } catch (err) {
        return res.status(500).json({ message: 'Unexpected error in auth middleware', error: err.message });
    }
};