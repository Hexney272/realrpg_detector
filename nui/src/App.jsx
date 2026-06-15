import React, { useState, useEffect, useCallback } from 'react'
import DetectorPanel from './components/DetectorPanel'
import DigIcons from './components/DigIcons'
import CrateIcons from './components/CrateIcons'

// FiveM NUI resource name helper
if (!window.GetParentResourceName) {
  window.GetParentResourceName = () => 'realrpg_detector'
}

export default function App() {
  const [visible, setVisible] = useState(false)
  const [cratesOnlyVisible, setCratesOnlyVisible] = useState(false)
  const [cursorActive, setCursorActive] = useState(false)
  const [radarData, setRadarData] = useState({
    hasTarget: false,
    distance: 0,
    maxDistance: 85,
    angle: 0,
    strength: 0,
    area: '',
    coordX: 0,
    coordY: 0,
    canDig: false,
    pointId: null
  })
  const [digIcons, setDigIcons] = useState([])
  const [crateIcons, setCrateIcons] = useState([])

  const handleMessage = useCallback((event) => {
    const data = event.data || {}

    switch (data.action) {
      case 'show':
        setVisible(true)
        setCratesOnlyVisible(false)
        break
      case 'hide':
        setVisible(false)
        setCratesOnlyVisible(false)
        setDigIcons([])
        setCrateIcons([])
        break
      case 'cursorState':
        setCursorActive(!!data.active)
        break
      case 'radar':
        setRadarData({
          hasTarget: data.hasTarget || false,
          distance: data.distance || 0,
          maxDistance: data.maxDistance || 85,
          angle: data.angle || 0,
          strength: data.strength || 0,
          area: data.area || '',
          coordX: data.coordX || 0,
          coordY: data.coordY || 0,
          canDig: data.canDig || false,
          pointId: data.pointId || null
        })
        break
      case 'digIcons':
        setDigIcons(data.icons || [])
        break
      case 'crateIcons':
        setCrateIcons(data.icons || [])
        break
      case 'showCratesOnly':
        setCratesOnlyVisible(true)
        break
      case 'hideCratesOnly':
        setCratesOnlyVisible(false)
        setCrateIcons([])
        break
      default:
        break
    }
  }, [])

  useEffect(() => {
    window.addEventListener('message', handleMessage)
    return () => window.removeEventListener('message', handleMessage)
  }, [handleMessage])

  // Escape key closes cursor
  useEffect(() => {
    const handleKey = (e) => {
      if (e.key === 'Escape' && cursorActive) {
        fetch(`https://${window.GetParentResourceName()}/closeCursor`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({})
        })
        setCursorActive(false)
      }
    }
    window.addEventListener('keydown', handleKey)
    return () => window.removeEventListener('keydown', handleKey)
  }, [cursorActive])

  const handleDigClick = useCallback((pointId) => {
    fetch(`https://${window.GetParentResourceName()}/nuiDigRequest`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ pointId })
    })
  }, [])

  const handleCrateClick = useCallback((crateId) => {
    fetch(`https://${window.GetParentResourceName()}/nuiCratePickup`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ crateId })
    })
  }, [])

  // Show crate icons even when detector panel is hidden (cratesOnlyVisible)
  const showCrates = (visible || cratesOnlyVisible) && crateIcons.length > 0

  if (!visible && !showCrates) return null

  return (
    <div className={`app-root ${cursorActive ? 'cursor-active' : 'cursor-inactive'}`}>
      {visible && <DetectorPanel data={radarData} />}
      {visible && <DigIcons icons={digIcons} cursorActive={cursorActive} onClick={handleDigClick} />}
      {showCrates && <CrateIcons icons={crateIcons} cursorActive={cursorActive} onClick={handleCrateClick} />}
    </div>
  )
}
