---
--- 中心服逻辑处理部分
--- Created by Administrator.
--- DateTime: 2018/9/3 21:37
---

local skynet=require "skynet"
local log=require "log"
local faci=require "faci.module"
local env=require "faci.env"
local cluster=require "skynet.cluster"
local mc=require "skynet.multicast"
local dc=require "skynet.datacenter"
local module=faci.get_module("center")
local dispatch=module.dispatch
local nodename=skynet.getenv("nodename")
local channel
--初始化
env.users=env.users or {}


--中心服登录玩家信息,如果有玩家信息存在,则先登出,然后再重新登录
function dispatch.login(uid,data)
    local user=env.users[uid]
    if not user then
        log.debug("center login uid:%d success",uid)
        env.users[uid]=data
        return true
    end
    if not user.agent then
        log.debug("center login uid:%d fail,agent is nil",uid)
        return false
    end
    local isok=dispatch.logout(uid,user.key,"user on other login")
    if not isok then
        log.debug("center login uid:%d fail,logout fail",uid)
        return false
    end
    user=env.users[uid]
    if user then
        log.debug("center login uid:%d fail,logout fail",uid)
        return false
    end
    log.debug("center login uid:%d login success",uid)
    env.users[uid]=data
    return true
end

--中心服注册,实际是过来登记下.后面好广播找到对应的客户端消息处理服务
function dispatch.register(uid,data)
    local user=env.users[uid]
    if not user then
        log.debug("center register uid:%d user not found",uid)
        return false
    end
    if user.key~=data.key then
        log.debug("center register uid:%d user key err",uid)
        return false
    end
    if user.agent then
        log.debug("center register uid:%d user has agent",uid)
        return false
    end
    log.debug("center register uid:%d success",uid)
    user.agent=data.agent
    return true
end

--中心服登出
function dispatch.logout(uid,key,reason)
    local user=env.users[uid]
    if not user then
        log.debug("center logout uid:%d success",uid)
        return true
    end
    if user.key~=key then
        log.debug("center logout uid:%d fail,key err",uid)
        return false
    end
    if user.agent then
        --local isok=cluster.call(user.node,user.agent,"kick",uid,reason)
        --if not isok then
        --    log.debug("center logout uid:%d fail,kick err",uid)
        --    return false
        --end
        local isok=skynet.call(user.agent,'lua',"kick",uid,reason)
        if not isok then
            log.debug("center logout uid:%d fail,kick err",uid)
            return false
        end
    end
    log.debug("center logout uid:%d success",uid)
    env.users[uid]=nil
    return true
end

--数据统计
function dispatch.watch(acm)
    local logined=0
    local logining=0
    for i,v in pairs(env.users) do
        if v.agent then
            logined=logined+1
        else
            logining=logining+1
        end
    end
    local ret={logined=logined,logining=logining}
    acm.logined=acm.logined and acm.logined+logined or logined
    acm.logining=acm.logining and acm.logining+logining or logining
    return ret,acm
end

--广播消息给全部客户端
function dispatch.broadcast(msg)
    for i,user in pairs(env.users) do
        log.debug("broadcast to uid:%d",user.uid)
        dispatch.send2client(user.uid,msg)
    end
end

--发送给客户端,如果是当前节点,就直接发送,否则就发到对应的节点去处理
local function send(node,addr,cmd,...)
    if nodename==node then
        skynet.send(addr,"lua",cmd,...)
    else
        cluster.send(node,addr,cmd,...)
    end
end

--发送消息给指定客户端
function dispatch.send2client(uid,msg)
    local user=env.users[uid]
    if not user then
        log.debug("center send2client uid:%d not found",uid)
        return
    end
    if not user.agent then
        log.debug("center send2client uid:%d not agent",uid)
        return
    end
    send(user.node,user.agent,"send2client",msg)
end

function dispatch.multcast(msg)
    if channel then
        channel:publish(msg)
        log.debug("multcast:",msg)
    else
        log.debug("channel is nil msg:",msg)
    end
end

local function init()
    channel=mc.new()
    dc.set("multall",channel.channel)
    INFO("set channel id:"..channel.channel)
end

skynet.init(init)