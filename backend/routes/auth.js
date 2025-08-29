const express = require('express');
const { login, getAdminProfile, updateAdminProfile } = require('../controllers/authController');
const { validateLogin, validateAdminProfileUpdate } = require('../middleware/validation');

const router = express.Router();

// POST route for proper API calls
router.post('login', validateLogin, login); // Remove leading slash

// GET route for browser testing - TEMPORARY
router.get('login/:phoneNumber', async (req, res) => { // Remove leading slash
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

// Admin profile routes - Remove leading slashes
router.get('admin', getAdminProfile); // This becomes /api/auth/admin
router.put('admin', validateAdminProfileUpdate, updateAdminProfile); // This becomes /api/auth/admin

module.exports = router;
