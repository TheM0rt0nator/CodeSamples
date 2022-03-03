local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local TestService = game:GetService("TestService")
local RunService = game:GetService("RunService")

local SHARED_MODULE_PATHS = {
	ReplicatedStorage.SharedScripts;
	ReplicatedStorage.ZenithFramework.Libraries;
}
local SERVER_MODULES_PATH
local CLIENT_MODULES_PATH = StarterPlayer.StarterPlayerScripts.ClientScripts

local LoadedSignal = Instance.new("BindableEvent")

local Promise = require(ReplicatedStorage.ZenithFramework.Libraries.Promise)
local Roact = ReplicatedStorage.ZenithFramework.Libraries.Roact

local ModuleScriptLoader = {}
ModuleScriptLoader.__index = ModuleScriptLoader

-- Creates new module loader which can be used to reference any module in the above paths
function ModuleScriptLoader.new(loadLocation)
	local self = setmetatable({}, ModuleScriptLoader)

	self._modules = {}

	if loadLocation == "Server" then
		SERVER_MODULES_PATH = ServerScriptService.ServerScripts
	end

	self:AddModules(loadLocation)
	self:AddModules("Shared")

	return self
end

-- Yields until all of the modules have been loaded
function ModuleScriptLoader:WaitForLoad()
	if not self.modulesLoaded then
		LoadedSignal:Wait()
	end
end

-- Loads all the module scripts in _modules
function ModuleScriptLoader:LoadAll()
	local loadedModules = {}
	Promise.new(function(resolve)
		for moduleName, module in pairs(self._modules) do
			-- Don't load Roact components due to them being locked by metatables
			if module ~= Roact and not module:IsDescendantOf(Roact) and (module:GetAttribute("AutoLoad") == nil or module:GetAttribute("AutoLoad")) then
				local loadedModule = require(module)
				if typeof(loadedModule) == "table" and loadedModule.initiate and typeof(loadedModule.initiate) == "function" then
					loadedModule:initiate()
				end
				loadedModules[moduleName] = loadedModule
			end
		end

		resolve()
	end):andThen(function()
		local env = RunService:IsServer() and "Server" or "Client"
		TestService:Message(env .. " loaded all modules successfully!")
	end):catch(function(err)
		warn("Failed to load all modules: " , err)
	end)

	return loadedModules
end

-- Looks for the module in the table and returns it if found
function ModuleScriptLoader:RequireModule(moduleName)
	assert(type(moduleName) == "string")

	if self._modules[moduleName] then
		return require(self._modules[moduleName])
	end
end

-- Adds modules from the given location to the ._modules table
function ModuleScriptLoader:AddModules(location)
	assert(type(location) == "string" and self["get" .. location .. "Modules"])

	for _, module in pairs(self["get" .. location .. "Modules"]()) do
		if not self._modules[module.Name] then
			self._modules[module.Name] = module
		end
	end
end

-- Returns a table of all module scripts in SHARED_MODULES_PATH
function ModuleScriptLoader.getSharedModules()
	local sharedModules = {}
	for _, path in pairs(SHARED_MODULE_PATHS) do
		for _, module in pairs(path:GetDescendants()) do
			if module:IsA("ModuleScript") then
				table.insert(sharedModules, module)
			end
		end
	end

	return sharedModules
end

-- Returns a table of all module scripts in SERVER_MODULES_PATH
function ModuleScriptLoader.getServerModules()
	local serverModules = {}
	for _, module in pairs(SERVER_MODULES_PATH:GetDescendants()) do
		if module:IsA("ModuleScript") then
			table.insert(serverModules, module)
		end
	end

	return serverModules
end

-- Returns a table of all module scripts in CLIENT_MODULES_PATH
function ModuleScriptLoader.getClientModules()
	local clientModules = {}
	for _, module in pairs(CLIENT_MODULES_PATH:GetDescendants()) do
		if module:IsA("ModuleScript") then
			table.insert(clientModules, module)
		end
	end

	return clientModules
end

-- When the loader is called, requires the given module name and returns it
function ModuleScriptLoader:__call(moduleName)
	return self:RequireModule(moduleName)
end

return ModuleScriptLoader