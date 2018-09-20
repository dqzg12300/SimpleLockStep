---
--- 房间逻辑部分
--- Created by admin.
--- DateTime: 2018/9/12 16:01
---
local tablex=require "pl.tablex"
local libcenter=require "libcenter"
local ROOM=class("ROOM")
local env=require "faci.env"
local timer=require "timer"
local t=nil
local logic=require "room_step.step_logic"
local master=nil

function ROOM:init(uid)
    self._players={}
    logic.init()
    master=uid
    log.debug("room_id:%d init",env.id)
end

function ROOM:is_table_full()
    return tablex.size(self._players)>=3
end

function ROOM:broadcast(msg,filterUid)
    DEBUG("broadcast")
    for k,v in pairs(self._players) do
        if not filterUid or filterUid~=k then
            libcenter.send2client(k,msg)
        end
    end
end

local function get_usersdata()
    local data={}
    for k,v in pairs(ROOM._players) do
        local pd={
            uid=v.uid,
            username=v.account,
        }
        table.insert(data,pd)
    end
    return data
end

function ROOM:enter(data)
    local uid=data.uid
    self._players[uid]=data
    local data=get_usersdata()
    self:broadcast({_cmd="room.flush_userdataNty",data=data})
    log.debug("logic enter_room play size:%d",tablex.size(self._players))
    return SYSTEM_ERROR.success
end

function ROOM:leave(uid)
    if not uid then
        log.debug("logic leave_room uid is nil")
        return DESK_ERROR.room_not_uid
    end
    self._players[uid]=nil
    local data=get_usersdata()
    self:broadcast({_cmd="room.flush_userdataNty",data=data})

    log.debug("logic enter_room play size:%d",tablex.size(self._players))
    return SYSTEM_ERROR.success
end

local function get_uids()
    local uids={}
    for i,v in pairs(ROOM._players) do
        uids[v.uid]=1
    end
    return uids
end

--每一帧广播的消息
local function update_step()
    --获取收集到的所有用户指令
    local msg_queue=logic.get_queue()
    --设置对应数据
    local fs={}
    fs._cmd="lockstep.frame"
    fs._check=0
    fs.frameId=logic.getframeId()
    fs.serverTime=os.time()
    fs.nextFrameId=logic.getframeId()+1
    fs.frameData={}
    --获取当前所有玩家id
    local uids=get_uids()
    --插入所有玩家指令,并将有消息的玩家从列表中移除
    for i,msg in pairs(msg_queue) do
        table.insert(fs.frameData,msg)
        if uids[msg.uid] then
            uids[msg.uid]=nil
        end
    end
    --剩下没有发消息过来的玩家,这里给这些玩家发空命令
    for i,v in pairs(uids) do
        local msg={uid=i,cmd=0x00}
        table.insert(fs.frameData,msg)
    end
    --广播当前帧消息,并且清空收集到的消息列表
    ROOM:broadcast(fs)
    logic.clear()
end

function ROOM:start_game(uid)
    if uid~=master then
        return GAME_ERROR.no_master_game
    end
    logic.init()
    t=timer:new()
    t:init(300,update_step,true)
    t:start()
    return SYSTEM_ERROR.success
end

function ROOM:frame(msg)
    logic.push(msg)
end

return ROOM