---
--- 斗地主逻辑,在handler中写游戏的逻辑部分.用fsm状态机关联起来。然后切换状态就好了
--- Created by admin.
--- DateTime: 2018/9/17 11:49
---

local M={}

local msg_queue={}
local fid=1

function M.init()
    msg_queue={}
end

function M.push(msg)
    table.insert(msg_queue,msg)
end

function M.get_queue()
    return msg_queue
end

function M.clear()
    msg_queue={}
    fid=fid+1
end

function M.getframeId()
    return fid
end

return M