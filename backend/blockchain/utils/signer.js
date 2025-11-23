// /backend/blockchain/utils/signer.js
const { ethers } = require('ethers');
require('dotenv').config();

// Đảm bảo ABI và Contract Address đã được đưa vào Backend
// Thay đổi đường dẫn này theo cấu trúc thực tế của bạn
// Ví dụ: /backend/blockchain/contract/abi.json
const ContractABI = require('../contract/abi.json'); 
const contractAddress = process.env.CONTRACT_ADDRESS; 
// Thay thế bằng địa chỉ từ contract-address.json hoặc biến môi trường

// --- 1. Cấu hình & Khởi tạo ---

// Lấy thông tin từ .env
const rpcUrl = process.env.RPC_URL || "https://rpc.zeroscan.org"; // Hoặc dùng Infura/Alchemy
const relayerPrivateKey = process.env.PRIVATE_KEY;

if (!relayerPrivateKey) {
    throw new Error("PRIVATE_KEY must be set in .env for Relayer.");
}

// 1. PROVIDER: Kết nối với mạng Blockchain (pionezero)
const provider = new ethers.JsonRpcProvider(rpcUrl);

// 2. WALLET (SIGNER): Tài khoản Relayer sẽ ký và trả phí gas
const relayerSigner = new ethers.Wallet(relayerPrivateKey, provider);
console.log(`Relayer Wallet Address: ${relayerSigner.address}`);

// 3. CONTRACT INSTANCE: Đối tượng Contract đã được gắn với Relayer Signer
// Mọi lệnh gọi hàm ghi (write) trên đối tượng này sẽ được Relayer ký
const contractInstance = new ethers.Contract(
    contractAddress,
    ContractABI,
    relayerSigner 
);

/**
 * Hàm đọc/truy vấn công khai (VIEW functions)
 * Thường không cần Relayer, chỉ cần Provider là đủ.
 */
const readContractInstance = new ethers.Contract(
    contractAddress,
    ContractABI,
    provider
);

// --- 2. Export các đối tượng cần thiết ---
module.exports = {
    // Contract dùng để gửi giao dịch (Relayer ký thay)
    contract: contractInstance, 
    // Contract chỉ dùng để đọc dữ liệu (View/Public)
    readContract: readContractInstance,
    // Địa chỉ ví Relayer (có thể cần dùng để kiểm tra vai trò nếu muốn)
    relayerAddress: relayerSigner.address
};