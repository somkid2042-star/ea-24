use serde_json::Value;

fn main() {
    let response = r#"
{
  "sentiment": "NEUTRAL",
  "summary": "สรุปข้อมูล",
  "stories": [
    {
      "title": "หัวข้อ",
      "content": "เนื้อหา"
    }
  ]
}
"#;
    let start = response.find('{');
    let end = response.rfind('}');
    let clean_json = match (start, end) {
        (Some(s), Some(e)) if s < e => &response[s..=e],
        _ => response.trim()
    };
    
    match serde_json::from_str::<Value>(clean_json) {
        Ok(_) => println!("OK!"),
        Err(e) => println!("Error: {}", e),
    }
}
