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

// NEW: Validate ride completion data
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
    
    if (tripData.distanceFare && typeof tripData.distanceFare !== 'number') {
      return res.status(400).json({ 
        success: false,
        message: 'Trip distance fare must be a number' 
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

// NEW: Validate user ID parameter
const validateUserId = (req, res, next) => {
  const { userId, adminId } = req.params;
  const idToValidate = userId || adminId;
  
  if (!idToValidate) {
    return res.status(400).json({
      success: false,
      message: 'User ID is required'
    });
  }
  
  if (idToValidate === 'undefined' || idToValidate === 'null') {
    return res.status(400).json({
      success: false,
      message: 'Invalid user ID provided'
    });
  }
  
  // Basic MongoDB ObjectId format validation (24 character hex string)
  if (!/^[a-fA-F0-9]{24}$/.test(idToValidate)) {
    return res.status(400).json({
      success: false,
      message: 'Invalid user ID format'
    });
  }
  
  next();
};

// NEW: Validate fare data
const validateFareData = (req, res, next) => {
  const { baseFare, perKmRate } = req.body;
  
  // Validate base fare
  if (!baseFare && baseFare !== 0) {
    return res.status(400).json({
      success: false,
      message: 'Base fare is required'
    });
  }
  
  if (typeof baseFare !== 'number' || baseFare <= 0) {
    return res.status(400).json({
      success: false,
      message: 'Base fare must be a positive number'
    });
  }
  
  if (baseFare > 5000) {
    return res.status(400).json({
      success: false,
      message: 'Base fare seems too high (max: ₹5,000)'
    });
  }
  
  // Validate per km rate
  if (!perKmRate && perKmRate !== 0) {
    return res.status(400).json({
      success: false,
      message: 'Per kilometer rate is required'
    });
  }
  
  if (typeof perKmRate !== 'number' || perKmRate <= 0) {
    return res.status(400).json({
      success: false,
      message: 'Per kilometer rate must be a positive number'
    });
  }
  
  if (perKmRate > 1000) {
    return res.status(400).json({
      success: false,
      message: 'Per kilometer rate seems too high (max: ₹1,000/km)'
    });
  }
  
  // Validate waiting charges (optional fields)
  const waitingFields = ['waiting5min', 'waiting10min', 'waiting15min', 'waiting20min', 'waiting25min', 'waiting30min'];
  
  for (const field of waitingFields) {
    const value = req.body[field];
    if (value !== undefined && value !== null) {
      if (typeof value !== 'number' || value < 0) {
        return res.status(400).json({
          success: false,
          message: `${field} must be a non-negative number`
        });
      }
      
      if (value > 1000) {
        return res.status(400).json({
          success: false,
          message: `${field} seems too high (max: ₹1,000)`
        });
      }
    }
  }
  
  next();
};

// NEW: Validate fare calculation data
const validateFareCalculation = (req, res, next) => {
  const { distance, waitingMinutes } = req.body;
  
  // Validate distance
  if (!distance && distance !== 0) {
    return res.status(400).json({
      success: false,
      message: 'Distance is required'
    });
  }
  
  if (typeof distance !== 'number' || distance <= 0) {
    return res.status(400).json({
      success: false,
      message: 'Distance must be a positive number'
    });
  }
  
  if (distance > 1000) {
    return res.status(400).json({
      success: false,
      message: 'Distance seems too high (max: 1000km)'
    });
  }
  
  // Validate waiting minutes (optional)
  if (waitingMinutes !== undefined && waitingMinutes !== null) {
    if (typeof waitingMinutes !== 'number' || waitingMinutes < 0) {
      return res.status(400).json({
        success: false,
        message: 'Waiting minutes must be a non-negative number'
      });
    }
    
    if (waitingMinutes > 480) { // 8 hours max
      return res.status(400).json({
        success: false,
        message: 'Waiting time seems too high (max: 480 minutes)'
      });
    }
  }
  
  next();
};

// NEW: Validate admin profile update
const validateAdminProfileUpdate = (req, res, next) => {
  const { name, password } = req.body;

  // At least one field should be provided for update
  if (!name && !password && name !== '' && password !== '') {
    return res.status(400).json({
      success: false,
      message: 'At least one field (name or password) is required for update'
    });
  }

  // Validate name if provided
  if (name !== undefined) {
    if (typeof name !== 'string') {
      return res.status(400).json({
        success: false,
        message: 'Name must be a string'
      });
    }
    
    if (name.trim().length < 2) {
      return res.status(400).json({
        success: false,
        message: 'Name must be at least 2 characters'
      });
    }
    
    if (name.trim().length > 50) {
      return res.status(400).json({
        success: false,
        message: 'Name must not exceed 50 characters'
      });
    }
  }

  // Validate password if provided
  if (password !== undefined) {
    if (typeof password !== 'string') {
      return res.status(400).json({
        success: false,
        message: 'Password must be a string'
      });
    }
    
    if (password.length < 3) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 3 characters'
      });
    }
    
    if (password.length > 20) {
      return res.status(400).json({
        success: false,
        message: 'Password must not exceed 20 characters'
      });
    }
  }

  next();
};

module.exports = {
  validateLogin,
  validateAddDriver,
  validateUpdateEarnings,
  validateUpdateRide,
  validateRideCompletion,
  validateUserId,
  validateFareData,
  validateFareCalculation,
  validateAdminProfileUpdate  // NEW
};
