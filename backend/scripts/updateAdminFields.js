const mongoose = require('mongoose');
require('dotenv').config();

const User = require('../models/User');

const updateExistingAdmin = async () => {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Update existing admin record
    const result = await User.updateOne(
      { 
        phoneNumber: "9876543210", 
        userType: "admin" 
      },
      { 
        $set: { 
          name: "admin", 
          password: "123" 
        } 
      }
    );

    console.log('Update result:', result);
    
    if (result.modifiedCount > 0) {
      console.log('✅ Admin record updated successfully');
      
      // Verify the update
      const updatedAdmin = await User.findOne({ phoneNumber: "9876543210", userType: "admin" });
      console.log('Updated admin:', updatedAdmin);
    } else {
      console.log('⚠️ No admin record was modified');
    }

  } catch (error) {
    console.error('❌ Error updating admin:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
};

updateExistingAdmin();
