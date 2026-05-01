const BACKEND_URL = process.env['BACKEND_URL'];

module.exports = {
  '/api': {
    target: BACKEND_URL,
    secure: false,
    changeOrigin: true,
    logLevel: 'debug'
  }
};
