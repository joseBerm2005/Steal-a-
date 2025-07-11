local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")


local NPCManager = require(ServerScriptService.Modules.Core.MoveServer.NPCManager)
local Bases = require(ServerScriptService.Modules.Core.Bases)
local DataLoader = require(ServerScriptService.Modules.Data.DataLoader)

local Modules = ReplicatedStorage.Modules
local Shared = Modules.Shared

local NPC_Info = require(Shared.NPC_INFO)

-- check npcsinplots for npcs and get their income info from npcinfo
while task.wait(1) do
	local NPCTbl = NPCManager.NPCsInPlots -- get the table where npcs are stored in plots
	
	local PendingMoneyTbl = Bases.pendingMoneyTbl -- get the money table
	
	-- loop through npc tbl and add the money to the player
	for npcid, info in pairs(NPCTbl) do
		local playerData = DataLoader.GetReplica(info.player)
	
		-- if table with npcid exists then just add money (else new table is made)
		if PendingMoneyTbl[npcid] then
		
			PendingMoneyTbl[npcid].money += NPC_Info.NPCS[info.npcName].Base_Gen
			PendingMoneyTbl[npcid].spot.Collect.BillboardGui.TextLabel.Text = "Collect: <br/> <font color='#53ff1e'>"..PendingMoneyTbl[npcid].money.." </font>"
		else
		
			PendingMoneyTbl[npcid] = {
				player = info.player,
				spot = info.spot,
				money = NPC_Info.NPCS[info.npcName].Base_Gen,
				Base = info.Base
			}
		end
	end
end


Players.PlayerRemoving:Connect(function(player)
	local NPCTbl = NPCManager.NPCsInPlots
	local StolenTbl = NPCManager.StolenNPCsOutOfPlots
	local PendingMoneyTbl = Bases.pendingMoneyTbl
	for npcid, info in pairs(NPCTbl) do
		if info.player == player.Name then
			if PendingMoneyTbl[npcid] then
				PendingMoneyTbl[npcid].player = nil
				PendingMoneyTbl[npcid].spot:SetAttribute("NPC", nil)
				-- remove npcs remote
			end
			
						


			NPCTbl[npcid] = nil
		end
	end
	for npcid, info in pairs(StolenTbl) do
		if info.player == player.Name then
			
			-- if og owner aint there anymore then no one gets it fr lel
			if not Players[info.OriginalOwner] then StolenTbl[npcid] = nil return end
			
			NPCManager.NPCsInPlots[npcid] = {
				player = info.OriginalOwner,
				Base = info.Base,
				spot = info.spot,
				npcName = info.npcName
			}
			
			StolenTbl[npcid] = nil
		end
	end
end)
