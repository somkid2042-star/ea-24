import asyncio
import websockets
import json

async def test():
    uri = "ws://242.147.187.35.bc.googleusercontent.com:8080"
    try:
        async with websockets.connect(uri) as ws:
            print("Connected!")
            req = {
                "action": "upload_video_from_url",
                "url": "https://t.me/c/3128090090/4077"
            }
            await ws.send(json.dumps(req))
            while True:
                resp = await asyncio.wait_for(ws.recv(), timeout=15.0)
                if "upload_video_status" in resp:
                    print("Received:", resp)
    except asyncio.TimeoutError:
        print("Timeout! No more messages.")
    except Exception as e:
        print("Error:", e)

asyncio.run(test())
