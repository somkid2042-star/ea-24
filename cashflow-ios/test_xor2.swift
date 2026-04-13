import Foundation

let encoded = "NHY8U0AtITwKNDoiISY7K2FubWZ+ChZkcCw6NTE8PS4wGjYmI3ZqEFw8JjgmeAN/DmA7MTNmezwiHFcnPxR6OAs/PSMnZ292Oj0PWkAlPmpvYGM0Ozl0NjctIzFtbhYUIBQ7Yn9wcjsxPTd5Ljg5VVpyciswLCs1IHR0GTEIIw==" 
/* I added w== to pad it correctly, wait let me just use Data(base64Encoded: ) ignore missing padding */

func xorDecode(_ encoded: String) -> String? {
    // Add padding if missing
    var padded = encoded
    while padded.count % 4 != 0 { padded.append("=") }
    
    guard let data = Data(base64Encoded: padded) else { return "base64 fail" }
    let secretKey = "OTP24HRHUB_PROTECT"
    let keyBytes = Array(secretKey.utf8)
    var decoded = [UInt8]()
    for (i, byte) in data.enumerated() {
        decoded.append(byte ^ keyBytes[i % keyBytes.count])
    }
    return String(bytes: decoded, encoding: .utf8)
}
print(xorDecode(encoded) ?? "nil")
