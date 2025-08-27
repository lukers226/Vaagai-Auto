const Driver = require('../models/Driver');
const User = require('../models/User');
const mongoose = require('mongoose');

// Cancel ride - increment cancelled rides count
const cancelRide = async (req, res) => {
  try {
    const { userId } = req.params;
    const { action, timestamp } = req.body;
    
    console.log('[CANCEL RIDE] Processing for user:', userId);
    console.log('[CANCEL RIDE] Request body:', { action, timestamp });
    
    // Validate userId format
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid user ID format'
      });
    }
    
    let updatedDriver = null;
    
    // Strategy 1: Find by _id (this is the main driver record ID)
    updatedDriver = await Driver.findByIdAndUpdate(
      userId,
      { 
        $inc: { cancelledRides: 1 },
        lastCancelledAt: new Date(timestamp || new Date()),
        updatedAt: new Date()
      },
      { new: true }
    );
    
    if (updatedDriver) {
      console.log('[CANCEL RIDE] Updated driver record found by _id:', updatedDriver._id);
    }
    
    // Strategy 2: Find by userId field (this matches the User's _id)
    if (!updatedDriver) {
      console.log('[CANCEL RIDE] Driver not found by _id, searching by userId field...');
      
      // Search for driver where userId field matches the provided userId
      updatedDriver = await Driver.findOneAndUpdate(
        { userId: userId }, // This should match userId: ObjectId("68ade3c889d828fd2f80b5bc")
        { 
          $inc: { cancelledRides: 1 },
          lastCancelledAt: new Date(timestamp || new Date()),
          updatedAt: new Date()
        },
        { new: true }
      );
      
      if (updatedDriver) {
        console.log('[CANCEL RIDE] Updated driver record found by userId field:', updatedDriver._id);
      }
    }
    
    // Strategy 3: Create new driver record if none exists
    if (!updatedDriver) {
      console.log('[CANCEL RIDE] No driver record found, checking if user exists and creating driver record...');
      
      const user = await User.findById(userId);
      if (!user) {
        return res.status(404).json({ 
          success: false,
          error: 'User not found. Please ensure you are logged in correctly.' 
        });
      }
      
      console.log('[CANCEL RIDE] User found:', user.name, 'Creating new Driver record...');
      
      // Create new driver record
      updatedDriver = new Driver({
        userId: user._id, // Store as ObjectId reference
        name: user.name,
        phoneNumber: user.phoneNumber,
        userType: user.userType || 'driver',
        cancelledRides: 1,
        completedRides: 0,
        totalRides: 1, // Include cancelled rides in total
        totalEarnings: 0,
        earnings: 0,
        totalTrips: 0,
        lastCancelledAt: new Date(timestamp || new Date()),
        createdAt: new Date(),
        updatedAt: new Date()
      });
      
      await updatedDriver.save();
      console.log('[CANCEL RIDE] New driver record created with ID:', updatedDriver._id);
    }
    
    // Final validation
    if (!updatedDriver) {
      return res.status(404).json({ 
        success: false,
        error: 'Failed to update or create driver record' 
      });
    }
    
    console.log('[CANCEL RIDE] SUCCESS - Final stats:', {
      driverRecordId: updatedDriver._id,
      userIdField: updatedDriver.userId,
      cancelledRides: updatedDriver.cancelledRides,
      totalRides: updatedDriver.totalRides,
      name: updatedDriver.name
    });
    
    res.status(200).json({
      success: true,
      message: 'Ride cancelled successfully',
      data: {
        driverRecordId: updatedDriver._id,
        userId: updatedDriver.userId,
        cancelledRides: updatedDriver.cancelledRides,
        totalRides: updatedDriver.totalRides,
        completedRides: updatedDriver.completedRides,
        name: updatedDriver.name,
        phoneNumber: updatedDriver.phoneNumber,
        lastCancelledAt: updatedDriver.lastCancelledAt
      }
    });
    
  } catch (error) {
    console.error('[CANCEL RIDE] Error:', error);
    
    if (error.name === 'CastError') {
      return res.status(400).json({ 
        success: false,
        error: 'Invalid user ID format' 
      });
    }
    
    if (error.name === 'ValidationError') {
      return res.status(400).json({ 
        success: false,
        error: 'Validation error: ' + error.message 
      });
    }
    
    res.status(500).json({ 
      success: false,
      error: error.message || 'Internal server error while cancelling ride' 
    });
  }
};

