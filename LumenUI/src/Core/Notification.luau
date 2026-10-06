local Create = require(script.Parent.Parent.Util.Create)
local Tween = require(script.Parent.Parent.Util.Tween)

local Notification = {}
Notification.__index = Notification

function Notification.new(gui: ScreenGui, theme)
	local self = setmetatable({}, Notification)
	self._theme = theme

	self._holder = Create("Frame", {
		Name = "Notifications",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.new(0, 300, 1, -32),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		Create("UIListLayout", {
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
		}),
	})

	return self
end

function Notification:Push(options)
	local theme = self._theme
	local duration = options.Duration or 4

	-- CanvasGroup lets us fade the whole card (text, stroke and all) with one property
	local card = Create("CanvasGroup", {
		Name = "Notification",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = theme.Surface,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		Parent = self._holder,
	}, {
		Create("UICorner", { CornerRadius = theme.Corner }),
		Create("UIStroke", { Color = theme.Stroke, Thickness = 1 }),
		Create("UIPadding", {
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 14),
			PaddingRight = UDim.new(0, 14),
		}),
		Create("UIListLayout", {
			Padding = UDim.new(0, 2),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Create("TextLabel", {
			Name = "Title",
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 18),
			BackgroundTransparency = 1,
			Text = options.Title or "Notice",
			Font = theme.FontBold,
			TextSize = theme.TextSize,
			TextColor3 = theme.Accent,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		Create("TextLabel", {
			Name = "Body",
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Text = options.Content or "",
			Font = theme.Font,
			TextSize = theme.TextSize - 1,
			TextColor3 = theme.Text,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
	})

	Tween.to(card, { GroupTransparency = 0 }, 0.25)

	task.delay(duration, function()
		if not card.Parent then
			return -- window was destroyed in the meantime
		end
		Tween.to(card, { GroupTransparency = 1 }, 0.3).Completed:Wait()
		card:Destroy()
	end)
end

return Notification
