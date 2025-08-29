const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const connectDB = require('./config/database');
const authRoutes = require('./routes/auth');
const adminRoutes = require('./routes/admin');
const rideRoutes = require('./routes/rides');
const fareRoutes = require('./routes/fare');
require('dotenv').config();

const app = express();

// Connect to MongoDB
connectDB();

// Middleware
app.use(cors({
  origin: ['http://localhost:3000', 'https://vaagai-auto.onrender.com'],
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.originalUrl}`);
  if (req.body && Object.keys(req.body).length > 0) {
    console.log('Request body:', JSON.stringify(req.body, null, 2));
  }
  next();
});

// Routes - NO trailing slashes to match Flutter requests
app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/drivers', rideRoutes);
app.use('/api/rides', rideRoutes);
app.use('/api/fares', fareRoutes);

// Default route
app.get('/', (req, res) => {
  res.json({ 
    message: 'Auto Meter API is running!',
    timestamp: new Date().toISOString(),
    endpoints: [
      'GET  /api/auth/admin - Get admin profile',
      'PUT  /api/auth/admin - Update admin profile',
      'POST /api/auth/login - Login',
      '/api/admin', 
      '/api/drivers',
      '/api/rides',
      '/api/fares'
    ]
  });
});

// Health check route
app.get('/health', async (req, res) => {
  try {
    const dbStatus = mongoose.connection.readyState;
    const collections = await mongoose.connection.db?.listCollections().toArray() || [];
    
    res.status(200).json({ 
      status: 'OK', 
      timestamp: new Date().toISOString(),
      database: dbStatus === 1 ? 'connected' : 'disconnected',
      collections: collections.map(col => col.name),
      environment: process.env.NODE_ENV || 'development'
    });
  } catch (error) {
    res.status(500).json({
      status: 'ERROR',
      timestamp: new Date().toISOString(),
      error: error.message
    });
  }
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Unhandled error:', error);
  res.status(500).json({
    success: false,
    message: 'Internal server error',
    error: process.env.NODE_ENV === 'development' ? error.message : 'Something went wrong'
  });
});

// 404 handler
app.use('*', (req, res) => {
  console.log(`404 - Route not found: ${req.method} ${req.originalUrl}`);
  res.status(404).json({
    success: false,
    message: `Route ${req.originalUrl} not found`
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log('Available routes:');
  console.log('  GET  /api/auth/admin');
  console.log('  PUT  /api/auth/admin');
  console.log('  POST /api/auth/login');
});
