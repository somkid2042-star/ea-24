from PIL import Image, ImageDraw, ImageFont
import os

icons_dir = "/Users/somkidchaihanid/Desktop/ea-24/ea-client/src-tauri/icons"

SIZE = 1024
BG = (21, 24, 33, 255)
FG = (255, 255, 255, 255)

# macOS standard: icon content is ~80% of total size, centered with ~10% padding each side
PADDING = int(SIZE * 0.10)
ICON_SIZE = SIZE - (PADDING * 2)  # ~819px
radius = int(ICON_SIZE * 0.2237)

# Fully transparent canvas
img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Draw squircle centered with padding
draw.rounded_rectangle(
    (PADDING, PADDING, PADDING + ICON_SIZE - 1, PADDING + ICON_SIZE - 1),
    radius=radius, fill=BG
)

# Draw "EA24" text centered within the squircle
font = None
for fp in ["/System/Library/Fonts/Supplemental/Arial Bold.ttf", "/System/Library/Fonts/Helvetica.ttc"]:
    if os.path.exists(fp):
        try:
            font = ImageFont.truetype(fp, size=int(ICON_SIZE * 0.30))
            break
        except:
            continue

text = "EA24"
bbox = draw.textbbox((0, 0), text, font=font) if font else draw.textbbox((0, 0), text)
tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
tx = (SIZE - tw) // 2 - bbox[0]
ty = (SIZE - th) // 2 - bbox[1]
draw.text((tx, ty), text, fill=FG, font=font) if font else draw.text((tx, ty), text, fill=FG)

# Delete all old files
for f in os.listdir(icons_dir):
    full = os.path.join(icons_dir, f)
    if os.path.isfile(full):
        os.remove(full)

# Generate all sizes
mac_sizes = {"icon.png": 512, "32x32.png": 32, "64x64.png": 64, "128x128.png": 128, "128x128@2x.png": 256}
win_sizes = {"Square30x30Logo.png": 30, "Square44x44Logo.png": 44, "Square71x71Logo.png": 71,
             "Square89x89Logo.png": 89, "Square107x107Logo.png": 107, "Square142x142Logo.png": 142,
             "Square150x150Logo.png": 150, "Square284x284Logo.png": 284, "Square310x310Logo.png": 310,
             "StoreLogo.png": 50}

for name, size in {**mac_sizes, **win_sizes}.items():
    resized = img.resize((size, size), Image.Resampling.LANCZOS)
    resized.save(os.path.join(icons_dir, name), "PNG")

img.resize((512, 512), Image.Resampling.LANCZOS).save(os.path.join(icons_dir, "icon.icns"), format="ICNS")

ico_sizes = [16, 24, 32, 48, 64, 128, 256]
ico_imgs = [img.resize((s, s), Image.Resampling.LANCZOS) for s in ico_sizes]
ico_imgs[0].save(os.path.join(icons_dir, "icon.ico"), format="ICO",
                 sizes=[(s, s) for s in ico_sizes], append_images=ico_imgs[1:])

print("✅ Done — standard macOS size with 10% padding!")
