--[[
	Lumen UI
	A small, modular UI library for Roblox. Works with mouse, keyboard and touch.

	local Lumen = require(ReplicatedStorage.LumenUI)
	local window = Lumen.CreateWindow({ Title = "My Hub" })
	local tab = window:AddTab("Main")
	tab:AddButton({ Name = "Hello", Callback = function() print("hi") end })
]]

local Window = require(script.Core.Window)
local Theme = require(script.Theme)

local Lumen = {}

Lumen.Version = "0.2.0"
Lumen.Themes = Theme

function Lumen.CreateWindow(options)
	return Window.new(options)
end

return Lumen
