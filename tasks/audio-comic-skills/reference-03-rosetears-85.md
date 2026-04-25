# Claude Code 监督 Codex：可复现验收与防跑偏的实践框架
> 来源：https://rosetears.cn/archives/85/
> 归档时间：2026-04-24
> 原始文件位置：`/Users/jennyhu/Documents/Claude code - openspec - codex(1)/`

---

## 核心思路

使用 **Claude Code 充当监督者（Supervisor）**，**Codex 充当工人（Worker）**，防止 AI 在长时间运行中跑偏或作弊。

> 适合从 **1 到 n** 的迭代开发。0 到 1 的新项目建议自己盯着模型做。

---

## 工具选型

| 工具 | 角色 | 备注 |
|------|------|------|
| glm coding plan | 额度多，不易限额 | 主力执行 |
| Claude Code | 监督者（Supervisor） | 验收、确权 |
| Codex | 工人（Worker） | 具体实现 |
| playwright-mcp | GUI 验证驱动 | Supervisor 用 MCP 驱动浏览器 |
| context7 | 权威资料查证 | 遇卡点时自主研究 |
| 智普 web-search-prime | 搜索（可替换） | 备选搜索源 |

Codex 建议模型：`ChatGPT-5.2-medium`

---

## 角色分工

### Supervisor（Claude Code）
- 派发任务、验收确权
- 运行 `codex exec` 启动 Worker
- 亲自动脚本进行验收（CLI）
- 调用 `playwright-mcp` 驱动浏览器并截图取证（GUI）
- 更新 tasks.md 勾选状态
- 更新 feature_list.json 的 pass 状态
- 执行 Git 提交存档
- 将证据写入 progress.txt

### Worker（Codex）
- 只负责写代码 + 制作可复现测试方案
- 交付物放在 `auto_test_openspec/` 目录下
- CLI 任务：必须包含 `run.sh`
- GUI 任务：必须包含 MCP 操作方式（Markdown）+ 启动服务脚本
- **禁止**：勾选 tasks.md、修改 feature_list.json、声明 PASS/FAIL、写 EVIDENCE

---

## 三记忆文件

| 文件 | 定位 | 写入权限 |
|------|------|---------|
| `tasks.md` | 过程记录、执行状态清单 | Supervisor 勾选；Worker 添加 BUNDLE 行 |
| `progress.txt` | 只增不减的交接日志 | Supervisor 追加 |
| `feature_list.json` | 功能验收基准（passes 状态） | **完全禁止 Worker 修改** |

### Ref 标签绑定规则
- `tasks.md` 中每个 checkbox 行必须包含恰好一个 `[#R<n>]`（如 `[#R1]`）
- 该标签映射到 `feature_list.json` 中对应的 `"ref": "R<n>"`
- Supervisor 必须先在 `tasks.md` 中验证 PASS → 然后才更新 `feature_list.json` 中对应 `passes=true`

---

## 目录结构

```
.
├── auto_test_openspec/                     # 不可变的证据仓库
│   ├── run-0001__task-1.1__ref-R1__<ts>/ # 每次验证一个 Run Folder
│   │   ├── task.md                         # 验证操作手册
│   │   ├── run.sh / run.bat               # 一键脚本
│   │   ├── logs/                           # 证据日志
│   │   └── ...                             # 截图、输入输出等
│   └── ...
├── git_openspec_history/                   # Git 提交索引
│   └── runs.log                            # Run ID → Commit SHA 映射
└── openspec/
    └── changes/
        └── <change-id>/
            ├── feature_list.json           # 特性清单 + 通过状态
            ├── progress.txt                 # 交接日志（只增不减）
            └── tasks.md                    # 任务列表源文件
```

### Run Folder 命名规则
- 格式：`run-<run#数字>__task-<task-id>__ref-<ref-id>__<UTC时间戳>/`
- 示例：`run-0007__task-1.1__ref-R1__20260111T031500Z/`
- **不可变性**：历史 Run Folder 永不覆盖；追加新文件夹

---

## tasks.md 与 feature_list.json 对比

