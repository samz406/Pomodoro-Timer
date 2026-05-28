import React, { useState, useEffect, useCallback } from 'react';
import { useTimer } from '../../hooks/useTimer';
import Toggle from '../ui/Toggle';
import './settings.css';

interface Props {
  timer: ReturnType<typeof useTimer>;
}

export default function SettingsPage({ timer }: Props) {
  const { settings, updateSettings, loadSettings, reset } = timer;
  const [version, setVersion] = useState('1.0.0');
  const [recording, setRecording] = useState(false);
  const [showReset, setShowReset] = useState(false);
  const [exportMsg, setExportMsg] = useState('');

  useEffect(() => {
    window.electronAPI.app.version().then(setVersion);
  }, []);

  // Global shortcut recording
  const startRecording = useCallback(() => {
    setRecording(true);
    const onKey = async (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        setRecording(false);
        window.removeEventListener('keydown', onKey, true);
        return;
      }
      // Require a modifier
      const mods = [];
      if (e.ctrlKey) mods.push('Ctrl');
      if (e.altKey) mods.push('Alt');
      if (e.shiftKey) mods.push('Shift');
      if (e.metaKey) mods.push('Meta');
      if (mods.length === 0) return;

      e.preventDefault();
      e.stopPropagation();

      const key = e.key.length === 1 ? e.key.toUpperCase() : e.key;
      const accelerator = [...mods, key].join('+');
      setRecording(false);
      window.removeEventListener('keydown', onKey, true);

      const ok = await window.electronAPI.hotkey.register(accelerator);
      if (ok) {
        await updateSettings({ hotkeyAccelerator: accelerator });
      }
    };
    window.addEventListener('keydown', onKey, true);
  }, [updateSettings]);

  const clearHotkey = async () => {
    await window.electronAPI.hotkey.unregister();
    await updateSettings({ hotkeyAccelerator: '' });
  };

  const exportData = async () => {
    const ok = await window.electronAPI.data.export();
    setExportMsg(ok ? '导出成功！' : '已取消');
    setTimeout(() => setExportMsg(''), 3000);
  };

  const doReset = async () => {
    await window.electronAPI.data.reset();
    await loadSettings();
    await reset();
    setShowReset(false);
  };

  return (
    <div className="page-scroll">
      <div className="page-content">

        {/* System */}
        <div className="section-header"><GearIcon />系统</div>
        <div className="panel">
          <div className="toggle-row">
            <div className="toggle-label">登录时自动启动</div>
            <Toggle
              checked={settings.launchAtLogin}
              onChange={v => updateSettings({ launchAtLogin: v })}
            />
          </div>
          <div className="toggle-row">
            <div className="toggle-label">窗口置顶</div>
            <Toggle
              checked={settings.isAlwaysOnTop}
              onChange={v => updateSettings({ isAlwaysOnTop: v })}
            />
          </div>
        </div>

        <hr className="divider" />

        {/* Hotkey */}
        <div className="section-header"><KeyboardIcon />全局快捷键</div>
        <div className="panel">
          <div className="toggle-row">
            <div>
              <div className="toggle-label">暂停 / 启动计时</div>
              <div className="toggle-desc">示例：Ctrl+Alt+P（点击按钮后按下快捷键）</div>
            </div>
            <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
              <button
                className={`hotkey-btn ${recording ? 'recording' : ''}`}
                onClick={startRecording}
              >
                {recording ? '按下快捷键...' : (settings.hotkeyAccelerator || '未设置')}
              </button>
              {settings.hotkeyAccelerator && !recording && (
                <button className="clear-btn" onClick={clearHotkey} title="清除">✕</button>
              )}
            </div>
          </div>
        </div>

        <hr className="divider" />

        {/* Data management */}
        <div className="section-header"><DriveIcon />本地数据管理</div>
        <div className="panel">
          <div className="data-actions">
            <button className="btn btn-secondary" onClick={exportData}>
              <UploadIcon /> 导出备份数据
            </button>
            <button className="btn btn-danger" onClick={() => setShowReset(true)}>
              <TrashIcon /> 重置全量数据
            </button>
          </div>
          {exportMsg && <div className="export-msg">{exportMsg}</div>}
        </div>

        <hr className="divider" />

        {/* About */}
        <div className="section-header"><InfoIcon />关于</div>
        <div className="panel">
          <div className="about-row"><span className="about-key">版本</span><span>{version}</span></div>
          <div className="about-row"><span className="about-key">数据存储</span><span>本地 SQLite（无网络）</span></div>
          <div className="about-row"><span className="about-key">平台</span><span>Electron + React</span></div>
        </div>

      </div>

      {/* Reset confirm modal */}
      {showReset && (
        <div className="modal-overlay">
          <div className="modal">
            <h3>确认重置全量数据</h3>
            <p>此操作将清空所有专注记录并将设置恢复为出厂状态，操作不可撤销。</p>
            <div className="modal-actions">
              <button className="btn btn-secondary" onClick={() => setShowReset(false)}>取消</button>
              <button className="btn btn-danger" onClick={doReset}>重置</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function GearIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="3" />
      <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z" />
    </svg>
  );
}

function KeyboardIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="2" y="6" width="20" height="13" rx="2" />
      <path d="M6 10h.01M10 10h.01M14 10h.01M18 10h.01M8 14h8" />
    </svg>
  );
}

function DriveIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <ellipse cx="12" cy="5" rx="9" ry="3" />
      <path d="M21 12c0 1.66-4 3-9 3s-9-1.34-9-3" />
      <path d="M3 5v14c0 1.66 4 3 9 3s9-1.34 9-3V5" />
    </svg>
  );
}

function InfoIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="10" /><line x1="12" y1="16" x2="12" y2="12" /><line x1="12" y1="8" x2="12.01" y2="8" />
    </svg>
  );
}

function UploadIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
      <polyline points="17 8 12 3 7 8" />
      <line x1="12" y1="3" x2="12" y2="15" />
    </svg>
  );
}

function TrashIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="3 6 5 6 21 6" />
      <path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6" />
    </svg>
  );
}
