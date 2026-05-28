import { ipcMain, app, Notification } from 'electron';
import fs from 'fs';
import { DatabaseManager } from './database';
import {
  setAlwaysOnTop,
  registerGlobalShortcut,
  unregisterGlobalShortcut,
  showExportDialog,
} from './index';

export function registerIpcHandlers(): void {
  const db = DatabaseManager.getInstance();

  // ── Settings ──────────────────────────────────────────
  ipcMain.handle('settings:load', () => db.loadAppSettings());
  ipcMain.handle('settings:save', (_e, partial) => {
    db.saveAppSettings(partial);

    // Side effects
    if ('isAlwaysOnTop' in partial) {
      setAlwaysOnTop(partial.isAlwaysOnTop as boolean);
    }
    if ('hotkeyAccelerator' in partial) {
      const acc = partial.hotkeyAccelerator as string;
      if (acc) {
        registerGlobalShortcut(acc);
      } else {
        unregisterGlobalShortcut();
      }
    }
    if ('launchAtLogin' in partial) {
      app.setLoginItemSettings({ openAtLogin: partial.launchAtLogin as boolean });
    }
  });

  // ── Focus Records ────────────────────────────────────
  ipcMain.handle('records:insert', (_e, startTime: number, durationMinutes: number) =>
    db.insertFocusRecord(startTime, durationMinutes)
  );
  ipcMain.handle(
    'records:update',
    (_e, id: number, endTime: number, durationMinutes: number, status: string) =>
      db.updateFocusRecord(id, endTime, durationMinutes, status)
  );
  ipcMain.handle('records:getAll', () => db.getAllRecords());
  ipcMain.handle('records:delete', (_e, id: number) => db.deleteRecord(id));

  // ── Stats ────────────────────────────────────────────
  ipcMain.handle('stats:load', () => db.loadStats());
  ipcMain.handle('stats:weekly', () => db.getWeeklyData());
  ipcMain.handle('stats:monthly', () => db.getMonthlyData());

  // ── Notifications ────────────────────────────────────
  ipcMain.handle('notify:send', (_e, title: string, body: string) => {
    if (Notification.isSupported()) {
      new Notification({ title, body }).show();
    }
  });

  // ── Hotkey ───────────────────────────────────────────
  ipcMain.handle('hotkey:register', (_e, accelerator: string) =>
    registerGlobalShortcut(accelerator)
  );
  ipcMain.handle('hotkey:unregister', () => {
    unregisterGlobalShortcut();
  });

  // ── Data management ──────────────────────────────────
  ipcMain.handle('data:export', async () => {
    const filePath = await showExportDialog();
    if (!filePath) return false;
    const data = db.exportData();
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf-8');
    return true;
  });

  ipcMain.handle('data:reset', () => {
    db.resetAllData();
  });

  // ── App version ──────────────────────────────────────
  ipcMain.handle('app:version', () => app.getVersion());
}
