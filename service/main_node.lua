local skynet=require "skynet"
require "skynet.manager"
local runconfig=require(skynet.getenv("runconfig"))
local serverconf=runconfig.service
local nodename=skynet.getenv("nodename")

local function start_debug_console()
	for i,v in pairs(serverconf.debug_console) do
		if nodename==v.node then
			skynet.uniqueservice("debug_console",v.port)
			INFO("start debug_console port"..v.port)
		end
	end
end

local function start_dbporxy()
	for i,v in pairs(serverconf.dbproxy) do
		if nodename==v.node then
			skynet.newservice("dbproxy","dbproxy",i)
			INFO("start dbproxy")
		end
	end
end

local function start_gate()
	for i,v in pairs(serverconf.gateway) do
        local name=string.format("gateway%d",i)
		if nodename==v.node then
			local gate=skynet.newservice("gateway","gateway",i)
			INFO("start gateway "..i)
            local gateway_common=serverconf.gateway_common
            skynet.name(name,gate)
            skynet.call(gate,"lua","open",{
                port=v.port,
                maxclient=gateway_common.maxclient,
                nodelay=gateway_common.nodelay,
                name=name,
            })
		end
	end
end

local function start_login()
    for i,v in pairs(serverconf.login) do
        if nodename==v.node then
            skynet.newservice("login","login",i)
            INFO("start login "..i)
        end
    end
end

local function start_agentpool()
    local cnf=serverconf.agent_pool
    local name=cnf.name
    local pool=skynet.newservice("agentpool")
    skynet.name(name,pool)
    INFO("start agentpool")
    skynet.call(pool,"lua","init_pool",{
        agentname="agent",
        maxnum=cnf.maxnum,
        recycle=cnf.recycle,
    })
end

local function start_center()
    for i,v in pairs(serverconf.center) do
        if nodename==v.node then
            skynet.newservice("center","center",i)
            INFO("start center")
        end
    end
end

local function start_scene()
    for i,v in pairs(serverconf.scene) do
        if nodename==v.node then
            skynet.newservice("scene","scene",i)
            INFO("start scene"..i)
        end
    end
end

skynet.start(function()
	INFO("server start")
	start_debug_console()
	start_dbporxy()
    start_login()
    start_agentpool()
    start_center()
    start_scene()
	start_gate()
	skynet.exit()
end)