const mongoose = require('mongoose');

const fareSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true // Each user can only have one fare configuration
  },
  baseFare: {
    type: Number,
    required: true,
    min: 0
  },
  waiting5min: {
    type: Number,
    default: 0,
    min: 0
  },
  waiting10min: {
    type: Number,
    default: 0,
    min: 0
  },
  waiting15min: {
    type: Number,
    default: 0,
    min: 0
  },
  waiting20min: {
    type: Number,
    default: 0,
    min: 0
  },
  waiting25min: {
    type: Number,
    default: 0,
    min: 0
  },
  waiting30min: {
    type: Number,
    default: 0,
    min: 0
  },
  isActive: {
    type: Boolean,
    default: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Update the updatedAt field before saving
fareSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

module.exports = mongoose.model('Fare', fareSchema);
