//! task-book-keeper
//! 
//! TODO: 实现核心逻辑

use anyhow::Result;

pub fn init() -> Result<()> {
    tracing::info!("{} initialized", env!("CARGO_PKG_NAME"));
    Ok(())
}
