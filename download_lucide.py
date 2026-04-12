import os
import urllib.request
import json

base_url = "https://raw.githubusercontent.com/lucide-icons/lucide/main/icons/"
asset_dir = "/Users/somkidchaihanid/Desktop/ea-24/ea-ios/EA24/Assets.xcassets"

# All icons needed for EA-24 trading app
icons = [
    # Header
    "user", "bell", "menu",
    # Banner / PnL
    "arrow-up-right", "arrow-down-right", "trending-up", "trending-down",
    # Categories (Grid)
    "bar-chart-2", "list", "zap", "settings", "chart-candlestick",
    # Signals
    "arrow-up-circle", "arrow-down-circle", "minus-circle",
    # Tab Bar
    "home", "clipboard-list", "plus", "gear",
    # Sidebar
    "layout-dashboard", "globe", "cpu", "history", "log-out", "chevron-right",
    # Settings / Extra
    "server", "network", "trash-2", "rotate-ccw",
    # Nav
    "chevron-down",
]

contents_json = {
    "images": [{"filename": "icon.svg", "idiom": "universal"}],
    "info": {"author": "xcode", "version": 1},
    "properties": {"preserves-vector-representation": True}
}

ok = 0
fail = 0

for icon in icons:
    imageset_path = os.path.join(asset_dir, f"lucide-{icon}.imageset")
    os.makedirs(imageset_path, exist_ok=True)
    
    svg_url = f"{base_url}{icon}.svg"
    svg_path = os.path.join(imageset_path, "icon.svg")
    
    try:
        urllib.request.urlretrieve(svg_url, svg_path)
        # Fix currentColor -> #000000 so Xcode can render as template
        with open(svg_path, "r") as f:
            content = f.read()
        content = content.replace('stroke="currentColor"', 'stroke="#000000"')
        content = content.replace('fill="currentColor"', 'fill="#000000"')
        with open(svg_path, "w") as f:
            f.write(content)
        # Write Contents.json
        with open(os.path.join(imageset_path, "Contents.json"), "w") as f:
            json.dump(contents_json, f, indent=2)
        print(f"  ✅ {icon}")
        ok += 1
    except Exception as e:
        print(f"  ❌ {icon}: {e}")
        fail += 1

print(f"\nDone: {ok} ok, {fail} failed")
