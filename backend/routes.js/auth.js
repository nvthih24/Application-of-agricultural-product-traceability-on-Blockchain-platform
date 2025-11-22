// backend/routes/auth.js
const express = require("express");
const jwt = require("jsonwebtoken");
const User = require("../models/User");
const auth = require("../middleware/auth");
const Transaction = require("../models/Transaction");

const router = express.Router();

// REGISTER (app Flutter sẽ gửi thêm walletAddress nếu có)
router.post("/register", async (req, res) => {
  const { fullName, phone, email, address, password, confirmPassword, role, walletAddress } = req.body;

  if (password !== confirmPassword) return res.status(400).json({ msg: "Passwords do not match" });
  if (role === "admin") return res.status(403).json({ msg: "Cannot register as admin" });

  try {
    let user = await User.findOne({ email });
    if (user) return res.status(400).json({ msg: "User already exists" });

    user = new User({ 
      fullName, phone, email, address, password, role, 
      walletAddress: walletAddress || null 
    });
    await user.save();

    const payload = { 
      userId: user._id, 
      role: user.role, 
      walletAddress: user.walletAddress 
    };
    const token = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: "7d" });

    res.json({
      token,
      user: { 
        id: user._id, 
        email: user.email, 
        role: user.role,
        walletAddress: user.walletAddress 
      },
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ msg: "Server error" });
  }
});

// LOGIN
router.post("/login", async (req, res) => {
  const { email, password } = req.body;

  try {
    const user = await User.findOne({ email });
    if (!user) return res.status(400).json({ msg: "Invalid credentials" });

    const isMatch = await user.comparePassword(password);
    if (!isMatch) return res.status(400).json({ msg: "Invalid credentials" });

    const payload = { 
      userId: user._id, 
      role: user.role, 
      walletAddress: user.walletAddress || null   // có thể null
    };
    const token = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: "7d" });

    res.json({
      token,
      user: { 
        id: user._id, 
        email: user.email, 
        role: user.role,
        walletAddress: user.walletAddress 
      },
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ msg: "Server error" });
  }
});

// Lấy thông tin user hiện tại
router.get("/me", auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId).select("-password");
    res.json({ user });
  } catch (err) {
    res.status(500).json({ msg: "Server error" });
  }
});

// Bind ví (dùng khi user lần đầu connect ví trên app)
router.post("/bind-wallet", auth, async (req, res) => {
  const { walletAddress } = req.body;
  if (!walletAddress) return res.status(400).json({ msg: "walletAddress required" });

  try {
    const user = await User.findById(req.user.userId);
    if (user.walletAddress) {
      return res.status(400).json({ msg: "Wallet already bound" });
    }

    user.walletAddress = walletAddress.toLowerCase();
    await user.save();

    // Tạo token mới có wallet
    const payload = { userId: user._id, role: user.role, walletAddress: user.walletAddress };
    const token = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: "7d" });

    res.json({ 
      msg: "Wallet bound successfully", 
      token,
      walletAddress: user.walletAddress 
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ msg: "Server error" });
  }
});

// Lưu transaction (APP: backend ký thay)
router.post("/transactions", auth, async (req, res) => {
  const {
    txHash,
    productId,
    action,
    timestamp,
    plantingImageUrl,
    harvestImageUrl,
    receiveImageUrl,
    deliveryImageUrl,
    managerReceiveImageUrl,
  } = req.body;

  // Bắt buộc có walletAddress vì backend ký thay
  if (!req.user.walletAddress) {
    return res.status(400).json({ msg: "User has no wallet address. Please bind wallet first." });
  }

  if (!txHash || !productId || !action || !timestamp) {
    return res.status(400).json({ msg: "Missing required fields" });
  }

  try {
    const transaction = new Transaction({
      txHash,
      productId,
      userAddress: req.user.walletAddress,   // tự động lấy từ JWT
      action,
      timestamp,
      plantingImageUrl,
      harvestImageUrl,
      receiveImageUrl,
      deliveryImageUrl,
      managerReceiveImageUrl,
    });

    await transaction.save();
    res.status(201).json({ message: "Transaction saved successfully", txHash });
  } catch (error) {
    console.error("Error saving transaction:", error);
    res.status(500).json({ error: "Failed to save transaction" });
  }
});

// Các route còn lại (get users, get transactions…) giữ nguyên
// ...

module.exports = router;