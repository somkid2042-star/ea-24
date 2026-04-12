import os
import re

directory = '/Users/somkidchaihanid/Desktop/ea-24/ea-ios/EA24'

replacements = {
    r'\.font\(\.largeTitle\)': '.font(.eaLargeTitle)',
    r'\.font\(\.title\)': '.font(.eaTitle)',
    r'\.font\(\.title2\)': '.font(.eaTitle2)',
    r'\.font\(\.title3\)': '.font(.eaTitle3)',
    r'\.font\(\.headline\)': '.font(.eaHeadline)',
    r'\.font\(\.subheadline\)': '.font(.eaSubheadline)',
    r'\.font\(\.body\)': '.font(.eaBody)',
    r'\.font\(\.callout\)': '.font(.eaCallout)',
    r'\.font\(\.footnote\)': '.font(.eaFootnote)',
    r'\.font\(\.caption\)': '.font(.eaCaption)',
    r'\.font\(\.caption2\)': '.font(.eaCaption2)',
    r'\.font\(\.headline\.weight\(\.medium\)\)': '.font(.eaHeadline.weight(.medium))',
    r'\.font\(\.subheadline\.weight\(\.medium\)\)': '.font(.eaSubheadline.weight(.medium))',
    r'\.font\(\.subheadline\.bold\(\)\)': '.font(.eaSubheadline.weight(.bold))',
    r'\.font\(\.caption\.weight\(\.medium\)\)': '.font(.eaCaption.weight(.medium))',
    r'\.font\(\.caption\.weight\(\.semibold\)\)': '.font(.eaCaption.weight(.semibold))',
    r'\.font\(\.caption\.bold\(\)\)': '.font(.eaCaption.weight(.bold))',
}

def replace_system_fonts(content):
    # Standard named fonts
    for pattern, rep in replacements.items():
        content = re.sub(pattern, rep, content)
    
    # regex for .font(.system(size: X))
    content = re.sub(r'\.font\(\.system\(\s*size:\s*([0-9.]+)\s*\)\)', r'.font(.custom("CamingoCode", size: \1))', content)
    
    # regex for .font(.system(size: X, weight: .Y))
    content = re.sub(r'\.font\(\.system\(\s*size:\s*([0-9.]+),\s*weight:\s*\.([a-zA-Z]+)\s*\)\)', r'.font(.custom("CamingoCode", size: \1).weight(.\2))', content)
    
    # regex for .font(.system(size: X, weight: .Y, design: .Z))
    content = re.sub(r'\.font\(\.system\(\s*size:\s*([0-9.]+),\s*weight:\s*\.([a-zA-Z]+),\s*design:\s*\.[a-zA-Z]+\s*\)\)', r'.font(.custom("CamingoCode", size: \1).weight(.\2))', content)
    
    return content

for root, _, files in os.walk(directory):
    for f in files:
        if f.endswith('.swift'):
            path = os.path.join(root, f)
            with open(path, 'r', encoding='utf-8') as file:
                content = file.read()
            new_content = replace_system_fonts(content)
            if new_content != content:
                with open(path, 'w', encoding='utf-8') as file:
                    file.write(new_content)
                print(f"Updated {f}")

