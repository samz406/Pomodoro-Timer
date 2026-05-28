import Database from 'better-sqlite3';
import path from 'path';
import { app } from 'electron';
import fs from 'fs';

export interface AppSettings {
  interfaceName: string;
  isAlwaysOnTop: boolean;
  digitColorHex: string;
  autoBreak: boolean;
  breakMinutes: number;
  showSystemNotification: boolean;
  autoSkipBreak: boolean;
  timerMode: number; // 0=classic, 1=forward, 2=infinite
  currentTheme: string;
  followSystemAppearance: boolean;
  launchAtLogin: boolean;
  hotkeyAccelerator: string;
}

export interface FocusRecord {
  id: number;
  startTime: number; // Unix ms
  endTime: number | null;
  durationMinutes: number;
  status: string; // COMPLETED | INTERRUPTED
}

export interface StatsData {
  todayCount: number;
  totalMinutes: number;
  streakDays: number;
}

const DEFAULT_SETTINGS: AppSettings = {
  interfaceName: '番茄时钟',
  isAlwaysOnTop: false,
  digitColorHex: '#E25C43',
  autoBreak: true,
  breakMinutes: 5,
  showSystemNotification: true,
  autoSkipBreak: false,
  timerMode: 0,
  currentTheme: 'tomato',
  followSystemAppearance: true,
  launchAtLogin: false,
  hotkeyAccelerator: '',
};

export class DatabaseManager {
  private static instance: DatabaseManager;
  private db!: Database.Database;

  static getInstance(): DatabaseManager {
    if (!DatabaseManager.instance) {
      DatabaseManager.instance = new DatabaseManager();
    }
    return DatabaseManager.instance;
  }

  initialize(): void {
    const dbDir = path.join(app.getPath('userData'), 'data');
    fs.mkdirSync(dbDir, { recursive: true });
    const dbPath = path.join(dbDir, 'pomodoro.db');
    this.db = new Database(dbPath);
    this.db.pragma('journal_mode = WAL');
    this.db.pragma('synchronous = NORMAL');
    this.createTables();
    this.seedDefaults();
  }

