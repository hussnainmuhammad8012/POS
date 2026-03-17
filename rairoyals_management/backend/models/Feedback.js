const mongoose = require('mongoose');

const FeedbackSchema = new mongoose.Schema({
  clientId: { type: mongoose.Schema.Types.ObjectId, ref: 'Client', required: true },
  type: { 
    type: String, 
    enum: ['positive', 'negative', 'neutral'], 
    default: 'neutral' 
  },
  content: { type: String, required: true },
  attachments: [{
    fileName: String,
    fileUrl: String,
    fileType: String
  }],
  isProcessed: { type: Boolean, default: false },
}, { timestamps: true });

module.exports = mongoose.model('Feedback', FeedbackSchema);
