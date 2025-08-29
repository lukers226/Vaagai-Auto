const express = require('express');
const { 
  login, 
  adminLogin, 
  getAdminPassword, 
  createAdminAccount,
  fixAdminAccount
} = require('../controllers/authController');
const { 
  validateLogin, 
  validateAdminLogin, 
  validatePhoneNumberParam,
  validateAddDriver 
} = require('../middleware/validation');

const router = express.Router();

// Original login route
router.post('/login', validateLogin, login);

// Admin login route with password verification
router.post('/admin-login', validateAdminLogin, adminLogin);

// Route to get admin default password
router.get('/admin/:phoneNumber/password', validatePhoneNumberParam, getAdminPassword);

// Route to manually create admin account
router.post('/create-admin', validateAddDriver, createAdminAccount);

// Route to fix existing admin account (add missing fields)
router.put('/admin/:phoneNumber/fix', validatePhoneNumberParam, fixAdminAccount);

module.exports = router;
