const express = require('express');
const { login, adminLogin, getAdminPassword } = require('../controllers/authController');
const { validateLogin, validateAdminLogin } = require('../middleware/validation');

const router = express.Router();

// Original login route (for both admin without password and drivers)
router.post('/login', validateLogin, login);

// New admin login route with password verification
router.post('/admin-login', validateAdminLogin, adminLogin);
router.post('/admin-login', validateAdminLogin, adminLogin);
router.get('/admin/:phoneNumber/password', validatePhoneNumberParam, getAdminPassword);

// Future password change route
router.put('/admin/change-password', validatePasswordChange, changeAdminPassword);

// Route to get admin default password (use with caution)
router.get('/admin/:phoneNumber/password', getAdminPassword);

module.exports = router;
