local default = require("tacz_manual_action_state_machine")
local STATIC_TRACK_LINE = default.STATIC_TRACK_LINE
local MAIN_TRACK = default.MAIN_TRACK
local main_track_states = default.main_track_states
local bolt_caught_states = default.bolt_caught_states
local idle_state = setmetatable({}, {__index = main_track_states.idle})
local normal_states = setmetatable({}, {__index = bolt_caught_states.normal})
local caught_states = setmetatable({}, {__index = bolt_caught_states.bolt_caught})
local reload_state = {
    need_ammo = 0,
    loaded_ammo = 0
}
local function get_ejection_time(context)
    local ejection_time = context:getStateMachineParams().intro_shell_ejecting_time
    if (ejection_time) then
        ejection_time = ejection_time * 1000
    else
        ejection_time = 0
    end
    return ejection_time
end

local function runInspectAnimation(context)
    local track = context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK)
    if (not context:hasBulletInBarrel() and context:getAmmoCount() <= 0) then
        context:runAnimation("inspect_empty", track, false, PLAY_ONCE_STOP, 0.2)
    elseif (context:getAmmoCount() <= 0) then
        context:runAnimation("inspect", track, false, PLAY_ONCE_STOP, 0.2)
    end
end

function idle_state.transition(this, context, input)
    if (input == INPUT_RELOAD) then
        return this.main_track_states.reload
    end
    if (input == INPUT_INSPECT) then
        runInspectAnimation(context)
        return this.main_track_states.inspect
    end
    return main_track_states.idle.transition(this, context, input)
end

local function isNoAmmo(context)
    return (context:getAmmoCount() <= 0)
end

function reload_state.entry(this, context)
    local state = this.main_track_states.reload
    if (isNoAmmo(context)) then
        state.timestamp = context:getCurrentTimestamp()
        state.ejection_time = get_ejection_time(context)
        context:runAnimation("reload_intro_empty", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_HOLD, 0.2)
    else
        state.timestamp = -1
        state.ejection_time = 0
        if (context:getAmmoCount() <= 3) then
            context:runAnimation("reload_into_1", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_HOLD, 0.2)
        else
            context:runAnimation("reload_into_4", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_HOLD, 0.2)
        end
    end
    state.need_ammo = context:getMaxAmmoCount() - context:getAmmoCount()
    state.loaded_ammo = 0
end
function reload_state.update(this, context)
    local state = this.main_track_states.reload
    if (state.timestamp ~= -1 and context:getCurrentTimestamp() - state.timestamp > state.ejection_time) then
        context:popShellFrom(0)
        state.timestamp = -1
    end
    if (state.loaded_ammo > state.need_ammo or not context:hasAmmoToConsume()) then
        context:trigger(this.INPUT_RELOAD_RETREAT)
    else
        local track = context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK)
        if (context:isHolding(track)) then
            if (context:getAmmoCount() == 1) then
                context:runAnimation("reload_loop_1", track, false, PLAY_ONCE_HOLD, 0)
            elseif (context:getAmmoCount() == 2) then
                context:runAnimation("reload_loop_2", track, false, PLAY_ONCE_HOLD, 0)
            elseif (context:getAmmoCount() == 3) then
                context:runAnimation("reload_loop_3", track, false, PLAY_ONCE_HOLD, 0)
            elseif (context:getAmmoCount() == 4) then
                context:runAnimation("reload_loop_4", track, false, PLAY_ONCE_HOLD, 0)
            elseif (context:getAmmoCount() == 5) then
                context:runAnimation("reload_loop_5", track, false, PLAY_ONCE_HOLD, 0)
            end
            state.loaded_ammo = state.loaded_ammo + 1
        end
    end
end

function reload_state.transition(this, context, input)
    if (input == this.INPUT_RELOAD_RETREAT or input == INPUT_CANCEL_RELOAD) then
        context:runAnimation("reload_quit", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0.2)
        return this.main_track_states.idle
    end
    return this.main_track_states.idle.transition(this, context, input)
end

local function isNoAmmo(context)
    return (context:getAmmoCount() <= 0)
end

local bolt_caught_states = {
    normal = {},
    bolt_caught = {}
}

function normal_states.entry(this, context)
    context:runAnimation("cnm", context:getTrack(STATIC_TRACK_LINE, BOLT_CAUGHT_TRACK), false, PLAY_ONCE_STOP, 0)
    return this.bolt_caught_states.normal
end


function normal_states.update(this, context)
    if (isNoAmmo(context)) then
        context:trigger(this.INPUT_BOLT_CAUGHT)
    end
    context:setAnimationProgress(context:getTrack(STATIC_TRACK_LINE, BOLT_CAUGHT_TRACK), (6.5 - context:getAmmoCount()), false)
end



local M = setmetatable({
    main_track_states = setmetatable({
        idle = idle_state,
        reload = reload_state
    }, {__index = main_track_states}),
    bolt_caught_states = setmetatable({
        bolt_caught = caught_states,
        normal = normal_states
    }, {__index = bolt_caught_states}),
    INPUT_RELOAD_RETREAT = "reload_retreat",
}, {__index = default})

function M:initialize(context)
    default.initialize(self, context)
    self.main_track_states.reload.need_ammo = 0
    self.main_track_states.reload.loaded_ammo = 0
end

return M