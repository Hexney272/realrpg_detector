import React from 'react'

export default function CrateIcons({ icons, cursorActive, onClick }) {
  if (!icons || icons.length === 0) return null

  return (
    <div className="world-overlay">
      {icons.map((icon) => (
        <div
          key={icon.crateId}
          className={`crate-icon ${icon.canPickup ? 'pickup-ready' : 'distant'} ${cursorActive ? 'clickable' : ''}`}
          style={{
            left: `${icon.x}%`,
            top: `${icon.y}%`
          }}
          onClick={cursorActive && icon.canPickup ? () => onClick(icon.crateId) : undefined}
        >
          <div className="crate-icon-box">
            <svg viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
              <rect x="6" y="12" width="20" height="14" rx="2" fill="currentColor" opacity="0.85" />
              <rect x="6" y="12" width="20" height="14" rx="2" stroke="currentColor" strokeWidth="1.5" />
              <path d="M6 15H26" stroke="rgba(255,255,255,0.3)" strokeWidth="1" />
              <rect x="14" y="16" width="4" height="4" rx="1" fill="rgba(255,255,255,0.5)" />
              <path d="M10 12L12 8H20L22 12" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
            </svg>
          </div>
          <span className="crate-icon-label">{icon.label}</span>
          {icon.canPickup && cursorActive && (
            <span className="crate-pickup-hint">Felvétel</span>
          )}
        </div>
      ))}
    </div>
  )
}
