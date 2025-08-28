const express = require('express');
const mongoose = require('mongoose'); // IMPORTANT: Added missing import
const router = express.Router();
const Fare = require('../models/fareModel');

// Debug middleware to log all requests
router.use((req, res, next) => {
  console.log(`${req.method} ${req.path}`, req.body);
  next();
});

// Middleware to validate ObjectId
const validateObjectId = (req, res, next) => {
  const { userId } = req.params;
  if (userId && !mongoose.Types.ObjectId.isValid(userId)) {
    return res.status(400).json({
      success: false,
      message: 'Invalid user ID format'
    });
  }
  next();
};

// @route   POST /api/fares
// @desc    Create or update fare for a user
// @access  Public
router.post('/', async (req, res) => {
  console.log('POST /api/fares called with body:', req.body);
  
  try {
    const {
      userId,
      baseFare,
      waiting5min = 0,
      waiting10min = 0,
      waiting15min = 0,
      waiting20min = 0,
      waiting25min = 0,
      waiting30min = 0
    } = req.body;

    // Enhanced validation
    if (!userId || !baseFare) {
      console.log('Validation failed: Missing userId or baseFare');
      return res.status(400).json({
        success: false,
        message: 'User ID and base fare are required'
      });
    }

    // Validate ObjectId format
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      console.log('Validation failed: Invalid userId format');
      return res.status(400).json({
        success: false,
        message: 'Invalid user ID format'
      });
    }

    // Validate baseFare is a positive number
    if (isNaN(baseFare) || baseFare <= 0) {
      console.log('Validation failed: Invalid baseFare value');
      return res.status(400).json({
        success: false,
        message: 'Base fare must be a positive number'
      });
    }

    console.log('Looking for existing fare for userId:', userId);
    
    // Check if fare already exists for this user
    let fare = await Fare.findOne({ userId: new mongoose.Types.ObjectId(userId) });
    console.log('Existing fare found:', fare ? 'Yes' : 'No');

    if (fare) {
      // Update existing fare
      console.log('Updating existing fare');
      
      fare.baseFare = Number(baseFare);
      fare.waiting5min = Number(waiting5min);
      fare.waiting10min = Number(waiting10min);
      fare.waiting15min = Number(waiting15min);
      fare.waiting20min = Number(waiting20min);
      fare.waiting25min = Number(waiting25min);
      fare.waiting30min = Number(waiting30min);

      const savedFare = await fare.save();
      console.log('Fare updated successfully:', savedFare._id);

      return res.status(200).json({
        success: true,
        message: 'Fare updated successfully',
        data: savedFare
      });
    } else {
      // Create new fare
      console.log('Creating new fare');
      
      const newFareData = {
        userId: new mongoose.Types.ObjectId(userId),
        baseFare: Number(baseFare),
        waiting5min: Number(waiting5min),
        waiting10min: Number(waiting10min),
        waiting15min: Number(waiting15min),
        waiting20min: Number(waiting20min),
        waiting25min: Number(waiting25min),
        waiting30min: Number(waiting30min)
      };

      console.log('New fare data:', newFareData);

      fare = new Fare(newFareData);
      const savedFare = await fare.save();
      console.log('Fare created successfully:', savedFare._id);

      return res.status(201).json({
        success: true,
        message: 'Fare created successfully',
        data: savedFare
      });
    }
  } catch (error) {
    console.error('Error in POST /api/fares:', error);
    
    // Handle mongoose validation errors
    if (error.name === 'ValidationError') {
      const validationErrors = Object.values(error.errors).map(err => err.message);
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors: validationErrors
      });
    }

    // Handle duplicate key error
    if (error.code === 11000) {
      return res.status(409).json({
        success: false,
        message: 'Fare already exists for this user'
      });
    }

    return res.status(500).json({
      success: false,
      message: 'Server error occurred while processing fare',
      error: error.message
    });
  }
});

// @route   GET /api/fares/:userId
// @desc    Get fare by user ID
// @access  Public
router.get('/:userId', validateObjectId, async (req, res) => {
  console.log('GET /api/fares/:userId called with userId:', req.params.userId);
  
  try {
    const { userId } = req.params;

    const fare = await Fare.findOne({ userId: new mongoose.Types.ObjectId(userId) });
    console.log('Fare found:', fare ? 'Yes' : 'No');

    if (!fare) {
      return res.status(404).json({
        success: false,
        message: 'Fare not found for this user'
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Fare retrieved successfully',
      data: fare
    });
  } catch (error) {
    console.error('Error in GET /api/fares/:userId:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error occurred while fetching fare',
      error: error.message
    });
  }
});

// @route   GET /api/fares
// @desc    Get all fares
// @access  Public
router.get('/', async (req, res) => {
  console.log('GET /api/fares called');
  
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const fares = await Fare.find({ isActive: true })
      .sort({ updatedAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await Fare.countDocuments({ isActive: true });
    const totalPages = Math.ceil(total / limit);

    console.log(`Found ${fares.length} fares out of ${total} total`);

    return res.status(200).json({
      success: true,
      message: 'Fares retrieved successfully',
      data: fares,
      pagination: {
        currentPage: page,
        totalPages,
        totalFares: total,
        hasNextPage: page < totalPages,
        hasPrevPage: page > 1
      }
    });
  } catch (error) {
    console.error('Error in GET /api/fares:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error occurred while fetching fares',
      error: error.message
    });
  }
});

// Debug route to test connection and collection
router.get('/debug/test', async (req, res) => {
  try {
    console.log('Testing database connection...');
    
    // Test database connection
    const dbStatus = mongoose.connection.readyState;
    console.log('Database connection status:', dbStatus);
    
    // Test collection exists
    const collections = await mongoose.connection.db.listCollections().toArray();
    const fareCollection = collections.find(col => col.name === 'fares');
    console.log('Fares collection exists:', fareCollection ? 'Yes' : 'No');
    
    // Test document count
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
