const https = require('https');
const fs = require('fs');
const path = require('path');

// Define the server address and port
const port = 8443; // Standard HTTPS alternative port

// Define the path to the certificate and key files
const certPath = path.join(__dirname, 'certs/server.crt');
const keyPath = path.join(__dirname, 'certs/personal.key'); // Используем personal.key для сервера

// Check if certificate and key files exist
if (!fs.existsSync(certPath)) {
    console.error(`Error: Certificate file not found at ${certPath}`);
    process.exit(1);
}

if (!fs.existsSync(keyPath)) {
    console.error(`Error: Private key file not found at ${keyPath}`);
    process.exit(1);
}

// Read certificate and key files
const options = {
    key: fs.readFileSync(keyPath),
    cert: fs.readFileSync(certPath)
};

// Create an HTTPS server
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