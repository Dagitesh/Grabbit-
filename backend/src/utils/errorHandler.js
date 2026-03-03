function errorHandler(err, req, res, next) {
  const statusCode = err.statusCode || 500;
  let message = err.message || 'Internal server error';
  if (err.errors && Array.isArray(err.errors) && err.errors.length > 0) {
    const first = err.errors[0];
    const msg = first.msg || first.message;
    if (msg) message = msg;
  }

  // Always log 500s so you can see the real error in the terminal
  if (statusCode === 500) {
    const method = req?.method ?? '?';
    const url = req?.originalUrl ?? req?.url ?? '?';
    console.error(`[500] ${method} ${url}`);
    console.error('[500]', err.message);
    console.error(err.stack);
  }

  const response = {
    success: false,
    message,
  };

  if (err.errors && Array.isArray(err.errors)) {
    response.errors = err.errors;
  }

  if (process.env.NODE_ENV === 'development' && statusCode === 500) {
    response.stack = err.stack;
  }

  res.status(statusCode).json(response);
}

module.exports = errorHandler;
