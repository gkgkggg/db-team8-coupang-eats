class ApiError extends Error {
  constructor(status, code, message) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

const badRequest = (message) => new ApiError(400, 'BAD_REQUEST', message);
const notFound = (message) => new ApiError(404, 'NOT_FOUND', message);

function parseId(value, name) {
  if (!/^[1-9]\d{0,17}$/.test(String(value))) {
    throw badRequest(`${name}는 1 이상의 정수여야 합니다.`);
  }
  return Number(value);
}

function errorHandler(err, req, res, next) {
  if (err instanceof ApiError) {
    return res.status(err.status).json({ error: { code: err.code, message: err.message } });
  }
  console.error(err);
  res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: '서버 오류가 발생했습니다.' } });
}

module.exports = { ApiError, badRequest, notFound, parseId, errorHandler };
