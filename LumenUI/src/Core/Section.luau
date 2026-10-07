local Create = require(script.Parent.Parent.Util.Create)
local Tween = require(script.Parent.Parent.Util.Tween)
local Device = require(script.Parent.Parent.Util.Device)
local Interact = require(script.Parent.Parent.Util.Interact)
local Container = require(script.Parent.Container)

local Section = {}
Section.__index = Section

-- options (all optional): Collapsible = true, Collapsed = true
function Section.new(parent, theme, title: string, options)
	options = options or {}

	local self = setmetatable({}, Section)
	self._theme = theme
	self._collapsible = options.Collapsible == true or options.Collapsed ~= nil
	self._collapsed = options.Collapsed == true

	self.Instance = Create("Frame", {
		Name = "Section",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = parent,
	}, {
		Create("UIListLayout", {
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local header = Create("TextButton", {
		Name = "Header",
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, Device.isTouch() and 28 or 22),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Active = self._collapsible,
		Text = "",
		Parent = self.Instance,
	}, {
		Create("UIPadding", { PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 4) }),
		-- little gradient bar in front of the title
		Create("Frame", {
			Name = "Marker",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0, 0.5),
			Size = UDim2.fromOffset(3, 12),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
		}, {
			Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
			Create("UIGradient", { Color = ColorSequence.new(theme.Accent, theme.Accent2), Rotation = 90 }),
		}),
		Create("TextLabel", {
			Name = "Title",
			Position = UDim2.fromOffset(11, 0),
			Size = UDim2.new(1, -30, 1, 0),
			BackgroundTransparency = 1,
			Text = string.upper(title or "Section"),
			Font = theme.FontBold,
			TextSize = theme.TextSize - 3,
			TextColor3 = theme.TextDim,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}),
	})

	if self._collapsible then
		self._arrow = Create("TextLabel", {
			Name = "Arrow",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.fromOffset(16, 16),
			BackgroundTransparency = 1,
			Text = ">",
			Font = theme.FontBold,
			TextSize = theme.TextSize - 2,
			TextColor3 = theme.TextDim,
			Rotation = self._collapsed and 0 or 90,
			Parent = header,
		})

		Interact.bind(header, function(state)
			Tween.to(header:FindFirstChild("Title"), { TextColor3 = state == "Idle" and theme.TextDim or theme.Text }, 0.12)
		end)

		header.Activated:Connect(function()
			self:SetCollapsed(not self._collapsed)
		end)
	end

	self._content = Create("Frame", {
		Name = "Content",
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = theme.Section,
		BorderSizePixel = 0,
		Visible = not self._collapsed,
		Parent = self.Instance,
	}, {
		Create("UICorner", { CornerRadius = theme.Corner }),
		Create("UIStroke", {
			Color = theme.Stroke,
			Transparency = 0.35,
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		Create("UIPadding", {
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
		}),
		Create("UIListLayout", {
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	return self
end

function Section:SetCollapsed(collapsed: boolean)
	if not self._collapsible then
		return
	end

	self._collapsed = collapsed
	self._content.Visible = not collapsed
	Tween.to(self._arrow, { Rotation = collapsed and 0 or 90 }, 0.15)
end

function Section:Destroy()
	self.Instance:Destroy()
end

Container.mixin(Section)

return Section
