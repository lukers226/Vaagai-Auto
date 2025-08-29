const User = require('../models/User');

const login = async (req, res) => {
  try {
    const { phoneNumber, password } = req.body;

    // Check if admin phone number
    const adminPhoneNumber = "9876543210";
    
    if (phoneNumber === adminPhoneNumber) {
      let admin = await User.findOne({ phoneNumber, userType: 'admin' });
      
      // If admin doesn't exist, create one with default password and name
      if (!admin) {
        admin = await User.createAdmin(phoneNumber, 'Admin');
        
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
          message: 'Admin account created successfully',
          defaultPassword: admin.getOriginalPassword()
        });
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
        }
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

// Admin login function with password verification
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

// Get admin default password
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

// Force create admin (for testing/setup)
const createAdminAccount = async (req, res) => {
  try {
    const { phoneNumber, name } = req.body;
    
    // Check if admin already exists
    const existingAdmin = await User.findOne({ phoneNumber, userType: 'admin' });
    if (existingAdmin) {
      return res.status(400).json({
        success: false,
        message: 'Admin with this phone number already exists'
      });
    }
    
    // Create admin
    const admin = await User.createAdmin(phoneNumber, name || 'Admin');
    
    res.status(201).json({
      success: true,
      message: 'Admin account created successfully',
      user: {
        _id: admin._id,
        phoneNumber: admin.phoneNumber,
        name: admin.name,
        userType: admin.userType,
        password: admin.password, // This will show the plain password
        originalPassword: admin.originalPassword,
        createdAt: admin.createdAt,
        updatedAt: admin.updatedAt
      },
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
  getAdminPassword,
  createAdminAccount
};
