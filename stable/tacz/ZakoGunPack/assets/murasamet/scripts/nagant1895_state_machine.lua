local track_line_top = {value = 0}
local static_track_top = {value = 0}
local blending_track_top = {value = 0}

local function increment(obj)
    obj.value = obj.value + 1
    return obj.value - 1
end

local FIRE_MODE_TRACK = increment(static_track_top)
local SWITCH_MODE_TRACK = increment(static_track_top)
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
local LOOP_TRACK = increment(blending_track_top)
local SLIDE_TRACK = increment(blending_track_top)

local function runPutAwayAnimation(context)
    local put_away_time = context:getPutAwayTime()
    local track = context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK)
    context:runAnimation("put_away", track, false, PLAY_ONCE_HOLD, put_away_time * 0.75)
    context:setAnimationProgress(track, 1, true)
    context:adjustAnimationProgress(track, -put_away_time, false)
end

local function isNoAmmo(context)
    return (not context:hasBulletInBarrel()) and (context:getAmmoCount() <= 0)
end

local function runReloadAnimation(context)
    local track = context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK)
    if (isNoAmmo(context)) then
        context:runAnimation("reload_start_empty", track, false, PLAY_ONCE_HOLD, 0)
    else
        context:runAnimation("reload_start", track, false, PLAY_ONCE_HOLD, 0)
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

local base_track_state = {}

function base_track_state.entry(this, context)
    if (context:getAttachment("SCOPE") == "murasamet:scope_mosin_pu") then
        context:runAnimation("static_idle_pu", context:getTrack(STATIC_TRACK_LINE, BASE_TRACK), false, LOOP, 0)
    else
        context:runAnimation("static_idle", context:getTrack(STATIC_TRACK_LINE, BASE_TRACK), false, LOOP, 0)
    end
end

local bolt_caught_states = {
    normal = {},
    bolt_caught = {}
}

function bolt_caught_states.normal.update(this, context)
    if (isNoAmmo(context) and context:getFireMode() == SEMI) then
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
    if (input == this.INPUT_BOLT_NORMAL or context:getFireMode() == AUTO) then
        context:stopAnimation(context:getTrack(STATIC_TRACK_LINE, BOLT_CAUGHT_TRACK))
        return this.bolt_caught_states.normal
    end
end

local main_track_states = {
    start = {},
    idle = {},
    reload = {
        retreat = "reload_retreat",
        need_ammo = 0,
        loaded_ammo = 0,
        emptyload = 0
    },
    inspect = {
        retreat = "inspect_retreat"
    },
    final = {},
    bayonet_counter = 0
}

function main_track_states.start.transition(this, context, input)
    if (input == INPUT_DRAW) then
        context:runAnimation("draw", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0)
        return main_track_states.idle
    end
end

function main_track_states.idle.transition(this, context, input)
    if (input == INPUT_PUT_AWAY) then
        runPutAwayAnimation(context)
        return main_track_states.final
    end
    if (input == INPUT_RELOAD) then
        return main_track_states.reload
    end
    if (input == INPUT_BOLT) then
        context:runAnimation("bolt", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0.2)
        return this.main_track_states.idle
    end
    if (input == INPUT_INSPECT) then
        runInspectAnimation(context)
        return main_track_states.inspect
    end
    if (input == INPUT_BAYONET_MUZZLE) then
        local counter = main_track_states.bayonet_counter
        local animationName = "melee_bayonet_" .. tostring(counter + 1)
        main_track_states.bayonet_counter = (counter + 1) % 3
        context:runAnimation(animationName, context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0.2)
        return main_track_states.idle
    end
    if (input == INPUT_BAYONET_STOCK) then
        context:runAnimation("melee_stock", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0.2)
        return main_track_states.idle
    end
    if (input == INPUT_BAYONET_PUSH) then
        context:runAnimation("melee_push", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0.2)
        return main_track_states.idle
    end
end

