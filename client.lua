local ESX = nil
local detectorActive = false
local detectorObject = nil
local shovelObject = nil
local knownPoints = {}
local localCrates = {}
local pendingDigPoint = nil
local isDigging = false
local lastBeep = 0
local lastNuiUpdate = 0
local nuiCursorActive = false
local closestDiggablePoint = nil

local function dbg(msg)
    if Config.Debug then
        print(('[realrpg_detector/client] %s'):format(msg))
    end
end

local function getESX()
    if ESX then return ESX end
    if exports and exports['es_extended'] and exports['es_extended'].getSharedObject then
        ESX = exports['es_extended']:getSharedObject()
    else
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    end
    return ESX
end

local function notify(msg, nType)
    if GetResourceState('ox_lib') == 'started' then
        local ok = pcall(function()
            exports.ox_lib:notify({ title = 'Detektor', description = msg, type = nType or 'inform' })
        end)
        if ok then return end
    end
    local esx = getESX()
    if esx and esx.ShowNotification then esx.ShowNotification(msg) return end
    TriggerEvent('chat:addMessage', { color = { 230, 190, 60 }, args = { 'Detektor', msg } })
end

RegisterNetEvent('realrpg_detector:client:notify', function(msg, nType) notify(msg, nType) end)

-- ═══════════════════════════════════════════
-- MODEL HELPERS
-- ═══════════════════════════════════════════
local function loadModel(modelName, timeoutMs)
    timeoutMs = timeoutMs or 3500
    if not modelName or modelName == '' then return nil end
    local model = joaat(modelName)
    if not IsModelInCdimage(model) then return nil end
    RequestModel(model)
    local s = GetGameTimer()
    while not HasModelLoaded(model) do Wait(10); if GetGameTimer() - s > timeoutMs then return nil end end
    return model, modelName
end

local function loadFirstModel(modelList, fallbackModel)
    if type(modelList) == 'table' then
        for _, mn in ipairs(modelList) do local m, n = loadModel(mn); if m then return m, n end end
    elseif type(modelList) == 'string' then
        local m, n = loadModel(modelList); if m then return m, n end
    end
    if fallbackModel then return loadModel(fallbackModel) end
    return nil, nil
end

local function deleteEntitySafe(entity)
    if entity and DoesEntityExist(entity) then SetEntityAsMissionEntity(entity, true, true); DeleteEntity(entity) end
end

-- ═══════════════════════════════════════════
-- DETECTOR / SHOVEL ATTACH
-- ═══════════════════════════════════════════
local function attachDetector()
    local ped = PlayerPedId()
    SetCurrentPedWeapon(ped, joaat('WEAPON_UNARMED'), true)
    local model = loadFirstModel(Config.Models.detector, Config.Models.detectorFallback)
    if not model then notify('A detektor modell nem tölthető be.', 'error') return end
    deleteEntitySafe(detectorObject)
    local coords = GetEntityCoords(ped)
    detectorObject = CreateObject(model, coords.x, coords.y, coords.z + 0.2, true, true, false)
    local a = Config.Attachments.detector or {}
    AttachEntityToEntity(detectorObject, ped, GetPedBoneIndex(ped, a.bone or 57005),
        a.x or 0.16, a.y or 0.03, a.z or -0.05, a.rx or -95.0, a.ry or 0.0, a.rz or 18.0,
        true, true, false, true, 1, true)
    if Config.ItemUse.playDetectorIdleAnim then
        RequestAnimDict('amb@world_human_stand_mobile@male@text@base')
        local s2 = GetGameTimer()
        while not HasAnimDictLoaded('amb@world_human_stand_mobile@male@text@base') and GetGameTimer() - s2 < 1000 do Wait(10) end
        if HasAnimDictLoaded('amb@world_human_stand_mobile@male@text@base') then
            TaskPlayAnim(ped, 'amb@world_human_stand_mobile@male@text@base', 'base', 2.0, 2.0, -1, 49, 0.0, false, false, false)
        end
    end
    SetModelAsNoLongerNeeded(model)
end