  private createTables(): void {
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS app_settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS focus_records (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time       INTEGER NOT NULL,
        end_time         INTEGER,
        duration_minutes INTEGER NOT NULL DEFAULT 25,
        status           TEXT    NOT NULL DEFAULT 'COMPLETED'
      );

      CREATE INDEX IF NOT EXISTS idx_focus_records_start ON focus_records(start_time);
    `);
  }

  private seedDefaults(): void {
    const insert = this.db.prepare(
      'INSERT OR IGNORE INTO app_settings (key, value) VALUES (?, ?)'
    );
    const entries = Object.entries(DEFAULT_SETTINGS) as [string, unknown][];
    const seedAll = this.db.transaction(() => {
      for (const [k, v] of entries) {
        insert.run(k, String(v));
      }
    });
    seedAll();
  }

  // ──────────────────────────── Settings ─────────────────────────────

  loadAppSettings(): AppSettings {
    const rows = this.db
      .prepare('SELECT key, value FROM app_settings')
      .all() as { key: string; value: string }[];

    const map: Record<string, string> = {};
    for (const r of rows) map[r.key] = r.value;

    const get = (k: keyof AppSettings, fallback: unknown) => {
      if (!(k in map)) return fallback;
      const v = map[k];
      if (typeof fallback === 'boolean') return v === 'true';
      if (typeof fallback === 'number') return Number(v);
      return v;
    };

    return {
      interfaceName: get('interfaceName', DEFAULT_SETTINGS.interfaceName) as string,
      isAlwaysOnTop: get('isAlwaysOnTop', DEFAULT_SETTINGS.isAlwaysOnTop) as boolean,
      digitColorHex: get('digitColorHex', DEFAULT_SETTINGS.digitColorHex) as string,
      autoBreak: get('autoBreak', DEFAULT_SETTINGS.autoBreak) as boolean,
      breakMinutes: get('breakMinutes', DEFAULT_SETTINGS.breakMinutes) as number,
      showSystemNotification: get('showSystemNotification', DEFAULT_SETTINGS.showSystemNotification) as boolean,
      autoSkipBreak: get('autoSkipBreak', DEFAULT_SETTINGS.autoSkipBreak) as boolean,
      timerMode: get('timerMode', DEFAULT_SETTINGS.timerMode) as number,
      currentTheme: get('currentTheme', DEFAULT_SETTINGS.currentTheme) as string,
      followSystemAppearance: get('followSystemAppearance', DEFAULT_SETTINGS.followSystemAppearance) as boolean,
      launchAtLogin: get('launchAtLogin', DEFAULT_SETTINGS.launchAtLogin) as boolean,
      hotkeyAccelerator: get('hotkeyAccelerator', DEFAULT_SETTINGS.hotkeyAccelerator) as string,
    };
  }

  saveAppSettings(settings: Partial<AppSettings>): void {
    const upsert = this.db.prepare(
      'INSERT OR REPLACE INTO app_settings (key, value) VALUES (?, ?)'
    );
    const saveAll = this.db.transaction(() => {
      for (const [k, v] of Object.entries(settings)) {
        upsert.run(k, String(v));
      }
    });
    saveAll();
  }

  // ──────────────────────────── Focus Records ──────────────────────────

  insertFocusRecord(startTime: number, durationMinutes: number): number {
    const result = this.db
      .prepare(
        'INSERT INTO focus_records (start_time, duration_minutes, status) VALUES (?, ?, ?)'
      )
      .run(startTime, durationMinutes, 'COMPLETED');
    return result.lastInsertRowid as number;
  }

  updateFocusRecord(id: number, endTime: number, durationMinutes: number, status: string): void {
    this.db
      .prepare(
        'UPDATE focus_records SET end_time=?, duration_minutes=?, status=? WHERE id=?'
      )
      .run(endTime, durationMinutes, status, id);
  }

  getAllRecords(): FocusRecord[] {
    return this.db
      .prepare('SELECT id, start_time as startTime, end_time as endTime, duration_minutes as durationMinutes, status FROM focus_records ORDER BY start_time DESC')
      .all() as FocusRecord[];
  }

  deleteRecord(id: number): void {
    this.db.prepare('DELETE FROM focus_records WHERE id=?').run(id);
  }

  loadStats(): StatsData {
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);
    const todayStartMs = todayStart.getTime();

    const todayCount = (
      this.db
        .prepare(
          "SELECT COUNT(*) as c FROM focus_records WHERE start_time >= ? AND status='COMPLETED'"
        )
        .get(todayStartMs) as { c: number }
    ).c;

    const totalMinutes = (
      this.db
        .prepare(
          "SELECT COALESCE(SUM(duration_minutes), 0) as s FROM focus_records WHERE status='COMPLETED'"
        )
        .get() as { s: number }
    ).s;

    const streakDays = this.calculateStreakDays();

    return { todayCount, totalMinutes, streakDays };
  }

  private calculateStreakDays(): number {
    const rows = this.db
      .prepare(
        "SELECT DISTINCT date(start_time/1000,'unixepoch','localtime') as d FROM focus_records WHERE status='COMPLETED' ORDER BY d DESC"
      )
      .all() as { d: string }[];

    if (rows.length === 0) return 0;

    let streak = 0;
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    for (let i = 0; i < rows.length; i++) {
      const expected = new Date(today);
      expected.setDate(expected.getDate() - i);
      const expectedStr = expected.toISOString().split('T')[0];
      if (rows[i].d === expectedStr) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  getWeeklyData(): { date: string; minutes: number }[] {
    const result = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      d.setHours(0, 0, 0, 0);
      const next = new Date(d);
      next.setDate(next.getDate() + 1);

      const minutes = (
        this.db
          .prepare(
            "SELECT COALESCE(SUM(duration_minutes),0) as s FROM focus_records WHERE start_time>=? AND start_time<? AND status='COMPLETED'"
          )
          .get(d.getTime(), next.getTime()) as { s: number }
      ).s;

      result.push({ date: d.toISOString().split('T')[0], minutes });
    }
    return result;
  }

  getMonthlyData(): { date: string; minutes: number }[] {
    const result = [];
    for (let i = 29; i >= 0; i--) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      d.setHours(0, 0, 0, 0);
      const next = new Date(d);
      next.setDate(next.getDate() + 1);

      const minutes = (
        this.db
          .prepare(
            "SELECT COALESCE(SUM(duration_minutes),0) as s FROM focus_records WHERE start_time>=? AND start_time<? AND status='COMPLETED'"
          )
          .get(d.getTime(), next.getTime()) as { s: number }
      ).s;

      result.push({ date: d.toISOString().split('T')[0], minutes });
    }
    return result;
  }

  exportData(): object {
    return {
      exportedAt: new Date().toISOString(),
      settings: this.loadAppSettings(),
      records: this.getAllRecords(),
    };
  }

  resetAllData(): void {
    this.db.exec('DELETE FROM focus_records;');
    this.db.exec('DELETE FROM app_settings;');
    this.seedDefaults();
  }
}
