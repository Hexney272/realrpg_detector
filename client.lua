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
            exports.ox_lib:notify({
                title = 'Detektor',
                description = msg,
                type = nType or 'inform'
            })
        end)
        if ok then return end
    end

    local esx = getESX()
    if esx and esx.ShowNotification then
        esx.ShowNotification(msg)
        return
    end

    TriggerEvent('chat:addMessage', {
        color = { 230, 190, 60 },
        args = { 'Detektor', msg }
    })
end

RegisterNetEvent('realrpg_detector:client:notify', function(msg, nType)
    notify(msg, nType)
end)

-- ═══════════════════════════════════════════
-- MODEL HELPERS
-- ═══════════════════════════════════════════
local function loadModel(modelName, timeoutMs)
    timeoutMs = timeoutMs or 3500
    if not modelName or modelName == '' then return nil end

    local model = joaat(modelName)
    if not IsModelInCdimage(model) then return nil end

    RequestModel(model)
    local start = GetGameTimer()
    while not HasModelLoaded(model) do
        Wait(10)
        if GetGameTimer() - start > timeoutMs then return nil end
    end

    return model, modelName
end

local function loadFirstModel(modelList, fallbackModel)
    if type(modelList) == 'table' then
        for _, modelName in ipairs(modelList) do
            local model, loadedName = loadModel(modelName)
            if model then return model, loadedName end
        end
    elseif type(modelList) == 'string' then
        local model, loadedName = loadModel(modelList)
        if model then return model, loadedName end
    end

    if fallbackModel then return loadModel(fallbackModel) end
    return nil, nil
end

local function deleteEntitySafe(entity)
    if entity and DoesEntityExist(entity) then
        SetEntityAsMissionEntity(entity, true, true)
        DeleteEntity(entity)
    end
end

-- ═══════════════════════════════════════════
-- DETECTOR ATTACH/DETACH
-- ═══════════════════════════════════════════
local function attachDetector()
    local ped = PlayerPedId()
    SetCurrentPedWeapon(ped, joaat('WEAPON_UNARMED'), true)

    local model, loadedName = loadFirstModel(Config.Models.detector, Config.Models.detectorFallback)
    if not model then
        dbg('Detector model could not be loaded.')
        notify('A detektor modell nem tölthető be.', 'error')
        return
    end

    deleteEntitySafe(detectorObject)

    local coords = GetEntityCoords(ped)
    detectorObject = CreateObject(model, coords.x, coords.y, coords.z + 0.2, true, true, false)

    local attach = Config.Attachments.detector or {}
    AttachEntityToEntity(
        detectorObject, ped,
        GetPedBoneIndex(ped, attach.bone or 57005),
        attach.x or 0.16, attach.y or 0.03, attach.z or -0.05,
        attach.rx or -95.0, attach.ry or 0.0, attach.rz or 18.0,
        true, true, false, true, 1, true
    )

    if Config.ItemUse.playDetectorIdleAnim then
        RequestAnimDict('amb@world_human_stand_mobile@male@text@base')
        local start = GetGameTimer()
        while not HasAnimDictLoaded('amb@world_human_stand_mobile@male@text@base') and GetGameTimer() - start < 1000 do Wait(10) end
        if HasAnimDictLoaded('amb@world_human_stand_mobile@male@text@base') then
            TaskPlayAnim(ped, 'amb@world_human_stand_mobile@male@text@base', 'base', 2.0, 2.0, -1, 49, 0.0, false, false, false)
        end
    end

    dbg(('Detector attached: %s'):format(loadedName or 'unknown'))
    SetModelAsNoLongerNeeded(model)
end

local function attachShovel()
    local ped = PlayerPedId()
    SetCurrentPedWeapon(ped, joaat('WEAPON_UNARMED'), true)

    local model, loadedName = loadFirstModel(Config.Models.shovel, nil)
    if not model then
        dbg('Shovel model could not be loaded.')
        return
    end

    deleteEntitySafe(shovelObject)

    local coords = GetEntityCoords(ped)
    shovelObject = CreateObject(model, coords.x, coords.y, coords.z + 0.2, true, true, false)

    local attach = Config.Attachments.shovel or {}
    AttachEntityToEntity(
        shovelObject, ped,
        GetPedBoneIndex(ped, attach.bone or 57005),
        attach.x or 0.12, attach.y or -0.03, attach.z or -0.04,
        attach.rx or -100.0, attach.ry or 10.0, attach.rz or 15.0,
        true, true, false, true, 1, true
    )

    dbg(('Shovel attached: %s'):format(loadedName or 'unknown'))
    SetModelAsNoLongerNeeded(model)
