local Players = game:GetService("Players")

local Config = require(script.Parent.Config)
local NetworkManager = require(script.Parent.NetworkManager)
local NPCManager = require(script.Parent.NPCManager)

local DataLoader = require(script.Parent.Parent.Parent.Data.DataLoader)

local PlayerManager = {}


local PlayersAwaitingSync = {}

function PlayerManager:Initialize()
	self:SetupEventConnections()
	self:StartBackupSyncSystem()
end

function PlayerManager:SetupEventConnections()
	
	Config.Events.ClientReady.OnServerEvent:Connect(function(player)
		self:HandleClientReady(player)
	end)


	Players.PlayerAdded:Connect(function(player)
		self:HandlePlayerAdded(player)
	end)

	
	Players.PlayerRemoving:Connect(function(player)
		self:HandlePlayerRemoving(player)
	end)

	
	Config.Events.NPCSyncRequest.OnServerEvent:Connect(function(player)
		self:HandleManualSyncRequest(player)
	end)
end

function PlayerManager:HandleClientReady(player)
	print("Client ready:", player.Name)
	PlayersAwaitingSync[player] = nil

	NetworkManager:SendTimeSync(player)
	task.wait(Config.SYNC_DELAY)
	self:SyncActiveNPCsToPlayer(player)
end

function PlayerManager:HandlePlayerAdded(player : Player)

	repeat task.wait() until player.Character

	PlayersAwaitingSync[player] = tick() + Config.PLAYER_SYNC_TIMEOUT
end

function PlayerManager:HandlePlayerRemoving(player)

	PlayersAwaitingSync[player] = nil
end

function PlayerManager:HandleManualSyncRequest(player)
	
	NetworkManager:SendTimeSync(player)
	
	task.wait(Config.SYNC_DELAY)
	
	self:SyncActiveNPCsToPlayer(player)
end

function PlayerManager:SyncActiveNPCsToPlayer(player)
	local NPCManager = require(script.Parent.NPCManager)
	local activeNPCs, serverTime = NPCManager:GetActiveNPCs()
	NetworkManager:SendNPCBulkSync(player, activeNPCs, serverTime)
end

function PlayerManager:StartBackupSyncSystem()
	task.spawn(function()
		while true do
			task.wait(2)
			local currentTime = tick()

			for player, timeoutTime in pairs(PlayersAwaitingSync) do
				if currentTime > timeoutTime then
					
					self:SyncActiveNPCsToPlayer(player)
					PlayersAwaitingSync[player] = nil
				end
			end
		end
	end)
end

return PlayerManager