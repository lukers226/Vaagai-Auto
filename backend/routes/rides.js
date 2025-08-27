const express = require('express');
const { 
  cancelRide, 
  completeRide, 
  getDriverStats 
} = require('../controllers/rideController');
const { 
  validateRideCompletion,
  validateUserId 
} = require('../middleware/validation');

const router = express.Router();

// Cancel ride endpoint - with user ID validation
router.patch('/:userId/cancel-ride', validateUserId, cancelRide);

// Complete ride endpoint - with user ID and ride completion validation
router.patch('/:userId/complete-ride', validateUserId, validateRideCompletion, completeRide);

// Get driver stats endpoint - with user ID validation
router.get('/:userId/stats', validateUserId, getDriverStats);

module.exports = router;
