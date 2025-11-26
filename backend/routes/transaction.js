// backend/routes/transaction.routes.js
const express = require("express");
const router = express.Router();
const { contract } = require("../blockchain/utils/signer");
const jwtAuth = require("../middleware/auth");
const User = require("../models/User"); // THÊM DÒNG NÀY

router.post("/", jwtAuth, async (req, res) => {
  try {
    const { action, ...data } = req.body;

    // LẤY THÔNG TIN USER TỪ MONGODB
    const currentUser = await User.findById(req.user.userId);
    if (!currentUser) {
      return res.status(404).json({ error: "Không tìm thấy người dùng" });
    }

    let tx;
    switch (action) {
      case "addProduct":
        tx = await contract.addProduct(
          data.productName,
          data.productId,
          data.farmName || currentUser.fullName + "'s Farm",
          data.plantingDate,
          data.plantingImageUrl || "",
          0,
          "",
          data.seedOrigin || data.seedSource || "",
          "",
          currentUser.phone || "0900000000", // SĐT thật
          currentUser.fullName || "Nông dân", // Tên thật
          0,
          "",
        );
        break;

      case "logCare":
        // KIỂM TRA CHỦ SỞ HỮU BẰNG PHONE
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
case "harvestProduct":
        // Kiểm tra quyền sở hữu (Optional)
        // const trace = await contract.getTrace(data.productId);
        // if (trace.creatorPhone !== currentUser.phone) return res.status(403)...

        tx = await contract.updateProduct( // Contract tên là updateProduct
          data.productId,
          data.productName || "Sản phẩm", // Tên SP
          data.farmName || currentUser.fullName + "'s Farm", // Tên Farm
          data.harvestDate, // Ngày thu hoạch
          data.harvestImageUrl || "", // Ảnh thu hoạch
          data.quantity || 0, // Sản lượng (Số lượng)
          data.quality || "Loại 1" // Chất lượng
        );
        break;
// 4. TRANSPORTER: Nhận hàng (Pickup)
      case "updateReceive":
        // Kiểm tra quyền (Nếu cần)
        // if (req.user.role !== 'transporter') return res.status(403)...
        
        tx = await contract.updateReceive(
          data.productId,
          data.transporterName,
          data.receiveDate, // Thời gian nhận
          data.receiveImageUrl || "", // Ảnh nhận hàng (nếu có)
          data.transportInfo || "Xe vận chuyển" // Biển số xe / Ghi chú
        );
        break;

      // 5. TRANSPORTER: Giao hàng (Delivery)
      case "updateDelivery":
        tx = await contract.updateDelivery(
          data.productId,
          data.transporterName,
          data.deliveryDate,
          data.deliveryImageUrl || "",
          data.transportInfo || "Giao thành công"
        );
        break;

      // 1. DUYỆT GIEO TRỒNG
      case "approvePlanting":
        // Kiểm tra xem user đang đăng nhập có phải là Moderator không
        // (Lưu ý: req.user lấy từ jwtAuth middleware)
        tx = await contract.approvePlanting(data.productId);
        break;

      // 2. TỪ CHỐI GIEO TRỒNG
      case "rejectPlanting":
        tx = await contract.rejectPlanting(data.productId);
        break;

      // 3. DUYỆT THU HOẠCH
      case "approveHarvest":
        tx = await contract.approveHarvest(data.productId);
        break;

      // 4. TỪ CHỐI THU HOẠCH
      case "rejectHarvest":
        tx = await contract.rejectHarvest(data.productId);
        break;

      // 5. RETAILER: Cập nhật thông tin bán hàng (Nhận hàng & Lên kệ)
      case "updateManagerInfo":
        // Kiểm tra quyền (Nếu muốn chặt chẽ)
        // if (req.user.role !== 'manager') return res.status(403).json({error: "Không có quyền"});
        tx = await contract.updateManagerInfo(
          data.productId,
          data.managerReceiveDate, // Thời gian nhận/lên kệ
          data.managerReceiveImageUrl || "", // Ảnh quầy kệ
          data.price // Giá bán
        );
        break;

      // 6. RETAILER: Xác nhận đã bán (Deactivate) - Để kết thúc vòng đời
      case "deactivateProduct":
        // if (req.user.role !== 'manager') return res.status(403).json({error: "Không có quyền"});

        // Lưu ý: Hàm này trong contract tên là deactivateProduct
        tx = await contract.deactivateProduct(data.productId);
        break;
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
      details: error.reason || error.message || error.toString(),
    });
  }
});

module.exports = router;
