---
--- 斗地主的场景逻辑
--- Created by admin.
--- DateTime: 2018/9/12 11:56
---
local skynet=require "skynet"
local faci=require "faci.module"
local libdbproxy=require "libdbproxy"
local module=faci.get_module("scene_ddz")
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

function dispatch.create_room()
    local room_id=get_room()
    if room_id then
        return room_id
    end
    local room_id=libdbproxy.inc_room()
    local addr=skynet.newservice("room_ddz","room_ddz",room_id)
    ROOM_MAP[room_id]={
        addr=addr,
        count=0
    }
    skynet.call(addr,"lua","room_ddz.start")
    INFO("scene_ddz create_room room_id:"..room_id)
    return room_id
end

function dispatch.enter_room(room_id,data)
    INFO("scene_ddz enter_room")
    local roomItem=ROOM_MAP[room_id]
    if not roomItem then
        log.debug("enter_room not found room_id:%d",room_id)
        return DESK_ERROR.room_not_found
    end
    roomItem.count=roomItem.count+1
    return skynet.call(roomItem.addr,"lua","room_ddz.enter",data)
end

function dispatch.leave_room(room_id,uid)
    INFO("scene_ddz leave_room")
    local roomItem=ROOM_MAP[room_id]
    if not roomItem then
        log.debug("enter_room not found room_id:%d",room_id)
        return DESK_ERROR.room_not_found
    end
    roomItem.count=roomItem.count-1
    return skynet.call(roomItem.addr,"lua","room_ddz.leave",uid)
end
