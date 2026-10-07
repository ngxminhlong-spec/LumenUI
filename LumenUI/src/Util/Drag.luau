-- Drag any GuiObject by a handle, with mouse or finger.
--
--   Drag.attach(topBar, window, {
--       Clamp = function(position: UDim2): UDim2 ... end,  -- keep it on screen
--       OnTap = function() ... end,                        -- released without moving
--       Threshold = 5,                                     -- pixels before it counts as a drag
--   })
--
-- Returns an object with :Disconnect().

local UserInputService = game:GetService("UserInputService")

local Drag = {}

local function isPointerDown(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

function Drag.attach(handle: GuiObject, target: GuiObject, options)
	options = options or {}
	local threshold = options.Threshold or 5

	local active = false
	local moved = false
	local startPoint = Vector3.zero
	local startPosition = target.Position

	local began = handle.InputBegan:Connect(function(input)
		if active or not isPointerDown(input) then
			return
		end

		active = true
		moved = false
		startPoint = input.Position
		startPosition = target.Position
	end)

	local changed = UserInputService.InputChanged:Connect(function(input)
		if not active then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local delta = input.Position - startPoint
		if not moved then
			if delta.Magnitude < threshold then
				return -- still a tap, not a drag
			end
			moved = true
		end

		local position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)

		if options.Clamp then
			position = options.Clamp(position)
		end
		target.Position = position
	end)

	local ended = UserInputService.InputEnded:Connect(function(input)
		if not active or not isPointerDown(input) then
			return
		end

		active = false
		if not moved and options.OnTap then
			options.OnTap()
		end
	end)

	local connection = {}

	function connection:Disconnect()
		began:Disconnect()
		changed:Disconnect()
		ended:Disconnect()
	end

	return connection
end

return Drag
