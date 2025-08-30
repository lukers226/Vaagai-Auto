const mongoose = require('mongoose');

const fareSchema = new mongoose.Schema({
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
  perKmRate: {
    type: Number,
    required: [true, 'Per kilometer rate is required'],
    min: [0.1, 'Per kilometer rate must be at least 0.1'],
    max: [1000, 'Per kilometer rate cannot exceed 1000']
  },
  waiting60min: {
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
    default: true
  }
}, {
  timestamps: true,
  collection: 'fares'
});

fareSchema.index({ isSystemDefault: 1, isActive: 1 }, { 
  unique: true,
  partialFilterExpression: { isSystemDefault: true, isActive: true }
});

module.exports = mongoose.model('Fare', fareSchema);
