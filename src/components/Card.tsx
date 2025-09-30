import React from 'react';
import '../styles/tokens.css';

interface CardProps {
  children: React.ReactNode;
  className?: string;
  hover?: boolean;
}

export default function Card({ children, className = '', hover = false }: CardProps) {
  const baseClasses = 'bg-[var(--surface)] border border-[var(--border)] rounded-[var(--radius-card)] shadow-[var(--shadow-card)] p-card';
  const hoverClasses = hover ? 'hover:shadow-[var(--shadow-hover)] transition-shadow duration-200' : '';
  
  return (
    <div className={`${baseClasses} ${hoverClasses} ${className}`.trim()}>
      {children}
    </div>
  );
}