function main_track_states.reload.entry(this, context)
    if (isNoAmmo(context)) then
        main_track_states.reload.emptyload = 1
        if (context:getAttachment("SCOPE") == "murasamet:scope_mosin_pu") then
            context:runAnimation("reload_start_with_scope_empty", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_HOLD, 0.2)
        else
            context:runAnimation("reload_start_clip", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_HOLD, 0.2)
        end
    elseif(context:getAmmoCount() == 0) then
        if (context:getAttachment("SCOPE") == "murasamet:scope_mosin_pu") then
            context:runAnimation("reload_start_with_scope", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_HOLD, 0.2)
        else
            context:runAnimation("reload_start", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_HOLD, 0.2)
        end
    else
        if (context:getAttachment("SCOPE") == "murasamet:scope_mosin_pu") then
            context:runAnimation("reload_start_with_scope", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_HOLD, 0.2)
        else
            context:runAnimation("reload_start", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_HOLD, 0.2)
        end
    end
    main_track_states.reload.need_ammo = context:getMaxAmmoCount() - context:getAmmoCount()
    main_track_states.reload.loaded_ammo = 0
    if(context:hasBulletInBarrel())then
        main_track_states.reload.loaded_ammo = main_track_states.reload.loaded_ammo + 1
    end
end


function main_track_states.reload.update(this, context)
    if (main_track_states.reload.loaded_ammo > main_track_states.reload.need_ammo or not context:hasAmmoToConsume()) then
        context:trigger(main_track_states.reload.retreat)
    else
        local track = context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK)
        if(context:isHolding(track)) then
            if(main_track_states.reload.emptyload == 1 and context:getAttachment("SCOPE") ~= "murasamet:scope_mosin_pu") then
                if (main_track_states.reload.loaded_ammo ~= 7) then
                    context:runAnimation("reload_load_clip", track, false, PLAY_ONCE_HOLD, 0.2)
                    main_track_states.reload.loaded_ammo = main_track_states.reload.loaded_ammo + 7
                else
                    context:runAnimation("reload_loop", track, false, PLAY_ONCE_HOLD, 0.2)
                    main_track_states.reload.loaded_ammo = main_track_states.reload.loaded_ammo + 1
                end
            else
                if (context:getAttachment("SCOPE") == "murasamet:scope_mosin_pu") then
                    if (context:getAmmoCount() == 0) and (context:hasBulletInBarrel() == false) then
                        context:runAnimation("reload_loop_with_scope_empty", track, false, PLAY_ONCE_HOLD, 0.2)
                    else
                        context:runAnimation("reload_loop_with_scope", track, false, PLAY_ONCE_HOLD, 0.2)
                    end
                else
                    if (math.random(100) >= 50) then
                        context:runAnimation("reload_loop", track, false, PLAY_ONCE_HOLD, 0.2)
                    else
                        context:runAnimation("reload_loop2", track, false, PLAY_ONCE_HOLD, 0.2)
                    end
                end
                main_track_states.reload.loaded_ammo = main_track_states.reload.loaded_ammo + 1
            end
        end
    end
end

function main_track_states.reload.transition(this, context, input)
    if (input == main_track_states.reload.retreat or input == INPUT_CANCEL_RELOAD) then
        if(main_track_states.reload.emptyload == 1 and context:getAttachment("SCOPE") ~= "murasamet:scope_mosin_pu") then
            context:runAnimation("reload_end_clip", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0.2)
            main_track_states.reload.emptyload = 0
        else
            if (context:getAttachment("SCOPE") == "murasamet:scope_mosin_pu") then
                context:runAnimation("reload_end_with_scope", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0.2)
            else
                context:runAnimation("reload_end", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0.2)
            end
        end
        return main_track_states.idle
    end
    return this.main_track_states.idle.transition(this, context, input)
end


function main_track_states.inspect.entry(this, context)
    context:setShouldHideCrossHair(true)
end

function main_track_states.inspect.exit(this, context)
    context:setShouldHideCrossHair(false)
end

function main_track_states.inspect.update(this, context)
    if (context:isStopped(context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK))) then
        context:trigger(main_track_states.inspect.retreat)
    end
end

function main_track_states.inspect.transition(this, context, input)
    if (input == main_track_states.inspect.retreat) then
        return main_track_states.idle
    end
    if (input == INPUT_SHOOT) then
        context:stopAnimation(context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK))
        return main_track_states.idle
    end
    return main_track_states.idle.transition(context, input)
end

local gun_kick_state = {}

