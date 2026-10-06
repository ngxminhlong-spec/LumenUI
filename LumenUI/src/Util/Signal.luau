-- Minimal signal class. Not as fancy as GoodSignal, but it's tiny and does the job.

local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ _handlers = {} }, Signal)
end

function Signal:Connect(fn)
	local handlers = self._handlers
	local handler = { Fn = fn }
	table.insert(handlers, handler)

	local connection = { Connected = true }

	function connection:Disconnect()
		if not self.Connected then
			return
		end
		self.Connected = false

		local index = table.find(handlers, handler)
		if index then
			table.remove(handlers, index)
		end
	end

	return connection
end

function Signal:Fire(...)
	-- clone first, a handler might disconnect itself while we're looping
	for _, handler in table.clone(self._handlers) do
		task.spawn(handler.Fn, ...)
	end
end

function Signal:Destroy()
	table.clear(self._handlers)
end

return Signal
