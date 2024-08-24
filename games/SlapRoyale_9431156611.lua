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

-- other thing
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

local friends = {}
local fO_s,friendsOnline = pcall(LocalPlr.GetFriendsOnline, LocalPlr)
for _,friend in fO_s and friendsOnline or {} do
	friends[friend.VisitorId] = true
end
for _,plr in Players:GetPlayers() do
	if friends[plr.UserId] then continue end
	friends[plr.UserId] = LocalPlr:IsFriendsWith(plr.UserId)
end
Players.PlayerAdded:Connect(function(plr)
	if friends[plr.UserId] then return end
	friends[plr.UserId] = LocalPlr:IsFriendsWith(plr.UserId)
end)

-- function
local dataPingItem = StatsService.Network:WaitForChild("ServerStatsItem"):WaitForChild("Data Ping")
local function getDataPing():number
	local s,a = pcall(dataPingItem.GetValue, dataPingItem)
	return s and a/1000 or LocalPlr:GetNetworkPing() + 0.2
end

local lastDataRecvTime, lastRecvData = os.clock(), StatsService.DataReceiveKbps
RunService.Heartbeat:Connect(function()
	local currentRecvData = StatsService.DataReceiveKbps
	if currentRecvData ~= lastRecvData then
		lastDataRecvTime = os.clock()
	elseif os.clock()-lastDataRecvTime > 0.5 then
		warn("Server not send data!")
	end
	lastRecvData = currentRecvData
end)

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

local function canHitPlayer(player:Player, checkVulnerability:boolean?, checkPosition:boolean?)
	if player == LocalPlr then return false end
	local char = player.Character
	if not char or not char:FindFirstChild("Humanoid") or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Head") then return false end
	if not char.inMatch.Value or char:FindFirstChild("Dead") or char.Humanoid.Health <= 0 then return false end
	
	if checkVulnerability then
		if char.Ragdolled.Value or not char.Vulnerable.Value or char.Head.Transparency == 1 and not char:FindFirstChildWhichIsA("Tool") and not player.Backpack:FindFirstChildWhichIsA("Tool") and workspace:FindFirstChild("BusModel") then return false end
	end
	if checkPosition then
		local CHRMPOS = char.HumanoidRootPart.Position
		if math.abs(CHRMPOS.X) > 2000 or math.abs(CHRMPOS.Z) > 2000 or CHRMPOS.Y < -185 or CHRMPOS.Y > 1000 then
			return false
		end
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
		if v.ClassName == "Tool" and table.find(names, v.Name) then
			safeEquipTool(v, true)
			itemsUsed += 1
			if intervalFunc and intervalFunc(itemsUsed) == "break" then break end
		end
	end
end

local function hasToolOfNames(names:{string})
	for _,v in LocalPlr.Backpack:GetChildren() do
		if v.ClassName == "Tool" and table.find(names, v.Name) then
			return true
		end
	end
	return false
end

local function lerpVector3WithSpeed(a:Vector3, goal:Vector3, speed:number, moveTick:number, maxAlpha:number?)
	return a:Lerp(goal, math.min(speed/(a-goal).Magnitude * moveTick, maxAlpha or 1))
end

local function slapPlayer(character:Model)
	Events.Slap:FireServer(getModelClosestChild(character, HumanoidRootPart.Position))
	Events.Slap:FireServer(character.HumanoidRootPart)
end

-- disable exploit countermeasures (anti-anticheat)
local blockedRemotes = {[Events.WS] = "FireServer", [Events.WS2] = "FireServer"}
if Events:FindFirstChild("AdminGUI") then
	blockedRemotes[Events.AdminGUI] = "FireServer"
end

if hookmetamethod and getnamecallmethod and checkcaller and newcclosure then
	local bypass;bypass = hookmetamethod(game, "__namecall", newcclosure(function(a, ...)
		if blockedRemotes[a] ~= nil and not checkcaller() and ( blockedRemotes[a] == true or getnamecallmethod() == blockedRemotes[a] ) then return end
		return bypass(a, ...)
	end))
