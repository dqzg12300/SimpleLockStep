---
--- 向中心服发送请求的辅助文件
--- Created by Administrator.
--- DateTime: 2018/9/4 20:58
---

local skynet = require "skynet"

local runconf = require(skynet.getenv("runconfig"))
local servconf = runconf.service
local MAX_CENTER_COUNT = #servconf.center


local M = {}
local centers = {}

local function init()
    for i = 1, MAX_CENTER_COUNT do
        centers[i] = string.format("center%d", i)
    end
end

function M.fetch_centerd(uid)
    local id = uid % MAX_CENTER_COUNT + 1
    assert(centers[id])
    return centers[id]
end

function M.login(uid, data)
    local center = M.fetch_centerd(uid)
    return skynet.call(center, "lua", "center.login", uid, data)
end

function M.register(uid, data)
    local center = M.fetch_centerd(uid)
    return skynet.call(center, "lua", "center.register", uid, data)
end

function M.logout(uid, key)
    local center = M.fetch_centerd(uid)
    return skynet.call(center, "lua", "center.logout", uid, key)
end

function M.broadcast(cmd, ...)
    for i = 1, MAX_CENTER_COUNT do
        skynet.send(centers[i], "lua", cmd, ...)
    end
end

function M.send2client(uid, msg)
    local center = M.fetch_centerd(uid)
    skynet.call(center, "lua", "center.send2client", uid, msg)
end

function M.send2clientcmd(uid, cmd)
    local msg={}
    msg._cmd=cmd
    msg._check=0
    local center = M.fetch_centerd(uid)
    skynet.call(center, "lua", "center.send2client", uid, msg)
end

function M.broadcast2client(msg)
    M.broadcast("center.broadcast2client", msg)
end

--通过组播方式广播全部玩家
function M.broadcast2multcast(...)
    for i = 1, MAX_CENTER_COUNT do
        skynet.send(centers[i], "lua", "center.multcast", ...)
    end
end

skynet.init(init)

return M