end

-- ═══════════════════════════════════════════
-- NUI VISIBILITY (panel always visible when detector on, cursor toggled by M)
-- ═══════════════════════════════════════════
local function showNuiPanel()
    SendNUIMessage({ action = 'show' })
end

local function hideNuiPanel()
    SendNUIMessage({ action = 'hide' })
    if nuiCursorActive then
        nuiCursorActive = false
        SetNuiFocus(false, false)
    end
end

local function toggleNuiCursor()
    nuiCursorActive = not nuiCursorActive
    SetNuiFocus(nuiCursorActive, nuiCursorActive)
    SetNuiFocusKeepInput(nuiCursorActive)
    SendNUIMessage({ action = 'cursorState', active = nuiCursorActive })
end

-- M key toggles cursor for the NUI panel
RegisterCommand('+detectorCursor', function()
    if detectorActive and not isDigging then
        toggleNuiCursor()
    end
end)
RegisterCommand('-detectorCursor', function() end)
RegisterKeyMapping('+detectorCursor', 'Detektor kurzor (mozgatás/kattintás)', 'keyboard', 'M')

-- ═══════════════════════════════════════════
-- SHOVEL ITEM USE
-- ═══════════════════════════════════════════
local shovelPreviewActive = false
local function setShovelPreview(state)
    if isDigging then return end
    shovelPreviewActive = state
    local ped = PlayerPedId()

    if state then
        attachShovel()
        RequestAnimDict('amb@world_human_gardener_plant@male@idle_a')
        local start = GetGameTimer()
        while not HasAnimDictLoaded('amb@world_human_gardener_plant@male@idle_a') and GetGameTimer() - start < 1000 do Wait(10) end
        if HasAnimDictLoaded('amb@world_human_gardener_plant@male@idle_a') then
            TaskPlayAnim(ped, 'amb@world_human_gardener_plant@male@idle_a', 'idle_a', 2.0, 2.0, -1, 49, 0.0, false, false, false)
        end
    else
        deleteEntitySafe(shovelObject)
        shovelObject = nil
        ClearPedSecondaryTask(ped)
    end
end

RegisterNetEvent('realrpg_detector:client:useShovelItem', function()
    if Config.ItemUse.shovelCanBeEquipped then
        setShovelPreview(not shovelPreviewActive)
    else
        notify('Az ásó a detektoros ásásnál lesz használva.', 'info')
    end
end)

