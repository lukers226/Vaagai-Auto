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

// Debug middleware to log all requests
router.use((req, res, next) => {
  console.log(`[RIDES ROUTE] ${req.method} ${req.originalUrl}`);
  console.log(`[RIDES ROUTE] Params:`, req.params);
  console.log(`[RIDES ROUTE] Body:`, req.body);
  next();
});

// Cancel ride endpoint - PATCH /:userId/cancel-ride
router.patch('/:userId/cancel-ride', validateUserId, cancelRide);

// Complete ride endpoint - PATCH /:userId/complete-ride
router.patch('/:userId/complete-ride', validateUserId, validateRideCompletion, completeRide);

// Get driver stats endpoint - GET /:userId/stats
router.get('/:userId/stats', validateUserId, getDriverStats);

module.exports = router;
