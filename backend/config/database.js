const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    const mongoURI = process.env.MONGODB_URI;
    
    if (!mongoURI) {
      console.error('❌ MONGODB_URI environment variable is not set');
      process.exit(1);
    }
    
    console.log('🔄 Attempting to connect to MongoDB Atlas...');
    console.log('🔗 Connection URI:', mongoURI.replace(/\/\/([^:]+):([^@]+)@/, '//[username]:[password]@')); // Hide credentials in logs
    
    const conn = await mongoose.connect(mongoURI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      serverSelectionTimeoutMS: 30000,
      socketTimeoutMS: 45000,
      maxPoolSize: 10,
      minPoolSize: 5,
      maxIdleTimeMS: 30000,
      waitQueueTimeoutMS: 5000,
      heartbeatFrequencyMS: 10000,
    });
    
    console.log('✅ MongoDB Atlas connected successfully');
    console.log('🏷️  Database Name:', conn.connection.name);
    console.log('🌐 Host:', conn.connection.host);
    console.log('🔢 Ready State:', conn.connection.readyState);
    
    // Test collection access
    const collections = await conn.connection.db.listCollections().toArray();
    console.log('📁 Available Collections:', collections.map(col => col.name).join(', ') || 'None');
    
    // Ensure fare collection exists by creating a test document (will be removed)
    const Fare = require('../models/fareModel');
    const testConnection = await Fare.db.db.admin().ping();
    console.log('🏓 Database ping successful:', testConnection.ok === 1 ? 'OK' : 'FAILED');
    
  } catch (error) {
    console.error('❌ MongoDB connection failed:');
    console.error('   Error Name:', error.name);
    console.error('   Error Message:', error.message);
    console.error('   Error Code:', error.code);
    
    if (error.name === 'MongooseServerSelectionError') {
      console.error('🔍 Possible causes:');
      console.error('   - Check your IP is whitelisted in MongoDB Atlas');
      console.error('   - Verify username/password in connection string');
      console.error('   - Ensure cluster is running');
      console.error('   - Check firewall settings');
    }
    
    process.exit(1);
  }
};

// Enhanced Connection event handlers
mongoose.connection.on('connected', () => {
  console.log('🔗 Mongoose connected to MongoDB Atlas');
  console.log('📊 Connection State: Connected');
});

mongoose.connection.on('error', (err) => {
  console.error('❌ Mongoose connection error:', err.message);
  console.error('🔍 Error details:', err);
});

mongoose.connection.on('disconnected', () => {
  console.log('📡 Mongoose disconnected from MongoDB Atlas');
  console.log('📊 Connection State: Disconnected');
});

mongoose.connection.on('reconnected', () => {
  console.log('🔄 Mongoose reconnected to MongoDB Atlas');
});

mongoose.connection.on('reconnectFailed', () => {
  console.error('❌ Mongoose reconnection failed');
});

// Graceful shutdown
process.on('SIGINT', async () => {
  try {
    await mongoose.connection.close();
    console.log('🛑 MongoDB connection closed through app termination');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error during MongoDB disconnection:', error.message);
    process.exit(1);
  }
});

module.exports = connectDB;
