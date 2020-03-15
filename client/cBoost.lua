-- Created by DaAlpha
class 'Boost'

function Boost:__init()
  -- Settings
  self.landKey          = 160
  self.landKeyText      = "SHIFT"
  self.airKey           = 81
  self.airKeyText       = "Q"
  self.controllerAction = Action.VehicleFireLeft
  self.controllerText   = "LB"

  -- Default Settings
  self.strength           = 100
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
  self.windowOpen   = false
  self.delta        = 0

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
  Events:Subscribe("ModuleLoad", self, self.ModuleLoad)
  Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
  Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
end

function Boost:UpdateSettings(settings)
  -- Unsubscribe
  Network:Unsubscribe(self.settingSub)
  self.settingSub = nil

  -- Apply settings if given
  if settings then
    for setting, value in pairs(settings) do
      self[setting] = value == 1
    end
  end

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

function Boost:Render(args)
  if LocalPlayer:GetWorld() ~= DefaultWorld then return end

  local vehicle = LocalPlayer:GetVehicle()
  if not IsValid(vehicle) then return end
  if vehicle:GetDriver() ~= LocalPlayer then return end

  self.delta  = args.delta
  local land  = self:LandCheck(vehicle)
  local boat  = self:BoatCheck(vehicle)
  local heli  = self:HeliCheck(vehicle)
  local plane = self:PlaneCheck(vehicle)

  -- Boost
  if land or boat then
    if Key:IsDown(self.landKey) then
      self:Boost(vehicle)
    end
  elseif heli or plane then
    if Key:IsDown(self.airKey) then
      self:Boost(vehicle)
    end
  end

  -- Text
  if self.textEnabled and (land or boat or heli or plane) then
    local text = "Hold "
    if land or boat then
      text = text .. self.landKeyText .. " "
    elseif heli or plane then
      text = text .. self.airKeyText .. " "
    end
    if self.padEnabled then
      text = text .. "or " .. self.controllerText .. " "
    end
    text = text .. "to boost"

    local size = Render:GetTextSize(text, 18)
    local pos = Vector2((Render.Width - size.x) / 2, Render.Height - size.y - 10)

    Render:DrawText(pos + Vector2.One, text, Color(0, 0, 0, 180), 18)
    Render:DrawText(pos, text, Color.White, 18)
  end
end

function Boost:ModuleLoad()
  Events:Fire("HelpAddItem", {
    name = "Boost",
    text =
      "Press Shift in a boat or land vehicle or Q in an air vehicle to boost.\n \n" ..
      "Press LB on an Xbox Controller to boost in any type of vehicle.\n \n" ..
      "Type /boost in chat to open the boost settings window.\n \n" ..
      "Advanced Boost (public version) by DaAlpha, creator and owner of Alpha's Salt Factory"
  })
end

function Boost:ModuleUnload()
  Events:Fire("HelpRemoveItem", {name = "Boost"})
end

function Boost:LocalPlayerChat(args)
  if args.text:lower() == "/boost" then
    self:SetWindowOpen(true)
    return false
  end
end

function Boost:LocalPlayerInput(args)
  if self.windowOpen then return false end
  if self.padEnabled
      and args.input == self.controllerAction
      and LocalPlayer:GetWorld() == DefaultWorld
      and Game:GetSetting(GameSetting.GamepadInUse) == 1 then
    local vehicle = LocalPlayer:GetVehicle()
    if IsValid(vehicle) and vehicle:GetDriver() == LocalPlayer
        and (self:LandCheck(vehicle) or self:BoatCheck(vehicle)
        or self:HeliCheck(vehicle) or self:PlaneCheck(vehicle)) then
      self:Boost(vehicle)
    end
  end
end

function Boost:ResolutionChange()
  self.window:SetPositionRel(Vector2(0.5, 0.5) - self.window:GetSizeRel() / 2)
end

function Boost:SetWindowOpen(state)
  self.windowOpen = state
  self.window:SetVisible(state)
  Mouse:SetVisible(state)
end

function Boost:AddSetting(text, setting, value, default)
  local checkBox = LabeledCheckBox.Create(self.window)
  checkBox:SetSize(Vector2(200, 20))
  checkBox:SetDock(GwenPosition.Top)
  checkBox:GetLabel():SetText(text)
  checkBox:GetCheckBox():SetChecked(value)
  checkBox:GetCheckBox():Subscribe("CheckChanged", function(box)
    self:UpdateSetting(setting, box:GetChecked(), default)
  end)
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

function Boost:Boost(vehicle)
  vehicle:SetLinearVelocity(vehicle:GetLinearVelocity() +
    vehicle:GetAngle() * Vector3(0, 0, - self.strength * self.delta))
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

Boost()
