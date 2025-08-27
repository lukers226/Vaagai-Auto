const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose'); // Added this import
const connectDB = require('./config/database');
const authRoutes = require('./routes/auth');
const adminRoutes = require('./routes/admin');
const rideRoutes = require('./routes/rides'); // NEW: Add ride routes
require('dotenv').config();

const app = express();

// Connect to MongoDB
connectDB();

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/drivers', rideRoutes); // NEW: Add ride management routes
app.use('/api/rides', rideRoutes);


// Default route
app.get('/', (req, res) => {
  res.json({ message: 'Auto Meter API is running!' });
});

// Health check route
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    database: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected'
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});
