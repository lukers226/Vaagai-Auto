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
    },
    select: false, // This prevents password from being returned in queries by default
    default: function() {
      return this.userType === 'admin' ? ADMIN_DEFAULT_PASSWORD : undefined;
    }
  },
  // Store original password for admin (as per your requirement)
  originalPassword: {
    type: String,
    required: function() {
      return this.userType === 'admin';
    },
    default: function() {
      return this.userType === 'admin' ? ADMIN_DEFAULT_PASSWORD : undefined;
    }
  }
}, {
  timestamps: true
});

// Pre-save middleware to handle password hashing and default password
userSchema.pre('save', async function(next) {
  try {
    // If this is a new admin user and no password is set, use default
    if (this.isNew && this.userType === 'admin' && !this.password) {
      this.password = ADMIN_DEFAULT_PASSWORD;
      this.originalPassword = ADMIN_DEFAULT_PASSWORD;
    }
    
    // Only hash password if it's modified and user is admin
    if (this.isModified('password') && this.userType === 'admin') {
      // Store original password (as per your requirement to show original string)
      this.originalPassword = this.password;
      
      // Hash the password for security (recommended for actual authentication)
      const saltRounds = 12;
      this.password = await bcrypt.hash(this.password, saltRounds);
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
  return await bcrypt.compare(candidatePassword, this.password);
};

// Method to get original password (use carefully - security risk)
userSchema.methods.getOriginalPassword = function() {
  if (this.userType === 'admin') {
    return this.originalPassword;
  }
  return null;
};

// Static method to find admin by phone and verify password
userSchema.statics.findAdminAndVerify = async function(phoneNumber, password) {
  const admin = await this.findOne({ 
    phoneNumber, 
    userType: 'admin' 
  }).select('+password');
  
  if (!admin) {
    return null;
  }
  
  const isMatch = await admin.comparePassword(password);
  return isMatch ? admin : null;
};

// Static method to create admin with default password
userSchema.statics.createAdmin = async function(phoneNumber, name) {
  const admin = new this({
    phoneNumber,
    name,
    userType: 'admin',
    password: ADMIN_DEFAULT_PASSWORD
  });
  
  return await admin.save();
};

module.exports = mongoose.model('User', userSchema);