// Complete ride - increment completed rides and update earnings
const completeRide = async (req, res) => {
  try {
    const { userId } = req.params;
    const { rideEarnings, tripData } = req.body;
    
    console.log('[COMPLETE RIDE] Processing for user:', userId, 'with earnings:', rideEarnings);
    
    // Validate inputs
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid user ID format'
      });
    }
    
    if (!rideEarnings || rideEarnings <= 0) {
      return res.status(400).json({
        success: false,
        error: 'Valid ride earnings are required'
      });
    }
    
    let updatedDriver = null;
    
    // Strategy 1: Find by _id
    updatedDriver = await Driver.findByIdAndUpdate(
      userId,
      { 
        $inc: { 
          completedRides: 1,
          totalRides: 1,
          totalTrips: 1,
          totalEarnings: rideEarnings,
          earnings: rideEarnings
        },
        lastCompletedAt: new Date(),
        updatedAt: new Date()
      },
      { new: true }
    );
    
    if (updatedDriver) {
      console.log('[COMPLETE RIDE] Updated driver record found by _id:', updatedDriver._id);
    }
    
    // Strategy 2: Find by userId field
    if (!updatedDriver) {
      console.log('[COMPLETE RIDE] Driver not found by _id, searching by userId field...');
      
      updatedDriver = await Driver.findOneAndUpdate(
        { userId: userId },
        { 
          $inc: { 
            completedRides: 1,
            totalRides: 1,
            totalTrips: 1,
            totalEarnings: rideEarnings,
            earnings: rideEarnings
          },
          lastCompletedAt: new Date(),
          updatedAt: new Date()
        },
        { new: true }
      );
      
      if (updatedDriver) {
        console.log('[COMPLETE RIDE] Updated driver record found by userId field:', updatedDriver._id);
      }
    }
    
    // Strategy 3: Create new driver record
    if (!updatedDriver) {
      console.log('[COMPLETE RIDE] No driver record found, checking if user exists and creating driver record...');
      
      const user = await User.findById(userId);
      if (!user) {
        return res.status(404).json({ 
          success: false,
          error: 'User not found. Please ensure you are logged in correctly.' 
        });
      }
      
      console.log('[COMPLETE RIDE] User found:', user.name, 'Creating new Driver record...');
      
      updatedDriver = new Driver({
        userId: user._id,
        name: user.name,
        phoneNumber: user.phoneNumber,
        userType: user.userType || 'driver',
        cancelledRides: 0,
        completedRides: 1,
        totalRides: 1,
        totalEarnings: rideEarnings,
        earnings: rideEarnings,
        totalTrips: 1,
        lastCompletedAt: new Date(),
        createdAt: new Date(),
        updatedAt: new Date()
      });
      
      await updatedDriver.save();
      console.log('[COMPLETE RIDE] New driver record created with ID:', updatedDriver._id);
    }
    
    if (!updatedDriver) {
      return res.status(404).json({ 
        success: false,
        error: 'Failed to update or create driver record' 
      });
    }
    
    console.log('[COMPLETE RIDE] SUCCESS - Final stats:', {
      driverRecordId: updatedDriver._id,
      userIdField: updatedDriver.userId,
      completedRides: updatedDriver.completedRides,
      totalRides: updatedDriver.totalRides,
      totalEarnings: updatedDriver.totalEarnings,
      name: updatedDriver.name
    });
    
    res.status(200).json({
      success: true,
      message: 'Trip completed successfully! Earnings updated.',
      data: {
        driverRecordId: updatedDriver._id,
        userId: updatedDriver.userId,
        completedRides: updatedDriver.completedRides,
        totalRides: updatedDriver.totalRides,
        totalEarnings: updatedDriver.totalEarnings,
        earnings: updatedDriver.earnings,
        name: updatedDriver.name,
        phoneNumber: updatedDriver.phoneNumber,
        rideEarnings: rideEarnings,
        previousTotal: updatedDriver.totalEarnings - rideEarnings,
        lastCompletedAt: updatedDriver.lastCompletedAt
      }
    });
    
  } catch (error) {
    console.error('[COMPLETE RIDE] Error:', error);
    
    if (error.name === 'CastError') {
      return res.status(400).json({ 
        success: false,
        error: 'Invalid user ID format' 
      });
    }
    
    if (error.name === 'ValidationError') {
      return res.status(400).json({ 
        success: false,
        error: 'Validation error: ' + error.message 
      });
    }
    
    res.status(500).json({ 
      success: false,
      error: error.message || 'Internal server error while completing ride' 
    });
  }
};

