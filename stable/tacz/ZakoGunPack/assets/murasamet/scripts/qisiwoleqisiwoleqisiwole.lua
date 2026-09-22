local track_line_top = {value = 0}
local static_track_top = {value = 0}
local blending_track_top = {value = 0}
local function increment(obj)
    obj.value = obj.value + 1
    return obj.value - 1
end

local STATIC_TRACK_LINE = increment(track_line_top)
local BASE_TRACK = increment(static_track_top)
local BOLT_CAUGHT_TRACK = increment(static_track_top)
local SAFETY_TRACK = increment(static_track_top)
local ADS_TRACK = increment(static_track_top)
local MAIN_TRACK = increment(static_track_top)
local SPRINT_TRACK = increment(static_track_top)

local GUN_KICK_TRACK_LINE = increment(track_line_top)

local BLENDING_TRACK_LINE = increment(track_line_top)
local MOVEMENT_TRACK = increment(blending_track_top)
local SLIDE_TRACK = increment(blending_track_top)
local OVER_HEAT_TRACK = increment(blending_track_top)
local OVER_HEATING_TRACK = increment(blending_track_top)
local LOOP_TRACK = increment(blending_track_top)

local function isNoAmmo(context)
    return (not context:hasBulletInBarrel()) and (context:getAmmoCount() <= 0)
end

local function runPutAwayAnimation(context)
    local put_away_time = context:getPutAwayTime()
    local track = context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK)
    context:runAnimation("put_away", track, false, PLAY_ONCE_HOLD, put_away_time * 0.75)
    context:setAnimationProgress(track, 1, true)
    context:adjustAnimationProgress(track, -put_away_time, false)
end


local function runReloadAnimation(context)
    local track = context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK)
    if (isNoAmmo(context)) then
        context:runAnimation("reload_empty", track, false, PLAY_ONCE_STOP, 0.2)
    else
        context:runAnimation("reload_tactical", track, false, PLAY_ONCE_STOP, 0.2)
    end
end

local function runInspectAnimation(context)
    local track = context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK)
    if (isNoAmmo(context)) then
        context:runAnimation("inspect_empty", track, false, PLAY_ONCE_STOP, 0.2)
    else
        context:runAnimation("inspect", track, false, PLAY_ONCE_STOP, 0.2)
    end
end

local function isOverHeat(context)
    return context:isOverHeat()
end
local base_track_state = {}
function base_track_state.entry(this, context)
    context:runAnimation("static_idle", context:getTrack(STATIC_TRACK_LINE, BASE_TRACK), false, LOOP, 0)
end
local bolt_caught_states = {
    normal = {},
    bolt_caught = {}
}

function bolt_caught_states.normal.update(this, context)
    if (isNoAmmo(context)) then
        context:trigger(this.INPUT_BOLT_CAUGHT)
    end
end

function bolt_caught_states.normal.entry(this, context)
    this.bolt_caught_states.normal.update(this, context)
end

function bolt_caught_states.normal.transition(this, context, input)
    if (input == this.INPUT_BOLT_CAUGHT) then
        return this.bolt_caught_states.bolt_caught
    end
end

function bolt_caught_states.bolt_caught.entry(this, context)
    context:runAnimation("static_bolt_caught", context:getTrack(STATIC_TRACK_LINE, BOLT_CAUGHT_TRACK), false, LOOP, 0)
end

function bolt_caught_states.bolt_caught.update(this, context)
    if (not isNoAmmo(context)) then
        context:trigger(this.INPUT_BOLT_NORMAL)
    end
end

function bolt_caught_states.bolt_caught.transition(this, context, input)
    if (input == this.INPUT_BOLT_NORMAL) then
        context:stopAnimation(context:getTrack(STATIC_TRACK_LINE, BOLT_CAUGHT_TRACK))
        return this.bolt_caught_states.normal
    end
end

local main_track_states = {
    start = {},
    idle = {},
    inspect = {},
    final = {
        isfinal = -1
    },
    bayonet_counter = 0
}

function main_track_states.start.transition(this, context, input)
    if (input == INPUT_DRAW) then
        this.main_track_states.final.isfinal = -1
        context:runAnimation("draw", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0)
        return this.main_track_states.idle
    end
end

