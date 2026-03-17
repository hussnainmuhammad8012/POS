const mongoose = require('mongoose');

const ClientSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  licenseKey: { type: String, required: true, unique: true },
  status: { 
    type: String, 
    enum: ['trial', 'active', 'blocked'], 
    default: 'trial' 
  },
  trialStartDate: { type: Date, default: Date.now },
  trialExpiryDate: { type: Date },
  isRemoteBlocked: { type: Boolean, default: false },
  storeName: { type: String },
  deviceId: { type: String }, // Hardware ID binding
  lastSeen: { type: Date, default: Date.now },
}, { timestamps: true });

module.exports = mongoose.model('Client', ClientSchema);
