import React from 'react';
import { useTimer } from '../../hooks/useTimer';
import Toggle from '../ui/Toggle';
import './countdown.css';

interface Props {
  timer: ReturnType<typeof useTimer>;
}

const MODES = ['经典番茄（倒计时）', '正向流逝计时', '无限循环模式'];

export default function CountdownPage({ timer }: Props) {
  const { settings, updateSettings } = timer;

  const set = (partial: Parameters<typeof updateSettings>[0]) => updateSettings(partial);

  return (
    <div className="page-scroll">
      <div className="page-content">
        {/* Timer Mode */}
        <div className="section-header">
          <ClockIcon />
          计时模式
        </div>
        <div className="panel">
          {MODES.map((label, idx) => (
            <div key={idx} className="mode-row" onClick={() => set({ timerMode: idx })}>
              <RadioIcon selected={settings.timerMode === idx} />
              <span>{label}</span>
            </div>
          ))}
        </div>

        <hr className="divider" />

        {/* Break Settings */}
        <div className="section-header">
          <BellIcon />
          结束行为规则
        </div>
        <div className="panel">
          <div className="toggle-row">
            <div>
              <div className="toggle-label">倒计时完毕后自动进入休息</div>
            </div>
            <Toggle
              checked={settings.autoBreak}
              onChange={v => set({ autoBreak: v })}
            />
          </div>

          {settings.autoBreak && (
            <div className="toggle-row">
              <div className="toggle-label" style={{ paddingLeft: 24 }}>休息时长</div>
              <div className="stepper">
                <button
                  className="stepper-btn"
                  onClick={() => set({ breakMinutes: Math.max(1, settings.breakMinutes - 1) })}
                >−</button>
                <span className="stepper-value">{settings.breakMinutes} 分钟</span>
                <button
                  className="stepper-btn"
                  onClick={() => set({ breakMinutes: Math.min(30, settings.breakMinutes + 1) })}
                >+</button>
              </div>
            </div>
          )}

          <div className="toggle-row">
            <div className="toggle-label">触发系统横幅通知</div>
            <Toggle
              checked={settings.showSystemNotification}
              onChange={v => set({ showSystemNotification: v })}
            />
          </div>

          <div className="toggle-row">
            <div className="toggle-label">自动跳过休息（休息后自动开始下一轮）</div>
            <Toggle
              checked={settings.autoSkipBreak}
              onChange={v => set({ autoSkipBreak: v })}
            />
          </div>
        </div>
      </div>
    </div>
  );
}

function RadioIcon({ selected }: { selected: boolean }) {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke={selected ? 'var(--accent)' : 'var(--text-2)'} strokeWidth="2">
      <circle cx="12" cy="12" r="10" />
      {selected && <circle cx="12" cy="12" r="5" fill="var(--accent)" stroke="none" />}
    </svg>
  );
}

function ClockIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8" />
      <path d="M3 3v5h5" /><path d="M12 7v5l4 2" />
    </svg>
  );
}

function BellIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
      <path d="M13.73 21a2 2 0 0 1-3.46 0" />
    </svg>
  );
}
