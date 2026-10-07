local Create = require(script.Parent.Parent.Util.Create)
local Signal = require(script.Parent.Parent.Util.Signal)
local Tween = require(script.Parent.Parent.Util.Tween)
local Device = require(script.Parent.Parent.Util.Device)
local Interact = require(script.Parent.Parent.Util.Interact)

local TRACK_WIDTH = 44
local TRACK_HEIGHT = 24
local KNOB_SIZE = 18
local KNOB_STRETCH = 22 -- the knob gets a little wider while it is pressed
local KNOB_GAP = 3

local Toggle = {}
Toggle.__index = Toggle

-- options: Name, Description (optional second line), Default, Callback
function Toggle.new(parent, theme, options)
	local self = setmetatable({}, Toggle)
	self.Changed = Signal.new()

	self._theme = theme
	self._callback = options.Callback
	self._value = options.Default == true
	self._pressed = false

	local hasDescription = options.Description ~= nil
	local height = Device.rowHeight() + (hasDescription and 12 or 0)

	local children = {
		Create("UICorner", { CornerRadius = theme.Corner }),
		Create("UIStroke", {
			Color = theme.Stroke,
			Transparency = 0.5,
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		Create("UIPadding", {
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
		}),
		Create("TextLabel", {
			Name = "Title",
			Position = hasDescription and UDim2.fromOffset(0, 7) or UDim2.new(),
			Size = hasDescription and UDim2.new(1, -(TRACK_WIDTH + 12), 0, 20) or UDim2.new(1, -(TRACK_WIDTH + 12), 1, 0),
			BackgroundTransparency = 1,
			Text = options.Name or "Toggle",
			Font = theme.Font,
			TextSize = theme.TextSize,
			TextColor3 = theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}),
	}

	if hasDescription then
		table.insert(children, Create("TextLabel", {
			Name = "Description",
			Position = UDim2.fromOffset(0, 27),
			Size = UDim2.new(1, -(TRACK_WIDTH + 12), 0, 14),
			BackgroundTransparency = 1,
			Text = options.Description,
			Font = theme.Font,
			TextSize = theme.TextSize - 2,
			TextColor3 = theme.TextDim,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}))
	end

	local row = Create("TextButton", {
		Name = "Toggle",
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = theme.Surface,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Parent = parent,
	}, children)

	self._track = Create("Frame", {
		Name = "Track",
		Size = UDim2.fromOffset(TRACK_WIDTH, TRACK_HEIGHT),
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
		Size = UDim2.fromOffset(KNOB_SIZE, KNOB_SIZE),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, KNOB_GAP, 0.5, 0),
		BackgroundColor3 = theme.TextDim,
		BorderSizePixel = 0,
		Parent = self._track,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})

	self.Instance = row

	Interact.bind(row, function(state)
		self._pressed = state == "Press"
		Tween.to(row, { BackgroundColor3 = state == "Idle" and theme.Surface or theme.SurfaceHover }, 0.12)
		self:_render(true)
	end)

	row.Activated:Connect(function()
		self:Set(not self._value)
	end)

	self:_render(false)
	return self
end

function Toggle:_render(animate: boolean)
	local theme = self._theme
	local on = self._value

	local knobWidth = self._pressed and KNOB_STRETCH or KNOB_SIZE
	local knobX = on and (TRACK_WIDTH - knobWidth - KNOB_GAP) or KNOB_GAP

	local trackGoal = { BackgroundColor3 = on and theme.Accent or theme.Stroke }
	local knobGoal = {
		Size = UDim2.fromOffset(knobWidth, KNOB_SIZE),
		Position = UDim2.new(0, knobX, 0.5, 0),
		BackgroundColor3 = on and Color3.new(1, 1, 1) or theme.TextDim,
	}

	if animate then
		Tween.to(self._track, trackGoal, 0.18)
		Tween.to(self._knob, knobGoal, 0.18)
	else
		self._track.BackgroundColor3 = trackGoal.BackgroundColor3
		self._knob.Size = knobGoal.Size
		self._knob.Position = knobGoal.Position
		self._knob.BackgroundColor3 = knobGoal.BackgroundColor3
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
