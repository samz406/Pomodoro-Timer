import React from 'react';
import { useTimer } from '../../hooks/useTimer';
import Toggle from '../ui/Toggle';
import './theme.css';

interface Props {
  timer: ReturnType<typeof useTimer>;
}

interface ThemeDef {
  id: string;
  name: string;
  color: string;
  description: string;
}

const THEMES: ThemeDef[] = [
  { id: 'tomato',     name: '经典番茄红', color: '#E25C43', description: '温暖专注，经典配色' },
  { id: 'geek',       name: '极客复古绿', color: '#43A047', description: '终端风格，极简复古' },
  { id: 'deep_space', name: '深空冷峻蓝', color: '#1976D2', description: '沉静深邃，专注利器' },
  { id: 'midnight',   name: '暗夜极简黑', color: '#424242', description: '低调极简，夜间友好' },
];

export default function ThemePage({ timer }: Props) {
  const { settings, updateSettings } = timer;

  const selectTheme = (t: ThemeDef) => {
    updateSettings({ currentTheme: t.id, digitColorHex: t.color });
  };

  return (
    <div className="page-scroll">
      <div className="page-content">
        <div className="section-header">
          <PaletteIcon />
          主题配色
        </div>

        {/* Follow system toggle */}
        <div className="panel">
          <div className="toggle-row">
            <div>
              <div className="toggle-label">紧随系统外观切换</div>
              <div className="toggle-desc">开启后，深色模式下自动使用深色背景</div>
            </div>
            <Toggle
              checked={settings.followSystemAppearance}
              onChange={v => updateSettings({ followSystemAppearance: v })}
            />
          </div>
        </div>

        {/* Theme grid */}
        <div className="theme-grid">
          {THEMES.map(t => {
            const isSelected = settings.currentTheme === t.id;
            return (
              <button
                key={t.id}
                className={`theme-card ${isSelected ? 'selected' : ''}`}
                style={isSelected ? { borderColor: t.color, boxShadow: `0 0 0 3px ${t.color}22` } : {}}
                onClick={() => selectTheme(t)}
              >
                {/* Preview */}
                <div className="theme-preview" style={{ background: `${t.color}18` }}>
                  <svg width="60" height="60" viewBox="0 0 60 60">
                    <circle cx="30" cy="30" r="26" fill="none" stroke={t.color} strokeWidth="4" />
                    <text x="30" y="34" textAnchor="middle" fill={t.color} fontSize="12" fontWeight="700" fontFamily="monospace">25:00</text>
                  </svg>
                  <div className="theme-preview-dots">
                    {[0, 1, 2].map(i => (
                      <div key={i} className="theme-dot" style={{ background: `${t.color}80` }} />
                    ))}
                  </div>
                </div>
                {/* Info */}
                <div className="theme-info">
                  <div className="theme-name">
                    {t.name}
                    {isSelected && (
                      <svg width="16" height="16" viewBox="0 0 24 24" fill={t.color}><path d="M20 6L9 17l-5-5" stroke={t.color} strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" fill="none" /></svg>
                    )}
                  </div>
                  <div className="theme-desc">{t.description}</div>
                </div>
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}

function PaletteIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 22C6.477 22 2 17.523 2 12S6.477 2 12 2s10 4.477 10 10c0 2.5-2 4-4 4h-2a2 2 0 0 0-2 2 2 2 0 0 1-2 2z" />
      <circle cx="7.5" cy="10.5" r="1.5" fill="currentColor" stroke="none" />
      <circle cx="12" cy="7.5" r="1.5" fill="currentColor" stroke="none" />
      <circle cx="16.5" cy="10.5" r="1.5" fill="currentColor" stroke="none" />
    </svg>
  );
}
