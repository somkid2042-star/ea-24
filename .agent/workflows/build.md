---
description: Build ea-server with MSVC (requires VS Build Tools)
---

// turbo-all

## Steps

1. Set MSVC environment and build ea-server

```bash
cmd //C "\"C:\\Program Files (x86)\\Microsoft Visual Studio\\2022\\BuildTools\\VC\\Auxiliary\\Build\\vcvarsall.bat\" x64 && cd /d c:\\Users\\somkid\\Desktop\\ea-24\\ea-server && cargo build 2>&1 | tail -20"
```

If vcvarsall.bat path doesn't exist, try:
```bash
cmd //C "\"C:\\Program Files\\Microsoft Visual Studio\\2022\\BuildTools\\VC\\Auxiliary\\Build\\vcvarsall.bat\" x64 && cd /d c:\\Users\\somkid\\Desktop\\ea-24\\ea-server && cargo build 2>&1 | tail -20"
```