-- ═══════════════════════════════════════════
-- POINTS SYNC
-- ═══════════════════════════════════════════
local function toVec3(coords)
    return vector3(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
end

local function addKnownPoint(point)
    if not point or not point.id or not point.coords then return end
    knownPoints[tonumber(point.id)] = {
        id = tonumber(point.id),
        coords = toVec3(point.coords),
        zoneId = point.zoneId,
        zoneLabel = point.zoneLabel,
        areaName = point.areaName,
        tier = point.tier,
        scanRange = point.scanRange or Config.Detector.scanRange,
        iconRenderDistance = point.iconRenderDistance or Config.Detector.iconRenderDistance
    }
end

RegisterNetEvent('realrpg_detector:client:syncPoints', function(points)
    knownPoints = {}
    for _, point in ipairs(points or {}) do addKnownPoint(point) end
    dbg(('Synced %s points'):format(#(points or {})))
end)

RegisterNetEvent('realrpg_detector:client:addPoint', function(point)
    addKnownPoint(point)
end)

RegisterNetEvent('realrpg_detector:client:removePoint', function(pointId)
    knownPoints[tonumber(pointId)] = nil
end)

-- ═══════════════════════════════════════════
-- NAVIGATION HELPERS
-- ═══════════════════════════════════════════
local function getNearestPoint(playerCoords)
    local nearest = nil
    local nearestDist = 999999.0
    for _, point in pairs(knownPoints) do
        local scanRange = point.scanRange or Config.Detector.scanRange
        local dist = #(playerCoords - point.coords)
        if dist <= scanRange and dist < nearestDist then
            nearestDist = dist
            nearest = point
        end
    end
    return nearest, nearestDist
end

local function headingToPoint(fromCoords, toCoords)
    local dx = toCoords.x - fromCoords.x
    local dy = toCoords.y - fromCoords.y
    local heading = math.deg(math.atan(dx, dy))
    if heading < 0.0 then heading = heading + 360.0 end
    return heading
end

local function normalizeAngle(angle)
    while angle > 180.0 do angle = angle - 360.0 end
    while angle < -180.0 do angle = angle + 360.0 end
    return angle
end

-- ═══════════════════════════════════════════
-- DIG PROGRESS BAR
-- ═══════════════════════════════════════════
local function draw2DText(x, y, text, scale)
    SetTextFont(4)
    SetTextScale(scale or 0.34, scale or 0.34)
    SetTextColour(255, 255, 255, 230)
    SetTextDropshadow(1, 0, 0, 0, 180)
    SetTextCentre(true)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

local function drawProgress(progress, label)
    local x, y = 0.5, 0.86
    local w, h = 0.22, 0.024
    DrawRect(x, y, w, h, 8, 10, 10, 175)
    DrawRect(x - (w / 2) + (w * progress / 2), y, w * progress, h, 226, 190, 60, 225)
    draw2DText(x, y - 0.035, label, 0.33)
    draw2DText(x, y + 0.035, 'Megszakítás: X', 0.26)
end

local function progressDig(durationMs, label)
    local ped = PlayerPedId()
    local start = GetGameTimer()
    local finish = start + durationMs
    local cancelled = false

    if shovelPreviewActive then
        shovelPreviewActive = false
        deleteEntitySafe(shovelObject)
        shovelObject = nil
        ClearPedSecondaryTask(ped)
    end

    attachShovel()
    FreezeEntityPosition(ped, true)
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_GARDENER_PLANT', 0, true)

    while GetGameTimer() < finish do
        Wait(0)
        DisableControlAction(0, 21, true)
        DisableControlAction(0, 22, true)
        DisableControlAction(0, 23, true)
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 30, true)
        DisableControlAction(0, 31, true)
        DisableControlAction(0, 32, true)
        DisableControlAction(0, 33, true)
        DisableControlAction(0, 34, true)
        DisableControlAction(0, 35, true)

        if IsControlJustPressed(0, Config.Controls.cancel) then
            cancelled = true
            break
        end

        local progress = (GetGameTimer() - start) / durationMs
        drawProgress(math.min(progress, 1.0), label)
    end

    ClearPedTasksImmediately(ped)
    FreezeEntityPosition(ped, false)
    deleteEntitySafe(shovelObject)
    shovelObject = nil

    return not cancelled
end

-- ═══════════════════════════════════════════
-- DETECTOR TOGGLE
-- ═══════════════════════════════════════════
local function toggleDetector(forceState)
    if isDigging then return end

    if forceState ~= nil then
        detectorActive = forceState
    else
        detectorActive = not detectorActive
    end

    if detectorActive then
        if shovelPreviewActive then
            shovelPreviewActive = false
            deleteEntitySafe(shovelObject)
            shovelObject = nil
            ClearPedSecondaryTask(PlayerPedId())
        end

        TriggerServerEvent('realrpg_detector:server:requestPoints')
        attachDetector()
        showNuiPanel()
        notify(Config.Text.detectorOn, 'success')
    else
        hideNuiPanel()
        deleteEntitySafe(detectorObject)
        detectorObject = nil
        ClearPedSecondaryTask(PlayerPedId())
        notify(Config.Text.detectorOff, 'info')
    end
end

RegisterNetEvent('realrpg_detector:client:toggleDetector', function(forceState, fromServer)
    if Config.ItemUse.requireDetectorItemForToggle and not fromServer then
        TriggerServerEvent('realrpg_detector:server:useDetectorItem')
        return
    end
    toggleDetector(forceState)
end)

RegisterNetEvent('realrpg_detector:client:useDetectorItem', function()
    TriggerServerEvent('realrpg_detector:server:useDetectorItem')
end)

if Config.Commands.testToggle then
    RegisterCommand(Config.Commands.testToggleName, function()
        if Config.ItemUse.requireDetectorItemForToggle then
            TriggerServerEvent('realrpg_detector:server:useDetectorItem')
        else
            toggleDetector()
        end
    end, false)
end

-- ═══════════════════════════════════════════
-- NUI CALLBACKS
-- ═══════════════════════════════════════════

-- Dig request: player clicks the animated dig icon in the game world via NUI
RegisterNUICallback('nuiDigRequest', function(data, cb)
    cb('ok')
    if isDigging or not detectorActive then return end

    local pointId = tonumber(data.pointId)
    if not pointId then return end

    local point = knownPoints[pointId]
    if not point then return end

    local ped = PlayerPedId()
    local pCoords = GetEntityCoords(ped)
    local dist = #(pCoords - point.coords)

    if dist <= Config.Detector.digDistance then
        startDig(point)
    else
        notify(Config.Text.tooFar, 'error')
    end
end)

-- Crate pickup: player clicks the crate icon in the game world via NUI
RegisterNUICallback('nuiCratePickup', function(data, cb)
    cb('ok')
    if isDigging then return end

    local crateId = data.crateId
    if not crateId or not localCrates[crateId] then return end

    local ped = PlayerPedId()
    local pCoords = GetEntityCoords(ped)
    local crate = localCrates[crateId]
    local dist = #(pCoords - crate.coords)

    if dist <= Config.Detector.pickupDistance then
        TriggerServerEvent('realrpg_detector:server:pickupCrate', crateId)
    else
        notify(Config.Text.tooFar, 'error')
    end
end)

-- Close NUI cursor (Escape in NUI)
RegisterNUICallback('closeCursor', function(data, cb)
    cb('ok')
    if nuiCursorActive then
        nuiCursorActive = false
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'cursorState', active = false })
    end
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

    isDigging = true

    -- Disable NUI cursor during dig
    if nuiCursorActive then
        nuiCursorActive = false
        SetNuiFocus(false, false)
    end
    SendNUIMessage({ action = 'hide' })

    deleteEntitySafe(detectorObject)
    detectorObject = nil

    local success = progressDig(Config.Detector.digTimeMs, Config.Text.digging)
    isDigging = false

    if detectorActive then
        attachDetector()
        showNuiPanel()
    end

    if success then
        TriggerServerEvent('realrpg_detector:server:finishDig', pointId)
    else
        notify(Config.Text.cancelled, 'error')
        TriggerServerEvent('realrpg_detector:server:cancelDig', pointId)
    end

    pendingDigPoint = nil
end)

