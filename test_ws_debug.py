import asyncio
import websockets
import json

async def test():
    uri = "ws://242.147.187.35.bc.googleusercontent.com:8080"
    try:
        async with websockets.connect(uri) as ws:
            # Wait for welcome message first
            welcome = await asyncio.wait_for(ws.recv(), timeout=5.0)
            data = json.loads(welcome)
            print(f"SERVER VERSION: {data.get('server_version', 'UNKNOWN')}")
            print(f"Server uptime: {data.get('server_uptime_secs', '?')} secs")
            
            # Now send upload command
            req = {"action": "upload_video_from_url", "url": "https://t.me/c/3128090090/4077"}
            await ws.send(json.dumps(req))
            print(f"Sent: {json.dumps(req)}")
            
            # Collect ALL responses for 20 seconds
            for i in range(100):
                try:
                    resp = await asyncio.wait_for(ws.recv(), timeout=20.0)
                    data = json.loads(resp)
                    msg_type = data.get("type", "")
                    if "upload" in msg_type or "video" in msg_type or "error" in msg_type:
                        print(f">>> UPLOAD MSG: {resp}")
                except asyncio.TimeoutError:
                    print("TIMEOUT - no more messages after 20s")
                    break
    except Exception as e:
        print(f"Error: {e}")

asyncio.run(test())
