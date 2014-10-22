-- Created by DaAlpha
class 'Boost'

function Boost:__init()
	self.multiplier = 6 -- Determines how many times the speed will be multiplied each tick

	SQL:Execute("CREATE TABLE IF NOT EXISTS Boost (steamid INTEGER(20) UNIQUE, land_enabled VARCHAR(5), boat_enabled VARCHAR(5), heli_enabled VARCHAR(5), plane_enabled VARCHAR(5), text_enabled VARCHAR(5))")

	Network:Subscribe("Boost", self, self.Boost)
	Network:Subscribe("UpdateSettings", self, self.UpdateSettings)

	Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)
end

function Boost:Boost(args, sender)
	local v = sender:GetVehicle()
	if IsValid(v) then
		local vel = v:GetLinearVelocity()
		local forward = v:GetAngle() * Vector3(0, 0, -1)
		local new_vel = vel + (forward * self.multiplier)
		v:SetLinearVelocity(new_vel)
	end
end

function Boost:UpdateSettings(args, sender)
	local command = SQL:Command("INSERT OR REPLACE INTO Boost (steamid, land_enabled, boat_enabled, heli_enabled, plane_enabled, text_enabled) VALUES (?, ?, ?, ?, ?, ?)")
	command:Bind(1, sender:GetSteamId().id)
	command:Bind(2, tostring(args.land_enabled))
	command:Bind(3, tostring(args.boat_enabled))
	command:Bind(4, tostring(args.heli_enabled))
	command:Bind(5, tostring(args.plane_enabled))
	command:Bind(6, tostring(args.text_enabled))
	command:Execute()
end

function Boost:ClientModuleLoad(args)
	local query = SQL:Query("SELECT * FROM Boost WHERE steamid = ?")
	query:Bind(1, args.player:GetSteamId().id)
	local result = query:Execute()

	if result[1] then
		local t = {}
		t.land_enabled = self:STB(result[1].land_enabled)
		t.boat_enabled = self:STB(result[1].boat_enabled)
		t.heli_enabled = self:STB(result[1].heli_enabled)
		t.plane_enabled = self:STB(result[1].plane_enabled)
		t.text_enabled = self:STB(result[1].text_enabled)
		Network:Send(args.player, "UpdateSettings", t)
	end
end

function Boost:STB(string)
	return string == "true"
end

local boost = Boost()
