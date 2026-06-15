import React, { useState, useEffect, useCallback, useRef } from 'react'
import DetectorPanel from './components/DetectorPanel'

if (!window.GetParentResourceName) {
  window.GetParentResourceName = () => 'realrpg_detector'
}

export default function App() {
  const [visible, setVisible] = useState(false)
  const [iconsOnlyVisible, setIconsOnlyVisible] = useState(false)
  const [cursorActive, setCursorActive] = useState(false)
  const [radarData, setRadarData] = useState({
    hasTarget: false, distance: 0, maxDistance: 85, angle: 0, strength: 0,
    area: '', coordX: 0, coordY: 0, canDig: false, pointId: null
  })
  // World icons updated every frame (raw positions from Lua)
  const [worldIcons, setWorldIcons] = useState([])

  const handleMessage = useCallback((event) => {
    const data = event.data || {}
    switch (data.action) {
      case 'show': setVisible(true); setIconsOnlyVisible(false); break
      case 'hide': setVisible(false); setIconsOnlyVisible(false); setWorldIcons([]); break
      case 'cursorState': setCursorActive(!!data.active); break
      case 'radar': setRadarData({
        hasTarget: data.hasTarget || false, distance: data.distance || 0,
        maxDistance: data.maxDistance || 85, angle: data.angle || 0,
        strength: data.strength || 0, area: data.area || '',
        coordX: data.coordX || 0, coordY: data.coordY || 0,
        canDig: data.canDig || false, pointId: data.pointId || null
      }); break
      case 'worldIcons': setWorldIcons(data.icons || []); break
      case 'showIconsOnly': setIconsOnlyVisible(true); break
      case 'hideIconsOnly': setIconsOnlyVisible(false); setWorldIcons([]); break
      default: break
    }
  }, [])

  useEffect(() => {
    window.addEventListener('message', handleMessage)
    return () => window.removeEventListener('message', handleMessage)
  }, [handleMessage])

  useEffect(() => {
    const handleKey = (e) => {
      if (e.key === 'Escape' && cursorActive) {
        fetch(`https://${window.GetParentResourceName()}/closeCursor`, {
          method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}'
        })
        setCursorActive(false)
      }
    }
    window.addEventListener('keydown', handleKey)
    return () => window.removeEventListener('keydown', handleKey)
  }, [cursorActive])

  const handleDigClick = useCallback((pointId) => {
    fetch(`https://${window.GetParentResourceName()}/nuiDigRequest`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ pointId })
    })
  }, [])

  const handleCrateClick = useCallback((crateId) => {
    fetch(`https://${window.GetParentResourceName()}/nuiCratePickup`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ crateId })
    })
  }, [])

  const showIcons = (visible || iconsOnlyVisible) && worldIcons.length > 0

  if (!visible && !showIcons) return null

  return (
    <div className={`app-root ${cursorActive ? 'cursor-active' : 'cursor-inactive'}`}>
      {visible && <DetectorPanel data={radarData} />}
      {showIcons && (
        <div className="world-icons-layer">
          {worldIcons.map((icon) => {
            if (icon.type === 'dig') {
              return (
                <div
                  key={`dig-${icon.id}`}
                  className={`world-icon dig-icon ${cursorActive ? 'clickable' : ''}`}
                  style={{ left: `${icon.x * 100}%`, top: `${icon.y * 100}%` }}
                  onClick={cursorActive ? () => handleDigClick(icon.id) : undefined}
                >
                  <div className="icon-box">
                    <svg viewBox="0 0 24 24" fill="currentColor">
                      <path d="M15.1 1.81l-2.83 2.83c-.77.78-.77 2.05 0 2.83l1.41 1.41-8.49 8.49-2.83-2.83-1.41 1.41 8.49 8.49 1.41-1.41-2.83-2.83 8.49-8.49 1.41 1.41c.78.78 2.05.78 2.83 0l2.83-2.83L15.1 1.81z"/>
                    </svg>
                  </div>
                </div>
              )
            } else if (icon.type === 'crate') {
              return (
                <div
                  key={`crate-${icon.id}`}
                  className={`world-icon crate-icon ${icon.canPickup ? 'pickup' : ''} ${cursorActive ? 'clickable' : ''}`}
                  style={{ left: `${icon.x * 100}%`, top: `${icon.y * 100}%` }}
                  onClick={cursorActive && icon.canPickup ? () => handleCrateClick(icon.id) : undefined}
                >
                  <div className="icon-box">
                    <svg viewBox="0 0 24 24" fill="currentColor">
                      <path d="M21 16.5c0 .38-.21.71-.53.88l-7.9 4.44c-.16.12-.36.18-.57.18-.21 0-.41-.06-.57-.18l-7.9-4.44A.991.991 0 0 1 3 16.5v-9c0-.38.21-.71.53-.88l7.9-4.44c.16-.12.36-.18.57-.18.21 0 .41.06.57.18l7.9 4.44c.32.17.53.5.53.88v9zM12 4.15L6.04 7.5 12 10.85l5.96-3.35L12 4.15zM5 15.91l6 3.38v-6.71L5 9.21v6.7zm14 0v-6.7l-6 3.37v6.71l6-3.38z"/>
                    </svg>
                  </div>
                </div>
              )
            }
            return null
          })}
        </div>
      )}
    </div>
  )
}
