const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const authController = require('../controllers/authController');
const clientController = require('../controllers/clientController');
const feedbackController = require('../controllers/feedbackController');

// Multer Storage for Feedback Attachments
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/');
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + path.extname(file.originalname));
  }
});
const upload = multer({ storage });

// Public Routes (Desktop App API)
router.post('/verify-license', clientController.verifyLicense);
router.post('/submit-feedback', upload.array('attachments'), feedbackController.submitFeedback);

// Admin Routes (Management Dashboard)
router.post('/admin/login', authController.login);
router.get('/clients', clientController.getClients);
router.post('/clients', clientController.createClient);
router.put('/clients/:id', clientController.updateClientStatus);
router.get('/feedback', feedbackController.getAllFeedback);
router.put('/feedback/:id', feedbackController.updateFeedbackStatus);

module.exports = router;
