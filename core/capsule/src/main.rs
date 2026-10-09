use serde_json::json;

fn main() {
    let data = json!({
        "component": "SID",
        "build": "cache_verified"
    });

    println!("SID capsule started: {}", data);
}
