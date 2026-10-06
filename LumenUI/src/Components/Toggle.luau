local Create = require(script.Parent.Parent.Util.Create)
local Signal = require(script.Parent.Parent.Util.Signal)
local Tween = require(script.Parent.Parent.Util.Tween)

local Toggle = {}
Toggle.__index = Toggle

local KNOB_OFF = UDim2.new(0, 3, 0.5, 0)
local KNOB_ON = UDim2.new(1, -17, 0.5, 0)

function Toggle.new(parent, theme, options)
	local self = setmetatable({}, Toggle)
	self.Changed = Signal.new()

	self._theme = theme
	self._callback = options.Callback
	self._value = options.Default == true

	local row = Create("TextButton", {
		Name = "Toggle",
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = theme.Surface,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Parent = parent,
	}, {
		Create("UICorner", { CornerRadius = theme.Corner }),
		Create("UIPadding", {
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
		}),
		Create("TextLabel", {
			Name = "Title",
			Size = UDim2.new(1, -50, 1, 0),
			BackgroundTransparency = 1,
			Text = options.Name or "Toggle",
			Font = theme.Font,
			TextSize = theme.TextSize,
			TextColor3 = theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
	})

	self._track = Create("Frame", {
		Name = "Track",
		Size = UDim2.fromOffset(38, 20),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		BackgroundColor3 = theme.Stroke,
		BorderSizePixel = 0,
		Parent = row,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})

	self._knob = Create("Frame", {
		Name = "Knob",
		Size = UDim2.fromOffset(14, 14),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = KNOB_OFF,
		BackgroundColor3 = theme.Text,
		BorderSizePixel = 0,
		Parent = self._track,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})

	self.Instance = row

	row.MouseEnter:Connect(function()
		Tween.to(row, { BackgroundColor3 = theme.SurfaceHover }, 0.12)
	end)
	row.MouseLeave:Connect(function()
		Tween.to(row, { BackgroundColor3 = theme.Surface }, 0.12)
	end)
	row.Activated:Connect(function()
		self:Set(not self._value)
	end)

	self:_render(false)
	return self
end

function Toggle:_render(animate: boolean)
	local on = self._value
	local trackGoal = { BackgroundColor3 = on and self._theme.Accent or self._theme.Stroke }
	local knobGoal = { Position = on and KNOB_ON or KNOB_OFF }

	if animate then
		Tween.to(self._track, trackGoal, 0.15)
		Tween.to(self._knob, knobGoal, 0.15)
	else
		self._track.BackgroundColor3 = trackGoal.BackgroundColor3
		self._knob.Position = knobGoal.Position
	end
end

-- silent = true skips the callback / Changed signal (handy when loading configs)
function Toggle:Set(value: boolean, silent: boolean?)
	value = not not value
	if value == self._value then
		return
	end

	self._value = value
	self:_render(true)

	if not silent then
		self.Changed:Fire(value)
		if self._callback then
			task.spawn(self._callback, value)
		end
	end
end

function Toggle:Get(): boolean
	return self._value
end

function Toggle:Destroy()
	self.Changed:Destroy()
	self.Instance:Destroy()
end

return Toggle
