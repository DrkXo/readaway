use std::sync::RwLock;
use std::time::{SystemTime, UNIX_EPOCH};
use once_cell::sync::Lazy;
use crate::frb_generated::StreamSink;

#[derive(Debug, Clone)]
pub struct RustLogEntry {
    pub time_millis: i64,
    pub level: i32, // 1 = error, 2 = warn, 3 = info, 4 = debug, 5 = trace
    pub tag: String,
    pub msg: String,
}

static LOG_SINK: Lazy<RwLock<Option<StreamSink<RustLogEntry>>>> =
    Lazy::new(|| RwLock::new(None));

struct DartBridgeLogger {}

impl log::Log for DartBridgeLogger {
    fn enabled(&self, _metadata: &log::Metadata) -> bool {
        true
    }

    fn log(&self, record: &log::Record) {
        let level = match record.level() {
            log::Level::Error => 1,
            log::Level::Warn => 2,
            log::Level::Info => 3,
            log::Level::Debug => 4,
            log::Level::Trace => 5,
        };

        let now_millis = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map(|d| d.as_millis() as i64)
            .unwrap_or(0);

        let entry = RustLogEntry {
            time_millis: now_millis,
            level,
            tag: record.target().to_string(),
            msg: record.args().to_string(),
        };

        if let Ok(guard) = LOG_SINK.read() {
            if let Some(sink) = guard.as_ref() {
                let _ = sink.add(entry);
            }
        }
    }

    fn flush(&self) {}
}

static DART_LOGGER: DartBridgeLogger = DartBridgeLogger {};

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_backtrace();
    let _ = log::set_logger(&DART_LOGGER);
    log::set_max_level(log::LevelFilter::Debug);
    log::info!("ReadAway native Rust core engine initialized successfully");
}

/// Creates a continuous stream of Rust log records forwarded to Dart.
pub fn create_log_stream(s: StreamSink<RustLogEntry>) {
    if let Ok(mut guard) = LOG_SINK.write() {
        *guard = Some(s);
    }
}

/// Returns true if the native Rust library is initialized and functional.
#[flutter_rust_bridge::frb(sync)]
pub fn is_rust_initialized() -> bool {
    true
}
