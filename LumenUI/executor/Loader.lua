--[[
	Lumen UI - executor loader

	Executors can't read a folder of ModuleScripts, so this script:
	  1. downloads every file in src/ from a URL you host (GitHub raw works fine)
	  2. rebuilds the folder tree as fake "script" objects
	  3. gives each file its own `script` and `require`, so the library code
	     (script.Parent.Util.Create etc) runs without any changes
	  4. returns the library

	Usage:
		local Lumen = loadstring(game:HttpGet("https://raw.githubusercontent.com/YOU/LumenUI/main/executor/Loader.lua"))()

	Point it at your own copy of src/ by setting LUMEN_BASE before running (must end with "/"):
		getgenv().LUMEN_BASE = "https://raw.githubusercontent.com/YOU/LumenUI/main/src/"
]]

local BASE = (getgenv and getgenv().LUMEN_BASE) or "https://raw.githubusercontent.com/YOUR_NAME/LumenUI/main/src/"

-- every file that has to be downloaded, relative to src/
local FILES = {
	"init.luau",
	"Theme.luau",
	"Util/Create.luau",
	"Util/Signal.luau",
	"Util/Tween.luau",
	"Components/init.luau",
	"Components/Label.luau",
	"Components/Button.luau",
	"Components/Toggle.luau",
	"Components/Slider.luau",
	"Components/TextBox.luau",
	"Components/Dropdown.luau",
	"Core/Container.luau",
	"Core/Section.luau",
	"Core/Tab.luau",
	"Core/Notification.luau",
	"Core/Window.luau",
}

---- fake instance tree ---------------------------------------------------------------

local Node = {}
-- anything that isn't a real field (Name / Parent) is looked up as a child,
-- which is what makes `script.Parent.Util.Create` work
Node.__index = function(self, key)
	return rawget(self, "_children")[key]
end

local function newNode(name, parent)
	local node = setmetatable({ Name = name, Parent = parent, _children = {} }, Node)
	if parent then
		parent._children[name] = node
	end
	return node
end

local root = newNode("LumenUI")
local entries = {} -- node -> { Path = "...", Chunk = function }

for _, path in FILES do
	local parts = string.split(path, "/")
	local fileName = table.remove(parts)
	local moduleName = (string.gsub(fileName, "%.luau?$", ""))

	local parent = root
	for _, folderName in parts do
		parent = parent._children[folderName] or newNode(folderName, parent)
	end

	-- init files belong to their folder (same rule Rojo uses)
	local node = parent
	if moduleName ~= "init" then
		node = newNode(moduleName, parent)
	end

	entries[node] = { Path = path }
end

---- download everything in parallel --------------------------------------------------

local pending = 0
local failure

for _, entry in entries do
	pending += 1

	task.spawn(function()
		local ok, body = pcall(function()
			return game:HttpGet(BASE .. entry.Path)
		end)

		if not ok then
			failure = failure or ("could not download " .. entry.Path .. ": " .. tostring(body))
		else
			-- same-line prefix so error line numbers still match the original file
			local chunk, err = loadstring("local script, require = ...; " .. body, "=LumenUI/" .. entry.Path)
			if chunk then
				entry.Chunk = chunk
			else
				failure = failure or ("syntax error in " .. entry.Path .. ": " .. tostring(err))
			end
		end

		pending -= 1
	end)
end

while pending > 0 do
	task.wait()
end

if failure then
	error("[LumenUI] " .. failure, 0)
end

---- require shim ---------------------------------------------------------------------

local cache = {}

local function fakeRequire(node)
	local entry = entries[node]
	if not entry then
		error("[LumenUI] tried to require something that isn't part of the library", 2)
	end

	if cache[node] == nil then
		cache[node] = entry.Chunk(node, fakeRequire)
	end
	return cache[node]
end

return fakeRequire(root)
