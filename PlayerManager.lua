--!strict

local PlayerManager = {}
local ProfileLoader = require(game.ServerScriptService.Modules.Data.DataLoader)

function PlayerManager.CalculateTotalBoost(Player : Player): number
	local Profile = ProfileLoader.GetReplica(Player)
	local MoneyBoosts = Profile.Data.MoneyBoosts
	return MoneyBoosts.FriendBoost * MoneyBoosts.RebirthBoost
end

function PlayerManager.AddMoney(Player : Player, Amount : number)
	local Replica = ProfileLoader.GetReplica(Player)
	Replica:SetValue("Cash", Replica.Data.Cash + Amount)
end

return PlayerManager
