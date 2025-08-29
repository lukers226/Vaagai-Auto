const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  phoneNumber: {
    type: String,
    required: true,
    unique: true,
    validate: {
      validator: function(v) {
        return /^[0-9]{10}$/.test(v);
      },
      message: 'Phone number must be 10 digits'
    }
  },
  name: {
    type: String,
    required: true,
    trim: true,
    minlength: 2,
    maxlength: 50
  },
  password: {
    type: String,
    required: function() {
      return this.userType === 'admin';
    },
    minlength: 6
  },
  originalPassword: {
    type: String,
    default: null
  },
  userType: {
    type: String,
    required: true,
    enum: ['driver', 'admin'],
    default: 'driver'
  },
  // Driver specific fields
  totalEarnings: {
    type: Number,
    default: 0,
    min: 0
  },
  currentRideStatus: {
    type: String,
    enum: ['available', 'busy', 'offline'],
    default: 'available'
  },
  rideHistory: [{
    rideId: String,
    date: Date,
    earnings: Number,
    status: {
      type: String,
      enum: ['completed', 'cancelled']
    },
    tripData: {
      distance: Number,
      duration: Number,
      baseFare: Number,
      distanceCharge: Number,
      timeCharge: Number,
      waitingCharge: Number,
      totalFare: Number,
      pickupLocation: String,
      dropoffLocation: String
    }
  }],
  // Admin specific fields
  isActive: {
    type: Boolean,
    default: true
  },
  lastLogin: {
    type: Date,
    default: null
  },
  // Common fields
  profilePicture: {
    type: String,
    default: null
  },
  isOnline: {
    type: Boolean,
    default: false
  }
}, {
  timestamps: true,
  collection: 'users'
});

// Pre-save middleware to hash passwords (only if password is modified and is plain text)
userSchema.pre('save', async function(next) {
  try {
    // Only hash the password if it has been modified (or is new)
    if (!this.isModified('password')) return next();
    
    // Skip hashing if password is already hashed (starts with $2a, $2b, or $2y)
    if (this.password && this.password.startsWith('$2')) {
      return next();
    }
    
    // Only hash if we have a password to hash
    if (this.password && this.password.length > 0) {
      const saltRounds = 10;
      
      // Store original password before hashing (for admin accounts)
      if (this.userType === 'admin' && !this.originalPassword) {
        this.originalPassword = this.password;
      }
      
      // Hash the password
      this.password = await bcrypt.hash(this.password, saltRounds);
    }
    
    next();
  } catch (error) {
    console.error('Error in pre-save password hashing:', error);
    next(error);
  }
});

// Instance method to compare passwords
userSchema.methods.comparePassword = async function(candidatePassword) {
  try {
    // If no password is set, return false
    if (!this.password) {
      console.error('No password found in database for user:', this.phoneNumber);
      return false;
    }
    
    // If password is not hashed (plain text), do direct comparison
    if (!this.password.startsWith('$2')) {
      console.log('Using direct password comparison for user:', this.phoneNumber);
      return this.password === candidatePassword;
    }
    
    // Use bcrypt for hashed passwords
    console.log('Using bcrypt comparison for user:', this.phoneNumber);
    return await bcrypt.compare(candidatePassword, this.password);
    
  } catch (error) {
    console.error('Error in comparePassword for user', this.phoneNumber, ':', error);
    // Fallback to direct comparison if bcrypt fails
    return this.password === candidatePassword;
  }
};

// Static method to find admin and verify password
userSchema.statics.findAdminAndVerify = async function(phoneNumber, password) {
  try {
    const admin = await this.findOne({ 
      phoneNumber: phoneNumber, 
      userType: 'admin' 
    });
    
    if (!admin) {
      console.log('Admin not found with phone number:', phoneNumber);
      return null;
    }
    
    console.log('Admin found, verifying password...');
    const isValid = await admin.comparePassword(password);
    
    if (isValid) {
      console.log('Password verification successful for admin:', phoneNumber);
      return admin;
    } else {
      console.log('Password verification failed for admin:', phoneNumber);
      return null;
    }
    
  } catch (error) {
    console.error('Error in findAdminAndVerify:', error);
    return null;
  }
};

// Instance method to get original password (for admin accounts)
userSchema.methods.getOriginalPassword = function() {
  return this.originalPassword || this.password;
};

// Instance method to update earnings (for drivers)
userSchema.methods.updateEarnings = function(amount) {
  if (this.userType === 'driver') {
    this.totalEarnings += amount;
    return this.save();
  }
  throw new Error('Only drivers can update earnings');
};

// Instance method to add ride to history (for drivers)
userSchema.methods.addRideToHistory = function(rideData) {
  if (this.userType === 'driver') {
    this.rideHistory.push({
      rideId: rideData.rideId || new mongoose.Types.ObjectId().toString(),
      date: new Date(),
      earnings: rideData.earnings,
      status: rideData.status,
      tripData: rideData.tripData || {}
    });
    
    // Update total earnings
    this.totalEarnings += rideData.earnings;
    
    return this.save();
  }
  throw new Error('Only drivers can add ride history');
};

// Instance method to update ride status (for drivers)
userSchema.methods.updateRideStatus = function(status) {
  if (this.userType === 'driver') {
    this.currentRideStatus = status;
    return this.save();
  }
  throw new Error('Only drivers can update ride status');
};

// Instance method to update last login (for admins)
userSchema.methods.updateLastLogin = function() {
  if (this.userType === 'admin') {
    this.lastLogin = new Date();
    return this.save();
  }
  throw new Error('Only admins can update last login');
};

// Static method to create admin account
userSchema.statics.createAdminAccount = async function(phoneNumber, name = 'Admin', password = 'vaagaiauto123') {
  try {
    // Check if admin already exists
    let admin = await this.findOne({ phoneNumber, userType: 'admin' });
    
    if (admin) {
      // Update existing admin
      admin.name = name;
      admin.password = password;
      admin.originalPassword = password;
      await admin.save();
      return admin;
    }
    
    // Create new admin
    admin = new this({
      phoneNumber: phoneNumber,
      userType: 'admin',
      name: name,
      password: password,
      originalPassword: password,
      isActive: true
    });
    
    await admin.save();
    return admin;
    
  } catch (error) {
    console.error('Error creating admin account:', error);
    throw error;
  }
};

// Virtual for full profile
userSchema.virtual('profile').get(function() {
  const profile = {
    _id: this._id,
    phoneNumber: this.phoneNumber,
    name: this.name,
    userType: this.userType,
    isActive: this.isActive,
    isOnline: this.isOnline,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt
  };
  
  if (this.userType === 'driver') {
    profile.totalEarnings = this.totalEarnings;
    profile.currentRideStatus = this.currentRideStatus;
    profile.totalRides = this.rideHistory.length;
  }
  
  if (this.userType === 'admin') {
    profile.lastLogin = this.lastLogin;
  }
  
  return profile;
});

// Index for better query performance
userSchema.index({ phoneNumber: 1, userType: 1 });
userSchema.index({ userType: 1, isActive: 1 });

// Ensure virtual fields are serialized
userSchema.set('toJSON', {
  virtuals: true,
  transform: function(doc, ret) {
    // Remove sensitive information from JSON output
    delete ret.password;
    delete ret.originalPassword;
    delete ret.__v;
    return ret;
  }
});

// Export the model
module.exports = mongoose.model('User', userSchema);
