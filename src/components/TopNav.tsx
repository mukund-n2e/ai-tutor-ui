'use client'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
const links = [
  { href: '/', label: 'Home' },
  { href: '/tutor', label: 'Tutor' },
  { href: '/sessions', label: 'Sessions' },
  { href: '/settings', label: 'Settings' },
  { href: '/ship', label: 'Ship' },
]
export default function TopNav() {
  const pathname = usePathname()
  return (
    <nav className="topnav" style={{display:'flex',gap:'1rem',padding:'12px',borderBottom:'1px solid #eee'}}>
  <Link href="/" className="brand"><img src="/brand/logo.svg" alt="Nudge2Edge" /><span>Nudge2Edge</span></Link>
      {links.map(l => (
        <Link
          key={l.href}
          href={l.href}
          style={{
            textDecoration: 'none',
            color: pathname === l.href ? '#111' : '#555',
            fontWeight: pathname === l.href ? 700 : 400
          }}
        >
          {l.label}
        </Link>
      ))}
    </nav>
  )
}
