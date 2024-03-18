-- Slap Royale (PID 9431156611)
local getgenv = getgenv or getfenv
if not game:IsLoaded() then game.Loaded:Wait() end

-- Services
local CoreGui:CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatsService = game:GetService("Stats")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Events = ReplicatedStorage.Events
local MatchInfo = ReplicatedStorage.MatchInfo

-- other thingies
local LocalPlr = Players.LocalPlayer
local Character = LocalPlr.Character or LocalPlr.CharacterAdded:Wait()
local HumanoidRootPart:BasePart = Character:WaitForChild("HumanoidRootPart")
Character.PrimaryPart = HumanoidRootPart
local Humanoid:Humanoid = Character:WaitForChild("Humanoid")

LocalPlr.CharacterAdded:Connect(function(char)
	Character = char
	HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
	char.PrimaryPart = HumanoidRootPart
	Humanoid = char:WaitForChild("Humanoid")
end)

local gloveName:StringValue = LocalPlr.Glove

local permanentItems = {"Boba", "Bull's essence", "Frog Brew", "Frog Potion", "Potion of Strength", "Speed Brew", "Speed Potion", "Strength Brew"}
local healingItems = {"Apple", "Bandage", "Boba", "First Aid Kit", "Healing Brew", "Healing Potion"}

-- functions
local dataPingItem = StatsService.Network:WaitForChild("ServerStatsItem"):WaitForChild("Data Ping")
local function getDataPing():number
	local a
	xpcall(function()
		a = dataPingItem:GetValue()/1000
	end, function()
		a = LocalPlr:GetNetworkPing() + .2
	end)
	return a
end

local function pivotModelTo(model:Model, cFrame:CFrame, removeVelocity:boolean?)
	model:PivotTo(cFrame)
	if not removeVelocity then return end
	for _,v in model:GetDescendants() do
		if v:IsA("BasePart") then
			v.AssemblyLinearVelocity = Vector3.zero
			v.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

local function getModelClosestChild(model:Model, position:Vector3)
	local closestPart, closestMagnitude = nil, nil

	for _,v in model:GetChildren() do
		if v:IsA("BasePart") then
			local magnitude = (v.Position-position).Magnitude
			if not closestPart or magnitude < closestMagnitude then
				closestPart = v
				closestMagnitude = magnitude
			end
		end
	end

	return closestPart
end

local function lerpVector3WithSpeed(a:Vector3, goal:Vector3, speed:number, moveTick:number, maxAlpha:number?)
	return a:Lerp(goal, math.min(speed/(a-goal).Magnitude * (os.clock()-moveTick), maxAlpha or 1))
end

local function canHitPlayer(player:Player, checkVulnerability:boolean?)
	if player == LocalPlr then return false end
	local char = player.Character
	if not char or not char:FindFirstChild("Humanoid") or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Head") then return false end
	if not char.inMatch.Value or char:FindFirstChild("Dead") or char.Humanoid.Health <= 0 then return false end
	
	if checkVulnerability then
		if char.Ragdolled.Value or not char.Vulnerable.Value or char.Head.Transparency == 1 and not char:FindFirstChildWhichIsA("Tool") and not player.Backpack:FindFirstChildWhichIsA("Tool") then return false end
	end
	
	return true
end

local function safeEquipTool(tool:Tool, activate:boolean?, immediateUnequip:boolean?)
	if tool:FindFirstChild("Handle") then
		for _,v in tool:GetDescendants() do
			if v:IsA("BasePart") then
				v.Massless = true
				v.Anchored = false
			end
		end
		tool.PrimaryPart = tool.PrimaryPart or tool.Handle
		pivotModelTo(tool, HumanoidRootPart.CFrame, true)
	end
	pcall(Humanoid.EquipTool, Humanoid, tool)
	if activate then tool:Activate() end
	if immediateUnequip then Humanoid:UnequipTools() end
end

local function useAllToolsOfNames(names:{string}, intervalFunc:any?)
	local itemsUsed = 0
	for _,v in LocalPlr.Backpack:GetChildren() do
		if v:IsA("Tool") and table.find(names, v.Name) then
			safeEquipTool(v, true)
			itemsUsed += 1
			if intervalFunc and intervalFunc(itemsUsed) == "break" then break end
		end
	end
end

