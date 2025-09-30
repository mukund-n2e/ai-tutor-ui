import React from 'react';
import '../styles/tokens.css';

interface ChipProps {
  children: React.ReactNode;
  icon?: React.ReactNode;
  className?: string;
  title?: string;
}

export default function Chip({ children, icon, className = '', title }: ChipProps) {
  const baseClasses = 'inline-flex items-center gap-2 px-3 py-1 text-sm font-medium text-[var(--text-mid)] bg-[var(--surface-muted)] border border-[var(--border)] rounded-[var(--radius-chip)]';
  
  return (
    <span className={`${baseClasses} ${className}`.trim()} title={title}>
      {icon && <span className="flex-shrink-0">{icon}</span>}
      {children}
    </span>
  );
}