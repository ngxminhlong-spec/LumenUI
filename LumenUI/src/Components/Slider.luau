local UserInputService = game:GetService("UserInputService")

local Create = require(script.Parent.Parent.Util.Create)
local Signal = require(script.Parent.Parent.Util.Signal)
local Tween = require(script.Parent.Parent.Util.Tween)
local Device = require(script.Parent.Parent.Util.Device)

local Slider = {}
Slider.__index = Slider

local function isPointer(input: InputObject)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

-- 5 -> 0 decimals, 0.5 -> 1, 0.25 -> 2. Used so "60" doesn't show up as "60.0".
local function decimalsOf(step: number): number
	local decimals = 0
	while decimals < 4 do
		local scaled = step * 10 ^ decimals
		if math.abs(scaled - math.round(scaled)) < 1e-6 then
			break
		end
		decimals += 1
	end
	return decimals
end

-- options: Name, Min, Max, Default, Increment, Suffix, Callback
function Slider.new(parent, theme, options)
	local self = setmetatable({}, Slider)
	self.Changed = Signal.new()

	local touch = Device.isTouch()

	self._callback = options.Callback
	self._min = options.Min or 0
	self._max = math.max(options.Max or 100, self._min) -- Max below Min would break the maths
	self._increment = math.max(options.Increment or 1, 0)
	self._decimals = self._increment > 0 and decimalsOf(self._increment) or 2
	self._suffix = options.Suffix or ""
	self._connections = {}
	self._value = self:_snap(options.Default or self._min)

	local knobSize = touch and 20 or 16
	local knobBig = knobSize + 4

	local row = Create("Frame", {
		Name = "Slider",
		Size = UDim2.new(1, 0, 0, touch and 64 or 56),
		BackgroundColor3 = theme.Surface,
		BorderSizePixel = 0,
		Parent = parent,
	}, {
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
			Position = UDim2.fromOffset(0, 8),
			Size = UDim2.new(0.65, 0, 0, 20),
			BackgroundTransparency = 1,
			Text = options.Name or "Slider",
			Font = theme.Font,
			TextSize = theme.TextSize,
			TextColor3 = theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}),
	})

	self._valueLabel = Create("TextLabel", {
		Name = "Value",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 8),
		Size = UDim2.new(0.35, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = theme.FontBold,
		TextSize = theme.TextSize,
		TextColor3 = theme.Accent,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = row,
	})

	-- The hit box is taller than the visible bar so it's easy to grab with a thumb. The side
	-- padding leaves room for the knob to overhang the ends of the track.
	local hitbox = Create("Frame", {
		Name = "Hitbox",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, -4),
		Size = UDim2.new(1, 0, 0, touch and 32 or 26),
		BackgroundTransparency = 1,
		Parent = row,
	}, {
		Create("UIPadding", {
			PaddingLeft = UDim.new(0, knobBig / 2),
			PaddingRight = UDim.new(0, knobBig / 2),
		}),
	})

	self._track = Create("Frame", {
		Name = "Track",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(1, 0, 0, touch and 8 or 6),
		BackgroundColor3 = theme.Stroke,
		BorderSizePixel = 0,
		Parent = hitbox,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})

	self._fill = Create("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = self._track,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Create("UIGradient", { Color = ColorSequence.new(theme.Accent, theme.Accent2) }),
	})

	self._knob = Create("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(knobSize, knobSize),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = self._track,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Create("UIStroke", { Color = theme.Accent, Thickness = 2 }),
	})

	self.Instance = row

	local dragging = false
	local lockedScroller: ScrollingFrame? = nil

	-- Touching a slider inside a ScrollingFrame would scroll the page as well, so the page
	-- is frozen for as long as the finger is on the slider.
	local function setDragging(active: boolean)
		dragging = active
		Tween.to(self._knob, {
			Size = UDim2.fromOffset(active and knobBig or knobSize, active and knobBig or knobSize),
		}, 0.1)

		if active then
			lockedScroller = row:FindFirstAncestorWhichIsA("ScrollingFrame")
			if lockedScroller then
				lockedScroller.ScrollingEnabled = false
			end
		elseif lockedScroller then
			lockedScroller.ScrollingEnabled = true
			lockedScroller = nil
		end
	end

	local function updateFromX(x: number)
		local width = self._track.AbsoluteSize.X
		if width <= 0 then
			return
		end
		local alpha = math.clamp((x - self._track.AbsolutePosition.X) / width, 0, 1)
		self:Set(self._min + (self._max - self._min) * alpha)
	end

	hitbox.InputBegan:Connect(function(input)
		if isPointer(input) then
			setDragging(true)
			updateFromX(input.Position.X)
		end
	end)

	table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			updateFromX(input.Position.X)
		end
	end))

	table.insert(self._connections, UserInputService.InputEnded:Connect(function(input)
		if dragging and isPointer(input) then
			setDragging(false)
		end
	end))

	-- These connections live on UserInputService, so destroying the window would NOT clean
	-- them up by itself. Hook the row's own destruction instead.
	row.Destroying:Connect(function()
		if dragging then
			setDragging(false)
		end
		self:_disconnect()
	end)

	self:_render(false)
	return self
end

function Slider:_disconnect()
	for _, connection in self._connections do
		connection:Disconnect()
	end
	table.clear(self._connections)
end

-- Snap to the increment, then clamp. The round() cleans up float noise like 0.30000000004.
function Slider:_snap(value: number): number
	if self._increment > 0 then
		value = math.floor((value - self._min) / self._increment + 0.5) * self._increment + self._min
	end
	return math.clamp(math.round(value * 10000) / 10000, self._min, self._max)
end

function Slider:_render(animate: boolean)
	local range = self._max - self._min
	local alpha = range > 0 and (self._value - self._min) / range or 0

	if animate then
		Tween.to(self._fill, { Size = UDim2.fromScale(alpha, 1) }, 0.06)
		Tween.to(self._knob, { Position = UDim2.fromScale(alpha, 0.5) }, 0.06)
	else
		self._fill.Size = UDim2.fromScale(alpha, 1)
		self._knob.Position = UDim2.fromScale(alpha, 0.5)
	end

	self._valueLabel.Text = string.format("%." .. self._decimals .. "f", self._value) .. self._suffix
end

function Slider:Set(value: number, silent: boolean?)
	value = self:_snap(value)

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

function Slider:Get(): number
	return self._value
end

function Slider:Destroy()
	self:_disconnect()
	self.Changed:Destroy()
	self.Instance:Destroy()
end

return Slider
