const express = require('express');
const router = express.Router();
const Fare = require('../models/fareModel');
const User = require('../models/User'); // Assuming you have User model
const Driver = require('../models/driverModel');

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
// @access  Public (you can add auth middleware later)
router.post('/', async (req, res) => {
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

    // Validate required fields
    if (!userId || !baseFare) {
      return res.status(400).json({
        success: false,
        message: 'User ID and base fare are required'
      });
    }

    // Validate that userId exists in User or Driver collection
    const userExists = await User.findById(userId) || await Driver.findById(userId);
    if (!userExists) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Check if fare already exists for this user
    let fare = await Fare.findOne({ userId });

    if (fare) {
      // Update existing fare
      fare.baseFare = baseFare;
      fare.waiting5min = waiting5min;
      fare.waiting10min = waiting10min;
      fare.waiting15min = waiting15min;
      fare.waiting20min = waiting20min;
      fare.waiting25min = waiting25min;
      fare.waiting30min = waiting30min;
      fare.updatedAt = Date.now();

      await fare.save();

      return res.status(200).json({
        success: true,
        message: 'Fare updated successfully',
        data: fare
      });
    } else {
      // Create new fare
      fare = new Fare({
        userId,
        baseFare,
        waiting5min,
        waiting10min,
        waiting15min,
        waiting20min,
        waiting25min,
        waiting30min
      });

      await fare.save();

      return res.status(201).json({
        success: true,
        message: 'Fare created successfully',
        data: fare
      });
    }
  } catch (error) {
    console.error('Error creating/updating fare:', error);
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
  try {
    const { userId } = req.params;

    const fare = await Fare.findOne({ userId }).populate('userId', 'name phoneNumber');

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
    console.error('Error fetching fare:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error occurred while fetching fare',
      error: error.message
    });
  }
});

// @route   GET /api/fares
// @desc    Get all fares
// @access  Public (Admin only - you can add auth middleware)
router.get('/', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const fares = await Fare.find({ isActive: true })
      .populate('userId', 'name phoneNumber')
      .sort({ updatedAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await Fare.countDocuments({ isActive: true });
    const totalPages = Math.ceil(total / limit);

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
    console.error('Error fetching fares:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error occurred while fetching fares',
      error: error.message
    });
  }
});

// @route   PUT /api/fares/:userId
// @desc    Update fare for a specific user
// @access  Public
router.put('/:userId', validateObjectId, async (req, res) => {
  try {
    const { userId } = req.params;
    const updateData = req.body;

    // Remove userId from update data if present
    delete updateData.userId;
    
    // Add updatedAt timestamp
    updateData.updatedAt = Date.now();

    const fare = await Fare.findOneAndUpdate(
      { userId },
      updateData,
      { new: true, runValidators: true }
    ).populate('userId', 'name phoneNumber');

    if (!fare) {
      return res.status(404).json({
        success: false,
        message: 'Fare not found for this user'
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Fare updated successfully',
      data: fare
    });
  } catch (error) {
    console.error('Error updating fare:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error occurred while updating fare',
      error: error.message
    });
  }
});

// @route   DELETE /api/fares/:userId
// @desc    Delete fare for a specific user (soft delete)
// @access  Public (Admin only)
router.delete('/:userId', validateObjectId, async (req, res) => {
  try {
    const { userId } = req.params;

    const fare = await Fare.findOneAndUpdate(
      { userId },
      { isActive: false, updatedAt: Date.now() },
      { new: true }
    );

    if (!fare) {
      return res.status(404).json({
        success: false,
        message: 'Fare not found for this user'
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Fare deleted successfully',
      data: fare
    });
  } catch (error) {
    console.error('Error deleting fare:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error occurred while deleting fare',
      error: error.message
    });
  }
});

// @route   POST /api/fares/:userId/activate
// @desc    Reactivate a soft-deleted fare
// @access  Public (Admin only)
router.post('/:userId/activate', validateObjectId, async (req, res) => {
  try {
    const { userId } = req.params;

    const fare = await Fare.findOneAndUpdate(
      { userId },
      { isActive: true, updatedAt: Date.now() },
      { new: true }
    ).populate('userId', 'name phoneNumber');

    if (!fare) {
      return res.status(404).json({
        success: false,
        message: 'Fare not found for this user'
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Fare activated successfully',
      data: fare
    });
  } catch (error) {
    console.error('Error activating fare:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error occurred while activating fare',
      error: error.message
    });
  }
});

module.exports = router;
