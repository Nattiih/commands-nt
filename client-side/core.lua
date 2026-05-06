v-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
Punishment = {}
Tunnel.bindInterface("nt_punishment",Punishment)
vSERVER = Tunnel.getInterface("nt_punishment")
LocalPlayer["state"]:set("Punishment-nt",false,true)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local IsPunished = false

local BlockedControls = {
	24,  -- LMB Attack
	25,  -- RMB Aim
	140, -- R Attack light
	142, -- LMB Alternate
	257, -- LMB Attack2
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- INIT PUNISHMENT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("nt_punishment:Init",function()
	if IsPunished then
		return
	end

	IsPunished = true
	LocalPlayer["state"]:set("Punishment-nt",true,true)
	TriggerEvent("Notify","Modo Punição","Você foi punido. Siga as regras na próxima vez.","vermelho",5000)

	local playerId = PlayerId()
	local controlsCount = #BlockedControls

	CreateThread(function()
		while IsPunished do
			SetPlayerCanDoDriveBy(playerId,false)
			DisablePlayerFiring(playerId,true)

			for i = 1,controlsCount do
				DisableControlAction(0,BlockedControls[i],true)
			end

			Wait(0)
		end
	end)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- STOP PUNISHMENT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("nt_punishment:Stop",function()
	if not IsPunished then
		return
	end

	IsPunished = false
	LocalPlayer["state"]:set("Punishment-nt",false,true)
	TriggerEvent("Notify","Modo Punição","Você foi liberado da punição.","verde",5000)
end)
