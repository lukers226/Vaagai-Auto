const express = require('express');
const { 
  cancelRide, 
  completeRide, 
  getDriverStats,
  debugDriverRecords 
} = require('../controllers/rideController');
const { 
  validateRideCompletion,
  validateUserId 
} = require('../middleware/validation');

const router = express.Router();

// Debug middleware to log all requests
router.use((req, res, next) => {
  console.log(`[RIDES ROUTE] ${req.method} ${req.originalUrl}`);
  console.log(`[RIDES ROUTE] Params:`, req.params);
  console.log(`[RIDES ROUTE] Body:`, req.body);
  next();
});

// Cancel ride endpoint
router.patch('/:userId/cancel-ride', validateUserId, cancelRide);

// Complete ride endpoint
router.patch('/:userId/complete-ride', validateUserId, validateRideCompletion, completeRide);

// Get driver stats endpoint
router.get('/:userId/stats', validateUserId, getDriverStats);

// DEBUG: Check driver records (remove in production)
router.get('/:userId/debug', debugDriverRecords);

module.exports = router;
