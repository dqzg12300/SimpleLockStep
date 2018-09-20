local skynet=require "skynet"
local tool=require "tool"

local runconfig=require(skynet.getenv("runconfig"))
local dbconf=runconfig.service.dbproxy_common

local faci=require "faci.module"
local module=faci.get_module("dbproxy")

local dispatch=module.dispatch
local forward=module.forward
local event=module.event

local db={
	["account"]=nil,
    ["global"]=nil,
    ["game"]=nil,
}

local function init(conf)
	if not conf.enable then
        WARN("db "..conf.db_name.." is enable false")
		return nil
	end
	local dbtype=conf.db_type
	local dbc=require(dbtype)
	local mdb= dbc:start(conf)
	assert(mdb)
    log.info("dbname:%s dbtype:%s connect success",conf.db_name,conf.db_type)
	return mdb
end

function event.awake()
    db.account=init(dbconf.accountdb)
    db.global=init(dbconf.globaldb)
    db.game=init(dbconf.gamedb)
end

function dispatch.get(dbname,cname,select)
	return db[dbname]:findOne(cname,select)
end

function dispatch.set(dbname,cname,select,update)
	return db[dbname]:update(cname,select,update,true)
end

function dispatch.insert(dbname,cname,data)
	db[dbname]:insert(cname,data)
end



--发号器
local t_max_uuid = {
    ["account"] = { uuid = 50000}, 	--角色唯一ID
    ["roomid"] = { uuid = 50000}, --房间唯一ID
}

local function rand_inc_num()
    return math.random(1, 1)
end

function event.start()
    for k, v in pairs(t_max_uuid) do
        local ret = db["global"]:findOne("tb_key", {key=k})
        if ret then
            v.uuid = tonumber(ret.uuid)
        end

    end

end

function event.exit()
    for _, v in pairs(t_max_uuid) do
        db["global"]:update("tb_key", {key=k}, {key=k, uuid=tonumber(v.uuid), true})
    end
end

--原来方案有数据竞争问题，协程中调用数据库，协程会被挂起
--中途会执行其他协程
function dispatch.incr(cname)
	local cuu = t_max_uuid[cname]
	assert(cuu)

	cuu.uuid = cuu.uuid + rand_inc_num()

	--这一行存储只是防止停服，也会有竞争问题
	db["global"]:update("tb_key", {key=cname}, {key=cname, uuid= cuu.uuid }, true)
	return cuu.uuid
end
