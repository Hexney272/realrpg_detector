import React from 'react'

export default function WorldIcons({ icons }) {
  if (!icons || icons.length === 0) return null

  return (
    <div className="world-icons-container">
      {icons.map((icon, i) => (
        <div
          key={i}
          className="world-icon"
          style={{
            left: `${icon.x}%`,
            top: `${icon.y}%`,
            opacity: Math.max(0.18, Math.min(icon.alpha || 0.55, 1))
          }}
        />
      ))}
    </div>
  )
}
