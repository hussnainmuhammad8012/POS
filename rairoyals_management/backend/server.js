const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');

const routes = require('./routes');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
// Allow multiple origins
const allowedOrigins = [
  'http://localhost:5173',  // Vite dev server
  'http://localhost:3000',  // React dev server
  // We'll add Vercel URL after deployment
];

app.use(cors({
  origin: function(origin, callback) {
    // Allow requests with no origin (mobile apps, curl, etc.)
    if (!origin) return callback(null, true);
    
    if (allowedOrigins.indexOf(origin) === -1) {
      return callback(null, true); // Allow all for now, restrict later
    }
    return callback(null, true);
  },
  credentials: true
}));
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Database Connection
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/rairoyals_management')
  .then(() => console.log('MongoDB connected successfully'))
  .catch(err => console.error('MongoDB connection error:', err));

// Routes
app.use('/api', routes);

app.get('/', (req, res) => {
  res.send('RaiRoyalsCode Management API is running...');
});

// Start Server
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
