# 🍅 番茄时钟（Pomodoro Timer）

> 原生 macOS 桌面番茄工作法应用 · Swift + SwiftUI · 纯本地存储 · 零依赖

[![Platform](https://img.shields.io/badge/Platform-macOS%2012%2B-lightgray?logo=apple)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange?logo=swift)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-blue)](LICENSE)
[![Architecture](https://img.shields.io/badge/Architecture-MVVM-green)](PomodoroTimer/)

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
| 🔔 系统通知 | 专注/休息结束后触发 macOS 横幅通知 |
| 📊 Bento 看板 | 今日专注次数、总专注时间、连续坚持天数 |
| 📈 历史图表 | 周/月专注柱状图 + 打断时段热力图 |
| 🗂 历史记录 | 完整历史流水，右键可本地删除 |
| 🎨 四套主题 | 经典番茄红、极客复古绿、深空冷峻蓝、暗夜极简黑 |
| 🌙 深浅色自适应 | 随 macOS 系统外观自动切换 |
| ⌨️ 全局快捷键 | 自定义全局暂停/启动快捷键（如 ⌥⌘P） |
| 🚀 开机自启 | 登录 macOS 时自动启动（SMAppService） |
| 💾 数据导出 | 将历史数据导出为 JSON 文件至 Finder |
| 🗑 数据重置 | 一键清空所有本地数据并确认 |
| 🔒 隐私安全 | 100% 本地存储，无网络请求，无账户注册 |

---

## 系统要求

| 项目 | 最低要求 |
|------|---------|
| 操作系统 | macOS 12.0 Monterey 及以上 |
| 处理器 | Apple Silicon (M1/M2/M3) 或 Intel x86_64 |
| 内存 | 50 MB（运行时） |
| 磁盘 | 10 MB（含数据库） |
| Xcode | 15.0 及以上（仅开发时需要） |

---

## 安装方式

### 方式一：从源码编译（推荐）

#### 前置条件

1. 安装 **Xcode 15.0+**（从 [Mac App Store](https://apps.apple.com/app/xcode/id497799835) 或 [Apple Developer](https://developer.apple.com/xcode/) 下载）
2. 安装 Xcode Command Line Tools：
   ```bash
   xcode-select --install
   ```

#### 步骤

```bash
# 1. 克隆仓库
git clone https://github.com/samz406/Pomodoro-Timer.git
cd Pomodoro-Timer

# 2. 用 Xcode 打开项目
open PomodoroTimer.xcodeproj

# 3. 在 Xcode 中选择目标设备为 "My Mac"

# 4. 配置代码签名（首次）
#    Xcode → Targets → PomodoroTimer → Signing & Capabilities
#    → 选择您的 Apple ID 团队

# 5. 按下 ⌘+R 运行，或 ⌘+B 仅编译
```

或使用命令行编译：

```bash
# 编译（Debug）
xcodebuild -project PomodoroTimer.xcodeproj \
           -scheme PomodoroTimer \
           -configuration Debug \
           -destination 'platform=macOS' \
           build

# 编译并运行
xcodebuild -project PomodoroTimer.xcodeproj \
           -scheme PomodoroTimer \
           -destination 'platform=macOS' \
           build && \
open build/Debug/PomodoroTimer.app
```

> **Apple Silicon 用户**：项目已原生支持 arm64，无需 Rosetta。

### 方式二：直接下载（Release）

前往 [Releases 页面](https://github.com/samz406/Pomodoro-Timer/releases) 下载最新的 `PomodoroTimer.dmg`，挂载后将 `PomodoroTimer.app` 拖入 `/Applications` 即可。

> **首次启动提示**：由于 App 未经 App Store 分发，macOS 可能显示「无法打开来自未知开发者的应用」。解决方法：
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
技术栈：Swift 5.9 + SwiftUI + SQLite3（系统库）
架构：MVVM（Model-View-ViewModel）
平台：macOS 12.0+，支持 Apple Silicon & Intel
依赖：零第三方库（仅使用系统框架）
```

```
PomodoroTimer/
├── PomodoroTimerApp.swift       # App 入口、AppDelegate
├── ContentView.swift            # NavigationView 侧边栏导航
├── Views/
│   ├── TimerView.swift          # 计时主页（环形计时器、Bento 看板）
│   ├── CountdownSettingsView.swift  # 倒计时规则配置
│   ├── RecordsView.swift        # 历史记录与图表
│   ├── ThemeView.swift          # 主题选择
│   └── SettingsView.swift       # 系统设置
├── Models/
│   └── DatabaseManager.swift    # SQLite3 数据层（三张核心表）
├── ViewModels/
│   ├── TimerViewModel.swift     # 计时业务逻辑
│   └── RecordsViewModel.swift   # 记录数据管理
├── Extensions/
│   └── Color+Hex.swift          # 颜色十六进制互转
└── Helpers/
    ├── HotkeyManager.swift      # Carbon 全局快捷键注册
    └── LaunchAtLoginHelper.swift # SMAppService 开机自启
```

---

## 数据库设计

数据存储于 `~/Library/Application Support/PomodoroTimer/pomodoro.db`

### tb_focus_record（专注历史记录）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK AI | 唯一主键 |
| start_time | INTEGER | Unix 时间戳（启动时间） |
| end_time | INTEGER | Unix 时间戳（结束/打断时间） |
| duration_minutes | INTEGER | 实际有效专注分钟数 |
| status | TEXT | `COMPLETED` / `INTERRUPTED` |

### tb_countdown_preset（预设时长）

| 字段 | 类型 | 说明 |
|------|------|------|
| preset_id | INTEGER PK | 预设 ID |
| minutes_value | INTEGER | 时长（1–90 分钟） |
| is_default | INTEGER | 是否为默认预设 |
| last_used_at | INTEGER | 最后使用时间戳 |

### tb_app_settings（全局配置，单行）

| 字段 | 类型 | 说明 |
|------|------|------|
| interface_name | TEXT | 界面显示名称 |
| is_always_on_top | INTEGER | 窗口是否置顶 |
| digit_color_hex | TEXT | 计时器数字颜色（如 `#E25C43`） |
| is_desktop_mini_mode | INTEGER | 是否启用桌面迷你模式 |
| auto_break | INTEGER | 是否自动进入休息 |
| break_minutes | INTEGER | 休息时长（分钟） |
| play_white_noise | INTEGER | 是否播放白噪音 |
| show_system_notification | INTEGER | 是否显示系统通知 |
| auto_skip_break | INTEGER | 是否自动跳过休息 |
| timer_mode | INTEGER | 计时模式（0/1/2） |
| current_theme | TEXT | 当前主题 ID |
| follow_system_appearance | INTEGER | 是否跟随系统外观 |
| launch_at_login | INTEGER | 是否开机自启 |
| hotkey_modifiers | INTEGER | 快捷键修饰键掩码 |
| hotkey_key_code | INTEGER | 快捷键键码 |

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

- [x] `[开关]` 登录 macOS 时自动启动（SMAppService / SMLoginItemSetEnabled）
- [x] 全局快捷键自定义（点击后录制键位，支持 ⌘⌥⌃⇧ 组合）
- [x] 快捷键清除按钮
- [x] `[导出备份数据]`：导出 JSON 至 Finder（NSSavePanel）
- [x] `[重置全量数据]`：清空所有表，触发 macOS 警告弹窗确认

### 全局功能

- [x] 左侧导航栏 + 右侧主内容区双栏结构（NavigationView）
- [x] 所有设置变更即时写入本地 SQLite（WAL 模式，< 16ms）
- [x] 纯本地运行，无网络请求
- [x] 数据存储路径：`~/Library/Application Support/PomodoroTimer/pomodoro.db`
- [x] 支持 Apple Silicon（M1/M2/M3）原生运行
- [x] 支持 Intel x86_64

### 非功能性指标

| 指标 | 目标值 | 说明 |
|------|--------|------|
| CPU（静默/计时中） | < 1% | Timer 使用 1000ms 步进，WAL 模式写入 |
| 内存占用 | < 50 MB | 纯 Swift/SwiftUI，无第三方库 |
| 数据库写入延时 | < 16 ms | WAL + NORMAL synchronous 模式 |
| macOS 版本兼容 | 12 / 13 / 14+ | 条件编译处理 API 差异 |

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

