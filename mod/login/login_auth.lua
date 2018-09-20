---
--- 登录校验处理
--- Created by Administrator.
--- DateTime: 2018/9/4 20:28
---
local log=require "log"
local libdbproxy = require "libdbproxy"

--sdk 列表 1为内联 2为debug
local sdk     = {
    inner       = 1,
    debug       = 2,
}

--注册,并插入到数据库
local function register(account, password)
    if not account then
        log.error("register not account" )
        return false
    end
    local ret = libdbproxy.get_accountdata(account)
    if ret then
        return false
    end

    local uid = libdbproxy.inc_uid()
    local data = {
        uid = uid,
        account = account,
        password = password,
    }
    libdbproxy.set_accountdata(account, data)
    log.info("register succ account:%s uid:%d", account,uid)
    return true, uid
end

--校验用户信息
local function check_normal_sdk(account, password)
    if not account then
        log.error("check_pw not account")
        return false
    end

    local ret = libdbproxy.get_accountdata(account)
    --登录
    if ret and ret.password == password then
        log.info("check_pw succ account:%s then login uid: %d", account, ret.uid)
        return true, ret.uid
    end
    --注册
    log.info("check_pw fail account:%s then register", account)
    local ret, uid = register(account, password)
    if ret then
        return true, uid
    end
    return false
end


local function inner_auth(openId, userdata)
    local account = userdata.username
    local password = userdata.password

    return check_normal_sdk(account, password)
end

local function debug_auth(openId, userdata)
    local appkey = "NGE8sVGVy3rvY4e6GflP3vdbCdo830qHxVa"
    local sign = md5.sumhexa(openId .. appkey)
    if sign ~= userdata then
        INFO("sign not equal userdata")
        return false
    end
    local ret = libdbproxy.get_accountsdk(openId)
    if not ret then
        INFO("not this user in db")
        return false
    end
    return true
end


local auth_handler = {
    [sdk.inner] = inner_auth,
    [sdk.debug] = debug_auth,
}

return function(sdk, userdata)
    local fc = auth_handler[sdk]
    local openId = userdata.openId or ""
    return fc(openId, userdata)
end
