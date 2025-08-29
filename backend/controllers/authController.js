const User = require('../models/User');

const login = async (req, res) => {
  try {
    const { phoneNumber, password } = req.body;

    // Check if admin phone number
    const adminPhoneNumber = "9876543210";
    
    if (phoneNumber === adminPhoneNumber) {
      let admin = await User.findOne({ phoneNumber, userType: 'admin' });
      
      // If admin doesn't exist, create one with default password
      if (!admin) {
        admin = new User({
          phoneNumber,
          userType: 'admin',
          name: 'Admin', // You can make this dynamic if needed
          password: 'vaagaiauto123' // This will be hashed by the schema
        });
        await admin.save();
      }
      
      // If password is provided, verify it
      if (password) {
        const isPasswordValid = await admin.comparePassword(password);
        if (!isPasswordValid) {
          return res.status(401).json({
            success: false,
            message: 'Invalid password'
          });
        }
      }
      
      return res.json({
        success: true,
        user: {
          _id: admin._id,
          phoneNumber: admin.phoneNumber,
          userType: admin.userType,
          name: admin.name,
          createdAt: admin.createdAt,
          updatedAt: admin.updatedAt
        },
        // Include default password info for first-time setup
        defaultPassword: admin.isNew ? admin.getOriginalPassword() : undefined
      });
    }

    // Check if driver exists
    const driver = await User.findOne({ phoneNumber, userType: 'driver' });
    
    if (driver) {
      return res.json({
        success: true,
        user: driver
      });
    }

    res.status(401).json({
      success: false,
      message: 'Phone number not registered as driver'
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// New admin login function with password verification
const adminLogin = async (req, res) => {
  try {
    const { phoneNumber, password } = req.body;

    if (!password) {
      return res.status(400).json({
        success: false,
        message: 'Password is required for admin login'
      });
    }

    // Use the static method to find and verify admin
    const admin = await User.findAdminAndVerify(phoneNumber, password);
    
    if (!admin) {
      return res.status(401).json({ 
        success: false,
        message: 'Invalid phone number or password' 
      });
    }
    
    res.json({
      success: true,
      message: 'Admin login successful',
      user: {
        _id: admin._id,
        phoneNumber: admin.phoneNumber,
        name: admin.name,
        userType: admin.userType,
        createdAt: admin.createdAt,
        updatedAt: admin.updatedAt
      }
    });
    
  } catch (error) {
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
};

// Get admin default password (for reference)
const getAdminPassword = async (req, res) => {
  try {
    const { phoneNumber } = req.params;
    
    const admin = await User.findOne({ phoneNumber, userType: 'admin' });
    
    if (!admin) {
      return res.status(404).json({ 
        success: false,
        message: 'Admin not found' 
      });
    }
    
    res.json({
      success: true,
      defaultPassword: admin.getOriginalPassword()
    });
    
  } catch (error) {
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
};

module.exports = {
  login,
  adminLogin,
  getAdminPassword
};
