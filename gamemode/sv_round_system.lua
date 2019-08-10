local ttt_firstpreptime = CreateConVar("ttt_firstpreptime", "5", FCVAR_REPLICATED, "The wait time before the first round starts.")
local ttt_preptime_seconds = CreateConVar("ttt_preptime_seconds", "5", FCVAR_NONE, "The wait time before any round besides the first starts.")
local ttt_minimum_players = CreateConVar("ttt_minimum_players", "2", FCVAR_NONE, "Amount of players required before starting the round.")
local ttt_posttime_seconds = CreateConVar("ttt_posttime_seconds", "5", FCVAR_REPLICATED, "The wait time after a round has been completed.")
local ttt_roundtime_minutes = CreateConVar("ttt_roundtime_minutes", "10", FCVAR_REPLICATED, "The maximum length of a round.")

ttt.ActivePlayers = ttt.ActivePlayers or {}
round = round or {
	FirstRound = true,
	Players = {
		--[[
			{
				Player = entity,
				Nick = string,
				SteamID = string
			}
		]]
	},
	Started = {},
	CurrentePromise = nil
}

function round.SetState(state, time)
	ttt.SetRoundState(state)
	ttt.SetRoundTime(CurTime() + time)
	local prom = round.CurrentPromise

	if (prom) then
		timer.Remove("TTTRoundStatePromise")

		if (prom["fail"]) then
			prom["fail"](state, time)
		end
	end

	local promise = {
		_fail = function(self, fn)
			self["fail"] = fn
			return self
		end,
		_then = function(self, fn)
			self["then"] = fn
			return self
		end,
	}

	round.CurrentPromise = promise

	if (time) then
		timer.Create("TTTRoundStatePromise", time, 1, function()
			if (promise["then"]) then
				promise["then"](state, time)
			else
				warn("no then found for roundstate %s\n", ttt.Enums.RoundState[state])
			end
		end)
	end

	return promise
end


function round.GetActivePlayers()
	return round.Players
end

function round.GetStartingPlayers()
	return round.Started
end

function round.IsPlayerActive(ply)
	local plys = round.GetActivePlayers()
	for _, active in pairs(plys) do
		if (ply == active.Player) then
			return true
		end
	end

	return false
end

function round.RemovePlayer(ply)
	local plys = round.GetActivePlayers()
	for i, active in pairs(plys) do
		if (ply == active.Player) then
			table.remove(plys, i)
			hook.Run("TTTPlayerRemoved", ply)
			return true
		end
	end

	return false
end

function round.Prepare()
	if (ttt.GetRoundState() ~= ttt.ROUNDSTATE_WAITING and ttt.GetRoundState() ~= ttt.ROUNDSTATE_ENDED) then
		return
	end

	round.SetState(ttt.ROUNDSTATE_PREPARING, 0):_then(function()
		local eligible = ttt.GetEligiblePlayers()
		for _, ply in pairs(eligible) do
			ply:StripAmmo()
			ply:StripWeapons()
			ply:Spawn()
			ply:SetHealth(ply:GetMaxHealth())
			printf("%s <%s> has been respawned", ply:Nick(), ply:SteamID())
		end

		round.SetState(ttt.ROUNDSTATE_PREPARING, (round.FirstRound and ttt_firstpreptime or ttt_preptime_seconds):GetFloat()):_then(round.TryStart)
	end)
end


