---
description: Start ea-server and ea-client (kill existing ports if busy)
---

// turbo-all

## Steps

1. Kill any processes using ports 5173, 8080, 8081, 4173

```bash
powershell -Command "foreach ($port in @(5173, 8080, 8081, 4173)) { Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue } }"
```

2. Wait 2 seconds for ports to be released

```bash
sleep 2
```

3. Start ea-server from debug binary (working directory must be ea-server for DB path)

```bash
cd c:/Users/somkid/Desktop/ea-24/ea-server && ./target/debug/ea-server.exe &
```

4. Wait 2 seconds for server to initialize

```bash
sleep 2
```

5. Start ea-client Vite dev server on port 5173

```bash
PATH="/c/Users/somkid/Desktop/ea-24/node-v22.14.0-win-x64:$PATH" npm run dev --prefix c:/Users/somkid/Desktop/ea-24/ea-client
```

This starts Vite on http://localhost:5173/ and ea-server on ports 8080/8081/4173.
