local skynet = require "skynet"
local runconf = require(skynet.getenv("runconfig"))
local prototype = runconf.prototype

return require("faci.gateserver_"..prototype)