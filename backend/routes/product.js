// backend/routes/product.routes.js
const express = require("express");
const router = express.Router();
const { readContract } = require("../blockchain/utils/signer");
const jwtAuth = require("../middleware/auth");
const User = require("../models/User");

// HÀM CHUYỂN BigInt/Number/string → number an toàn
const toNumber = (value) => {
  if (!value) return 0;
  if (typeof value === "string") return parseInt(value) || 0;
  if (value._isBigNumber || value.toString) return Number(value.toString());
  return Number(value);
};

// API Công khai: Lấy danh sách tất cả nông trại (Farmer)
router.get("/farmers", async (req, res) => {
  try {
    // Tìm user có role là farmer
    // .select('-password') nghĩa là lấy hết trừ mật khẩu ra (bảo mật)
    const farmers = await User.find({ role: "farmer" }).select("-password");

    res.json({ success: true, data: farmers });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Lỗi lấy danh sách nông dân" });
  }
});

router.get("/my-products", jwtAuth, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user || user.role !== "farmer") {
      return res.status(403).json({ error: "Chỉ nông dân mới xem được" });
    }

    const products = [];
    const nextId = await readContract.nextProductId();
    console.log("nextProductId =", nextId.toString());

    for (let i = 1; i < nextId; i++) {
      try {
        const productId = await readContract.indexToProductId(i);

        if (
          !productId ||
          productId === "" ||
          productId === "0x0000000000000000000000000000000000000000"
        ) {
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
            status:
              harvestDate > 0
                ? "Đã thu hoạch"
                : plantingStatus === 1
                ? "Đang trồng"
                : "Chờ duyệt gieo trồng",
            statusCode: harvestDate > 0 ? 2 : plantingStatus === 1 ? 1 : 0,
            plantingStatus: plantingStatus,
          });
        }
      } catch (e) {
        console.log(`Lỗi nhẹ tại index ${i}, bỏ qua:`, e.message);
        // Không crash nữa → tiếp tục vòng lặp
      }
    }

    console.log(
      `TÌM THẤY ${products.length} SẢN PHẨM CỦA NÔNG DÂN ${user.phone}`
    );
    res.json({ products });
  } catch (error) {
    console.error("Lỗi server:", error);
    res.status(500).json({ error: "Lỗi server" });
  }
});

// API CHO MODERATOR: Lấy danh sách chờ duyệt
router.get("/pending-requests", jwtAuth, async (req, res) => {
  try {
    // 1. Check quyền Moderator
    const user = await User.findById(req.user.userId);
    if (!user || user.role !== "moderator") {
      return res
        .status(403)
        .json({ error: "Chỉ kiểm duyệt viên mới được xem" });
    }

    const pendingPlanting = [];
    const pendingHarvest = [];

    const nextId = await readContract.nextProductId();

    for (let i = 1; i < nextId; i++) {
      try {
        const productId = await readContract.indexToProductId(i);
        if (!productId) continue;

        const trace = await readContract.getTrace(productId);

        // Convert BigInt
        const plantingStatus = toNumber(trace.plantingStatus);
        const harvestStatus = toNumber(trace.harvestStatus);
        const harvestDate = toNumber(trace.harvestDate);

        // Format dữ liệu gọn nhẹ để trả về App
        const item = {
          id: productId,
          name: trace.productName,
          farm: trace.farmName,
          image: trace.plantingImageUrl || "", // Hoặc harvestImageUrl tùy loại
          date: toNumber(trace.plantingDate), // Timestamp
          quantity: "N/A", // Contract chưa có field sản lượng, tạm để N/A hoặc update sau
        };

        // LOGIC LỌC:
        // 1. Chờ duyệt Gieo trồng (Status = 0)
        if (plantingStatus === 0) {
          pendingPlanting.push({ ...item, type: "planting" });
        }

        // 2. Chờ duyệt Thu hoạch (Planting = 1 (Approved) VÀ Harvest = 0 (Pending) VÀ đã có ngày thu hoạch)
        else if (
          plantingStatus === 1 &&
          harvestStatus === 0 &&
          harvestDate > 0
        ) {
          pendingHarvest.push({
            ...item,
            image: trace.harvestImageUrl || item.image, // Ưu tiên ảnh thu hoạch
            date: harvestDate,
            type: "harvest",
          });
        }
      } catch (e) {
        console.log(`Lỗi skip index ${i}`);
      }
    }

    res.json({
      success: true,
      data: {
        planting: pendingPlanting,
        harvest: pendingHarvest,
      },
    });
  } catch (error) {
    console.error("Lỗi lấy pending list:", error);
    res.status(500).json({ error: "Lỗi server" });
  }
});

// API CÔNG KHAI: Lấy chi tiết sản phẩm & Nhật ký chăm sóc theo ID
// GET /api/products/:id
router.get("/:id", async (req, res) => {
  try {
    const productId = req.params.id;
    console.log("🔍 Đang truy xuất sản phẩm:", productId);

    // 1. Lấy thông tin cơ bản (TraceInfo)
    const trace = await readContract.getTrace(productId);

    // Kiểm tra xem sản phẩm có tồn tại không
    if (
      !trace ||
      trace.productId === "" ||
      trace.productId === "0x0000000000000000000000000000000000000000"
    ) {
      return res
        .status(404)
        .json({ error: "Sản phẩm không tồn tại trên Blockchain" });
    }

    // 2. Lấy nhật ký chăm sóc (CareLogs) - Vì mảng trong struct đôi khi trả về lỗi, nên gọi hàm riêng nếu có
    // Nếu trong contract ông có hàm getCareLogs thì dùng, không thì dùng trace.careLogs
    let careLogs = [];
    try {
      careLogs = await readContract.getCareLogs(productId);
    } catch (e) {
      console.log("⚠️ Không lấy được CareLogs hoặc rỗng:", e.message);
      careLogs = trace.careLogs || [];
    }

    // 3. Format dữ liệu cho đẹp (BigInt -> Number)
    const formattedProduct = {
      id: trace.productId,
      name: trace.productName,
      farm: {
        name: trace.farmName,
        owner: trace.creatorName,
        phone: trace.creatorPhone,
        seed: trace.seedOrigin || "Không rõ nguồn gốc",
      },
      dates: {
        planting: toNumber(trace.plantingDate),
        harvest: toNumber(trace.harvestDate),
        receive: toNumber(trace.receiveDate),
        delivery: toNumber(trace.deliveryDate),
      },
      images: {
        planting: trace.plantingImageUrl,
        harvest: trace.harvestImageUrl,
        receive: trace.receiveImageUrl,
        delivery: trace.deliveryImageUrl,
      },
      status: {
        planting: toNumber(trace.plantingStatus), // 0: Pending, 1: Approved
        harvest: toNumber(trace.harvestStatus),
      },
      transporter: {
        name: trace.transporterName,
        info: trace.transportInfo,
      },
      retailer: {
        price: toNumber(trace.price),
        image: trace.managerReceiveImageUrl,
      },
      // Format lại CareLogs
      careLogs: careLogs.map((log) => ({
        type: log.careType,
        desc: log.description,
        date: toNumber(log.careDate),
        image: log.careImageUrl,
      })),
    };

    res.json({ success: true, data: formattedProduct });
  } catch (error) {
    console.error("Lỗi truy xuất:", error);
    res.status(500).json({ error: "Lỗi server khi truy xuất Blockchain" });
  }
});

module.exports = router;
