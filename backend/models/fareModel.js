const mongoose = require('mongoose');

const fareSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'User ID is required'],
    index: true // Add index for better performance
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
  }
}, {
  timestamps: true, // This will automatically create createdAt and updatedAt
  collection: 'fares' // Explicitly set collection name
});

// Create unique compound index to ensure one fare per user
fareSchema.index({ userId: 1 }, { unique: true });

// Add pre-save middleware for debugging
fareSchema.pre('save', function(next) {
  console.log('About to save fare document:', this.toObject());
  next();
});

// Add post-save middleware for debugging
fareSchema.post('save', function(doc) {
  console.log('Successfully saved fare document:', doc.toObject());
});

module.exports = mongoose.model('Fare', fareSchema);
