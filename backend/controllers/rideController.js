const Driver = require('../models/Driver');

// Cancel ride - increment cancelled rides count
const cancelRide = async (req, res) => {
  try {
    const { userId } = req.params;
    
    console.log('Cancelling ride for user:', userId);
    
    // FIXED: Look for driver by userId field, not by _id
    const updatedDriver = await Driver.findOneAndUpdate(
      { userId: userId }, // CHANGED: Search by userId field instead of _id
      { 
        $inc: { cancelledRides: 1 },
        updatedAt: new Date()
      },
      { new: true }
    );
    
    if (!updatedDriver) {
      console.log('Driver not found with userId:', userId);
      return res.status(404).json({ 
        success: false,
        error: 'Driver record not found for this user' 
      });
    }
    
    console.log('Cancelled rides updated successfully for:', updatedDriver.name);
    
    res.json({
      success: true,
      message: 'Cancelled rides updated successfully',
      data: {
        cancelledRides: updatedDriver.cancelledRides,
        totalRides: updatedDriver.totalRides,
        name: updatedDriver.name,
        phoneNumber: updatedDriver.phoneNumber
      }
    });
  } catch (error) {
    console.error('Cancel ride error:', error);
    
    // Handle specific MongoDB errors
    if (error.name === 'CastError') {
      return res.status(400).json({ 
        success: false,
        error: 'Invalid user ID format' 
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
    
    console.log('Completing ride for user:', userId, 'with earnings:', rideEarnings);
    
    // FIXED: Look for driver by userId field, not by _id
    const updatedDriver = await Driver.findOneAndUpdate(
      { userId: userId }, // CHANGED: Search by userId field instead of _id
      { 
        $inc: { 
          completedRides: 1,
          totalRides: 1,
          totalTrips: 1,
          totalEarnings: rideEarnings,
          earnings: rideEarnings
        },
        updatedAt: new Date()
      },
      { new: true }
    );
    
    if (!updatedDriver) {
      console.log('Driver not found with userId:', userId);
      return res.status(404).json({ 
        success: false,
        error: 'Driver record not found for this user' 
      });
    }
    
    console.log('Completed ride updated successfully for:', updatedDriver.name);
    console.log('Previous total earnings:', (updatedDriver.totalEarnings - rideEarnings));
    console.log('New total earnings:', updatedDriver.totalEarnings);
    console.log('This ride earnings:', rideEarnings);
    
    // Optional: Save trip details to a separate trips collection
    if (tripData) {
      console.log('Trip data received:', JSON.stringify(tripData, null, 2));
      // Uncomment these lines if you want to save detailed trip data:
      // const Trip = require('../models/Trip');
      // const trip = new Trip({
      //   driverId: updatedDriver._id,
      //   ...tripData
      // });
      // await trip.save();
      // console.log('Trip details saved successfully');
    }
    
    res.json({
      success: true,
      message: 'Trip completed successfully! Earnings updated.',
      data: {
        completedRides: updatedDriver.completedRides,
        totalRides: updatedDriver.totalRides,
        totalEarnings: updatedDriver.totalEarnings,
        earnings: updatedDriver.earnings,
        name: updatedDriver.name,
        phoneNumber: updatedDriver.phoneNumber,
        rideEarnings: rideEarnings,
        previousTotal: updatedDriver.totalEarnings - rideEarnings
      }
    });
  } catch (error) {
    console.error('Complete ride error:', error);
    
    // Handle specific MongoDB errors
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
    
    console.log('Getting stats for user:', userId);
    
    // FIXED: Look for driver by userId field, not by _id
    const driver = await Driver.findOne({ userId: userId }); // CHANGED: Search by userId field instead of _id
    
    if (!driver) {
      console.log('Driver not found with userId:', userId);
      return res.status(404).json({ 
        success: false,
        error: 'Driver record not found for this user' 
      });
    }
    
    const stats = {
      name: driver.name,
      phoneNumber: driver.phoneNumber,
      totalRides: driver.totalRides || 0,
      completedRides: driver.completedRides || 0,
      cancelledRides: driver.cancelledRides || 0,
      totalEarnings: driver.totalEarnings || 0,
      earnings: driver.earnings || 0,
      totalTrips: driver.totalTrips || 0,
      createdAt: driver.createdAt,
      updatedAt: driver.updatedAt
    };
    
    console.log('Driver stats retrieved:', JSON.stringify(stats, null, 2));
    
    res.json({
      success: true,
      message: 'Driver statistics retrieved successfully',
      data: stats
    });
  } catch (error) {
    console.error('Get driver stats error:', error);
    
    // Handle specific MongoDB errors
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