function main_track_states.idle.transition(this, context, input)
    if (input == INPUT_PUT_AWAY) then
        runPutAwayAnimation(context)
        this.main_track_states.final.isfinal = 1
        return this.main_track_states.final
    end
    if (input == INPUT_RELOAD) then
        runReloadAnimation(context)
        return this.main_track_states.idle
    end
    if (input == INPUT_SHOOT) then
        context:popShellFrom(0)
        return this.main_track_states.idle
    end
    if (input == INPUT_BOLT) then
        context:runAnimation("bolt", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0.2)
        return this.main_track_states.idle
    end
    if (input == INPUT_INSPECT and context:getAimingProgress() < 1) then
        runInspectAnimation(context)
        return this.main_track_states.inspect
    end
    if (input == INPUT_BAYONET_MUZZLE) then
        local counter = this.main_track_states.bayonet_counter
        local animationName = "melee_bayonet_" .. tostring(counter + 1)
        this.main_track_states.bayonet_counter = (counter + 1) % 3
        context:runAnimation(animationName, context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0.2)
        return this.main_track_states.idle
    end
    if (input == INPUT_BAYONET_STOCK) then
        context:runAnimation("melee_stock", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0.2)
        return this.main_track_states.idle
    end
    if (input == INPUT_BAYONET_PUSH) then
        context:runAnimation("melee_push", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0.2)
        return this.main_track_states.idle
    end
end

function main_track_states.inspect.entry(this, context)
    context:setShouldHideCrossHair(true)
end

function main_track_states.inspect.exit(this, context)
    context:stopAnimation(context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK))
    context:setShouldHideCrossHair(false)
end

function main_track_states.inspect.update(this, context)
    if (context:isStopped(context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK))) then
        context:trigger(this.INPUT_INSPECT_RETREAT)
    end
end

function main_track_states.inspect.transition(this, context, input)
    if (input == this.INPUT_INSPECT_RETREAT) then
        return this.main_track_states.idle
    end
    if (input == INPUT_SHOOT or context:getAimingProgress() > 0) then
        context:stopAnimation(context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK))
        return this.main_track_states.idle
    end
    return this.main_track_states.idle.transition(this, context, input)
end

local gun_kick_state = {}

function gun_kick_state.transition(this, context, input)
    if (input == INPUT_SHOOT) then
        local track = context:findIdleTrack(GUN_KICK_TRACK_LINE, false)
        context:runAnimation("shoot", track, true, PLAY_ONCE_STOP, 0)
    end
    return nil
end

local movement_track_states = {
    idle = {},
    run = {
        mode = -1,
        time = 0
    },
    walk = {
        mode = -1
    },
    sprint = {
        mode = -1
    }
}

function movement_track_states.idle.update(this, context)
    local track = context:getTrack(BLENDING_TRACK_LINE, MOVEMENT_TRACK)
    if (context:isStopped(track) or context:isHolding(track)) then
        context:runAnimation("idle", track, true, LOOP, 0)
    end
end

function movement_track_states.idle.transition(this, context, input)
    if (input == INPUT_RUN) then
        if (context:isStopped(context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK))) then
            return this.movement_track_states.run
        else
            return this.movement_track_states.walk
        end
    elseif (input == INPUT_WALK) then
        return this.movement_track_states.walk
    end
end

function movement_track_states.run.entry(this, context)
    this.movement_track_states.run.mode = -1
    this.movement_track_states.run.time = context:getCurrentTimestamp()
    context:runAnimation("run_start", context:getTrack(BLENDING_TRACK_LINE, MOVEMENT_TRACK), true, PLAY_ONCE_HOLD, 0.2)
end

function movement_track_states.run.exit(this, context)
    context:runAnimation("run_end", context:getTrack(BLENDING_TRACK_LINE, MOVEMENT_TRACK), true, PLAY_ONCE_HOLD, 0.3)
end

function movement_track_states.run.update(this, context)
    local track = context:getTrack(BLENDING_TRACK_LINE, MOVEMENT_TRACK)
    local state = this.movement_track_states.run;
    if (context:isHolding(track)) then
        context:runAnimation("run", track, true, LOOP, 0.2)
        state.mode = 0
        context:anchorWalkDist() 
    end
    if (state.mode ~= -1) then
        if (not context:isOnGround()) then
            if (state.mode ~= 1) then
                state.mode = 1
                context:runAnimation("run_hold", track, true, LOOP, 0.6)
            end
        else
            if (state.mode ~= 0) then
                state.mode = 0
                context:runAnimation("run", track, true, LOOP, 0.2)
            end
            context:setAnimationProgress(track, (context:getWalkDist() % 2.0) / 2.0, true)
        end
    end
end

function movement_track_states.run.transition(this, context, input)
    if (input == INPUT_IDLE) then
        return this.movement_track_states.idle
    elseif (input == INPUT_WALK or not context:isStopped(context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK))) then
        return this.movement_track_states.walk
    end
end


function movement_track_states.walk.entry(this, context)
    this.movement_track_states.walk.mode = -1
end

function movement_track_states.walk.exit(this, context)
    context:runAnimation("idle", context:getTrack(BLENDING_TRACK_LINE, MOVEMENT_TRACK), true, PLAY_ONCE_HOLD, 0.4)