local function attachShovel()
    local ped = PlayerPedId()
    SetCurrentPedWeapon(ped, joaat('WEAPON_UNARMED'), true)
    local model = loadFirstModel(Config.Models.shovel, nil)
    if not model then return end
    deleteEntitySafe(shovelObject)
    local coords = GetEntityCoords(ped)
    shovelObject = CreateObject(model, coords.x, coords.y, coords.z + 0.2, true, true, false)
    local a = Config.Attachments.shovel or {}
    AttachEntityToEntity(shovelObject, ped, GetPedBoneIndex(ped, a.bone or 57005),
        a.x or 0.12, a.y or -0.03, a.z or -0.04, a.rx or -100.0, a.ry or 10.0, a.rz or 15.0,
        true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(model)
end

-- ═══════════════════════════════════════════
-- NUI VISIBILITY
-- ═══════════════════════════════════════════
local function showNuiPanel() SendNUIMessage({ action = 'show' }) end
local function hideNuiPanel()
    SendNUIMessage({ action = 'hide' })
    if nuiCursorActive then nuiCursorActive = false; SetNuiFocus(false, false) end
end

local function toggleNuiCursor()
    nuiCursorActive = not nuiCursorActive
    SetNuiFocus(nuiCursorActive, nuiCursorActive)
    SetNuiFocusKeepInput(nuiCursorActive)
    SendNUIMessage({ action = 'cursorState', active = nuiCursorActive })
end

RegisterCommand('+detectorCursor', function()
    if (detectorActive or next(localCrates)) and not isDigging then toggleNuiCursor() end
end)
RegisterCommand('-detectorCursor', function() end)
RegisterKeyMapping('+detectorCursor', 'Detektor kurzor (mozgatás/kattintás)', 'keyboard', 'M')

-- ═══════════════════════════════════════════
-- SHOVEL ITEM
-- ═══════════════════════════════════════════
local shovelPreviewActive = false
RegisterNetEvent('realrpg_detector:client:useShovelItem', function()
    if Config.ItemUse.shovelCanBeEquipped then
        if isDigging then return end
        shovelPreviewActive = not shovelPreviewActive
        local ped = PlayerPedId()
        if shovelPreviewActive then
            attachShovel()
        else
            deleteEntitySafe(shovelObject); shovelObject = nil; ClearPedSecondaryTask(ped)
        end
    else
        notify('Az ásó a detektoros ásásnál lesz használva.', 'info')
    end
end)

-- ═══════════════════════════════════════════
-- POINTS SYNC
-- ═══════════════════════════════════════════
local function toVec3(coords) return vector3(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0) end

local function addKnownPoint(point)
    if not point or not point.id or not point.coords then return end
    knownPoints[tonumber(point.id)] = {
        id = tonumber(point.id), coords = toVec3(point.coords),
        zoneId = point.zoneId, zoneLabel = point.zoneLabel, areaName = point.areaName,
        tier = point.tier,
        scanRange = point.scanRange or Config.Detector.scanRange,
        iconRenderDistance = point.iconRenderDistance or Config.Detector.iconRenderDistance
    }
end

RegisterNetEvent('realrpg_detector:client:syncPoints', function(points)
    knownPoints = {}
    for _, p in ipairs(points or {}) do addKnownPoint(p) end
end)
RegisterNetEvent('realrpg_detector:client:addPoint', function(p) addKnownPoint(p) end)
RegisterNetEvent('realrpg_detector:client:removePoint', function(id) knownPoints[tonumber(id)] = nil end)

-- ═══════════════════════════════════════════
-- NAVIGATION
-- ═══════════════════════════════════════════
local function getNearestPoint(playerCoords)
    local nearest, nearestDist = nil, 999999.0
    for _, point in pairs(knownPoints) do
        local dist = #(playerCoords - point.coords)
        if dist <= (point.scanRange or Config.Detector.scanRange) and dist < nearestDist then
            nearestDist = dist; nearest = point
        end
    end
    return nearest, nearestDist
end

local function headingToPoint(from, to)
    local h = math.deg(math.atan(to.x - from.x, to.y - from.y))
    if h < 0 then h = h + 360 end
    return h
end

local function normalizeAngle(a)
    while a > 180 do a = a - 360 end
    while a < -180 do a = a + 360 end
    return a
end

-- ═══════════════════════════════════════════
-- DIG PROGRESS
-- ═══════════════════════════════════════════
local function draw2DText(x, y, text, scale)
    SetTextFont(4); SetTextScale(scale, scale); SetTextColour(255,255,255,230)
    SetTextDropshadow(1,0,0,0,180); SetTextCentre(true)
    BeginTextCommandDisplayText('STRING'); AddTextComponentSubstringPlayerName(text); EndTextCommandDisplayText(x,y)
end

local function progressDig(durationMs, label)
    local ped = PlayerPedId()
    local start = GetGameTimer()
    local finish = start + durationMs
    local cancelled = false

    if shovelPreviewActive then shovelPreviewActive = false; deleteEntitySafe(shovelObject); shovelObject = nil; ClearPedSecondaryTask(ped) end
    attachShovel()
    FreezeEntityPosition(ped, true)
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_GARDENER_PLANT', 0, true)

    while GetGameTimer() < finish do
        Wait(0)
        for _, c in ipairs({21,22,23,24,25,30,31,32,33,34,35}) do DisableControlAction(0, c, true) end
        if IsControlJustPressed(0, Config.Controls.cancel) then cancelled = true; break end
        local p = (GetGameTimer() - start) / durationMs
        DrawRect(0.5, 0.86, 0.22, 0.024, 8,10,10,175)
        DrawRect(0.5 - (0.22/2) + (0.22*p/2), 0.86, 0.22*p, 0.024, 226,190,60,225)
        draw2DText(0.5, 0.825, label, 0.33)
        draw2DText(0.5, 0.895, 'Megszakítás: X', 0.26)
    end

    ClearPedTasksImmediately(ped); FreezeEntityPosition(ped, false)
    deleteEntitySafe(shovelObject); shovelObject = nil
    return not cancelled
end

-- ═══════════════════════════════════════════
-- DETECTOR TOGGLE
-- ═══════════════════════════════════════════
local function toggleDetector(forceState)
    if isDigging then return end
    if forceState ~= nil then detectorActive = forceState else detectorActive = not detectorActive end

    if detectorActive then
        if shovelPreviewActive then shovelPreviewActive = false; deleteEntitySafe(shovelObject); shovelObject = nil; ClearPedSecondaryTask(PlayerPedId()) end
        TriggerServerEvent('realrpg_detector:server:requestPoints')
        attachDetector()
        showNuiPanel()
        notify(Config.Text.detectorOn, 'success')
    else
        hideNuiPanel()
        deleteEntitySafe(detectorObject); detectorObject = nil
        ClearPedSecondaryTask(PlayerPedId())
        closestDiggablePoint = nil
        notify(Config.Text.detectorOff, 'info')
    end
end

RegisterNetEvent('realrpg_detector:client:toggleDetector', function(forceState, fromServer)
    if Config.ItemUse.requireDetectorItemForToggle and not fromServer then
        TriggerServerEvent('realrpg_detector:server:useDetectorItem'); return
    end
    toggleDetector(forceState)
end)

RegisterNetEvent('realrpg_detector:client:useDetectorItem', function()
    TriggerServerEvent('realrpg_detector:server:useDetectorItem')
end)

if Config.Commands.testToggle then
    RegisterCommand(Config.Commands.testToggleName, function()
        if Config.ItemUse.requireDetectorItemForToggle then TriggerServerEvent('realrpg_detector:server:useDetectorItem')
        else toggleDetector() end
    end, false)
end

-- ═══════════════════════════════════════════
-- NUI CALLBACKS
-- ═══════════════════════════════════════════
RegisterNUICallback('nuiDigRequest', function(data, cb)
    cb('ok')
    if isDigging or not detectorActive then return end
    local pointId = tonumber(data.pointId)
    if not pointId and closestDiggablePoint then pointId = closestDiggablePoint.id end
    if not pointId then return end
    local point = knownPoints[pointId]
    if not point then return end
    local dist = #(GetEntityCoords(PlayerPedId()) - point.coords)
    if dist <= Config.Detector.digDistance then startDig(point) else notify(Config.Text.tooFar, 'error') end
end)

RegisterNUICallback('nuiCratePickup', function(data, cb)
    cb('ok')
    if isDigging then return end
    local crateId = data.crateId
    if not crateId or not localCrates[crateId] then return end
    local dist = #(GetEntityCoords(PlayerPedId()) - localCrates[crateId].coords)
    if dist <= Config.Detector.pickupDistance then
        TriggerServerEvent('realrpg_detector:server:pickupCrate', crateId)
    else notify(Config.Text.tooFar, 'error') end
end)

RegisterNUICallback('closeCursor', function(data, cb)
    cb('ok')
    if nuiCursorActive then nuiCursorActive = false; SetNuiFocus(false, false); SendNUIMessage({ action = 'cursorState', active = false }) end
end)

-- ═══════════════════════════════════════════
-- DIG LOGIC
-- ═══════════════════════════════════════════
function startDig(point)
    if isDigging or not point then return end
    pendingDigPoint = point.id
    TriggerServerEvent('realrpg_detector:server:beginDig', point.id)
end

RegisterNetEvent('realrpg_detector:client:beginDigAllowed', function(pointId)
    pointId = tonumber(pointId)
    if pendingDigPoint ~= pointId then return end
    isDigging = true; closestDiggablePoint = nil
    if nuiCursorActive then nuiCursorActive = false; SetNuiFocus(false, false) end
    SendNUIMessage({ action = 'hide' })
    deleteEntitySafe(detectorObject); detectorObject = nil

    local success = progressDig(Config.Detector.digTimeMs, Config.Text.digging)
    isDigging = false
    if detectorActive then attachDetector(); showNuiPanel() end
    if success then TriggerServerEvent('realrpg_detector:server:finishDig', pointId)
    else notify(Config.Text.cancelled, 'error'); TriggerServerEvent('realrpg_detector:server:cancelDig', pointId) end
    pendingDigPoint = nil
end)

-- ═══════════════════════════════════════════
-- CRATES
-- ═══════════════════════════════════════════
local function spawnCrate(crateData)
    local coords = toVec3(crateData.coords)
    local gf, gz = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 15.0, false)
    if gf then coords = vector3(coords.x, coords.y, gz + 0.02) end
    local model = loadModel(Config.Models.crate)
    local obj = nil
    if model then
        obj = CreateObject(model, coords.x, coords.y, coords.z, true, true, false)
        PlaceObjectOnGroundProperly(obj); FreezeEntityPosition(obj, true); SetEntityAsMissionEntity(obj, true, true)
        SetModelAsNoLongerNeeded(model)
        if crateData.style == 'green' then SetEntityDrawOutlineColor(80,160,80,255); SetEntityDrawOutline(obj, true)
        elseif crateData.style == 'blue' then SetEntityDrawOutlineColor(80,140,230,255); SetEntityDrawOutline(obj, true)
        elseif crateData.style == 'rare' or crateData.style == 'gold' then SetEntityDrawOutlineColor(226,190,60,255); SetEntityDrawOutline(obj, true) end
    end
    localCrates[crateData.id] = {
        id = crateData.id, pointId = crateData.pointId, coords = coords, object = obj,
        label = crateData.label or 'Láda', weight = crateData.weight or 3000,
        style = crateData.style or 'white', tier = crateData.tier,
        zoneLabel = crateData.zoneLabel, areaName = crateData.areaName
    }
