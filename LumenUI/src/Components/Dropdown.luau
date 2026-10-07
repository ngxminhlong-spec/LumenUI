local Create = require(script.Parent.Parent.Util.Create)
local Signal = require(script.Parent.Parent.Util.Signal)
local Tween = require(script.Parent.Parent.Util.Tween)
local Device = require(script.Parent.Parent.Util.Device)
local Interact = require(script.Parent.Parent.Util.Interact)

-- Longer lists scroll instead of pushing the whole page down.
local MAX_VISIBLE = 5

local Dropdown = {}
Dropdown.__index = Dropdown

-- options: Name, Options = { ... }, Default, Callback
function Dropdown.new(parent, theme, options)
	local self = setmetatable({}, Dropdown)
	self.Changed = Signal.new()

	self._theme = theme
	self._callback = options.Callback
	self._options = options.Options or {}
	self._selected = options.Default
	self._open = false

	local rowHeight = Device.rowHeight()
	self._itemHeight = rowHeight - 6

	-- root grows when the list opens, which pushes everything below it down
	local root = Create("Frame", {
		Name = "Dropdown",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = parent,
	}, {
		Create("UIListLayout", {
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local header = Create("TextButton", {
		Name = "Header",
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, rowHeight),
		BackgroundColor3 = theme.Surface,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Parent = root,
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
			Size = UDim2.new(0.5, -8, 1, 0),
			BackgroundTransparency = 1,
			Text = options.Name or "Dropdown",
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
		Position = UDim2.new(1, -22, 0, 0),
		Size = UDim2.new(0.5, -22, 1, 0),
		BackgroundTransparency = 1,
		Font = theme.Font,
		TextSize = theme.TextSize,
		TextColor3 = theme.Accent,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = header,
	})

	-- a plain ">" rotated 90 degrees: points down when closed, up when open
	self._arrow = Create("TextLabel", {
		Name = "Arrow",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		Text = ">",
		Font = theme.FontBold,
		TextSize = theme.TextSize,
		TextColor3 = theme.TextDim,
		Rotation = 90,
		Parent = header,
	})

	self._list = Create("ScrollingFrame", {
		Name = "List",
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = theme.Surface,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = theme.Stroke,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
		Parent = root,
	}, {
		Create("UICorner", { CornerRadius = theme.Corner }),
		Create("UIStroke", {
			Color = theme.Stroke,
			Transparency = 0.5,
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		Create("UIPadding", {
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
		}),
		Create("UIListLayout", {
			Padding = UDim.new(0, 2),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	self.Instance = root

	Interact.bind(header, function(state)
		Tween.to(header, { BackgroundColor3 = state == "Idle" and theme.Surface or theme.SurfaceHover }, 0.12)
	end)

	header.Activated:Connect(function()
		self:_setOpen(not self._open)
	end)

	self:_buildOptions()
	self:_updateLabel()
	return self
end

-- how tall the list is when fully open (capped at MAX_VISIBLE rows)
function Dropdown:_targetHeight(): number
	local count = #self._options
	if count == 0 then
		return 0
	end
	local visible = math.min(count, MAX_VISIBLE)
	return visible * (self._itemHeight + 2) + 6
end

function Dropdown:_setOpen(open: boolean)
	if open and #self._options == 0 then
		return
	end

	self._open = open
	Tween.to(self._arrow, { Rotation = open and -90 or 90 }, 0.18)

	if open then
		self._list.Visible = true
		Tween.to(self._list, { Size = UDim2.new(1, 0, 0, self:_targetHeight()) }, 0.2, Enum.EasingStyle.Quint)
	else
		local tween = Tween.to(self._list, { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
		tween.Completed:Connect(function()
			if not self._open then
				self._list.Visible = false
			end
		end)
	end
end

function Dropdown:_updateLabel()
	self._valueLabel.Text = self._selected ~= nil and tostring(self._selected) or "Select..."
	self._valueLabel.TextColor3 = self._selected ~= nil and self._theme.Accent or self._theme.TextDim
end

function Dropdown:_buildOptions()
	local theme = self._theme

	-- wipe the old buttons, but keep the layout / padding / corner objects
	for _, child in self._list:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	for index, option in self._options do
		local isSelected = option == self._selected

		local item = Create("TextButton", {
			Name = tostring(option),
			LayoutOrder = index,
			Size = UDim2.new(1, 0, 0, self._itemHeight),
			BackgroundColor3 = theme.SurfaceHover,
			BackgroundTransparency = isSelected and 0.3 or 1,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = tostring(option),
			Font = theme.Font,
			TextSize = theme.TextSize,
			TextColor3 = isSelected and theme.Accent or theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = self._list,
		}, {
			Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
			Create("UIPadding", { PaddingLeft = UDim.new(0, 26), PaddingRight = UDim.new(0, 8) }),
		})

		if isSelected then
			-- small accent dot marks the current choice
			Create("Frame", {
				Name = "Dot",
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, -16, 0.5, 0),
				Size = UDim2.fromOffset(6, 6),
				BackgroundColor3 = theme.Accent,
				BorderSizePixel = 0,
				Parent = item,
			}, {
				Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
			})
		end

		if not isSelected then
			Interact.bind(item, function(state)
				Tween.to(item, { BackgroundTransparency = state == "Idle" and 1 or 0.5 }, 0.1)
			end)
		end

		item.Activated:Connect(function()
			self:Set(option)
			self:_setOpen(false)
		end)
	end
end

function Dropdown:Set(option, silent: boolean?)
	if option == self._selected then
		return
	end

	self._selected = option
	self:_updateLabel()
	self:_buildOptions()

	if not silent then
		self.Changed:Fire(option)
		if self._callback then
			task.spawn(self._callback, option)
		end
	end
end

function Dropdown:Get()
	return self._selected
end

-- swap out the whole list, e.g. when the player list changes
function Dropdown:Refresh(newOptions: { any })
	self._options = newOptions

	if not table.find(newOptions, self._selected) then
		self._selected = nil
		self:_updateLabel()
	end

	self:_buildOptions()

	if self._open then
		if #newOptions == 0 then
			self:_setOpen(false)
		else
			Tween.to(self._list, { Size = UDim2.new(1, 0, 0, self:_targetHeight()) }, 0.15)
		end
	end
end

function Dropdown:Destroy()
	self.Changed:Destroy()
	self.Instance:Destroy()
end

return Dropdown
