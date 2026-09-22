-- 脚本的位置是 "{命名空间}:{路径}"，那么 require 的格式为 "{命名空间}_{路径}"
-- 注意！require 取得的内容不应该被修改，应仅调用
local default = require("murasamet_qisiwoleqisiwoleqisiwole")
local GUN_KICK_TRACK_LINE = default.GUN_KICK_TRACK_LINE
local STATIC_TRACK_LINE = default.STATIC_TRACK_LINE
local MAIN_TRACK = default.MAIN_TRACK
local BOLT_CAUGHT_TRACK = default.BOLT_CAUGHT_TRACK
local main_track_states = default.main_track_states
local bolt_caught_states = default.bolt_caught_states
local normal_states = setmetatable({}, {__index = bolt_caught_states.normal})
local idle_state = setmetatable({}, {__index = main_track_states.idle})

local gun_kick_state = setmetatable({}, {__index = default.gun_kick_state})

local reload_state = {
    need_round = 0,
    loaded_round = 0
}

function gun_kick_state.transition(this, context, input)
    if (input == INPUT_SHOOT) then
        local track = context:findIdleTrack(GUN_KICK_TRACK_LINE, false)
        if ((context:getAmmoCount() - 1) % 5 == 0) then
            context:runAnimation("shoot_clip", track, true, PLAY_ONCE_STOP, 0)
        else
            context:runAnimation("shoot", track, true, PLAY_ONCE_STOP, 0)
        end
    end
    return nil
end

function normal_states.entry(this, context)
    context:runAnimation("you_are_making_a_big_mistake", context:getTrack(STATIC_TRACK_LINE, BOLT_CAUGHT_TRACK), false, PLAY_ONCE_STOP, 0)
    return this.bolt_caught_states.normal
end

local function isNoAmmo(context)
    return (context:getAmmoCount() <= 0)
end

function normal_states.update(this, context)
    if (isNoAmmo(context)) then
        context:trigger(this.INPUT_BOLT_CAUGHT)
    end
    context:setAnimationProgress(context:getTrack(STATIC_TRACK_LINE, BOLT_CAUGHT_TRACK), 6.1 - context:getAmmoCount()/5, false)
end

local function runInspectAnimation(context)
    local track = context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK)
    context:runAnimation("inspect", track, false, PLAY_ONCE_STOP, 0.2)
end

-- 重写 idle 状态的 transition 函数，将输入 INPUT_RELOAD 重定向到新定义的 reload_state 状态
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
-- 在 entry 函数里，我们根据情况选择播放 'reload_intro_empty' 或 'reload_intro' 动画，
-- 并初始化 需要的弹药数、已装填的弹药数。这决定了后续的 'loop' 动画进行几次循环。
function reload_state.entry(this, context)
    local state = this.main_track_states.reload
    local isNoAmmo = not context:hasBulletInBarrel()
    state.need_round = ((30 - context:getAmmoCount()) - (30 - context:getAmmoCount()) % 5) / 5
    state.loaded_round = 0
    state.loading_round = 7 - state.need_round
    if (context:getAmmoCount() <= 0) then
        reload_state.emptyload = 1
    else
        reload_state.emptyload = 0
    end
    if (state.loading_round == 1) then
        context:runAnimation("reload_intro1", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_HOLD, 0.2)
    elseif (state.loading_round == 2) then
        context:runAnimation("reload_intro2", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_HOLD, 0.2)
    elseif (state.loading_round == 3) then
        context:runAnimation("reload_intro3", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_HOLD, 0.2)
    elseif (state.loading_round == 4) then
        context:runAnimation("reload_intro4", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_HOLD, 0.2)
    elseif (state.loading_round == 5) then
        context:runAnimation("reload_intro5", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_HOLD, 0.2)
    elseif (state.loading_round == 6) then
        context:runAnimation("reload_intro6", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_HOLD, 0.2)
    else
        context:runAnimation("reload_intro7", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_HOLD, 0.2)
    end
end
-- 在 update 函数里，循环播放 loop，让 loaded_round 变量自增。
function reload_state.update(this, context)
    local state = this.main_track_states.reload
    if (state.loaded_round > state.need_round or not context:hasAmmoToConsume()) then
        context:trigger(this.INPUT_RELOAD_RETREAT)
    else
        local track = context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK)
        if (context:isHolding(track)) then
            if (state.loading_round == 1) then
                context:runAnimation("reload_loop1", track, false, PLAY_ONCE_HOLD, 0)
            elseif (state.loading_round == 2) then
                context:runAnimation("reload_loop2", track, false, PLAY_ONCE_HOLD, 0)
            elseif (state.loading_round == 3) then
                context:runAnimation("reload_loop3", track, false, PLAY_ONCE_HOLD, 0)
            elseif (state.loading_round == 4) then
                context:runAnimation("reload_loop4", track, false, PLAY_ONCE_HOLD, 0)
            elseif (state.loading_round == 5) then
                context:runAnimation("reload_loop5", track, false, PLAY_ONCE_HOLD, 0)
            elseif (state.loading_round == 6) then
                context:runAnimation("reload_loop6", track, false, PLAY_ONCE_HOLD, 0)
            end
            state.loading_round = state.loading_round + 1
            state.loaded_round = state.loaded_round + 1
        end
    end
end
-- 如果 loop 循环结束或者换弹被打断，退出到 idle 状态。否则由 idle 的 transition 函数决定下一个状态。
function reload_state.transition(this, context, input)
    local manbaout = 7 - ((30 - context:getAmmoCount()) - (30 - context:getAmmoCount()) % 5) / 5
    if (input == this.INPUT_RELOAD_RETREAT or input == INPUT_CANCEL_RELOAD) then
        if (manbaout == 6) then
            context:runAnimation("reload_end_6", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0.2)
        elseif (manbaout == 5) then
            context:runAnimation("reload_end_5", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0.2)
        elseif (manbaout == 4) then
            context:runAnimation("reload_end_4", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0.2)
        elseif (manbaout == 3) then
            context:runAnimation("reload_end_3", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0.2)
        elseif (manbaout == 2) then
            context:runAnimation("reload_end_2", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0.2)
        elseif (manbaout == 1) then
            context:runAnimation("reload_end_1", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0.2)
        else
            context:runAnimation("reload_end_7", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0.2)
        end
        if (reload_state.emptyload == 1) then
            context:runAnimation("end_bolt", context:findIdleTrack(GUN_KICK_TRACK_LINE, false), true, PLAY_ONCE_STOP, 0)
        else
            context:runAnimation("empty", context:findIdleTrack(GUN_KICK_TRACK_LINE, false), true, PLAY_ONCE_STOP, 0)
        end
        reload_state.emptyload = 0
        return this.main_track_states.idle
    end
    return this.main_track_states.idle.transition(this, context, input)
end
-- 用元表的方式继承默认状态机的属性
local M = setmetatable({
    main_track_states = setmetatable({
        -- 自定义的 idle 状态需要覆盖掉父级状态机的对应状态，新建的 reload 状态也要加进来
        idle = idle_state,
        reload = reload_state
    }, {__index = main_track_states}),
    bolt_caught_states = setmetatable({
        bolt_caught = caught_states,
        normal = normal_states
    }, {__index = bolt_caught_states}),
    gun_kick_state = gun_kick_state,
    INPUT_RELOAD_RETREAT = "reload_retreat",
}, {__index = default})
-- 先调用父级状态机的初始化函数，然后进行自己的初始化
function M:initialize(context)
    default.initialize(self, context)
    self.main_track_states.reload.need_round = 0
    self.main_track_states.reload.loaded_round = 0
end
-- 导出状态机
return M