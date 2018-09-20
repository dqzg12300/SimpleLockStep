---
--- 登陆并加入已经创建好的桌子
--- Created by admin.
--- DateTime: 2018/9/13 12:18
---

local client=require "tcpclient"

local Hander={}
local CMD={}
local room_id=nil
function CMD.login_loginResult(msg)
    if msg.result==0 then
        print("account:"..msg.username.." success")
        client.enter_room("ddz",room_id)
    else
        print("account:"..msg.username..",login err:",msg.result)
    end

end

function CMD.room_create_roomResult(msg)
    print("room_id:"..msg.room_id.." result:"..msg.result)
    if msg.result==0 then
        print("create room success")
        client.enter_room("ddz",msg.room_id)
    else
        print("create room err ")
    end
end

function CMD.room_enter_roomResult(msg)
    print("enter_room room_id:"..msg.room_id.." result:"..msg.result)
    if msg.result==0 then
        print("enter room success")
    else
        print("enter room err ")
    end
end

function CMD.room_flush_userdataNty(msg)
    print("cur player data")
    for i,v in pairs(msg.data) do
        print("player uid:"..v.uid..",username:"..v.username)
    end
end

function Hander.CallBack(cmd,check,msg)
    funcname=string.gsub(cmd,"%.","_")
    if CMD[funcname] then
        CMD[funcname](msg)
    else
        print("not found cmd:"..cmd)
    end
end

print("please enter room_id:")
room_id=io.read("*number")
print(room_id)

client.init("127.0.0.1",11200,Hander)
client.login("jin","111111")
client.start()


