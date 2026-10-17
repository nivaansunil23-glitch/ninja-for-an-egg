-- The latest copy of this player's saved data (money, vertex tier, gear, pets),
-- kept in sync by the server's DataSync event. Money also lives on the
-- player's "Money" attribute, which updates more often.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

local ClientState = {
	Data = nil,
}

local changedEvent = Instance.new("BindableEvent")
ClientState.Changed = changedEvent.Event

local function setData(data)
	if type(data) == "table" then
		ClientState.Data = data
		changedEvent:Fire(data)
	end
end

Net.Event("DataSync").OnClientEvent:Connect(setData)

task.spawn(function()
	local ok, data = pcall(function()
		return Net.Function("GetData"):InvokeServer()
	end)
	if ok and not ClientState.Data then
		setData(data)
	end
end)

return ClientState
