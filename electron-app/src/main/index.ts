import { app, BrowserWindow, Notification, dialog, globalShortcut, shell, ipcMain } from 'electron';
import path from 'path';
import { DatabaseManager } from './database';
import { registerIpcHandlers } from './ipc';

const isDev = process.env.NODE_ENV === 'development';

let mainWindow: BrowserWindow | null = null;
let currentShortcut: string | null = null;

function createWindow(): void {
  mainWindow = new BrowserWindow({
    width: 900,
    height: 600,
    minWidth: 820,
    minHeight: 560,
    titleBarStyle: 'hiddenInset',
    trafficLightPosition: { x: 16, y: 16 },
    movable: true,
    frame: process.platform !== 'darwin',
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
    },
    backgroundColor: '#1e1e1e',
  });

  if (isDev) {
    mainWindow.loadURL('http://localhost:5173');
    mainWindow.webContents.openDevTools();
  } else {
    mainWindow.loadFile(path.join(__dirname, '../renderer/index.html'));
  }

  mainWindow.on('closed', () => {
    mainWindow = null;
  });

  // Apply always-on-top from saved settings
  const settings = DatabaseManager.getInstance().loadAppSettings();
  if (settings.isAlwaysOnTop) {
    mainWindow.setAlwaysOnTop(true);
  }

  // Register saved global shortcut
  if (settings.hotkeyAccelerator) {
    registerGlobalShortcut(settings.hotkeyAccelerator);
  }
}

export function setAlwaysOnTop(enabled: boolean): void {
  mainWindow?.setAlwaysOnTop(enabled);
}

export function registerGlobalShortcut(accelerator: string): boolean {
  if (currentShortcut) {
    globalShortcut.unregister(currentShortcut);
    currentShortcut = null;
  }
  if (!accelerator) return false;
  try {
    const success = globalShortcut.register(accelerator, () => {
      mainWindow?.webContents.send('global-shortcut-triggered');
    });
    if (success) {
      currentShortcut = accelerator;
    }
    return success;
  } catch {
    return false;
  }
}

export function unregisterGlobalShortcut(): void {
  if (currentShortcut) {
    globalShortcut.unregister(currentShortcut);
    currentShortcut = null;
  }
}

export function sendNotification(title: string, body: string): void {
  if (Notification.isSupported()) {
    new Notification({ title, body }).show();
  }
}

export function showExportDialog(): Promise<string | undefined> {
  return dialog.showSaveDialog(mainWindow!, {
    title: '导出番茄时钟数据',
    defaultPath: 'pomodoro_backup.json',
    filters: [{ name: 'JSON', extensions: ['json'] }],
  }).then(result => result.canceled ? undefined : result.filePath);
}

app.whenReady().then(() => {
  DatabaseManager.getInstance().initialize();
  registerIpcHandlers();
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('will-quit', () => {
  globalShortcut.unregisterAll();
});

// Handle external links
ipcMain.on('open-external', (_event, url: string) => {
  shell.openExternal(url);
});
