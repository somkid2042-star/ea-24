const SECRET_KEY = "OTP24HRHUB_PROTECT";
const API_BASE = "https://otp24hr.com/api/v1/tools/api";

function decodeData(encodedStr, key) {
    // 1. ถอดรหัส Base64 (ใช้ Buffer เข้ากันได้ดีที่สุดใน Node.js)
    const binaryBuffer = Buffer.from(encodedStr, 'base64');
    const bytes = new Uint8Array(binaryBuffer.length);
    
    // 2. นำข้อมูลระดับ Byte มาเข้าสมการ XOR กับ Key ของเรา
    for (let i = 0; i < binaryBuffer.length; i++) {
        bytes[i] = binaryBuffer[i] ^ key.charCodeAt(i % key.length);
    }
    
    // 3. ปั้นกลับมาเป็น Text (UTF-8) ให้มนุษย์อ่านได้
    return new TextDecoder().decode(bytes);
}

async function run() {
    console.log("=========================================");
    console.log("🚀 Starting OTP24 Data Reader App...");
    console.log("=========================================\n");

    // เลือก Action: get_ui, check_version, get_packages ฯลฯ
    const url = `${API_BASE}?action=check_version`;
    console.log(`📡 Fetching API Endpoint: ${url}`);
    
    try {
        const response = await fetch(url);
        const jsonResponse = await response.json();
        
        if (jsonResponse.payload) {
            console.log("\n✅ Success! Received encrypted Base64 payload.");
            console.log("🛡️  Decrypting using Secret Key...");
            
            const realData = decodeData(jsonResponse.payload, SECRET_KEY);
            const parsedData = JSON.parse(realData);
            
            console.log("\n📦 --- DECODED DATA ---");
            console.log(JSON.stringify(parsedData, null, 2));
            console.log("------------------------\n");
        } else {
            console.log("❌ No payload found. Response was:", jsonResponse);
        }
    } catch(err) {
        console.error("\n❌ Error fetching data:", err.message);
    }
}

run();
