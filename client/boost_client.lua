-- Created by DaAlpha
class 'Boost'

function Boost:__init()
	self.land_enabled		= true
	self.boat_enabled		= true
	self.heli_enabled		= true
	self.plane_enabled		= true

	self.controller_enabled = true

	self.text_enabled		= true
	self.land_text			= "SHIFT "
	self.air_text			= "TAB "
	self.controller_text	= "or LB "

	self.timer				= Timer()
	self.boost_interval		= 100 -- ms

	self.window_open		= false

	self.boats				= {5, 6, 16, 19, 25, 27, 28, 38, 45, 50, 53, 69, 80, 88}
	self.helis				= {3, 14, 37, 57, 62, 64, 65, 67}
	self.planes				= {24, 30, 34, 39, 51, 59, 81, 85}

	self:CreateWindow()
	self:UpdateCheckboxes()

	Network:Subscribe("UpdateSettings", self, self.UpdateSettings)

	Events:Subscribe("LocalPlayerChat", self, self.LocalPlayerChat)
	Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
	Events:Subscribe("Render", self, self.Render)
	Events:Subscribe("ResolutionChange", self, self.UpdateWindowPos)
end

function Boost:CreateWindow()
	self.window = Window.Create()
	self.window:SetSize(Vector2(200, 200))
	self:UpdateWindowPos()

	self.window:SetTitle("Boost Settings")
	self.window:SetVisible(self.window_open)
	self.window:Subscribe("WindowClosed", self, self.WindowClosed)

	-- Land checkbox
	local land_checkbox = LabeledCheckBox.Create(self.window)
	land_checkbox:SetSize(Vector2(200, 20))
	land_checkbox:SetDock(GwenPosition.Top)
	land_checkbox:GetLabel():SetText("Land vehicle boost enabled")
	land_checkbox:GetCheckBox():Subscribe("CheckChanged",
		function() self.land_enabled = land_checkbox:GetCheckBox():GetChecked() end)
	self.land_checkbox = land_checkbox:GetCheckBox()

	-- Boat checkbox
	local boat_checkbox = LabeledCheckBox.Create(self.window)
	boat_checkbox:SetSize(Vector2(200, 20))
	boat_checkbox:SetDock(GwenPosition.Top)
	boat_checkbox:GetLabel():SetText("Boat boost enabled")
	boat_checkbox:GetCheckBox():Subscribe("CheckChanged",
		function() self.boat_enabled = boat_checkbox:GetCheckBox():GetChecked() end)
	self.boat_checkbox = boat_checkbox:GetCheckBox()

	-- Heli checkbox
	local heli_checkbox = LabeledCheckBox.Create(self.window)
	heli_checkbox:SetSize(Vector2(200, 20))
	heli_checkbox:SetDock(GwenPosition.Top)
	heli_checkbox:GetLabel():SetText("Helicopter boost enabled")
	heli_checkbox:GetCheckBox():Subscribe("CheckChanged",
		function() self.heli_enabled = heli_checkbox:GetCheckBox():GetChecked() end)
	self.heli_checkbox = heli_checkbox:GetCheckBox()

	-- Plane checkbox
	local plane_checkbox = LabeledCheckBox.Create(self.window)
	plane_checkbox:SetSize(Vector2(200, 20))
	plane_checkbox:SetDock(GwenPosition.Top)
	plane_checkbox:GetLabel():SetText("Plane boost enabled")
	plane_checkbox:GetCheckBox():Subscribe("CheckChanged",
		function() self.plane_enabled = plane_checkbox:GetCheckBox():GetChecked() end)
	self.plane_checkbox = plane_checkbox:GetCheckBox()

	-- Separator 1
	local separator1 = Label.Create(self.window)
	separator1:SetSize(Vector2(256, 20))
	separator1:SetDock(GwenPosition.Top)

	-- Text checkbox
	local text_checkbox = LabeledCheckBox.Create(self.window)
	text_checkbox:SetSize(Vector2(200, 20))
	text_checkbox:SetDock(GwenPosition.Top)
	text_checkbox:GetLabel():SetText("Boost text enabled")
	text_checkbox:GetCheckBox():Subscribe("CheckChanged",
		function() self.text_enabled = text_checkbox:GetCheckBox():GetChecked() end)
	self.text_checkbox = text_checkbox:GetCheckBox()

	-- Separator 2
	local separator2 = Label.Create(self.window)
	separator2:SetSize(Vector2(256, 20))
	separator2:SetDock(GwenPosition.Top)

	-- Controller checkbox
	local controller_checkbox = LabeledCheckBox.Create(self.window)
	controller_checkbox:SetSize(Vector2(200, 20))
	controller_checkbox:SetDock(GwenPosition.Top)
	controller_checkbox:GetLabel():SetText("Controller boost enabled")
	controller_checkbox:GetCheckBox():Subscribe("CheckChanged",
		function() self.text_enabled = controller_checkbox:GetCheckBox():GetChecked() end)
	self.controller_checkbox = controller_checkbox:GetCheckBox()
