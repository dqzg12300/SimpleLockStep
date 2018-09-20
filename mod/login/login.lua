---
--- 登录服的业务逻辑处理
--- Created by Administrator.
--- DateTime: 2018/9/2 20:35
---

local skynet=require "skynet"
local log=require "log"
local faci=require "faci.module"
local login_auth=require "login.login_auth"
local libcenter=require "libcenter"
local libagentpool=require "libagentpool"

local module=faci.get_module("login")
local forward=module.forward
local key_seq = 1
local nodename=skynet.getenv("nodename")


function forward.login(fd, msg, source)
    local account = msg.username
    local msgresult={username=account,_cmd=msg._cmd,_check=msg._check}
    local sdkid=msg.sdkid
    --key
    key_seq = key_seq + 1
    local key = env.id*10000 + key_seq
    --login 校验账号密码
    local isok, uid = login_auth(sdkid,msg)
    if not isok then
        log.error("account:%s login login_auth fail",account)
        msgresult.result = AUTH_ERROR.password_wrong
        return msgresult
    end
    --center
    local data = {
        node = nodename,
        fd = fd,
        gate = source,
        key = key,
    }
    if not libcenter.login(uid, data) then
        ERROR("+++++++++++", uid, " login fail, center login +++++++++")
        log.error("account:%d login center fail",account)
        msgresult.result = AUTH_ERROR.center_fail
        return msgresult
    end
    --game
    data = {
        clientfd = fd,
        gate = source,
        accountdata = {
            uid = uid,
            account = msg.username,
            password = msg.password,
        }
    }
    local ret, agent = libagentpool.login(data)
    if not ret then
        ERROR("++++++++++++", uid, " login fail, load data err +++++++++")
        libcenter.logout(uid, key)
        msgresult.result = AUTH_ERROR.load_data_fail
        return msgresult
    end
    --center
    local data = {
        agent = agent,
        key = key,
    }
    if not libcenter.register(uid, data) then
        ERROR("++++++++++++", uid, " login fail, register center fail +++++++++")
        libcenter.logout(uid, key)
        msgresult.result =AUTH_ERROR.center_register_fail
        return msgresult
    end
    --gate
    local data = {
        uid = uid,
        fd = fd,
        agent = agent,
        key = key
    }
    if not skynet.call(source, "lua", "register", data) then
        ERROR("++++++++++++", uid, " login fail, register gate fail +++++++++")
        libcenter.logout(uid, key)
        msgresult.result = AUTH_ERROR.LOGIN_REGISTER_GATE_FILE
        return msgresult
    end
    msgresult.uid = uid
    msgresult.result = SYSTEM_ERROR.success

    INFO("++++++++++++++++login success uid:", uid, " account:"..account.."++++++++++++++++++")
    return msgresult
end