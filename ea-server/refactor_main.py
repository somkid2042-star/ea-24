import re

def main():
    with open("src/main.rs", "r") as f:
        code = f.read()

    # 1. Replace start_telegram_bot_loop with start_discord_bot
    code = code.replace("notify::start_telegram_bot_loop(tg_db, tg_tx, tg_ea_state).await;", "crate::discord_bot::start_discord_bot(tg_db, tg_tx, tg_ea_state).await;")

    # 2. Replace Job parameter telegram_alert with discord_alert
    code = code.replace('let telegram_alert = job["telegram_alert"].as_bool().unwrap_or(false);', 'let telegram_alert = job["telegram_alert"].as_bool().unwrap_or(false);\n                    let discord_alert = job["discord_alert"].as_bool().unwrap_or(telegram_alert);')

    # 3. Replace all notify::send_telegram_notify blocks in main loop (indentation varies, use regex)
    # The pattern matches:
    # if telegram_alert {
    #     let tg_token = ...
    #     let tg_chat = ...
    #     notify::send_telegram_notify(&tg_token, &tg_chat, ...).await;
    # }
    
    pattern = re.compile(
        r'if telegram_alert\s*\{\s*let tg_token = db_ai\.get_config\("telegram_bot_token"\)\.await\.unwrap_or_default\(\);\s*let tg_chat = db_ai\.get_config\("telegram_chat_id"\)\.await\.unwrap_or_default\(\);\s*notify::send_telegram_notify\(&tg_token, &tg_chat, &(format!\(.*?\)|\w+)\)\.await;\s*\}', 
        re.DOTALL
    )

    def replacer(match):
        msg_expr = match.group(1)
        # Determine channel based on context
        if "News Avoidance" in msg_expr or "NewsUpdate" in msg_expr:
            chan_key = '"discord_channel_news"'
        elif "Summary" in msg_expr or "Daily" in msg_expr or "PnL" in msg_expr:
            chan_key = '"discord_channel_report"'
        else:
            chan_key = '"discord_channel_order"'
            
        space = "                                        "
        return f"""if discord_alert {{
{space}    let chan_id = db_ai.get_config({chan_key}).await.unwrap_or_default();
{space}    crate::discord_bot::send_to_channel(&chan_id, &{msg_expr}).await;
{space}}}"""

    code = pattern.sub(replacer, code)

    # 4. Handle global news check loop (not db_ai, but global_ai_db)
    pattern2 = re.compile(
        r'let tg_token = global_ai_db\.get_config\("telegram_bot_token"\)\.await\.unwrap_or_default\(\);\s*let tg_chat = global_ai_db\.get_config\("telegram_chat_id"\)\.await\.unwrap_or_default\(\);\s*if !tg_token\.is_empty\(\)[\s\S]*?notify::send_telegram_notify\(&tg_token, &tg_chat, &news_msg\)\.await;\s*\}',
        re.DOTALL
    )
    def replacer2(match):
        return """let chan_id = global_ai_db.get_config("discord_channel_news").await.unwrap_or_default();
                        crate::discord_bot::send_to_channel(&chan_id, &news_msg).await;"""
    code = pattern2.sub(replacer2, code)

    # 5. Handle journal loop (journal_db)
    pattern3 = re.compile(
        r'let tg_token = journal_db\.get_config\("telegram_bot_token"\)\.await\.unwrap_or_default\(\);\s*let tg_chat = journal_db\.get_config\("telegram_chat_id"\)\.await\.unwrap_or_default\(\);\s*if !tg_token\.is_empty\(\)[\s\S]*?notify::send_telegram_notify\(&tg_token, &tg_chat, &msg\)\.await;\s*\}',
        re.DOTALL
    )
    def replacer3(match):
        return """let chan_id = journal_db.get_config("discord_channel_report").await.unwrap_or_default();
                    crate::discord_bot::send_to_channel(&chan_id, &msg).await;"""
    code = pattern3.sub(replacer3, code)
    
    # 6. Replace test_telegram_notify -> test_discord_notify
    code = code.replace('"test_telegram_notify" => {', '"test_discord_notify" => {')
    code = code.replace('let bot_token = db.get_config("telegram_bot_token").await.unwrap_or_default();', 'let chan_id = db.get_config("discord_channel_report").await.unwrap_or_default();')
    code = code.replace('let chat_id = db.get_config("telegram_chat_id").await.unwrap_or_default();', '')
    code = code.replace('let ok = notify::send_telegram_notify(&bot_token, &chat_id, "✅ ทดสอบแจ้งเตือน EA-24\\nระบบแจ้งเตือนผ่าน Telegram ทำงานปกติ!").await;', 'let ok = crate::discord_bot::send_to_channel(&chan_id, "✅ ทดสอบแจ้งเตือน EA-24\\nระบบแจ้งเตือนผ่าน Discord ทำงานปกติ!").await;')


    with open("src/main.rs", "w") as f:
        f.write(code)
    
    print("Python substitution done!")

if __name__ == '__main__':
    main()
