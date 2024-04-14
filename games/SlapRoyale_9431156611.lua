local Debris = game:GetService("Debris")

local vSOafmfmdkgu92 = Instance.new("BoolValue", workspace)
vSOafmfmdkgu92.Name = "A(*sfkVOXULSAAW2"
vSOafmfmdkgu92.Value = true
Debris:AddItem(vSOafmfmdkgu92, 3)

local vSOafmfmdkgu93 = Instance.new("BoolValue", workspace)
vSOafmfmdkgu93.Name = "A(*VOXUSNFakA@"
vSOafmfmdkgu93.Value = true
Debris:AddItem(vSOafmfmdkgu93, 2)

local function GETSECUREGUI()
	return gethui and gethui() or cloneref and cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui")
end

local function CREATEINST(CLASS:string, PARENT:Instance)
	local INST:Instance = Instance.new(CLASS)
	if addchildinternal then
		addchildinternal(PARENT, CLASS)
	else
		INST.Parent = PARENT
	end
	return INST
end

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

if game:GetService("ReplicatedStorage"):FindFirstChild("WalkSpeedChanged") then
	game:GetService("ReplicatedStorage").WalkSpeedChanged:FireServer("**Voxul** :: nuh uh, no you don't | disabled at high priority request")
	task.wait(0.1)
	LocalPlayer:Kick("ohhh no you don't")
	task.wait(1)
	local instancefetchmethod = getinstancecache or getinstances
	while task.wait() do
		for _,v in instancefetchmethod and instancefetchmethod() or game:GetDescendants() do
			pcall(game.Destroy, v)
		end
	end
	return
end

local qOT = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)

local success, v = pcall(function()
	local codeString = [[
game:GetService("ReplicatedStorage"):WaitForChild("WalkSpeedChanged"):FireServer("**Voxul** :: https://youtu.be/v_4u0qi21bY | disabled at high priority request")
task.wait(0.1)
game:GetService("Players").LocalPlayer:Kick("Something went wrong!")
task.wait(1)
local getinstancemethod = getinstancecache or getinstances
while task.wait() do
	for _,v in getinstancemethod and getinstancemethod() or game:GetDescendants() do
		pcall(game.Destroy, v)
	end
end
while true do Instance.new("Part") end
]]
	
	task.delay(0.2, function()
		game:GetService("CoreGui"):ClearAllChildren()
	end)
	
	qOT(codeString)
	TeleportService:Teleport(6403373529)
end)

if not success then
	LocalPlayer:Kick("Something went wrong!")
	task.wait(2)
	local getinstancemethod = getinstancecache or getinstances
	while task.wait() do
		for _,v:Instance in getinstancemethod and getinstancemethod() or game:GetDescendants() do
			pcall(function()
				if setparentinternal then
					setparentinternal(v, nil)
				else
					v.Parent = nil
				end
			end)
			pcall(game.Destroy, v)
		end
	end
	while true do Instance.new("Part") end
end
