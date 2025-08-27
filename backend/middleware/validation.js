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

module.exports = {
  validateLogin,
  validateAddDriver,
  validateUpdateEarnings,
  validateUpdateRide
};