-- disable exploit countermeasures (anti-anticheat)
-- Remote Blocker
local blockedRemotes = {[Events.WS] = "FireServer", [Events.WS2] = "FireServer"}

local bypass; bypass = hookmetamethod(game, "__namecall", function(remote, ...)
	if blockedRemotes[remote] == true or blockedRemotes[remote] == getnamecallmethod() then return end
	return bypass(remote, ...)
end)

workspace.Map.OriginOffice:WaitForChild("Antiaccess").CanTouch = false


local OrionLib = loadstring(game:HttpGet(getgenv().VoxulLib or 'https://raw.githubusercontent.com/shlexware/Orion/main/source'))()
local Window = OrionLib:MakeWindow(getgenv().VoxulWindowCONF or {Name = "Voxul", HidePremium = false, SaveConfig = false, ConfigFolder = "Voxul_ORIONLIB", IntroEnabled = true, IntroText = "Voxul", IntroIcon = "http://www.roblox.com/asset/?id=6035039429"})

-- Home
local Tab_Home = Window:MakeTab({
	Name = "Home",
	Icon = "http://www.roblox.com/asset/?id=6035145364",
	PremiumOnly = false
})

Tab_Home:AddLabel("made with ♡ by voxul~")
Tab_Home:AddButton({
	Name = "Destroy GUI",
	Callback = function()
		OrionLib:Destroy()
	end
})
Tab_Home:AddToggle({
	Name = "Save Configuration",
	Default = true,
	Callback = function(v)
		OrionLib.SaveCfg = v
		if not v then
			delfile(OrionLib.Folder .. "/" .. game.PlaceId .. ".txt")
		end
	end,
	Save = true,
	Flag = "SaveConfig"
})
Tab_Home:AddButton({
	Name = "Infinite Yield",
	Callback = function()
		OrionLib:MakeNotification({
			Name = "Voxul Hub",
			Content = "Loading InfiniteYield...",
			Image = "http://www.roblox.com/asset/?id=6034934023",
			Time = 5
		})
		loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
	end
})

-- Items
local Tab_Items = Window:MakeTab({
	Name = "Items",
	Icon = "http://www.roblox.com/asset/?id=6034767621"
})

Tab_Items:AddLabel("All features below will activate when the match starts")
local ItemVacSection = Tab_Items:AddSection({
	Name = "Item Vacuum"
})
ItemVacSection:AddDropdown({
	Name = "Item Vacuum Mode",
	Default = "Disabled",
	Options = {"Disabled", "Pick Up", "Tween (WIP)", "Teleport (WIP)", "Hybrid (WIP)"},
	Save = true,
	Flag = "ItemVacMode"
})
ItemVacSection:AddToggle({
	Name = "Vacuum Dropped Items",
	Default = false,
	Save = true,
	Flag = "DroppedItemVac"
})

local AutoItemSection = Tab_Items:AddSection({
	Name = "Auto Item Usage"
})
AutoItemSection:AddToggle({
	Name = "Bomb Bus",
	Default = false,
	Save = true,
	Flag = "AutoBombBus"
})
AutoItemSection:AddToggle({
	Name = "Cube of Ice",
	Default = false,
	Save = true,
	Flag = "AutoIceCube"
})
AutoItemSection:AddToggle({
	Name = "Permanent True Power",
	Default = false,
	Save = true,
	Flag = "AutoTruePower"
})
AutoItemSection:AddToggle({
	Name = "Permanent items",
	Default = false,
	Save = true,
	Flag = "AutoPermItem"
})

-- Combat
local Tab_Combat = Window:MakeTab({
	Name = "Combat",
	Icon = "http://www.roblox.com/asset/?id=6034837802"
})

local AutoHeal = Tab_Combat:AddSection({
	Name = "Auto-Heal"
})
AutoHeal:AddToggle({
	Name = "Enabled",
	Default = false,
	Save = true,
	Flag = "AutoHeal"
})
AutoHeal:AddSlider({
	Name = "Activation Health",
	Min = 0,
	Max = 600,
	Default = 30,
	Increment = 1,
	ValueName = "HP",
	Save = true,
	Flag = "HealLowHP"
})
AutoHeal:AddSlider({
	Name = "Safe Health",
	Min = 0,
	Max = 600,
	Default = 80,
	Increment = 1,
	ValueName = "HP",
	Save = true,
	Flag = "HealSafeHP"
})
local healdebounce = false
local function heal()
	if healdebounce then return end
	if not OrionLib.Flags["AutoHeal"].Value then return end
	healdebounce = true
	
	print("Healing...")
	OrionLib:MakeNotification({
		Name = "Auto Heal",
		Content = "Healing to safe health...",
		Image = "http://www.roblox.com/asset/?id=6034684956",
		Time = 3
	})
	
	useAllToolsOfNames(healingItems, function()
		task.wait(getDataPing()+0.05)
		if Humanoid.Health >= OrionLib.Flags["HealSafeHP"].Value or Character:FindFirstChild("Dead") then return "break" end
	end)
	healdebounce = false
