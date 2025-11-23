// backend/routes/transaction.routes.js
const express = require('express');
const router = express.Router();
const { contract } = require('../blockchain/utils/signer');
const jwtAuth = require('../middleware/auth');
const User = require('../models/User'); // THÊM DÒNG NÀY

router.post('/', jwtAuth, async (req, res) => {
  try {
    const { action, ...data } = req.body;

    // LẤY THÔNG TIN USER TỪ MONGODB (KHÔNG DÙNG VÍ NỮA)
    const currentUser = await User.findById(req.user.userId);
    if (!currentUser) {
      return res.status(404).json({ error: "Không tìm thấy người dùng" });
    }

    let tx;
    switch (action) {

      case 'addProduct':
        tx = await contract.addProduct(
          data.productName,
          data.productId,
          data.farmName || currentUser.fullName + "'s Farm",
          data.plantingDate,
          data.plantingImageUrl || "",
          0, "", 
          data.seedOrigin || data.seedSource || "",
          "",
          currentUser.phone || "0900000000",           // SĐT thật
          currentUser.fullName || "Nông dân"           // Tên thật
        );
        break;

      case 'logCare':
        // KIỂM TRA CHỦ SỞ HỮU BẰNG PHONE THAY VÌ VÍ
        const trace = await contract.getTrace(data.productId);
        if (trace.creatorPhone !== currentUser.phone) {
          return res.status(403).json({ error: "Bạn không phải chủ lô hàng!" });
        }

        tx = await contract.logCare(
          data.productId,
          data.careType,
          data.description,
          data.careDate,
          data.careImageUrl || "",
          currentUser.phone || "0900000000",
          currentUser.fullName || "Nông dân"
        );
        break;

      // Các case khác (updateProduct, harvest, transport...) thêm sau
      default:
        return res.status(400).json({ error: "Action không hợp lệ" });
    }

    const receipt = await tx.wait();

    res.json({
      success: true,
      txHash: receipt.hash,
      blockNumber: receipt.blockNumber,
      message: "Ghi lên blockchain thành công!",
    });

  } catch (error) {
    console.error("Relayer Error:", error);
    res.status(500).json({
      error: "Giao dịch thất bại",
      details: error.reason || error.message || error.toString()
    });
  }
});

module.exports = router;