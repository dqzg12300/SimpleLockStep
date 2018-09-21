---
--- 斗地主的场景逻辑
--- Created by admin.
--- DateTime: 2018/9/12 11:56
---
local skynet=require "skynet"
local faci=require "faci.module"
local libdbproxy=require "libdbproxy"
local module=faci.get_module("scene_step")
local dispatch=module.dispatch

--key id,value addr
local ROOM_MAP={}

--重用0人的桌子
local function get_room()
    for i,v in pairs(ROOM_MAP) do
        if v.count==0 then
            return i
        end
    end
end

function dispatch.create_room(uid)
    local room_id=get_room()
    if room_id then
        return room_id
    end
    local room_id=libdbproxy.inc_room()
    local addr=skynet.newservice("room_step","room_step",room_id)
    ROOM_MAP[room_id]={
        addr=addr,
        count=0
    }
    skynet.call(addr,"lua","room_step.start",uid)
    INFO("scene_step create_room room_id:"..room_id)
    return room_id
end

function dispatch.enter_room(room_id,data)
    INFO("scene_step enter_room")
    local roomItem=ROOM_MAP[room_id]
    if not roomItem then
        log.debug("enter_room not found room_id:%d",room_id)
        return DESK_ERROR.room_not_found
    end
    roomItem.count=roomItem.count+1
    return skynet.call(roomItem.addr,"lua","room_step.enter",data)
end

function dispatch.leave_room(room_id,uid)
    INFO("scene_step leave_room")
    local roomItem=ROOM_MAP[room_id]
    if not roomItem then
        log.debug("enter_room not found room_id:%d",room_id)
        return DESK_ERROR.room_not_found
    end
    roomItem.count=roomItem.count-1
    return skynet.call(roomItem.addr,"lua","room_step.leave",uid)
end

function dispatch.start_game(room_id,uid)
    INFO("scene_step start_game")
    local roomItem=ROOM_MAP[room_id]
    if not roomItem then
        log.debug("enter_room not found room_id:%d",room_id)
        return DESK_ERROR.room_not_found
    end
    return skynet.call(roomItem.addr,"lua","room_step.start_game",uid)
end

function dispatch.frame(room_id,msg)
    INFO("frame start_game")
    local roomItem=ROOM_MAP[room_id]
    if not roomItem then
        log.debug("enter_room not found room_id:%d",room_id)
        return DESK_ERROR.room_not_found
    end
    return skynet.call(roomItem.addr,"lua","room_step.frame",msg)
end
