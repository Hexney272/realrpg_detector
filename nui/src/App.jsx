import React, { useState, useEffect, useCallback } from 'react'
import DetectorPanel from './components/DetectorPanel'
import WorldIcons from './components/WorldIcons'

export default function App() {
  const [visible, setVisible] = useState(false)
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
  const [worldIcons, setWorldIcons] = useState([])

  const handleMessage = useCallback((event) => {
    const data = event.data || {}

    switch (data.action) {
      case 'show':
        setVisible(true)
        break
      case 'hide':
        setVisible(false)
        setWorldIcons([])
        break
      case 'radar':
        setRadarData(prev => ({
          ...prev,
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
        }))
        break
      case 'worldIcons':
        setWorldIcons(data.icons || [])
        break
      default:
        break
    }
  }, [])

  useEffect(() => {
    window.addEventListener('message', handleMessage)
    return () => window.removeEventListener('message', handleMessage)
  }, [handleMessage])

  const handleDig = useCallback(() => {
    // Send NUI callback to client.lua
    fetch(`https://${GetParentResourceName()}/nuiDigRequest`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ pointId: radarData.pointId })
    })
  }, [radarData.pointId])

  if (!visible) return null

  return (
    <>
      <DetectorPanel data={radarData} onDig={handleDig} />
      <WorldIcons icons={worldIcons} />
    </>
  )
}

// Helper for FiveM NUI resource name
if (!window.GetParentResourceName) {
  window.GetParentResourceName = () => 'realrpg_detector'
}
