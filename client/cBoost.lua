-- Created by DaAlpha
class 'Boost'

function Boost:__init()
  -- Default Settings
  self.multiplier         = 3
  self.defaultLandBoost   = true
  self.defaultBoatBoost   = true
  self.defaultHeliBoost   = true
  self.defaultPlaneBoost  = true
  self.defaultTextEnabled = true
  self.defaultPadEnabled  = true

  -- Globals
  self.landBoost    = self.defaultLandBoost
  self.boatBoost    = self.defaultBoatBoost
  self.heliBoost    = self.defaultHeliBoost
  self.planeBoost   = self.defaultPlaneBoost
  self.textEnabled  = self.defaultTextEnabled
  self.padEnabled   = self.defaultPadEnabled
  self.timer        = Timer()
  self.interval     = 50 -- ms
  self.windowOpen   = false

  self.boats = {
    [5] = true, [6] = true, [16] = true, [19] = true,
    [25] = true, [27] = true, [28] = true, [38] = true,
    [45] = true, [50] = true, [53] = true, [69] = true,
    [80] = true, [88] = true
    }
  self.helis = {
    [3] = true, [14] = true, [37] = true, [57] = true,
    [62] = true, [64] = true, [65] = true, [67] = true
    }
  self.planes = {
    [24] = true, [30] = true, [34] = true, [39] = true,
    [51] = true, [59] = true, [81] = true, [85] = true
    }

  -- GUI Initiation Sub
  self.settingSub = Network:Subscribe("UpdateSettings", self, self.UpdateSettings)

  -- Events
  Events:Subscribe("Render", self, self.Render)
  Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
end

function Boost:UpdateSettings(args) -- args = settings
  -- Unsubscribe
  Network:Unsubscribe(self.settingSub)
  self.settingSub = nil

  -- Apply settings
  if args.landBoost then self.landBoost = args.landBoost == 1 end
  if args.boatBoost then self.boatBoost = args.boatBoost == 1 end
  if args.heliBoost then self.heliBoost = args.heliBoost == 1 end
  if args.planeBoost then self.planeBoost = args.planeBoost == 1 end
  if args.textEnabled then self.textEnabled = args.textEnabled == 1 end
  if args.padEnabled then self.padEnabled = args.padEnabled == 1 end

  -- Create main window
  self.window = Window.Create()
  self.window:SetSize(Vector2(180, 155))
  self.window:SetTitle("Boost Settings")
  self.window:SetVisible(false)
  self.window:Subscribe("WindowClosed", function() self:SetWindowOpen(false) end)
  self:ResolutionChange()

  -- Create checkboxes
  self:AddSetting("Land vehicle boost enabled", "landBoost", self.landBoost, self.defaultLandBoost)
  self:AddSetting("Boat boost enabled", "boatBoost", self.boatBoost, self.defaultBoatBoost)
  self:AddSetting("Helicopter boost enabled", "heliBoost", self.heliBoost, self.defaultHeliBoost)
  self:AddSetting("Plane boost enabled", "planeBoost", self.planeBoost, self.defaultPlaneBoost)
  self:AddSetting("Boost text enabled", "textEnabled", self.textEnabled, self.defaultTextEnabled)
  self:AddSetting("Controller boost enabled", "padEnabled", self.padEnabled, self.defaultPadEnabled)

  -- Subscribe to window related events
  Events:Subscribe("LocalPlayerChat", self, self.LocalPlayerChat)
  Events:Subscribe("ResolutionChange", self, self.ResolutionChange)

  -- Debug
  --self:SetWindowOpen(true)
end

function Boost:SetWindowOpen(state)
  self.windowOpen = state
  self.window:SetVisible(state)
  Mouse:SetVisible(state)
end

function Boost:LocalPlayerChat(args)
  if args.text:lower() == "/boost" then
    self:SetWindowOpen(true)
    return false
  end
end

function Boost:LocalPlayerInput(args)
  if self.windowOpen then return false end
  if self.padEnabled then
    if args.input == Action.VehicleFireLeft then
      if LocalPlayer:GetWorld() == DefaultWorld and self:IsDriver() and
          Game:GetSetting(GameSetting.GamepadInUse) == 1 then
        local v = LocalPlayer:GetVehicle()
        if self:LandCheck(v) or self:BoatCheck(v) or self:HeliCheck(v) or self:PlaneCheck(v) then
          self:Boost()
        end
      end
    end
  end
end

function Boost:Render()
  if not self:IsDriver() then return end
  if LocalPlayer:GetWorld() ~= DefaultWorld then return end

  local v     = LocalPlayer:GetVehicle()
  local land  = self:LandCheck(v)
  local boat  = self:BoatCheck(v)
  local heli  = self:HeliCheck(v)
  local plane = self:PlaneCheck(v)

  -- Boost
  local v = LocalPlayer:GetVehicle()
  if land or boat then
    if Key:IsDown(160) then -- LShift
      self:Boost()
    end
  elseif heli or plane then
    if Key:IsDown(81) then -- Q
      self:Boost()
    end
  end

  -- Text
  if self.textEnabled and (land or boat or heli or plane) then
    local text = "Hold "
    if land or boat then
      text = text .. "SHIFT "
    elseif heli or plane then
      text = text .. "Q "
    end
    if self.padEnabled then
      text = text .. "or LB "
    end
    text = text .. "to boost"

    local size = Render:GetTextSize(text, 18)
    local pos = Vector2((Render.Width - size.x) / 2, Render.Height - size.y - 10)

    Render:DrawText(pos + Vector2.One, text, Color(0, 0, 0, 180), 18)
    Render:DrawText(pos, text, Color.White, 18)
  end
end

function Boost:ResolutionChange()
  self.window:SetPositionRel(Vector2(0.5, 0.5) - self.window:GetSizeRel() / 2)
end

function Boost:AddSetting(text, setting, value, default)
  local checkBox = LabeledCheckBox.Create(self.window)
  checkBox:SetSize(Vector2(200, 20))
  checkBox:SetDock(GwenPosition.Top)
  checkBox:GetLabel():SetText(text)
  checkBox:GetCheckBox():SetChecked(value)
  checkBox:GetCheckBox():Subscribe("CheckChanged", function(box)
    self:UpdateSetting(setting, box:GetChecked(), default) end)
end

function Boost:UpdateSetting(setting, value, default)
  self[setting] = value

  -- Translate for DB
  if value == default then
    value = nil
  else
    value = value and 1 or 0
  end

  Network:Send("ChangeSetting", {setting = setting, value = value})
end

function Boost:Boost()
  if self.timer:GetMilliseconds() > self.interval then
  	local v = LocalPlayer:GetVehicle()
  	if IsValid(v) then
  		local forward = v:GetAngle() * Vector3(0, 0, -1 * self.multiplier)
  		v:SetLinearVelocity(v:GetLinearVelocity() + forward)
  	end
    self.timer:Restart()
  end
end

function Boost:IsDriver()
  return LocalPlayer:InVehicle() and LocalPlayer == LocalPlayer:GetVehicle():GetDriver()
end

function Boost:LandCheck(vehicle)
  local id = vehicle:GetModelId()
  return self.landBoost and not self.boats[id] and not self.helis[id] and not self.planes[id]
end

function Boost:BoatCheck(vehicle)
  return self.boatBoost and self.boats[vehicle:GetModelId()]
end

function Boost:HeliCheck(vehicle)
  return self.heliBoost and self.helis[vehicle:GetModelId()]
end

function Boost:PlaneCheck(vehicle)
  return self.planeBoost and self.planes[vehicle:GetModelId()]
end

local boost = Boost()