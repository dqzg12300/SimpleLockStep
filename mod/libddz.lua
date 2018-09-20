---
--- 访问ddz场景的帮助文件
--- Created by admin.
--- DateTime: 2018/9/13 11:31
---

local skynet=require "skynet"


local runconf = require(skynet.getenv("runconfig"))
local moveconf = runconf.ddz
local MAX_GLOBAL_COUNT = #moveconf.global


local function fetch_global(id)
    local index = id % MAX_GLOBAL_COUNT + 1
    return moveconf.global[index]
end

local function call(cmd, id, ...)
    local global = fetch_global(id)
    if not global then
        ERROE("cmd:"..cmd..",id:"..id.." is nil")
        return false
    end
    return skynet.call(global, "lua", cmd, id, ...)
end


local M={}

function M.create_room(uid)
    return call("scene_ddz.create_room",uid)
end

function M.enter_room(room_id,data)
    return call("scene_ddz.enter_room",room_id,data)
end

function M.leave_room(room_id,uid)
    return call("scene_ddz.leave",room_id,uid)
end


return M