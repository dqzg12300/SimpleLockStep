---
--- 给login服务发送消息的辅助文件,由于login服务可能会开启多个,所以这里要辅助文件来取一个login服发送
--- Created by Administrator.
--- DateTime: 2018/9/2 20:41
---

local skynet=require "skynet"
local log=require "log"
local runconfig=require(skynet.getenv("runconfig"))
local serconfig=runconfig.service
local nodename=skynet.getenv("nodename")

local M={}
local login_services={}
local login_num=0
local next_id=1

local function init()
    for i,v in pairs(serconfig.login) do
        if v.node==nodename then
            local name=string.format("login%d",i)
            table.insert(login_services,name)
            login_num=login_num+1
            log.info("liblogin init %s",name)
        end
    end
end

--获取一个login服务.
function M.fetch_login()
    next_id=next_id%login_num+1
    return login_services[next_id]
end

skynet.init(init)

return M