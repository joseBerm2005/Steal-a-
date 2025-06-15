local Config = require(script.Parent.Config)
local Proximity = require(script.Parent.Proximity)
local NPCManager = require(script.Parent.NPCManager)


local NetworkManager = {}

local function findNPC(npcid : number)

	for _, npc in pairs(game.Workspace.NPCS:GetChildren()) do
		if npc:GetAttribute("NPCID") then
	
			if npc:GetAttribute("NPCID") == tonumber(npcid) then
				return npc
			end
		end
	end
end

local function hideProximityPrompt(ProxPrompt)
	ProxPrompt.Enabled = false
end

function NetworkManager:Initialize(NPCManager, TimeSync, EventBuffer)
	self.NPCManager = NPCManager
	self.TimeSync = TimeSync
	self.EventBuffer = EventBuffer
	self:SetupEventConnections()

	-- Request initial sync when client loads
	self:RequestInitialSync()
end

function NetworkManager:RequestInitialSync()
	-- Wait a moment for everything to load, then request sync
	task.wait(2)
	game.ReplicatedStorage.Events.NPCSyncRequest:FireServer()
end

function NetworkManager:SetupEventConnections()
	-- Remove the bulk sync handler since we're using spawn events
	-- Config.Events.NPCSyncRequest.OnClientEvent:Connect(function(serializedData)

	-- Handle time sync
	Config.Events.TimeSync.OnClientEvent:Connect(function(serializedData)
		local Sera = require(game:GetService("ReplicatedStorage").Modules.Replication.Sera)
		local Schemas = require(script.Parent.Schemas)

		local syncData = Sera.Deserialize(Schemas.TimeSyncSchema, serializedData)
		if syncData then
			self.TimeSync:UpdateTimeSync(syncData.ServerTime)
		else
		end
	end)
	
	Config.Events.UpdateProxs.OnClientEvent:Connect(function(npcBuyOrSteal, hideProxFrom)
		-- Validate input
		if type(npcBuyOrSteal) ~= "table" or type(hideProxFrom) ~= "table" then
			warn("Invalid proximity update data received")
			return
		end


		-- Process each NPC with error handling
		for npcId, actionType in pairs(npcBuyOrSteal) do
			local npcModel = findNPC(npcId)

			if npcModel then

				if npcModel.PrimaryPart:FindFirstChild(actionType) then continue end

				local proximityPrompt = Proximity.new(npcModel.PrimaryPart,actionType)

			else
			end

		end

		-- Process hide/show with error handling
		for npcID, shouldHide in pairs(hideProxFrom) do
			local success, errorMsg = pcall(function()
				local npcModel = findNPC(npcID)

				if npcModel then
					for _, prox in pairs(npcModel:GetDescendants()) do
						if prox:IsA("ProximityPrompt") then
							if shouldHide then
								hideProximityPrompt(prox)
							else
								prox.Enabled = true -- Make sure to show it
							end
						end
					end
				else
				end
			end)

			if not success then
				warn("Error processing hide operation for NPC", npcID, ":", errorMsg)
			end
		end
	end)

	local activeNPCAnimations = {}
	
	local activeNPCAttachments = {}

	
	
	-- find npc from npc id in the npcs folder
	-- weld npc to player
	-- use motor6ds to have a holding animation
	-- modify ncps motor6ds to be laying down (also rotate npc to be laying down)
	Config.Events.StealNPC.OnClientEvent:Connect(function(player, NPCID)
		local StolenNPC = findNPC(NPCID)
		
		print("hi")
		
		if activeNPCAttachments[NPCID] then
			for i,v in pairs(activeNPCAttachments[NPCID]) do
				if typeof(v) == "Instance" then
					v:Destroy()
				end
			end
		end

		if StolenNPC and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then

			
			local EatingNPC = game.Workspace.NPCS:WaitForChild(StolenNPC.Name.."NPC")
			
			if EatingNPC then
				
				-- this is the npcs npc (not the food npc)
				if EatingNPC:GetAttribute("NPC_ID") == tonumber(NPCID) then
					EatingNPC:Destroy()
				end
			end

			-- ANCHOR NPC PARTS to prevent falling
			for _, part in pairs(StolenNPC:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
					part.Massless = true
					part.Anchored = true
					part.TopSurface = Enum.SurfaceType.Smooth
					part.BottomSurface = Enum.SurfaceType.Smooth
					
					part.Size = part.Size * 2
				end
			end

			-- Remove ONLY external constraints, NOT internal Motor6Ds
			for _, obj in pairs(StolenNPC:GetDescendants()) do
				if obj:IsA("BodyPosition") or obj:IsA("BodyVelocity") or obj:IsA("BodyAngularVelocity") or obj:IsA("BodyThrust") then
					obj:Destroy()
				elseif obj:IsA("WeldConstraint") then
					-- Only remove WeldConstraints that connect to external objects
					local part0, part1 = obj.Part0, obj.Part1
					if part0 and part1 then
						local part0InNPC = part0:IsDescendantOf(StolenNPC)
						local part1InNPC = part1:IsDescendantOf(StolenNPC)
						-- If one part is outside the NPC, remove the constraint
						if not (part0InNPC and part1InNPC) then
							obj:Destroy()
						end
					end
				elseif obj:IsA("Motor6D") then
					-- Only remove Motor6Ds that connect to external objects
					local part0, part1 = obj.Part0, obj.Part1
					if part0 and part1 then
						local part0InNPC = part0:IsDescendantOf(StolenNPC)
						local part1InNPC = part1:IsDescendantOf(StolenNPC)
						-- If one part is outside the NPC, remove the constraint
						if not (part0InNPC and part1InNPC) then
							obj:Destroy()
						end
					end
				end
			end

			-- Position NPC behind player
			StolenNPC.PrimaryPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -2)

			-- CRITICAL: Ensure player humanoid is not affected
			local playerHumanoid = player.Character.Humanoid
			playerHumanoid.PlatformStand = false
			playerHumanoid.Sit = false

			-- Wait for physics to settle
			game:GetService("RunService").Heartbeat:Wait()

			-- UNANCHOR before creating Motor6D
			for _, part in pairs(StolenNPC:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = false
				end
			end

			-- Create Motor6D for attachment
			local motor6D = Instance.new("Motor6D")
			motor6D.Name = "NPCAttachment"
			motor6D.Part0 = player.Character.UpperTorso
			motor6D.Part1 = StolenNPC.PrimaryPart
			motor6D.C0 = CFrame.new()
			motor6D.C1 = CFrame.new(0, 0, -1.5)
			motor6D.Parent = player.Character.UpperTorso
			
			if activeNPCAttachments[NPCID] then
					table.insert(activeNPCAttachments[NPCID], motor6D)
			else
					activeNPCAttachments[NPCID] = {
					[1] = motor6D
				}
			end

			-- Load and play animations AFTER attachment
			--local NPCAnim = StolenNPC.Humanoid.Animator:LoadAnimation(game.ReplicatedStorage.Animations.DummyRide)
			local playerAnim = player.Character.Humanoid.Animator:LoadAnimation(game.ReplicatedStorage.Animations.PlayerRide)

			--NPCAnim.Looped = true
			playerAnim.Looped = true

			--NPCAnim:Play()
			playerAnim:Play()

			-- Ensure player can move
			game:GetService("RunService").Heartbeat:Wait()
			playerHumanoid:ChangeState(Enum.HumanoidStateType.Running)

		end
	end)
	
	Config.Events.PlaceNPC.OnClientEvent:Connect(function(npcId, mainPad, character, NpcName : string)
		local npcToPlace = findNPC(npcId)
		
		if npcToPlace == nil then
			print(NpcName)
			local npcToPlace = self.NPCManager:CreateIdleNPC(npcId, NpcName, mainPad)
			
			print(npcToPlace)
		end

		if npcToPlace then
			print("npc found in place npc :3")

			-- Configure NPC parts
			for _, part in pairs(npcToPlace:GetDescendants()) do
				if part:IsA("BasePart") or part:IsA("MeshPart") then
					part.CanCollide = false
					part.Massless = true
					part.Anchored = true
					part.TopSurface = Enum.SurfaceType.Smooth
					part.BottomSurface = Enum.SurfaceType.Smooth
				end
			end

			-- Remove Motor6D attachment
			if activeNPCAttachments[npcId] then
				for i,v in pairs(activeNPCAttachments[npcId]) do
					if typeof(v) == "Instance" then
						v:Destroy()
					end
				end
			end

			-- Stop character animations
			local CharHum = character:FindFirstChild("Humanoid")
			if CharHum then
				local CharAnimator = CharHum:FindFirstChild("Animator")
				if CharAnimator then
					for _, animTrack in pairs(CharAnimator:GetPlayingAnimationTracks()) do
						animTrack:Stop(0)
					end
				end
			end

			-- Position the NPC
			npcToPlace:PivotTo(CFrame.new(mainPad.MainPart.Position + Vector3.new(0,3,0)))

		end
	end)
	
	
	-- Handle new NPC spawns (including bulk sync)
	Config.Events.NPCSpawnEvent.OnClientEvent:Connect(function(serializedData)
		if not self.EventBuffer:IsClientReady() then
			self.EventBuffer:BufferSpawnEvent(serializedData)
			return
		end

		self.NPCManager:HandleSpawnEvent(serializedData)
	end)

	-- Handle NPC batch updates
	Config.Events.NPCBatchEvent.OnClientEvent:Connect(function(serializedData)
		if not self.EventBuffer:IsClientReady() then
			self.EventBuffer:BufferBatchEvent(serializedData)
			return
		end

		self.NPCManager:HandleBatchEvent(serializedData)
	end)

	-- Handle NPC destruction
	Config.Events.NPCDestroyEvent.OnClientEvent:Connect(function(serializedData)
		if not self.EventBuffer:IsClientReady() then
			self.EventBuffer:BufferDestroyEvent(serializedData)
			return
		end

		self.NPCManager:HandleDestroyEvent(serializedData)
	end)

	-- Handle NPC redirects
	Config.Events.NPCRedirectEvent.OnClientEvent:Connect(function(serializedData)
		if not self.EventBuffer:IsClientReady() then
			self.EventBuffer:BufferRedirectEvent(serializedData)
			return
		end

		self.NPCManager:HandleRedirectEvent(serializedData)
	end)
end

return NetworkManager