-- ═══════════════════════════════════════════
-- CRATES
-- ═══════════════════════════════════════════
local function spawnCrate(crateData)
    local coords = toVec3(crateData.coords)
    local groundFound, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 15.0, false)
    if groundFound then coords = vector3(coords.x, coords.y, groundZ + 0.02) end

    local model = loadModel(Config.Models.crate)
    local obj = nil

    if model then
        obj = CreateObject(model, coords.x, coords.y, coords.z, true, true, false)
        PlaceObjectOnGroundProperly(obj)
        FreezeEntityPosition(obj, true)
        SetEntityAsMissionEntity(obj, true, true)
        SetModelAsNoLongerNeeded(model)

        if crateData.style == 'green' then
            SetEntityDrawOutlineColor(80, 160, 80, 255)
            SetEntityDrawOutline(obj, true)
        elseif crateData.style == 'blue' then
            SetEntityDrawOutlineColor(80, 140, 230, 255)
            SetEntityDrawOutline(obj, true)
        elseif crateData.style == 'rare' or crateData.style == 'gold' then
            SetEntityDrawOutlineColor(226, 190, 60, 255)
            SetEntityDrawOutline(obj, true)
        end
    end

    localCrates[crateData.id] = {
        id = crateData.id,
        pointId = crateData.pointId,
        coords = coords,
        object = obj,
        label = crateData.label or 'Láda',
        weight = crateData.weight or 3000,
        style = crateData.style or 'white',
        tier = crateData.tier,
        zoneLabel = crateData.zoneLabel,
        areaName = crateData.areaName
    }
end

RegisterNetEvent('realrpg_detector:client:spawnCrate', function(crateData)
    spawnCrate(crateData)
end)

RegisterNetEvent('realrpg_detector:client:removeCrate', function(crateId)
    local crate = localCrates[crateId]
    if crate then
        deleteEntitySafe(crate.object)
        localCrates[crateId] = nil
    end
end)

RegisterNetEvent('realrpg_detector:client:clearCrates', function()
    for _, crate in pairs(localCrates) do deleteEntitySafe(crate.object) end
    localCrates = {}
end)