end

Humanoid.HealthChanged:Connect(function(health)
	if health <= OrionLib.Flags["HealLowHP"].Value then heal() end
end)

local SlapAuraSection = Tab_Combat:AddSection({
	Name = "Slap Aura"
})
local friends = {}
SlapAuraSection:AddToggle({
	Name = "Enabled",
	Default = false,
	Callback = function(v)
		if not v then return end
		while OrionLib.Flags["SlapAura"].Value and task.wait() do
			if not Character:FindFirstChild(gloveName.Value) then continue end
			for _,v in Players:GetPlayers() do
				if friends[v.UserId] and OrionLib.Flags["SlapAuraFriendly"] or not canHitPlayer(v) then 
					continue 
				elseif friends[v.UserId] == nil then
					friends[v.UserId] = false
					task.spawn(function()
						friends[v.UserId] = LocalPlr:IsFriendsWith(v.UserId)
					end)
				end
				
				local distance = (v.Character.HumanoidRootPart.Position-HumanoidRootPart.Position).Magnitude
				if distance > OrionLib.Flags["SlapAuraRange"].Value then continue end
				
				Events.Slap:FireServer(getModelClosestChild(v.Character, HumanoidRootPart.Position))
				Events.Slap:FireServer(v.Character.HumanoidRootPart)
				
				if OrionLib.Flags["SlapAuraAnim"].Value then
					Character[gloveName.Value]:Activate()
				end
				
				if distance < 6 and canHitPlayer(v, true) and OrionLib.Flags["SlapAuraCooldown"].Value > 0 then
					task.wait(OrionLib.Flags["SlapAuraCooldown"].Value)
				end
			end
		end
	end,
	Save = true,
	Flag = "SlapAura"
})
SlapAuraSection:AddBind({
	Name = "Quick Toggle Bind",
	Default = Enum.KeyCode.Q,
	Hold = false,
	Callback = function()
		OrionLib.Flags["SlapAura"]:Set(not OrionLib.Flags["SlapAura"].Value)
	end,
	Save = true,
	Flag = "SlapAuraBind"
})
SlapAuraSection:AddSlider({
	Name = "Aura Radius",
	Min = 0,
	Max = 25,
	Default = 25,
	Increment = 0.5,
	ValueName = "Studs",
	Save = true,
	Flag = "SlapAuraRange"
})
SlapAuraSection:AddSlider({
	Name = "Slap Cooldown",
	Min = 0,
	Max = 2,
	Default = 0,
	Increment = 0.05,
	ValueName = "seconds",
	Save = true,
	Flag = "SlapAuraCooldown"
})
SlapAuraSection:AddToggle({
	Name = "Ignore Friends",
	Default = false,
	Save = true,
	Flag = "SlapAuraFriendly"
})
SlapAuraSection:AddToggle({
	Name = "Slap Animation",
	Default = false,
	Save = true,
	Flag = "SlapAuraAnim"
})

local AutoWinSection = Tab_Combat:AddSection({
	Name = "Auto-Win (OP)"
})
AutoWinSection:AddLabel("Not done!!!!")
AutoWinSection:AddDropdown({
	Name = "Auto-Win Mode",
	Default = "Disabled",
	Options = {"Disabled", "Tween", "Teleport (WIP)", "Hybrid (WIP)"},
	Save = true,
	Flag = "AutoWinMode"
})
AutoWinSection:AddSlider({
	Name = "Tween Speed",
	Min = 0,
	Max = 500,
	Default = 0,
	Increment = 1,
	ValueName = "studs/second",
	Save = true,
	Flag = "AutoWinTweenSpeed"
})
AutoWinSection:AddToggle({
	Name = "Allow Gliding Targets",
	Default = true,
	Save = true,
	Flag = "AutoWinGlidingTargets"
})
AutoWinSection:AddToggle({
	Name = "Lag Compensation",
	Default = true,
	Save = true,
	Flag = "AutoWinLagAdjust"
})
AutoWinSection:AddToggle({
	Name = "Optimizations",
	Default = true,
	Save = true,
	Flag = "AutoWinOptimizations"
})

