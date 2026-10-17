-- Shared helper for RemoteEvents/RemoteFunctions.
-- The server creates remotes on first use; clients wait for them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local IS_SERVER = RunService:IsServer()
local FOLDER_NAME = "Remotes"

local Net = {}

local function getFolder(): Folder
	if IS_SERVER then
		local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = FOLDER_NAME
			folder.Parent = ReplicatedStorage
		end
		return folder
	end
	return ReplicatedStorage:WaitForChild(FOLDER_NAME)
end

local function getRemote(className: string, name: string)
	local folder = getFolder()
	if IS_SERVER then
		local remote = folder:FindFirstChild(name)
		if not remote then
			remote = Instance.new(className)
			remote.Name = name
			remote.Parent = folder
		end
		return remote
	end
	return folder:WaitForChild(name)
end

function Net.Event(name: string): RemoteEvent
	return getRemote("RemoteEvent", name)
end

function Net.Function(name: string): RemoteFunction
	return getRemote("RemoteFunction", name)
end

return Net
