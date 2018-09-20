---
--- 客户端请求例子
--- Created by admin.
--- DateTime: 2018/9/7 16:00
---

local client=require "wsclient"

local Hander={}

function login_login(msg)
    print(msg.error)
    if msg.error=="login success" then
        print("account:"..msg.account.." success")
    else
        print("account:"..msg.account..",login err:",msg.error)
    end
end


function Hander.CallBack(cmd,check,msg)
    funcname=string.gsub(cmd,"%.","_")
    if _G[funcname] then
        _G[funcname](msg)
    end
end

client.init("127.0.0.1",11200,Hander)
client.login("king","111111")
client.start()