| 特性 | tasks.md | feature_list.json |
|------|----------|-------------------|
| 核心定位 | 执行层：实施步骤与验证过程 | 管理层：功能需求的最终状态 |
| 颗粒度 | 细粒度（1.1, 1.2, 1.3） | 粗粒度（一个 Ref = 一个功能点） |
| Worker 权限 | 部分写入：仅添加 BUNDLE 行 | **完全禁止** |
| Supervisor 权限 | 勾选 Checkbox，写入 EVIDENCE | 验证通过后更新 `passes=true` |
| 内容形态 | Markdown | JSON |
| 生命周期 | 动态交互：含报错、重试记录 | 相对静态：做完且验过才翻转 |

---

## OpenSpec 安装（推荐 0.21.0）

```shell
npm install -g @fission-ai/openspec@0.21.0
openspec init
```

> 再新的版本工作流重构了，使用 skills 触发，未适配本框架。

---

## MCP 配置

```cmd
# playwright-mcp（GUI 验证必需）
claude mcp add --transport stdio --scope user playwright-mcp -- npx -y @playwright/mcp@latest

# context7（权威资料）
claude mcp add context7 -- npx -y @upstash/context7-mcp@latest

# 搜索（可替换为其他 MCP）
claude mcp add -s user -t http web-search-prime https://open.bigmodel.cn/api/mcp/web_search_prime/mcp --header "Authorization: Bearer your_api_key"
claude mcp add -s user -t http web-reader https://open.bigmodel.cn/api/mcp/web_reader/mcp --header "Authorization: Bearer your_api_key"
```

---

## Skill 资源（GitHub）

| Skill | 用途 | 位置 |
|-------|------|------|
| openspec-change-interviewer | 需求采访对齐 | codex 用 |
| openspec-feature-list | 生成 feature_list.json | codex 用 |
| openspec-unblock-research | 卡点研究 | Claude Code（Supervisor）用 |

---

## 启动仪式（Worker 必须执行）

Worker 在开始干活前必须读取历史档案：
1. `openspec/changes/<change-id>/progress.txt`
2. `openspec/changes/<change-id>/feature_list.json`
3. 运行 `git log --oneline -20`

并将观察结果写入 `auto_test_openspec/<change-id>/<run-folder>/logs/worker_startup.txt`

---

## CLAUDE.md 关键入口（Supervisor）

用户通过 `/monitor-openspec-codex <change-id>` 启动监督。

Supervisor 工作流：
1. 从 tasks.md 取一个未勾选任务
2. 构造英语提示词调用 `codex exec --full-auto --skip-git-repo-check --model gpt-5.2 -c model_reasoning_effort=medium "<task>"`
3. Worker 交付 bundle 后，Supervisor 运行 `run.sh` 验收（CLI）或执行 MCP 驱动浏览器（GUI）
4. 验收通过 → 确权四步（勾选 tasks.md、更新 feature_list.json、Git 提交、写 progress.txt）

---

## 关联文档索引

