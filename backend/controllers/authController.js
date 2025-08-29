const User = require('../models/User');

const login = async (req, res) => {
  try {
    const { phoneNumber, password } = req.body;

    // Check if admin phone number
    const adminPhoneNumber = "9876543210";
    
    if (phoneNumber === adminPhoneNumber) {
      let admin = await User.findOne({ phoneNumber, userType: 'admin' });
      
      // If admin doesn't exist, create one with explicit fields
      if (!admin) {
        admin = new User({
          phoneNumber: adminPhoneNumber,
          userType: 'admin',
          name: 'Admin',
          password: 'vaagaiauto123',
          originalPassword: 'vaagaiauto123'
        });
        
        await admin.save();
        
        return res.json({
          success: true,
          user: {
            _id: admin._id,
            phoneNumber: admin.phoneNumber,
            userType: admin.userType,
            name: admin.name,
            password: admin.password,
            createdAt: admin.createdAt,
            updatedAt: admin.updatedAt
          },
          message: 'Admin account created successfully',
          defaultPassword: admin.password
        });
      }
      
      // If password is provided, verify it
      if (password) {
        // Check if admin.password exists and is not null/undefined
        if (!admin.password) {
          return res.status(500).json({
            success: false,
            message: 'Admin password not found in database. Please contact support.'
          });
        }

        let isPasswordValid = false;
        try {
          // Check if comparePassword method exists and works
          if (admin.comparePassword && typeof admin.comparePassword === 'function') {
            isPasswordValid = await admin.comparePassword(password);
          } else {
            // Fallback to direct comparison
            isPasswordValid = admin.password === password;
          }
        } catch (compareError) {
          console.error('Password comparison error:', compareError);
          // Fallback to direct string comparison
          isPasswordValid = admin.password === password;
        }

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
          password: admin.password,
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
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// Admin login function with password verification - FIXED
const adminLogin = async (req, res) => {
  try {
    const { phoneNumber, password } = req.body;

    console.log('Admin login attempt:', { phoneNumber, passwordProvided: !!password });

    if (!password) {
      return res.status(400).json({
        success: false,
        message: 'Password is required for admin login'
      });
    }

    // Find admin user
    const admin = await User.findOne({ 
      phoneNumber: phoneNumber, 
      userType: 'admin' 
    });

    console.log('Admin found:', !!admin);
    console.log('Admin password exists:', !!admin?.password);

    if (!admin) {
      return res.status(401).json({ 
        success: false,
        message: 'Admin not found' 
      });
    }

    // Check if admin password exists in database
    if (!admin.password) {
      console.error('Admin password is null/undefined in database');
      return res.status(500).json({
        success: false,
        message: 'Admin account configuration error. Please contact support.'
      });
    }

    let isPasswordValid = false;
    
    try {
      // Try using the static method first
      if (User.findAdminAndVerify && typeof User.findAdminAndVerify === 'function') {
        const verifiedAdmin = await User.findAdminAndVerify(phoneNumber, password);
        if (verifiedAdmin) {
          isPasswordValid = true;
        }
      } else if (admin.comparePassword && typeof admin.comparePassword === 'function') {
        // Try instance method
        isPasswordValid = await admin.comparePassword(password);
      } else {
        // Fallback to direct string comparison
        console.log('Using direct string comparison');
        isPasswordValid = admin.password === password;
      }
    } catch (compareError) {
      console.error('Password comparison error:', compareError);
      // Final fallback to direct comparison
      isPasswordValid = admin.password === password;
    }
    
    if (!isPasswordValid) {
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
        password: admin.password,
        createdAt: admin.createdAt,
        updatedAt: admin.updatedAt
      }
    });
    
  } catch (error) {
    console.error('Admin login error:', error);
    res.status(500).json({ 
      success: false,
      message: 'Internal server error' 
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
      admin: {
        phoneNumber: admin.phoneNumber,
        name: admin.name,
        password: admin.password,
        originalPassword: admin.originalPassword
      },
      defaultPassword: admin.getOriginalPassword ? admin.getOriginalPassword() : admin.password
    });
    
  } catch (error) {
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
};

// Force create/update admin account
const createAdminAccount = async (req, res) => {
  try {
    const { phoneNumber, name } = req.body;
    const adminName = name || 'Admin';
    
    // Check if admin already exists
    let admin = await User.findOne({ phoneNumber, userType: 'admin' });
    
    if (admin) {
      // Update existing admin with missing fields
      admin.name = adminName;
      admin.password = 'vaagaiauto123';
      admin.originalPassword = 'vaagaiauto123';
      await admin.save();
      
      return res.json({
        success: true,
        message: 'Admin account updated successfully',
        user: {
          _id: admin._id,
          phoneNumber: admin.phoneNumber,
          name: admin.name,
          userType: admin.userType,
          password: admin.password,
          originalPassword: admin.originalPassword,
          createdAt: admin.createdAt,
          updatedAt: admin.updatedAt
        }
      });
    }
    
    // Create new admin with explicit field assignment
    admin = new User({
      phoneNumber: phoneNumber,
      userType: 'admin',
      name: adminName,
      password: 'vaagaiauto123',
      originalPassword: 'vaagaiauto123'
    });
    
    await admin.save();
    
    res.status(201).json({
      success: true,
      message: 'Admin account created successfully',
      user: {
        _id: admin._id,
        phoneNumber: admin.phoneNumber,
        name: admin.name,
        userType: admin.userType,
        password: admin.password,
        originalPassword: admin.originalPassword,
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

// Fix existing admin account (add missing fields)
const fixAdminAccount = async (req, res) => {
  try {
    const { phoneNumber } = req.params;
    
    const admin = await User.findOne({ phoneNumber, userType: 'admin' });
    
    if (!admin) {
      return res.status(404).json({
        success: false,
        message: 'Admin not found'
      });
    }
    
    // Update missing fields
    let updated = false;
    
    if (!admin.name) {
      admin.name = 'Admin';
      updated = true;
    }
    
    if (!admin.password) {
      admin.password = 'vaagaiauto123';
      updated = true;
    }
    
    if (!admin.originalPassword) {
      admin.originalPassword = 'vaagaiauto123';
      updated = true;
    }
    
    if (updated) {
      await admin.save();
    }
    
    res.json({
      success: true,
      message: updated ? 'Admin account fixed successfully' : 'Admin account is already complete',
      user: {
        _id: admin._id,
        phoneNumber: admin.phoneNumber,
        name: admin.name,
        userType: admin.userType,
        password: admin.password,
        originalPassword: admin.originalPassword,
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

// NEW: Update admin profile - FIXED
const updateAdminProfile = async (req, res) => {
  try {
    const { phoneNumber } = req.params;
    const { name, phoneNumber: newPhoneNumber, password } = req.body;

    console.log('Update admin profile request:', { phoneNumber, name, newPhoneNumber });

    // First find the admin
    const admin = await User.findOne({ 
      phoneNumber: phoneNumber, 
      userType: 'admin' 
    });

    if (!admin) {
      return res.status(404).json({ 
        success: false, 
        message: 'Admin not found' 
      });
    }

    // Check if admin password exists in database
    if (!admin.password) {
      console.error('Admin password is null/undefined in database during update');
      return res.status(500).json({
        success: false,
        message: 'Admin account configuration error. Please contact support.'
      });
    }

    // Verify password
    let isPasswordValid = false;
    
    try {
      if (admin.comparePassword && typeof admin.comparePassword === 'function') {
        isPasswordValid = await admin.comparePassword(password);
      } else {
        // Fallback to direct comparison
        isPasswordValid = admin.password === password;
      }
    } catch (compareError) {
      console.error('Password comparison error during update:', compareError);
      // Fallback to direct comparison
      isPasswordValid = admin.password === password;
    }

    if (!isPasswordValid) {
      return res.status(401).json({ 
        success: false, 
        message: 'Invalid password' 
      });
    }

    // Check if new phone number is already taken by another user
    if (newPhoneNumber !== phoneNumber) {
      const existingUser = await User.findOne({ 
        phoneNumber: newPhoneNumber,
        _id: { $ne: admin._id } // Exclude current admin
      });
      
      if (existingUser) {
        return res.status(400).json({
          success: false,
          message: 'Phone number is already registered'
        });
      }
    }

    // Update the admin profile
    const updateData = {
      name: name,
      phoneNumber: newPhoneNumber,
      updatedAt: new Date()
    };

    const updatedAdmin = await User.findOneAndUpdate(
      { phoneNumber: phoneNumber, userType: 'admin' },
      { $set: updateData },
      { new: true }
    );

    if (!updatedAdmin) {
      return res.status(500).json({ 
        success: false, 
        message: 'Failed to update profile' 
      });
    }

    res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      user: {
        _id: updatedAdmin._id,
        name: updatedAdmin.name,
        phoneNumber: updatedAdmin.phoneNumber,
        userType: updatedAdmin.userType,
        password: updatedAdmin.password,
        originalPassword: updatedAdmin.originalPassword,
        createdAt: updatedAdmin.createdAt,
        updatedAt: updatedAdmin.updatedAt
      }
    });

  } catch (error) {
    console.error('Update admin profile error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Internal server error' 
    });
  }
};

module.exports = {
  login,
  adminLogin,
  getAdminPassword,
  createAdminAccount,
  fixAdminAccount,
  updateAdminProfile
};
