local Create = require(script.Parent.Parent.Util.Create)
local Tween = require(script.Parent.Parent.Util.Tween)
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

	self._button = Create("TextButton", {
		Name = name,
		Size = UDim2.new(1, 0, 0, 32),
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
		Create("UIPadding", { PaddingLeft = UDim.new(0, 10) }),
	})

	-- _content is where the Container mixin drops new components
	self._content = Create("ScrollingFrame", {
		Name = name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = theme.Stroke,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = window.Pages,
	}, {
		Create("UIPadding", {
			PaddingTop = UDim.new(0, 12),
			PaddingBottom = UDim.new(0, 12),
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 14),
		}),
		Create("UIListLayout", {
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	self._button.Activated:Connect(function()
		self:Select()
	end)

	return self
end

function Tab:Select()
	self._window:_selectTab(self)
end

-- called by the window, not meant to be used directly
function Tab:_setActive(active: boolean)
	local theme = self._theme
	self._content.Visible = active

	Tween.to(self._button, {
		BackgroundTransparency = active and 0 or 1,
		TextColor3 = active and theme.Text or theme.TextDim,
	}, 0.15)
end

function Tab:AddSection(title: string)
	return Section.new(self._content, self._theme, title)
end

function Tab:Destroy()
	self._button:Destroy()
	self._content:Destroy()
end

Container.mixin(Tab)

return Tab
