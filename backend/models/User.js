const mongoose = require('mongoose');

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
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('User', userSchema);
