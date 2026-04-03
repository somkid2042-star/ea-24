import re

def stub_functions(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Stub out get_wine_appdata()
    content = re.sub(
        r'fn get_wine_appdata\(\) -> PathBuf \{.*?(?=\nfn |\nasync fn)', 
        'fn get_wine_appdata() -> PathBuf {\n    PathBuf::from("/tmp/ea24_mock_appdata")\n}', 
        content, flags=re.DOTALL
    )

    # Stub out scan_mt5_instances() 
    content = re.sub(
        r'fn scan_mt5_instances\(\) -> Vec<Mt5Instance> \{.*?(?=\nasync fn )', 
        'fn scan_mt5_instances() -> Vec<Mt5Instance> {\n    vec![]\n}', 
        content, flags=re.DOTALL
    )

    # Remove Wine execution in launch_mt5_by_id
    content = re.sub(
        r'fn launch_mt5_by_id\(target_id: &str\) -> bool \{.*?(?=\nfn |\nasync fn)',
        'fn launch_mt5_by_id(target_id: &str) -> bool {\n    false\n}',
        content, flags=re.DOTALL
    )
    
    # Remove Wine/xdotool execution in kill_mt5_instance
    content = re.sub(
        r'fn kill_mt5_instance\(install_dir: &str\) \{.*?(?=\nfn |\nasync fn)',
        'fn kill_mt5_instance(_install_dir: &str) {\n    \n}',
        content, flags=re.DOTALL
    )

    # Empty out update_ea block to just send error or success without using wine
    content = re.sub(
        r'("update_ea" => \{).*?(\n[ \t]*\})[ \t]*(?=\n[ \t]*"restart_mt5")',
        r'\1\n                                        let resp = serde_json::json!({\n                                            "type": "deploy_status",\n                                            "status": "error",\n                                            "message": "EA update via Wine is disabled on Ubuntu headless server."\n                                        });\n                                        let _ = write.send(Message::Text(resp.to_string())).await;\n                                    }',
        content, flags=re.DOTALL
    )

    with open(filepath, 'w') as f:
        f.write(content)

stub_functions("/Users/somkidchaihanid/Desktop/ea-24/ea-server/src/main.rs")
