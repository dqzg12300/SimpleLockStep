---
--- 客户端处理池子.玩家登录成功后的协议转发到agent,agent是从该池子中获取
--- Created by Administrator.
--- DateTime: 2018/9/2 14:20
---

local skynet=require "skynet"
local log=require "log"
require "skynet.manager"
local pool={}
local agentlist={}
local agentname
local maxnum
local recycle_poll
local CMD={}

--初始化池子,预先创建好连接的服务
function CMD.init_pool(cnf)
    agentname=cnf.agentname
    maxnum=cnf.maxnum
    recycle_poll=cnf.recycle

    for i=1, maxnum do
        local agent=skynet.newservice(agentname)
        table.insert(pool,agent)
        agentlist[agent]=agent
    end
end

--获取一个处理客户端消息的服务
function CMD.get()
    local agent=table.remove(pool)
    if not agent then
        agent=assert(skynet.newservice(agentname))
        agentlist[agent]=agent
    end
    return agent
end

--释放一个客户端消息的服务
function CMD.recycle(agent)
    assert(agent)
    if recycle_poll==1 and #pool>maxnum then
        agentlist[agent]=nil
        skynet.kill(agent)
    else
        table.insert(pool,agent)
    end
end

skynet.start(function()
    skynet.dispatch("lua",function(_,_,cmd,...)
        local f=CMD[cmd]
        if not f then
            log.warn("agentpool dispatch cmd:%s not found function",cmd)
            return
        end
        skynet.ret(skynet.pack(f(...)))
    end)
end)