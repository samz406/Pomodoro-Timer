import React from 'react';

interface Props {
  checked: boolean;
  onChange: (v: boolean) => void;
}

export default function Toggle({ checked, onChange }: Props) {
  return (
    <label className="switch">
      <input type="checkbox" checked={checked} onChange={e => onChange(e.target.checked)} />
      <span className="switch-slider" />
    </label>
  );
}
