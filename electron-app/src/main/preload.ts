import { contextBridge, ipcRenderer } from 'electron';

const api = {
  settings: {
    load: () => ipcRenderer.invoke('settings:load'),
    save: (partial: Record<string, unknown>) => ipcRenderer.invoke('settings:save', partial),
  },
  records: {
    insert: (startTime: number, durationMinutes: number) =>
      ipcRenderer.invoke('records:insert', startTime, durationMinutes),
    update: (id: number, endTime: number, durationMinutes: number, status: string) =>
      ipcRenderer.invoke('records:update', id, endTime, durationMinutes, status),
    getAll: () => ipcRenderer.invoke('records:getAll'),
    delete: (id: number) => ipcRenderer.invoke('records:delete', id),
  },
  stats: {
    load: () => ipcRenderer.invoke('stats:load'),
    weekly: () => ipcRenderer.invoke('stats:weekly'),
    monthly: () => ipcRenderer.invoke('stats:monthly'),
  },
  notify: {
    send: (title: string, body: string) => ipcRenderer.invoke('notify:send', title, body),
  },
  hotkey: {
    register: (accelerator: string) => ipcRenderer.invoke('hotkey:register', accelerator),
    unregister: () => ipcRenderer.invoke('hotkey:unregister'),
    onTriggered: (callback: () => void) => {
      ipcRenderer.on('global-shortcut-triggered', callback);
      return () => ipcRenderer.removeListener('global-shortcut-triggered', callback);
    },
  },
  data: {
    export: () => ipcRenderer.invoke('data:export'),
    reset: () => ipcRenderer.invoke('data:reset'),
  },
  app: {
    version: () => ipcRenderer.invoke('app:version'),
    openExternal: (url: string) => ipcRenderer.send('open-external', url),
  },
};

contextBridge.exposeInMainWorld('electronAPI', api);
