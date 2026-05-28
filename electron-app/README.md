# 番茄时钟 – Electron 版

> 原 Swift + SwiftUI 版本迁移至 **Electron + TypeScript + React**

## 技术栈

| 层级 | 技术 |
|------|------|
| 桌面框架 | Electron 31 |
| 语言 | TypeScript |
| UI 框架 | React 18 |
| 构建工具 | Vite (renderer) + tsc (main) |
| 本地存储 | SQLite via `better-sqlite3` |
| 设置持久化 | `electron-store` (via SQLite in app) |
| 系统通知 | Electron Notification API |
| 打包 | electron-builder |

## 功能

- 🍅 **经典番茄倒计时** – 可拖拽环形设置时长（1–90 分钟）
- ⏩ **正向流逝计时** – 记录已专注时长
- 🔁 **无限循环模式** – 自动切换专注 / 休息
- 📊 **记录页** – 周/月柱状图、打断时段热力图、历史表格
- 🎨 **主题页** – 4 套配色主题，支持跟随系统外观
- ⚙️ **设置页** – 登录启动、窗口置顶、全局快捷键、数据导出/重置
- 🔔 **系统通知** – 专注/休息完成时弹出原生通知

## 开发

```bash
cd electron-app

# 安装依赖
npm install

# 构建（主进程 + 渲染进程）
npm run build

# 打包 macOS 应用
npm run dist:mac

# 打包 Windows 应用
npm run dist:win

# 打包 Linux 应用
npm run dist:linux
```

## 项目结构

```
electron-app/
├── src/
│   ├── main/            # Electron 主进程
│   │   ├── index.ts     # 入口，窗口管理，全局快捷键
│   │   ├── database.ts  # SQLite 数据库操作
│   │   ├── ipc.ts       # IPC 处理器
│   │   └── preload.ts   # Context Bridge / 安全 API 暴露
│   ├── renderer/        # React 渲染进程
│   │   ├── App.tsx
│   │   ├── hooks/
│   │   │   └── useTimer.ts   # 计时器核心逻辑
│   │   ├── components/
│   │   │   ├── Sidebar.tsx
│   │   │   ├── Timer/        # 计时页
│   │   │   ├── Countdown/    # 倒计时设置页
│   │   │   ├── Records/      # 记录页
│   │   │   ├── Theme/        # 主题页
│   │   │   └── Settings/     # 设置页
│   │   └── styles/
│   └── shared/
│       └── types.ts     # 共享类型定义
├── tsconfig.json        # 渲染进程 TS 配置
├── tsconfig.main.json   # 主进程 TS 配置
├── vite.config.ts       # Vite 构建配置
└── package.json
```

## 数据存储

所有数据存储在本地 SQLite 数据库（无任何网络请求）：

- 路径：`<userData>/data/pomodoro.db`
- 表：`focus_records`（专注记录）、`app_settings`（键值配置）
