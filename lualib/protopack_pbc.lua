local skynet = require "skynet"
local json = require "cjson"
local log = require "log"
local pb = require("protobuf")
local io = require "io" 
local crc32 = require "crc32" 
local tool = require "tool"
local lfstool = require "lfstool"

--协议号映射表
local name2code = {}
local code2name = {}

local pbfilename = {}

--分析proto文件，计算映射表
local function analysis_file(pathfile, path)
	local file = io.open(pathfile, "r") 
	local package = ""
	
	for line in file:lines() do
		local s, c = string.gsub(line, "^%s*package%s*([%w%._]+).*$", "%1")
		if c > 0 then
			package = s
		end
		local s, c = string.gsub(line, "^%s*message%s*([%w%._]+).*$", "%1")
		if c > 0 then
			local name = package.."."..s
			local code = crc32.hash(name)
			--print(string.format("analysis proto file:%s->%d(%x)", name, code, code))
			name2code[name] = code
			code2name[code] = name
		end
	end
	file:close()  
end

--导入proto文件，并analysis_file
local path = skynet.getenv("app_root").."proto"

local function register_pbfile(path, filename)
    local pathfile = path .. "/" .. filename
    local file = io.open(pathfile, "r")

    for line in file:lines() do
        local s, c = string.gsub(line, '^%s*import%s*%"([%w%.%/]+).proto"%;', "%1")
        if c > 0 then
            local stmp = string.sub(s, 1, -2)
            if not pbfilename[stmp] then
                pb.register_file(path .. "/pb/"..stmp..".pb")
                pbfilename[stmp] = true
            end
        end
    end
    file:close()
    local nosuffix = string.sub(filename, 1, -7)
    local pbfile = path.."/pb/"..nosuffix..".pb"
    if not pbfilename[nosuffix] then
        pb.register_file(pbfile)
        pbfilename[nosuffix] = true
    end
end

local pb_file = io.open(path.."/pbfile", "a+")
local content = pb_file:read()
if not content or content ~= "" then
    lfstool.attrdir(path, function(file)
        local file = string.match(file, path.."/(.+%.proto)")
        if file then
            local nosuffix = string.sub(file, 1, -7)
            local pbfile = path.."/pb/"..nosuffix..".pb"
            local command = "protoc " .. "-I=" .. path .. " --descriptor_set_out "..pbfile.." "..path.."/"..file
            os.execute(command)
        end
    end)
    pb_file:write("pbfile has been generated")
end
pb_file:close()

lfstool.attrdir(path, function(file)
	local file = string.match(file, path.."/(.+%.proto)") --获取文件名
	if file then
		analysis_file(path.."/"..file, path) 
        register_pbfile(path, file)
	end
end)

--打印二进制string，用于调试
local function bin2hex(s)
    s=string.gsub(s, "(.)", function (x) return string.format("%02X ", string.byte(x)) end)
    return s
end

local M = {}

--cmd:login.Login
--checkcode:1234
--msg:{account="1",password="1234"}
function M.pack(cmd, check, msg)
	--格式说明
	--> >:big endian
	-->i2:前面两位为长度
	-->i4:int32 checkcode
    -->I4:uint32 cmd_code 
	
	--code
	local code = name2code[cmd]
	if not code then
		log.error(string.format("protopack_pb fail, cmd:%s", cmd or "nil"))
		return
	end
	--check
	check = check or 0
	--pbstr
	local pbstr = pb.encode(cmd, msg)
	local pblen = string.len(pbstr)
	--len
	local len = 4+4+pblen
	--组成发送字符串
	local f = string.format("> i2 i4 I4 c%d", pblen)
	local str = string.pack(f, len, check, code, pbstr)
	--调试
	log.info("send:"..bin2hex(str))
	log.info(string.format("send:cmd(%s) check(%d) msg->%s", cmd, check, tool.dump(msg)))
    return str
end

function M.unpack(str)
	log.info("recv:"..bin2hex(str))
	local pblen = string.len(str)-4-4
	local f = string.format("> i4 I4 c%d", pblen)
	local check, code, pbstr = string.unpack(f, str)
	log.info("recv pbstr:"..bin2hex(pbstr))
	local cmd = code2name[code]
	if not cmd then
		log.info("recv:code(%d) but not regiest", code)
		return 
	end
	local msg = pb.decode(cmd, pbstr)
	
	log.info("recv:cmd(%s) check(%d) msg->%s", cmd, check, tool.dump(msg))
    return cmd, check, msg
end

--本地测试解包使用,因为前两个字节是协议包大小。网络传递的会被拿掉。本地传递的不会
function M.local_unpack(str)
    log.info("recv:"..bin2hex(str))
    local pblen = string.len(str)-4-4-2
    local f = string.format("> i2 i4 I4 c%d", pblen)
    local len,check, code, pbstr = string.unpack(f, str)
    log.info("recv pbstr:"..bin2hex(pbstr))
    local cmd = code2name[code]
    if not cmd then
        log.info("recv:code(%d) but not regiest", code)
        return
    end
    local msg = pb.decode(cmd, pbstr)

    log.info("recv:cmd(%s) check(%d) msg->%s", cmd, check, tool.dump(msg))
    return cmd, check, msg
end

return M


