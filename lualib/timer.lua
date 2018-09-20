local skynet = require "skynet"

local timer = {}

function timer.new(self)
	local t = {}

	setmetatable(t, self)

	self.__index = self

	return t
end

function timer.init(self, interval,func,loop)
	if not interval then
		interval = 100
	end
	self.interval = interval
	self.callback = func
	self.loop=loop
end

function timer:on_time_out()
	local f=self.callback
	if type(f)~="function" then
		skynet.error("callback is not function")
		return
	end
	f()
	if self.loop then
		skynet.timeout(self.interval, function()
			self:on_time_out()
		end)
	end
end

function timer:start()
	skynet.timeout(self.interval, function()
		self:on_time_out()
	end)
end

function timer:stop()
	self.loop=false
end

return timer
