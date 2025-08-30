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

const validateRideCompletion = (req, res, next) => {
  const { rideEarnings, tripData } = req.body;
  
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
  
  if (rideEarnings > 10000) {
    return res.status(400).json({ 
      success: false,
      message: 'Ride earnings seems too high (max: ₹10,000)' 
    });
  }
  
  if (tripData) {
    const requiredFields = ['distance', 'duration', 'totalFare'];
    for (const field of requiredFields) {
      if (!tripData[field] && tripData[field] !== 0) {
        return res.status(400).json({ 
          success: false,
          message: `Trip data missing required field: ${field}` 
        });
      }
    }
    
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
    
    if (tripData.totalFare && Math.abs(tripData.totalFare - rideEarnings) > 0.01) {
      return res.status(400).json({ 
        success: false,
        message: 'Trip total fare must match ride earnings' 
      });
    }
  }
  
  next();
};

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
  
  if (!/^[a-fA-F0-9]{24}$/.test(idToValidate)) {
    return res.status(400).json({
      success: false,
      message: 'Invalid user ID format'
    });
  }
  
  next();
};

// CLEAN: Validate fare data for fresh collection (only waiting60min field)
const validateFareData = (req, res, next) => {
  const { baseFare, perKmRate, waiting60min } = req.body;
  
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
  
  // Validate waiting60min charge (optional field)
  if (waiting60min !== undefined && waiting60min !== null) {
    if (typeof waiting60min !== 'number' || waiting60min < 0) {
      return res.status(400).json({
        success: false,
        message: 'waiting60min must be a non-negative number'
      });
    }
    
    if (waiting60min > 1000) {
      return res.status(400).json({
        success: false,
        message: 'waiting60min seems too high (max: ₹1,000)'
      });
    }
  }
  
  next();
};

const validateFareCalculation = (req, res, next) => {
  const { distance, waitingMinutes } = req.body;
  
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
  
  if (waitingMinutes !== undefined && waitingMinutes !== null) {
    if (typeof waitingMinutes !== 'number' || waitingMinutes < 0) {
      return res.status(400).json({
        success: false,
        message: 'Waiting minutes must be a non-negative number'
      });
    }
    
    if (waitingMinutes > 480) {
      return res.status(400).json({
        success: false,
        message: 'Waiting time seems too high (max: 480 minutes)'
      });
    }
  }
  
  next();
};

const validateAdminProfileUpdate = (req, res, next) => {
  const { name, password } = req.body;

  if (!name && !password && name !== '' && password !== '') {
    return res.status(400).json({
      success: false,
      message: 'At least one field (name or password) is required for update'
    });
  }

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
  validateAdminProfileUpdate
};