-- Player
local Tab_Player = Window:MakeTab({
	Name = "Player",
	Icon = "http://www.roblox.com/asset/?id=4335489011"
})

local PlrMovement = Tab_Player:AddSection({
	Name = "Movement"
})
PlrMovement:AddSlider({
	Name = "WalkSpeed",
	Min = 0,
	Max = 800,
	Default = 20,
	Increment = 1,
	ValueName = "WS",
	Callback = function(v)
		Humanoid.WalkSpeed = v
	end,
	Save = false,
	Flag = "WalkSpeed"
})
PlrMovement:AddToggle({
	Name = "Persistent WalkSpeed",
	Default = false,
	Save = true,
	Flag = "SpeedPersist"
})
local sprinting = false
Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
	if OrionLib.Flags["SpeedPersist"].Value and not sprinting then
		Humanoid.WalkSpeed = OrionLib.Flags["WalkSpeed"].Value
	end
end)
PlrMovement:AddSlider({
	Name = "JumpPower",
	Min = 0,
	Max = 800,
	Default = 50,
	Increment = 1,
	ValueName = "JP",
	Callback = function(v)
		Humanoid.JumpPower = v
	end,
	Save = false,
	Flag = "JumpPower"
})
PlrMovement:AddToggle({
	Name = "Persistent JumpPower",
	Default = false,
	Save = true,
	Flag = "JumpPowerPersist"
})
Humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
	if OrionLib.Flags["JumpPowerPersist"].Value then
		Humanoid.JumpPower = OrionLib.Flags["JumpPower"].Value
	end
end)
PlrMovement:AddToggle({
	Name = "Auto-Jump Enabled",
	Default = false,
	Callback = function(v)
		LocalPlr.AutoJumpEnabled = v
		Humanoid.AutoJumpEnabled = v
	end,
	Save = true,
	Flag = "AutoJumpEnabled"
})
PlrMovement:AddToggle({
	Name = "Sprint Enabled",
	Default = true,
	Save = true,
	Flag = "SprintEnabled"
})
PlrMovement:AddSlider({
	Name = "Sprint Speed",
	Min = 0,
	Max = 800,
	Default = 30,
	Increment = 1,
	ValueName = "WS",
	Save = true,
	Flag = "SprintSpeed"
})
PlrMovement:AddBind({
	Name = "Sprint KeyBind",
	Default = Enum.KeyCode.LeftShift,
	Hold = true,
	Callback = function(v)
		sprinting = v
		if v then
			Humanoid.WalkSpeed = OrionLib.Flags["SprintSpeed"].Value
		else
			Humanoid.WalkSpeed = OrionLib.Flags["WalkSpeed"].Value
		end
	end,
	Save = true,
	Flag = "SprintBind"
})

-- Misc
local Tab_Misc = Window:MakeTab({
	Name = "Misc",
	Icon = "http://www.roblox.com/asset/?id=4370318685"
})

local lobbyViewerPart = Instance.new("Part", workspace)
lobbyViewerPart.Anchored = true
lobbyViewerPart.Transparency = 1
lobbyViewerPart.CanCollide = false
local lobbyhiding = false
Tab_Misc:AddToggle({
	Name = "Hide in lobby",
	Default = false,
	Callback = function(v)
		lobbyhiding = v
		if not v or not workspace:FindFirstChild("Lobby") then return end
		
		lobbyViewerPart.Position = HumanoidRootPart.Position
		local cframe = HumanoidRootPart.CFrame
		while lobbyhiding and workspace:FindFirstChild("Lobby") do
			workspace.CurrentCamera.CameraSubject = lobbyViewerPart
			pivotModelTo(Character, cframe + Vector3.new(math.random(), 150, math.random()), true)
			task.wait()
		end
		workspace.CurrentCamera.CameraSubject = Humanoid
		pivotModelTo(Character, cframe, true)
	end,
	Save = true,
	Flag = "LobbyHider"
})

