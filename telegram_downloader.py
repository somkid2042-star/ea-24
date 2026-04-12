import os
import sys
import asyncio
import tempfile
from telethon import TelegramClient

API_ID = 2040
API_HASH = "b18441a1ff607e10a989891a5462e627"

async def main():
    if len(sys.argv) < 2:
        print("Usage: python3 telegram_downloader.py [--login <phone> | <telegram_url>]")
        sys.exit(1)

    client = TelegramClient('telegram_session', API_ID, API_HASH)

    if sys.argv[1] == "--login":
        phone = sys.argv[2]
        await client.connect()
        if not await client.is_user_authorized():
            print(f"Sending code to {phone}...")
            await client.send_code_request(phone)
            code = input("Enter the 5-digit code: ")
            await client.sign_in(phone, code)
            print("Login successful! telegram_session.session created.")
        else:
            print("Already logged in.")
        await client.disconnect()
        return

    url = sys.argv[1]
    if not url.startswith("https://t.me/c/"):
        print("Error: Only private URLs (t.me/c/) are supported by this downloader.")
        sys.exit(1)

    # e.g., https://t.me/c/3241081896/3609
    parts = url.split('/')
    if len(parts) < 6:
        print("Invalid URL format")
        sys.exit(1)
        
    chat_id = int("-100" + parts[4])
    msg_id = int(parts[5])

    await client.connect()
    if not await client.is_user_authorized():
        print("Not authorized. Run --login first.")
        await client.disconnect()
        sys.exit(1)

    print(f"Fetching message {msg_id} from {chat_id}...")
    message = await client.get_messages(chat_id, ids=msg_id)
    if not message or not message.media:
        print("Message not found or has no media.")
        sys.exit(1)

    fd, path = tempfile.mkstemp(suffix=".mp4")
    os.close(fd)
    
    print(f"Downloading to {path}...")
    await client.download_media(message, file=path)
    print(f"SUCCESS:{path}")
    await client.disconnect()

if __name__ == '__main__':
    asyncio.run(main())
