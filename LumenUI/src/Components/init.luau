-- One place that lists every component. Container.luau loops over this table and
-- generates the AddButton / AddToggle / ... methods automatically, so adding a new
-- component is just: write the file, add one line here.

return {
	Label = require(script.Label),
	Button = require(script.Button),
	Toggle = require(script.Toggle),
	Slider = require(script.Slider),
	TextBox = require(script.TextBox),
	Dropdown = require(script.Dropdown),
}
