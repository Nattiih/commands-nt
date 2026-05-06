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
local ActivePunishments = {}  
-----------------------------------------------------------------------------------------------------------------------------------------
-- COMMAND: /punir [id] [tempo em segundos]
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("punir",function(source,args)
	local Passport = vRP.Passport(source)
	if not Passport then
		return
	end

	if not vRP.HasGroup(Passport,Config.AdminGroup) then
		TriggerClientEvent("Notify",source,"Sistema","Você não tem permissão.","vermelho",5000)
		return
	end

	local targetId = tonumber(args[1])
	local duration = tonumber(args[2]) or Config.DefaultTime

	if not targetId or not GetPlayerName(targetId) then
		TriggerClientEvent("Notify",source,"Sistema","Use: /punir [id] [tempo]","amarelo",5000)
		return
	end

	if duration > Config.MaxTime then
		duration = Config.MaxTime
	end

	if ActivePunishments[targetId] then
		TriggerClientEvent("Notify",source,"Sistema","Jogador já está punido.","amarelo",5000)
		return
	end

	ActivePunishments[targetId] = os.time() + duration

	TriggerClientEvent("nt_punishment:Init",targetId)
	TriggerClientEvent("Notify",source,"Sistema","Jogador "..targetId.." punido por "..duration.."s.","verde",5000)

	SetTimeout(duration * 1000,function()
		if ActivePunishments[targetId] and GetPlayerName(targetId) then
			ActivePunishments[targetId] = nil
			TriggerClientEvent("nt_punishment:Stop",targetId)
		end
	end)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- COMMAND: /despunir [id]
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("despunir",function(source,args)
	local Passport = vRP.Passport(source)
	if not Passport then
		return
	end

	if not vRP.HasGroup(Passport,Config.AdminGroup) then
		TriggerClientEvent("Notify",source,"Sistema","Você não tem permissão.","vermelho",5000)
		return
	end

	local targetId = tonumber(args[1])
	if not targetId or not GetPlayerName(targetId) then
		TriggerClientEvent("Notify",source,"Sistema","Use: /despunir [id]","amarelo",5000)
		return
	end

	if not ActivePunishments[targetId] then
		TriggerClientEvent("Notify",source,"Sistema","Jogador não está punido.","amarelo",5000)
		return
	end

	ActivePunishments[targetId] = nil
	TriggerClientEvent("nt_punishment:Stop",targetId)
	TriggerClientEvent("Notify",source,"Sistema","Jogador "..targetId.." liberado.","verde",5000)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HANDLE DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("playerDropped",function()
	local source = source
	if ActivePunishments[source] then
		ActivePunishments[source] = nil
	end
end)
