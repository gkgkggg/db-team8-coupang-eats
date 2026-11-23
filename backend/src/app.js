const express = require('express');
const homeRouter = require('./routes/home');
const { notFound, errorHandler } = require('./errors');

const app = express();
app.use(express.json());

app.use('/api', homeRouter);

app.use((req, res, next) => next(notFound(`${req.method} ${req.path} 경로가 없습니다.`)));
app.use(errorHandler);

module.exports = app;
