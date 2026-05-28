import React, { useEffect, useState, useCallback } from 'react';
import { FocusRecord, ChartPoint } from '../../../shared/types';
import './records.css';

interface Props {
  accentColor: string;
}

function formatDate(ts: number): string {
  const d = new Date(ts);
  return d.toLocaleString('zh-CN', { month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit', hour12: false });
}

function dayLabel(dateStr: string, showMonthly: boolean): string {
  const d = new Date(dateStr + 'T00:00:00');
  if (showMonthly) {
    return `${d.getMonth() + 1}/${d.getDate()}`;
  }
  return ['日', '一', '二', '三', '四', '五', '六'][d.getDay()];
}

export default function RecordsPage({ accentColor }: Props) {
  const [records, setRecords] = useState<FocusRecord[]>([]);
  const [weekly, setWeekly] = useState<ChartPoint[]>([]);
  const [monthly, setMonthly] = useState<ChartPoint[]>([]);
  const [showMonthly, setShowMonthly] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<FocusRecord | null>(null);

  const load = useCallback(async () => {
    const [recs, w, m] = await Promise.all([
      window.electronAPI.records.getAll(),
      window.electronAPI.stats.weekly(),
      window.electronAPI.stats.monthly(),
    ]);
    setRecords(recs);
    setWeekly(w);
    setMonthly(m);
  }, []);

  useEffect(() => { load(); }, [load]);

  const chartData = showMonthly ? monthly : weekly;
  const maxVal = Math.max(...chartData.map(d => d.minutes), 1);

  const confirmDelete = async () => {
    if (!deleteTarget) return;
    await window.electronAPI.records.delete(deleteTarget.id);
    setDeleteTarget(null);
    load();
  };

  // Interruption heatmap by hour
  const hourCounts = Array(24).fill(0) as number[];
  for (const r of records) {
    if (r.status === 'INTERRUPTED') {
      const hour = new Date(r.startTime).getHours();
      hourCounts[hour]++;
    }
  }
  const maxHour = Math.max(...hourCounts, 1);

  return (
    <div className="page-scroll">
      <div className="records-page">
        {/* Charts row */}
        <div className="charts-row">
          {/* Bar chart */}
          <div className="panel chart-panel">
            <div className="chart-header">
              <span className="chart-title">{showMonthly ? '月度专注（分钟）' : '周专注（分钟）'}</span>
              <div className="seg-control">
                <button className={!showMonthly ? 'active' : ''} onClick={() => setShowMonthly(false)}>周</button>
                <button className={showMonthly ? 'active' : ''} onClick={() => setShowMonthly(true)}>月</button>
              </div>
            </div>
            <div className="bar-chart">
              {chartData.map((d, i) => (
                <div key={i} className="bar-col">
                  {d.minutes > 0 && <span className="bar-val">{d.minutes}</span>}
                  <div
                    className="bar"
                    style={{
                      height: `${Math.max(4, (d.minutes / maxVal) * 100)}px`,
                      background: accentColor,
                    }}
                  />
                  <span className="bar-label">{dayLabel(d.date, showMonthly)}</span>
                </div>
              ))}
            </div>
          </div>

          {/* Heatmap */}
          <div className="panel heatmap-panel">
            <div className="chart-title">打断分布</div>
            <div className="heatmap-label">打断时段热力图</div>
            <div className="heatmap-grid">
              {hourCounts.map((count, hour) => {
                const intensity = count / maxHour;
                return (
                  <div
                    key={hour}
                    className="heatmap-cell"
                    title={`${hour}:00 — ${count} 次打断`}
                    style={{ background: `rgba(255, 165, 0, ${0.1 + 0.9 * intensity})` }}
                  >
                    <span className="heatmap-hour">{hour}</span>
                  </div>
                );
              })}
            </div>
            <div className="heatmap-legend">
              <span>低</span><span>高</span>
            </div>
          </div>
        </div>

        {/* History table */}
        <div className="records-table-wrap">
          <div className="table-header">
            <span style={{ width: 150 }}>开始时间</span>
            <span style={{ width: 90, textAlign: 'center' }}>预计时长</span>
            <span style={{ width: 90, textAlign: 'center' }}>实际时长</span>
            <span style={{ width: 80, textAlign: 'center' }}>状态</span>
            <span style={{ flex: 1 }} />
          </div>
          {records.length === 0 ? (
            <div className="empty-state">
              <EmptyIcon />
              <p>暂无记录，完成一个番茄钟后这里会显示历史数据</p>
            </div>
          ) : (
            <div className="records-list">
              {records.map(r => {
                const actualMins = r.endTime
                  ? Math.floor((r.endTime - r.startTime) / 60000)
                  : null;
                return (
                  <div key={r.id} className="record-row">
                    <span style={{ width: 150, fontFamily: 'monospace', fontSize: 13 }}>{formatDate(r.startTime)}</span>
                    <span style={{ width: 90, textAlign: 'center' }}>{r.durationMinutes} 分钟</span>
                    <span style={{ width: 90, textAlign: 'center' }}>
                      {actualMins !== null ? `${actualMins} 分钟` : '–'}
                    </span>
                    <span style={{ width: 80, textAlign: 'center' }}>
                      <StatusBadge status={r.status} />
                    </span>
                    <span style={{ flex: 1 }} />
                    <button
                      className="delete-btn"
                      title="删除"
                      onClick={() => setDeleteTarget(r)}
                    >
                      <TrashIcon />
                    </button>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>

      {/* Delete confirm dialog */}
      {deleteTarget && (
        <div className="modal-overlay">
          <div className="modal">
            <h3>确认删除</h3>
            <p>此操作将从本地数据库永久删除该条记录，无法恢复。</p>
            <div className="modal-actions">
              <button className="btn btn-secondary" onClick={() => setDeleteTarget(null)}>取消</button>
              <button className="btn btn-danger" onClick={confirmDelete}>删除</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function StatusBadge({ status }: { status: string }) {
  const done = status === 'COMPLETED';
  return (
    <span className={`status-badge ${done ? 'done' : 'interrupted'}`}>
      {done ? '完成' : '打断'}
    </span>
  );
}

function EmptyIcon() {
  return (
    <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="var(--text-2)" strokeWidth="1.5">
      <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
    </svg>
  );
}

function TrashIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <polyline points="3 6 5 6 21 6" />
      <path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6" />
      <path d="M10 11v6M14 11v6" />
      <path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2" />
    </svg>
  );
}

