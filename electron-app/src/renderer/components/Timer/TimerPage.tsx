import React, { useRef, useCallback } from 'react';
import { useTimer } from '../../hooks/useTimer';
import './timer.css';

const RING_SIZE = 260;
const LINE_WIDTH = 14;
const RADIUS = RING_SIZE / 2 - LINE_WIDTH / 2;
const CIRCUMFERENCE = 2 * Math.PI * RADIUS;

interface Props {
  timer: ReturnType<typeof useTimer>;
}

// Presets: (label, minutes)
const PRESETS: [string, number][] = [
  ['25 分钟', 25],
  ['30 分钟', 30],
  ['45 分钟', 45],
];

export default function TimerPage({ timer }: Props) {
  const {
    settings,
    selectedMinutes,
    progress,
    isRunning,
    isPaused,
    timeString,
    phaseLabel,
    stats,
    startOrPause,
    reset,
    setMinutesFromAngle,
    setSelectedMinutes,
  } = timer;

  const accent = settings.digitColorHex;
  const svgRef = useRef<SVGSVGElement>(null);
  const dragging = useRef(false);

  // Dash offset for progress ring
  const dashOffset = CIRCUMFERENCE * (1 - progress);

  // Thumb position
  const thumbAngle = -Math.PI / 2 + progress * 2 * Math.PI;
  const thumbX = RING_SIZE / 2 + Math.cos(thumbAngle) * RADIUS;
  const thumbY = RING_SIZE / 2 + Math.sin(thumbAngle) * RADIUS;

  const angleFromEvent = useCallback((e: React.MouseEvent | MouseEvent) => {
    const svg = svgRef.current;
    if (!svg) return 0;
    const rect = svg.getBoundingClientRect();
    const cx = rect.left + rect.width / 2;
    const cy = rect.top + rect.height / 2;
    const dx = e.clientX - cx;
    const dy = e.clientY - cy;
    let angle = (Math.atan2(dy, dx) * 180) / Math.PI + 90;
    if (angle < 0) angle += 360;
    return angle;
  }, []);

  const onMouseDown = useCallback((e: React.MouseEvent) => {
    if (isRunning || isPaused) return;
    dragging.current = true;
    e.preventDefault();
    const onMove = (ev: MouseEvent) => {
      if (!dragging.current) return;
      setMinutesFromAngle(angleFromEvent(ev));
    };
    const onUp = () => {
      dragging.current = false;
      window.removeEventListener('mousemove', onMove);
      window.removeEventListener('mouseup', onUp);
    };
    window.addEventListener('mousemove', onMove);
    window.addEventListener('mouseup', onUp);
  }, [isRunning, isPaused, setMinutesFromAngle, angleFromEvent]);

  const totalFocusString = () => {
    const h = Math.floor(stats.totalMinutes / 60);
    const m = stats.totalMinutes % 60;
    if (h > 0) return `${h}h ${m}m`;
    return `${m}m`;
  };

  return (
    <div className="timer-page">
      {/* Left: circular timer */}
      <div className="timer-center">
        <svg
          ref={svgRef}
          width={RING_SIZE}
          height={RING_SIZE}
          className="timer-ring"
          onMouseDown={onMouseDown}
          style={{ cursor: isRunning || isPaused ? 'default' : 'grab' }}
        >
          {/* Track */}
          <circle
            cx={RING_SIZE / 2}
            cy={RING_SIZE / 2}
            r={RADIUS}
            fill="none"
            stroke="rgba(255,255,255,0.07)"
            strokeWidth={LINE_WIDTH}
          />
          {/* Progress */}
          <circle
            cx={RING_SIZE / 2}
            cy={RING_SIZE / 2}
            r={RADIUS}
            fill="none"
            stroke={accent}
            strokeWidth={LINE_WIDTH}
            strokeLinecap="round"
            strokeDasharray={CIRCUMFERENCE}
            strokeDashoffset={dashOffset}
            transform={`rotate(-90 ${RING_SIZE / 2} ${RING_SIZE / 2})`}
            style={{ transition: 'stroke-dashoffset 0.3s linear' }}
          />
          {/* Thumb (drag handle) */}
          {!isRunning && !isPaused && (
            <circle
              cx={thumbX}
              cy={thumbY}
              r={11}
              fill={accent}
              filter="url(#thumbShadow)"
              style={{ cursor: 'grab' }}
            />
          )}
          <defs>
            <filter id="thumbShadow" x="-50%" y="-50%" width="200%" height="200%">
              <feDropShadow dx="0" dy="1" stdDeviation="3" floodColor={accent} floodOpacity="0.5" />
            </filter>
          </defs>
          {/* Center text */}
          <text
            x={RING_SIZE / 2}
            y={RING_SIZE / 2 - 8}
            textAnchor="middle"
            dominantBaseline="middle"
            fill={accent}
            fontSize="44"
            fontWeight="700"
            fontFamily="monospace"
            style={{ userSelect: 'none' }}
          >
            {timeString}
          </text>
          <text
            x={RING_SIZE / 2}
            y={RING_SIZE / 2 + 28}
            textAnchor="middle"
            dominantBaseline="middle"
            fill="var(--text-2)"
            fontSize="13"
            style={{ userSelect: 'none' }}
          >
            {phaseLabel}
          </text>
        </svg>

        {/* Controls */}
        <div className="timer-controls">
          <button
            className="btn-round btn-round-primary"
            style={{ background: accent }}
            onClick={startOrPause}
          >
            {isRunning ? (
              <PauseIcon />
            ) : (
              <PlayIcon />
            )}
          </button>
          <button
            className="btn-round btn-round-secondary"
            onClick={reset}
            title="重置"
          >
            <ResetIcon />
          </button>
        </div>

        {/* Presets */}
        <div className="preset-row">
          {PRESETS.map(([label, min]) => (
            <button
              key={min}
              className={`preset-btn ${selectedMinutes === min ? 'active' : ''}`}
              style={selectedMinutes === min ? { borderColor: accent, color: accent } : {}}
              onClick={() => setSelectedMinutes(min)}
              disabled={isRunning || isPaused}
            >
              {label}
            </button>
          ))}
        </div>
      </div>

      {/* Right: bento stats */}
      <div className="bento-grid">
        <BentoCard label="今日专注" value={String(stats.todayCount)} unit="个" accent={accent} />
        <BentoCard label="累计时长" value={totalFocusString()} unit="" accent={accent} />
        <BentoCard label="连续打卡" value={String(stats.streakDays)} unit="天" accent={accent} />
        <BentoCard label="当前模式" value={modeLabel(settings.timerMode)} unit="" accent={accent} />
      </div>
    </div>
  );
}

function modeLabel(mode: number): string {
  if (mode === 1) return '正向';
  if (mode === 2) return '循环';
  return '经典';
}

function BentoCard({ label, value, unit, accent }: { label: string; value: string; unit: string; accent: string }) {
  return (
    <div className="bento-card">
      <div className="bento-label">{label}</div>
      <div className="bento-value">
        <span style={{ color: accent }}>{value}</span>
        {unit && <span className="bento-unit">{unit}</span>}
      </div>
    </div>
  );
}

function PlayIcon() {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
      <polygon points="5,3 19,12 5,21" />
    </svg>
  );
}

function PauseIcon() {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
      <rect x="6" y="4" width="4" height="16" rx="1" />
      <rect x="14" y="4" width="4" height="16" rx="1" />
    </svg>
  );
}

function ResetIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8" />
      <path d="M3 3v5h5" />
    </svg>
  );
}
