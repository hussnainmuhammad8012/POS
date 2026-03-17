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

const auth = require('../middleware/authMiddleware');

// Public Routes (Desktop App API)
router.post('/verify-license', clientController.verifyLicense);
router.post('/submit-feedback', upload.array('attachments'), feedbackController.submitFeedback);

// Admin Routes (Management Dashboard) - Protected by JWT
router.post('/admin/login', authController.login);
router.get('/admin/stats', auth, clientController.getDashboardStats);
router.get('/clients', auth, clientController.getClients);
router.post('/clients', auth, clientController.createClient);
router.put('/clients/:id', auth, clientController.updateClientStatus);
router.get('/feedback', auth, feedbackController.getAllFeedback);
router.put('/feedback/:id', auth, feedbackController.updateFeedbackStatus);

module.exports = router;
