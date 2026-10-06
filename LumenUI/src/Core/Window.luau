local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Create = require(script.Parent.Parent.Util.Create)
local Theme = require(script.Parent.Parent.Theme)
local Tab = require(script.Parent.Tab)
local Notification = require(script.Parent.Notification)

local Window = {}
Window.__index = Window

-- In Studio / normal games this is just PlayerGui. If the environment offers gethui()
-- (most executors do) we use that instead, since PlayerGui can get wiped on respawn
-- or inspected by the game.
local function getDefaultParent()
	local ok, hidden = pcall(function()
		return gethui and gethui()
	end)
	if ok and hidden then
		return hidden
	end
	return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local TOPBAR_HEIGHT = 40
local SIDEBAR_WIDTH = 140

function Window.new(options)
	options = options or {}

	local self = setmetatable({}, Window)
	self.Theme = Theme.extend(Theme.Dark, options.Theme)
	self.Tabs = {}

	self._connections = {}
	self._activeTab = nil
	self._toggleKey = options.ToggleKey or Enum.KeyCode.RightShift

	local theme = self.Theme
	local parent = options.Parent or getDefaultParent()

	self.Gui = Create("ScreenGui", {
		Name = "LumenUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 100,
		Parent = parent,
	})

	self.Main = Create("Frame", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = options.Size or UDim2.fromOffset(580, 400),
		BackgroundColor3 = theme.Background,
		BorderSizePixel = 0,
		Parent = self.Gui,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 10) }),
		Create("UIStroke", { Color = theme.Stroke, Thickness = 1 }),
	})

	-- top bar (also the drag handle)
	local topBar = Create("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, TOPBAR_HEIGHT),
		BackgroundTransparency = 1,
		Parent = self.Main,
	}, {
		Create("TextLabel", {
			Name = "Title",
			Position = UDim2.fromOffset(14, 0),
			Size = UDim2.new(1, -60, 1, 0),
			BackgroundTransparency = 1,
			Text = options.Title or "Lumen UI",
			Font = theme.FontBold,
			TextSize = theme.TextSize + 1,
			TextColor3 = theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
	})

	local closeButton = Create("TextButton", {
		Name = "Close",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(28, 28),
		BackgroundColor3 = theme.Surface,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "X",
		Font = theme.FontBold,
		TextSize = theme.TextSize,
		TextColor3 = theme.TextDim,
		Parent = topBar,
	}, {
		Create("UICorner", { CornerRadius = theme.Corner }),
	})

	closeButton.MouseEnter:Connect(function()
		closeButton.BackgroundTransparency = 0
	end)
	closeButton.MouseLeave:Connect(function()
		closeButton.BackgroundTransparency = 1
	end)
	closeButton.Activated:Connect(function()
		self:Destroy()
	end)

	-- thin divider lines
	Create("Frame", {
		Name = "TopDivider",
		Position = UDim2.fromOffset(0, TOPBAR_HEIGHT),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = theme.Stroke,
		BorderSizePixel = 0,
		Parent = self.Main,
	})
	Create("Frame", {
		Name = "SideDivider",
		Position = UDim2.fromOffset(SIDEBAR_WIDTH, TOPBAR_HEIGHT + 1),
		Size = UDim2.new(0, 1, 1, -(TOPBAR_HEIGHT + 1)),
		BackgroundColor3 = theme.Stroke,
		BorderSizePixel = 0,
		Parent = self.Main,
	})

	-- sidebar holds the tab buttons, pages hold the tab content
	self.TabList = Create("Frame", {
		Name = "TabList",
		Position = UDim2.fromOffset(0, TOPBAR_HEIGHT + 1),
		Size = UDim2.new(0, SIDEBAR_WIDTH, 1, -(TOPBAR_HEIGHT + 1)),
		BackgroundTransparency = 1,
		Parent = self.Main,
	}, {
		Create("UIPadding", {
			PaddingTop = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
		}),
		Create("UIListLayout", {
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	self.Pages = Create("Frame", {
		Name = "Pages",
		Position = UDim2.fromOffset(SIDEBAR_WIDTH + 1, TOPBAR_HEIGHT + 1),
		Size = UDim2.new(1, -(SIDEBAR_WIDTH + 1), 1, -(TOPBAR_HEIGHT + 1)),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = self.Main,
	})

	self._notifications = Notification.new(self.Gui, theme)

	self:_makeDraggable(topBar)

	table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return -- they're typing in chat or a textbox
		end
		if input.KeyCode == self._toggleKey then
			self:Toggle()
		end
	end))

	return self
end

function Window:_makeDraggable(handle: GuiObject)
	local dragging = false
	local dragStart: Vector3
	local startPosition: UDim2

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPosition = self.Main.Position
		end
	end)

	table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			self.Main.Position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			)
		end
	end))

	table.insert(self._connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
end

function Window:_selectTab(tab)
	if self._activeTab == tab then
		return
	end
	if self._activeTab then
		self._activeTab:_setActive(false)
	end

	self._activeTab = tab
	tab:_setActive(true)
end

function Window:AddTab(name: string)
	local tab = Tab.new(self, name)
	table.insert(self.Tabs, tab)

	-- first tab opens automatically so the window isn't empty
	if #self.Tabs == 1 then
		tab:Select()
	end

	return tab
end

function Window:Notify(options)
	self._notifications:Push(options or {})
end

function Window:SetVisible(visible: boolean)
	self.Main.Visible = visible
end

function Window:Toggle()
	self.Main.Visible = not self.Main.Visible
end

function Window:Destroy()
	for _, connection in self._connections do
		connection:Disconnect()
	end
	table.clear(self._connections)
	self.Gui:Destroy()
end

return Window
