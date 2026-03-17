require('dotenv').config();
const path = require('path');
const fs = require('fs');
const express = require('express');
const cors = require('cors');
const multer = require('multer');
const { sequelize } = require('./config/database');

const uploadsDir = path.join(__dirname, '..', 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}
const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadsDir),
  filename: (_req, file, cb) => cb(null, `${Date.now()}-${Math.random().toString(36).slice(2)}${path.extname(file.originalname) || '.jpg'}`),
});
const upload = multer({ storage, limits: { fileSize: 5 * 1024 * 1024 } });
require('./modules/user/user.model');
require('./modules/vendor/vendorProfile.model');
require('./modules/customer/customerProfile.model');
require('./modules/location/location.model');
require('./modules/category/category.model');
require('./modules/deal/deal.model');
require('./modules/order/order.model');
require('./modules/payment/payment.model');
require('./modules/review/review.model');
require('./modules/appConfig/appConfig.model');
require('./config/associations');
const authRoutes = require('./modules/auth/auth.routes');
const userRoutes = require('./modules/user/user.routes');
const vendorRoutes = require('./modules/vendor/vendor.routes');
const dealRoutes = require('./modules/deal/deal.routes');
const orderRoutes = require('./modules/order/order.routes');
const adminRoutes = require('./modules/admin/admin.routes');
const errorHandler = require('./utils/errorHandler');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Log requests in development to see which endpoint returns 500
if (process.env.NODE_ENV !== 'production') {
  app.use((req, res, next) => {
    const start = Date.now();
    res.on('finish', () => {
      const status = res.statusCode;
      const msg = `${req.method} ${req.originalUrl} ${status} ${Date.now() - start}ms`;
      if (status >= 500) console.error(msg);
      else console.log(msg);
    });
    next();
  });
}

app.use('/uploads', express.static(uploadsDir));
app.use('/api/auth', authRoutes);
app.use('/api', userRoutes);
app.use('/api/vendor', vendorRoutes);
app.use('/api', dealRoutes);
app.use('/api', orderRoutes);
app.use('/api/admin', adminRoutes);

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.post('/api/upload', upload.single('file'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ success: false, message: 'No file uploaded' });
  }
  const baseUrl = process.env.BASE_URL || `http://localhost:${process.env.PORT || 3000}`;
  const url = `${baseUrl}/uploads/${req.file.filename}`;
  res.json({ success: true, url });
});

// 404 for any other /api route so missing endpoints return JSON, not hang
app.use('/api', (req, res, next) => {
  res.status(404).json({ success: false, message: 'Not found', path: req.originalUrl });
});

app.use(errorHandler);

async function start() {
  try {
    await sequelize.authenticate();
    // Safer default for hosted environments: don't mutate schema unless explicitly enabled.
    const syncOpts = process.env.DB_SYNC_ALTER === 'true' ? { alter: true } : {};
    await sequelize.sync(syncOpts);
    console.log('Database connected and synced.');
    app.listen(PORT, () => {
      console.log(`Server running on http://localhost:${PORT}`);
    });
  } catch (err) {
    console.error('Unable to start server:', err);
    process.exit(1);
  }
}

start();
