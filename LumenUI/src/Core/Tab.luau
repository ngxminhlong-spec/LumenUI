local Create = require(script.Parent.Parent.Util.Create)
local Tween = require(script.Parent.Parent.Util.Tween)
local Device = require(script.Parent.Parent.Util.Device)
local Interact = require(script.Parent.Parent.Util.Interact)
local Container = require(script.Parent.Container)
local Section = require(script.Parent.Section)

local Tab = {}
Tab.__index = Tab

function Tab.new(window, name: string)
	local self = setmetatable({}, Tab)
	local theme = window.Theme

	self.Name = name
	self._window = window
	self._theme = theme
	self._active = false
	self._state = "Idle"
	self._compact = false

	self._indicator = Create("Frame", {
		Name = "Indicator",
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Create("UIGradient", { Color = ColorSequence.new(theme.Accent, theme.Accent2), Rotation = 90 }),
	})

	self._buttonPadding = Create("UIPadding", {
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
	})

	self._button = Create("TextButton", {
		Name = name,
		Size = UDim2.new(1, 0, 0, Device.isTouch() and 40 or 34),
		BackgroundColor3 = theme.Surface,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = name,
		Font = theme.Font,
		TextSize = theme.TextSize,
		TextColor3 = theme.TextDim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = window.TabList,
	}, {
		Create("UICorner", { CornerRadius = theme.Corner }),
		self._buttonPadding,
		self._indicator,
	})

	self._pagePadding = Create("UIPadding", {
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 14),
	})

	-- _content is where the Container mixin drops new components
	self._content = Create("ScrollingFrame", {
		Name = name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = Device.isTouch() and 4 or 3,
		ScrollBarImageColor3 = theme.Stroke,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
		Parent = window.Pages,
	}, {
		self._pagePadding,
		Create("UIListLayout", {
			Padding = UDim.new(0, 12),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	Interact.bind(self._button, function(state)
		self._state = state
		self:_refresh()
	end)

	self._button.Activated:Connect(function()
		self:Select()
	end)

	self:_setCompact(window._compact == true)
	self:_refresh()

	return self
end

function Tab:Select()
	self._window:_selectTab(self)
end

-- Sidebar button (desktop) or button in the top strip (narrow screens, phones in portrait).
-- Called by the window whenever its layout changes.
function Tab:_setCompact(compact: boolean)
	self._compact = compact

	if compact then
		self._button.Size = UDim2.fromOffset(0, Device.isTouch() and 34 or 30)
		self._button.AutomaticSize = Enum.AutomaticSize.X
		self._button.TextXAlignment = Enum.TextXAlignment.Center
		self._indicator.AnchorPoint = Vector2.new(0.5, 1)
		self._indicator.Position = UDim2.new(0.5, 0, 1, 0)
		self._indicator.Size = UDim2.new(0.5, 0, 0, 3)
		self._pagePadding.PaddingLeft = UDim.new(0, 10)
		self._pagePadding.PaddingRight = UDim.new(0, 12)
		self._pagePadding.PaddingTop = UDim.new(0, 10)
	else
		self._button.Size = UDim2.new(1, 0, 0, Device.isTouch() and 40 or 34)
		self._button.AutomaticSize = Enum.AutomaticSize.None
		self._button.TextXAlignment = Enum.TextXAlignment.Left
		-- the button has 14px of left padding, which shifts its children, so pull the bar back out
		self._indicator.AnchorPoint = Vector2.new(0, 0.5)
		self._indicator.Position = UDim2.new(0, -14, 0.5, 0)
		self._indicator.Size = UDim2.fromOffset(3, 16)
		self._pagePadding.PaddingLeft = UDim.new(0, 12)
		self._pagePadding.PaddingRight = UDim.new(0, 14)
		self._pagePadding.PaddingTop = UDim.new(0, 12)
	end
end

function Tab:_refresh()
	local theme = self._theme
	local state = self._state

	local color, transparency, text
	if self._active then
		color = theme.Accent
		transparency = state == "Press" and 0.72 or 0.86
		text = theme.Text
	else
		color = theme.Surface
		transparency = if state == "Press" then 0.3 elseif state == "Hover" then 0.6 else 1
		text = state == "Idle" and theme.TextDim or theme.Text
	end

	Tween.to(self._button, {
		BackgroundColor3 = color,
		BackgroundTransparency = transparency,
		TextColor3 = text,
	}, 0.15)
	Tween.to(self._indicator, { BackgroundTransparency = self._active and 0 or 1 }, 0.15)
end

-- called by the window, not meant to be used directly
function Tab:_setActive(active: boolean)
	self._active = active
	self._content.Visible = active
	self:_refresh()

	if active then
		-- the page slides up a few pixels as it appears
		self._content.Position = UDim2.fromOffset(0, 10)
		Tween.to(self._content, { Position = UDim2.new() }, 0.25, Enum.EasingStyle.Quint)
	end
end

-- options (optional): { Collapsible = true, Collapsed = false }
function Tab:AddSection(title: string, options)
	return Section.new(self._content, self._theme, title, options)
end

function Tab:Destroy()
	self._button:Destroy()
	self._content:Destroy()
end

Container.mixin(Tab)

return Tab
