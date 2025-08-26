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

module.exports = {
  addDriver,
  getDrivers
};