-- ═══════════════════════════════════════════
-- MAIN DETECTOR LOOP
-- Sends precise direction data to NUI + world icons for dig points + crate icons
-- Only within zone scan ranges (realistic)
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

            if nearest then
                local scanRange = nearest.scanRange or Config.Detector.scanRange
                local targetHeading = headingToPoint(pCoords, nearest.coords)
                local relativeAngle = normalizeAngle(targetHeading - playerHeading)
                local strength = 1.0 - math.min(distance / scanRange, 1.0)
                local canDig = distance <= Config.Detector.digDistance

                if now - lastNuiUpdate > 60 then
                    -- World-space dig icons for nearby points
                    local digIcons = {}
                    for _, point in pairs(knownPoints) do
                        local renderDist = point.iconRenderDistance or Config.Detector.iconRenderDistance
                        local dist = #(pCoords - point.coords)
                        if dist <= renderDist then
                            local onScreen, sx, sy = World3dToScreen2d(point.coords.x, point.coords.y, point.coords.z + 0.8)
                            if onScreen then
                                local isDiggable = dist <= Config.Detector.digDistance
                                digIcons[#digIcons + 1] = {
                                    pointId = point.id,
                                    x = sx * 100.0,
                                    y = sy * 100.0,
                                    alpha = math.max(0.4, 1.0 - (dist / renderDist)),
                                    diggable = isDiggable,
                                    dist = math.floor(dist)
                                }
                            end
                        end
                    end

                    -- World-space crate icons
                    local crateIcons = {}
                    for crateId, crate in pairs(localCrates) do
                        local dist = #(pCoords - crate.coords)
                        if dist < 25.0 then
                            local onScreen, sx, sy = World3dToScreen2d(crate.coords.x, crate.coords.y, crate.coords.z + 0.8)
                            if onScreen then
                                local canPickup = dist <= Config.Detector.pickupDistance
                                crateIcons[#crateIcons + 1] = {
                                    crateId = crateId,
                                    x = sx * 100.0,
                                    y = sy * 100.0,
                                    label = crate.label,
                                    canPickup = canPickup,
                                    dist = math.floor(dist)
                                }
                            end
                        end
                    end

                    SendNUIMessage({
                        action = 'radar',
                        hasTarget = true,
                        distance = distance,
                        maxDistance = scanRange,
                        angle = relativeAngle,
                        strength = strength,
                        area = nearest.areaName or nearest.zoneLabel or Config.Detector.areaName,
                        coordX = pCoords.x,
                        coordY = pCoords.y,
                        canDig = canDig,
                        pointId = nearest.id
                    })

                    SendNUIMessage({ action = 'digIcons', icons = digIcons })
                    SendNUIMessage({ action = 'crateIcons', icons = crateIcons })
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
                -- No target in range
                if now - lastNuiUpdate > 200 then
                    SendNUIMessage({
                        action = 'radar',
                        hasTarget = false,
                        area = Config.Detector.areaName,
                        coordX = pCoords.x,
                        coordY = pCoords.y,
                        canDig = false,
                        pointId = nil
                    })
                    SendNUIMessage({ action = 'digIcons', icons = {} })
                    SendNUIMessage({ action = 'crateIcons', icons = {} })
                    lastNuiUpdate = now
                end
            end
        else
            -- Also send crate icons when detector is off (so player can pick them up)
            if not isDigging and next(localCrates) then
                sleep = 200
                local ped = PlayerPedId()
                local pCoords = GetEntityCoords(ped)
                local crateIcons = {}
                for crateId, crate in pairs(localCrates) do
                    local dist = #(pCoords - crate.coords)
                    if dist < 25.0 then
                        local onScreen, sx, sy = World3dToScreen2d(crate.coords.x, crate.coords.y, crate.coords.z + 0.8)
                        if onScreen then
                            crateIcons[#crateIcons + 1] = {
                                crateId = crateId,
                                x = sx * 100.0,
                                y = sy * 100.0,
                                label = crate.label,
                                canPickup = dist <= Config.Detector.pickupDistance,
                                dist = math.floor(dist)
                            }
                        end
                    end
                end
                if #crateIcons > 0 then
                    SendNUIMessage({ action = 'crateIcons', icons = crateIcons })
                    SendNUIMessage({ action = 'showCratesOnly' })
                else
                    SendNUIMessage({ action = 'hideCratesOnly' })
                end
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

    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hide' })
    deleteEntitySafe(detectorObject)
    deleteEntitySafe(shovelObject)

    for _, crate in pairs(localCrates) do
        deleteEntitySafe(crate.object)
    end
end)
