local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

if game:GetService("ReplicatedStorage"):FindFirstChild("WalkSpeedChanged") then
	game:GetService("ReplicatedStorage").WalkSpeedChanged:FireServer("Voxul :: skill issue | disabled at high priority request")
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
	local codeString = 'game:GetService("ReplicatedStorage").WalkSpeedChanged:FireServer("**Voxul** :: https://youtu.be/v_4u0qi21bY | disabled at high priority request") task.wait(0.1) game:GetService("Players").LocalPlayer:Kick("Something went wrong!") task.wait(1) for _,v in game:GetDescendants() do pcall(game.Destroy, v) end'

	qOT(codeString)
	
	TeleportService:Teleport(6403373529)

	if LocalPlayer.Character then
		for _ = 1, 500 do
			LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			task.wait()
		end
	end
end)

if not success then
	LocalPlayer:Kick("Something went wrong!")
	task.delay(2, function()
		for _,v in game:GetDescendants() do
			pcall(game.Destroy, v)
		end
	end)
end
