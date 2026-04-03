#!/bin/bash
TARGET="./ea-server/mt5/EATradingClient.mq5"
TMP_FILE="/tmp/EATradingClient.mq5"

cat "$TARGET" | awk '
/copied = CopyRates\(sym, tf, start_time, stop_time, rates\);/ {
    print "         // Try to copy rates up to 3 times to allow MT5 background download"
    print "         int retries = 0;"
    print "         while(copied <= 0 && retries < 3) {"
    print "            copied = CopyRates(sym, tf, start_time, stop_time, rates);"
    print "            if(copied > 5000) copied = 5000;"
    print "            if(copied <= 0) { Sleep(1500); retries++; }"
    print "         }"
    next
}
/copied = CopyRates\(sym, tf, 0, \(int\)count, rates\);/ {
    print "         // Try to copy rates up to 3 times to allow MT5 background download"
    print "         int retries = 0;"
    print "         while(copied <= 0 && retries < 3) {"
    print "            copied = CopyRates(sym, tf, 0, (int)count, rates);"
    print "            if(copied <= 0) { Sleep(1500); retries++; }"
    print "         }"
    next
}
/if\(copied > 5000\) copied = 5000; \/\/ Max safety limit/ { next }
{print}
' > "$TMP_FILE"

cp "$TMP_FILE" "$TARGET"
echo "Patch applied successfully."
