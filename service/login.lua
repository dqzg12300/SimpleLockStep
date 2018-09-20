---
--- 登录服务的初始化,具体业务逻辑看mod/login
--- Created by Administrator.
--- DateTime: 2018/9/2 20:33
---

local name,id=...
local s=require "faci.service"
s.init(name,id)