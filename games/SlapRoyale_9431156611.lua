-- Slap Royale (PID 9431156611)
local getgenv = getgenv or getfenv
if not game:IsLoaded() then game.Loaded:Wait() end

-- Services
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

local gloveName = LocalPlr.Glove

local permanentItems = {"Boba", "Bull's essence", "Frog Brew", "Frog Potion", "Potion of Strength", "Speed Brew", "Speed Potion", "Strength Brew"}
local healingItems = {"Apple", "Bandage", "Boba", "First Aid Kit", "Forcefield Crystal", "Healing Brew", "Healing Potion"}

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
	for _,v in LocalPlr.Backpack:GetChildren() do
		if v:IsA("Tool") and table.find(names, v.Name) then
			safeEquipTool(v, true)
			if intervalFunc and intervalFunc() == "break" then break end
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

local OrionLib = loadstring(game:HttpGet(getgenv().VoxulLib or 'https://raw.githubusercontent.com/shlexware/Orion/main/source'))()
local Window = OrionLib:MakeWindow(getgenv().VoxulWindowCONF or {Name = "Voxul", HidePremium = false, SaveConfig = false, ConfigFolder = "Voxul_ORIONLIB", IntroEnabled = true, IntroText = "Voxul", IntroIcon = "http://www.roblox.com/asset/?id=6035039429"})

-- Home
local Tab_Home = Window:MakeTab({
	Name = "Home",
	Icon = "http://www.roblox.com/asset/?id=6035145364",
	PremiumOnly = false
})

Tab_Home:AddLabel("Developed by Voxul")
Tab_Home:AddLabel("i gave up writing my own gui lib")
Tab_Home:AddButton({
	Name = "Destroy GUI",
	Callback = function()
		OrionLib:Destroy()
	end    
})

-- Items
local Tab_Items = Window:MakeTab({
	Name = "Items",
	Icon = "http://www.roblox.com/asset/?id=6034767621"
})

Tab_Items:AddLabel("All features below will activate when the match starts")
Tab_Items:AddDropdown({
	Name = "Item Vacuum Mode",
	Default = "Disabled",
	Options = {"Disabled", "Tween (WIP)", "Teleport (WIP)", "Pick Up"},
	Callback = function(Value)
		print("Item Vacuum "..Value)
	end,
	Save = true,
	Flag = "ItemVacMode"
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
	Color = Color3.fromRGB(255,255,255),
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
	Color = Color3.fromRGB(255,255,255),
	Increment = 1,
	ValueName = "HP",
	Save = true,
	Flag = "HealSafeHP"
})
local healdebounce = false
local function heal()
	if healdebounce then return end
	if not OrionLib.Flags["AutoHeal"].Value then return end
	print("Healing...")
	healdebounce = true
	for _,v in LocalPlr.Backpack:GetChildren() do
		useAllToolsOfNames(healingItems, function()
			task.wait(getDataPing()+0.05)
			if Humanoid.Health >= OrionLib.Flags["HealSafeHP"] or Character:FindFirstChild("Dead") then return "break" end
		end)
	end
	healdebounce = false
end

Humanoid.HealthChanged:Connect(function(health)
	if health > OrionLib.Flags["HealLowHP"] then return end
	heal()
end)

