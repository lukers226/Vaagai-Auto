const express = require('express');
const { login, getAdminProfile, updateAdminProfile } = require('../controllers/authController');
const { validateLogin, validateUserId, validateAdminProfileUpdate } = require('../middleware/validation');

const router = express.Router();

router.post('/login', validateLogin, login);

// NEW: Admin profile routes
router.get('/admin/:adminId', validateUserId, getAdminProfile);
router.put('/admin/:adminId', validateUserId, validateAdminProfileUpdate, updateAdminProfile);

module.exports = router;
