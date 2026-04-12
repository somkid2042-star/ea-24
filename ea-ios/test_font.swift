import Foundation
import CoreGraphics
import CoreText

let urls = [
    URL(fileURLWithPath: "/Users/somkidchaihanid/Desktop/ea-24/ea-ios/EA24/Fonts/CamingoCode-Regular.ttf"),
    URL(fileURLWithPath: "/Users/somkidchaihanid/Desktop/ea-24/ea-ios/EA24/Fonts/CamingoCode-Bold.ttf"),
    URL(fileURLWithPath: "/Users/somkidchaihanid/Desktop/ea-24/ea-ios/EA24/Fonts/CamingoCode-Italic.ttf"),
    URL(fileURLWithPath: "/Users/somkidchaihanid/Desktop/ea-24/ea-ios/EA24/Fonts/CamingoCode-BoldItalic.ttf")
]

for url in urls {
    guard let dataProvider = CGDataProvider(url: url as CFURL),
          let font = CGFont(dataProvider) else {
        print("Failed to load \(url.lastPathComponent)")
        continue
    }
    if let postScriptName = font.postScriptName {
        print("\(url.lastPathComponent) -> \(postScriptName)")
    } else {
        print("\(url.lastPathComponent) -> No PostScript name")
    }
}
