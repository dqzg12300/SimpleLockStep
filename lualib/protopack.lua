local skynet = require "skynet"
local runconf = require(skynet.getenv("runconfig"))
local protopack = runconf.protopack

return require("protopack_"..protopack)