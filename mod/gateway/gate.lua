---
--- 网关处理,负责分发客户端的请求给login或agent
--- Created by king.
--- DateTime: 2018/8/31 11:58
---

local skynet=require "skynet"
local gateserver=require "faci.gateserver"
local log=require "log"
local liblogin=require "liblogin"
local libagentpool=require "libagentpool"
local connect={}
local handler={}
local CMD={}
local name

--关闭客户端连接
local function close_agent(fd)
    local c=connect[fd]
    if c then
        if c.uid then
            --todo中心服退出,agentpool回收
        end
        INFO(inspect(c))
        libagentpool.recycle(c.agent)
        gateserver.closeclient(fd)
        connect[fd]=nil
    end
    return true
end

--函数执行错误时打印错误信息
local function trace_err(cmd)
    log.warn("gate command trace err cmd:%s err:%s",cmd,debug.traceback())
end

--网关启动
function handler.open(source,conf)
    log.debug("gate open name:%s start listen port:%d",conf.name,conf.port)
    name=conf.name
end

--向skynet注册消息类型
skynet.register_protocol {
    name = "client",
    id = skynet.PTYPE_CLIENT,
}


--客户端连接连接处理
function handler.connect(fd,addr)
    local c={
        fd=fd,
        addr=addr,
        uid=nil,
        agent=nil,
        key=nil
    }
    connect[fd]=c
    gateserver.openclient(fd)
    log.debug("gate connect fd:%d addr:%s",fd,addr)
end

--客户端消息处理
function handler.message(fd,msg,sz)
    local c=connect[fd]
    if not c then
        log.error("gate message fd:%d not found client",fd)
    end
    local source=skynet.self()
    local uid=c.uid
    if uid then
        log.debug("gate message redirect agent fd:%d",fd)
        skynet.redirect(c.agent,source,"client",fd,msg,sz)

    else
        local login=liblogin.fetch_login()
        log.debug("gate message redirect login fd:%d source:%s sz:%d",fd,source,sz)
        skynet.redirect(login,source,"client",fd,msg,sz)
    end
end

--连接断开处理
function handler.disconnect(fd)
    close_agent(fd)
    log.debug("gate disconnect fd:%d",fd)
end

function handler.error(fd)
    close_agent(fd)
    log.debug("gate error fd:%d",fd)
end

function handler.warning(fd,sz)
    log.warn("gate warning fd:%d sz:%d",fd,sz)
end

function handler.command(cmd,source,...)
    local f=CMD[cmd]
    if not f then
        log.warn("gate command cmd:%s not found",cmd)
        return nil
    end
    return f(source,...)
end

function CMD.register(source,data)
    INFO(inspect(data))
    local c=connect[data.fd]
    if not c then
        return false
    end
    c.uid=data.uid
    c.agent=data.agent
    c.key=data.key
    return true
end

function CMD.kick(source,fd)
    close_agent(fd)
    log.debug("gate cmd kick fd:%d",fd)
end

gateserver.start(handler)
