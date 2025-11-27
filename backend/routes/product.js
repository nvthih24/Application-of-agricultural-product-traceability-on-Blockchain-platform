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
            harvestStatus: toNumber(trace.harvestStatus),
            harvestDate: toNumber(trace.harvestDate),
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

// API: Lấy lịch sử kiểm duyệt (Đã duyệt / Từ chối)
router.get('/moderated-requests', jwtAuth, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user || user.role !== 'moderator') return res.status(403).json({ error: "Cấm" });

    const historyPlanting = [];
    const historyHarvest = [];
    const nextId = await readContract.nextProductId();

    for (let i = 1; i < nextId; i++) {
      try {
        const pid = await readContract.indexToProductId(i);
        if (!pid) continue;
        const trace = await readContract.getTrace(pid);
        
        const pStatus = toNumber(trace.plantingStatus); // 1: Approved, 2: Rejected
        const hStatus = toNumber(trace.harvestStatus);

        const item = {
          id: pid,
          name: trace.productName,
          farm: trace.farmName,
          image: trace.plantingImageUrl || "",
          date: toNumber(trace.plantingDate),
          status: "Unknown"
        };

        // Lọc danh sách Gieo trồng đã xử lý (Khác 0)
        if (pStatus !== 0) {
            let statusText = pStatus === 1 ? "Đã duyệt" : "Từ chối";
            historyPlanting.push({ ...item, status: statusText, statusCode: pStatus });
        }

        // Lọc danh sách Thu hoạch đã xử lý (Khác 0)
        if (hStatus !== 0) {
            let statusText = hStatus === 1 ? "Đã duyệt" : "Từ chối";
            historyHarvest.push({ 
                ...item, 
                status: statusText, 
                statusCode: hStatus,
                image: trace.harvestImageUrl || item.image,
                type: 'harvest' 
            });
        }
      } catch (e) {}
    }

    res.json({ success: true, data: { planting: historyPlanting, harvest: historyHarvest } });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// API: Lấy danh sách hàng hóa của Tài xế (Đang chở hoặc Đã giao)
router.get("/my-shipments", jwtAuth, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);

    // LẤY TÊN ĐỂ LỌC (Ưu tiên Tên Công Ty, nếu không có thì lấy Tên Thật)
    const filterName = user.companyName ? user.companyName : user.fullName;
    console.log("Đang lọc đơn hàng cho đơn vị:", filterName);

    const shipments = [];
    const nextId = await readContract.nextProductId();

    for (let i = 1; i < nextId; i++) {
      try {
        const productId = await readContract.indexToProductId(i);
        if (!productId) continue;

        const trace = await readContract.getTrace(productId);
        const receiveDate = toNumber(trace.receiveDate);
        const deliveryDate = toNumber(trace.deliveryDate);

        // ĐIỀU KIỆN LỌC:
        // 1. Đơn hàng đã được quét nhận (receiveDate > 0)
        // 2. Tên đơn vị vận chuyển trên Blockchain KHỚP với tên của User (Công ty hoặc Tên riêng)
        if (receiveDate > 0 && trace.transporterName === filterName) {
          shipments.push({
            id: productId,
            name: trace.productName,
            image: trace.plantingImageUrl || "",
            farmName: trace.farmName,
            // Logic hiển thị vị trí/trạng thái
            location: deliveryDate > 0 ? "Đã giao xong" : "Đang vận chuyển",
            time: deliveryDate > 0 ? deliveryDate : receiveDate,
            statusCode: deliveryDate > 0 ? 2 : 1, // 1: Đang đi, 2: Đã xong
            status: deliveryDate > 0 ? "Completed" : "In Transit",
            // Trả thêm thông tin phụ để FE hiển thị nếu cần
            transporterName: trace.transporterName,
            transportInfo: trace.transportInfo,
          });
        }
      } catch (e) {
        // Bỏ qua lỗi nhỏ khi đọc từng item
      }
    }

    res.json({ success: true, data: shipments });
  } catch (error) {
    console.error("Lỗi lấy danh sách vận chuyển:", error);
    res.status(500).json({ error: "Lỗi server" });
  }
});

// API CÔNG KHAI: Lấy danh sách sản phẩm của 1 nông dân cụ thể (qua SĐT)
router.get("/by-farmer/:phone", async (req, res) => {
  try {
    const farmerPhone = req.params.phone;
    const products = [];
    const nextId = await readContract.nextProductId();

    for (let i = 1; i < nextId; i++) {
      try {
        const productId = await readContract.indexToProductId(i);
        if (!productId) continue;

        const trace = await readContract.getTrace(productId);

        // So sánh SĐT trên Blockchain với SĐT truyền vào
        if (trace.creatorPhone === farmerPhone) {
          products.push({
            id: productId,
            name: trace.productName,
            image: trace.plantingImageUrl || "", // Lấy ảnh lúc trồng làm đại diện
            status:
              toNumber(trace.harvestDate) > 0 ? "Đã thu hoạch" : "Đang trồng",
          });
        }
      } catch (e) {}
    }

    res.json({ success: true, data: products });
  } catch (error) {
    console.error(error);
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
