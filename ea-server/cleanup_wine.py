import re

def process(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Match the update_ea block recursively or roughly
    # We can just replace the whole text from `"update_ea" => {` to the next command `"restart_mt5" => {`
    # Let's find "update_ea" and replace everything until "restart_mt5"
    content = re.sub(r'[ \t]*"update_ea" => \{.*?(?=[ \t]*"restart_mt5" => \{)', '', content, flags=re.DOTALL)
    
    # And remove "restart_mt5" as well since it uses wine
    content = re.sub(r'[ \t]*"restart_mt5" => \{.*?(?=[ \t]*_ => \{|// --- End of action match ---)', '', content, flags=re.DOTALL)
    
    # Remove scan_mt5_instances entirely
    content = re.sub(r'fn scan_mt5_instances\(\).*?(?=async fn verify_ea_deployment)', '', content, flags=re.DOTALL)
    content = re.sub(r'fn scan_mt5_instances\(\).*?(?=\nasync fn )', '', content, flags=re.DOTALL)
    content = re.sub(r'fn get_wine_appdata\(\).*?(?=\nfn |\nasync fn )', '', content, flags=re.DOTALL)
    content = re.sub(r'async fn verify_ea_deployment\(\).*?(?=\nfn |\nasync fn )', '', content, flags=re.DOTALL)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
        
    print("Cleaned up MT5 specific local Windows deployment.")

process("/Users/somkidchaihanid/Desktop/ea-24/ea-server/src/main.rs")
