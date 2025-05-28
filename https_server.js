const https = require('https');
const fs = require('fs');
const path = require('path');

const port = 8443;

const certPath = path.join(__dirname, 'certs/server.crt');
const keyPath = path.join(__dirname, 'certs/personal.key');

if (!fs.existsSync(certPath)) {
    console.error(`Error: Certificate file not found at ${certPath}`);
    process.exit(1);
}

if (!fs.existsSync(keyPath)) {
    console.error(`Error: Private key file not found at ${keyPath}`);
    process.exit(1);
}

const options = {
    key: fs.readFileSync(keyPath),
    cert: fs.readFileSync(certPath)
};

const server = https.createServer(options, (req, res) => {
    res.writeHead(200, {'Content-Type': 'text/plain'});
    res.end('Hello from HTTPS Server with generated certs!');
});

server.listen(port, () => {
    console.log(`HTTPS server listening on port ${port}`);
    console.log(`Open your browser to https://localhost:${port}/`);
});

server.on('error', (err) => {
    console.error('Server error:', err);
}); 