end

function Boost:UpdateCheckboxes()
	self.land_checkbox:SetChecked(self.land_enabled)
	self.boat_checkbox:SetChecked(self.boat_enabled)
	self.heli_checkbox:SetChecked(self.heli_enabled)
	self.plane_checkbox:SetChecked(self.plane_enabled)
	self.text_checkbox:SetChecked(self.text_enabled)
	self.controller_checkbox:SetChecked(self.controller_enabled)
end

function Boost:WindowClosed()
	local t = {}
	t.land_enabled = self.land_enabled
	t.boat_enabled = self.boat_enabled
	t.heli_enabled = self.heli_enabled
	t.plane_enabled = self.plane_enabled
	t.text_enabled = self.text_enabled
	t.controller_enabled = self.controller_enabled

	Network:Send("UpdateSettings", t)

	self:SetWindowOpen(false)
end

function Boost:SetWindowOpen(state)
	self.window_open = state
	self.window:SetVisible(state)
	Mouse:SetVisible(state)
end

function Boost:UpdateSettings(args)
	self.land_enabled = args.land_enabled
	self.boat_enabled = args.boat_enabled
	self.heli_enabled = args.heli_enabled
	self.plane_enabled = args.plane_enabled
	self.text_enabled = args.text_enabled
	self.controller_enabled = args.controller_enabled

	self:UpdateCheckboxes()
end

function Boost:LocalPlayerChat(args)
	if args.text == "/boost" then
		self:SetWindowOpen(true)
	end
end

function Boost:LocalPlayerInput(args)
	if self.window_open then return false end

	if LocalPlayer:GetWorld() == DefaultWorld and self.controller_enabled and self:IsDriver(LocalPlayer) and
			Game:GetSetting(GameSetting.GamepadInUse) == 1 then
		local v = LocalPlayer:GetVehicle()
		if args.input == Action.VehicleFireLeft then
			if self:LandCheck(v) or self:BoatCheck(v) or self:HeliCheck(v) or self:PlaneCheck(v) then
				self:Boost()
			end
		end
	end
end

function Boost:Render()
	if not self:IsDriver(LocalPlayer) then return end
	if not LocalPlayer:GetWorld() == DefaultWorld then return end

	local v = LocalPlayer:GetVehicle()

	if LocalPlayer:GetWorld() == DefaultWorld then
		if Key:IsDown(160) then -- LShift
			if self:LandCheck(v) or self:BoatCheck(v) then
				self:Boost()
			end
		elseif Key:IsDown(9) then -- Tab
			if self:HeliCheck(v) or self:PlaneCheck(v) then
				self:Boost()
			end
		end
	end

	if not self.text_enabled then return end

	local text = "Press "
	if self:LandCheck(v) or self:BoatCheck(v) then
		text = text .. self.land_text
	elseif self:HeliCheck(v) or self:PlaneCheck(v) then
		text = text .. self.air_text
	end

	if self.controller_enabled then
		text = text .. self.controller_text
	end

	text = text .. "to boost"

	local text_size = Render:GetTextSize(text)
	local pos = Vector2((Render.Width - text_size.x) / 2, Render.Height - text_size.y - 5)

	Render:DrawText(pos + Vector2.One, text, Color.Black)
	Render:DrawText(pos, text, Color.White)
end

function Boost:Boost()
	if self.timer:GetMilliseconds() >= self.boost_interval then
		Network:Send("Boost")
		self.timer:Restart()
	end
end

function Boost:UpdateWindowPos()
	self.window:SetPositionRel(Vector2(0.5, 0.5) - self.window:GetSizeRel() / 2)
end

function Boost:IsDriver(player)
	return player:InVehicle() and player == player:GetVehicle():GetDriver()
end

function Boost:LandCheck(vehicle)
	local id = vehicle:GetModelId()
	return not table.find(self.boats, id) and not table.find(self.helis, id)
		and not table.find(self.planes, id) and self.land_enabled
end

function Boost:BoatCheck(vehicle)
	return table.find(self.boats, vehicle:GetModelId()) and self.boat_enabled
end

function Boost:HeliCheck(vehicle)
	return table.find(self.helis, vehicle:GetModelId()) and self.heli_enabled
end

function Boost:PlaneCheck(vehicle)
	return table.find(self.planes, vehicle:GetModelId()) and self.plane_enabled
end

local boost = Boost()
