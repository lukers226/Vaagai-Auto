const express = require('express');
const mongoose = require('mongoose');
const router = express.Router();
const Fare = require('../models/fareModel');

// Debug middleware
router.use((req, res, next) => {
  console.log(`${req.method} ${req.path}`, req.body);
  next();
});

// @route   POST /api/fares/migrate
// @desc    ONE-TIME MIGRATION: Add waiting60min field to existing documents
// @access  Public (call once after deployment)
router.post('/migrate', async (req, res) => {
  try {
    console.log('🚀 Starting migration to add waiting60min field...');
    
    // Use raw MongoDB operations to bypass Mongoose schema validation
    const db = mongoose.connection.db;
    const collection = db.collection('fares');

    // Check existing documents
    const totalDocs = await collection.countDocuments();
    const docsWithoutWaiting60min = await collection.countDocuments({
      waiting60min: { $exists: false }
    });

    console.log(`📊 Total documents: ${totalDocs}`);
    console.log(`📊 Documents missing waiting60min field: ${docsWithoutWaiting60min}`);

    if (docsWithoutWaiting60min > 0) {
      // Add waiting60min field and remove old waiting fields
      const result = await collection.updateMany(
        { waiting60min: { $exists: false } },
        { 
          $set: { waiting60min: 60 }, // Default to 60 for existing documents
          $unset: { 
            // Remove old waiting time fields if they exist
            waiting5min: "",
            waiting10min: "",
            waiting15min: "",
            waiting20min: "",
            waiting25min: "",
            waiting30min: ""
          }
        }
      );

      console.log(`✅ Migration completed!`);
      console.log(`   - Matched documents: ${result.matchedCount}`);
      console.log(`   - Modified documents: ${result.modifiedCount}`);

      // Verify migration
      const updatedCount = await collection.countDocuments({
        waiting60min: { $exists: true }
      });

      return res.status(200).json({
        success: true,
        message: 'Migration completed successfully',
        data: {
          totalDocuments: totalDocs,
          documentsUpdated: result.modifiedCount,
          documentsWithWaiting60min: updatedCount,
          migrationDetails: {
            matchedCount: result.matchedCount,
            modifiedCount: result.modifiedCount
          }
        }
      });
    } else {
      console.log('✅ All documents already have waiting60min field');
      
      return res.status(200).json({
        success: true,
        message: 'No migration needed - all documents already have waiting60min field',
        data: {
          totalDocuments: totalDocs,
          documentsWithWaiting60min: totalDocs
        }
      });
    }

  } catch (error) {
    console.error('❌ Migration failed:', error);
    return res.status(500).json({
      success: false,
      message: 'Migration failed',
      error: error.message
    });
  }
});

// @route   POST /api/fares/initialize
// @desc    Initialize fare collection with default system fare
// @access  Public
router.post('/initialize', async (req, res) => {
  try {
    console.log('🚀 Initializing fare collection...');
    
    const existingFare = await Fare.findOne({ isSystemDefault: true, isActive: true });
    
    if (existingFare) {
      return res.status(200).json({
        success: true,
        message: 'System fare already exists',
        data: existingFare
      });
    }

    const defaultFareData = {
      adminId: new mongoose.Types.ObjectId(),
      baseFare: 25,
      perKmRate: 10,
      waiting60min: 60,
      isSystemDefault: true,
      isActive: true
    };

    const newFare = new Fare(defaultFareData);
    const savedFare = await newFare.save();

    console.log('✅ Default system fare created successfully:', savedFare._id);

    return res.status(201).json({
      success: true,
      message: 'Fare collection initialized successfully',
      data: savedFare
    });

  } catch (error) {
    console.error('❌ Error initializing fare collection:', error);
    return res.status(500).json({
      success: false,
      message: 'Error initializing fare collection',
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
    const { baseFare, perKmRate, waiting60min = 60 } = req.body;

    // Validation
    if (!baseFare || baseFare <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Base fare is required and must be greater than 0'
      });
    }

    if (!perKmRate || perKmRate <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Per kilometer rate is required and must be greater than 0'
      });
    }

    if (perKmRate > 1000) {
      return res.status(400).json({
        success: false,
        message: 'Per kilometer rate cannot exceed ₹1000'
      });
    }

    console.log('Looking for existing system fare...');
    
    // Since you have only single collection (admin-based), find or create
    let fare = await Fare.findOne({ isSystemDefault: true, isActive: true });
    console.log('Existing system fare found:', fare ? 'Yes' : 'No');

    if (fare) {
      // Update existing system fare
      console.log('Updating existing system fare');
      
      fare.baseFare = Number(baseFare);
      fare.perKmRate = Number(perKmRate);
      fare.waiting60min = Number(waiting60min);

      const savedFare = await fare.save();
      console.log('System fare updated successfully:', savedFare._id);

      return res.status(200).json({
        success: true,
        message: 'System fare updated successfully',
        data: savedFare
      });
    } else {
      // Create new system fare (single admin-based fare)
      console.log('Creating new system fare');
      
      const newFareData = {
        adminId: new mongoose.Types.ObjectId(),
        baseFare: Number(baseFare),
        perKmRate: Number(perKmRate),
        waiting60min: Number(waiting60min),
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
// @desc    Get current system fare (auto-create if doesn't exist)
// @access  Public
router.get('/', async (req, res) => {
  console.log('GET /api/fares called');
  
  try {
    let fare = await Fare.findOne({ isSystemDefault: true, isActive: true });
    console.log('System fare found:', fare ? 'Yes' : 'No');

    if (!fare) {
      console.log('⚠️ No system fare found, creating default...');
      
      // Auto-create default system fare with new structure
      const defaultFareData = {
        adminId: new mongoose.Types.ObjectId(),
        baseFare: 25,
        perKmRate: 10,
        waiting60min: 60,
        isSystemDefault: true,
        isActive: true
      };

      fare = new Fare(defaultFareData);
      await fare.save();
      
      console.log('✅ Default system fare created automatically');
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
      // Auto-create default if missing
      console.log('⚠️ No system fare found for calculation, creating default...');
      
      const defaultFareData = {
        adminId: new mongoose.Types.ObjectId(),
        baseFare: 25,
        perKmRate: 10,
        waiting60min: 60,
        isSystemDefault: true,
        isActive: true
      };

      fare = new Fare(defaultFareData);
      await fare.save();
      console.log('✅ Default system fare created for calculation');
    }

    // Calculate fare components
    const baseFare = fare.baseFare;
    const distanceFare = Number(distance) * fare.perKmRate;
    
    // Calculate waiting charges - charge per 60-minute interval
    let waitingCharge = 0;
    if (waitingMinutes > 0) {
      const intervals = Math.ceil(waitingMinutes / 60);
      waitingCharge = intervals * fare.waiting60min;
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
      hasWaiting60min: fareDoc ? (fareDoc.waiting60min !== undefined) : false,
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
