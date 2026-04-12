import os
import re

directory = '/Users/somkidchaihanid/Desktop/ea-24/ea-ios/EA24'

def fix_fonts(content):
    # .font(.custom("CamingoCode", size: X).weight(.Y))
    content = re.sub(
        r'\.font\(\.custom\("CamingoCode",\s*size:\s*([0-9.]+)\)\.weight\(\.([a-zA-Z]+)\)\)',
        r'.font(ThemeFont.custom(size: \1, weight: .\2))',
        content
    )
    # .font(.custom("CamingoCode", size: X)).fontWeight(.Y)
    content = re.sub(
        r'\.font\(\.custom\("CamingoCode",\s*size:\s*([0-9.]+)\)\)\.fontWeight\(\.([a-zA-Z]+)\)',
        r'.font(ThemeFont.custom(size: \1, weight: .\2))',
        content
    )
    # .font(.custom("CamingoCode", size: X))  (no weight chained)
    content = re.sub(
        r'\.font\(\.custom\("CamingoCode",\s*size:\s*([0-9.]+)\)\)',
        r'.font(ThemeFont.custom(size: \1))',
        content
    )
    return content

for root, _, files in os.walk(directory):
    for f in files:
        if f.endswith('.swift'):
            path = os.path.join(root, f)
            with open(path, 'r', encoding='utf-8') as file:
                content = file.read()
            new_content = fix_fonts(content)
            if new_content != content:
                with open(path, 'w', encoding='utf-8') as file:
                    file.write(new_content)
                print(f"Fixed {f}")
