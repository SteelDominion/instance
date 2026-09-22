local M = {}

function M.shoot(api)
    api:shootOnce(api:isShootingNeedConsumeAmmo())
end

function M.start_reload(api)
    local cache = {
        reloaded_count = 0,
        needed_count = (api:getNeededAmmoAmount() - (api:getNeededAmmoAmount() % 5)),
        is_tactical = true,
        interrupted_time = -1,
    }
    api:cacheScriptData(cache)
    return true
end

local function getReloadTimingFromParam(param)
    local intro_empty = param.intro_empty * 1000
    local intro = param.intro * 1000
    local loop = param.loop * 1000
    local ending = param.ending * 1000
    local intro_empty_feed = param.intro_empty_feed * 1000
    local loop_feed = param.loop_feed * 100
    if (intro_empty == nil or intro == nil or loop == nil or ending == nil or intro_empty_feed == nil or loop_feed == nil) then
        return nil
    end
    return intro_empty, intro, loop, ending, intro_empty_feed, loop_feed
end

function M.tick_reload(api)
    local param = api:getScriptParams();
    local intro_empty, intro, loop, ending, intro_empty_feed, loop_feed = getReloadTimingFromParam(param)
    if (intro_empty == nil) then
        return NOT_RELOADING, -1
    end
    local reload_time = api:getReloadTime()
    local cache = api:getCachedScriptData()
    local interrupted_time = cache.interrupted_time
    if (interrupted_time ~= -1) then
        local int_time = reload_time - interrupted_time
        if (int_time >= ending) then
            return NOT_RELOADING, -1
        else
            if (cache.is_tactical) then
                return TACTICAL_RELOAD_FINISHING, ending - int_time
            else
                return EMPTY_RELOAD_FINISHING, ending - int_time
            end
        end
    else
        if (not api:hasAmmoToConsume()) then
            interrupted_time = api:getReloadTime()
        end
    end
    local reloaded_count = cache.reloaded_count;
    if (reloaded_count == 0) then
        if (not cache.is_tactical) then
            if (reload_time > intro_empty_feed) then
                api:consumeAmmoFromPlayer(1)
                api:setAmmoInBarrel(true)
                --史山忽略即可
                reloaded_count = reloaded_count + 1
            end
        else
            reloaded_count = reloaded_count + 1
        end
    end
    if (reloaded_count > 0) then
        local base_time = (reloaded_count -1) / 5 * loop + loop_feed
        if (not cache.is_tactical) then
            base_time = base_time + intro_empty
        else
            base_time = base_time + intro
        end
        while (base_time < reload_time) do
            if (reloaded_count >= cache.needed_count) then
                break
            end
            reloaded_count = reloaded_count + 5
            base_time = base_time + loop
            api:consumeAmmoFromPlayer(5)
            api:putAmmoInMagazine(5)
        end
    end
    if (reloaded_count > cache.needed_count) then
        interrupted_time = api:getReloadTime() - loop_feed + loop
    end
    cache.interrupted_time = interrupted_time
    cache.reloaded_count = reloaded_count
    api:cacheScriptData(cache)
    local total_time = cache.needed_count / 5 * loop
    if (not cache.is_tactical) then
        total_time = total_time + intro_empty
        return EMPTY_RELOAD_FEEDING, total_time - reload_time
    else
        total_time = total_time + intro
        return TACTICAL_RELOAD_FEEDING, total_time - reload_time
    end
end

function M.interrupt_reload(api)
    local cache = api:getCachedScriptData()
    if (cache ~= nil and cache.interrupted_time == -1) then
        cache.interrupted_time = api:getReloadTime()
    end
end

return M