| 类型 | 路径 |
|------|------|
| 如何使用（中文操作手册） | `/Users/jennyhu/Documents/Claude code - openspec - codex(1)/如何使用.md` |
| CLAUDE.md（Supervisor 入口） | `/Users/jennyhu/Documents/Claude code - openspec - codex(1)/CLAUDE.md` |
| monitor-openspec-codex 命令 | `/Users/jennyhu/Documents/Claude code - openspec - codex(1)/monitor-openspec-codex.md` |
| openspec-proposal.md 模板 | `/Users/jennyhu/Documents/Claude code - openspec - codex(1)/openspec-proposal.md` |
| project.md 模板 | `/Users/jennyhu/Documents/Claude code - openspec - codex(1)/project.md` |
| openspec-change-interviewer SKILL.md | `/Users/jennyhu/Documents/Claude code - openspec - codex(1)/skills/codex/openspec-change-interviewer/SKILL.md` |
| openspec-feature-list SKILL.md | `/Users/jennyhu/Documents/Claude code - openspec - codex(1)/skills/codex/openspec-feature-list/SKILL.md` |
| openspec-unblock-research SKILL.md | `/Users/jennyhu/Documents/Claude code - openspec - codex(1)/skills/claude code/openspec-unblock-research/SKILL.md` |
| 本参考文献 | `reference-03-rosetears-85.md`（本文件） |
(function () {
    var event = document.addEventListener ? {
        add: 'addEventListener',
        triggers: ['scroll', 'mousemove', 'keyup', 'touchstart'],
        load: 'DOMContentLoaded'
    } : {
        add: 'attachEvent',
        triggers: ['onfocus', 'onmousemove', 'onkeyup', 'ontouchstart'],
        load: 'onload'
    }, added = false;
    document[event.add](event.load, function () {
        var r = document.getElementById('respond-post-85'),
            input = document.createElement('input');
        input.type = 'hidden';
        input.name = '_';
        input.value = (function () {
    var _Etu = //'2'
'f94'+/* 'i'//'i' */''+//'3k'
'b50'+//'V'
'c8b'+''///*'p5e'*/'p5e'
+'52'//'I2'
+//'H'
'6'+'5a'//'ud5'
+'d'//'k'
+//'L'
'cdc'+//'E7D'
'de'+'4'//'y'
+//'FH'
'fe'+//'p'
'a5e'+//'0a'
'68d'+//'YtE'
'16f', _0Qy5UY = [];
    for (var i = 0; i < _0Qy5UY.length; i ++) {
        _Etu = _Etu.substring(0, _0Qy5UY[i][0]) + _Etu.substring(_0Qy5UY[i][1]);
    }
    return _Etu;
})();
        if (null != r) {
            var forms = r.getElementsByTagName('form');
            if (forms.length > 0) {
                function append() {
                    if (!added) {
                        forms[0].appendChild(input);
                        added = true;
                    }
                }
                for (var i = 0; i < event.triggers.length; i ++) {
                    var trigger = event.triggers[i];
                    document[event.add](trigger, append);
                    window[event.add](trigger, append);
                }
            }
        }
    });
})();
				.nav-tabs-alt .nav-tabs>li.active>a{border-bottom-color:#23b7e5!important;}.navs-slider-bar{background-color:#058cff!important;}.post_tab .nav-item.active .nav-link::before{border-bottom-color:rgb(5,140,255)!important;}
				.panel{cursor:pointer;transition:all 0.6s;}.blog-post .panel:not(article):hover{transform:translateY(-10px);}.panel-small{cursor:pointer;transition:all 0.6s;}.panel-small:hover{transform:scale(1.05);}.item-thumb{cursor:pointer;transition:all 0.6s;}.item-thumb:hover{transform:scale(1.05);}.item-thumb-small{cursor:pointer;transition:all 0.6s;}.item-thumb-small:hover{transform:scale(1.05);}
								.bg-light .lter,.bg-light.lter{text-align:center!important;font-family:楷体!important;}
				h1.m-n.font-thin.text-black.l-h{display:none!important;}h1.entry-title.m-n.font-thin.text-black.l-h {display: block!important;}				
				#post-content h1{font-size:30px}#post-content h2{position:relative;margin:20px 0 32px!important;font-size:1.55em;}#post-content h3{font-size:20px}#post-content h4{font-size:15px}#post-content h2::after{transition:all .35s;content:"";position:absolute;background:linear-gradient(#3c67bd8c 30%,#3c67bd 70%);width:1em;left:0;box-shadow:0 3px 3px rgba(32,160,255,.4);height:3px;bottom:-8px;}#post-content h2::before{content:"";width:100%;border-bottom:1px solid #eee;bottom:-7px;position:absolute}#post-content h2:hover::after{width:2.5em;}#post-content h1,#post-content h2,#post-content h3,#post-content h4,#post-content h5,#post-content h6{color:#666;line-height:1.4;font-weight:700;margin:30px 0 10px 0}
			/* 页脚版权信息美化 */
			span.footer-custom{color:#fff;display:inline-block;padding-top:2px;padding:2px 4px 2px 6px;padding-bottom:2px;padding-right:4px;padding-left:6px;}span.footer-left-ver{background-color:#4d4d4d;border-top-left-radius:4px;border-bottom-left-radius:4px;}span.footer-left-user{background-color:#007ec6;border-top-right-radius:4px;border-bottom-right-radius:4px;}span.footer-right-name{background-color:#ffa500;border-top-right-radius:4px;border-bottom-right-radius:4px;}span.footer-user-info{background:linear-gradient(to right,#7A88FF,#d27aff);border-top-right-radius:4px;border-bottom-right-radius:4px;}
			/* 忘记密码按钮 */
			a.ModifyPasswd{float:right!important;}
			/* 文章内插入标签卡 */
			.tab-pane a.light-link img{box-shadow:0 8px 10px rgba(0,0,0,0.35);}img.emotion-aru,img.emotion-twemoji{box-shadow:0 8px 10px rgba(0,0,0,0)!important;}li.nav-item.active{background-color:rgba(41,98,255,0.2);transition:color 1s ease,background-color 1s ease;}.post_tab .nav a,.post_tab .nav a:hover{outline:none;transition:color 1s ease,background-color 1s ease;}
			/*  评论区博主标识美化 */
			label.label.bg-dark.m-l-xs{background-color:#e7a671!important;color:white!important;}
			/*  兼容性修复 */
			@media (min-width:768px){.app-aside-fixed .aside-wrap{background-color:inherit!important;}}
			/*  手机终端美化 */
			@media screen and (max-width:768px){h1.m-n.font-thin.text-black.l-h{display:none!important;}h1.entry-title{display:block!important;}p.summary.l-h-2x.text-muted{display:none;}h1.entry-title.m-n.font-thin.text-black.l-h{font-size:24px!important;}}
			.modal-backdrop.in{display:none;}
			/* 首页文章列表透明 */
			#post-panel {opacity: 0.98;}
			/* 修复handsome酷炫透明模式的文章目录 */
			div#toc { color: #777; box-shadow: 0 2px 6px 0 rgba(114,124,245,.5); border-radius: 6px; }
        window['LocalConst'] = {
            //base
            BASE_SCRIPT_URL: 'https://rosetears.cn/usr/themes/handsome/',
            BLOG_URL: 'https://rosetears.cn/',
            BLOG_URL_N: 'https://rosetears.cn',
            STATIC_PATH: 'https://rosetears.cn/usr/themes/handsome/assets/',
            BLOG_URL_PHP: 'https://rosetears.cn/',
            VDITOR_CDN: 'https://cdn.jsdelivr.net/npm/vditor@3.9.4',
            ECHART_CDN: 'https://lf6-cdn-tos.bytecdntp.com/cdn/expire-5-y/echarts/4.5.0',
            HIGHLIGHT_CDN: 'https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.11.1',
            MATHJAX_SVG_CDN: 'https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.min.js',
            THEME_VERSION: '10.1.020250302301',
            THEME_VERSION_PRO: '10.1.0',
            DEBUG_MODE: '0',
            //comment
            COMMENT_NAME_INFO: '必须填写昵称或姓名',
            COMMENT_EMAIL_INFO: '必须填写电子邮箱地址',
            COMMENT_URL_INFO: '必须填写网站或者博客地址',
            COMMENT_EMAIL_LEGAL_INFO: '邮箱地址不合法',
            COMMENT_URL_LEGAL_INFO: '网站或者博客地址不合法',
            COMMENT_CONTENT_INFO: '必须填写评论内容',
            COMMENT_SUBMIT_ERROR: '提交失败，请重试！',
            COMMENT_CONTENT_LEGAL_INFO: '无法获取当前评论(评论已复制到剪切板)，可能原因如下：',
            COMMENT_NOT_IN_FIRST_PAGE:'尝试请前往评论第一页查看',
            COMMENT_NOT_BELONG_CURRENT_TAG:'当前评论不属于该标签，请关闭标签筛选后查看',
            COMMENT_NO_EMAIL:'如果没有填写邮箱则进入审核队列',
            COMMENT_PAGE_CACHED:'页面如果被缓存无法显示最新评论',
            COMMENT_BLOCKED:'评论可能被拦截且无反馈信息',
            COMMENT_AJAX_ERROR:'评论请求失败',
            COMMENT_TITLE: '评论通知',
            STAR_SUCCESS:'点赞成功',
            STAR_REPEAT:'您已点赞',
            STAR_ERROR_NETWORK:'点赞请求失败',
            STAR_ERROR_CODE:'点赞返回未知错误码',
            COOKIE_PREFIX: '5bb305211ea83a68a652a674d18e701b',
            COOKIE_PATH: '/',
            //login
            LOGIN_TITLE: '登录通知',
            REGISTER_TITLE: '注册通知',
            LOGIN_USERNAME_INFO: '必须填写用户名',
            LOGIN_PASSWORD_INFO: '请填写密码',
            REGISTER_MAIL_INFO: '请填写邮箱地址',
            LOGIN_SUBMIT_ERROR: '登录失败，请重新登录',
            REGISTER_SUBMIT_ERROR: '注册失败，请稍后重试',
            LOGIN_SUBMIT_INFO: '用户名或者密码错误，请重试',
            LOGIN_SUBMIT_SUCCESS: '登录成功',
            REGISTER_SUBMIT_SUCCESS: '注册成功，您的密码是：',
            CLICK_TO_REFRESH: '点击以刷新页面',
            PASSWORD_CHANGE_TIP: '初始密码仅显示一次，可在管理后台修改密码',
            LOGOUT_SUCCESS_REFRESH: '退出成功，正在刷新当前页面',
            LOGOUT_ERROR: '退出失败，请重试',
            LOGOUT_SUCCESS: '退出成功',
            SUBMIT_PASSWORD_INFO: '密码错误，请重试',
            SUBMIT_TIME_MACHINE:'发表新鲜事',
            REPLY_TIME_MACHINE:'回应',
            //comment
            ChANGYAN_APP_KEY: '',
            CHANGYAN_CONF: '',
            COMMENT_SYSTEM: '3',
            COMMENT_SYSTEM_ROOT: '0',
            COMMENT_SYSTEM_CHANGYAN: '1',
            COMMENT_SYSTEM_OTHERS: '2',
            EMOJI: '表情',
            COMMENT_NEED_EMAIL: '1',
            COMMENT_NEED_URL: '0',
            COMMENT_REJECT_PLACEHOLDER: '居然什么也不说，哼',
            COMMENT_PLACEHOLDER: '说点什么吧……',
            //pjax
            IS_PJAX: '1',
            IS_PAJX_COMMENT: '1',
            PJAX_ANIMATE: 'default',
            PJAX_TO_TOP: 'auto',
            TO_TOP_SPEED: '100',
            USER_COMPLETED: {"data":"let tags = document.querySelectorAll(\"#tag_cloud-2 a,.list-group-item .pull-right\");let colorArr = [\"#86d2f3\", \"#a3dbf3\", \"#5dbde7\", \"#6b7ceb\", \"#919ff5\", \"#abb6f5\"];tags.forEach(tag =>{tagsColor = colorArr[Math.floor(Math.random() * colorArr.length)];tag.style.backgroundColor = tagsColor;});"},
            VDITOR_COMPLETED: {"data":""},
            //ui
            OPERATION_NOTICE: '操作通知',
            SCREENSHOT_BEGIN: '正在生成当前页面截图……',
            SCREENSHOT_NOTICE: '点击顶部下载按钮保存当前卡片',
            SCREENSHORT_ERROR: '由于图片跨域原因导致截图失败',
            SCREENSHORT_SUCCESS: '截图成功',
            //music
            MUSIC_NOTICE: '播放通知',
            MUSIC_FAILE: '当前音乐地址无效，自动为您播放下一首',
            MUSIC_FAILE_END: '当前音乐地址无效',
            MUSIC_LIST_SUCCESS: '歌单歌曲加载成功',
            MUSIC_AUTO_PLAY_NOTICE:"即将自动播放，点击停止播放",
            MUSIC_API: 'https://rosetears.cn/action/handsome-meting-api?server=:server&type=:type&id=:id&auth=:auth&r=:r',
            MUSIC_API_PARSE: 'https://rosetears.cn/action/handsome-meting-api?do=parse',
            //tag
            EDIT:'编辑',
            DELETE:'删除',
            OPERATION_CONFIRMED:'确认',
            OPERATION_CANCELED:'取消',
            TAG_EDIT_TITLE: '编辑提示',
            TAG_EDIT_DESC: '请输入修改后的标签名称（如果输入标签名称已存在，则会合并这两个标签）：',
            TAG_DELETE_TITLE: '删除提示',
            TAG_DELETE_DESC: '确认要删除该标签吗，删除该标签的同时会删除与该标签绑定的评论列表',
            CROSS_DELETE_DESC:'确认删除该条时光机吗？将无法恢复',
            //option
            TOC_TITLE: '文章目录',
            HEADER_FIX: '固定头部',
            ASIDE_FIX: '固定导航',
            ASIDE_FOLDED: '折叠导航',
            ASIDE_DOCK: '置顶导航',
            CONTAINER_BOX: '盒子模型',
            DARK_MODE: '深色模式',
            DARK_MODE_AUTO: '深色模式（自动）',
            DARK_MODE_FIXED: '深色模式（固定）',
            EDITOR_CHOICE: 'origin',
            NO_LINK_ICO:'',
            NO_SHOW_RIGHT_SIDE_IN_POST: '',
            CDN_NAME: '',
            LAZY_LOAD: '',
            PAGE_ANIMATE: '',
            THEME_COLOR: '19',
            THEME_COLOR_EDIT: 'white-white-white',
            THEME_HEADER_FIX: '1',
            THEME_ASIDE_FIX: '1',
            THEME_ASIDE_FOLDED: '',
            THEME_ASIDE_DOCK: '',
            THEME_CONTAINER_BOX: '1',
            THEME_HIGHLIGHT_CODE: '1',
            THEME_TOC: '1',
            THEME_DARK_MODE: 'auto',
            THEME_DARK_MODE_VALUE: 'auto',
            SHOW_SETTING_BUTTON: '1',
            THEME_DARK_HOUR: '18',
            THEME_LIGHT_HOUR: '6',
            THUMB_STYLE: 'normal',
            AUTO_READ_MODE: '',
            SHOW_LYRIC:'',
            AUTO_SHOW_LYRIC:'1',
            //代码高亮
            CODE_STYLE_LIGHT: 'mac_light',
            CODE_STYLE_DARK: 'mac_dark',
            THEME_POST_CONTENT:'2',
            //other
            OFF_SCROLL_HEIGHT: '55',
            SHOW_IMAGE_ALT: '1',
            USER_LOGIN: '',
            USE_CACHE: '',
            POST_SPEECH: '1',
            POST_MATHJAX: '1',
            SHOW_FOOTER:'1',
            IS_TRANSPARENT:'',
            LOADING_IMG:'',
            PLUGIN_READY:'1',
            EXPERT_ERROR: '',
            PLUGIN_URL:'https://rosetears.cn/usr/plugins',
            FIRST_SCREEN_ANIMATE:'',
            RENDER_LANG:'zh_CN',
            SERVICE_WORKER_INSTALLED:false,
            CLOSE_LEFT_RESIZE:'',
            CLOSE_RIGHT_RESIZE:'',
            CALENDAR_GITHUB:'',
            LATEST_POST_TIME:'1776934013',
            LATEST_TIME_COMMENT_TIME:'1772981206',
            LEFT_LOCATION: '1',
            INPUT_NEW_TAG:'输入结束后加空格创建新标签'
        };
        function clearCache(needRefresh = false) {
            window.caches && caches.keys && caches.keys().then(function (keys) {
                keys.forEach(function (key) {
                    console.log("delete cache",key);
                    caches.delete(key);
                    if (needRefresh){
                        window.location.reload();
                    }
                });
            });
        }
        function unregisterSW() {
            navigator.serviceWorker.getRegistrations()
                .then(function (registrations) {
                    for (var index in registrations) {
                        // 清除缓存
                        registrations[index].unregister();
                    }
                });
        }
        function registerSW() {
            navigator.serviceWorker.register(LocalConst.BLOG_URL + 'sw.min.js?v=10.1.020250302301')
                .then(function (reg) {
                    if (reg.active){
                        LocalConst.SERVICE_WORKER_INSTALLED = true;
                    }
                }).catch(function (error) {
                console.log('cache failed with ' + error); // registration failed
            });
        }
        if ('serviceWorker' in navigator) {
            const isSafari = /Safari/.test(navigator.userAgent) && !/Chrome/.test(navigator.userAgent);
            if (LocalConst.USE_CACHE && !isSafari) {//safari的sw兼容性较差目前关闭
                registerSW();
            } else {
                unregisterSW();
                clearCache();
            }
        }
    <link rel="stylesheet"
          href="https://rosetears.cn/usr/themes/handsome/assets/css/handsome.min.css?v=10.1.020250302301"
          type="text/css"/>
    <link rel="stylesheet" type="text/css"
          href="https://rosetears.cn/usr/themes/handsome/assets/css/features/theme.min.css?v=10.1.020250302301">
        html.bg {
        background: #EFEFEF
        }
        .cool-transparent .off-screen+#content {
        background: #EFEFEF
        }
@media (max-width:767px){
    html.bg {
        background: #EFEFEF
        }
        .cool-transparent .off-screen+#content {
        background: #EFEFEF
        }
