#!/usr/bin/env python3
"""
MiniMax Token Plan 用量监控工具

显示今日用量（匹配 MiniMax 后台）

更新周期:
  - 24小时: music-2.6, music-cover, lyrics_generation, image-01
  - 5小时:  其他 (MiniMax-M*, speech-hd, coding-plan-*)
"""

import os
import json
import sqlite3
import argparse
from pathlib import Path
from datetime import datetime, date
from urllib.request import Request, urlopen

DB_PATH = Path.home() / ".minimax" / "usage.db"
API_ENDPOINT = "https://api.minimaxi.com/v1/api/openplatform/coding_plan/remains"

# 今日开始的 UTC+8 时间戳 (毫秒)
def get_today_start_ms():
    """获取今日 00:00 UTC+8 的时间戳"""
    today = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
    # 转换为毫秒时间戳
    return int(today.timestamp() * 1000)


def get_api_key():
    api_key = os.environ.get("MINIMAX_API_KEY", "")
    if not api_key:
        openclaw = Path.home() / ".openclaw" / "agents" / "coding" / "agent" / "auth-profiles.json"
        if openclaw.exists():
            try:
                config = json.loads(openclaw.read_text())
                for profile in config.get("profiles", {}).values():
                    if profile.get("provider") == "minimax":
                        api_key = profile.get("key", "")
                        break
            except:
                pass
    return api_key


def get_cycle_type(model_name):
    """获取更新周期"""
    cycle_24h = ["music-2.6", "music-cover", "lyrics_generation", "image-01"]
    for m in cycle_24h:
        if m in model_name:
            return "24小时"
    return "5小时"


def fmt_time(ms):
    """格式化剩余时间"""
    seconds = ms / 1000
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) / 60)
    if hours > 24:
        days = hours // 24
        hours = hours % 24
        return f"{days}天{hours}小时"
    return f"{hours}小时{minutes}分钟"


def fetch_usage(api_key):
    if not api_key:
        print("❌ 未设置 MINIMAX_API_KEY")
        return None
    
    try:
        request = Request(API_ENDPOINT)
        request.add_header("Authorization", f"Bearer {api_key}")
        request.add_header("Content-Type", "application/json")
        
        with urlopen(request, timeout=30) as response:
            data = json.loads(response.read().decode("utf-8"))
            base_resp = data.get("base_resp", {})
            if base_resp.get("status_code") != 0:
                print(f"❌ API 错误")
                return None
            return data
    except Exception as e:
        print(f"❌ 错误: {e}")
        return None


def save_to_db(data):
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS usage_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT NOT NULL,
            model_name TEXT NOT NULL,
            cycle_type TEXT,
            interval_used INTEGER,
            interval_total INTEGER
        )
    """)
    
    now = datetime.now().isoformat()
    for model in data.get("model_remains", []):
        cursor.execute("""
            INSERT INTO usage_records 
            (timestamp, model_name, cycle_type, interval_used, interval_total)
            VALUES (?, ?, ?, ?, ?)
        """, (
            now,
            model.get("model_name", "unknown"),
            get_cycle_type(model.get("model_name", "")),
            model.get("current_interval_usage_count", 0),
            model.get("current_interval_total_count", 0)
        ))
    
    conn.commit()
    conn.close()


def show_current():
    """显示今日用量（匹配 MiniMax 后台）"""
    api_key = get_api_key()
    data = fetch_usage(api_key)
    
    if not data:
        return
    
    save_to_db(data)
    
    today = date.today().strftime("%Y/%m/%d")
    print(f"\n{'='*72}")
    print(f"  MiniMax Token Plan - 今日用量 ({today})")
    print(f"{'='*72}")
    
    models = data.get("model_remains", [])
    
    # 5小时周期
    cycle_5h = [m for m in models if get_cycle_type(m.get("model_name", "")) == "5小时"]
    # 24小时周期
    cycle_24h = [m for m in models if get_cycle_type(m.get("model_name", "")) == "24小时"]
    
    # 5小时周期
    print(f"\n  ┌─ 📅 5小时周期")
    for model in cycle_5h:
        _show_model(model, today)
    print(f"  └─────────────────────────────────────────────")
    
    # 24小时周期
    print(f"\n  ┌─ 📆 24小时周期")
    for model in cycle_24h:
        _show_model(model, today)
    print(f"  └─────────────────────────────────────────────")
    
    print(f"\n{'='*72}")


def _show_model(model, today):
    """显示单个模型"""
    name = model.get("model_name", "unknown")
    
    # 映射显示名称
    display_name = {
        "MiniMax-M*": "文本生成",
        "speech-hd": "Text to Speech HD",
        "coding-plan-vlm": "coding-plan-vlm",
        "coding-plan-search": "coding-plan-search",
    }.get(name, name)
    
    interval_used = model.get("current_interval_usage_count", 0)
    interval_total = model.get("current_interval_total_count", 0)
    interval_remaining = model.get("current_interval_remaining_count", 0)
    remains_time = model.get("remains_time", 0)
    
    cycle_pct = (interval_used / interval_total * 100) if interval_total > 0 else 0
    
    # 状态
    if interval_remaining == 0:
        status = "🔴"
    elif cycle_pct >= 70:
        status = "⚠️"
    else:
        status = "✅"
    
    # 重置时间
    reset_time = fmt_time(remains_time)
    
    print(f"  │")
    print(f"  │ {status} {display_name}")
    print(f"  │    {today} | 重置时间: {reset_time}后")
    print(f"  │    {interval_used}/{interval_total} | {cycle_pct:.1f}% 已使用")


def show_stats():
    if not DB_PATH.exists():
        print("❌ 请先运行: python3 minimax_usage.py")
        return
    
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    cursor.execute("""
        SELECT model_name, cycle_type, MAX(timestamp) as last_seen, SUM(interval_used) as total
        FROM usage_records
        GROUP BY model_name
        ORDER BY total DESC
    """)
    
    print(f"\n{'='*72}")
    print("  MiniMax 用量历史")
    print(f"{'='*72}")
    
    for row in cursor.fetchall():
        print(f"\n  📊 {row['model_name']} [{row['cycle_type']}]")
        print(f"     累计: {row['total']:,}")
        print(f"     最近: {row['last_seen'][:19]}")
    
    print(f"\n{'='*72}")
    conn.close()


def main():
    parser = argparse.ArgumentParser(description="MiniMax Token Plan 用量监控")
    parser.add_argument("command", nargs="?", default="current", choices=["current", "stats", "help"])
    
    args = parser.parse_args()
    
    if args.command == "current":
        show_current()
    elif args.command == "stats":
        show_stats()
    else:
        print("MiniMax Token Plan 用量监控")
        print("  python3 minimax_usage.py        # 今日用量")
        print("  python3 minimax_usage.py stats   # 历史统计")


if __name__ == "__main__":
    main()
