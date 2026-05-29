# 🍅 番茄时钟（Pomodoro Timer）

> 跨平台桌面番茄工作法应用 · Electron + TypeScript + React · 纯本地存储

[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Windows%20%7C%20Linux-lightgray?logo=electron)](https://www.electronjs.org/)
[![Electron](https://img.shields.io/badge/Electron-31-47848F?logo=electron)](https://www.electronjs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.4-3178C6?logo=typescript)](https://www.typescriptlang.org/)
[![React](https://img.shields.io/badge/React-18-61DAFB?logo=react)](https://react.dev/)
[![License](https://img.shields.io/badge/License-MIT-blue)](LICENSE)

---

## 目录

- [产品截图](#产品截图)
- [功能特性](#功能特性)
- [系统要求](#系统要求)
- [安装方式](#安装方式)
- [使用说明](#使用说明)
- [技术架构](#技术架构)
- [数据库设计](#数据库设计)
- [PRD 功能检查清单](#prd-功能检查清单)
- [开发贡献](#开发贡献)

---

## 功能特性

| 功能 | 说明 |
|------|------|
| 🕐 环形倒计时 | 可拖拽圆环调整时长（1–90 分钟），大字体 mm:ss 显示 |
| ⚡ 快捷预设 | 一键切换 25 / 30 / 45 分钟标准番茄钟 |
| 🏷 三种计时模式 | 经典倒计时、正向流逝、无限循环 |
| 🔔 系统通知 | 专注/休息结束后触发系统横幅通知 |
| 📊 Bento 看板 | 今日专注次数、总专注时间、连续坚持天数 |
| 📈 历史图表 | 周/月专注柱状图 + 打断时段热力图 |
| 🗂 历史记录 | 完整历史流水，右键可本地删除 |
| 🎨 四套主题 | 经典番茄红、极客复古绿、深空冷峻蓝、暗夜极简黑 |
| 🌙 深浅色自适应 | 随系统外观自动切换 |
| ⌨️ 全局快捷键 | 自定义全局暂停/启动快捷键（如 Alt+Ctrl+P） |
| 🚀 开机自启 | 登录系统时自动启动 |
| 💾 数据导出 | 将历史数据导出为 JSON 文件 |
| 🗑 数据重置 | 一键清空所有本地数据并确认 |
| 🔒 隐私安全 | 100% 本地存储，无网络请求，无账户注册 |

---

## 系统要求

| 项目 | 最低要求 |
|------|---------|
| 操作系统 | macOS 12+、Windows 10+、主流 Linux 发行版 |
| Node.js | 18.0 及以上（仅开发时需要） |
| npm | 9.0 及以上（仅开发时需要） |
| 内存 | 100 MB（运行时） |
| 磁盘 | 200 MB（含 node_modules）|

---

## 安装方式

### 方式一：从源码编译（推荐）

#### 前置条件

1. 安装 **Node.js 18+**（从 [nodejs.org](https://nodejs.org/) 下载）
2. 确认 npm 已安装：
   ```bash
   node -v && npm -v
   ```

#### 步骤

```bash
# 1. 克隆仓库
git clone https://github.com/samz406/Pomodoro-Timer.git
cd Pomodoro-Timer/electron-app

# 2. 安装依赖
npm install

# 3. 开发模式启动（热更新）
npm run dev
# 新开终端运行
npm run electron

# 或直接打包运行
npm run build
npm run electron
```

#### 打包发布

```bash
cd electron-app

npm run dist:mac    # → release/*.dmg + *.zip（macOS）
npm run dist:win    # → release/*.exe（Windows，NSIS 安装包）
npm run dist:linux  # → release/*.AppImage + *.deb（Linux）
```

### 方式二：直接下载（Release）

前往 [Releases 页面](https://github.com/samz406/Pomodoro-Timer/releases) 下载对应平台的安装包：

- **macOS**：下载 `.dmg`，挂载后将 App 拖入 `/Applications`
- **Windows**：下载 `.exe` 安装包，按向导安装
- **Linux**：下载 `.AppImage`（赋予执行权限后直接运行）或 `.deb`（`sudo dpkg -i` 安装）

> **macOS 首次启动提示**：由于 App 未经 App Store 分发，macOS 可能提示「无法打开来自未知开发者的应用」。解决方法：
> ```bash
> # 方法一：右键点击 App → 打开 → 确认
> # 方法二：命令行移除隔离属性
> xattr -cr /Applications/PomodoroTimer.app
> ```

---

## 使用说明

### 快速开始

1. **选择预设时长**：点击顶部「25 / 30 / 45 分钟」快捷按钮
2. **调整时长**：未计时时，拖拽圆环上的控制点（顺时针增加，逆时针减少，范围 1–90 分钟）
3. **开始计时**：点击【开始】按钮，圆环进度条开始消退
4. **暂停/继续**：再次点击按钮或使用全局快捷键
5. **重置**：点击【重置】，当前计时归档为「打断」状态

### 页面说明

| 页面 | 功能 |
|------|------|
| **计时** | 主计时器页，含右侧设置面板、底部 Bento 统计看板 |
| **倒计时** | 配置计时模式、休息时长、结束行为 |
| **记录** | 查看历史记录、周/月图表、打断热力图 |
| **主题** | 切换配色主题，配置系统外观跟随 |
| **设置** | 开机自启、全局快捷键、数据导出/重置 |

---

## 技术架构

```
技术栈：Electron 31 + TypeScript 5.4 + React 18 + better-sqlite3
架构：Main Process / Renderer Process / Preload (contextBridge)
平台：macOS 12+、Windows 10+、Linux
```

```
electron-app/
├── src/
│   ├── main/
│   │   ├── index.ts          # BrowserWindow、globalShortcut、always-on-top、login item
│   │   ├── database.ts       # SQLite（better-sqlite3，WAL 模式）
│   │   ├── ipc.ts            # IPC handlers（设置、记录 CRUD、统计、通知、热键、导出）
│   │   └── preload.ts        # contextBridge 安全暴露 electronAPI
│   ├── renderer/
│   │   ├── App.tsx           # 根组件，侧边栏导航
│   │   ├── hooks/
│   │   │   └── useTimer.ts   # Ref-based 计时器 Hook（支持三种计时模式）
│   │   ├── components/
│   │   │   ├── Timer/        # 计时主页（SVG 环形、Bento 看板）
│   │   │   ├── Countdown/    # 倒计时规则配置
│   │   │   ├── Records/      # 历史记录与图表
│   │   │   ├── Theme/        # 主题选择
│   │   │   └── Settings/     # 系统设置
│   │   └── styles/           # CSS 样式（CSS 变量主题）
│   └── shared/
│       └── types.ts          # AppSettings、FocusRecord、StatsData、ElectronAPI 类型定义
├── package.json              # 依赖 & electron-builder 配置
├── tsconfig.json             # Renderer TypeScript 配置
├── tsconfig.main.json        # Main process TypeScript 配置
└── vite.config.ts            # Vite 构建配置
```

---

## 数据库设计

数据存储于各平台的 userData 目录下的 `pomodoro.db`（SQLite，WAL 模式）：
- **macOS**：`~/Library/Application Support/pomodoro-timer/pomodoro.db`
- **Windows**：`%APPDATA%\pomodoro-timer\pomodoro.db`
- **Linux**：`~/.config/pomodoro-timer/pomodoro.db`

### focus_records（专注历史记录）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK AI | 唯一主键 |
| start_time | INTEGER | Unix 时间戳（启动时间） |
| end_time | INTEGER | Unix 时间戳（结束/打断时间） |
| duration_minutes | INTEGER | 实际有效专注分钟数 |
| status | TEXT | `COMPLETED` / `INTERRUPTED` |

### app_settings（全局配置，键值对）

| 字段 | 类型 | 说明 |
|------|------|------|
| key | TEXT PK | 配置项名称 |
| value | TEXT | 配置项值 |

主要配置项：`interface_name`、`is_always_on_top`、`digit_color_hex`、`auto_break`、`break_minutes`、`show_system_notification`、`auto_skip_break`、`timer_mode`、`current_theme`、`follow_system_appearance`、`launch_at_login`、`hotkey_accelerator`

---

## PRD 功能检查清单

以下清单基于 v1.0.0 PRD 文档，用于验收测试：

### 页面一：【计时】页面

- [x] 顶部三个快捷预设按钮（25 / 30 / 45 分钟），点击后圆环和数字同步重置
- [x] 中央大字体 `mm:ss` 格式倒计时显示
- [x] 下挂当前状态标签（专注时间 / 暂停 / 准备开始 / 休息时间）
- [x] 圆环拖拽操纵点（Thumb slider），未计时时可拖拽调整（1–90 分钟）
- [x] 拖拽时数字实时更新
- [x] 【开始】按钮：点击后变为「暂停」，圆环进度顺时针消退，写入本地记录
- [x] 【重置】按钮：恢复初始状态，中途重置归档为 `INTERRUPTED`
- [x] 右侧设置面板：应用名称、数字颜色选择器、窗口置顶、迷你模式开关
- [x] 右侧修改数字颜色，左侧计时数字立即重绘（双向实时同步）
- [x] 底部 Bento 看板：今日专注次数 / 总专注时间 / 连续坚持天数

### 页面二：【倒计时】页面

- [x] 计时模式选择：经典番茄（倒计时）/ 正向流逝计时 / 无限循环模式
- [x] 「倒计时完毕后自动进入 N 分钟休息」配置
- [x] 休息时长 Stepper（1–30 分钟）
- [x] `[√] 触发 macOS 系统横幅通知` 开关
- [x] `[√] 自动跳过休息` 开关
- [x] 所有配置实时写入本地 `tb_app_settings`

### 页面三：【记录】页面

- [x] 周专注柱状图（最近 7 天）
- [x] 月度专注柱状图（最近 30 天，切换显示）
- [x] 打断时段热力图（24 小时分布）
- [x] 历史流水网格表：开始时间、预计时长、实际时长、状态
- [x] 按时间倒序排列
- [x] 右键上下文菜单「删除此条本地记录」
- [x] 删除后统计指标动态刷新

### 页面四：【主题】页面

- [x] 经典番茄红主题
- [x] 极客复古绿主题
- [x] 深空冷峻蓝主题
- [x] 暗夜极简黑主题
- [x] 网格卡片布局，每张卡片展示配色预览
- [x] 选中主题后数字颜色立即更新
- [x] `[√] 紧随 macOS 系统外观切换` 开关（深色模式自适应）

### 页面五：【设置】页面

- [x] `[开关]` 登录系统时自动启动
- [x] 全局快捷键自定义（点击后录制键位，支持 Ctrl/Alt/Shift/Meta 组合）
- [x] 快捷键清除按钮
- [x] `[导出备份数据]`：通过系统 Save Dialog 导出 JSON 文件
- [x] `[重置全量数据]`：清空所有表，触发确认弹窗

### 全局功能

- [x] 左侧侧边栏导航 + 右侧主内容区双栏结构
- [x] 所有设置变更即时写入本地 SQLite（WAL 模式，< 16ms）
- [x] 纯本地运行，无网络请求
- [x] 数据存储路径：各平台 userData 目录下的 `pomodoro.db`
- [x] 跨平台支持：macOS、Windows、Linux

### 非功能性指标

| 指标 | 目标值 | 说明 |
|------|--------|------|
| CPU（静默/计时中） | < 5% | setInterval 1000ms 步进，WAL 模式写入 |
| 内存占用 | < 150 MB | Electron + React |
| 数据库写入延时 | < 16 ms | better-sqlite3 WAL 模式 |
| 平台兼容 | macOS 12+ / Win 10+ / Linux | electron-builder 多平台打包 |

---

## 开发贡献

```bash
# Fork & Clone
git clone https://github.com/your-username/Pomodoro-Timer.git

# 创建功能分支
git checkout -b feature/your-feature

# 提交并推送
git commit -m "feat: add your feature"
git push origin feature/your-feature

# 发起 Pull Request
```

---

## 许可证

[MIT License](LICENSE) © 2026 samz406

