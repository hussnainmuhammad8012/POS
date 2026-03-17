const mongoose = require('mongoose');
const Admin = require('./models/Admin');
const dotenv = require('dotenv');

dotenv.config();

const seedAdmin = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/rairoyals_management');
    
    const adminExists = await Admin.findOne({ username: 'admin' });
    if (adminExists) {
      console.log('Admin user already exists.');
      process.exit();
    }

    const admin = new Admin({
      username: 'admin',
      password: 'adminpassword123', // User should change this after first login
      role: 'superadmin'
    });

    await admin.save();
    console.log('Admin user created successfully!');
    console.log('Username: admin');
    console.log('Password: adminpassword123');
    process.exit();
  } catch (err) {
    console.error('Error seeding admin:', err);
    process.exit(1);
  }
};

seedAdmin();
