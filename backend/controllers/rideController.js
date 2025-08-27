const Driver = require('../models/Driver');
const User = require('../models/User'); // Make sure this import exists

// Cancel ride - increment cancelled rides count
const cancelRide = async (req, res) => {
  try {
    const { userId } = req.params;
    const { action, timestamp } = req.body;
    
    console.log('[CANCEL RIDE] Processing for user:', userId);
    console.log('[CANCEL RIDE] Request body:', { action, timestamp });
    
    // First try to find by _id (MongoDB ObjectId)
    let updatedDriver = await Driver.findByIdAndUpdate(
      userId,
      { 
        $inc: { cancelledRides: 1 },
        lastCancelledAt: new Date(timestamp || new Date()),
        updatedAt: new Date()
      },
      { new: true }
    );
    
    // If not found by _id, try searching by userId field
    if (!updatedDriver) {
      console.log('[CANCEL RIDE] Driver not found by _id, trying userId field...');
      updatedDriver = await Driver.findOneAndUpdate(
        { userId: userId },
        { 
          $inc: { cancelledRides: 1 },
          lastCancelledAt: new Date(timestamp || new Date()),
          updatedAt: new Date()
        },
        { new: true }
      );
    }
    
    // If still not found, try to find/create driver record using User data
    if (!updatedDriver) {
      console.log('[CANCEL RIDE] Driver record not found, trying to find User and create Driver record...');
      
      const user = await User.findById(userId);
      if (user) {
        console.log('[CANCEL RIDE] User found, creating new Driver record...');
        
        updatedDriver = new Driver({
          userId: user._id,
          name: user.name,
          phoneNumber: user.phoneNumber,
          userType: user.userType,
          cancelledRides: 1,
          completedRides: 0,
          totalRides: 0,
          totalEarnings: 0,
          earnings: 0,
          totalTrips: 0,
          lastCancelledAt: new Date(timestamp || new Date()),
          createdAt: new Date(),
          updatedAt: new Date()
        });
        
        await updatedDriver.save();
        console.log('[CANCEL RIDE] New driver record created successfully');
      }
    }
    
    if (!updatedDriver) {
      console.log('[CANCEL RIDE] Driver/User not found with ID:', userId);
      return res.status(404).json({ 
        success: false,
        error: 'Driver not found. Please ensure you are logged in correctly.' 
      });
    }
    
    console.log('[CANCEL RIDE] Success for:', updatedDriver.name);
    
    res.status(200).json({
      success: true,
      message: 'Ride cancelled successfully',
      data: {
        userId: updatedDriver.userId || updatedDriver._id,
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
    
    if (!rideEarnings || rideEarnings <= 0) {
      return res.status(400).json({
        success: false,
        error: 'Valid ride earnings are required'
      });
    }
    
    // First try to find by _id (MongoDB ObjectId)
    let updatedDriver = await Driver.findByIdAndUpdate(
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
    
    // If not found by _id, try searching by userId field
    if (!updatedDriver) {
      console.log('[COMPLETE RIDE] Driver not found by _id, trying userId field...');
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
    }
    
    // If still not found, try to find/create driver record using User data
    if (!updatedDriver) {
      console.log('[COMPLETE RIDE] Driver record not found, trying to find User and create Driver record...');
      
      const user = await User.findById(userId);
      if (user) {
        console.log('[COMPLETE RIDE] User found, creating new Driver record...');
        
        updatedDriver = new Driver({
          userId: user._id,
          name: user.name,
          phoneNumber: user.phoneNumber,
          userType: user.userType,
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
        console.log('[COMPLETE RIDE] New driver record created successfully');
      }
    }
    
    if (!updatedDriver) {
      console.log('[COMPLETE RIDE] Driver/User not found with ID:', userId);
      return res.status(404).json({ 
        success: false,
        error: 'Driver not found. Please ensure you are logged in correctly.' 
      });
    }
    
    console.log('[COMPLETE RIDE] Success for:', updatedDriver.name);
    
    res.status(200).json({
      success: true,
      message: 'Trip completed successfully! Earnings updated.',
      data: {
        userId: updatedDriver.userId || updatedDriver._id,
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
    
    // First try to find by _id (MongoDB ObjectId)
    let driver = await Driver.findById(userId);
    
    // If not found by _id, try searching by userId field
    if (!driver) {
      console.log('[GET STATS] Driver not found by _id, trying userId field...');
      driver = await Driver.findOne({ userId: userId });
    }
    
    // If still not found, try to find user and create driver record
    if (!driver) {
      console.log('[GET STATS] Driver record not found, trying to find User...');
      
      const user = await User.findById(userId);
      if (user) {
        console.log('[GET STATS] User found, creating new Driver record...');
        
        driver = new Driver({
          userId: user._id,
          name: user.name,
          phoneNumber: user.phoneNumber,
          userType: user.userType,
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
        console.log('[GET STATS] New driver record created successfully');
      }
    }
    
    if (!driver) {
      console.log('[GET STATS] Driver/User not found with ID:', userId);
      return res.status(404).json({ 
        success: false,
        error: 'Driver not found. Please ensure you are logged in correctly.' 
      });
    }
    
    const stats = {
      userId: driver.userId || driver._id,
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
    
    console.log('[GET STATS] Success for:', driver.name);
    
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

module.exports = {
  cancelRide,
  completeRide,
  getDriverStats
};
