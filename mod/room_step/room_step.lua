---
--- 斗地主的桌子逻辑处理
--- Created by admin.
--- DateTime: 2018/9/12 15:23
---

local skynet=require "skynet"
local faci=require "faci.module"
local module=faci.get_module("room_step")
local dispatch=module.dispatch
local ROOM=require "room_step.room_step_logic"

function dispatch.start(uid)
    INFO(ROOM.init)
    ROOM:init(uid)
    return SYSTEM_ERROR.success
end

function dispatch.enter(data)
    if ROOM:is_table_full() then
        log.debug("room_enter player count full")
        return false
    end
    return ROOM:enter(data)
end

function dispatch.leave(uid)
    return ROOM:leave(uid)
end

function dispatch.start_game(uid)
    return ROOM:start_game(uid)
end