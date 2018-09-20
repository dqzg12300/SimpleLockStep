---
--- 封装的客户端操作
--- Created by admin.
--- DateTime: 2018/9/7 15:34
---

package.cpath = "../luaclib/?.so;../skynet/luaclib/?.so"
package.path = "./?.lua;../lualib/?.lua"

if _VERSION ~= "Lua 5.3" then
    error "Use lua 5.3"
end

local M = {}
local protopack= require "protopackjson"
local socket = require "clientwebsocket"
local fd = nil
local cb = nil
local cbt = nil
M.stop = false
--
--
function M.connect(ip, port, recvcb, timercb)
    cb = recvcb
    cbt = timercb
    fd = assert(socket.connect(ip or "127.0.0.1", port or 11798))
end

function M.sleep(t)
    socket.usleep(t)
end


local function request(name, args)
    local str = protopack.pack(name,0,args)
    socket.send(fd,str)
    return str
end


local function recv_package()
    local r , istimeout= socket.recv(fd, 10)
    if not r then
        return nil
    end
    if r == ""  and istimeout == 0 then
        error "Server closed"
    end
    return r
end

local session = 0

function M.send(name, args)
    session = session + 1
    local str = request(name, args)
    print("Request:", session)
end

local function dispatch_package()
    while true do
        local v
        v = recv_package()
        if not v  or v == "" then
            break
        end
        if cb then
            local cmd,check,t = protopack.unpack(v)
            cb(cmd,check,t)
        else
            print("cb == nil")
        end
    end
end

function M.start()
    while true do
        if M.stop then
            break
        end
        dispatch_package()
        if cbt then
            cbt()
        end
        socket.usleep(50)
    end
end

function CallBack(cmd,check,msg)
    print("error:"..msg)
end


function M.init(ip,port,hander)
    M.connect(ip,port,hander.CallBack,hander.CallBackTimer)
end

function M.login(account,password)
    M.send("login.login", {username = account, password = password,sdkid=1})
end

function M.create_room(game_name)
    M.send("room.create_room", {game = game_name})
end

function M.enter_room(game,room_id)
    M.send("room.enter_room", {room_id=room_id,game=game})
end

function M.leave_room()
    M.send("room.leave_room",{})
end

return M
