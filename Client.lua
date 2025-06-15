--!strict
--[[

	--------------------
	TABLE_OF_CONTENTS
	Author -- yoda962 (yoda_06 discord)
	
	last modified 4/11/2025

]]

type ModuleWithInit = {
	init: (self: any) -> () 
}

local Client = {}

Client.player = game:GetService("Players").LocalPlayer :: Player
Client.playerGui = Client.player:WaitForChild("PlayerGui") :: PlayerGui
Client.mouse = Client.player:GetMouse() :: Mouse
Client.camera = workspace.CurrentCamera :: Camera

Client.character = nil :: Model?

Client.CanSprint = true

repeat task.wait() until game:IsLoaded()

Client.player.CharacterRemoving:Connect(function(character: Model)
	Client.character = nil
end)

Client.player.CharacterAdded:Connect(function(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	Client.character = character

	humanoid.Died:Connect(function()
		Client.character = nil
	end)
end)

function Client.init()
	for _, moduleScript in ipairs(script.Modules:GetDescendants()) do
		if not moduleScript:IsA("ModuleScript") then continue end

		local success, requiredModule = pcall(function()
			return require(moduleScript) :: ModuleWithInit
		end)

		if success and typeof(requiredModule) == "table" and typeof(requiredModule.init) == "function" then
			requiredModule.init()
		end
	end
end

return Client