function gun_kick_state.transition(this, context, input)
    if (input == INPUT_SHOOT) then
        local track = context:findIdleTrack(GUN_KICK_TRACK_LINE, false)
        if (context:getFireMode() == SEMI) then
            if ((context:getAttachment("MUZZLE") == "tacz:muzzle_silencer_mirage") or (context:getAttachment("MUZZLE") == "tacz:muzzle_silencer_ptilopsis")) then
                context:runAnimation("shoot_single_action_silencer", track, true, PLAY_ONCE_STOP, 0)
            else
                context:runAnimation("shoot_single_action", track, true, PLAY_ONCE_STOP, 0)
            end
            context:runAnimation("bolt", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0.2)
        else
            if ((context:getAttachment("MUZZLE") == "tacz:muzzle_silencer_mirage") or (context:getAttachment("MUZZLE") == "tacz:muzzle_silencer_ptilopsis")) then
                context:runAnimation("shoot_double_action_silencer", track, true, PLAY_ONCE_STOP, 0)
            else
                context:runAnimation("shoot_double_action", track, true, PLAY_ONCE_STOP, 0)
            end
        end
    end
    return nil
end

local fire_mode_state = {
    semi = {},
    burst = {},
    auto = {},
    draw = {}
}

function fire_mode_state.draw.update(this, context)
    context:trigger(this.INPUT_MODE_DRAW)
end

function fire_mode_state.draw.transition(this, context,input)
    if (input == this.INPUT_MODE_DRAW) then
        if (context:getFireMode() == SEMI) then
            context:runAnimation("static_semi", context:getTrack(STATIC_TRACK_LINE, FIRE_MODE_TRACK), true, PLAY_ONCE_HOLD, 0)
            return fire_mode_state.semi
        elseif (context:getFireMode() == BURST) then
            context:runAnimation("static_burst", context:getTrack(STATIC_TRACK_LINE, FIRE_MODE_TRACK), true, PLAY_ONCE_HOLD, 0)
            return fire_mode_state.burst
        end
    end
end

function fire_mode_state.semi.update(this, context)
    local track = context:getTrack(STATIC_TRACK_LINE, FIRE_MODE_TRACK)
    if (context:isHolding(track)) then
        context:runAnimation("static_semi", track, true, PLAY_ONCE_HOLD, 0)
    end
    if (context:getFireMode() == BURST) then
        context:trigger(this.INPUT_MODE_BURST)
    end
end
function fire_mode_state.semi.transition(this, context,input)
    if(input == this.INPUT_MODE_BURST)then
        context:runAnimation("switch_burst", context:getTrack(STATIC_TRACK_LINE, SWITCH_MODE_TRACK), false, PLAY_ONCE_STOP, 0)
        return fire_mode_state.burst
    end
    if(input == INPUT_SHOOT)then
        context:stopAnimation(context:getTrack(STATIC_TRACK_LINE, SWITCH_MODE_TRACK))
    end
    if(input == INPUT_RELOAD)then
        context:stopAnimation(context:getTrack(STATIC_TRACK_LINE, SWITCH_MODE_TRACK))
    end
    if(input == INPUT_INSPECT)then
        context:stopAnimation(context:getTrack(STATIC_TRACK_LINE, SWITCH_MODE_TRACK))
    end
end
function fire_mode_state.burst.update(this, context)
    local track = context:getTrack(STATIC_TRACK_LINE, FIRE_MODE_TRACK)
    if (context:isHolding(track)) then
        context:runAnimation("static_burst", track, true, PLAY_ONCE_HOLD, 0)
    end
    if (context:getFireMode() == SEMI) then
        context:trigger(this.INPUT_MODE_SEMI)
    end
end
function fire_mode_state.burst.transition(this, context,input)
    if(input == this.INPUT_MODE_SEMI)then
        context:runAnimation("switch_semi", context:getTrack(STATIC_TRACK_LINE, SWITCH_MODE_TRACK), false, PLAY_ONCE_STOP, 0)
        return fire_mode_state.semi
    end

    if(input == INPUT_SHOOT)then
        context:stopAnimation(context:getTrack(STATIC_TRACK_LINE, SWITCH_MODE_TRACK))
    end
    if(input == INPUT_RELOAD)then
        context:stopAnimation(context:getTrack(STATIC_TRACK_LINE, SWITCH_MODE_TRACK))
    end
    if(input == INPUT_INSPECT)then
        context:stopAnimation(context:getTrack(STATIC_TRACK_LINE, SWITCH_MODE_TRACK))
    end
