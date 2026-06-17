use actix_web::{web, App, HttpServer, HttpResponse, middleware};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Mutex;
use std::time::Instant;
use uuid::Uuid;

struct AppState {
    start_time: Instant,
    items: Mutex<HashMap<String, Item>>,
}

#[derive(Serialize, Deserialize, Clone)]
struct Item {
    id: String,
    name: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    description: Option<String>,
}

#[derive(Deserialize)]
struct ItemRequest {
    name: Option<String>,
    description: Option<String>,
}

async fn health() -> HttpResponse {
    HttpResponse::Ok().json(serde_json::json!({
        "status": "healthy",
        "service": "${{ values.serviceName }}"
    }))
}

async fn ready(data: web::Data<AppState>) -> HttpResponse {
    let uptime = data.start_time.elapsed().as_secs();
    HttpResponse::Ok().json(serde_json::json!({
        "status": "ready",
        "uptime_seconds": uptime
    }))
}

async fn metrics(data: web::Data<AppState>) -> HttpResponse {
    let uptime = data.start_time.elapsed().as_secs();
    let count = data.items.lock().unwrap().len();
    HttpResponse::Ok().json(serde_json::json!({
        "service": "${{ values.serviceName }}",
        "uptime_seconds": uptime,
        "items_count": count
    }))
}

async fn list_items(data: web::Data<AppState>) -> HttpResponse {
    let items = data.items.lock().unwrap();
    let result: Vec<&Item> = items.values().collect();
    HttpResponse::Ok().json(result)
}

async fn get_item(data: web::Data<AppState>, path: web::Path<String>) -> HttpResponse {
    let id = path.into_inner();
    let items = data.items.lock().unwrap();
    match items.get(&id) {
        Some(item) => HttpResponse::Ok().json(item),
        None => HttpResponse::NotFound().json(serde_json::json!({"error": "Item not found"})),
    }
}

async fn create_item(data: web::Data<AppState>, body: web::Json<ItemRequest>) -> HttpResponse {
    let name = match &body.name {
        Some(n) => n.clone(),
        None => return HttpResponse::BadRequest().json(serde_json::json!({"error": "name is required"})),
    };
    let item = Item {
        id: Uuid::new_v4().to_string(),
        name,
        description: body.description.clone(),
    };
    let mut items = data.items.lock().unwrap();
    items.insert(item.id.clone(), item.clone());
    HttpResponse::Created().json(item)
}

async fn update_item(
    data: web::Data<AppState>,
    path: web::Path<String>,
    body: web::Json<ItemRequest>,
) -> HttpResponse {
    let id = path.into_inner();
    let mut items = data.items.lock().unwrap();
    match items.get_mut(&id) {
        Some(item) => {
            if let Some(name) = &body.name {
                item.name = name.clone();
            }
            if let Some(desc) = &body.description {
                item.description = Some(desc.clone());
            }
            HttpResponse::Ok().json(item.clone())
        }
        None => HttpResponse::NotFound().json(serde_json::json!({"error": "Item not found"})),
    }
}

async fn delete_item(data: web::Data<AppState>, path: web::Path<String>) -> HttpResponse {
    let id = path.into_inner();
    let mut items = data.items.lock().unwrap();
    match items.remove(&id) {
        Some(_) => HttpResponse::NoContent().finish(),
        None => HttpResponse::NotFound().json(serde_json::json!({"error": "Item not found"})),
    }
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let port: u16 = std::env::var("PORT")
        .unwrap_or_else(|_| "${{ values.httpPort }}".to_string())
        .parse()
        .expect("PORT must be a number");

    let data = web::Data::new(AppState {
        start_time: Instant::now(),
        items: Mutex::new(HashMap::new()),
    });

    println!("${{ values.serviceName }} listening on port {}", port);

    HttpServer::new(move || {
        App::new()
            .app_data(data.clone())
            .route("/health", web::get().to(health))
            .route("/ready", web::get().to(ready))
            .route("/metrics", web::get().to(metrics))
            .route("/api/items", web::get().to(list_items))
            .route("/api/items/{id}", web::get().to(get_item))
            .route("/api/items", web::post().to(create_item))
            .route("/api/items/{id}", web::put().to(update_item))
            .route("/api/items/{id}", web::delete().to(delete_item))
    })
    .bind(("0.0.0.0", port))?
    .run()
    .await
}
