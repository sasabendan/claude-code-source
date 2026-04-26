// kb-rust v2: LLM Wiki Manager
// Based on Karpathy llm-wiki method: Ingest / Query / Lint
// Three layers: Raw Sources / Wiki / Schema
use regex::Regex;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::io::Write;
use std::path::PathBuf;
use std::process;
use walkdir::WalkDir;

const DEFAULT_WORKFLOW: &str = include_str!("default_workflow.md");

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct KbEntry {
    #[serde(alias = "type")]
    pub entry_type: String,
    pub name: String,
    pub file: Option<String>,
    pub tags: String,
    pub created: String,
    pub updated: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub status: Option<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub sources: Vec<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub backlinks: Vec<String>,
    #[serde(flatten)]
    pub extra: HashMap<String, serde_json::Value>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ProjectMeta {
    pub name: String,
    pub created: String,
    pub description: String,
    pub version: String,
}

pub struct KbManager {
    kb_dir: PathBuf,
    compiled_dir: PathBuf,
    workflow_file: PathBuf,
}

impl KbManager {
    fn new(kb_dir: &str) -> Self {
        let kb = PathBuf::from(kb_dir);
        KbManager {
            kb_dir: kb.clone(),
            compiled_dir: kb.join("_compiled"),
            workflow_file: kb.join("WORKFLOW.md"),
        }
    }

    fn index_path(&self) -> PathBuf { self.kb_dir.join(".index.jsonl") }
    fn project_path(&self) -> PathBuf { self.kb_dir.join(".project.json") }
    fn log_path(&self) -> PathBuf { self.compiled_dir.join("_log.md") }
    fn index_md_path(&self) -> PathBuf { self.compiled_dir.join("_index.md") }
    fn overview_path(&self) -> PathBuf { self.compiled_dir.join("_overview.md") }
    fn backlinks_path(&self) -> PathBuf { self.kb_dir.join("_backlinks.json") }

    fn ensure_index_exists(&self) -> std::io::Result<()> {
        let path = self.index_path();
        if !path.exists() { fs::File::create(path)?; }
        Ok(())
    }

    fn load_index(&self) -> Vec<KbEntry> {
        let path = self.index_path();
        if !path.exists() { return vec![]; }
        let content = fs::read_to_string(&path).unwrap_or_default();
        content.lines()
            .filter(|l| !l.trim().is_empty())
            .filter_map(|l| serde_json::from_str::<KbEntry>(l).ok())
            .collect()
    }

    fn add_entry(&self, entry: &KbEntry) -> std::io::Result<()> {
        let mut f = fs::OpenOptions::new().create(true).append(true).open(self.index_path())?;
        let line = serde_json::to_string(entry).unwrap();
        f.write_all(line.as_bytes())?;
        f.write_all(b"\n")
    }

    fn init_v2(&self) -> std::io::Result<()> {
        // Non-destructive: only create if missing (idempotent)
        for sub in &["characters","world","plot","styles","voices","experience"] {
            fs::create_dir_all(self.kb_dir.join(sub))?;
        }
        fs::create_dir_all(&self.compiled_dir)?;
        for sub in &["entities","concepts","synthesis"] {
            fs::create_dir_all(self.compiled_dir.join(sub))?;
        }
        self.ensure_index_exists()?;
        // Ensure _log.md header exists (non-destructive)
        if !self.log_path().exists() {
            fs::write(&self.log_path(), "# 知识库操作日志\n\n")?;
        }
        Ok(())
    }

    fn ensure_project(&self) -> std::io::Result<()> {
        if !self.project_path().exists() {
            let meta = ProjectMeta {
                name: "audio-comic-skills".to_string(),
                created: chrono::Utc::now().to_rfc3339(),
                description: "有声漫画自动化生产知识库".to_string(),
                version: "2.0.0".to_string(),
            };
            let s = serde_json::to_string_pretty(&meta).unwrap();
            fs::write(self.project_path(), s)?;
        }
        Ok(())
    }

    fn append_log(&self, entry_type: &str, description: &str) -> std::io::Result<()> {
        fs::create_dir_all(&self.compiled_dir)?;
        if !self.log_path().exists() {
            fs::write(&self.log_path(), "# 知识库操作日志\n\n")?;
        }
        let now = chrono::Local::now().format("%Y-%m-%d %H:%M:%S");
        let line = format!("## [{}] {} | {}\n\n", now, entry_type, description);
        fs::OpenOptions::new().append(true).open(&self.log_path())?
            .write_all(line.as_bytes())
    }

    fn load_backlinks(&self) -> HashMap<String, Vec<String>> {
        let path = self.backlinks_path();
        if !path.exists() { return HashMap::new(); }
        fs::read_to_string(&path).ok()
            .and_then(|s| serde_json::from_str(&s).ok())
            .unwrap_or_default()
    }

    fn save_backlinks(&self, bl: &HashMap<String, Vec<String>>) -> std::io::Result<()> {
        let s = serde_json::to_string_pretty(bl).unwrap();
        fs::write(self.backlinks_path(), s)
    }

    fn rebuild_index_v2(&self) -> std::io::Result<usize> {
        let mut entries = vec![];
        let mut backlinks: HashMap<String, Vec<String>> = HashMap::new();
        let wikilink_re = Regex::new(r"\[\[([^\]]+)\]\]").unwrap();

        for entry in WalkDir::new(&self.kb_dir)
            .follow_links(true)
            .into_iter().filter_map(|e| e.ok())
        {
            let path = entry.path();
            if !path.is_file() { continue; }
            let ext = path.extension().and_then(|e| e.to_str()).unwrap_or("");
            if ext != "md" { continue; }
            let fname = path.file_name().and_then(|n| n.to_str()).unwrap_or("");
            if fname.starts_with('.') || fname == "WORKFLOW.md" { continue; }
            let path_str = path.to_str().unwrap_or("");
            if path_str.contains("/_compiled/") { continue; }

            let content = fs::read_to_string(path).unwrap_or_default();
            // Fallback to filename (without .md) if no frontmatter name and no # heading
            let raw_name = extract_title(&content);
            let name = if raw_name.is_empty() {
                fname.trim_end_matches(".md").to_string()
            } else {
                raw_name
            };
            let entry_type = infer_type(path);
            let tags = extract_tags(&content);
            let created = extract_created(&content);
            let updated = extract_updated(&content);
            let status = extract_status(&content);
            let sources = extract_sources(&content);
            let rel = path.strip_prefix(&self.kb_dir).ok()
                .and_then(|p| p.to_str()).map(|s| s.to_string());

            for cap in wikilink_re.captures_iter(&content) {
                let target = cap.get(1).unwrap().as_str().trim().to_string();
                if let Some(ref rel) = rel {
                    let targets = backlinks.entry(target).or_insert_with(Vec::new);
                    if !targets.contains(rel) {
                        targets.push(rel.clone());
                    }
                }
            }

            entries.push(KbEntry {
                entry_type,
                name,
                file: rel,
                tags,
                created,
                updated,
                status,
                sources,
                backlinks: vec![],
                extra: HashMap::new(),
            });
        }

        entries.sort_by(|a, b| {
            let a_time = b.updated.as_ref().unwrap_or(&b.created).clone();
            let b_time = a.updated.as_ref().unwrap_or(&a.created).clone();
            b_time.cmp(&a_time)
        });

        let count = entries.len();

        let mut f = fs::File::create(self.index_path())?;
        for e in &entries {
            let bl_for_e = backlinks.get(&e.name).cloned().unwrap_or_default();
            let mut e2 = e.clone();
            e2.backlinks = bl_for_e;
            let line = serde_json::to_string(&e2).unwrap();
            f.write_all(line.as_bytes())?;
            f.write_all(b"\n")?;
        }

        self.save_backlinks(&backlinks)?;
        self.update_index_md(&entries)?;
        self.update_overview(&entries)?;

        Ok(count)
    }

    fn update_index_md(&self, entries: &[KbEntry]) -> std::io::Result<()> {
        fs::create_dir_all(&self.compiled_dir)?;
        let now = chrono::Local::now().format("%Y-%m-%d");
        let total = entries.len();

        let mut groups: HashMap<String, Vec<&KbEntry>> = HashMap::new();
        for e in entries {
            groups.entry(e.entry_type.clone()).or_insert_with(Vec::new).push(e);
        }

        let mut md = format!(
            "# 知识库索引\n\n最后更新：{}\n总条目：{}\n\n",
            now, total
        );

        for (etype, label) in [
            ("characters", "实体（Entities）"),
            ("experience", "经验知识"),
            ("styles", "风格参数"),
            ("plot", "剧情分解"),
            ("world", "世界观"),
            ("voices", "配音设定"),
        ] {
            if let Some(items) = groups.get(etype) {
                md.push_str(&format!("## {} \n", label));
                for e in items {
                    let ts = e.updated.as_deref().unwrap_or(&e.created);
                    md.push_str(&format!(
                        "- [{}]({}) - {} | {}\n",
                        e.name,
                        e.file.as_ref().unwrap_or(&String::new()),
                        e.tags,
                        &ts[..10.min(ts.len())]
                    ));
                }
                md.push('\n');
            }
        }

        md.push_str("## 最近更新\n");
        for e in entries.iter().take(10) {
            let ts = e.updated.as_deref().unwrap_or(&e.created);
            md.push_str(&format!("- [{}] {} - {} \n", &ts[..10.min(ts.len())], e.name, e.entry_type));
        }

        fs::write(&self.index_md_path(), md)
    }

    fn update_overview(&self, entries: &[KbEntry]) -> std::io::Result<()> {
        let now = chrono::Local::now().format("%Y-%m-%d %H:%M");
        let total = entries.len();
        let chars = entries.iter().filter(|e| e.entry_type == "characters").count();

        let md = format!(
            "# 知识库总览\n\n更新时间：{}\n\n- 总条目：{}\n- 角色数：{}\n\n## 关键发现\n\n（由 AI 在 ingest 时更新）\n\n## 最近更新\n\n（由 AI 在 ingest 时更新）\n",
            now, total, chars
        );

        fs::write(&self.overview_path(), md)
    }

    fn show_workflow(&self) -> std::io::Result<String> {
        if self.workflow_file.exists() {
            Ok(fs::read_to_string(&self.workflow_file)?)
        } else {
            Ok(DEFAULT_WORKFLOW.to_string())
        }
    }

    fn list_chars(&self) -> Vec<(String, String, String)> {
        self.load_index().iter()
            .filter(|e| e.entry_type == "characters")
            .map(|e| (e.name.clone(), e.status.clone().unwrap_or_else(|| "stable".to_string()), e.file.clone().unwrap_or_default()))
            .collect()
    }

    fn find_backlinks(&self, target: &str) -> Vec<String> {
        self.load_backlinks().get(target).cloned().unwrap_or_default()
    }

    fn show_project_info(&self) -> Option<ProjectMeta> {
        let path = self.project_path();
        if !path.exists() { return None; }
        fs::read_to_string(&path).ok().and_then(|s| serde_json::from_str(&s).ok())
    }

    fn sync_biji(&self) -> Result<String, String> {
        #[cfg(feature = "biji")]
        {
            Ok("Biji sync: not implemented yet".to_string())
        }
        #[cfg(not(feature = "biji"))]
        {
            Ok("Biji sync: requires --features biji".to_string())
        }
    }
}

fn infer_type(path: &std::path::Path) -> String {
    let parent = path.parent().and_then(|p| p.file_name())
        .and_then(|n| n.to_str()).unwrap_or("experience");
    match parent {
        "experience" => "experience".to_string(),
        "styles" => "styles".to_string(),
        "plot" => "plot".to_string(),
        "characters" => "characters".to_string(),
        "world" => "world".to_string(),
        "voices" => "voices".to_string(),
        _ => parent.to_string(),
    }
}

fn extract_title(content: &str) -> String {
    let mut in_front = false;
    for line in content.lines() {
        let trimmed = line.trim();
        if trimmed == "---" {
            in_front = !in_front;
            continue;
        }
        if in_front && trimmed.starts_with("name:") {
            return trimmed.trim_start_matches("name:").trim().to_string();
        }
        if !in_front && trimmed.starts_with("# ") {
            return trimmed.trim_start_matches("# ").to_string();
        }
    }
    String::new()
}

fn extract_tags(content: &str) -> String {
    let mut in_front = false;
    for line in content.lines() {
        let trimmed = line.trim();
        if trimmed == "---" {
            in_front = !in_front;
            continue;
        }
        if in_front && trimmed.starts_with("tags:") {
            let val = trimmed.trim_start_matches("tags:").trim();
            if val.starts_with('[') {
                return val.trim_start_matches('[').trim_end_matches(']')
                    .replace(", ", ",").trim().to_string();
            }
            return val.to_string();
        }
    }
    String::new()
}

fn extract_created(content: &str) -> String {
    content.lines()
        .filter(|l| l.starts_with("created:"))
        .map(|l| l.trim_start_matches("created:").trim())
        .next().unwrap_or("").to_string()
}

fn extract_updated(content: &str) -> Option<String> {
    content.lines()
        .filter(|l| l.starts_with("updated:"))
        .map(|l| l.trim_start_matches("updated:").trim().to_string())
        .next()
}

fn extract_status(content: &str) -> Option<String> {
    let mut in_front = false;
    for line in content.lines() {
        let trimmed = line.trim();
        if trimmed == "---" {
            in_front = !in_front;
            continue;
        }
        if in_front && trimmed.starts_with("status:") {
            return Some(trimmed.trim_start_matches("status:").trim().to_string());
        }
    }
    None
}

fn extract_sources(content: &str) -> Vec<String> {
    let mut in_front = false;
    for line in content.lines() {
        let trimmed = line.trim();
        if trimmed == "---" {
            in_front = !in_front;
            continue;
        }
        if in_front && trimmed.starts_with("sources:") {
            let val = trimmed.trim_start_matches("sources:").trim();
            if val.starts_with('[') {
                let inner = val.trim_start_matches('[').trim_end_matches(']');
                return inner.split(',')
                    .map(|s| s.trim().trim_matches('"').trim_matches('\'').to_string())
                    .filter(|s| !s.is_empty())
                    .collect();
            }
            break;
        }
    }
    vec![]
}

fn sanitize_filename(name: &str) -> String {
    let trimmed = name.trim();
    if trimmed.is_empty() { return "untitled".to_string(); }
    let mut out = String::with_capacity(trimmed.len());
    for ch in trimmed.chars() {
        let bad = matches!(ch, '/'|'\\'|':'|'*'|'?'|'"'|'<'|'>'|'|') || ch.is_control();
        if bad { out.push('_'); }
        else if ch.is_whitespace() { out.push('-'); }
        else { out.push(ch); }
    }
    let out = out.trim_matches(&['.', ' ', '-'][..]).to_string();
    if out.is_empty() { "untitled".to_string() } else { out }
}

fn print_usage() {
    println!("kb-rust v2: LLM Wiki Manager (Karpathy method)");
    println!();
    println!("v1 compatible commands:");
    println!("  init        Init KB structure (v2: _compiled/ + .project.json)");
    println!("  add <name> <type> <tags>  Add entry");
    println!("  list        List all entries by type");
    println!("  query <type>  Query by type");
    println!("  search <kw>  Full-text search");
    println!("  rebuild     Rebuild index (v2: + backlinks parsing)");
    println!();
    println!("v2 new commands:");
    println!("  workflow         Output WORKFLOW.md");
    println!("  chars            List all characters with status");
    println!("  backlinks <target>  Find files linking to target");
    println!("  project-info     Output project metadata");
    println!("  sync-biji        Sync GetBiji API (needs --features biji)");
    println!("  lint             Health check (orphans / bad entries / backlinks)");
    println!("  ingest <file>    Ingest source file -> update Wiki (.md only)");
    println!();
    println!("  --kb-dir <path>  Set KB directory");
    println!("  -h, --help       Show this help");
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.len() < 2 {
        print_usage();
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

    if args.iter().any(|a| a == "--help" || a == "-h") {
        print_usage();
        process::exit(0);
    }

    if cmd_idx >= args.len() {
        print_usage();
        process::exit(0);
    }

    let kb = KbManager::new(&kb_dir_str);
    let cmd = &args[cmd_idx];

    match cmd.as_str() {
        "init" => {
            if let Err(e) = kb.init_v2() { eprintln!("init failed: {}", e); process::exit(1); }
            kb.ensure_project().ok();
            kb.append_log("init", "KB structure initialized (v2: _compiled/ + .project.json)").ok();
            println!("KB structure ready (v2: _compiled/ + .project.json)");
        }

        "add" => {
            if cmd_idx+3 >= args.len() { eprintln!("add <name> <type> <tags>"); process::exit(1); }
            let entry_name = &args[cmd_idx+1];
            let entry_type = &args[cmd_idx+2];
            let tags = &args[cmd_idx+3];
            let now = chrono::Utc::now().to_rfc3339();

            let mut file_rel: Option<String> = None;
            if !entry_type.trim().is_empty() {
                let dir = kb.kb_dir.join(entry_type);
                fs::create_dir_all(&dir).ok();
                let safe = sanitize_filename(entry_name);
                let md_path = dir.join(format!("{}.md", safe));
                let rel = format!("{}/{}.md", entry_type, safe);
                if !md_path.exists() {
                    let content = format!(
                        "---\nname: {}\nentry_type: {}\ncreated: {}\nupdated: {}\ntags: [{}]\nstatus: stable\n---\n\n# {}\n\n",
                        entry_name, entry_type, now, now, tags, entry_name
                    );
                    fs::write(&md_path, content).ok();
                }
                file_rel = Some(rel);
            }

            let entry = KbEntry {
                entry_type: entry_type.clone(),
                name: entry_name.clone(),
                file: file_rel,
                tags: tags.clone(),
                created: now.clone(),
                updated: Some(now),
                status: Some("stable".to_string()),
                sources: vec![],
                backlinks: vec![],
                extra: HashMap::new(),
            };

            if let Err(e) = kb.add_entry(&entry) { eprintln!("add failed: {}", e); process::exit(1); }
            kb.append_log("add", &format!("Add entry: {} [{}]", entry_name, entry_type)).ok();
            // Auto-rebuild: keep _index.md and .index.jsonl always in sync
            if let Err(e) = kb.rebuild_index_v2() { eprintln!("rebuild after add failed: {}", e); }
            println!("Added [{}] {}", entry.entry_type, entry.name);
        }

        "list" => {
            let mut types = HashMap::new();
            for e in kb.load_index() { *types.entry(e.entry_type).or_insert(0) += 1; }
            let total: usize = types.values().sum();
            println!("Total: {} entries", total);
            for (t, c) in types { println!("  {}: {}", t, c); }
        }

        "query" => {
            if cmd_idx+1 >= args.len() { eprintln!("query <type>"); process::exit(1); }
            let t = &args[cmd_idx+1];
            let results: Vec<_> = kb.load_index().into_iter().filter(|e| e.entry_type == *t).collect();
            println!("{} entries:", results.len());
            for e in results { println!("  {} | {}", e.name, e.tags); }
        }

        "search" => {
            if cmd_idx+1 >= args.len() { eprintln!("search <keyword>"); process::exit(1); }
            let k = args[cmd_idx+1].to_lowercase();
            let results: Vec<_> = kb.load_index().into_iter()
                .filter(|e| e.name.to_lowercase().contains(&k) || e.tags.to_lowercase().contains(&k))
                .collect();
            println!("{} results for '{}':", results.len(), args[cmd_idx+1]);
            for e in results { println!("  [{}] {} | {}", e.entry_type, e.name, e.tags); }
        }

        "rebuild" => {
            match kb.rebuild_index_v2() {
                Ok(c) => {
                    println!("Rebuilt: {} entries", c);
                    kb.append_log("rebuild", &format!("Rebuild: {} entries", c)).ok();
                }
                Err(e) => { eprintln!("rebuild failed: {}", e); process::exit(1); }
            }
        }

        "workflow" => {
            if let Ok(content) = kb.show_workflow() {
                print!("{}", content);
            } else {
                eprintln!("workflow failed");
                process::exit(1);
            }
        }

        "chars" => {
            let chars = kb.list_chars();
            if chars.is_empty() {
                println!("0 characters found");
            } else {
                println!("{} characters:", chars.len());
                for (name, status, file) in chars {
                    println!("  [{}] {} -> {}", status, name, file);
                }
            }
        }

        "backlinks" => {
            if cmd_idx+1 >= args.len() { eprintln!("backlinks <target>"); process::exit(1); }
            let target = &args[cmd_idx+1];
            let links = kb.find_backlinks(target);
            if links.is_empty() {
                println!("0 backlinks for '{}'", target);
            } else {
                println!("{} backlinks to '{}':", links.len(), target);
                for l in links { println!("  <- {}", l); }
            }
        }

        "project-info" => {
            match kb.show_project_info() {
                Some(p) => {
                    println!("Project: {}", p.name);
                    println!("Version: {}", p.version);
                    println!("Created: {}", p.created);
                    println!("Description: {}", p.description);
                }
                None => {
                    println!("No .project.json found. Run init first.");
                    process::exit(1);
                }
            }
        }

        "sync-biji" => {
            match kb.sync_biji() {
                Ok(msg) => println!("{}", msg),
                Err(e) => { eprintln!("{}", e); process::exit(1); }
            }
        }

        "lint" => {
            println!("Running knowledge base health check...");
            let entries = kb.load_index();
            let bl = kb.load_backlinks();
            let orphans = entries.iter().filter(|e| e.backlinks.is_empty() && !e.name.is_empty()).count();
            let bad_entries = entries.iter().filter(|e| e.name.is_empty()).count();
            println!("  Orphan pages (no inbound links): {}", orphans);
            if bad_entries > 0 {
                println!("  BAD entries (empty name, no frontmatter/title): {} - rebuild will fix", bad_entries);
            }
            println!("  Total entries: {}", entries.len());
            println!("  Backlink targets: {}", bl.len());
            kb.append_log("lint", &format!("Lint: orphans={}, bad={}, total={}, backlink_targets={}", orphans, bad_entries, entries.len(), bl.len())).ok();
            println!("Lint done");
        }

        "ingest" => {
            if cmd_idx+1 >= args.len() { eprintln!("ingest <source_file>"); process::exit(1); }
            let source = &args[cmd_idx+1];
            let source_path = PathBuf::from(source);
            if !source_path.exists() {
                eprintln!("File not found: {}", source);
                process::exit(1);
            }
            let ext = source_path.extension().and_then(|e| e.to_str()).unwrap_or("");
            if ext != "md" {
                eprintln!("Only .md files supported for ingest. Got: {}", ext);
                eprintln!("(Future versions may support: .txt, .pdf, .epub, .docx)");
                process::exit(1);
            }
            let content = fs::read_to_string(&source_path).unwrap_or_default();
            let name = extract_title(&content);
            let etype = infer_type(&source_path);
            println!("Ingesting: {} ({})", name, etype);
            println!("Note: Full ingest (LLM analysis -> Wiki update) requires external LLM call.");
            println!("kb-rust only updates the index and log.");
            kb.append_log("ingest", &format!("Ingest: {} ({})", name, etype)).ok();
            // Auto-rebuild: keep _index.md and .index.jsonl always in sync
            if let Err(e) = kb.rebuild_index_v2() { eprintln!("rebuild after ingest failed: {}", e); }
        }

        "-h" | "--help" => { print_usage(); }

        _ => {
            eprintln!("Unknown command: {}", cmd);
            print_usage();
            process::exit(1);
        }
    }
}
