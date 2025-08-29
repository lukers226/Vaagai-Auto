const express = require('express');
const { 
  login, 
  adminLogin, 
  getAdminPassword, 
  createAdminAccount 
} = require('../controllers/authController');
const { 
  validateLogin, 
  validateAdminLogin, 
  validatePhoneNumberParam,
  validateAddDriver 
} = require('../middleware/validation');

const router = express.Router();

// Original login route (for both admin without password and drivers)
router.post('/login', validateLogin, login);

// Admin login route with password verification
router.post('/admin-login', validateAdminLogin, adminLogin);

// Route to get admin default password
router.get('/admin/:phoneNumber/password', validatePhoneNumberParam, getAdminPassword);

// Route to manually create admin account (for testing/setup)
router.post('/create-admin', validateAddDriver, createAdminAccount);

module.exports = router;
