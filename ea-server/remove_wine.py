import io

def process():
    with open('/Users/somkidchaihanid/Desktop/ea-24/ea-server/src/main.rs', 'r', encoding='utf-8') as f:
        lines = f.readlines()

    out = []
    ignoring = False
    brace_level = 0
    
    for i, line in enumerate(lines):
        if "fn get_wine_appdata()" in line:
            ignoring = True
            brace_level = 0
            
        if "fn scan_mt5_instances()" in line:
            ignoring = True
            brace_level = 0
            
        if "\"update_ea\" => {" in line:
            ignoring = True
            brace_level = 0
            
        if "\"restart_mt5\" => {" in line:
            ignoring = True
            brace_level = 0
            
        if ignoring:
            brace_level += line.count("{")
            brace_level -= line.count("}")
            if brace_level == 0 and ("{" in line or "}" in line):
                ignoring = False
        else:
            out.append(line)

    with open('/Users/somkidchaihanid/Desktop/ea-24/ea-server/src/main.rs', 'w', encoding='utf-8') as f:
        f.writelines(out)

process()