local AutoVotekicker = Tab_Misc:AddSection({
	Name = "Auto Votekick"
})
AutoVotekicker:AddLabel("Toggle in lobby")
AutoVotekicker:AddToggle({
	Name = "Enabled",
	Default = false,
	Save = true,
	Flag = "AutoVotekick"
})
AutoVotekicker:AddSlider({
	Name = "Delay (+3 seconds to sync with match start completion)",
	Min = 0,
	Max = 13,
	Default = 3,
	Increment = 0.05,
	ValueName = "seconds",
	Save = true,
	Flag = "AutoVotekickDelay"
})
AutoVotekicker:AddDropdown({
	Name = "Reason",
	Default = "Exploiting",
	Options = {"Bypassing", "Exploiting", "None"},
	Save = true,
	Flag = "AutoVotekickReason"
})
AutoVotekicker:AddDropdown({
	Name = "Vote Decision",
	Default = "Agree",
	Options = {"Agree", "Disagree", "None"},
	Save = true,
	Flag = "AutoVotekickDecision"
})

local AutoBusJumper = Tab_Misc:AddSection({
	Name = "Auto Bus Jump"
})
AutoBusJumper:AddToggle({
	Name = "Enabled",
	Default = false,
	Save = true,
	Flag = "AutoBusJump"
})
AutoBusJumper:AddToggle({
	Name = "Wait for Prompt",
	Default = false,
	Save = true,
	Flag = "BusJumpOnPrompt"
})
AutoBusJumper:AddToggle({
	Name = "Instant Land",
	Default = false,
	Save = true,
	Flag = "LandOnBusJump"
})

local AntiBarriers = Tab_Misc:AddSection({
	Name = "Anti Barrier/Hazards"
})
AntiBarriers:AddToggle({
	Name = "Safe Acid",
	Default = false,
	Callback = function(v)
		for _,v1 in workspace.Map.AcidAbnormality:GetChildren() do
			if v1.Name == "Acid" and v1:IsA("BasePart") and v1:FindFirstChildWhichIsA("TouchTransmitter") then
				v1.CanTouch = not v
			end
		end
	end,
	Save = true,
	Flag = "AntiAcid"
})
AntiBarriers:AddToggle({
	Name = "Acid Collision",
	Default = false,
	Callback = function(v)
		for _,v1 in workspace.Map.AcidAbnormality:GetChildren() do
			if v1.Name == "Acid" and v1:IsA("BasePart") and v1:FindFirstChildWhichIsA("TouchTransmitter") then
				v1.CanCollide = v
			end
		end
	end,
	Save = true,
	Flag = "SolidAcid"
})
AntiBarriers:AddToggle({
	Name = "Safe Lava",
	Default = false,
	Callback = function(v)
		workspace.Map.DragonDepths:WaitForChild("Lava").CanTouch = not v
	end,
	Save = true,
	Flag = "AntiLava"
})
AntiBarriers:AddToggle({
	Name = "Lava Collision",
	Default = false,
	Callback = function(v)
		workspace.Map.DragonDepths:WaitForChild("Lava").CanCollide = v
	end,
	Save = true,
	Flag = "SolidLava"
})

-- Init
OrionLib:Init()

if not MatchInfo.Started.Value then
	MatchInfo.Started.Changed:Wait()
end

