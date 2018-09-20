---
--- 处理客户端消息,登录部分逻辑
--- Created by Administrator.
--- DateTime: 2018/9/2 20:11
---

local skynet=require "skynet"
local log=require "log"
local env=require "faci.env"
local libdbproxy = require "libdbproxy"
local hash   = require "hash"
local runconf = require(skynet.getenv("runconfig"))
local mc=require "skynet.multicast"
local dc=require "skynet.datacenter"
local player = {}
local chan

local InitPlayerCMD = {}
function InitPlayerCMD.init_baseinfo_data()
    local ret = {}
    local now = os.time()
    ret.login_time = now
    ret.register_time = now
    return ret
end

local function get_init_data(cname)
    local funname = string.format("init_%s_data", cname)
    local func = InitPlayerCMD[funname]
    assert(type(func) == "function")
    return func()
end

--[[
    baseinfo = {data = {}, hashcode = 0}
]]
local function load_data(cname, uid)
    local ret = {data=nil, hashcode=nil}
    INFO("get player data")
    INFO(cname)
    ret.data = libdbproxy.get_playerdata(cname, uid)
    ret.data = ret.data or get_init_data(cname)
    if ret.data._id then
        ret.data._id = nil
    end

    if not ret.data.uid then
        ret.data.uid = uid
    end
    return ret
end

local function load_all_data()
    local data = {}
    for k, v in pairs(runconf.playerdata) do
        data[k] = load_data(k, player.uid)
    end
    return data
end

local function save_data()
    for k, v in pairs(player.mod_datas) do
        local now_code = hash.hashcode(v.data or {})
        if not v.hashcode or  v.hashcode ~= now_code then --第一次登陆保存一次
            v.hashcode = now_code
            libdbproxy.set_playerdata(k, player.uid, v.data)
        end
    end
end

function env.get_player()
    return player
end

function env.get_playerdata()
    return player.data
end

function env.get_player_mod_data(mod)
    return player.mod_datas
end

function env.set_player_mod_data(mod, data)
    if player.mod_datas.mod then
        player.mod_datas.mod = data
    end
end

local save_tick = 10 * 100
local function check_save_data()
    skynet.timeout(save_tick, check_save_data)
    save_data()
end

local function broadcast(chan,source,data)
    INFO("broadcast:"..data)
end


function env.login(accountdata)
    -- 从数据库里加载数据
    player = {
        addr = skynet.self(),
        uid = accountdata.uid,
        accountdata = accountdata,
        mod_datas = {}
    }

    player.mod_datas = load_all_data()
    player.mod_datas.baseinfo.login_time = os.time()
    skynet.timeout(save_tick, check_save_data)
    local channel_id=dc.get("multall")
    --添加组播监听
    chan=mc.new({
        channel=channel_id,
        dispatch=broadcast,
    })
    chan:subscribe()
    INFO(channel_id)
    return true
end

function env.logout()
    save_data()
    chan:unsubscribe()

    --是否要 取消 定时保存操作？
end
