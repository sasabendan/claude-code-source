// kb-rust: LLM Wiki Manager - Markdown files + JSONL index, no SQLite
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::io::Write;
use std::path::PathBuf;
use std::process;
use walkdir::WalkDir;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct KbEntry {
    #[serde(alias = "type")]
    pub entry_type: String,
    pub name: String,
    pub file: Option<String>,
    pub tags: String,
    pub created: String,
    #[serde(flatten)]
    pub extra: HashMap<String, serde_json::Value>,
}

pub struct KbManager { kb_dir: PathBuf }

impl KbManager {
    fn new(kb_dir: &str) -> Self { KbManager { kb_dir: PathBuf::from(kb_dir) } }
    fn index_path(&self) -> PathBuf { self.kb_dir.join(".index.jsonl") }

    fn load_index(&self) -> Vec<KbEntry> {
        let path = self.index_path();
        if !path.exists() {
            return vec![];
        }
        let content = fs::read_to_string(&path).unwrap_or_default();
        let entries: Vec<KbEntry> = content.lines()
            .filter(|l| !l.trim().is_empty())
            .filter_map(|l| {
                let result = serde_json::from_str::<KbEntry>(l);
                if result.is_err() {
                }
                result.ok()
            })
            .collect();
        entries
    }

    fn add_entry(&self, entry: &KbEntry) -> std::io::Result<()> {
        let mut f = fs::OpenOptions::new().create(true).append(true).open(self.index_path())?;
        let line = serde_json::to_string(entry).unwrap();
        f.write_all(line.as_bytes())?;
        f.write_all(b"\n")
    }

    fn search(&self, keyword: &str) -> Vec<KbEntry> {
        let k = keyword.to_lowercase();
        self.load_index().into_iter()
            .filter(|e| e.name.to_lowercase().contains(&k) || e.tags.to_lowercase().contains(&k))
            .collect()
    }

    fn list_by_type(&self, t: &str) -> Vec<KbEntry> {
        self.load_index().into_iter().filter(|e| e.entry_type == t).collect()
    }

    fn list_all(&self) -> HashMap<String, usize> {
        let mut types = HashMap::new();
        for e in self.load_index() { *types.entry(e.entry_type).or_insert(0) += 1; }
        types
    }

    fn rebuild_index(&self) -> std::io::Result<usize> {
        let mut entries = vec![];
        for entry in WalkDir::new(&self.kb_dir).follow_links(true).into_iter().filter_map(|e| e.ok()) {
            let path = entry.path();
            if !path.is_file() { continue; }
            let ext = path.extension().and_then(|e| e.to_str()).unwrap_or("");
            if ext != "md" { continue; }
            let fname = path.file_name().and_then(|n| n.to_str()).unwrap_or("");
            if fname == ".index.jsonl" { continue; }
            let content = fs::read_to_string(path).unwrap_or_default();
            let name = content.lines().next().map(|l| l.trim_start_matches("# ").to_string()).unwrap_or_default();
            let entry_type = infer_type(path);
            let tags = extract_tags(&content);
            let created = extract_created(&content);
            let rel = path.strip_prefix(&self.kb_dir).ok().and_then(|p| p.to_str()).map(|s| s.to_string());
            entries.push(KbEntry { entry_type, name, file: rel, tags, created, extra: HashMap::new() });
        }
        entries.sort_by(|a, b| b.created.cmp(&a.created));
        let count = entries.len();
        let mut f = fs::File::create(self.index_path())?;
        for e in &entries {
            let line = serde_json::to_string(e).unwrap();
            f.write_all(line.as_bytes())?;
            f.write_all(b"\n")?;
        }
        Ok(count)
    }
}

fn infer_type(path: &std::path::Path) -> String {
    let parent = path.parent().and_then(|p| p.file_name()).and_then(|n| n.to_str()).unwrap_or("experience");
    match parent {
        "experience" => "experience".to_string(),
        "styles" => "style".to_string(),
        "plot" => "plot".to_string(),
        "characters" => "character".to_string(),
        "world" => "world".to_string(),
        "voices" => "voice".to_string(),
        _ => parent.to_string(),
    }
}

fn extract_tags(content: &str) -> String {
    content.lines().filter(|l| l.starts_with("tags:"))
        .map(|l| l.trim_start_matches("tags:").trim()).collect::<Vec<_>>().join(", ")
}

fn extract_created(content: &str) -> String {
    content.lines().filter(|l| l.starts_with("created:"))
        .map(|l| l.trim_start_matches("created:").trim()).next().unwrap_or("").to_string()
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.len() < 2 {
        println!("kb-rust: LLM Wiki Manager (MD + JSONL, no SQLite)");
        println!("  init        Init KB structure");
        println!("  add <name> <type> <tags>  Add");
        println!("  list        List by type");
        println!("  query <type>  Query");
        println!("  search <kw>  Search");
        println!("  rebuild     Rebuild index from MDs");
        println!("  --kb-dir <path>  Set KB dir");
        process::exit(0);
    }

    let mut kb_dir_str = "knowledge-base".to_string();
    let mut cmd_idx = 1;
    for (i, arg) in args.iter().enumerate() {
        if arg == "--kb-dir" && i+1 < args.len() {
            kb_dir_str = args[i+1].clone();
            cmd_idx = i + 2;
        }
    }
    let kb = KbManager::new(&kb_dir_str);

    if cmd_idx >= args.len() { process::exit(0); }
    let cmd = &args[cmd_idx];
    match cmd.as_str() {
        "init" => {
            for sub in &["experience","styles","plot","characters","world","voices"] {
                fs::create_dir_all(kb_dir_str.clone() + "/" + sub).ok();
            }
            println!("✅ KB structure ready");
        }
        "add" => {
            if cmd_idx+3 >= args.len() { eprintln!("❌ add <name> <type> <tags>"); process::exit(1); }
            let entry = KbEntry {
                entry_type: args[cmd_idx+1].clone(),
                name: args[cmd_idx+2].clone(),
                file: None,
                tags: args[cmd_idx+3].clone(),
                created: chrono::Utc::now().to_rfc3339().to_string(),
                extra: HashMap::new(),
            };
            if let Err(e) = kb.add_entry(&entry) { eprintln!("❌ {}", e); process::exit(1); }
            println!("✅ Added [{}] {}", entry.entry_type, entry.name);
        }
        "list" => {
            let types = kb.list_all();
            let total: usize = types.values().sum();
            println!("Total: {} entries", total);
            for (t, c) in types { println!("  {}: {}", t, c); }
        }
        "query" => {
            if cmd_idx+1 >= args.len() { eprintln!("❌ query <type>"); process::exit(1); }
            let results = kb.list_by_type(&args[cmd_idx+1]);
            println!("{} entries:", results.len());
            for e in results { println!("  {} | {}", e.name, e.tags); }
        }
        "search" => {
            if cmd_idx+1 >= args.len() { eprintln!("❌ search <keyword>"); process::exit(1); }
            let results = kb.search(&args[cmd_idx+1]);
            println!("{} results for '{}':", results.len(), args[cmd_idx+1]);
            for e in results { println!("  [{}] {} | {}", e.entry_type, e.name, e.tags); }
        }
        "rebuild" => {
            match kb.rebuild_index() {
                Ok(c) => println!("✅ Rebuilt: {} entries", c),
                Err(e) => { eprintln!("❌ {}", e); process::exit(1); }
            }
        }
        "--kb-dir" => {}
        _ => { eprintln!("❌ unknown: {}", cmd); process::exit(1); }
    }
}
