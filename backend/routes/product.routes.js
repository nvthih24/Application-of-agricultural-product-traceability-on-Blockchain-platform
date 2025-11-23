// backend/routes/product.routes.js – BẢN CUỐI CÙNG, ĐÃ FIX TOÀN BỘ LỖI!
const express = require('express');
const router = express.Router();
const { readContract } = require('../blockchain/utils/signer');
const jwtAuth = require('../middleware/auth');
const User = require('../models/User');

// HÀM CHUYỂN BigInt/Number/string → number an toàn
const toNumber = (value) => {
  if (!value) return 0;
  if (typeof value === 'string') return parseInt(value) || 0;
  if (value._isBigNumber || value.toString) return Number(value.toString());
  return Number(value);
};

router.get('/my-products', jwtAuth, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user || user.role !== 'farmer') {
      return res.status(403).json({ error: "Chỉ nông dân mới xem được" });
    }

    const products = [];
    const nextId = await readContract.nextProductId();
    console.log("nextProductId =", nextId.toString());

    for (let i = 1; i < nextId; i++) {
      try {
        const productId = await readContract.indexToProductId(i);
        
        if (!productId || productId === "" || productId === "0x0000000000000000000000000000000000000000") {
          continue;
        }

        const trace = await readContract.getTrace(productId);

        // FIX LỖI: dùng toNumber() an toàn
        const harvestDate = toNumber(trace.harvestDate);
        const plantingStatus = toNumber(trace.plantingStatus);

        // SO SÁNH THEO SỐ ĐIỆN THOẠI
        if (trace.creatorPhone === user.phone) {
          products.push({
            id: productId,
            name: trace.productName || "Chưa đặt tên",
            image: trace.plantingImageUrl || "",
            status: harvestDate > 0
                ? "Đã thu hoạch"
                : plantingStatus === 1
                    ? "Đang trồng"
                    : "Chờ duyệt gieo trồng",
            statusCode: harvestDate > 0
                ? 2
                : plantingStatus === 1
                    ? 1
                    : 0,
          });
        }
      } catch (e) {
        console.log(`Lỗi nhẹ tại index ${i}, bỏ qua:`, e.message);
        // Không crash nữa → tiếp tục vòng lặp
      }
    }

    console.log(`TÌM THẤY ${products.length} SẢN PHẨM CỦA NÔNG DÂN ${user.phone}`);
    res.json({ products });
  } catch (error) {
    console.error("Lỗi server:", error);
    res.status(500).json({ error: "Lỗi server" });
  }
});

module.exports = router;