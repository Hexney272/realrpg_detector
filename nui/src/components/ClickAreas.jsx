import React from 'react'

/**
 * Invisible/subtle click areas that appear ONLY when cursor is active (M pressed).
 * They follow 3D world positions (sent from Lua at ~100ms when cursor is active).
 * The actual visual markers are drawn natively in Lua (no stutter).
 */
export default function ClickAreas({ digIcon, crateIcons, onDigClick, onCrateClick }) {
  return (
    <div className="click-areas-overlay">
      {/* Dig click area */}
      {digIcon && (
        <button
          className="click-area click-area-dig"
          style={{ left: `${digIcon.x}%`, top: `${digIcon.y}%` }}
          onClick={() => onDigClick(digIcon.pointId)}
          title="Ásás"
        >
          <span className="click-area-text">⛏ Ásás</span>
        </button>
      )}

      {/* Crate click areas */}
      {crateIcons.map((crate) => (
        <button
          key={crate.crateId}
          className={`click-area click-area-crate ${crate.canPickup ? 'ready' : 'far'}`}
          style={{ left: `${crate.x}%`, top: `${crate.y}%` }}
          onClick={crate.canPickup ? () => onCrateClick(crate.crateId) : undefined}
          disabled={!crate.canPickup}
          title={crate.canPickup ? 'Felvétel' : 'Menj közelebb'}
        >
          <span className="click-area-text">
            {crate.canPickup ? '✋ Felvétel' : `${crate.label}`}
          </span>
        </button>
      ))}
    </div>
  )
}
