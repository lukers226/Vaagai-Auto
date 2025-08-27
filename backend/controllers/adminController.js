const User = require('../models/User');
const Driver = require('../models/Driver');

const addDriver = async (req, res) => {
  try {
    const { name, phoneNumber } = req.body;

    // Check if phone number already exists
    const existingUser = await User.findOne({ phoneNumber });
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'Phone number already registered'
      });
    }

    // Create user
    const user = new User({
      phoneNumber,
      userType: 'driver',
      name
    });
    await user.save();

    // Create driver
    const driver = new Driver({
      name,
      phoneNumber,
      userId: user._id
    });
    await driver.save();

    res.status(201).json({
      success: true,
      message: 'Driver added successfully',
      driver: driver
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

const getDrivers = async (req, res) => {
  try {
    const drivers = await Driver.find().sort({ createdAt: -1 });
    
    res.json({
      success: true,
      drivers: drivers
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

const getDriverStats = async (req, res) => {
  try {
    const { id } = req.params;
    
    const driver = await Driver.findById(id);
    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Driver not found'
      });
    }

    res.json({
      success: true,
      stats: {
        earnings: driver.earnings,
        totalEarnings: driver.totalEarnings,
        totalTrips: driver.totalTrips,
        totalRides: driver.totalRides,
        completedRides: driver.completedRides,
        cancelledRides: driver.cancelledRides,
        completionRate: driver.totalRides > 0 ? 
          ((driver.completedRides / driver.totalRides) * 100).toFixed(2) : 0
      }
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

const updateDriverEarnings = async (req, res) => {
  try {
    const { id } = req.params;
    const { amount } = req.body;

    const driver = await Driver.findById(id);
    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Driver not found'
      });
    }

    // Update earnings
    driver.earnings += amount;
    driver.totalEarnings += amount;
    await driver.save();

    // Also update User model
    await User.findByIdAndUpdate(driver.userId, {
      $inc: { 
        earnings: amount,
        totalEarnings: amount
      }
    });

    res.json({
      success: true,
      message: 'Earnings updated successfully',
      driver: {
        earnings: driver.earnings,
        totalEarnings: driver.totalEarnings
      }
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

const updateDriverRide = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    const driver = await Driver.findById(id);
    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Driver not found'
      });
    }

    // Update ride counts
    driver.totalRides += 1;
    driver.totalTrips += 1;
    
    if (status === 'completed') {
      driver.completedRides += 1;
    } else if (status === 'cancelled') {
      driver.cancelledRides += 1;
    }

    await driver.save();

    // Also update User model
    const updateData = {
      $inc: { 
        totalRides: 1,
        totalTrips: 1
      }
    };

    if (status === 'completed') {
      updateData.$inc.completedRides = 1;
    } else if (status === 'cancelled') {
      updateData.$inc.cancelledRides = 1;
    }

    await User.findByIdAndUpdate(driver.userId, updateData);

    res.json({
      success: true,
      message: `Ride ${status} successfully`,
      driver: {
        totalRides: driver.totalRides,
        completedRides: driver.completedRides,
        cancelledRides: driver.cancelledRides,
        totalTrips: driver.totalTrips
      }
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

module.exports = {
  addDriver,
  getDrivers,
  getDriverStats,
  updateDriverEarnings,
  updateDriverRide
};
