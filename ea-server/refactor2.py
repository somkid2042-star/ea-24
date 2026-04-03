import re
import sys

def process(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Match the update_ea block recursively or roughly
    # It's at: "update_ea" => { ... }
    # This is tricky with regex, simpler to just replace large chunks manually
    
process("/Users/somkidchaihanid/Desktop/ea-24/ea-server/src/main.rs")