// Get driver statistics
const getDriverStats = async (req, res) => {
  try {
    const { userId } = req.params;
    
    console.log('[GET STATS] Processing for user:', userId);
    
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid user ID format'
      });
    }
    
    let driver = null;
    
    // Strategy 1: Find by _id
    driver = await Driver.findById(userId);
    
    if (driver) {
      console.log('[GET STATS] Driver found by _id:', driver._id);
    }
    
    // Strategy 2: Find by userId field
    if (!driver) {
      console.log('[GET STATS] Driver not found by _id, searching by userId field...');
      driver = await Driver.findOne({ userId: userId });
      
      if (driver) {
        console.log('[GET STATS] Driver found by userId field:', driver._id);
      }
    }
    
    // Strategy 3: Create new driver record with default stats
    if (!driver) {
      console.log('[GET STATS] No driver record found, checking if user exists...');
      
      const user = await User.findById(userId);
      if (!user) {
        return res.status(404).json({ 
          success: false,
          error: 'User not found. Please ensure you are logged in correctly.' 
        });
      }
      
      console.log('[GET STATS] User found:', user.name, 'Creating new Driver record with default stats...');
      
      driver = new Driver({
        userId: user._id,
        name: user.name,
        phoneNumber: user.phoneNumber,
        userType: user.userType || 'driver',
        cancelledRides: 0,
        completedRides: 0,
        totalRides: 0,
        totalEarnings: 0,
        earnings: 0,
        totalTrips: 0,
        createdAt: new Date(),
        updatedAt: new Date()
      });
      
      await driver.save();
      console.log('[GET STATS] New driver record created with ID:', driver._id);
    }
    
    const stats = {
      driverRecordId: driver._id,
      userId: driver.userId,
      name: driver.name,
      phoneNumber: driver.phoneNumber,
      userType: driver.userType,
      totalRides: driver.totalRides || 0,
      completedRides: driver.completedRides || 0,
      cancelledRides: driver.cancelledRides || 0,
      totalEarnings: driver.totalEarnings || 0,
      earnings: driver.earnings || 0,
      totalTrips: driver.totalTrips || 0,
      lastCompletedAt: driver.lastCompletedAt,
      lastCancelledAt: driver.lastCancelledAt,
      createdAt: driver.createdAt,
      updatedAt: driver.updatedAt,
      successRate: driver.totalRides > 0 ? 
        Math.round((driver.completedRides / driver.totalRides) * 100) : 0,
      averageEarnings: driver.completedRides > 0 ? 
        Math.round((driver.totalEarnings / driver.completedRides) * 100) / 100 : 0
    };
    
    console.log('[GET STATS] SUCCESS - Stats retrieved for:', driver.name);
    
    res.status(200).json({
      success: true,
      message: 'Driver statistics retrieved successfully',
      data: stats
    });
    
  } catch (error) {
    console.error('[GET STATS] Error:', error);
    
    if (error.name === 'CastError') {
      return res.status(400).json({ 
        success: false,
        error: 'Invalid user ID format' 
      });
    }
    
    res.status(500).json({ 
      success: false,
      error: error.message || 'Internal server error while getting driver stats' 
    });
  }
};

// NEW: Debug function to check existing driver records
const debugDriverRecords = async (req, res) => {
  try {
    const { userId } = req.params;
    
    console.log('[DEBUG] Searching for driver records related to userId:', userId);
    
    // Find all driver records that might be related
    const driverById = await Driver.findById(userId);
    const driverByUserId = await Driver.findOne({ userId: userId });
    const allDrivers = await Driver.find({});
    
    const result = {
      searchedUserId: userId,
      driverById: driverById,
      driverByUserId: driverByUserId,
      totalDriverRecords: allDrivers.length,
      allDrivers: allDrivers.map(d => ({
        _id: d._id,
        userId: d.userId,
        name: d.name,
        phoneNumber: d.phoneNumber,
        cancelledRides: d.cancelledRides,
        completedRides: d.completedRides
      }))
    };
    
    console.log('[DEBUG] Results:', JSON.stringify(result, null, 2));
    
    res.json({
      success: true,
      data: result
    });
    
  } catch (error) {
    console.error('[DEBUG] Error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

module.exports = {
  cancelRide,
  completeRide,
  getDriverStats,
  debugDriverRecords
};
