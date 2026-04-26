# Skill: encrypted-backup

**触发场景**：需要将敏感文件加密后备份到 Git，本地只保留明文

**触发词**："加密备份" / "加密推送" / "安全备份"

---

## 依赖

| 工具 | 类型 | 说明 |
|------|------|------|
| openssl | [本地请求] | 文件加密（AES-256-CBC） |
| git | [本地请求] | 版本控制与推送 |
| gzip | [本地请求] | 可选：批量压缩 |

---

## 密码管理

**密码存储于 `~/.backup-password`**（chmod 600，不推 GitHub，不备份）：
```bash
# 首次设置（只需一次）
echo "<password>" > ~/.backup-password && chmod 600 ~/.backup-password

# 脚本自动读取，无需每次输入
cat ~/.backup-password
```

---

## 输入

```yaml
git_message: <提交信息>
files:
  - /path/to/file1.md
  - /path/to/file2.md
```

---

## 输出

```yaml
status: success
encrypted_files:
  - file1.md.enc
  - file2.md.enc
git_commit: <commit hash>
git_push: success
local_cleanup: success
```

---

## 核心流程

1. **自动从本地密码文件读取**
   ```bash
   PASSWORD=$(cat ~/.backup-password)
   ```

2. **加密文件**
   ```bash
   echo "$PASSWORD" | openssl enc -aes-256-cbc -salt -pbkdf2 \
     -in <file> -out <file>.enc -pass stdin
   ```

3. **添加到 Git → 提交 → 推送 → 清理本地加密文件**
   ```bash
   git add <files>.enc
   git commit -m "<message>"
   git push origin main
   rm -f <files>.enc
   ```

---

## 验收标准

- [ ] 加密文件成功生成（.enc 后缀）
- [ ] GitHub 上只有加密文件
- [ ] 本地只有明文文件
- [ ] 推送成功
- [ ] 密码不存储在任何明文文件中

---

## 代码入口

`skills/encrypted-backup/encrypt-backup.sh`

---

## 使用示例

```bash
# 触发（无需提供密码）
"加密备份 tasks/audio-comic-skills/"
```
