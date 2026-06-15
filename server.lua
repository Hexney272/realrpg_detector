local ESX = nil
local ActivePoints = {}
local DigLocks = {}
local Crates = {}
local crateCounter = 0

local function dbg(msg)
    if Config.Debug then
        print(('[realrpg_detector] %s'):format(msg))
    end
end

local function notify(src, msg, nType)
    TriggerClientEvent('realrpg_detector:client:notify', src, msg, nType or 'info')
end

local function getESX()
    if ESX then return ESX end

    if Config.Framework == 'esx' then
        if exports and exports['es_extended'] and exports['es_extended'].getSharedObject then
            ESX = exports['es_extended']:getSharedObject()
        else
            TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        end
    end

    return ESX
end

local function plainCoords(coords)
    return {
        x = coords.x + 0.0,
        y = coords.y + 0.0,
        z = coords.z + 0.0
    }
end

local function getConfiguredZones()
    if Config.DetectorZones and type(Config.DetectorZones) == 'table' and #Config.DetectorZones > 0 then
        return Config.DetectorZones
    end

    return {
        {
            id = 'legacy',
            label = Config.Detector.areaName or 'Detektor zóna',
            areaName = Config.Detector.areaName or 'Detektor zóna',
            rewards = Config.Rewards or {},
            points = Config.DetectorPoints or {},
            respawnMinutes = Config.Detector.respawnMinutes
        }
    }
end

local function plainPoint(id)
    local p = ActivePoints[id]
    if not p or not p.active then return nil end

    return {
        id = id,
        coords = plainCoords(p.coords),
        zoneId = p.zoneId,
        zoneLabel = p.zoneLabel,
        areaName = p.areaName,
        tier = p.tier,
        scanRange = p.scanRange,
        iconRenderDistance = p.iconRenderDistance
    }
end

