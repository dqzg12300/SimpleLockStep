---
--- 客户端消息处理服务.登录成功后,客户端发送的消息都将转发到该服务
--- 这里主要是封装了收发的处理。业务逻辑请看mod/agent
--- Created by Administrator.
--- DateTime: 2018/9/2 15:57
---

local skynet=require "skynet"
local log=require "log"
local protopack=require "protopack"
local env=require "faci.env"
local libsocket=require "libsocket"
local queue=require "skynet.queue"

local cmdfunc_queue=queue()
local CMD={}
local clientfd
local accountdata
require "libstring"
require "agent.agent"


--客户端消息处理服务初始化
function CMD.start(conf)
    log.debug("agent start clientfd:%d",conf.clientfd)
    clientfd=conf.clientfd
    accountdata=conf.accountdata
    return env.login(accountdata)
end

--发送消息给对应客户端
function CMD.send2client(msg)
    local cmd=msg._cmd
    local check=msg._check
    msg._cmd=nil
    msg._check=nil
    local buff=protopack.pack(cmd,check,msg)
    INFO(#buff)
    libsocket.send(clientfd,buff)
end

--与客户端连接断开时的处理
function CMD.disconnect()
    log.debug("agent cmd.disconnect account:%s logout",accountdata.account)
    env.logout(accountdata)
    return true
end

--踢出玩家的处理
function CMD.kick()
    log.debug("agent cmd.kick account:%s kick",accountdata.account)
    local kickroom=env.dispatch["kick_room"]
    if type(kickroom)=="function" then
        kickroom()
    end
    env.logout(accountdata)
    local msg={
        _cmd="room.kickNty",
        uid=accountdata.uid,
        result=0,
        reason=LOGOUT_REASON.logout_kick,
    }
    CMD.send2client(msg)
    return true
end

--发送给agent处理的消息处理
local function default_dispatch(cmd,msg)
    local f=env.dispatch[cmd]
    if type(f)~="function" then
        log.wran("agent default_dispatch cmd:%s not found",cmd)
        return
    end

    local isok,ret=xpcall(f,debug.traceback,msg)
    if isok then
        return ret
    end
end


--要转发给其他服务的消息处理
local function service_dispatch(service_name,cmd,msg)
    local service=env.service[service_name]
    if not service then
        log.wran("agent service_dispatch service_name:%s not found",service_name)
        return
    end
    local player=env.get_player()
    if not player then
        log.wran("agent service_dispatch player is nil")
        return
    end
    local uid=player.uid
    local service_id=service.service_id
    local address=service.address
    return skynet.call(address,"lua","client_forward",service_id,uid,cmd,msg)
end

--处理来自客户端的请求,如果cmd可以用.分割,则代表是要转发给其他服务的消息,否则就是agent自身处理的消息
local function dispatch(_,_,buff)
    local cmd,check,msg=protopack.unpack(buff)
    if not cmd then
        log.wran("agent dispatch cmd is nil")
        return
    end
    local cmdlist=string.split(cmd,".")
    local ret
    --if #cmdlist==2 then
    --    ret=service_dispatch(cmdlist[1],cmdlist[2],msg)
    --elseif #cmdlist==1 then
    --    ret=default_dispatch(cmd,msg)
    --end

    if #cmdlist==2 then
        ret=default_dispatch(cmdlist[2],msg)
    elseif #cmdlist==1 then
        ret=default_dispatch(cmd,msg)
    end

    if ret then
        ret._cmd=cmd.."Result"
        INFO(inspect(ret))
        CMD.send2client(ret)
    end
end

--用来接收来自客户端的请求
skynet.register_protocol{
    name="client",
    id=skynet.PTYPE_CLIENT,
    unpack=skynet.tostring,
    dispatch=dispatch,
}

--用来接收其他服务的请求
skynet.start(function()
    skynet.dispatch("lua",function(_,_,cmd,...)
        local f=CMD[cmd]
        if type(f)~="function" then
            log.wran("agent init dispatch cmd:%s not found function",cmd)
            return
        end
        skynet.retpack(cmdfunc_queue(f,...))
    end)
end)