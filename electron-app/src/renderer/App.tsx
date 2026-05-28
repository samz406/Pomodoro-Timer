import React, { useState, useEffect } from 'react';
import { NavPage } from '../shared/types';
import { useTimer } from './hooks/useTimer';
import Sidebar from './components/Sidebar';
import TimerPage from './components/Timer/TimerPage';
import CountdownPage from './components/Countdown/CountdownPage';
import RecordsPage from './components/Records/RecordsPage';
import ThemePage from './components/Theme/ThemePage';
import SettingsPage from './components/Settings/SettingsPage';
import './styles/app.css';

export default function App() {
  const [page, setPage] = useState<NavPage>('timer');
  const timer = useTimer();

  // Apply theme accent color as CSS variable
  useEffect(() => {
    document.documentElement.style.setProperty('--accent', timer.settings.digitColorHex);
  }, [timer.settings.digitColorHex]);

  const renderPage = () => {
    switch (page) {
      case 'timer':     return <TimerPage timer={timer} />;
      case 'countdown': return <CountdownPage timer={timer} />;
      case 'records':   return <RecordsPage accentColor={timer.settings.digitColorHex} />;
      case 'theme':     return <ThemePage timer={timer} />;
      case 'settings':  return <SettingsPage timer={timer} />;
    }
  };

  return (
    <div className="app-shell">
      {/* macOS-style title bar drag region */}
      <div className="titlebar titlebar-drag" />
      <div className="app-body">
        <Sidebar
          current={page}
          onChange={setPage}
          title={timer.settings.interfaceName}
        />
        <main className="app-content">
          {renderPage()}
        </main>
      </div>
    </div>
  );
}
