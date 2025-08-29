const express = require('express');
const { 
  addDriver, 
  getDrivers, 
  updateDriverEarnings, 
  updateDriverRide,
  getDriverStats 
} = require('../controllers/adminController');
const { 
  validateAddDriver, 
  validateUpdateEarnings, 
  validateUpdateRide 
} = require('../middleware/validation');

const router = express.Router();

// Existing routes
router.post('/add-driver', validateAddDriver, addDriver);
router.get('/drivers', getDrivers);
router.get('/driver/:id/stats', getDriverStats);
router.put('/driver/:id/earnings', validateUpdateEarnings, updateDriverEarnings);
router.put('/driver/:id/ride', validateUpdateRide, updateDriverRide);

module.exports = router;
