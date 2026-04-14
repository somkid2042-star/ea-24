import json
import psycopg2

def run():
    # Read netflix cookies
    with open('otp24-reader/netflix_cookies.json', 'r') as f:
        cookies = json.load(f)

    # Format payload
    payload = {
        "status": "ok",
        "target_url": "https://www.netflix.com",
        "cookies": cookies
    }
    payload_str = json.dumps(payload)

    # Connect to db
    conn = psycopg2.connect(dbname="ea24", user="postgres", password="postgres", host="localhost")
    cur = conn.cursor()

    # Create table if not exists (to be safe, though rust does it too)
    cur.execute("""
        CREATE TABLE IF NOT EXISTS otp24_cache (
            id          BIGSERIAL PRIMARY KEY,
            cache_key   TEXT NOT NULL,
            payload     TEXT NOT NULL,
            updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
        CREATE INDEX IF NOT EXISTS idx_otp24_cache_key ON otp24_cache(cache_key);
    """)

    # Insert into cookie_779 up to cookie_805 (all netflix nodes)
    for i in range(779, 810):
        key = f"cookie_{i}"
        cur.execute("INSERT INTO otp24_cache (cache_key, payload) VALUES (%s, %s)", (key, payload_str))
        
    # Inject nodes_26 cache to bypass live server completely (Netflix app_id is 26)
    nodes_payload = [{"id": 779, "is_working": 1, "can_access": 1, "name": "Netflix Mock Server"}]
    cur.execute("INSERT INTO otp24_cache (cache_key, payload) VALUES (%s, %s)", ("nodes_26", json.dumps(nodes_payload)))
        
    conn.commit()
    cur.close()
    conn.close()
    print("Injected netflix cookies successfully into postgres db (ea24).")

if __name__ == "__main__":
    run()
