class 'Boost'

function Boost:__init()
	self.land_enabled	= true
	self.boat_enabled	= true
	self.heli_enabled	= true
	self.plane_enabled	= true

	self.text_enabled	= true
	self.land_text		= "Hold SHIFT to boost"
	self.air_text		= "Hold TAB to boost"
	self.window_open	= false
	self.timer			= Timer()

	self.boats			= {5, 6, 16, 19, 25, 27, 28, 38, 45, 50, 53, 69, 80, 88}
	self.helis			= {3, 14, 37, 57, 62, 64, 65, 67}
	self.planes			= {24, 30, 34, 39, 51, 59, 81, 85}

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
	self.window:SetSize(Vector2(200, 140))
	self:UpdateWindowPos()

	self.window:SetTitle("Boost Settings")
	self.window:SetVisible(self.window_open)
	self.window:Subscribe("WindowClosed", self, self.WindowClosed)

	self.land_checkbox = LabeledCheckBox.Create(self.window)
	self.land_checkbox:SetSize(Vector2(200, 20))
	self.land_checkbox:SetDock(GwenPosition.Top)
	self.land_checkbox:GetLabel():SetText("Land vehicle boost enabled")
	self.land_checkbox:GetCheckBox():Subscribe("CheckChanged",
		function() self.land_enabled = self.land_checkbox:GetCheckBox():GetChecked() end)

	self.boat_checkbox = LabeledCheckBox.Create(self.window)
	self.boat_checkbox:SetSize(Vector2(200, 20))
	self.boat_checkbox:SetDock(GwenPosition.Top)
	self.boat_checkbox:GetLabel():SetText("Boat boost enabled")
	self.boat_checkbox:GetCheckBox():Subscribe("CheckChanged",
		function() self.boat_enabled = self.boat_checkbox:GetCheckBox():GetChecked() end)

	self.heli_checkbox = LabeledCheckBox.Create(self.window)
	self.heli_checkbox:SetSize(Vector2(200, 20))
	self.heli_checkbox:SetDock(GwenPosition.Top)
	self.heli_checkbox:GetLabel():SetText("Helicopter boost enabled")
	self.heli_checkbox:GetCheckBox():Subscribe("CheckChanged",
		function() self.heli_enabled = self.heli_checkbox:GetCheckBox():GetChecked() end)

	self.plane_checkbox = LabeledCheckBox.Create(self.window)
	self.plane_checkbox:SetSize(Vector2(200, 20))
	self.plane_checkbox:SetDock(GwenPosition.Top)
	self.plane_checkbox:GetLabel():SetText("Plane boost enabled")
	self.plane_checkbox:GetCheckBox():Subscribe("CheckChanged",
		function() self.plane_enabled = self.plane_checkbox:GetCheckBox():GetChecked() end)

	self.text_checkbox = LabeledCheckBox.Create(self.window)
	self.text_checkbox:SetSize(Vector2(200, 20))
	self.text_checkbox:SetDock(GwenPosition.Top)
	self.text_checkbox:GetLabel():SetText("Boost text enabled")
	self.text_checkbox:GetCheckBox():Subscribe("CheckChanged",
		function() self.text_enabled = self.text_checkbox:GetCheckBox():GetChecked() end)
end

function Boost:UpdateCheckboxes()
	self.land_checkbox:GetCheckBox():SetChecked(self.land_enabled)
	self.boat_checkbox:GetCheckBox():SetChecked(self.boat_enabled)
	self.heli_checkbox:GetCheckBox():SetChecked(self.heli_enabled)
	self.plane_checkbox:GetCheckBox():SetChecked(self.plane_enabled)
	self.text_checkbox:GetCheckBox():SetChecked(self.text_enabled)
end

function Boost:WindowClosed()
	local t = {}
	t.land_enabled = self.land_checkbox:GetCheckBox():GetChecked()
	t.boat_enabled = self.boat_checkbox:GetCheckBox():GetChecked()
	t.heli_enabled = self.heli_checkbox:GetCheckBox():GetChecked()
	t.plane_enabled = self.plane_checkbox:GetCheckBox():GetChecked()
	t.text_enabled = self.text_checkbox:GetCheckBox():GetChecked()

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
	self:UpdateCheckboxes()
end

function Boost:LocalPlayerChat(args)
	if args.text == "/boost" then
		self:SetWindowOpen(true)
	end
end

function Boost:LocalPlayerInput(args)
	if self.window_open then return false end

	if self:IsDriver(LocalPlayer) and self.timer:GetMilliseconds() >= 100
			and LocalPlayer:GetWorld() == DefaultWorld 
			and Game:GetSetting(GameSetting.GamepadInUse) == 0 then
		local v = LocalPlayer:GetVehicle()
		if args.input == Action.PlaneIncTrust then
			if self:LandCheck(v) or self:BoatCheck(v) then
				self:Boost()
			end
		elseif args.input == Action.Evade then
			if self:HeliCheck(v) or self:PlaneCheck(v) then
				self:Boost()
			end
		end
	end
end

function Boost:Boost()
	Network:Send("Boost")
	self.timer:Restart()
end

function Boost:Render()
	if not self.text_enabled then return end
	if not self:IsDriver(LocalPlayer) then return end
	if not LocalPlayer:GetWorld() == DefaultWorld then return end

	local v = LocalPlayer:GetVehicle()
	local text
	if self:LandCheck(v) or self:BoatCheck(v) then
		text = self.land_text
	elseif self:HeliCheck(v) or self:PlaneCheck(v) then
		text = self.air_text
	else
		return
	end

	local text_size = Render:GetTextSize(text)
	local pos = Vector2((Render.Width - text_size.x) / 2, Render.Height - text_size.y - 5)

	Render:DrawText(pos + Vector2.One, text, Color.Black)
	Render:DrawText(pos, text, Color.White)
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
