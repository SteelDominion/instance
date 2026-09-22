local M = {}

function M.start_reload(api)
    return true
end

local function getReloadTimingFromParam(param)
    local reload_feed = {param.reload_feed, param.reload_xmag_1_feed, param.reload_xmag_2_feed, param.reload_xmag_3_feed}
    local reload_cooldown = {param.reload_cooldown, param.reload_xmag_1_cooldown, param.reload_xmag_2_cooldown, param.reload_xmag_3_cooldown}
    local empty_feed = {param.empty_feed, param.empty_xmag_1_feed, param.empty_xmag_2_feed, param.empty_xmag_3_feed}
    local empty_cooldown = {param.empty_cooldown, param.empty_xmag_1_cooldown, param.empty_xmag_2_cooldown, param.empty_xmag_3_cooldown}
    for i = 1, 4 do
        if (reload_feed[i] == nil or reload_cooldown[i] == nil or empty_feed[i] == nil or empty_cooldown[i] == nil) then
            return nil, nil, nil, nil
        end
        reload_feed[i] = reload_feed[i] * 1000
        reload_cooldown[i] = reload_cooldown[i] * 1000
        empty_feed[i] = empty_feed[i] * 1000
        empty_cooldown[i] = empty_cooldown[i] * 1000
    end

    return reload_feed, reload_cooldown, empty_feed, empty_cooldown
end

local function isReloadingEmpty(stateType)
    return stateType == EMPTY_RELOAD_FEEDING or stateType == EMPTY_RELOAD_FINISHING
end

local function isReloadingTactical(stateType)
    return stateType == TACTICAL_RELOAD_FEEDING or stateType == TACTICAL_RELOAD_FINISHING
end

local function isReloading(stateType)
    return isReloadingEmpty(stateType) or isReloadingTactical(stateType)
end

local function isReloadFinishing(stateType)
    return stateType == EMPTY_RELOAD_FINISHING or stateType == TACTICAL_RELOAD_FINISHING
end

local function finishReload(api, is_tactical)
    local needAmmoCount = api:getNeededAmmoAmount();
    api:setAmmoInBarrel(true)
    if (api:isReloadingNeedConsumeAmmo()) then
        api:putAmmoInMagazine(api:consumeAmmoFromPlayer(needAmmoCount))
    else
        api:putAmmoInMagazine(needAmmoCount)
    end
end

function M.tick_reload(api)
    local param = api:getScriptParams();
    local reload_feed, reload_cooldown, empty_feed, empty_cooldown = getReloadTimingFromParam(param)
    if (reload_feed == nil or reload_cooldown == nil or empty_feed == nil or empty_cooldown == nil) then
        return NOT_RELOADING, -1
    end

    local mag_level = math.min(api:getMagExtentLevel(), 3) + 1

    local countDown = -1
    local stateType = NOT_RELOADING
    local oldStateType = api:getReloadStateType()

    local progressTime = api:getReloadTime()

    if isReloadingEmpty(oldStateType) then
        local feed_time = empty_feed[mag_level]
        local finishing_time = empty_cooldown[mag_level]
        if progressTime < feed_time then
            stateType = EMPTY_RELOAD_FEEDING
            countDown = feed_time - progressTime
        elseif progressTime < finishing_time then
            stateType = EMPTY_RELOAD_FINISHING
            countDown = finishing_time - progressTime
        else
            stateType = NOT_RELOADING;
            countDown = -1
        end
    elseif isReloadingTactical(oldStateType) then
        local feed_time = reload_feed[mag_level]
        local finishing_time = reload_cooldown[mag_level]
        if progressTime < feed_time then
            stateType = TACTICAL_RELOAD_FEEDING
            countDown = feed_time - progressTime
        elseif progressTime < finishing_time then
            stateType = TACTICAL_RELOAD_FINISHING
            countDown = finishing_time - progressTime
        else
            stateType = NOT_RELOADING;
            countDown = -1
        end
    else
        stateType = NOT_RELOADING;
        countDown = -1
    end

    if oldStateType == EMPTY_RELOAD_FEEDING and oldStateType ~= stateType then
        finishReload(api,false);
    end

    if oldStateType == TACTICAL_RELOAD_FEEDING and oldStateType ~= stateType then
        finishReload(api, true);
    end

    return stateType, countDown
end

return M