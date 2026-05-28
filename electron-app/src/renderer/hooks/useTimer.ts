import { useState, useEffect, useCallback, useRef } from 'react';
import { AppSettings, StatsData, TimerPhase } from '../../shared/types';

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

export function useTimer() {
  const api = window.electronAPI;

  const [settings, setSettings] = useState<AppSettings>(DEFAULT_SETTINGS);
  const [selectedMinutes, setSelectedMinutesState] = useState(25);
  const [remainingSeconds, setRemainingSeconds] = useState(25 * 60);
  const [elapsedSeconds, setElapsedSeconds] = useState(0);
  const [isRunning, setIsRunning] = useState(false);
  const [isPaused, setIsPaused] = useState(false);
  const [phase, setPhase] = useState<TimerPhase>('focus');
  const [progress, setProgress] = useState(1.0);
  const [stats, setStats] = useState<StatsData>({ todayCount: 0, totalMinutes: 0, streakDays: 0 });

  // Refs to hold current values for use inside interval callback
  const settingsRef = useRef(settings);
  const selectedMinutesRef = useRef(selectedMinutes);
  const remainingSecondsRef = useRef(remainingSeconds);
  const phaseRef = useRef<TimerPhase>('focus');
  const isRunningRef = useRef(false);
  const currentRecordIdRef = useRef<number | null>(null);
  const sessionStartRef = useRef<number | null>(null);

  // Keep refs in sync with state
  settingsRef.current = settings;
  selectedMinutesRef.current = selectedMinutes;
  remainingSecondsRef.current = remainingSeconds;
  phaseRef.current = phase;
  isRunningRef.current = isRunning;

  const loadStats = useCallback(async () => {
    const s = await api.stats.load();
    setStats(s);
  }, [api]);

  const loadSettings = useCallback(async () => {
    const s = await api.settings.load();
    setSettings(s);
  }, [api]);

  // Stable completePhase using refs
  const completePhase = useCallback(async () => {
    const cfg = settingsRef.current;
    const selMin = selectedMinutesRef.current;
    const ph = phaseRef.current;

    if (ph === 'focus') {
      // Archive record
      const recId = currentRecordIdRef.current;
      const start = sessionStartRef.current;
      if (recId !== null && start !== null) {
        const actualMinutes = Math.max(1, Math.floor((Date.now() - start) / 60000));
        await api.records.update(recId, Date.now(), actualMinutes, 'COMPLETED');
        currentRecordIdRef.current = null;
        sessionStartRef.current = null;
      }
      await loadStats();
      if (cfg.showSystemNotification) {
        await api.notify.send('专注完成！', `休息一下吧，${cfg.breakMinutes} 分钟后继续。`);
      }

      if (cfg.autoBreak || cfg.timerMode === 2) {
        phaseRef.current = 'break';
        setPhase('break');
        setRemainingSeconds(cfg.breakMinutes * 60);
        remainingSecondsRef.current = cfg.breakMinutes * 60;
        setProgress(1.0);
      } else {
        isRunningRef.current = false;
        setIsRunning(false);
        setIsPaused(false);
        currentRecordIdRef.current = null;
        sessionStartRef.current = null;
        setElapsedSeconds(0);
        setRemainingSeconds(selMin * 60);
        remainingSecondsRef.current = selMin * 60;
        setProgress(1.0);
      }
    } else {
      // Break phase complete
      if (cfg.showSystemNotification) {
        await api.notify.send('休息结束', '开始新一轮专注！');
      }
      if (cfg.autoSkipBreak || cfg.timerMode === 2) {
        const now = Date.now();
        const id = await api.records.insert(now, selMin);
        currentRecordIdRef.current = id;
        sessionStartRef.current = now;
        phaseRef.current = 'focus';
        setPhase('focus');
        setRemainingSeconds(selMin * 60);
        remainingSecondsRef.current = selMin * 60;
        setProgress(1.0);
        isRunningRef.current = true;
        setIsRunning(true);
        setIsPaused(false);
      } else {
        isRunningRef.current = false;
        setIsRunning(false);
        setIsPaused(false);
        currentRecordIdRef.current = null;
        sessionStartRef.current = null;
        setElapsedSeconds(0);
        phaseRef.current = 'focus';
        setPhase('focus');
        setRemainingSeconds(selMin * 60);
        remainingSecondsRef.current = selMin * 60;
        setProgress(1.0);
      }
    }
  }, [api, loadStats]);

  // Interval-based timer tick
  useEffect(() => {
    if (!isRunning) return;
    const id = setInterval(async () => {
      if (!isRunningRef.current) return;

      setElapsedSeconds(e => e + 1);

      if (settingsRef.current.timerMode === 1) {
        // Forward elapsed mode
        setProgress(1.0);
        return;
      }

      const newRemaining = remainingSecondsRef.current - 1;
      remainingSecondsRef.current = newRemaining;
      setRemainingSeconds(newRemaining);

      const totalSeconds =
        phaseRef.current === 'focus'
          ? selectedMinutesRef.current * 60
          : settingsRef.current.breakMinutes * 60;
      setProgress(Math.max(0, newRemaining / totalSeconds));

      if (newRemaining <= 0) {
        await completePhase();
      }
    }, 1000);
    return () => clearInterval(id);
  }, [isRunning, completePhase]);

  // Init
  useEffect(() => {
    loadSettings();
    loadStats();
    const remove = api.hotkey.onTriggered(() => startOrPauseRef.current());
    return remove;
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  const start = useCallback(async () => {
    const now = Date.now();
    const id = await api.records.insert(now, selectedMinutesRef.current);
    currentRecordIdRef.current = id;
    sessionStartRef.current = now;
    setElapsedSeconds(0);
    isRunningRef.current = true;
    setIsRunning(true);
    setIsPaused(false);
    phaseRef.current = 'focus';
    setPhase('focus');
  }, [api]);

  const pause = useCallback(() => {
    isRunningRef.current = false;
    setIsRunning(false);
    setIsPaused(true);
  }, []);

  const resume = useCallback(() => {
    isRunningRef.current = true;
    setIsRunning(true);
    setIsPaused(false);
  }, []);

  const reset = useCallback(async () => {
    const recId = currentRecordIdRef.current;
    const start = sessionStartRef.current;
    if (recId !== null && start !== null) {
      const actualMinutes = Math.max(1, Math.floor((Date.now() - start) / 60000));
      await api.records.update(recId, Date.now(), actualMinutes, 'INTERRUPTED');
    }
    isRunningRef.current = false;
    setIsRunning(false);
    setIsPaused(false);
    currentRecordIdRef.current = null;
    sessionStartRef.current = null;
    setElapsedSeconds(0);
    const selMin = selectedMinutesRef.current;
    setRemainingSeconds(selMin * 60);
    remainingSecondsRef.current = selMin * 60;
    setProgress(1.0);
    phaseRef.current = 'focus';
    setPhase('focus');
    await loadStats();
  }, [api, loadStats]);

  const startOrPause = useCallback(() => {
    if (isRunningRef.current) pause();
    else if (isPaused) resume();
    else start();
  }, [isPaused, pause, resume, start]);

  // Stable ref for hotkey callback
  const startOrPauseRef = useRef(startOrPause);
  startOrPauseRef.current = startOrPause;

  const setMinutesFromAngle = useCallback((angleDeg: number) => {
    if (isRunningRef.current || isPaused) return;
    const fraction = angleDeg / 360;
    const minutes = Math.max(1, Math.min(90, Math.floor(fraction * 90) + 1));
    setSelectedMinutesState(minutes);
    selectedMinutesRef.current = minutes;
    setRemainingSeconds(minutes * 60);
    remainingSecondsRef.current = minutes * 60;
    setProgress(1.0);
  }, [isPaused]);

  const setSelectedMinutes = useCallback((m: number) => {
    if (isRunningRef.current || isPaused) return;
    setSelectedMinutesState(m);
    selectedMinutesRef.current = m;
    setRemainingSeconds(m * 60);
    remainingSecondsRef.current = m * 60;
    setProgress(1.0);
  }, [isPaused]);

  const updateSettings = useCallback(async (partial: Partial<AppSettings>) => {
    await api.settings.save(partial);
    setSettings(prev => ({ ...prev, ...partial }));
  }, [api]);

  const timeString = (): string => {
    const secs = settings.timerMode === 1 ? elapsedSeconds : remainingSeconds;
    const m = Math.floor(secs / 60);
    const s = secs % 60;
    return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
  };

  const phaseLabel = (): string => {
    if (phase === 'focus') {
      if (isRunning) return '专注时间';
      if (isPaused) return '已暂停';
      return '准备开始';
    }
    return isRunning ? '休息时间' : '休息完成';
  };

  return {
    settings,
    selectedMinutes,
    remainingSeconds,
    elapsedSeconds,
    isRunning,
    isPaused,
    phase,
    progress,
    stats,
    timeString: timeString(),
    phaseLabel: phaseLabel(),
    start,
    pause,
    resume,
    reset,
    startOrPause,
    setMinutesFromAngle,
    updateSettings,
    loadSettings,
    loadStats,
    setSelectedMinutes,
  };
}

