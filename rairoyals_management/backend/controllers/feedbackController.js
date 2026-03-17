const Feedback = require('../models/Feedback');
const Client = require('../models/Client');

const submitFeedback = async (req, res) => {
  try {
    const { licenseKey, type, content } = req.body;
    const client = await Client.findOne({ licenseKey });
    
    if (!client) {
      return res.status(404).json({ message: 'Client not registered' });
    }

    const attachments = req.files ? req.files.map(file => ({
      fileName: file.originalname,
      fileUrl: `/uploads/${file.filename}`,
      fileType: file.mimetype
    })) : [];

    const feedback = new Feedback({
      clientId: client._id,
      type,
      content,
      attachments
    });

    await feedback.save();
    res.status(201).json({ message: 'Feedback submitted successfully', feedback });
  } catch (err) {
    res.status(500).json({ message: 'Error submitting feedback', error: err.message });
  }
};

const getAllFeedback = async (req, res) => {
  try {
    const feedback = await Feedback.find()
      .populate('clientId', 'name storeName email')
      .sort({ createdAt: -1 });
    res.json(feedback);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

const updateFeedbackStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { isProcessed } = req.body;
    
    const feedback = await Feedback.findByIdAndUpdate(id, { isProcessed }, { new: true });
    if (!feedback) return res.status(404).json({ message: 'Feedback not found' });
    res.json(feedback);
  } catch (err) {
    res.status(500).json({ message: 'Error updating feedback', error: err.message });
  }
};

module.exports = { submitFeedback, getAllFeedback, updateFeedbackStatus };
