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
// @desc    ENHANCED MIGRATION: Remove old waiting fields and ensure waiting60min exists
// @access  Public (call once after deployment)
router.post('/migrate', async (req, res) => {
  try {
    console.log('🚀 Starting ENHANCED migration...');
    
    // Use raw MongoDB operations to bypass Mongoose schema validation
    const db = mongoose.connection.db;
    const collection = db.collection('fares');

    // Check existing documents
    const totalDocs = await collection.countDocuments();
    console.log(`📊 Total documents: ${totalDocs}`);

    // Check for documents with old waiting fields
    const docsWithOldFields = await collection.countDocuments({
      $or: [
        { waiting5min: { $exists: true } },
        { waiting10min: { $exists: true } },
        { waiting15min: { $exists: true } },
        { waiting20min: { $exists: true } },
        { waiting25min: { $exists: true } },
        { waiting30min: { $exists: true } }
      ]
    });

    console.log(`📊 Documents with old waiting fields: ${docsWithOldFields}`);

    if (docsWithOldFields > 0 || totalDocs > 0) {
      // STEP 1: Remove all old waiting fields and ensure waiting60min exists
      const result = await collection.updateMany(
        {}, // Update ALL documents
        [
          {
            $set: {
              waiting60min: { 
                $cond: { 
                  if: { $exists: ["$waiting60min"] }, 
                  then: "$waiting60min", 
                  else: 60 // Default value if waiting60min doesn't exist
                } 
              }
            }
          },
          {
            $unset: [
              "waiting5min",
              "waiting10min", 
              "waiting15min",
              "waiting20min",
              "waiting25min",
              "waiting30min"
            ]
          }
        ]
      );

      console.log(`✅ Enhanced migration completed!`);
      console.log(`   - Matched documents: ${result.matchedCount}`);
      console.log(`   - Modified documents: ${result.modifiedCount}`);

      // Verify migration
      const finalCount = await collection.countDocuments({
        waiting60min: { $exists: true }
      });

      const oldFieldsRemaining = await collection.countDocuments({
        $or: [
          { waiting5min: { $exists: true } },
          { waiting10min: { $exists: true } },
          { waiting15min: { $exists: true } },
          { waiting20min: { $exists: true } },
          { waiting25min: { $exists: true } },
          { waiting30min: { $exists: true } }
        ]
      });

      return res.status(200).json({
        success: true,
        message: 'Enhanced migration completed successfully',
        data: {
          totalDocuments: totalDocs,
          documentsUpdated: result.modifiedCount,
          documentsWithWaiting60min: finalCount,
          oldFieldsRemaining: oldFieldsRemaining,
          migrationDetails: {
            matchedCount: result.matchedCount,
            modifiedCount: result.modifiedCount
          }
        }
      });
    } else {
      return res.status(200).json({
        success: true,
        message: 'No migration needed',
        data: {
          totalDocuments: totalDocs,
          documentsWithWaiting60min: totalDocs
        }
      });
    }

  } catch (error) {
    console.error('❌ Enhanced migration failed:', error);
    return res.status(500).json({
      success: false,
      message: 'Enhanced migration failed',
      error: error.message
    });
  }
});

// @route   POST /api/fares/force-clean
// @desc    FORCE CLEAN: Remove ALL old waiting fields (nuclear option)
// @access  Public (use if migrate doesn't work)
router.post('/force-clean', async (req, res) => {
  try {
    console.log('🚀 Starting FORCE CLEAN of old waiting fields...');
    
    const db = mongoose.connection.db;
    const collection = db.collection('fares');

    // FORCE remove old fields from ALL documents
    const result = await collection.updateMany(
      {}, // All documents
      {
        $unset: {
          waiting5min: "",
          waiting10min: "",
          waiting15min: "",
          waiting20min: "",
          waiting25min: "",
          waiting30min: ""
        },
        $set: {
          waiting60min: 60 // Ensure waiting60min exists
        }
      }
    );

    console.log(`✅ Force clean completed!`);
    console.log(`   - Matched documents: ${result.matchedCount}`);
    console.log(`   - Modified documents: ${result.modifiedCount}`);

    // Verify cleanup
    const oldFieldsCheck = await collection.countDocuments({
      $or: [
        { waiting5min: { $exists: true } },
        { waiting10min: { $exists: true } },
        { waiting15min: { $exists: true } },
        { waiting20min: { $exists: true } },
        { waiting25min: { $exists: true } },
        { waiting30min: { $exists: true } }
      ]
    });

    return res.status(200).json({
      success: true,
      message: 'Force clean completed successfully',
      data: {
        documentsUpdated: result.modifiedCount,
        oldFieldsRemaining: oldFieldsCheck,
        cleanupComplete: oldFieldsCheck === 0
      }
    });

  } catch (error) {
    console.error('❌ Force clean failed:', error);
    return res.status(500).json({
      success: false,
      message: 'Force clean failed',
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
    
    // Find existing fare
    let fare = await Fare.findOne({ isSystemDefault: true, isActive: true });
    console.log('Existing system fare found:', fare ? 'Yes' : 'No');

    if (fare) {
      // Update existing system fare using raw MongoDB to ensure field cleanup
      const db = mongoose.connection.db;
      const collection = db.collection('fares');
      
      const updateResult = await collection.updateOne(
        { _id: fare._id },
        {
          $set: {
            baseFare: Number(baseFare),
            perKmRate: Number(perKmRate),
            waiting60min: Number(waiting60min),
            updatedAt: new Date()
          },
          $unset: {
            waiting5min: "",
            waiting10min: "",
            waiting15min: "",
            waiting20min: "",
            waiting25min: "",
            waiting30min: ""
          }
        }
      );

      // Get updated document
      const updatedFare = await Fare.findById(fare._id);
      console.log('System fare updated successfully:', updatedFare._id);

      return res.status(200).json({
        success: true,
        message: 'System fare updated successfully',
        data: updatedFare
      });
    } else {
      // Create new system fare
      console.log('Creating new system fare');
      
      const newFareData = {
        adminId: new mongoose.Types.ObjectId(),
        baseFare: Number(baseFare),
        perKmRate: Number(perKmRate),
        waiting60min: Number(waiting60min),
        isSystemDefault: true,
        isActive: true
      };

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

    let fare = await Fare.findOne({ isSystemDefault: true, isActive: true });
    
    if (!fare) {
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

// Debug route
router.get('/debug/test', async (req, res) => {
  try {
    console.log('Testing database connection...');
    
    const dbStatus = mongoose.connection.readyState;
    const count = await Fare.countDocuments();
    const fareDoc = await Fare.findOne({ isSystemDefault: true, isActive: true });
    
    // Check for old fields
    const db = mongoose.connection.db;
    const collection = db.collection('fares');
    const oldFieldsCount = await collection.countDocuments({
      $or: [
        { waiting5min: { $exists: true } },
        { waiting10min: { $exists: true } },
        { waiting15min: { $exists: true } },
        { waiting20min: { $exists: true } },
        { waiting25min: { $exists: true } },
        { waiting30min: { $exists: true } }
      ]
    });
    
    res.json({
      success: true,
      dbStatus: dbStatus === 1 ? 'connected' : 'disconnected',
      documentCount: count,
      systemFare: fareDoc,
      hasWaiting60min: fareDoc ? (fareDoc.waiting60min !== undefined) : false,
      oldFieldsStillExist: oldFieldsCount > 0,
      documentsWithOldFields: oldFieldsCount
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
