import React from 'react';
import '../styles/tokens.css';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  children: React.ReactNode;
}

export default function Button({ 
  variant = 'primary', 
  size = 'md', 
  className = '', 
  children, 
  ...props 
}: ButtonProps) {
  const baseClasses = 'inline-flex items-center justify-center font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50';
  
  const variantClasses = {
    primary: 'bg-[var(--brand-accent)] text-[var(--brand-accent-foreground)] hover:bg-[var(--brand-accent-hover)] focus-visible:ring-[var(--brand-accent)]',
    secondary: 'bg-[var(--surface)] border border-[var(--border)] text-[var(--text-high)] hover:bg-[var(--surface-hover)] focus-visible:ring-[var(--brand-accent)]',
    ghost: 'text-[var(--text-high)] hover:bg-[var(--surface-muted)] focus-visible:ring-[var(--brand-accent)]'
  } as const;
  
  const sizeClasses = {
    sm: 'h-9 px-3 text-sm rounded-[var(--radius-button)]',
    md: 'h-10 px-4 py-2 rounded-[var(--radius-button)]',
    lg: 'h-11 px-8 rounded-[var(--radius-button)]'
  } as const;
  
  return (
    <button className={`${baseClasses} ${variantClasses[variant]} ${sizeClasses[size]} min-touch ${className}`.trim()} {...props}>
      {children}
    </button>
  );
}