function round.TryStart()
	local plys = ttt.GetEligiblePlayers()
	if (#plys < ttt_minimum_players:GetInt()) then
		round.SetState(ttt.ROUNDSTATE_WAITING, 0)
		return false
	end

	local roles_needed = {}

	for role, info in pairs(ttt.roles) do
		if (info.CalculateAmount) then
			roles_needed[role] = info.CalculateAmount(#plys)
			if (roles_needed[role] == 0) then
				roles_needed[role] = nil
			end
		end
	end

	round.Players = {}
	for i, ply in RandomPairs(plys) do
		local role, amt = next(roles_needed)
		if (role) then
			if (amt == 1) then
				roles_needed[role] = nil
			else
				roles_needed[role] = amt - 1
			end
		else
			role = "Innocent"
		end

		round.Players[ply:UserID()] = {
			Player = ply,
			SteamID = ply:SteamID(),
			Nick = ply:Nick(),
			Role = ttt.roles[role]
		}
	end

	if (not hook.Run("TTTRoundStart", plys)) then
		printf("Round state is %i and failed to start round", ttt.GetRoundState())
		round.SetState(ttt.ROUNDSTATE_WAITING, 0)
		return false
	end

	round.Started = table.Copy(round.Players)

	printf("Round state is %i, we have enough players at %i, starting game", ttt.GetRoundState(), #plys)
	-- TODO(meep): setup variables

	round.SetState(ttt.ROUNDSTATE_ACTIVE, ttt_roundtime_minutes:GetFloat() * 60):_then(function()
		local winners = {}

		for _, ply in pairs(round.GetStartingPlayers()) do
			if (ply.Role.Team.Name == "innocent") then
				table.insert(winners, ply)
			end
		end

		round.End("innocent", winners)
	end)
	round.FirstRound = false
	return true
end

function round.End(winning_team, winners)
	hook.Run("TTTRoundEnd", winning_team, winners)
end

function GM:OnPlayerRoleChange(ply, old, new)
	for _, info in pairs(round.GetActivePlayers()) do
		if (info.Player == ply) then
			info.Role = ttt.roles[new]
		end
	end

	for _, info in pairs(round.GetStartingPlayers()) do
		if (info.Player == ply) then
			info.Role = ttt.roles[new]
		end
	end

	print "check"
	ttt.CheckTeamWin()
end

function GM:TTTRoundStart()
	for _, info in pairs(round.GetActivePlayers()) do
		if (IsValid(info.Player)) then
			info.Player:ChatPrint("Your role is "..info.Role.Name.." on team "..info.Role.Team.Name)
			info.Player:SetRole(info.Role.Name)
		end
		if (not info.Player:Alive()) then
			info.Player:Spawn()
		end
	end

	return true
end

function GM:TTTRoundEnd(winning_team, winners)
	local winner_names = {}
	local winner_ents  = {}

	for _, ply in pairs(winners) do
		table.insert(winner_names, ply.Nick)
		table.insert(winner_ents, ply.Player)
	end

	for _, ply in pairs(player.GetAll()) do
		ply:ChatPrint("Round is over, "..winning_team.." has won with players "..table.concat(winner_names, ", "))
	end

	round.SetState(ttt.ROUNDSTATE_ENDED, ttt_posttime_seconds:GetFloat()):_then(round.Prepare)
end

function GM:PlayerInitialSpawn(ply)
	local state = ents.Create("ttt_hidden_info")
	state:SetParent(ply)
	state:Spawn()
	ply:AllowFlashlight(true)
end

function GM:SV_PlayerSpawn(ply)
	local state = ttt.GetRoundState()
	ply:UnSpectate()

	if (state == ttt.ROUNDSTATE_WAITING) then
		round.Prepare()
	elseif (state ~= ttt.ROUNDSTATE_PREPARING) then
		printf("Player %s <%s> joined while round is active, killing silently", ply:Nick(), ply:SteamID())
		ply:KillSilent()
		-- TODO(meep): make spectator code
		return
	end

	hook.Run("PlayerLoadout", ply)
	hook.Run("PlayerSetModel", ply)

	local Role = ttt.roles[ply:GetRole()]

	hook.Run("PlayerSetSpeed", ply, Role.Speed, Role.RunSpeed)
end

function GM:PlayerSetSpeed(ply, walkspeed, runspeed)
	ply:SetWalkSpeed(walkspeed)
	ply:SetCrouchedWalkSpeed(0.2)
	ply:SetRunSpeed(runspeed or walkspeed)
end

function GM:PlayerDisconnected(ply)
	if (round.RemovePlayer(ply)) then
		printf("Player %s <%s> has disconnected while round is active", ply:Nick(), ply:SteamID())
		hook.Run("TTTActivePlayerDisconnected", ply)
	else
		printf("Player %s <%s> has disconnected", ply:Nick(), ply:SteamID())
	end
end

function GM:TTTHasRoundBeenWon(plys, roles)
	if (roles.innocent == 0) then
		return true, "traitor"
	end
	if (roles.traitor == 0) then
		return true, "innocent"
	end

	return false
end

function ttt.CheckTeamWin()
	local plys = round.GetActivePlayers()

	local roles = {}
	for team in pairs(ttt.teams) do
		roles[team] = 0
	end

	for _, ply in pairs(plys) do
		local team = ply.Role.Team.Name
		roles[team] = roles[team] + 1
	end

	local has_won, win_team, time_ran_out = hook.Run("TTTHasRoundBeenWon", plys, roles)

	if (has_won) then
		printf("Round has been won, team: %s, time limit reached: %s", win_team, time_ran_out and "true" or "false")

		local winners = {}

		for _, ply in pairs(round.GetStartingPlayers()) do
			if (ply.Role.Team.Name == win_team) then
				table.insert(winners, ply)
			end
		end

		round.End(win_team, winners)
	end
end

function GM:TTTPlayerRemoved(removed)
	if (IsValid(removed)) then
		removed:SetRole "Spectator"
	end

	self:TTTPlayerRemoveSpectate(removed)

	ttt.CheckTeamWin()
end


function GM:DoPlayerDeath(ply)
	ttt.CreatePlayerRagdoll(ply)
end


function GM:PlayerDeath(ply)
	round.RemovePlayer(ply)
end