import React from 'react'

export default function DigIcons({ icons, cursorActive, onClick }) {
  if (!icons || icons.length === 0) return null

  return (
    <div className="world-overlay">
      {icons.map((icon) => (
        <div
          key={icon.pointId}
          className={`dig-icon ${icon.diggable ? 'diggable' : 'distant'} ${cursorActive ? 'clickable' : ''}`}
          style={{
            left: `${icon.x}%`,
            top: `${icon.y}%`,
            opacity: icon.alpha
          }}
          onClick={cursorActive && icon.diggable ? () => onClick(icon.pointId) : undefined}
        >
          <div className="dig-icon-ring">
            <div className="dig-icon-inner">
              <svg viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path
                  d="M16 4L18 14L28 16L18 18L16 28L14 18L4 16L14 14L16 4Z"
                  fill="currentColor"
                  stroke="currentColor"
                  strokeWidth="0.5"
                />
              </svg>
            </div>
          </div>
          {icon.diggable && (
            <span className="dig-icon-label">Ásás</span>
          )}
          {!icon.diggable && (
            <span className="dig-icon-dist">{icon.dist}m</span>
          )}
        </div>
      ))}
    </div>
  )
}
