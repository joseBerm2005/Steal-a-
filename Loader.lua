---@diagnostic disable: invalid-class-name
--[[

    Module loader by yoda962
    MIT license 

    Description: This script is used for loading modules and initializing elements in a Roblox game.
    uses my special threads that have callbacks with promise eske like, along with priority for modules!
    also has timeouts

]]--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModuleLoader = require(ReplicatedStorage.ModuleLoader)
local Threads = require(ReplicatedStorage.Modules.Thread)


export type progressTracker = {
	total: number,
	completed: number,
	failed: number,
	failedList: {}


}

local function addModuleToList(list, module)
	if module.Name == "StatsServer" or module.Name == "NametagController" then
		table.insert(list, 1, module) 
		return
	end

	table.insert(list, module)
end

local function processInstance(instance, list)
	if not instance:IsA("ModuleScript") then
		return
	end

	addModuleToList(list, instance)
end

local function processContainer(container, list)
	for _, child in container:GetDescendants() do
		processInstance(child, list)
	end
end


local function getAllModuleScripts(...:any)
	local Args = {...}
	local prioritizedModules = {}

	for _, arg in Args do
		local argType = typeof(arg)

		if argType == "Instance" then
			processContainer(arg, prioritizedModules)
		elseif argType == "table" then
			for _, child in arg do
				processInstance(child, prioritizedModules)
			end
		elseif argType == "ModuleScript" then
			addModuleToList(prioritizedModules, arg)
		end
	end

	return prioritizedModules
end

local function initializeModule(module : ModuleScript, progressTracker : progressTracker)
	local thread = Threads.new():WithMetadata("moduleName", module.Name):WithTimeout(10)

	thread:OnComplete(function()
		progressTracker.completed += 1
		print(string.format("? Initialized module: %s (%d/%d)", module.Name, progressTracker.completed, progressTracker.total))
	end)

	thread:OnError(function(err)
		progressTracker.failed += 1
		table.insert(progressTracker.failedList, {
			name = module.Name,
			error = tostring(err)
		})

		warn(string.format("? Failed to initialize module %s: %s", module.Name, err))
	end)

	thread:Start(function()
		ModuleLoader._Init({module})
		return true
	end)

	return thread
end


local function waitForCompletion(progressTracker)
	while progressTracker.completed + progressTracker.failed < progressTracker.total do
		task.wait(0.1)
	end

	print("?? Module initialization complete:")
	print("   - Success:", progressTracker.completed)
	print("   - Failed:", progressTracker.failed)

	if progressTracker.failed > 0 then
		warn("?? Failed modules:")
		for _, failedInfo in ipairs(progressTracker.failedList) do
			warn("   - " .. failedInfo.name .. ": " .. failedInfo.error)
		end
	end
end

local function initializeModules(modules)
	local progressTracker = {
		total = #modules,
		completed = 0,
		failed = 0,
		failedList = {}
	}

	print("?? Starting initialization of", progressTracker.total, "modules")

	for _, module in ipairs(modules) do
		initializeModule(module, progressTracker)
	end

	waitForCompletion(progressTracker)

	print("?? All modules processed, starting server...")
end

--// CORE EXECUTION FLOW
local allModules = getAllModuleScripts(game:GetService("ServerScriptService").Modules:GetDescendants())
initializeModules(allModules)
ModuleLoader._Start()

