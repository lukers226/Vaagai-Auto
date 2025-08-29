const validateLogin = (req, res, next) => {
  const { phoneNumber } = req.body;

  if (!phoneNumber) {
    return res.status(400).json({
      success: false,
      message: 'Phone number is required'
    });
  }

  if (!/^[0-9]{10}$/.test(phoneNumber)) {
    return res.status(400).json({
      success: false,
      message: 'Phone number must be 10 digits'
    });
  }

  next();
};

// Validate admin login with password
const validateAdminLogin = (req, res, next) => {
  const { phoneNumber, password } = req.body;
  
  if (!phoneNumber) {
    return res.status(400).json({
      success: false,
      message: 'Phone number is required'
    });
  }
  
  if (!password) {
    return res.status(400).json({
      success: false,
      message: 'Password is required for admin login'
    });
  }
  
  // Validate phone number format
  if (!/^[0-9]{10}$/.test(phoneNumber)) {
    return res.status(400).json({
      success: false,
      message: 'Phone number must be 10 digits'
    });
  }
  
  // Basic password validation
  if (typeof password !== 'string' || password.length < 6) {
    return res.status(400).json({
      success: false,
      message: 'Password must be at least 6 characters long'
    });
  }
  
  next();
};

const validateAddDriver = (req, res, next) => {
  const { name, phoneNumber } = req.body;

  if (!name || !phoneNumber) {
    return res.status(400).json({
      success: false,
      message: 'Name and phone number are required'
    });
  }

  if (name.length < 2) {
    return res.status(400).json({
      success: false,
      message: 'Name must be at least 2 characters'
    });
  }

  if (!/^[0-9]{10}$/.test(phoneNumber)) {
    return res.status(400).json({
      success: false,
      message: 'Phone number must be 10 digits'
    });
  }

  next();
};

const validateUpdateEarnings = (req, res, next) => {
  const { amount } = req.body;

  if (!amount && amount !== 0) {
    return res.status(400).json({
      success: false,
      message: 'Amount is required'
    });
  }

  if (typeof amount !== 'number' || amount < 0) {
    return res.status(400).json({
      success: false,
      message: 'Amount must be a positive number'
    });
  }

  next();
};

const validateUpdateRide = (req, res, next) => {
  const { status } = req.body;

  if (!status) {
    return res.status(400).json({
      success: false,
      message: 'Ride status is required'
    });
  }

  if (!['completed', 'cancelled'].includes(status)) {
    return res.status(400).json({
      success: false,
      message: 'Status must be either "completed" or "cancelled"'
    });
  }

  next();
};

// Validate ride completion data
const validateRideCompletion = (req, res, next) => {
  const { rideEarnings, tripData } = req.body;
  
  // Validate ride earnings
  if (!rideEarnings && rideEarnings !== 0) {
    return res.status(400).json({ 
      success: false,
      message: 'Ride earnings is required' 
    });
  }
  
  if (typeof rideEarnings !== 'number' || rideEarnings <= 0) {
    return res.status(400).json({ 
      success: false,
      message: 'Ride earnings must be a positive number' 
    });
  }
  
  if (rideEarnings > 10000) { // Reasonable upper limit for safety
    return res.status(400).json({ 
      success: false,
      message: 'Ride earnings seems too high (max: ₹10,000)' 
    });
  }
  
  // Validate trip data (optional but recommended)
  if (tripData) {
    // Check for required trip data fields
    const requiredFields = ['distance', 'duration', 'totalFare'];
    for (const field of requiredFields) {
      if (!tripData[field] && tripData[field] !== 0) {
        return res.status(400).json({ 
          success: false,
          message: `Trip data missing required field: ${field}` 
        });
      }
    }
    
    // Validate specific trip data fields
    if (tripData.totalFare && typeof tripData.totalFare !== 'number') {
      return res.status(400).json({ 
        success: false,
        message: 'Trip total fare must be a number' 
      });
    }
    
    if (tripData.baseFare && typeof tripData.baseFare !== 'number') {
      return res.status(400).json({ 
        success: false,
        message: 'Trip base fare must be a number' 
      });
    }
    
    if (tripData.waitingCharge && typeof tripData.waitingCharge !== 'number') {
      return res.status(400).json({ 
        success: false,
        message: 'Trip waiting charge must be a number' 
      });
    }
    
    // Ensure trip total fare matches ride earnings
    if (tripData.totalFare && Math.abs(tripData.totalFare - rideEarnings) > 0.01) {
      return res.status(400).json({ 
        success: false,
        message: 'Trip total fare must match ride earnings' 
      });
    }
  }
  
  next();
};

