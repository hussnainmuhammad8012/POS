const Client = require('../models/Client');

const getClients = async (req, res) => {
  try {
    const clients = await Client.find().sort({ createdAt: -1 });
    res.json(clients);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

const createClient = async (req, res) => {
  try {
    const client = new Client(req.body);
    await client.save();
    res.status(201).json(client);
  } catch (err) {
    res.status(400).json({ message: 'Error creating client', error: err.message });
  }
};

const updateClientStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, isRemoteBlocked, trialExpiryDate } = req.body;
    
    const client = await Client.findByIdAndUpdate(
      id, 
      { status, isRemoteBlocked, trialExpiryDate },
      { new: true }
    );
    
    if (!client) return res.status(404).json({ message: 'Client not found' });
    res.json(client);
  } catch (err) {
    res.status(500).json({ message: 'Error updating client', error: err.message });
  }
};

const verifyLicense = async (req, res) => {
  try {
    const { licenseKey, deviceId } = req.body;
    
    if (!licenseKey || !deviceId) {
      return res.status(400).json({ valid: false, message: 'License key and Device ID are required' });
    }

    const client = await Client.findOne({ licenseKey });

    if (!client) {
      return res.status(404).json({ valid: false, message: 'Invalid license key' });
    }

    // 1. Device Binding Logic (Single-use enforcement)
    if (!client.deviceId) {
      // First time use: Link license to this device
      client.deviceId = deviceId;
      console.log(`[LICENSE] Binding key ${licenseKey} to device ${deviceId}`);
    } else if (client.deviceId !== deviceId) {
      // Attempted use on a different machine
      return res.status(403).json({ 
        valid: false, 
        message: 'This license is already active on another device. Please contact support to transfer.' 
      });
    }

    // 2. Status & Block Check
    if (client.isRemoteBlocked) {
      return res.json({ valid: true, isBlocked: true, message: 'Your access has been blocked by the developer.' });
    }

    // 3. Trial Management Logic
    let isTrialExpired = false;
    let daysRemaining = null;

    if (client.status === 'trial') {
      const now = new Date();
      if (!client.trialExpiryDate || now > client.trialExpiryDate) {
        isTrialExpired = true;
      } else {
        daysRemaining = Math.ceil((client.trialExpiryDate - now) / (1000 * 60 * 60 * 24));
      }
    }

    // Update last seen
    client.lastSeen = Date.now();
    await client.save();

    res.json({
      valid: true,
      status: client.status,
      isBlocked: false,
      isTrialExpired,
      trialExpiryDate: client.trialExpiryDate,
      daysRemaining: daysRemaining,
      storeName: client.storeName
    });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

module.exports = { getClients, createClient, updateClientStatus, verifyLicense };
