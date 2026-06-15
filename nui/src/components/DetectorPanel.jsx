import React, { useState, useRef, useCallback, useEffect } from 'react'

export default function DetectorPanel({ data }) {
  const [position, setPosition] = useState({ x: window.innerWidth - 380, y: window.innerHeight / 2 - 200 })
  const [dragging, setDragging] = useState(false)
  const dragOffset = useRef({ x: 0, y: 0 })
  const panelRef = useRef(null)

  // Dragging logic
  const handleMouseDown = useCallback((e) => {
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

  // Precise coordinate formatting
  const formatCoord = (value) => {
    const v = Math.round(value * 10) / 10
    return v.toFixed(1)
  }

  const strengthPercent = Math.round(data.strength * 100)
  const distanceDisplay = data.hasTarget ? `${data.distance.toFixed(1)}m` : '---'

  // Arrow rotation: precise angle relative to player heading
  const arrowRotation = data.hasTarget ? data.angle : 0

  // Radar dot position (precise from center, based on angle and distance ratio)
  const radarRadius = 42
  const distRatio = data.hasTarget ? Math.min(data.distance / data.maxDistance, 1) : 0
  const angleRad = (data.angle * Math.PI) / 180
  const dotX = 50 + Math.sin(angleRad) * (distRatio * radarRadius)
  const dotY = 50 - Math.cos(angleRad) * (distRatio * radarRadius)
  const dotSize = 8 + data.strength * 14

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
        <div className="header-hint">
          <span className="hint-key">M</span>
          <span className="hint-text">kurzor</span>
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

        {/* Direction arrow + info */}
        <div className="direction-section">
          <div className="direction-arrow-container">
            {data.hasTarget ? (
              <svg
                className="direction-arrow"
                viewBox="0 0 64 64"
                style={{ transform: `rotate(${arrowRotation}deg)` }}
              >
                <polygon
                  points="32,4 50,54 32,44 14,54"
                  fill="currentColor"
                />
              </svg>
            ) : (
              <div className="no-signal-icon">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
                  <line x1="4" y1="4" x2="20" y2="20" />
                  <path d="M12 2a10 10 0 0 1 0 20" strokeDasharray="4 3" />
                </svg>
              </div>
            )}
          </div>

          {/* Signal info */}
          <div className="signal-info">
            <div className="info-row">
              <span className="info-label">Jel</span>
              <span className={`info-value ${data.hasTarget ? (data.strength > 0.7 ? 'hot' : 'active') : ''}`}>
                {data.hasTarget ? `${strengthPercent}%` : '---'}
              </span>
            </div>
            <div className="info-row">
              <span className="info-label">Táv</span>
              <span className="info-value">{distanceDisplay}</span>
            </div>

            {/* Signal strength bar */}
            <div className="strength-bar-container">
              <div
                className={`strength-bar ${data.strength > 0.75 ? 'hot' : data.strength > 0.4 ? 'warm' : 'cold'}`}
                style={{ width: `${strengthPercent}%` }}
              />
            </div>

            {/* Coordinates */}
            <div className="coords-row">
              <span className="coord-val">X: {formatCoord(data.coordX)}</span>
              <span className="coord-val">Y: {formatCoord(data.coordY)}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Footer: area name */}
      <div className="panel-footer">
        <div className="footer-area">
          <span className="area-pin">&#9830;</span>
          <span className="area-name">{data.area || 'Keresés...'}</span>
        </div>
        <div className="footer-status">
          {data.hasTarget ? (
            <span className="status-active">● Jelzés</span>
          ) : (
            <span className="status-idle">○ Nincs jel</span>
          )}
        </div>
      </div>
    </div>
  )
}
