const express = require('express');
const mongoose = require('mongoose');
const router = express.Router();
const Fare = require('../models/fareModel');

// Debug middleware
router.use((req, res, next) => {
  console.log(`${req.method} ${req.path}`, req.body);
  next();
});

// @route   POST /api/fares/add-perkm-field
// @desc    One-time update to add perKmRate field to existing system fare
// @access  Public (remove after use)
router.post('/add-perkm-field', async (req, res) => {
  try {
    console.log('🚀 Adding perKmRate field to existing system fare...');
    
    // Find the existing system fare
    const existingFare = await Fare.findOne({ isSystemDefault: true, isActive: true });
    
    if (!existingFare) {
      return res.status(404).json({
        success: false,
        message: 'No existing system fare found'
      });
    }

    // Check if perKmRate already exists
    if (existingFare.perKmRate !== undefined) {
      return res.status(200).json({
        success: true,
        message: 'perKmRate field already exists',
        data: existingFare
      });
    }

    // Add the perKmRate field with a default value
    const defaultPerKmRate = 10; // Set your desired default rate
    existingFare.perKmRate = defaultPerKmRate;
    
    const updatedFare = await existingFare.save();
    
    console.log('✅ Successfully added perKmRate field to existing document');

    return res.status(200).json({
      success: true,
      message: 'perKmRate field added successfully to existing system fare',
      data: updatedFare
    });

  } catch (error) {
    console.error('❌ Error adding perKmRate field:', error);
    return res.status(500).json({
      success: false,
      message: 'Error adding perKmRate field',
      error: error.message
    });
  }
});

// @route   POST /api/fares
// @desc    Create or update system-wide fare (Admin only)
// @access  Public
router.post('/', async (req, res) => {
  console.log('POST /api/fares called with body:', req.body);
  
  try {
    const {
      baseFare,
      perKmRate,
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

    if (!perKmRate || perKmRate <= 0) {
      console.log('Validation failed: Invalid perKmRate');
      return res.status(400).json({
        success: false,
        message: 'Per kilometer rate is required and must be greater than 0'
      });
    }

    if (perKmRate > 1000) {
      console.log('Validation failed: perKmRate too high');
      return res.status(400).json({
        success: false,
        message: 'Per kilometer rate cannot exceed ₹1000'
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
      fare.perKmRate = Number(perKmRate);
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
        perKmRate: Number(perKmRate),
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
      console.log('System fare successfully:', savedFare._id);

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
// @desc    Get current system fare with automatic field addition
// @access  Public
router.get('/', async (req, res) => {
  console.log('GET /api/fares called');
  
  try {
    let fare = await Fare.findOne({ isSystemDefault: true, isActive: true });
    console.log('System fare found:', fare ? 'Yes' : 'No');

    if (!fare) {
      return res.status(404).json({
        success: false,
        message: 'No system fare configuration found'
      });
    }

    // Auto-add perKmRate field if missing (backward compatibility)
    let wasUpdated = false;
    if (fare.perKmRate === undefined || fare.perKmRate === null) {
      console.log('⚠️ perKmRate field missing, adding default value...');
      fare.perKmRate = 10; // Default value
      await fare.save();
      wasUpdated = true;
      console.log('✅ Added perKmRate field with default value');
    }

    return res.status(200).json({
      success: true,
      message: wasUpdated ? 
        'System fare retrieved and updated with missing field' : 
        'System fare retrieved successfully',
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

// @route   POST /api/fares/calculate
// @desc    Calculate fare based on distance and waiting time
// @access  Public
router.post('/calculate', async (req, res) => {
  console.log('POST /api/fares/calculate called with body:', req.body);
  
  try {
    const { distance, waitingMinutes = 0 } = req.body;

    if (!distance || distance <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Distance is required and must be greater than 0'
      });
    }

    // Get current system fare
    let fare = await Fare.findOne({ isSystemDefault: true, isActive: true });
    
    if (!fare) {
      return res.status(404).json({
        success: false,
        message: 'No system fare configuration found'
      });
    }

    // Ensure perKmRate exists (backward compatibility)
    if (!fare.perKmRate) {
      fare.perKmRate = 10; // Default value
      await fare.save();
      console.log('✅ Added missing perKmRate field during calculation');
    }

    // Calculate fare components
    const baseFare = fare.baseFare;
    const distanceFare = Number(distance) * fare.perKmRate;
    
    // Calculate waiting charges
    let waitingCharge = 0;
    if (waitingMinutes >= 30) {
      waitingCharge = fare.waiting30min;
    } else if (waitingMinutes >= 25) {
      waitingCharge = fare.waiting25min;
    } else if (waitingMinutes >= 20) {
      waitingCharge = fare.waiting20min;
    } else if (waitingMinutes >= 15) {
      waitingCharge = fare.waiting15min;
    } else if (waitingMinutes >= 10) {
      waitingCharge = fare.waiting10min;
    } else if (waitingMinutes >= 5) {
      waitingCharge = fare.waiting5min;
    }

    const totalFare = baseFare + distanceFare + waitingCharge;

    const calculationDetails = {
      baseFare: baseFare,
      distance: Number(distance),
      perKmRate: fare.perKmRate,
      distanceFare: Number(distanceFare.toFixed(2)),
      waitingMinutes: Number(waitingMinutes),
      waitingCharge: waitingCharge,
      totalFare: Number(totalFare.toFixed(2)),
      breakdown: {
        baseFare: `₹${baseFare}`,
        distanceFare: `₹${distanceFare.toFixed(2)} (${distance}km × ₹${fare.perKmRate}/km)`,
        waitingCharge: `₹${waitingCharge} (${waitingMinutes} minutes)`,
        total: `₹${totalFare.toFixed(2)}`
      }
    };

    console.log('Fare calculated successfully:', calculationDetails);

    return res.status(200).json({
      success: true,
      message: 'Fare calculated successfully',
      data: calculationDetails
    });

  } catch (error) {
    console.error('Error in POST /api/fares/calculate:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error occurred while calculating fare',
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
    const fareDoc = await Fare.findOne({ isSystemDefault: true, isActive: true });
    
    console.log('Total fare documents:', count);
    console.log('System fare document:', fareDoc);
    
    res.json({
      success: true,
      dbStatus: dbStatus === 1 ? 'connected' : 'disconnected',
      collectionExists: !!fareCollection,
      documentCount: count,
      systemFare: fareDoc,
      hasPerKmRate: fareDoc ? (fareDoc.perKmRate !== undefined) : false,
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
