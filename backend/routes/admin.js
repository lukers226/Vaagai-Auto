const express = require('express');
const { addDriver, getDrivers } = require('../controllers/adminController');
const { validateAddDriver } = require('../middleware/validation');

const router = express.Router();

router.post('/add-driver', validateAddDriver, addDriver);
router.get('/drivers', getDrivers);

module.exports = router;
