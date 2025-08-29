const User = require('../models/User');

const login = async (req, res) => {
  try {
    const { phoneNumber } = req.body;

    // Check if admin phone number
    const adminPhoneNumber = "9876543210";
    
    if (phoneNumber === adminPhoneNumber) {
      let admin = await User.findOne({ phoneNumber, userType: 'admin' });
      
      if (!admin) {
        // Create new admin with all required fields
        admin = new User({
          phoneNumber,
          userType: 'admin',
          name: 'admin',
          password: '123'
        });
        await admin.save();
      } else {
        // SOLUTION: Auto-update existing admin if missing fields
        let needsUpdate = false;
        
        if (!admin.name) {
          admin.name = 'admin';
          needsUpdate = true;
        }
        
        if (!admin.password) {
          admin.password = '123';
          needsUpdate = true;
        }
        
        if (needsUpdate) {
          await admin.save();
          console.log('✅ Admin fields updated automatically');
        }
      }
      
      return res.json({
        success: true,
        user: admin
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

// Get admin profile
const getAdminProfile = async (req, res) => {
  try {
    const { adminId } = req.params;
    
    const admin = await User.findOne({ _id: adminId, userType: 'admin' });
    
    if (!admin) {
      return res.status(404).json({
        success: false,
        message: 'Admin not found'
      });
    }

    res.json({
      success: true,
      admin: {
        _id: admin._id,
        phoneNumber: admin.phoneNumber,
        userType: admin.userType,
        name: admin.name,
        password: admin.password,
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

// Update admin profile
const updateAdminProfile = async (req, res) => {
  try {
    const { adminId } = req.params;
    const { name, password } = req.body;

    const admin = await User.findOne({ _id: adminId, userType: 'admin' });
    
    if (!admin) {
      return res.status(404).json({
        success: false,
        message: 'Admin not found'
      });
    }

    // Update fields if provided
    if (name !== undefined) {
      admin.name = name;
    }
    
    if (password !== undefined) {
      admin.password = password;
    }

    await admin.save();

    res.json({
      success: true,
      message: 'Admin profile updated successfully',
      admin: {
        _id: admin._id,
        phoneNumber: admin.phoneNumber,
        userType: admin.userType,
        name: admin.name,
        password: admin.password,
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

module.exports = {
  login,
  getAdminProfile,
  updateAdminProfile
};
