-- Hover / press states that behave on BOTH mouse and touch.
--
-- Plain MouseEnter / MouseLeave breaks on phones: a tap fires MouseEnter, but MouseLeave never
-- comes, so the row stays "hovered" forever. This helper only treats the mouse as hovering,
-- and releases the pressed state even when the finger slides off the button (or a
-- ScrollingFrame steals the touch and the button never sees InputEnded).
--
--   Interact.bind(button, function(state)  -- "Idle" | "Hover" | "Press"
--       ...
--   end)

local UserInputService = game:GetService("UserInputService")

local Interact = {}

local pressedResets = {} -- reset functions of everything that is currently held down
local globalConnection = nil
local references = 0

local function isPointer(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

-- Windows call retain() on creation and release() on destroy, so the one global
-- connection only exists while something is using it.
function Interact.retain()
	references += 1

	if not globalConnection then
		globalConnection = UserInputService.InputEnded:Connect(function(input)
			if not isPointer(input) then
				return
			end

			local resets = pressedResets
			pressedResets = {}
			for reset in resets do
				reset()
			end
		end)
	end
end

function Interact.release()
	references = math.max(0, references - 1)

	if references == 0 and globalConnection then
		globalConnection:Disconnect()
		globalConnection = nil
		table.clear(pressedResets)
	end
end

function Interact.bind(gui: GuiObject, callback: (state: string) -> ())
	local hovering = false
	local pressing = false
	local current = "Idle"

	local function refresh()
		local state = if pressing then "Press" elseif hovering then "Hover" else "Idle"
		if state ~= current then
			current = state
			callback(state)
		end
	end

	local function reset()
		pressing = false
		if UserInputService:GetLastInputType() == Enum.UserInputType.Touch then
			hovering = false
		end
		refresh()
	end

	gui.MouseEnter:Connect(function()
		hovering = UserInputService:GetLastInputType() ~= Enum.UserInputType.Touch
		refresh()
	end)

	gui.MouseLeave:Connect(function()
		hovering = false
		refresh()
	end)

	gui.InputBegan:Connect(function(input)
		if isPointer(input) then
			pressing = true
			pressedResets[reset] = true
			refresh()
		end
	end)

	gui.InputEnded:Connect(function(input)
		if isPointer(input) then
			pressedResets[reset] = nil
			reset()
		end
	end)
end

return Interact
