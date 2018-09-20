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
local protopack= require "protopackpbc"
local socket = require "client.socket"
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

--打印二进制string，用于调试
local function bin2hex(s)
    s=string.gsub(s, "(.)", function (x) return string.format("%02X ", string.byte(x)) end)
    return s
end


local function dispatch_package()
    local recvstr = ""
    while true do
        local v
        v = recv_package()
        if not v  or v == "" then
            break
        end
        --粘包分包
        recvstr=recvstr..v
        if string.len(recvstr) < 2 then
            return nil
        end
        local len = string.unpack("> i2", recvstr)
        local recvlen=string.len(recvstr)-2
        while string.len(recvstr)-2 >= len do
            print("recvlen:"..recvlen..",len:"..len)
            local f = string.format("> i2 c%d", len)
            local len, str = string.unpack(f, recvstr)
            local cmd, check, msg = protopack.unpack(str)
            recvstr = string.sub(recvstr, len+1+2, string.len(recvstr))
            if cb then
                cb(cmd,check,msg)
            else
                print("cb == nil")
            end
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

function M.start_game()
    M.send("room.start_game",{})
end

return M
