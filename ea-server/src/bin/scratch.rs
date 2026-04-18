use std::env;

#[tokio::main]
async fn main() {
    let pool = sqlx::postgres::PgPoolOptions::new()
        .connect("postgres://postgres:postgres@localhost:5432/ea24")
        .await
        .unwrap();

    let row: (String,) = sqlx::query_as("SELECT value FROM ea_config WHERE key = 'otp24_device_id'")
        .fetch_one(&pool)
        .await
        .unwrap_or(("NOT_FOUND".to_string(),));
        
    println!("=== DEVICE ID IN DB ===");
    println!("{}", row.0);
    println!("=======================");
}
