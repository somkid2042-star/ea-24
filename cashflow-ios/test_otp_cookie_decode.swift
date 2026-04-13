import Foundation

let secretKey = "OTP24HRHUB_PROTECT"
func xorDecode(_ encoded: String) -> String? {
    guard let data = Data(base64Encoded: encoded) else { return nil }
    let keyBytes = Array(secretKey.utf8)
    var decoded = [UInt8]()
    for (i, byte) in data.enumerated() {
        decoded.append(byte ^ keyBytes[i % keyBytes.count])
    }
    return String(bytes: decoded, encoding: .utf8)
}

let payload = "GRBTWQ0PWFcQQ19uGRcPVwwARgJAQVVFEQ1eXDwIARdOFxdXDRABGlgQBVQAAVQLAAJTBlpWU1AHVwBaAFQBUlZTBwBTAlVUAFBDGkMBC1UDW15FQF4THAQOClIOUE9VDghGFEBCUUIKRgsQP05HSE5OQ1gACAEaWBBTUD0HXVcCEwRbAVBDGkMTBVQXVxIMQFQAAVNXXQJRUAIDBwMGDlBUVldUAgYDU1NQAFQAWABZVwEBVFZWB1JGHRAHDghUC1sSFFtHE08VHFdZDQNdV00CClhAGUNGABEMGlgQbBlAGR1JQQ8EWAcXWxQAEBBQPUZfXQcKEx5BFwRZF1BDDENTAQ4BVFQDA1YGUVoFXAwBAFZUBFdWCVNWAgBbUAIDAFhRAlIHVlcDVlQOUQoFUFJXCVMHBFMEU1MCDwcHVwhWEBwUBgtcUwoPFhdYF09RDgoDVAccU1kPRh0QEwARXUAPQ2pORxllThBEVxADVEY8FBdZQA9DXhURFEtYbh9qTRNGRU0PAEEEWQhOTwYLVT4dUkQNE0JXQU1HRhZUFUMSR14aA1FEXxQBEx5BEgBHFFATaRUMCV1ACAEBVVIBB1JUXQwf"

if let dec = xorDecode(payload) {
    print("Decoded string:")
    print(dec)
} else {
    print("Failed")
}
