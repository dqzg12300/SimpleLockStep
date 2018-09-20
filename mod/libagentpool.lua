---
--- 客户端处理池子的辅助通道.具体逻辑看service/agent/agentpool
--- Created by Administrator.
--- DateTime: 2018/9/2 13:59
---

local skynet=require "skynet"
local runconfig=require(skynet.getenv("runconfig"))
local serconfig=runconfig.service

local M={}

local function get()
    local pool=serconfig.agent_pool.name
    return skynet.call(pool,"lua","get")
end

function M.recycle(agent)
    local pool=serconfig.agent_pool.name
    return skynet.call(pool,"lua","recycle",agent)
end

function M.login(data)
    local agent=get()
    local isok=skynet.call(agent,"lua","start",data)
    return isok,agent
end

return M