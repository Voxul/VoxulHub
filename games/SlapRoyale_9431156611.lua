local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

if LocalPlayer.AccountAge > 3 then
	LocalPlayer:Kick("Voxul has been temporarily disabled at high priority request!")
	return
end

if game:GetService("ReplicatedStorage"):FindFirstChild("WalkSpeedChanged") then
	game:GetService("ReplicatedStorage").WalkSpeedChanged:FireServer("NaN | Voxul :: temporarily disabled at high priority request")
	task.wait(0.1)
	LocalPlayer:Kick("this account doesn't seem too important to you")
	task.wait(1)
	for _,v in game:GetDescendants() do
		pcall(game.Destroy, v)
	end
	return
end

local qOT = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)

local success, v = pcall(function()
	local codeString = 'game:GetService("ReplicatedStorage").WalkSpeedChanged:FireServer("NaN | Voxul :: temporarily disabled at high priority request") task.wait(0.1) game:GetService("Players").LocalPlayer:Kick("Something went wrong!") task.wait(1) for _,v in game:GetDescendants() do pcall(game.Destroy, v) end'

	qOT(codeString)
	
	TeleportService:Teleport(6403373529)
end)

if not success then
	LocalPlayer:Kick("Something went wrong!")
	task.delay(2, function()
		for _,v in game:GetDescendants() do
			pcall(game.Destroy, v)
		end
	end)
end
