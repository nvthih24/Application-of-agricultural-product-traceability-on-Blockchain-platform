const express = require('express');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const cors = require('cors');
const authRoutes = require('./routes/auth');
const uploadRoutes = require('./routes/upload');
const qrCodeRoutes = require('./routes/qrcodes');

dotenv.config();

const app = express();
app.use(express.json());
app.use(cors());
app.use('/api/upload', uploadRoutes);
app.use('/api/qrcodes', qrCodeRoutes);

mongoose
  .connect(process.env.MONGO_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  })
  .then(() => console.log("MongoDB connected"))
  .catch((err) => console.log(err));

app.use("/api/auth", authRoutes);

const PORT = process.env.PORT || 5000;
app.listen(PORT, '0.0.0.0', () => console.log(`Server running on port ${PORT}`));
