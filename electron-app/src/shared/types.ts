export interface AppSettings {
  interfaceName: string;
  isAlwaysOnTop: boolean;
  digitColorHex: string;
  autoBreak: boolean;
  breakMinutes: number;
  showSystemNotification: boolean;
  autoSkipBreak: boolean;
  timerMode: number;
  currentTheme: string;
  followSystemAppearance: boolean;
  launchAtLogin: boolean;
  hotkeyAccelerator: string;
}

export interface FocusRecord {
  id: number;
  startTime: number;
  endTime: number | null;
  durationMinutes: number;
  status: string;
}

export interface StatsData {
  todayCount: number;
  totalMinutes: number;
  streakDays: number;
}

export type TimerPhase = 'focus' | 'break';
export type NavPage = 'timer' | 'countdown' | 'records' | 'theme' | 'settings';

export interface ChartPoint {
  date: string;
  minutes: number;
}

export type ElectronAPI = {
  settings: {
    load: () => Promise<AppSettings>;
    save: (partial: Partial<AppSettings>) => Promise<void>;
  };
  records: {
    insert: (startTime: number, durationMinutes: number) => Promise<number>;
    update: (id: number, endTime: number, durationMinutes: number, status: string) => Promise<void>;
    getAll: () => Promise<FocusRecord[]>;
    delete: (id: number) => Promise<void>;
  };
  stats: {
    load: () => Promise<StatsData>;
    weekly: () => Promise<ChartPoint[]>;
    monthly: () => Promise<ChartPoint[]>;
  };
  notify: {
    send: (title: string, body: string) => Promise<void>;
  };
  hotkey: {
    register: (accelerator: string) => Promise<boolean>;
    unregister: () => Promise<void>;
    onTriggered: (callback: () => void) => () => void;
  };
  data: {
    export: () => Promise<boolean>;
    reset: () => Promise<void>;
  };
  app: {
    version: () => Promise<string>;
    openExternal: (url: string) => void;
  };
};

declare global {
  interface Window {
    electronAPI: ElectronAPI;
  }
}