end

local movement_track_states = {
    idle = {},
    run = {
        mode = -1
    },
    walk = {
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
        return movement_track_states.run
    elseif (input == INPUT_WALK) then
        return movement_track_states.walk
    end
end

function movement_track_states.run.entry(this, context)
    movement_track_states.run.mode = -1
    context:runAnimation("run_start", context:getTrack(BLENDING_TRACK_LINE, MOVEMENT_TRACK), true, PLAY_ONCE_HOLD, 0.2)
end

function movement_track_states.run.exit(this, context)
    context:runAnimation("run_end", context:getTrack(BLENDING_TRACK_LINE, MOVEMENT_TRACK), true, PLAY_ONCE_HOLD, 0.3)
end

function movement_track_states.run.update(this, context)
    local track = context:getTrack(BLENDING_TRACK_LINE, MOVEMENT_TRACK)
    local state = movement_track_states.run;
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
        return movement_track_states.idle
    elseif (input == INPUT_WALK) then
        return movement_track_states.walk
    end
end

function movement_track_states.walk.entry(this, context)
    movement_track_states.walk.mode = -1
end

function movement_track_states.walk.exit(this, context)
    context:runAnimation("idle", context:getTrack(BLENDING_TRACK_LINE, MOVEMENT_TRACK), true, PLAY_ONCE_HOLD, 0.4)
end

function movement_track_states.walk.update(this, context)
    local track = context:getTrack(BLENDING_TRACK_LINE, MOVEMENT_TRACK)
    local state = movement_track_states.walk
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
        return movement_track_states.idle
    elseif (input == INPUT_RUN) then
        return movement_track_states.run
    end
end

local slide_states = {
    normal = {},
    slide = {}
}

function slide_states.normal.transition(this, context, input)
    if(context:shouldSlide() and context:isStopped(context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK)) and not context:isAiming()) then
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
    if(not context:shouldSlide() or not context:isStopped(context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK)) or context:isAiming()) then
        return this.slide_states.normal
    end
end

function slide_states.slide.exit(this, context)
    context:runAnimation("slide_back", context:getTrack(BLENDING_TRACK_LINE, SLIDE_TRACK), true, PLAY_ONCE_HOLD, 0.2)
end

local M = {
    track_line_top = track_line_top,
    STATIC_TRACK_LINE = STATIC_TRACK_LINE,
    GUN_KICK_TRACK_LINE = GUN_KICK_TRACK_LINE,
    BLENDING_TRACK_LINE = BLENDING_TRACK_LINE,
    SPRINT_TRACK = SPRINT_TRACK,
    static_track_top = static_track_top,
    BASE_TRACK = BASE_TRACK,
    BOLT_CAUGHT_TRACK = BOLT_CAUGHT_TRACK,
    SAFETY_TRACK = SAFETY_TRACK,
    ADS_TRACK = ADS_TRACK,
    MAIN_TRACK = MAIN_TRACK,
    blending_track_top = blending_track_top,
    MOVEMENT_TRACK = MOVEMENT_TRACK,
    SLIDE_TRACK = SLIDE_TRACK,
    LOOP_TRACK = LOOP_TRACK,
    base_track_state = base_track_state,
    bolt_caught_states = bolt_caught_states,
    main_track_states = main_track_states,
    gun_kick_state = gun_kick_state,
    movement_track_states = movement_track_states,
    slide_states = slide_states,
    INPUT_BOLT_CAUGHT = "bolt_caught",
    INPUT_BOLT_NORMAL = "bolt_normal",
    INPUT_INSPECT_RETREAT = "inspect_retreat",
    FIRE_MODE_TRACK = FIRE_MODE_TRACK,
    SWITCH_MODE_TRACK = SWITCH_MODE_TRACK,
    INPUT_MODE_SEMI = "input_mode_semi",
    INPUT_MODE_BURST = "input_mode_burst",
    INPUT_MODE_AUTO = "input_mode_auto",
    INPUT_MODE_DRAW = "input_mode_draw",
    fire_mode_state = fire_mode_state
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
        self.main_track_states.start,
        self.gun_kick_state,
        self.movement_track_states.idle,
        self.fire_mode_state.draw,
        self.slide_states.normal
    }
end

return M