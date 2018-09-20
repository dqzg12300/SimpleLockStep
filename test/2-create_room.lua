---
--- 登陆并创建桌子的例子,创建并加入自己的桌子
--- Created by admin.
--- DateTime: 2018/9/13 12:18
---

local client=require "tcpclient"

local Hander={}
local CMD={}

function CMD.login_loginResult(msg)
    if msg.result==0 then
        print("account:"..msg.username.." success")
        client.create_room("step")
    else
        print("account:"..msg.username..",login err:",msg.result)
    end

end

function CMD.room_create_roomResult(msg)
    print("room_id:"..msg.room_id.." result:"..msg.result)
    if msg.result==0 then
        print("create room success")
        client.enter_room("step",msg.room_id)
    else
        print("create room err ")
    end
end

function CMD.room_enter_roomResult(msg)
    print("enter_room room_id:"..msg.room_id.." result:"..msg.result)
    if msg.result==0 then
        print("enter room success")
        --client.start_game()
    else
        print("enter room err ")
    end
end

function CMD.room_kickNty(msg)
    print("uid:"..msg.uid.." reason:"..msg.reason)
    if msg.result==0 then
        print("kick success")
    else
        print("create room err ")
    end
end

function CMD.room_flush_userdataNty(msg)
    print("cur player data")
    if not msg then
        print("flush err")
    end
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

client.init("127.0.0.1",11200,Hander)
client.login("king","111111")
client.start()


