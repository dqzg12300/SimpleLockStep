
local json = require "cjson"

local M = {}

function M.pack(cmd,check, msg)
    msg._cmd = cmd
    msg._check=check
    local str = json.encode(msg)
    print(string.format("send:cmd(%s) check(%d) msg->%s", cmd, check, str))
    return str
end

function M.unpack(str)
    local isok, t = pcall(json.decode, str)
    if not isok then
        print(string.format("unpack error, msg: %s", str))
        return
    end
    print(string.format("recv:cmd(%s) check(%d) msg->%s", t._cmd, t._check,str))
    return t._cmd,t._check, t
end

json.encode_sparse_array(true) 

return M