// Validate user ID parameter
const validateUserId = (req, res, next) => {
  const { userId } = req.params;
  
  if (!userId) {
    return res.status(400).json({
      success: false,
      message: 'User ID is required'
    });
  }
  
  if (userId === 'undefined' || userId === 'null') {
    return res.status(400).json({
      success: false,
      message: 'Invalid user ID provided'
    });
  }
  
  // Basic MongoDB ObjectId format validation (24 character hex string)
  if (!/^[a-fA-F0-9]{24}$/.test(userId)) {
    return res.status(400).json({
      success: false,
      message: 'Invalid user ID format'
    });
  }
  
  next();
};

// Validate phone number parameter for admin password retrieval
const validatePhoneNumberParam = (req, res, next) => {
  const { phoneNumber } = req.params;
  
  if (!phoneNumber) {
    return res.status(400).json({
      success: false,
      message: 'Phone number is required'
    });
  }
  
  if (!/^[0-9]{10}$/.test(phoneNumber)) {
    return res.status(400).json({
      success: false,
      message: 'Phone number must be 10 digits'
    });
  }
  
  next();
};

// Validate password change request
const validatePasswordChange = (req, res, next) => {
  const { currentPassword, newPassword } = req.body;
  
  if (!currentPassword) {
    return res.status(400).json({
      success: false,
      message: 'Current password is required'
    });
  }
  
  if (!newPassword) {
    return res.status(400).json({
      success: false,
      message: 'New password is required'
    });
  }
  
  if (typeof newPassword !== 'string' || newPassword.length < 6) {
    return res.status(400).json({
      success: false,
      message: 'New password must be at least 6 characters long'
    });
  }
  
  if (currentPassword === newPassword) {
    return res.status(400).json({
      success: false,
      message: 'New password must be different from current password'
    });
  }
  
  next();
};

// NEW: Validate update admin request
const validateUpdateAdmin = (req, res, next) => {
  const { name, phoneNumber, password } = req.body;
  const { phoneNumber: paramPhoneNumber } = req.params;

  // Validate required fields
  if (!name || !phoneNumber || !password) {
    return res.status(400).json({
      success: false,
      message: 'Name, phone number, and password are required'
    });
  }

  // Validate phone number format for new phone number
  const phoneRegex = /^[0-9]{10}$/;
  if (!phoneRegex.test(phoneNumber)) {
    return res.status(400).json({
      success: false,
      message: 'New phone number must be 10 digits'
    });
  }

  // Validate phone number format for URL parameter
  if (!phoneRegex.test(paramPhoneNumber)) {
    return res.status(400).json({
      success: false,
      message: 'Invalid phone number in URL'
    });
  }

  // Validate name
  if (typeof name !== 'string' || name.trim().length < 2) {
    return res.status(400).json({
      success: false,
      message: 'Name must be at least 2 characters long'
    });
  }

  // Validate name contains only letters and spaces
  if (!/^[a-zA-Z\s]+$/.test(name.trim())) {
    return res.status(400).json({
      success: false,
      message: 'Name can only contain letters and spaces'
    });
  }

  // Validate password
  if (typeof password !== 'string' || password.length < 6) {
    return res.status(400).json({
      success: false,
      message: 'Password must be at least 6 characters long'
    });
  }

  // Additional validation: Check if name is not too long
  if (name.trim().length > 50) {
    return res.status(400).json({
      success: false,
      message: 'Name must not exceed 50 characters'
    });
  }

  next();
};

module.exports = {
  validateLogin,
  validateAdminLogin,           
  validateAddDriver,
  validateUpdateEarnings,
  validateUpdateRide,
  validateRideCompletion,
  validateUserId,
  validatePhoneNumberParam,     
  validatePasswordChange,
  validateUpdateAdmin           // NEW: Added this export
};
