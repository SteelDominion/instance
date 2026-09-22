local M = {}

function M.shoot(api)
    api:shootOnce(true)
end

function M.start_reload(api)
    local cache = {
        reloaded_count = 0,
        needed_count = api:getNeededAmmoAmount(),
        is_tactical = api:getReloadStateType() == TACTICAL_RELOAD_FEEDING,
        interrupted_time = -1,
    }
    if(api:hasAmmoInBarrel())then
        cache.needed_count = cache.needed_count - 1
    end
    api:cacheScriptData(cache)
    return true
end

local function getReloadTimingFromParam(param)
    local intro = param.intro * 1000
    local intro_empty = param.intro_empty * 1000
    local loop = param.loop * 1000
    local ending = param.ending * 1000
    local ending_empty = param.ending_empty * 1000
    local ending_empty_feed = param.ending_empty_feed * 1000
    local clip_load = param.clip_load * 1000
    local clip_load_feed = param.clip_load_feed * 1000
    local loop_feed = param.loop_feed * 1000
    if (intro == nil or intro_empty == nil or loop == nil or ending == nil or ending_empty == nil or ending_empty_feed == nil or clip_load == nil or clip_load_feed == nil or loop_feed == nil) then
        return nil
    end
    return intro, intro_empty, loop, ending, ending_empty, ending_empty_feed, clip_load, clip_load_feed, loop_feed
end

function M.tick_reload(api)
    local param = api:getScriptParams();
    local intro, intro_empty, loop, ending, ending_empty, ending_empty_feed, clip_load, clip_load_feed, loop_feed = getReloadTimingFromParam(param)
    local reload_time = api:getReloadTime()
    local cache = api:getCachedScriptData()
    local interrupted_time = cache.interrupted_time
    if (cache.interrupted_time ~= -1) then
        local int_time = reload_time - cache.interrupted_time
        if (not cache.is_tactical) then
            if(int_time >= ending_empty) then
               return NOT_RELOADING, -1
            else
               return EMPTY_RELOAD_FINISHING, ending_empty - int_time
            end
        else
            if(int_time >= ending) then
               return NOT_RELOADING, -1
            else
                return TACTICAL_RELOAD_FINISHING, ending - int_time
            end
        end
    else
        if (not api:hasAmmoToConsume()) then
            interrupted_time = api:getReloadTime()
        end
    end

    local reloaded_count = cache.reloaded_count;

    if (reloaded_count >= 0) then
        local base_time = reloaded_count * loop + loop_feed
        if(cache.needed_count == 8) then
            base_time = clip_load_feed
        end
        if (not cache.is_tactical) then
            base_time = base_time + intro_empty
        else
            base_time = base_time + intro
        end
        while (base_time < reload_time) do
            if (reloaded_count > cache.needed_count) then
                break
            end
            if (cache.needed_count == 8) then
                reloaded_count = reloaded_count + 9
                api:putAmmoInMagazine(api:isReloadingNeedConsumeAmmo() and api:consumeAmmoFromPlayer(8) or 8)
            else
                reloaded_count = reloaded_count + 1
                base_time = base_time + loop
                api:consumeAmmoFromPlayer(1)
                api:putAmmoInMagazine(1)
            end
        end
    end

    if (reloaded_count >= cache.needed_count) then
        interrupted_time = api:getReloadTime() - loop_feed + loop
    end
    cache.interrupted_time = interrupted_time
    cache.reloaded_count = reloaded_count
    api:cacheScriptData(cache)
    local total_time = 0
    if (not cache.is_tactical) then
        total_time = clip_load + intro_empty
        return EMPTY_RELOAD_FEEDING, total_time - reload_time
    else
        total_time = cache.needed_count * loop + intro
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