const app = require('./app');

const port = Number(process.env.SERVER_PORT || 3000);
app.listen(port, () => {
  console.log(`API server: http://localhost:${port}`);
});
