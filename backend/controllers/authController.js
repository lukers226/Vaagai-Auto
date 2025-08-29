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
        // Auto-update existing admin if missing fields
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
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// Get admin profile
const getAdminProfile = async (req, res) => {
  try {
    console.log('🔵 getAdminProfile function called');
    
    // Find the single admin user
    const admin = await User.findOne({ userType: 'admin' });
    
    if (!admin) {
      console.log('❌ No admin found in database');
      return res.status(404).json({
        success: false,
        message: 'Admin profile not found'
      });
    }

    console.log('✅ Admin found:', {
      id: admin._id,
      name: admin.name,
      phoneNumber: admin.phoneNumber,
      userType: admin.userType
    });

    const responseData = {
      success: true,
      data: {
        _id: admin._id,
        phoneNumber: admin.phoneNumber,
        userType: admin.userType,
        name: admin.name || 'admin',
        password: admin.password || '123',
        createdAt: admin.createdAt,
        updatedAt: admin.updatedAt
      }
    };

    console.log('📤 Sending response:', JSON.stringify(responseData, null, 2));
    res.status(200).json(responseData);

  } catch (error) {
    console.error('❌ Get admin profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error while fetching admin profile',
      error: error.message
    });
  }
};

// Update admin profile
const updateAdminProfile = async (req, res) => {
  try {
    const { name, phoneNumber, password } = req.body;
    
    console.log('🔵 updateAdminProfile function called');
    console.log('📥 Request data:', { name, phoneNumber, password: password ? '***' : undefined });

    // Find the single admin user
    const admin = await User.findOne({ userType: 'admin' });
    
    if (!admin) {
      console.log('❌ No admin found for update');
      return res.status(404).json({
        success: false,
        message: 'Admin profile not found'
      });
    }

    console.log('✅ Admin found for update:', {
      id: admin._id,
      currentName: admin.name,
      currentPhone: admin.phoneNumber
    });

    // Update fields
    if (name !== undefined && name !== null) {
      admin.name = name.trim();
      console.log('📝 Updated name:', admin.name);
    }
    
    if (phoneNumber !== undefined && phoneNumber !== null) {
      admin.phoneNumber = phoneNumber.trim();
      console.log('📝 Updated phone:', admin.phoneNumber);
    }
    
    if (password !== undefined && password !== null) {
      admin.password = password;
      console.log('📝 Updated password: ***');
    }

    admin.updatedAt = new Date();
    await admin.save();

    const responseData = {
      success: true,
      message: 'Admin profile updated successfully',
      data: {
        _id: admin._id,
        phoneNumber: admin.phoneNumber,
        userType: admin.userType,
        name: admin.name,
        password: admin.password,
        createdAt: admin.createdAt,
        updatedAt: admin.updatedAt
      }
    };

    console.log('✅ Admin profile updated successfully');
    console.log('📤 Sending response:', JSON.stringify(responseData, null, 2));
    
    res.status(200).json(responseData);

  } catch (error) {
    console.error('❌ Update admin profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error while updating admin profile',
      error: error.message
    });
  }
};

module.exports = {
  login,
  getAdminProfile,
  updateAdminProfile
};
