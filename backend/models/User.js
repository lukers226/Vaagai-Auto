const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const ADMIN_DEFAULT_PASSWORD = 'vaagaiauto123';

const userSchema = new mongoose.Schema({
  phoneNumber: {
    type: String,
    required: true,
    unique: true,
    match: /^[0-9]{10}$/
  },
  userType: {
    type: String,
    enum: ['admin', 'driver'],
    required: true
  },
  name: {
    type: String,
    required: function() {
      return this.userType === 'driver' || this.userType === 'admin';
    }
  },
  password: {
    type: String,
    required: function() {
      return this.userType === 'admin';
    }
    // Removed select: false completely
  },
  // Store hashed password for authentication
  hashedPassword: {
    type: String,
    select: false,
    required: function() {
      return this.userType === 'admin';
    }
  },
  // Store original password for reference
  originalPassword: {
    type: String,
    required: function() {
      return this.userType === 'admin';
    }
  }
}, {
  timestamps: true
});

// Pre-save middleware to handle password hashing and defaults
userSchema.pre('save', async function(next) {
  try {
    // Set defaults for admin users
    if (this.userType === 'admin') {
      // Set name if not provided
      if (!this.name) {
        this.name = 'Admin';
      }
      
      // Set password if not provided
      if (!this.password) {
        this.password = ADMIN_DEFAULT_PASSWORD;
      }
      
      // Set originalPassword
      if (!this.originalPassword) {
        this.originalPassword = this.password;
      }
      
      // Only hash password if it's modified
      if (this.isModified('password') || this.isNew) {
        const saltRounds = 12;
        this.hashedPassword = await bcrypt.hash(this.password, saltRounds);
      }
    }
    
    next();
  } catch (error) {
    return next(error);
  }
});

// Method to compare password for authentication
userSchema.methods.comparePassword = async function(candidatePassword) {
  if (this.userType !== 'admin') {
    return false;
  }
  return await bcrypt.compare(candidatePassword, this.hashedPassword);
};

// Method to get original password
userSchema.methods.getOriginalPassword = function() {
  if (this.userType === 'admin') {
    return this.originalPassword || this.password;
  }
  return null;
};

// Static method to find admin by phone and verify password
userSchema.statics.findAdminAndVerify = async function(phoneNumber, password) {
  const admin = await this.findOne({ 
    phoneNumber, 
    userType: 'admin' 
  }).select('+hashedPassword');
  
  if (!admin) {
    return null;
  }
  
  const isMatch = await admin.comparePassword(password);
  return isMatch ? admin : null;
};

// Static method to create admin with all required fields
userSchema.statics.createAdmin = async function(phoneNumber, name = 'Admin') {
  const admin = new this({
    phoneNumber: phoneNumber,
    userType: 'admin',
    name: name,
    password: ADMIN_DEFAULT_PASSWORD,
    originalPassword: ADMIN_DEFAULT_PASSWORD
  });
  
  return await admin.save();
};

module.exports = mongoose.model('User', userSchema);
