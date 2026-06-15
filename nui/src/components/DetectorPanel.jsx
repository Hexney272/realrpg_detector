import React, { useState, useRef, useCallback, useEffect } from 'react'

export default function DetectorPanel({ data, onDig }) {
  const [position, setPosition] = useState({ x: window.innerWidth - 380, y: window.innerHeight / 2 - 180 })
  const [dragging, setDragging] = useState(false)
  const dragOffset = useRef({ x: 0, y: 0 })
  const panelRef = useRef(null)

  // Dragging logic
  const handleMouseDown = useCallback((e) => {
    if (e.target.closest('.dig-btn')) return // Don't drag when clicking dig button
    setDragging(true)
    dragOffset.current = {
      x: e.clientX - position.x,
      y: e.clientY - position.y
    }
  }, [position])

  const handleMouseMove = useCallback((e) => {
    if (!dragging) return
    setPosition({
      x: e.clientX - dragOffset.current.x,
      y: e.clientY - dragOffset.current.y
    })
  }, [dragging])

  const handleMouseUp = useCallback(() => {
    setDragging(false)
  }, [])

  useEffect(() => {
    if (dragging) {
      window.addEventListener('mousemove', handleMouseMove)
      window.addEventListener('mouseup', handleMouseUp)
    }
    return () => {
      window.removeEventListener('mousemove', handleMouseMove)
      window.removeEventListener('mouseup', handleMouseUp)
    }
  }, [dragging, handleMouseMove, handleMouseUp])

  const formatCoord = (value) => {
    const sign = value >= 0 ? '+' : '-'
    return `${sign}${Math.abs(Math.floor(value)).toString().padStart(4, '0')}`
  }

  // Calculate arrow rotation: angle is relative to player heading
  // Positive = right, negative = left
  const arrowRotation = data.hasTarget ? data.angle : 0
  const strengthPercent = Math.round(data.strength * 100)
  const distanceDisplay = data.hasTarget ? `${Math.round(data.distance)}m` : '---'

  // Radar dot position (from center, based on angle and distance ratio)
  const radarRadius = 42 // percentage from center
  const distRatio = data.hasTarget ? Math.min(data.distance / data.maxDistance, 1) : 0
  const dotX = 50 + Math.sin((data.angle * Math.PI) / 180) * (distRatio * radarRadius)
  const dotY = 50 - Math.cos((data.angle * Math.PI) / 180) * (distRatio * radarRadius)
  const dotSize = 10 + data.strength * 16

  return (
    <div
      ref={panelRef}
      className={`detector-panel ${dragging ? 'dragging' : ''}`}
      style={{ left: position.x, top: position.y }}
      onMouseDown={handleMouseDown}
    >
      {/* Header */}
      <div className="panel-header">
        <div className="header-left">
          <span className="header-icon">&#9783;</span>
          <span className="header-title">FMDETEKTOR</span>
        </div>
        <div className="header-coords">
          {formatCoord(data.coordX)}, {formatCoord(data.coordY)}
        </div>
      </div>

      {/* Main content */}
      <div className="panel-body">
        {/* Radar / Compass */}
        <div className="radar-container">
          <div className="radar-ring ring-outer" />
          <div className="radar-ring ring-mid" />
          <div className="radar-ring ring-inner" />
          <div className="radar-cross-v" />
          <div className="radar-cross-h" />

          {/* Cardinal directions */}
          <span className="cardinal cardinal-n">N</span>
          <span className="cardinal cardinal-s">D</span>
          <span className="cardinal cardinal-e">K</span>
          <span className="cardinal cardinal-w">NY</span>

          {/* Sweep animation */}
          <div className="radar-sweep" />

          {/* Target dot */}
          {data.hasTarget && (
            <div
              className="radar-dot"
              style={{
                left: `${dotX}%`,
                top: `${dotY}%`,
                width: dotSize,
                height: dotSize,
                opacity: 0.6 + data.strength * 0.4
              }}
            />
          )}

          {/* Center dot (player) */}
          <div className="radar-center" />
        </div>

        {/* Direction arrow (large, shows direction to treasure) */}
        <div className="direction-section">
          <div className="direction-arrow-container">
            {data.hasTarget ? (
              <svg
                className="direction-arrow"
                viewBox="0 0 64 64"
                style={{ transform: `rotate(${arrowRotation}deg)` }}
              >
                <polygon
                  points="32,6 48,52 32,42 16,52"
                  fill="currentColor"
                />
              </svg>
            ) : (
              <div className="no-signal-icon">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <line x1="3" y1="3" x2="21" y2="21" />
                  <path d="M8.1 8.1C5.5 9.5 3.5 11.5 2 14" />
                  <path d="M5.1 5.1C3.1 6.5 1.5 8.5 0.5 11" />
                </svg>
              </div>
            )}
          </div>

          {/* Signal info */}
          <div className="signal-info">
            <div className="info-row">
              <span className="info-label">Jel:</span>
              <span className={`info-value ${data.hasTarget ? 'active' : ''}`}>
                {data.hasTarget ? `${strengthPercent}%` : 'Nincs'}
              </span>
            </div>
            <div className="info-row">
              <span className="info-label">Tav:</span>
              <span className="info-value">{distanceDisplay}</span>
            </div>

            {/* Signal strength bar */}
            <div className="strength-bar-container">
              <div
                className={`strength-bar ${data.strength > 0.75 ? 'hot' : data.strength > 0.4 ? 'warm' : 'cold'}`}
                style={{ width: `${strengthPercent}%` }}
              />
            </div>
          </div>
        </div>
      </div>

      {/* Footer with area + dig button */}
      <div className="panel-footer">
        <div className="footer-area">
          <span className="area-pin">&#9830;</span>
          <span className="area-name">{data.area || 'Ismeretlen'}</span>
        </div>

        {data.canDig && (
          <button className="dig-btn" onClick={onDig} title="Ásás megkezdése">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M14 10l-1.5 1.5a2 2 0 0 0 0 2.83l.17.17a2 2 0 0 0 2.83 0L17 13" />
              <path d="M6 20l4-4" />
              <path d="M17 5l2 2" />
              <path d="M11 11L5 5" />
              <path d="M17.5 6.5L20 4" />
              <path d="M7.5 17.5L4 21" />
            </svg>
            <span>ss</span>
          </button>
        )}
      </div>
    </div>
  )
}
