const express = require('express');
const mongoose = require('mongoose');
const router = express.Router();
const Fare = require('../models/fareModel');

// Debug middleware
router.use((req, res, next) => {
  console.log(`${req.method} ${req.path}`, req.body);
  next();
});

// @route   POST /api/fares
// @desc    Create or update system-wide fare (Admin only)
// @access  Public
router.post('/', async (req, res) => {
  console.log('POST /api/fares called with body:', req.body);
  
  try {
    const {
      baseFare,
      waiting5min = 0,
      waiting10min = 0,
      waiting15min = 0,
      waiting20min = 0,
      waiting25min = 0,
      waiting30min = 0
    } = req.body;

    // Validate required fields
    if (!baseFare || baseFare <= 0) {
      console.log('Validation failed: Invalid baseFare');
      return res.status(400).json({
        success: false,
        message: 'Base fare is required and must be greater than 0'
      });
    }

    console.log('Looking for existing system fare...');
    
    // Check if system fare already exists
    let fare = await Fare.findOne({ isSystemDefault: true, isActive: true });
    console.log('Existing system fare found:', fare ? 'Yes' : 'No');

    const adminId = new mongoose.Types.ObjectId(); // Default admin ID

    if (fare) {
      // Update existing system fare
      console.log('Updating existing system fare');
      
      fare.baseFare = Number(baseFare);
      fare.waiting5min = Number(waiting5min);
      fare.waiting10min = Number(waiting10min);
      fare.waiting15min = Number(waiting15min);
      fare.waiting20min = Number(waiting20min);
      fare.waiting25min = Number(waiting25min);
      fare.waiting30min = Number(waiting30min);

      const savedFare = await fare.save();
      console.log('System fare updated successfully:', savedFare._id);

      return res.status(200).json({
        success: true,
        message: 'System fare updated successfully',
        data: savedFare
      });
    } else {
      // Create new system fare
      console.log('Creating new system fare');
      
      const newFareData = {
        adminId: adminId,
        baseFare: Number(baseFare),
        waiting5min: Number(waiting5min),
        waiting10min: Number(waiting10min),
        waiting15min: Number(waiting15min),
        waiting20min: Number(waiting20min),
        waiting25min: Number(waiting25min),
        waiting30min: Number(waiting30min),
        isSystemDefault: true,
        isActive: true
      };

      console.log('New system fare data:', newFareData);

      fare = new Fare(newFareData);
      const savedFare = await fare.save();
      console.log('System fare created successfully:', savedFare._id);

      return res.status(201).json({
        success: true,
        message: 'System fare created successfully',
        data: savedFare
      });
    }
  } catch (error) {
    console.error('Error in POST /api/fares:', error);
    
    if (error.name === 'ValidationError') {
      const validationErrors = Object.values(error.errors).map(err => err.message);
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors: validationErrors
      });
    }

    return res.status(500).json({
      success: false,
      message: 'Server error occurred while processing fare',
      error: error.message
    });
  }
});

// @route   GET /api/fares
// @desc    Get current system fare
// @access  Public
router.get('/', async (req, res) => {
  console.log('GET /api/fares called');
  
  try {
    const fare = await Fare.findOne({ isSystemDefault: true, isActive: true });
    console.log('System fare found:', fare ? 'Yes' : 'No');

    if (!fare) {
      return res.status(404).json({
        success: false,
        message: 'No system fare configuration found'
      });
    }

    return res.status(200).json({
      success: true,
      message: 'System fare retrieved successfully',
      data: fare
    });
  } catch (error) {
    console.error('Error in GET /api/fares:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error occurred while fetching fare',
      error: error.message
    });
  }
});

// Debug route to test connection and collection
router.get('/debug/test', async (req, res) => {
  try {
    console.log('Testing database connection...');
    
    const dbStatus = mongoose.connection.readyState;
    console.log('Database connection status:', dbStatus);
    
    const collections = await mongoose.connection.db.listCollections().toArray();
    const fareCollection = collections.find(col => col.name === 'fares');
    console.log('Fares collection exists:', fareCollection ? 'Yes' : 'No');
    
    const count = await Fare.countDocuments();
    console.log('Total fare documents:', count);
    
    res.json({
      success: true,
      dbStatus: dbStatus === 1 ? 'connected' : 'disconnected',
      collectionExists: !!fareCollection,
      documentCount: count,
      collections: collections.map(col => col.name)
    });
  } catch (error) {
    console.error('Debug test error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

module.exports = router;
