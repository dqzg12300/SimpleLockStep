local skynet = require "skynet"
local log = require "log"

local runconf = require(skynet.getenv("runconfig"))
local servconf = runconf.service
local MAX_DBPROXY_COUNT = #servconf.dbproxy

local M = {}
local dbproxy = {}

local function init()
    for i = 1, MAX_DBPROXY_COUNT do
        dbproxy[i] = string.format("dbproxy%d", i) 
    end
end

local next_id = 0
local function next_dbproxy()
    next_id = next_id + 1
    if next_id > MAX_DBPROXY_COUNT then
        next_id = 1
    end
    return dbproxy[next_id]
end

function M.get_accountdata(account)
    local db = next_dbproxy()
    return skynet.call(db, "lua", "dbproxy.get", "account", "account", {account=account})
end

function M.set_accountdata(account, update)
    local db = next_dbproxy()
    return skynet.call(db, "lua", "dbproxy.set", "account", "account", {account=account}, update)
end


function M.get_playerdata(cname, uid)
    local db = next_dbproxy()
    return skynet.call(db, "lua", "dbproxy.get", "game", cname, {uid=uid})
end

function M.set_playerdata(cname, uid, update)
    local db = next_dbproxy()
    return skynet.call(db, "lua", "dbproxy.set", "game", cname, {uid=uid}, update)
end

function M.get_globaldata(cname, key)
    local db = next_dbproxy()
    return skynet.call(db, "lua", "dbproxy.get", "global", cname, {name=key})
end

function M.set_globaldata(cname, key, update)
    local db = next_dbproxy()
    return skynet.call(db, "lua", "dbproxy.set", "global", cname, {name=key}, update)
end

function M.add_dblog(cname, data)
    local db = next_dbproxy()
    return skynet.call(db, "lua", "dbproxy.insert", "log", cname, data)
end

local function inc_uid_cname(cname)
    local db = next_dbproxy()
    return skynet.call(db, "lua", "dbproxy.incr", cname)
end

function M.inc_uid()
    return inc_uid_cname("account")
end

function M.inc_room()
    return inc_uid_cname("roomid")
end


skynet.init(init)

return M


