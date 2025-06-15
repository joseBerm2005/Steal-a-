--!strict

local Random_NPC = {}
local NPC_INFO = require(game.ReplicatedStorage.Modules.Shared.NPC_INFO)

local rng = Random.new()

function Random_NPC:GetRandomNPCName(): string
	local weights = {}
	local totalWeight = 0

	for name, data in NPC_INFO.NPCS do
		local weight = 1 / data.rarity_chance
		weights[name] = weight
		totalWeight += weight
	end

	local choice = rng:NextNumber(0, totalWeight)
	local currentWeight = 0

	for name, weight in weights do
		currentWeight += weight
		if choice <= currentWeight then
			return name
		end
	end

	return "Unknown"
end

return Random_NPC
