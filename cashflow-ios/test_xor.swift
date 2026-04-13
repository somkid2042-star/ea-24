import Foundation

let payload = "MzE7ISttfXlycndlbnw8ISx1cHJiNyk+eGBkNjV6cmVhe2VnaHNkYiA7NyRTeHlsYWJmfTk5Z21sOTYnbXllcHxjcjkmfDsyIDomZWNgbXhgZHN4ZnwhNjcxUks0DSo5YXJ0bXtsaGx0eSowOjUlRV4nLDw2ZmxvdyQvIiUmW2suPzsze21udHBicjMvOyE2S2snMTg6cn1iY2N2PS4rLjNXaz4oLyYmdnxgYz41Jic9V2soNi8nci1qZ392bSZ/cGJlbgIAZGpwbm1ie2hhY3ZqYn9mNURBKiQjNyYpeHBubWJ/ZnNuZHtyEgRyYWpiZzckIiIyQUUtODsmd21iYGBubWJ/ZnNuZHtyAAN2bHV2IzQ8PTEmV2soPCcnYH9lcWN2Ny0tLjdXRjQpeHlsYWJmfTY3dms0NTo4NyMreGBkdj8yNykpS2s1KiR9am9wd21iYDs9ITNTeHlsYWJmfSkzJio7RlYpOTshNntvYHZvYi09NC0mW2soNy8ldXZidjwgKCklQUYkMTs+YWJkZy0rIz4LVWs5PCQnYWpwb3Z9eGxsbnxjdiU="
let secretKey = "OTP24HRHUB_PROTECT"

guard let data = Data(base64Encoded: payload) else { print("base64 failed"); exit(1) }
let keyBytes = Array(secretKey.utf8)
var decoded = [UInt8]()
for (i, byte) in data.enumerated() {
    decoded.append(byte ^ keyBytes[i % keyBytes.count])
}
print(String(bytes: decoded, encoding: .utf8) ?? "utf8 failed")