end

RegisterNetEvent('realrpg_detector:client:spawnCrate', function(d) spawnCrate(d) end)
RegisterNetEvent('realrpg_detector:client:removeCrate', function(id)
    local c = localCrates[id]; if c then deleteEntitySafe(c.object); localCrates[id] = nil end
end)
RegisterNetEvent('realrpg_detector:client:clearCrates', function()
    for _, c in pairs(localCrates) do deleteEntitySafe(c.object) end; localCrates = {}
end)

-- ═══════════════════════════════════════════
-- MAIN LOOP: radar data + world icon positions (EVERY FRAME for smooth icons)
-- The dig icon ONLY appears within digDistance (realistic)
-- ═══════════════════════════════════════════
CreateThread(function()
    getESX()

    while true do
        local sleep = 1000

        if detectorActive and not isDigging then
            sleep = 0
            local ped = PlayerPedId()
            local pCoords = GetEntityCoords(ped)
            local playerHeading = GetEntityHeading(ped)
            local nearest, distance = getNearestPoint(pCoords)
            local now = GetGameTimer()

            -- World icons: compute screen positions EVERY FRAME (no stutter)
            local icons = {}

            -- Dig points: only show if within digDistance
            for _, point in pairs(knownPoints) do
                local dist = #(pCoords - point.coords)
                if dist <= Config.Detector.digDistance then
                    local onScreen, sx, sy = World3dToScreen2d(point.coords.x, point.coords.y, point.coords.z + 0.6)
                    if onScreen then
                        icons[#icons + 1] = {
                            type = 'dig',
                            id = point.id,
                            x = sx,
                            y = sy,
                            dist = dist
                        }
                    end
                end
            end

            -- Crate icons: always show when nearby
            for crateId, crate in pairs(localCrates) do
                local dist = #(pCoords - crate.coords)
                if dist < 20.0 then
                    local onScreen, sx, sy = World3dToScreen2d(crate.coords.x, crate.coords.y, crate.coords.z + 0.7)
                    if onScreen then
                        icons[#icons + 1] = {
                            type = 'crate',
                            id = crateId,
                            x = sx,
                            y = sy,
                            dist = dist,
                            canPickup = dist <= Config.Detector.pickupDistance,
                            label = crate.label
                        }
                    end
                end
            end

            -- Send icon positions every frame for smooth tracking
            SendNUIMessage({ action = 'worldIcons', icons = icons })

            -- Radar data: send less often (every 50ms)
            if nearest then
                local scanRange = nearest.scanRange or Config.Detector.scanRange
                local targetHeading = headingToPoint(pCoords, nearest.coords)
                local relativeAngle = normalizeAngle(targetHeading - playerHeading)
                local strength = 1.0 - math.min(distance / scanRange, 1.0)
                local canDig = distance <= Config.Detector.digDistance

                if canDig then closestDiggablePoint = nearest else closestDiggablePoint = nil end

                if now - lastNuiUpdate > 50 then
                    SendNUIMessage({
                        action = 'radar',
                        hasTarget = true, distance = distance, maxDistance = scanRange,
                        angle = relativeAngle, strength = strength,
                        area = nearest.areaName or nearest.zoneLabel or Config.Detector.areaName,
                        coordX = pCoords.x, coordY = pCoords.y,
                        canDig = canDig, pointId = nearest.id
                    })
                    lastNuiUpdate = now
                end

                -- Beep
                if Config.Detector.beepEnabled then
                    local interval = Config.Detector.beepSlowMs - ((Config.Detector.beepSlowMs - Config.Detector.beepFastMs) * strength)
                    if now - lastBeep > interval then
                        PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
                        lastBeep = now
                    end
                end
            else
                closestDiggablePoint = nil
                if now - lastNuiUpdate > 250 then
                    SendNUIMessage({
                        action = 'radar', hasTarget = false,
                        area = Config.Detector.areaName,
                        coordX = pCoords.x, coordY = pCoords.y,
                        canDig = false, pointId = nil
                    })
                    lastNuiUpdate = now
                end
            end
        else
            -- Detector off: still show crate icons if nearby
            if not isDigging and next(localCrates) then
                sleep = 0
                local ped = PlayerPedId()
                local pCoords = GetEntityCoords(ped)
                local icons = {}
                for crateId, crate in pairs(localCrates) do
                    local dist = #(pCoords - crate.coords)
                    if dist < 20.0 then
                        local onScreen, sx, sy = World3dToScreen2d(crate.coords.x, crate.coords.y, crate.coords.z + 0.7)
                        if onScreen then
                            icons[#icons + 1] = {
                                type = 'crate', id = crateId,
                                x = sx, y = sy, dist = dist,
                                canPickup = dist <= Config.Detector.pickupDistance,
                                label = crate.label
                            }
                        end
                    end
                end
                if #icons > 0 then
                    SendNUIMessage({ action = 'worldIcons', icons = icons })
                    SendNUIMessage({ action = 'showIconsOnly' })
                else
                    SendNUIMessage({ action = 'hideIconsOnly' })
                end
            else
                closestDiggablePoint = nil
            end
        end

        Wait(sleep)
    end
end)

-- ═══════════════════════════════════════════
-- CLEANUP
-- ═══════════════════════════════════════════
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false); SendNUIMessage({ action = 'hide' })
    deleteEntitySafe(detectorObject); deleteEntitySafe(shovelObject)
    for _, c in pairs(localCrates) do deleteEntitySafe(c.object) end
end)
