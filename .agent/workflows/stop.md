---
description: Stop ea-server and ea-client (kill all processes on trading ports)
---

// turbo-all

## Steps

1. Kill all processes on ports 5173, 8080, 8081, 4173 and ea-server.exe

```bash
taskkill //F //IM ea-server.exe 2>/dev/null; powershell -Command "foreach ($port in @(5173, 8080, 8081, 4173)) { Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue } }"; echo "All stopped"
```