end

function movement_track_states.walk.update(this, context)
    local track = context:getTrack(BLENDING_TRACK_LINE, MOVEMENT_TRACK)
    local state = this.movement_track_states.walk
    if (context:getShootCoolDown() > 0) then
        if (state.mode ~= 0) then
            state.mode = 0
            context:runAnimation("idle", track, true, LOOP, 0.3)
        end
    elseif (not context:isOnGround()) then
        if (state.mode ~= 0) then
            state.mode = 0
            context:runAnimation("idle", track, true, LOOP, 0.6)
        end
    elseif (context:getAimingProgress() > 0.5) then
        if (state.mode ~= 1) then
            state.mode = 1
            context:runAnimation("walk_aiming", track, true, LOOP, 0.3)
        end
    elseif (context:isInputUp()) then
        if (state.mode ~= 2) then
            state.mode = 2
            context:runAnimation("walk_forward", track, true, LOOP, 0.4)
            context:anchorWalkDist()
        end
    elseif (context:isInputDown()) then
        if (state.mode ~= 3) then
            state.mode = 3
            context:runAnimation("walk_backward", track, true, LOOP, 0.4)
            context:anchorWalkDist()
        end
    elseif (context:isInputLeft() or context:isInputRight()) then
        if (state.mode ~= 4) then
            state.mode = 4
            context:runAnimation("walk_sideway", track, true, LOOP, 0.4)
            context:anchorWalkDist()
        end
    end
    if (state.mode >= 1 and state.mode <= 4) then
        context:setAnimationProgress(track, (context:getWalkDist() % 2.0) / 2.0, true)
    end
end

function movement_track_states.walk.transition(this, context, input)
    if (input == INPUT_IDLE) then
        return this.movement_track_states.idle
    elseif (input == INPUT_RUN) then
        if (context:isStopped(context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK))) then
            return this.movement_track_states.run
        end
    end
end

local slide_states = {
    normal = {},
    slide = {}
}

function slide_states.normal.transition(this, context, input)
    if(context:shouldSlide() and context:isStopped(context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK))) then
        return this.slide_states.slide
    end
end

function slide_states.slide.entry(this, context)
    context:runAnimation("slide", context:getTrack(BLENDING_TRACK_LINE, SLIDE_TRACK), true, PLAY_ONCE_HOLD, 0.5)
end

function slide_states.slide.update(this, context)
    if (context:isStopped(context:getTrack(STATIC_TRACK_LINE, BASE_TRACK)) or context:isHolding(context:getTrack(BLENDING_TRACK_LINE, SLIDE_TRACK))) then
        context:runAnimation("slide_idle", context:getTrack(BLENDING_TRACK_LINE, SLIDE_TRACK), true, LOOP, 0.4)
    end
end

function slide_states.slide.transition(this, context, input)
    if(not context:shouldSlide() or not context:isStopped(context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK))) then
        return this.slide_states.normal
    end
end

function slide_states.slide.exit(this, context)
    context:runAnimation("slide_back", context:getTrack(BLENDING_TRACK_LINE, SLIDE_TRACK), true, PLAY_ONCE_HOLD, 0.2)
end


local over_heat_states = {
    normal = {},
    over_heat = {}
}

function over_heat_states.normal.entry(this, context)
    this.over_heat_states.normal.update(this, context)
end

function over_heat_states.normal.update(this, context)
    if (isOverHeat(context)) then
        context:trigger(this.INPUT_OVER_HEAT)
    end
end

function over_heat_states.normal.transition(this, context, input)
    if (input == this.INPUT_OVER_HEAT) then
        return this.over_heat_states.over_heat
    end
end

function over_heat_states.over_heat.entry(this, context)
    context:runAnimation("over_heat", context:getTrack(BLENDING_TRACK_LINE, OVER_HEAT_TRACK), true, PLAY_ONCE_STOP, 0.2)
    context:runAnimation("static_over_heating", context:getTrack(BLENDING_TRACK_LINE, OVER_HEATING_TRACK), true, LOOP, 0)
end

function over_heat_states.over_heat.update(this, context)
    if (not isOverHeat(context)) then
        context:trigger(this.INPUT_COOLING_HEAT)
    end
end

function over_heat_states.over_heat.transition(this, context, input)
    if (input == this.INPUT_COOLING_HEAT) then
        context:stopAnimation(context:getTrack(BLENDING_TRACK_LINE, OVER_HEATING_TRACK))
        return this.over_heat_states.normal
    end
end

local ADS_states = {
    aiming_progress = 0,
    normal = {},
    aiming = {}
}

function ADS_states.normal.entry(this, context)
    this.ADS_states.normal.update(this, context)
end