local SlapAura = Tab_Combat:AddSection({
	Name = "Slap Aura"
})
local friends = {}
SlapAura:AddToggle({
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
					friends[v.UserId] = LocalPlr:IsFriendsWith(v.UserId) 
				end
				
				local distance = (v.Character.HumanoidRootPart.Position-HumanoidRootPart.Position).Magnitude
				if distance > OrionLib.Flags["SlapAuraRange"].Value then continue end
				
				Events.Slap:FireServer(getModelClosestChild(v.Character, HumanoidRootPart.Position))
				Events.Slap:FireServer(v.Character.HumanoidRootPart)
				
				if distance < 5 and canHitPlayer(v, true) then
					if OrionLib.Flags["SlapAuraAnim"].Value then
						print("debug activate tool")
						Character[gloveName.Value]:Activate()
					end
					if OrionLib.Flags["SlapAuraCooldown"].Value > 0 then
						task.wait(OrionLib.Flags["SlapAuraCooldown"].Value)
					end
				end
			end
		end
	end,
	Save = true,
	Flag = "SlapAura"
})
SlapAura:AddBind({
	Name = "Quick Toggle Bind",
	Default = Enum.KeyCode.Q,
	Hold = false,
	Callback = function()
		OrionLib.Flags["SlapAura"]:Set(not OrionLib.Flags["SlapAura"].Value)
	end,
	Save = true,
	Flag = "SlapAuraBind"
})
SlapAura:AddSlider({
	Name = "Aura Radius",
	Min = 0,
	Max = 10,
	Default = 10,
	Color = Color3.fromRGB(255,255,255),
	Increment = 0.5,
	ValueName = "Studs",
	Save = true,
	Flag = "SlapAuraRange"
})
SlapAura:AddSlider({
	Name = "Slap Cooldown",
	Min = 0,
	Max = 2,
	Default = 0,
	Color = Color3.fromRGB(255,255,255),
	Increment = 0.05,
	ValueName = "seconds",
	Save = true,
	Flag = "SlapAuraCooldown"
})
SlapAura:AddToggle({
	Name = "Ignore Friends",
	Default = false,
	Save = true,
	Flag = "SlapAuraFriendly"
})
SlapAura:AddToggle({
	Name = "Slap Animation",
	Default = false,
	Save = true,
	Flag = "SlapAuraAnim"
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
	Color = Color3.fromRGB(255,255,255),
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
	Color = Color3.fromRGB(255,255,255),
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
	Color = Color3.fromRGB(255,255,255),
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

local AutoVotekicker = Tab_Misc:AddSection({
	Name = "Auto Votekick"
})
Tab_Misc:AddLabel("Toggle in lobby")
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
	Color = Color3.fromRGB(255,255,255),
	Increment = 0.05,
	ValueName = "seconds",
	Save = true,
	Flag = "AutoVotekickDelay"
})
AutoVotekicker:AddDropdown({
	Name = "Reason",
	Default = "Exploiting",
	Options = {"Bypassing", "Exploiting", "None"},
	Callback = function(Value)
		print("Auto votekick "..Value)
	end,
	Save = true,
	Flag = "AutoVotekickReason"
})
AutoVotekicker:AddDropdown({
	Name = "Vote Decision",
	Default = "Agree",
	Options = {"Agree", "Disagree", "None"},
	Callback = function(Value)
		print("Vote Decision "..Value)
	end,
	Save = true,
	Flag = "AutoVotekickDecision"
})

local AntiBarriers = Tab_Misc:AddSection({
	Name = "Anti Barrier/Hazards"
})
AntiBarriers:AddToggle({
	Name = "Safe Acid",
	Default = false,
	Save = true,
	Flag = "AntiAcid"
})
AntiBarriers:AddToggle({
	Name = "Acid Collision",
	Default = false,
	Save = true,
	Flag = "SolidAcid"
})
AntiBarriers:AddToggle({
	Name = "Safe Lava",
	Default = false,
	Save = true,
	Flag = "AntiLava"
})
AntiBarriers:AddToggle({
	Name = "Lava Collision",
	Default = false,
	Save = true,
	Flag = "SolidLava"
})

-- Init
OrionLib:Init()

if not MatchInfo.Started.Value then
	MatchInfo.Started.Changed:Wait()
	print("match start")
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

-- item vac
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
		workspace.Items.ChildAdded:Connect(pickUpTool)
		workspace.Items.ChildRemoved:Wait()
		task.wait(getDataPing())
	end,
}
task.spawn(itemVacModes[OrionLib.Flags["ItemVacMode"].Value])

if not MatchInfo.StartingCompleted.Value then
	MatchInfo.StartingCompleted.Changed:Wait()
	print("starting complete")
	
	-- bus bomb
	if OrionLib.Flags["AutoBombBus"].Value then
		useAllToolsOfNames({"Bomb"})
	end
end
if OrionLib.Flags["AutoTruePower"].Value then
	--useAllToolsOfNames({"True Power"})
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
end