-- AutoVotekick
local votekickReasons = {Bypassing = 1, Exploiting = 2}
local votekickChoices = {Agree = true, Disagree = false}
if OrionLib.Flags["AutoVotekick"].Value then
	task.delay(OrionLib.Flags["AutoVotekickDelay"].Value, function()
		local players = Players:GetPlayers()
		table.remove(players, table.find(players, LocalPlr))
		local selected = players[math.random(1, #players)].Name
		print("Votekicking "..selected)
		-- ( PlayerName:string, isVoting:boolean, reason:string? | vote:boolean )
		Events.Votekick:FireServer(selected, false, votekickReasons[OrionLib.Flags["AutoVotekickReason"].Value])
		if OrionLib.Flags["AutoVotekickDecision"].Value ~= "None" then
			task.wait()
			Events.Votekick:FireServer(selected, true, votekickChoices[OrionLib.Flags["AutoVotekickDecision"].Value])
		end
	end)
end

--[[if not MatchInfo.StartingCompleted.Value then
	MatchInfo.StartingCompleted.Changed:Wait()
	print("starting complete")
end]]

if workspace:FindFirstChild("Lobby") then 
	workspace.Lobby.AncestryChanged:Wait()
end

workspace.CurrentCamera.CameraSubject = Humanoid

-- items
local itemVacModes = {
	["Disabled"] = function() end,
	["Tween"] = function() warn("Function not available yet!") end,
	["Teleport"] = function() warn("Function not available yet!") end,
	["Pick Up"] = function()
		local function pickUpTool(v:Tool)
			if not v:IsA("Tool") then return end
			safeEquipTool(v, false, true)
			v.Equipped:Once(function()
				v.AncestryChanged:Connect(function(_,p)
					if p ~= Character then return end
					task.defer(v.Activate, v)
				end)
			end)
		end

		for _,v in workspace.Items:GetChildren() do
			pickUpTool(v)
		end
		workspace.Items.ChildAdded:Connect(function(c)
			if not OrionLib.Flags["DroppedItemVac"].Value then return end
			task.wait()
			pickUpTool(c)
		end)
		workspace.Items.ChildRemoved:Wait()
		task.wait(getDataPing())
	end,
}
itemVacModes[OrionLib.Flags["ItemVacMode"].Value]()

if OrionLib.Flags["AutoBombBus"].Value then
	useAllToolsOfNames({"Bomb"}, function(i)
		if i%4 == 3 then heal() end
	end)
	task.wait(getDataPing())
end
if OrionLib.Flags["AutoTruePower"].Value then
	local firstTruePower = nil
	for _,v in LocalPlr.Backpack:GetChildren() do
		if v:IsA("Tool") and v.Name == "True Power" then
			if firstTruePower then
				print("Perma True Power")
				safeEquipTool(firstTruePower, true)
				task.wait(0.3 + getDataPing())
				safeEquipTool(v, true)
				task.wait(5.2 + getDataPing())
				break
			end
			firstTruePower = v
		end
	end
	task.wait(getDataPing())
end
if OrionLib.Flags["AutoIceCube"].Value then
	useAllToolsOfNames({"Cube of Ice"})
	task.wait(getDataPing())
end
if OrionLib.Flags["AutoPermItem"].Value then
	task.spawn(function()
		while gloveName.Value == "Pack-A-Punch" and not Character:FindFirstChild("Pack-A-Punch") and not LocalPlr.Backpack:FindFirstChild("Pack-A-Punch") do 
			task.wait() 
		end
		task.wait(0.1)
		useAllToolsOfNames(permanentItems)
	end)
end

if OrionLib.Flags["AutoBusJump"].Value and Character.Head.Transparency == 1 then
	while Character.Ragdolled.Value or OrionLib.Flags["BusJumpOnPrompt"].Value and not LocalPlr.PlayerGui:FindFirstChild("JumpPrompt") do
		task.wait()
	end

	Events.BusJumping:FireServer()
	
	if OrionLib.Flags["LandOnBusJump"].Value then
		local rayParam = RaycastParams.new()
		rayParam.FilterDescendantsInstances = {workspace.Terrain}
		rayParam.FilterType = Enum.RaycastFilterType.Include
		
		local ray
		for _ = 1, 10 do
			ray = workspace:Raycast(HumanoidRootPart.Position, Vector3.new(0,-500,0), rayParam)
			if ray then break else task.wait() end
		end
		
		local landingPos
		if ray then
			landingPos = CFrame.new(ray.Position + Vector3.new(0,2.5,0))
		else
			OrionLib:MakeNotification({
				Name = "Instant Land",
				Content = "Failed to find ground, defaulting to y-300",
				Image = "http://www.roblox.com/asset/?id=6034457092",
				Time = 5
			})
			landingPos = HumanoidRootPart.CFrame - Vector3.new(0,300,0)
		end
		
		local jumpTimeoutStart = os.clock()
		while (os.clock()-jumpTimeoutStart < 3 or Character.Ragdolled.Value) and not Character:FindFirstChild(gloveName.Value) and not LocalPlr.Backpack:FindFirstChild(gloveName.Value) do
			pivotModelTo(Character, landingPos, true)
			task.wait()
		end
		pivotModelTo(Character, landingPos, true)
	end
	
	local jpAddCon:RBXScriptConnection; jpAddCon = LocalPlr.PlayerGui.ChildAdded:Connect(function(c)
		if c.Name == "JumpPrompt" then task.defer(game.Destroy, c); jpAddCon:Disconnect() end
	end)
end
