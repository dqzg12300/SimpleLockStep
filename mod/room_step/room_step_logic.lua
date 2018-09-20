---
--- 房间逻辑部分
--- Created by admin.
--- DateTime: 2018/9/12 16:01
---
local tablex=require "pl.tablex"
local libcenter=require "libcenter"
local ROOM=require "room_ddz.ddz_logic"
local env=require "faci.env"

function ROOM:init()
    self._players={}
    self:init_game()
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
    if self:is_table_full() then
        --启动游戏
        self:start()
    end
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

return ROOM