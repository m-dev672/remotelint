use axum::{
    extract::Path,
    extract::Multipart,
    http::StatusCode,
    response::IntoResponse,
    routing::post,
    Router,
};
use axum_server::tls_rustls::RustlsConfig;
use std::{
    net::SocketAddr,
    fs::{
        File,
        create_dir,
        remove_dir_all
    },
    io::{
        BufReader,
        Write,
        Read
    },
    collections::HashMap,
    process::Command
};
use uuid::Uuid;

type Tools = HashMap<String, HashMap<String, String>>;

#[tokio::main]
async fn main() {
    let config = RustlsConfig::from_pem_file(
        format!("{}{}", std::env::var("HOME").unwrap(), "/.sibyl/certs/cert.pem"),
        format!("{}{}", std::env::var("HOME").unwrap(), "/.sibyl/certs/key.pem")
    )
    .await
    .unwrap();

    let app = Router::new().route("/:tooltype/:toolname", post(handler));

    let addr = SocketAddr::from(([0, 0, 0, 0], 3000));
    axum_server::bind_rustls(addr, config)
        .serve(app.into_make_service())
        .await
        .unwrap();
}

async fn handler(
    Path((tooltype, toolname)): Path<(String, String)>, mut multipart: Multipart) -> impl IntoResponse {
    if tooltype == "linter".to_string() || tooltype == "formatter".to_string() {
        if let Some(field) = multipart.next_field().await.unwrap() {
            let session_id = Uuid::new_v4().to_string();
            let workdir = format!("{}{}{}{}", std::env::var("HOME").unwrap(), "/.sibyl/workbench/", &session_id, "/");
            match create_dir(&workdir) {
                Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR, "INTERNAL_SERVER_ERROR\n".to_string()),
                Ok(_) => 0,
            };
            
            let file_name = field.file_name().unwrap().to_string();
            let bytes = field.bytes().await.unwrap();
            let file = File::create(format!("{}{}", &workdir, &file_name));
            file.expect("").write_all(&bytes).unwrap();
            
            let tools_json = File::open(format!("{}{}", std::env::var("HOME").unwrap(), "/.sibyl/tools.json")).unwrap();
            let tools_json_reader = BufReader::new(tools_json);
            let tools: Tools = serde_json::from_reader(tools_json_reader).unwrap();

            let mut output = String::from_utf8_lossy(
                &Command::new("sh")
                    .args(&["-c", &tools[&tooltype][&toolname].replace("{{ target }}", &format!("$'{}{}'", &workdir, &file_name.replace("'", "\'")))])
                    .output().expect("").stdout
            ).to_string();

            if tooltype == "formatter".to_string() {
                let file = File::open(format!("{}{}", &workdir, &file_name));
                output = String::new();
                match file.expect("").read_to_string(&mut output) {
                    Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR, "INTERNAL_SERVER_ERROR\n".to_string()),
                    Ok(_) => 0,
                };
            }

            match remove_dir_all(workdir) {
                Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR, "INTERNAL_SERVER_ERROR\n".to_string()),
                Ok(_) => 0,
            };

            return (StatusCode::OK, output);
        }
    }

    (StatusCode::BAD_REQUEST, "BAD_REQUEST\n".to_string())
}