function ADS_states.normal.update(this, context)
    if ((context:getAimingProgress() > this.ADS_states.aiming_progress or context:getAimingProgress() == 1) and context:isStopped(context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK))) then
        context:trigger(this.INPUT_AIM)
    else
        this.ADS_states.aiming_progress = context:getAimingProgress()
    end
end

function ADS_states.normal.transition(this, context, input)
    if (input == this.INPUT_AIM) then
        return this.ADS_states.aiming
    end
end

function ADS_states.aiming.entry(this, context)
    local track = context:getTrack(STATIC_TRACK_LINE, ADS_TRACK)
    if (context:isCrawl() or context:isCrouching()) then
        context:runAnimation("aim_start_sight", track, false, PLAY_ONCE_HOLD, 0.2)
    else
        context:runAnimation("aim_start", track, false, PLAY_ONCE_HOLD, 0.2)
    end
    context:trigger(this.INPUT_INSPECT_RETREAT)
end

function ADS_states.aiming.update(this, context)
    local track = context:getTrack(STATIC_TRACK_LINE, ADS_TRACK)
    if (context:isHolding(track)) then
        if (context:isCrawl() or context:isCrouching()) then
            context:runAnimation("aim_sight", track, false, PLAY_ONCE_HOLD, 0.2)
        else
            context:runAnimation("aim", track, false, PLAY_ONCE_HOLD, 0.2)
        end
    end
    if (context:getAimingProgress() < this.ADS_states.aiming_progress or not context:isStopped(context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK))) then
        context:trigger(this.INPUT_AIM_RETREAT)
    else
        this.ADS_states.aiming_progress = context:getAimingProgress()
    end
end

function ADS_states.aiming.transition(this, context, input)
    local track = context:getTrack(STATIC_TRACK_LINE, ADS_TRACK)
    if (input == this.INPUT_AIM_RETREAT) then
        if (context:isCrawl() or context:isCrouching()) then
            context:runAnimation("aim_end_sight", track, false, PLAY_ONCE_HOLD, 0.2)
        else
            context:runAnimation("aim_end", track, false, PLAY_ONCE_HOLD, 0.2)
        end
        context:setAnimationProgress(track, 1 - context:getAimingProgress(), true)
        return this.ADS_states.normal
    end
end

local M = {
    track_line_top = track_line_top,
    STATIC_TRACK_LINE = STATIC_TRACK_LINE,
    GUN_KICK_TRACK_LINE = GUN_KICK_TRACK_LINE,
    BLENDING_TRACK_LINE = BLENDING_TRACK_LINE,
    static_track_top = static_track_top,
    BASE_TRACK = BASE_TRACK,
    BOLT_CAUGHT_TRACK = BOLT_CAUGHT_TRACK,
    SAFETY_TRACK = SAFETY_TRACK,
    ADS_TRACK = ADS_TRACK,
    MAIN_TRACK = MAIN_TRACK,
    SPRINT_TRACK = SPRINT_TRACK,
    blending_track_top = blending_track_top,
    MOVEMENT_TRACK = MOVEMENT_TRACK,
    SLIDE_TRACK = SLIDE_TRACK,
    OVER_HEAT_TRACK = OVER_HEAT_TRACK,
    OVER_HEATING_TRACK = OVER_HEATING_TRACK,
    LOOP_TRACK = LOOP_TRACK,
    base_track_state = base_track_state,
    bolt_caught_states = bolt_caught_states,
    over_heat_states = over_heat_states,
    main_track_states = main_track_states,
    gun_kick_state = gun_kick_state,
    movement_track_states = movement_track_states,
    ADS_states = ADS_states,
    slide_states = slide_states,
    INPUT_BOLT_CAUGHT = "bolt_caught",
    INPUT_BOLT_NORMAL = "bolt_normal",
    INPUT_OVER_HEAT = "over_heat",
    INPUT_COOLING_HEAT = "cooling_heat",
    INPUT_INSPECT_RETREAT = "inspect_retreat",
    INPUT_AIM = "aim",
    INPUT_AIM_RETREAT = "aim_retreat"
}

function M:initialize(context)
    context:ensureTrackLineSize(track_line_top.value)
    context:ensureTracksAmount(STATIC_TRACK_LINE, static_track_top.value)
    context:ensureTracksAmount(BLENDING_TRACK_LINE, blending_track_top.value)
    self.movement_track_states.run.mode = -1
    self.movement_track_states.walk.mode = -1
end

function M:exit(context)
end

function M:states()
    return {
        self.base_track_state,
        self.bolt_caught_states.normal,
        self.over_heat_states.normal,
        self.main_track_states.start,
        self.gun_kick_state,
        self.movement_track_states.idle,
        self.ADS_states.aiming,
        self.slide_states.normal
    }
end

return M