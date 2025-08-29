const express = require('express');
const { login, getAdminProfile, updateAdminProfile } = require('../controllers/authController');
const { validateLogin, validateAdminProfileUpdate } = require('../middleware/validation');

const router = express.Router();

// Test route to verify this router is working
router.get('/test', (req, res) => {
  res.json({
    message: 'Auth router is working!',
    timestamp: new Date().toISOString(),
    version: '1.0.1'
  });
});

// POST route for proper API calls
router.post('/login', validateLogin, login);

// GET route for browser testing - TEMPORARY
router.get('/login/:phoneNumber', async (req, res) => {
  try {
    const { phoneNumber } = req.params;
    
    if (!/^[0-9]{10}$/.test(phoneNumber)) {
      return res.status(400).json({
        success: false,
        message: 'Phone number must be 10 digits'
      });
    }

    req.body = { phoneNumber };
    return login(req, res);
    
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

// Admin profile routes - These create /api/auth/admin
router.get('/admin', (req, res, next) => {
  console.log('🔵 GET /admin route hit - auth router working');
  getAdminProfile(req, res, next);
});

router.put('/admin', (req, res, next) => {
  console.log('🔵 PUT /admin route hit - auth router working');
  console.log('Request body:', req.body);
  next();
}, validateAdminProfileUpdate, updateAdminProfile);

module.exports = router;