else
	warn("unsupported executor, falling back to :Destroy()!")
	for i in blockedRemotes do
		if i.Parent then
			i:Destroy()
		end
	end
end

workspace.Map.OriginOffice:WaitForChild("Antiaccess").CanTouch = false


local OrionLib = loadstring(game:HttpGet(getgenv().VoxulLib or 'https://raw.githubusercontent.com/shlexware/Orion/main/source'))()
local Window = OrionLib:MakeWindow(getgenv().VoxulWindowCONF or {Name = "Voxul", HidePremium = false, SaveConfig = false, ConfigFolder = "Voxul_ORIONLIB", IntroEnabled = true, IntroText = "Voxul", IntroIcon = "http://www.roblox.com/asset/?id=6035039429"})

-- Home
local Tab_Home = Window:MakeTab({
	Name = "Home",
	Icon = "http://www.roblox.com/asset/?id=6035145364",
	PremiumOnly = false
})

Tab_Home:AddParagraph("made with ♡ by voxul~","DM voxuloid on Discord if you have problems or suggestions")
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
		if v == false then
			pcall(function()
				if isfile(OrionLib.Folder .. "/" .. game.PlaceId .. ".txt") then
					delfile(OrionLib.Folder .. "/" .. game.PlaceId .. ".txt")
				end
			end)
			OrionLib:MakeNotification({
				Name = "Configuration",
				Content = "Config will no longer be saved",
				Image = "http://www.roblox.com/asset/?id=6034509993",
				Time = 5
			})
		end
	end,
	Save = false,
	Flag = "SaveConfig"
})
Tab_Home:AddButton({
	Name = "Infinite Yield",
	Callback = function()
		OrionLib:MakeNotification({
			Name = "Voxul Hub",
			Content = "Loading Infinite Yield...",
			Image = "http://www.roblox.com/asset/?id=6034973074",
			Time = 3
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
	Options = {"Disabled", "Pick Up", --[["Tween", "Teleport", "Hybrid"]]},
	Save = true,
	Flag = "ItemVacMode"
})
--[[ItemVacSection:AddSlider({
	Name = "Tween Speed",
	Min = 0,
	Max = 450,
	Default = 400,
	Increment = 1,
	ValueName = "studs/sec",
	Save = true,
	Flag = "ItemVacTweenSpeed"
})
ItemVacSection:AddParagraph("Going too fast will kick you!", "Decrease the speed using the slider above if you get kicked")]]
ItemVacSection:AddToggle({
	Name = "Vacuum Dropped Items",
	Default = false,
	Save = true,
	Flag = "DroppedItemVac"
})
ItemVacSection:AddToggle({
	Name = "Auto-Activate Item (disabling can kick you)",
	Default = true,
	Save = true,
	Flag = "ItemVacActivateTools"
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
	Name = "Permanent Items",
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
	Max = 500,
	Default = 30,
	Increment = 1,
	ValueName = "HP",
	Save = true,
	Flag = "HealLowHP"
})
AutoHeal:AddSlider({
	Name = "Safe Health",
	Min = 0,
	Max = 500,
	Default = 80,
	Increment = 1,
	ValueName = "HP",
	Save = true,
	Flag = "HealSafeHP"
})

local healdebounce = false
local function heal()
	if healdebounce or not OrionLib.Flags["AutoHeal"].Value or not hasToolOfNames(healingItems) then return end
	healdebounce = true
	
	OrionLib:MakeNotification({
		Name = "Auto-Heal",
		Content = "Healing to safe health...",
		Image = "http://www.roblox.com/asset/?id=6034684956",
		Time = 3
	})
	
	useAllToolsOfNames(healingItems, function()
		task.wait(getDataPing())
		if Humanoid.Health >= OrionLib.Flags["HealSafeHP"].Value or Humanoid.Health >= Humanoid.MaxHealth or Character:FindFirstChild("Dead") then return "break" end
	end)
	healdebounce = false
end
Humanoid.HealthChanged:Connect(function(health)
	if health <= OrionLib.Flags["HealLowHP"].Value and health < Humanoid.MaxHealth then heal() end
end)

local SlapAuraSection = Tab_Combat:AddSection({
	Name = "Slap Aura"
})
SlapAuraSection:AddToggle({
	Name = "Enabled",
	Default = false,
	Callback = function(v)
		if not v then return end
		task.spawn(function()
			while OrionLib.Flags["SlapAura"].Value and task.wait() do
				if not Character:FindFirstChild(gloveName.Value) then continue end
				for _,v in Players:GetPlayers() do
					if OrionLib.Flags["SlapAuraFriendly"] and friends[v.UserId] or not canHitPlayer(v) then 
						continue
					elseif friends[v.UserId] == nil then
						friends[v.UserId] = LocalPlr:IsFriendsWith(v.UserId)
					end

					local distance = (v.Character.HumanoidRootPart.Position-HumanoidRootPart.Position).Magnitude
					if distance > OrionLib.Flags["SlapAuraRange"].Value then continue end

					slapPlayer(v.Character)

					if OrionLib.Flags["SlapAuraAnim"].Value then
						Character[gloveName.Value]:Activate()
					end

					if distance < 6 and canHitPlayer(v, true) and OrionLib.Flags["SlapAuraCooldown"].Value > 0 then
						task.wait(OrionLib.Flags["SlapAuraCooldown"].Value)
					end
				end
			end
		end)
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
	Max = 30,
	Default = 30,
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
AutoWinSection:AddDropdown({
	Name = "Auto-Win Mode",
	Default = "Disabled",
	Options = {"Disabled", "Tween"--[[, "Teleport", "Hybrid"]]}, -- other modes will be implemented at later date
	Save = true,
	Flag = "AutoWinMode"
})
AutoWinSection:AddSlider({
	Name = "Tween Speed",
	Min = 0,
	Max = 450,
	Default = 350,
	Increment = 1,
	ValueName = "studs/sec",
	Save = true,
	Flag = "AutoWinTweenSpeed"
})
AutoWinSection:AddParagraph("Going too fast will kick you!", "Decrease the speed using the slider above if you get kicked")
AutoWinSection:AddToggle({
	Name = "Ignore Friends",
	Default = false,
	Save = true,
	Flag = "AutoWinFriendly"
})
AutoWinSection:AddToggle({
	Name = "Target Gliding Players",
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

local PlayerOtherSection = Tab_Player:AddSection({
	Name = "Other"
})
PlayerOtherSection:AddToggle({
	Name = "Auto-Jump Enabled",
	Default = LocalPlr.AutoJumpEnabled,
	Callback = function(v)
		LocalPlr.AutoJumpEnabled = v
		Humanoid.AutoJumpEnabled = v
	end,
	Save = true,
	Flag = "AutoJumpEnabled"
})
PlayerOtherSection:AddToggle({
	Name = "Prevent Tripping",
	Default = false,
	Callback = function(v)
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, not v)
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, not v)
	end,
	Save = true,
	Flag = "PreventTripping"
})
PlayerOtherSection:AddToggle({
	Name = "Prevent Sitting",
	Default = false,
	Callback = function(v)
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, not v)
	end,
	Save = true,
	Flag = "PreventSitting"
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
	Name = "Lobby Hider",
	Default = false,
	Callback = function(v)
		task.spawn(function()
			lobbyhiding = v
			if not v or not workspace:FindFirstChild("Lobby") or not Character then return end
			lobbyViewerPart.Position = HumanoidRootPart.Position
			local cframe = HumanoidRootPart.CFrame
			while lobbyhiding and workspace:FindFirstChild("Lobby") do
				workspace.CurrentCamera.CameraSubject = lobbyViewerPart
				pivotModelTo(Character, cframe + Vector3.new(math.random(), 150, math.random()), true)
				task.wait()
			end
			workspace.CurrentCamera.CameraSubject = Humanoid
			pivotModelTo(Character, cframe, true)
		end)
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
	Name = "Delay (Increase to reduce suspicion)",
	Min = 3,
	Max = 13,
	Default = 3,
	Increment = 0.05,
	ValueName = "seconds",
	Save = true,
	Flag = "AutoVotekickDelay"
})
AutoVotekicker:AddToggle({
	Name = "Ignore Friends",
	Default = false,
	Save = true,
	Flag = "AutoVotekickFriendly"
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
	Name = "Anti Barriers/Hazards"
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
	Name = "Solid Acid",
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
	Name = "Solid Lava",
	Default = false,
	Callback = function(v)
		workspace.Map.DragonDepths:WaitForChild("Lava").CanCollide = v
	end,
	Save = true,
	Flag = "SolidLava"
})

AntiBarriers:AddToggle({
	Name = "Remove under-map walls",
	Default = false,
	Callback = function(v)
		for _,v1 in workspace.Map.AntiUnderMap:GetChildren() do
			if v1:IsA("BasePart") then
				v1.CanCollide = not v
			end
		end
	end,
	Save = true,
	Flag = "AntiUnderWalls"
})

Tab_Misc:AddToggle({
	Name = "Disable Zone Effects",
	Default = false,
	Save = true,
	Flag = "AntiZone"
})

Character:WaitForChild("inZone").Changed:Connect(function()
	if Character.inZone.Value and OrionLib.Flags["AntiZone"].Value then
		Character.inZone.Value = false
	end
end)

-- Init
OrionLib:Init()

OrionLib:MakeNotification({
	Name = "WARNING",
	Content = "This game has a moderation system, you are using Voxul at your own risk of being PERMANENTLY BANNED. It is not recommended to exploit on your primary account.",
	Image = "http://www.roblox.com/asset/?id=6035067826",
	Time = 20
})

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
		
		if OrionLib.Flags["AutoVotekickFriendly"] then
			for userId, friended in friends do
				if not friended then continue end
				local tIndex = table.find(players, Players:GetPlayerByUserId(userId))
				if tIndex then table.remove(players, tIndex) end
			end
		end
		
		local selected = players[math.random(1, #players)].Name
		
		OrionLib:MakeNotification({
			Name = "Auto-Votekick",
			Content = "Votekicking "..selected.." with reason "..OrionLib.Flags["AutoVotekickReason"].Value,
			Image = "http://www.roblox.com/asset/?id=6034267996",
			Time = 5
		})
		
		-- ( PlayerName:string, isVoting:boolean, reason:number? | vote:boolean )
		Events.Votekick:FireServer(selected, false, votekickReasons[OrionLib.Flags["AutoVotekickReason"].Value])
		if OrionLib.Flags["AutoVotekickDecision"].Value ~= "None" then
			task.wait()
			Events.Votekick:FireServer(selected, true, votekickChoices[OrionLib.Flags["AutoVotekickDecision"].Value])
		end
	end)
end

--[[if not MatchInfo.StartingCompleted.Value then
	MatchInfo.StartingCompleted.Changed:Wait()
end]]

if workspace:FindFirstChild("Lobby") then 
	workspace.Lobby.AncestryChanged:Wait()
end

workspace.CurrentCamera.CameraSubject = Humanoid

-- items
local pickedUpItems = 0
local itemVacModes = {
	["Disabled"] = function() end,
	["Pick Up"] = function()
		local function pickUpTool(v:Tool)
			if v.ClassName ~= "Tool" then return end
			safeEquipTool(v, false, true)
			v.Equipped:Once(function()
				pickedUpItems += 1
				v.AncestryChanged:Connect(function(_,p)
					if not OrionLib.Flags["ItemVacActivateTools"].Value then return end
					if p ~= Character then return end
					task.defer(function()
						v:Activate()
						Humanoid:UnequipTools()
					end)
				end)
				Humanoid:UnequipTools()
			end)
		end

		for _,v in workspace.Items:GetChildren() do
			pickUpTool(v)
		end
		workspace.Items.ChildAdded:Connect(function(c)
			task.wait()
			if not OrionLib.Flags["DroppedItemVac"].Value then return end
			pickUpTool(c)
		end)
		
		workspace.Items.ChildRemoved:Wait()
		task.wait(getDataPing())
		while os.clock()-lastDataRecvTime > 0.5 do task.wait() end
		
		OrionLib:MakeNotification({
			Name = "Item Vacuum",
			Content = "Picked up "..pickedUpItems.." items",
			Image = "http://www.roblox.com/asset/?id=6034767621",
			Time = 5
		})
		task.wait(0.1)
	end,
	["Tween"] = function() end, -- implement if above is patched
	["Teleport"] = function() end, -- implement if above is patched
	["Hybrid"] = function() end, -- implement if above is patched
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
		if v.ClassName == "Tool" and v.Name == "True Power" then
			if firstTruePower then
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

-- Auto Bus Jump
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

-- Auto Win
local ignored_targets = {}
local function getClosestHittablePlayer():(Player, number)
	local closest, closestMagnitude = nil, nil

	for _,plr in Players:GetPlayers() do
		if plr == LocalPlr or table.find(ignored_targets, plr) or OrionLib.Flags["AutoWinFriendly"].Value and friends[plr.UserId] or not canHitPlayer(plr, true, true) then continue end
		if plr.Character:FindFirstChild("Glider") and not OrionLib.Flags["AutoWinGlidingTargets"].Value then continue end
		
		local magnitude = (plr.Character.HumanoidRootPart.Position-HumanoidRootPart.Position).Magnitude
		if not closest or magnitude < closestMagnitude then
			closest = plr
			closestMagnitude = magnitude
		end
	end

	return closest, closestMagnitude
end

local Vector3XZ = Vector3.new(1,0,1)
local lOSParams = RaycastParams.new()
lOSParams.FilterType = Enum.RaycastFilterType.Exclude
lOSParams.IgnoreWater = true
lOSParams.FilterDescendantsInstances = {}

local function ignoreTarget(plr:Player)
	if not table.find(ignored_targets, plr) then
		table.insert(ignored_targets, plr)
		task.delay(0.4 + getDataPing(), function()
			table.remove(ignored_targets, table.find(ignored_targets, plr))
		end)
	end
end

local lastPositions = {}
local warnNotifDebounce = false
RunService.PostSimulation:Connect(function(dT)
	if not Character or Character:FindFirstChild("Dead") or OrionLib.Flags["AutoWinMode"].Value == "Disabled" then return end
	
	if not Character:FindFirstChild(gloveName.Value) then
		if not LocalPlr.Backpack:FindFirstChild(gloveName.Value) then
			if not warnNotifDebounce then
				warnNotifDebounce = true
				OrionLib:MakeNotification({
					Name = "Auto-Win",
					Content = "Glove not found!",
					Image = "http://www.roblox.com/asset/?id=6034457092",
					Time = 3
				})
				task.wait(3)
				warnNotifDebounce = false
			end
			
			return
		end
		Humanoid:EquipTool(LocalPlr.Backpack[gloveName.Value])
	end
	
	if Humanoid.SeatPart or Humanoid.Sit or Humanoid:GetState() == Enum.HumanoidStateType.Seated then
		Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		Humanoid.Sit = false
	end
	
	if os.clock()-lastDataRecvTime > 0.5 then
		if not warnNotifDebounce then
			warnNotifDebounce = true
			OrionLib:MakeNotification({
				Name = "Auto-Win",
				Content = "Paused due to lag ("..os.clock()-lastDataRecvTime.."s)",
				Image = "http://www.roblox.com/asset/?id=6034457092",
				Time = 3
			})
			task.wait(3)
			warnNotifDebounce = false
		end
		return
	end
	
	if Character:FindFirstChild("Torso") then
		Character.Torso.CanCollide = false
	end
	if Character:FindFirstChild("Head") then
		Character.Head.CanCollide = false
	end
	
	local target, distance = getClosestHittablePlayer()
	if target then
		local targetChar = target.Character
		if OrionLib.Flags["AutoWinMode"].Value == "Tween" then
			local tHRM:BasePart = targetChar.HumanoidRootPart
			
			local targetPos = tHRM.Position
			if OrionLib.Flags["AutoWinLagAdjust"].Value then
				local lagAhead:Vector3 = (targetPos-(lastPositions[target] or targetPos))/dT*(getDataPing()+0.05)
				if lagAhead.Magnitude > 8 then
					targetPos += Vector3.new(lagAhead.X, math.clamp(lagAhead.Y, -8, 8), lagAhead.Z)
				end
			end
			
			pivotModelTo(Character,
				CFrame.new(lerpVector3WithSpeed(HumanoidRootPart.Position, targetPos, OrionLib.Flags["AutoWinTweenSpeed"].Value, math.min(dT, 0.04)))*CFrame.Angles(math.rad(180), 0, 0),
				true
			)
			local velocityDirection = (targetPos-HumanoidRootPart.Position).Unit
			if velocityDirection == velocityDirection then
				HumanoidRootPart.AssemblyLinearVelocity = (targetPos-HumanoidRootPart.Position).Unit * OrionLib.Flags["AutoWinTweenSpeed"].Value
				RunService.PreSimulation:Once(function()
					HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
				end)
			end
			
			if OrionLib.Flags["AutoWinOptimizations"].Value and (HumanoidRootPart.Position-targetPos).Magnitude < 0.5 then
				if not targetChar:FindFirstChild("Glider") then
					lOSParams.FilterDescendantsInstances = {Character}
					local losTo = workspace:Raycast(HumanoidRootPart.Position, (targetPos-HumanoidRootPart.Position), lOSParams)
					lOSParams.FilterDescendantsInstances = {target, workspace.Terrain}
					local losFrom = workspace:Raycast(targetPos, (HumanoidRootPart.Position-targetPos), lOSParams)
					if not losTo or not losTo.Instance:IsDescendantOf(target) or not losFrom or not losFrom.Instance:IsDescendantOf(Character) then
						task.wait(0.08)
					end
				else
					task.wait(0.08)
				end
				ignoreTarget(target)
			end
		end
		
		slapPlayer(targetChar)
	else
		pivotModelTo(Character,
			CFrame.new(lerpVector3WithSpeed(HumanoidRootPart.Position, HumanoidRootPart.Position*Vector3XZ, OrionLib.Flags["AutoWinTweenSpeed"].Value, math.min(dT, 0.017)))*CFrame.Angles(math.rad(180), 0, 0),
			true
		)
		HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0,OrionLib.Flags["AutoWinTweenSpeed"].Value*-math.sign(HumanoidRootPart.Position.Y),0) -- improve physics interp
		RunService.PreSimulation:Once(function()
			HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
		end)
	end
	
	for _,plr in Players:GetPlayers() do
		if plr == LocalPlr then continue end
		local char = plr.Character
		if not char or not char:FindFirstChild("HumanoidRootPart") then continue end
		lastPositions[plr] = char.HumanoidRootPart.Position
		
		if (not OrionLib.Flags["AutoWinFriendly"].Value or not friends[plr.UserId]) and (char.HumanoidRootPart.Position-HumanoidRootPart.Position).Magnitude < 20 then
			slapPlayer(char)
		end
	end
end)