local function sendAllPoints(src)
    local data = {}

    for id, p in pairs(ActivePoints) do
        if p.active then
            data[#data + 1] = plainPoint(id)
        end
    end

    TriggerClientEvent('realrpg_detector:client:syncPoints', src, data)
end

local function broadcastPoint(id)
    local p = plainPoint(id)
    if p then
        TriggerClientEvent('realrpg_detector:client:addPoint', -1, p)
    else
        TriggerClientEvent('realrpg_detector:client:removePoint', -1, id)
    end
end

local function normalizeZone(zone, index)
    zone = zone or {}

    return {
        id = zone.id or ('zone_%s'):format(index),
        label = zone.label or zone.areaName or ('Detektor zóna #%s'):format(index),
        areaName = zone.areaName or zone.label or Config.Detector.areaName or 'Detektor zóna',
        rewards = zone.rewards or Config.Rewards or {},
        points = zone.points or {},
        respawnMinutes = zone.respawnMinutes or Config.Detector.respawnMinutes,
        scanRange = zone.scanRange or Config.Detector.scanRange,
        iconRenderDistance = zone.iconRenderDistance or Config.Detector.iconRenderDistance,
        tier = zone.tier or zone.valueTier
    }
end

local function initPoints()
    ActivePoints = {}
    local pointId = 0
    local zoneCount = 0

    for zoneIndex, rawZone in ipairs(getConfiguredZones()) do
        local zone = normalizeZone(rawZone, zoneIndex)
        zoneCount = zoneCount + 1

        for localIndex, coords in ipairs(zone.points or {}) do
            pointId = pointId + 1
            ActivePoints[pointId] = {
                id = pointId,
                localIndex = localIndex,
                coords = coords,
                active = true,
                lockedBy = nil,
                zoneId = zone.id,
                zoneLabel = zone.label,
                areaName = zone.areaName,
                rewards = zone.rewards,
                respawnMinutes = zone.respawnMinutes,
                scanRange = zone.scanRange,
                iconRenderDistance = zone.iconRenderDistance,
                tier = zone.tier
            }
        end
    end

    dbg(('Loaded %s detector points in %s zones'):format(pointId, zoneCount))
end

local function getItemCount(src, item)
    if Config.Inventory == 'ox' and GetResourceState('ox_inventory') == 'started' then
        local count = exports.ox_inventory:Search(src, 'count', item)
        return count or 0
    end

    local esx = getESX()
    local xPlayer = esx and esx.GetPlayerFromId(src)
    if not xPlayer then return 0 end

    local invItem = xPlayer.getInventoryItem(item)
    return (invItem and invItem.count) or 0
end

local function removeItem(src, item, count)
    count = count or 1

    if Config.Inventory == 'ox' and GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:RemoveItem(src, item, count)
    end

    local esx = getESX()
    local xPlayer = esx and esx.GetPlayerFromId(src)
    if not xPlayer then return false end

    xPlayer.removeInventoryItem(item, count)
    return true
end

local function addItem(src, item, count, metadata)
    count = count or 1

    if Config.Inventory == 'ox' and GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:AddItem(src, item, count, metadata or {})
    end

    local esx = getESX()
    local xPlayer = esx and esx.GetPlayerFromId(src)
    if not xPlayer then return false end

    if xPlayer.canCarryItem and not xPlayer.canCarryItem(item, count) then
        return false
    end

    xPlayer.addInventoryItem(item, count)
    return true
end

local function weightedReward(rewards)
    rewards = rewards or Config.Rewards or {}
    local total = 0

    for _, reward in ipairs(rewards) do
        total = total + (reward.chance or 0)
    end

    if total <= 0 then
        return {
            name = 'drog_alapanyag_lada',
            label = 'Drog alapanyag láda',
            weight = 3000,
            min = 1,
            max = 1,
            value = 0,
            crateStyle = 'white'
        }
    end

    local roll = math.random(1, total)
    local current = 0

    for _, reward in ipairs(rewards) do
        current = current + (reward.chance or 0)
        if roll <= current then
            return reward
        end
    end

    return rewards[1]
end

local function playerDistanceFromPoint(src, coords)
    local ped = GetPlayerPed(src)
    if ped == 0 then return 99999.0 end

    local pCoords = GetEntityCoords(ped)
    return #(pCoords - coords)
end

CreateThread(function()
    math.randomseed(os.time())
    getESX()
    initPoints()

    if Config.Framework == 'esx' and Config.RegisterUsableDetector then
        CreateThread(function()
            while not getESX() do Wait(500) end

            ESX.RegisterUsableItem(Config.Items.detector, function(src)
                if getItemCount(src, Config.Items.detector) <= 0 then
                    notify(src, Config.Text.noDetector or 'Nincs nálad fémkereső.', 'error')
                    return
                end
                TriggerClientEvent('realrpg_detector:client:toggleDetector', src, nil, true)
            end)

            ESX.RegisterUsableItem(Config.Items.shovel, function(src)
                if getItemCount(src, Config.Items.shovel) <= 0 then
                    notify(src, Config.Text.noShovel, 'error')
                    return
                end
                TriggerClientEvent('realrpg_detector:client:useShovelItem', src)
            end)
        end)
    end
end)

RegisterNetEvent('realrpg_detector:server:useDetectorItem', function()
    local src = source

    if getItemCount(src, Config.Items.detector) <= 0 then
        notify(src, Config.Text.noDetector or 'Nincs nálad fémkereső.', 'error')
        return
    end

    TriggerClientEvent('realrpg_detector:client:toggleDetector', src, nil, true)
end)

RegisterNetEvent('realrpg_detector:server:useShovelItem', function()
    local src = source

    if getItemCount(src, Config.Items.shovel) <= 0 then
        notify(src, Config.Text.noShovel or 'Nincs nálad ásó.', 'error')
        return
    end

    TriggerClientEvent('realrpg_detector:client:useShovelItem', src)
end)

RegisterNetEvent('realrpg_detector:server:requestPoints', function()
    local src = source
    sendAllPoints(src)
end)

RegisterNetEvent('realrpg_detector:server:beginDig', function(pointId)
    local src = source
    pointId = tonumber(pointId)

    local point = pointId and ActivePoints[pointId]
    if not point or not point.active then
        notify(src, Config.Text.pointBusy, 'error')
        return
    end

    if point.lockedBy and point.lockedBy ~= src then
        notify(src, Config.Text.pointBusy, 'error')
        return
    end

    if Config.Detector.requireShovel and getItemCount(src, Config.Items.shovel) <= 0 then
        notify(src, Config.Text.noShovel, 'error')
        return
    end

    local distance = playerDistanceFromPoint(src, point.coords)
    if distance > (Config.Detector.digDistance + 4.0) then
        notify(src, Config.Text.tooFar, 'error')
        return
    end

    point.lockedBy = src
    DigLocks[src] = pointId

    TriggerClientEvent('realrpg_detector:client:beginDigAllowed', src, pointId, plainCoords(point.coords))

    SetTimeout(Config.Detector.digTimeMs + 20000, function()
        if ActivePoints[pointId] and ActivePoints[pointId].lockedBy == src then
            ActivePoints[pointId].lockedBy = nil
        end

        if DigLocks[src] == pointId then
            DigLocks[src] = nil
        end
    end)
end)

RegisterNetEvent('realrpg_detector:server:cancelDig', function(pointId)
    local src = source
    pointId = tonumber(pointId)

    if pointId and ActivePoints[pointId] and ActivePoints[pointId].lockedBy == src then
        ActivePoints[pointId].lockedBy = nil
    end

    if DigLocks[src] == pointId then
        DigLocks[src] = nil
    end
end)

RegisterNetEvent('realrpg_detector:server:finishDig', function(pointId)
    local src = source
    pointId = tonumber(pointId)

    local point = pointId and ActivePoints[pointId]
    if not point or not point.active or point.lockedBy ~= src or DigLocks[src] ~= pointId then
        notify(src, Config.Text.pointBusy, 'error')
        return
    end

    if Config.Detector.requireShovel and getItemCount(src, Config.Items.shovel) <= 0 then
        point.lockedBy = nil
        DigLocks[src] = nil
        notify(src, Config.Text.noShovel, 'error')
        return
    end

    local distance = playerDistanceFromPoint(src, point.coords)
    if distance > (Config.Detector.digDistance + 6.0) then
        point.lockedBy = nil
        DigLocks[src] = nil
        notify(src, Config.Text.tooFar, 'error')
        return
    end

    if Config.Detector.removeShovelChance > 0 then
        local breakRoll = math.random(1, 100)
        if breakRoll <= Config.Detector.removeShovelChance then
            removeItem(src, Config.Items.shovel, 1)
        end
    end

    point.active = false
    point.lockedBy = nil
    DigLocks[src] = nil

    local reward = weightedReward(point.rewards)
    crateCounter = crateCounter + 1
    local crateId = ('crate_%s_%s_%s'):format(src, pointId, crateCounter)

    Crates[crateId] = {
        owner = src,
        pointId = pointId,
        coords = point.coords,
        reward = reward,
        zoneId = point.zoneId,
        zoneLabel = point.zoneLabel,
        areaName = point.areaName,
        expires = os.time() + (Config.Detector.crateLifetimeMinutes * 60)
    }

    TriggerClientEvent('realrpg_detector:client:removePoint', -1, pointId)
    TriggerClientEvent('realrpg_detector:client:spawnCrate', src, {
        id = crateId,
        pointId = pointId,
        coords = plainCoords(point.coords),
        label = reward.label,
        weight = reward.weight,
        value = reward.value or reward.estimatedValue or 0,
        tier = reward.tier,
        style = reward.crateStyle or 'white',
        zoneId = point.zoneId,
        zoneLabel = point.zoneLabel,
        areaName = point.areaName
    })

    notify(src, Config.Text.crateFound, 'success')

    SetTimeout(Config.Detector.crateLifetimeMinutes * 60000, function()
        if Crates[crateId] then
            Crates[crateId] = nil
            TriggerClientEvent('realrpg_detector:client:removeCrate', src, crateId)
        end
    end)

    SetTimeout((point.respawnMinutes or Config.Detector.respawnMinutes) * 60000, function()
        if ActivePoints[pointId] then
            ActivePoints[pointId].active = true
            ActivePoints[pointId].lockedBy = nil
            broadcastPoint(pointId)
        end
    end)
end)

RegisterNetEvent('realrpg_detector:server:pickupCrate', function(crateId)
    local src = source
    local crate = crateId and Crates[crateId]

    if not crate or crate.owner ~= src then
        return
    end

    if os.time() > crate.expires then
        Crates[crateId] = nil
        TriggerClientEvent('realrpg_detector:client:removeCrate', src, crateId)
        return
    end

    local distance = playerDistanceFromPoint(src, crate.coords)
    if distance > (Config.Detector.pickupDistance + 3.5) then
        notify(src, Config.Text.tooFar, 'error')
        return
    end

    local reward = crate.reward
    local amount = math.random(reward.min or 1, reward.max or 1)
    local value = reward.value or reward.estimatedValue or 0
    local metadata = {
        label = reward.label,
        description = ('Detektorozással talált lelet. Terület: %s. Becsült érték: %s%s.'):format(crate.areaName or crate.zoneLabel or Config.Detector.areaName, Config.Economy.currency or '$', value),
        weight = reward.weight,
        estimatedValue = value,
        value = value,
        tier = reward.tier,
        zoneId = crate.zoneId,
        zoneLabel = crate.zoneLabel,
        areaName = crate.areaName,
        foundAt = os.date('%Y-%m-%d %H:%M:%S'),
        source = crate.areaName or crate.zoneLabel or Config.Detector.areaName
    }

    local added = addItem(src, reward.name, amount, metadata)
    if not added then
        notify(src, Config.Text.inventoryFull, 'error')
        return
    end

    Crates[crateId] = nil
    TriggerClientEvent('realrpg_detector:client:removeCrate', src, crateId)
    notify(src, Config.Text.cratePicked, 'success')
end)

RegisterCommand(Config.Commands.adminResetName, function(src)
    if not Config.Commands.adminReset then return end

    if src ~= 0 and Config.Commands.adminAce and Config.Commands.adminAce ~= '' then
        if not IsPlayerAceAllowed(src, Config.Commands.adminAce) then
            notify(src, 'Nincs jogosultságod ehhez.', 'error')
            return
        end
    end

    initPoints()
    Crates = {}
    DigLocks = {}
    TriggerClientEvent('realrpg_detector:client:clearCrates', -1)

    for _, playerId in ipairs(GetPlayers()) do
        sendAllPoints(tonumber(playerId))
    end

    if src == 0 then
        print('[realrpg_detector] Detektor pontok újratöltve.')
    else
        notify(src, 'Detektor pontok újratöltve.', 'success')
    end
end, true)

AddEventHandler('playerDropped', function()
    local src = source

    if DigLocks[src] then
        local pointId = DigLocks[src]
        if ActivePoints[pointId] and ActivePoints[pointId].lockedBy == src then
            ActivePoints[pointId].lockedBy = nil
        end
        DigLocks[src] = nil
    end

    for crateId, crate in pairs(Crates) do
        if crate.owner == src then
            Crates[crateId] = nil
        end
    end
end)
