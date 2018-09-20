---
--- 处理客户端进房逻辑部分
--- Created by Administrator.
--- DateTime: 2018/9/2 20:06
---

local skynet=require "skynet"
local log=require "log"
local env=require "faci.env"
local runconfig=require(skynet.getenv("runconfig"))
local games_common=runconfig.games_common

local M=env.dispatch
local libmodules={}
local function init_modules()
    setmetatable(libmodules, {
        __index = function(t, k)
            local mod = games_common[k]
            if not mod then
                return nil
            end
            local v = require(mod)
            t[k] = v
            return v
        end
    })
end
init_modules()

local function cal_lib(game)
    return assert(libmodules[game])
end

local room_id=nil
local lib=nil

--创建房间逻辑
function M.create_room(msg)
    INFO("agent create_room")
    if lib or room_id then
        --踢出房间
    end
    lib=cal_lib(msg.game)
    local player=env.get_player()
    local rid=lib.create_room(player.uid)
    local ack={}
    ack.result=0
    ack.room_id=rid
    return ack
end

--进入房间逻辑
function M.enter_room(msg)
    INFO("agent enter_room room_id:"..msg.room_id)
    if room_id then
        --踢出房间
    end
    lib=cal_lib(msg.game)
    local player=env.get_player()
    local uid=player.uid
    local data={
        uid=uid,
        agent=player.agent,
        account=player.accountdata.account,
    }
    local ret=lib.enter_room(msg.room_id,data)
    if ret==0 then
        room_id=msg.room_id
    end

    local ack={
        room_id=msg.room_id,
        result=ret,
    }
    return ack
end

--离开房间逻辑
function M.leave_room(msg)
    INFO("agent leave_room")
    if not lib then
        INFO("leave_room not found lib")
        return {result=0}
    end
    if not room_id then
        INFO("leave_room not found room_id")
        return {result=0}
    end
    local uid=env.get_player().uid
    local ret=lib.leave_room(room_id,uid)
    local ack={
        result=ret,
    }
    return ack
end

--踢出房间逻辑
function M.kick_room()
    local ret=M.leave_room()
    local ack={
        result=ret,
    }
    return ack
end
