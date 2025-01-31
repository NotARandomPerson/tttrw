GM.Name    = "Trouble in Terrorist Town Rewrite"
GM.Author  = "Meepen <https://steamcommunity.com/id/meepen>"
GM.Email   = "meepdarknessmeep@gmail.com"
GM.Website = "https://github.com/meepen"

DeriveGamemode "base"
DEFINE_BASECLASS "gamemode_base"

IN_USE_ALT = IN_CANCEL

ttt = ttt or GM or {}

PLAYER = FindMetaTable "Player"

function PLAYER:GetEyeTrace(mask)
	return util.TraceLine {
		start = self:EyePos(),
		endpos = self:EyePos() + self:GetAimVector() * 0xffff,
		mask = mask,
		filter = self,
	}
end

white_text = Color(230, 230, 230, 255)

function PLAYER:IsActive()
	return self:Alive()
end

function PLAYER:IsSpec()
	return not self:IsActive()
end

AccessorFunc(PLAYER, "Target", "Target")
AccessorFunc(PLAYER, "TargetDisguised", "TargetDisguised")
ENTITY = FindMetaTable "Entity"

function PLAYER:SetTarget(target)
	self.Target = target
	hook.Run("PlayerTargetChanged", self, target)
end

function PLAYER:SetTargetDisguised(disguised)
	self.TargetDisguised = disguised
end

function printf(...)
	print(string.format(...))
end

function warn(...)
	MsgC(Color(240,20,20), string.format(...))
	MsgN ""
end

function startswithvowel(phrase)
	if (not phrase or not isstring(phrase)) then
		return false
	end

	phrase = string.lower(phrase)

	for _, starter in ipairs({"uni", "ump"}) do -- Sometimes starts with u but has a "yu" sound
		if string.StartWith(phrase, starter) then
			return false
		end
	end

	for _, starter in ipairs({"a", "e", "i", "o", "u", "xm", "sg", "m4", "mp", "m2", "r3", "stg", "8"}) do -- Sometimes starts with a non-vowel but read aloud with a vowel sound
		if string.StartWith(phrase, starter) then
			return true
		end
	end

	return false
end

function GM:InitPostEntity()
	self:InitPostEntity_Networking()
	if (SERVER) then
		self:SetupTextFileEntities()
	end
end

function GM:Initialize()
	self:SetupRoles()
	if (SERVER) then
		self:SetupTTTCompatibleEntities()
		self:TrackCurrentCommit()
	end
end

function GM:PlayerTick(ply)
	player_manager.RunClass(ply, "Think")
	if (SERVER) then
		self:Drown(ply)

		if (ply.propspec) then
			self:SpectatePropRecharge(ply)
		end
	end
end

function GM:StartCommand(ply, cmd)
	if (SERVER and cmd.SetTickCount and VERSION <= 190730) then -- server is always one tick ahead for some reason :(
		cmd:SetTickCount(cmd:TickCount() - 1)
	end
	-- fixes some hitreg issues
	-- causes issues with props!
	-- ply:SetAngles(Angle(0, cmd:GetViewAngles().y))

	local wep = ply:GetActiveWeapon()
	if (IsValid(wep) and wep.OverrideCommand) then
		wep:OverrideCommand(ply, cmd)
	end

	if (cmd:KeyDown(IN_USE)) then
		cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_USE_ALT))
	end

	if (cmd:KeyDown(IN_ZOOM)) then
		cmd:SetButtons(bit.bor(bit.band(bit.bnot(IN_ZOOM), cmd:GetButtons()), IN_GRENADE2))
	end

	player_manager.RunClass(ply, "StartCommand", cmd)

	local ang = cmd:GetViewAngles()
	ang.r = 1
	cmd:SetViewAngles(ang)
end

function GM:ScalePlayerDamage(ply, hitgroup, dmg)
	if (SERVER) then
		self:Karma_ScalePlayerDamage(ply, hitgroup, dmg)
	end
end

function GM:KeyPress(ply, key)
	if (key == IN_GRENADE2 and CLIENT and IsFirstTimePredicted()) then
		RunConsoleCommand "ttt_radio"
	end

	if (self.VoiceKey) then
		self:VoiceKey(ply, key)
	end

	if (CLIENT and key == IN_USE_ALT and not IsValid(ttt.InspectMenu) and self:TryInspectBody(ply)) then
		return
	end

	if (key == IN_WEAPON1) then
		self:DropCurrentWeapon(ply)
	elseif (SERVER) then
		self:SpectatorKey(ply, key)
	end
end

TEAM_TERROR = 1
function GM:CreateTeams()
	team.SetUp(TEAM_TERROR, "Terrorist", Color(46, 192, 94), false)
end

-- do this here so we can format stuff clientside to predict it ourselves
function GM:FormatPlayerText(ply, text, team)
	local replacements = {}
	local capitalize = {}

	if (IsValid(ply.Target)) then
		if (ply.Target:IsPlayer()) then
			replacements["{target}"] = ply.TargetDisguised and "someone in disguise" or ply.Target:Nick()
			capitalize["{target}"] = ply.TargetDisguised
		elseif (IsValid(ply.Target.HiddenState) and ply.Target.HiddenState:GetIdentified()) then
			replacements["{target}"] = ply.Target.HiddenState:GetNick() .. "'s body"
		else
			replacements["{target}"] = "an unidentified body"
			capitalize["{target}"] = true
		end
	else
		replacements["{target}"] = "nobody"
		capitalize["{target}"] = true
	end
	
	capitalize["{lookingat}"] = capitalize["{target}"]
	replacements["{lookingat}"] = replacements["{target}"]

	local amount = 0

	return text:gsub("()({.+})", function(ind, what)
		local replace = replacements[what]

		if (ind == 1 and capitalize[what] and replace) then
			replace = replace:sub(1, 1):upper() .. replace:sub(2)
			amount = amount + 1
		end

		return replace
	end), amount
end

function GM:EntityFireBullets(ent, data)
	return true
end