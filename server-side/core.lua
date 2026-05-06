-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
Punishment = {}
Tunnel.bindInterface("nt_punishment",Punishment)
vCLIENT = Tunnel.getInterface("nt_punishment")
-----------------------------------------------------------------------------------------------------------------------------------------
-- QUERIES
-----------------------------------------------------------------------------------------------------------------------------------------
vRP.Prepare("nt_punishment/SetPunishment","INSERT INTO nt_punishments (passport,end_time,applied_by,applied_at) VALUES (@passport,@end_time,@applied_by,@applied_at) ON DUPLICATE KEY UPDATE end_time = @end_time, applied_by = @applied_by, applied_at = @applied_at")
vRP.Prepare("nt_punishment/GetPunishment","SELECT end_time FROM nt_punishments WHERE passport = @passport")
vRP.Prepare("nt_punishment/RemovePunishment","DELETE FROM nt_punishments WHERE passport = @passport")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONFIG
-----------------------------------------------------------------------------------------------------------------------------------------
local Config = {
	AdminGroup = "Admin",  -- grupo necessário para usar os comandos
	DefaultTime = 600,     -- tempo padrão em segundos (10 min)
	MaxTime = 3600,        -- tempo máximo permitido (1 hora)
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local ActiveTimers = {}  
local TokenCounter = 0
-----------------------------------------------------------------------------------------------------------------------------------------
-- HELPERS
-----------------------------------------------------------------------------------------------------------------------------------------
local function GenerateToken()
	TokenCounter = TokenCounter + 1
	return TokenCounter
end

local function GetSourceFromPassport(passport)
	for _,playerId in ipairs(GetPlayers()) do
		local source = tonumber(playerId)
		if source and vRP.Passport(source) == passport then
			return source
		end
	end
	return nil
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- APPLY PUNISHMENT 
-----------------------------------------------------------------------------------------------------------------------------------------
local function ApplyPunishment(source,passport,remainingSeconds)
	local token = GenerateToken()
	ActiveTimers[passport] = token

	TriggerClientEvent("nt_punishment:Init",source)

	SetTimeout(remainingSeconds * 1000,function()
		if ActiveTimers[passport] ~= token then
			return  
		end

		ActiveTimers[passport] = nil
		vRP.Execute("nt_punishment/RemovePunishment",{ passport = passport })

		local currentSource = GetSourceFromPassport(passport)
		if currentSource then
			TriggerClientEvent("nt_punishment:Stop",currentSource)
		end
	end)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- COMMAND: /punir [id] [tempo em segundos]
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("punir",function(source,args)
	local adminPassport = vRP.Passport(source)
	if not adminPassport then
		return
	end

	if not vRP.HasGroup(adminPassport,Config.AdminGroup) then
		TriggerClientEvent("Notify",source,"Sistema","Você não tem permissão.","vermelho",5000)
		return
	end

	local targetSource = tonumber(args[1])
	local duration = tonumber(args[2]) or Config.DefaultTime

	if not targetSource or not GetPlayerName(targetSource) then
		TriggerClientEvent("Notify",source,"Sistema","Use: /punir [id] [tempo]","amarelo",5000)
		return
	end

	local targetPassport = vRP.Passport(targetSource)
	if not targetPassport then
		TriggerClientEvent("Notify",source,"Sistema","Jogador inválido.","vermelho",5000)
		return
	end

	if duration > Config.MaxTime then
		duration = Config.MaxTime
	end

	local endTime = os.time() + duration

	vRP.Execute("nt_punishment/SetPunishment",{
		passport = targetPassport,
		end_time = endTime,
		applied_by = adminPassport,
		applied_at = os.time(),
	})

	ApplyPunishment(targetSource,targetPassport,duration)
	TriggerClientEvent("Notify",source,"Sistema","Jogador "..targetSource.." punido por "..duration.."s.","verde",5000)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- COMMAND: /despunir [id]
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("despunir",function(source,args)
	local adminPassport = vRP.Passport(source)
	if not adminPassport then
		return
	end

	if not vRP.HasGroup(adminPassport,Config.AdminGroup) then
		TriggerClientEvent("Notify",source,"Sistema","Você não tem permissão.","vermelho",5000)
		return
	end

	local targetSource = tonumber(args[1])
	if not targetSource or not GetPlayerName(targetSource) then
		TriggerClientEvent("Notify",source,"Sistema","Use: /despunir [id]","amarelo",5000)
		return
	end

	local targetPassport = vRP.Passport(targetSource)
	if not targetPassport then
		return
	end

	vRP.Execute("nt_punishment/RemovePunishment",{ passport = targetPassport })
	ActiveTimers[targetPassport] = nil

	TriggerClientEvent("nt_punishment:Stop",targetSource)
	TriggerClientEvent("Notify",source,"Sistema","Jogador "..targetSource.." liberado.","verde",5000)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHECK PUNISHMENT ON JOIN
-----------------------------------------------------------------------------------------------------------------------------------------
function Punishment.CheckPunishment()
	local source = source
	local passport = vRP.Passport(source)
	if not passport then
		return
	end

	local result = vRP.Query("nt_punishment/GetPunishment",{ passport = passport })
	if not result or not result[1] then
		return
	end

	local endTime = result[1]["end_time"]
	local now = os.time()

	if endTime <= now then
		vRP.Execute("nt_punishment/RemovePunishment",{ passport = passport })
		return
	end

	local remaining = endTime - now
	ApplyPunishment(source,passport,remaining)
end
