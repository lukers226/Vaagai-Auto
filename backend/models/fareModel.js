const mongoose = require('mongoose');

const fareSchema = new mongoose.Schema({
  // Remove userId requirement - make it admin-based system-wide fare
  adminId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'Admin ID is required']
  },
  baseFare: {
    type: Number,
    required: [true, 'Base fare is required'],
    min: [1, 'Base fare must be at least 1']
  },
  waiting5min: {
    type: Number,
    default: 0,
    min: [0, 'Waiting charge cannot be negative']
  },
  waiting10min: {
    type: Number,
    default: 0,
    min: [0, 'Waiting charge cannot be negative']
  },
  waiting15min: {
    type: Number,
    default: 0,
    min: [0, 'Waiting charge cannot be negative']
  },
  waiting20min: {
    type: Number,
    default: 0,
    min: [0, 'Waiting charge cannot be negative']
  },
  waiting25min: {
    type: Number,
    default: 0,
    min: [0, 'Waiting charge cannot be negative']
  },
  waiting30min: {
    type: Number,
    default: 0,
    min: [0, 'Waiting charge cannot be negative']
  },
  isActive: {
    type: Boolean,
    default: true
  },
  isSystemDefault: {
    type: Boolean,
    default: true // Only one system-wide fare configuration
  }
}, {
  timestamps: true,
  collection: 'fares'
});

// Ensure only one active system fare exists
fareSchema.index({ isSystemDefault: 1, isActive: 1 }, { 
  unique: true,
  partialFilterExpression: { isSystemDefault: true, isActive: true }
});

module.exports = mongoose.model('Fare', fareSchema);
