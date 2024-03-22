if game.PlaceId ~= 9431156611 then warn("Not Slap Royale!") return end
local getgenv = getgenv or getfenv
if not getgenv().SRCheatConfigured then
	getgenv().SRCheatConfigured = true

	getgenv().disableBarriers = true
	getgenv().hazardCollision = true -- Whether the hazard should be solid
	
	getgenv().hideCharacterInLobby = true -- Useful for evading noobs yelling at you
	
	getgenv().autoVotekick = true -- Votekicks a random player at the start of the match
	
	getgenv().itemVacEnabled = true

	getgenv().bombBus = true
	getgenv().permaTruePower = true -- Activates when you have 2 or more True Powers
	getgenv().usePermaItems = true -- Automatically use permanent items
	getgenv().useIceCubes = false -- Automatically use ice cubes to allow killAll/kill aura oneshots for a few hits

	getgenv().instantBusJump = true
	getgenv().busJumpLegitMode = false -- Waits for the jump prompt to appear
	getgenv().instantLand = true -- Teleports you to the ground instantly

	getgenv().safetyHeal = true
	getgenv().healthLow = 30 -- When to trigger auto-heal
	getgenv().healthOk = 80 -- How much to heal until

	getgenv().killAll = true
	getgenv().killAllInitDelay = 1 -- How long to wait before starting
	getgenv().killAllStudsPerSecond = 440 -- How fast to go towards targets
	getgenv().killAllHitOptimizationEnabled = true -- Improves efficiency by not waiting for the client to know if the target got hit
	getgenv().killAllOptimizationActivationDistance = 3
	getgenv().killAllIgnoreGliders = false -- Ignore targets if they are gliding
	getgenv().killAllLagAdjustmentEnabled = true -- Determines whether or not to adjust for lag (useful for attacking gliders)
	getgenv().killAllGliderLagAdjustmentOnly = false -- Only adjust for lag if the target is gliding
	getgenv().killAllLagAdjustmentStudsAheadActivation = 8 -- How many studs the target is estimated to be ahead to trigger lag adjustment
end

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local StatsService = game:GetService("Stats")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Events = ReplicatedStorage.Events

local LocalPlr = Players.LocalPlayer
local Character = LocalPlr.Character or LocalPlr.CharacterAdded:Wait()
local HumanoidRootPart:BasePart = Character:WaitForChild("HumanoidRootPart")
local Humanoid:Humanoid = Character:WaitForChild("Humanoid")

Character.PrimaryPart = HumanoidRootPart

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

local function pivotModelTo(Model:Model, cFrame:CFrame, removeVelocity:boolean?)
	Model:PivotTo(cFrame)
	for _,v in Model:GetDescendants() do
		if v:IsA("BasePart") then
			v.AssemblyLinearVelocity = Vector3.zero
			v.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

-- Disable barriers
if getgenv().disableBarriers then
	print("Disable Barriers/Hazards")
	
	local function disableTouch(part:BasePart)
		part.CanTouch = false
		local tT = part:FindFirstChildWhichIsA("TouchTransmitter")
		if tT then tT:Destroy() end
	end
	
	for _,v:BasePart in workspace.Map.AcidAbnormality:GetChildren() do
		if v.Name == "Acid" and v:IsA("BasePart") and v:FindFirstChildWhichIsA("TouchTransmitter") then
			disableTouch(v)
			v.CanCollide = getgenv().hazardCollision
		end
	end
	
	disableTouch(workspace.Map.DragonDepths:WaitForChild("Lava"))
	workspace.Map.DragonDepths.Lava.CanCollide = getgenv().hazardCollision
	disableTouch(workspace.Map.OriginOffice:WaitForChild("Antiaccess"))
	workspace.Map.AntiUnderMap:ClearAllChildren()
end

if getgenv().hideCharacterInLobby and workspace:FindFirstChild("Lobby") then
	print("Hiding LocalPlayer in lobby")
	local ogCFrame = HumanoidRootPart.CFrame
	while workspace:FindFirstChild("Lobby") and task.wait() do
		pivotModelTo(Character, ogCFrame + Vector3.new(math.random(), 150, math.random()), true)
	end
end

if workspace:FindFirstChild("Lobby") then
	print("Waiting for Bus")
	workspace.Lobby.AncestryChanged:Wait()
end
HumanoidRootPart.Anchored = false

if getgenv().autoVotekick then
	local players = Players:GetPlayers()
	table.remove(players, table.find(players, LocalPlr))
	local selected = players[math.random(1, #players)].Name
	print("Votekicking "..selected)
	
	Events.Votekick:FireServer(selected, false, 2)
	task.wait()
	Events.Votekick:FireServer(selected, true, true)
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

if getgenv().itemVacEnabled then
	print("Item Vacuuming")

	-- Pick up dropped items
	local function pickUpTool(v:Tool)
		if v:IsA("Tool") then
			safeEquipTool(v, false, true)
			v.Equipped:Once(function()
				v.AncestryChanged:Connect(function(_,p)
					if p ~= Character then return end
					print("Auto-activate "..v.Name)
					task.defer(v.Activate, v)
				end)
			end)
		end
	end
	
	workspace.Items.ChildAdded:Connect(pickUpTool)

	for _,v in workspace.Items:GetChildren() do
		pickUpTool(v)
	end
	
	local toolWaitStart = os.clock()
	while os.clock()-toolWaitStart < 3 and not LocalPlr.Backpack:FindFirstChildWhichIsA("Tool") do task.wait(getDataPing()) end
	task.wait(getDataPing()*2)
end

local permanentItems = {"Boba", "Bull's essence", "Frog Brew", "Frog Potion", "Potion of Strength", "Speed Brew", "Speed Potion", "Strength Brew"}
local healingItems = {"Apple", "Bandage", "Boba", "First Aid Kit", "Forcefield Crystal", "Healing Brew", "Healing Potion"}

local function heal()
	print("Healing...")
	for _,v in LocalPlr.Backpack:GetChildren() do
		if v:IsA("Tool") and table.find(healingItems, v.Name) then
			safeEquipTool(v, true)
			task.wait(getDataPing()+0.05)
			if Humanoid.Health >= getgenv().healthOk or Character:FindFirstChild("Dead") then break end
		end
	end
end

if getgenv().safetyHeal then
	local debounce = false
	Humanoid.HealthChanged:Connect(function(health)
		if debounce or Character:FindFirstChild("Dead") then return end
		if health > getgenv().healthLow then return end 

		debounce = true
		heal()
		debounce = false
	end)
end

local gloveName = LocalPlr.Glove.Value
if getgenv().bombBus then
	print("bababooey")
	local bombsExploded = 0
	for _,v in LocalPlr.Backpack:GetChildren() do
		if v:IsA("Tool") and v.Name == "Bomb" then
			safeEquipTool(v, true)
			
			bombsExploded += 1
			if bombsExploded%4 == 3 and getgenv().safetyHeal then
				heal()
			end
		end
	end
	
	task.wait(getDataPing())
end

if getgenv().permaTruePower then
	local firstTruePower = nil
	for _,v in LocalPlr.Backpack:GetChildren() do
		if v:IsA("Tool") and v.Name == "True Power" then
			if firstTruePower then
				print("2 True Powers found!")

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

if getgenv().usePermaItems then
	print("Using all permanent items")
	task.spawn(function()
		if gloveName == "Pack-A-Punch" then
			repeat task.wait() until LocalPlr.Backpack:FindFirstChild("Pack-A-Punch") or Character:FindFirstChild("Pack-A-Punch")
			task.wait(0.1)
		end

		for _,v in LocalPlr.Backpack:GetChildren() do
			if v:IsA("Tool") and table.find(permanentItems, v.Name) then
				safeEquipTool(v, true)
			end
		end
	end)
	
	LocalPlr.Backpack.ChildAdded:Connect(function(v)
		if v:IsA("Tool") and table.find(permanentItems, v.Name) then
			safeEquipTool(v, true)
		end
	end)
end

if getgenv().useIceCubes then
	print("Using all ice cubes")
	for _,v in LocalPlr.Backpack:GetChildren() do
		if v:IsA("Tool") and v.Name == "Cube of Ice" then
			safeEquipTool(v, true)
		end
	end
	LocalPlr.Backpack.ChildAdded:Connect(function(v)
		if v:IsA("Tool") and v.Name == "Cube of Ice" then
			safeEquipTool(v, true)
		end
	end)
end

if getgenv().instantBusJump and not LocalPlr.Backpack:FindFirstChild(gloveName) and not Character:FindFirstChild(gloveName) and not LocalPlr.Backpack:FindFirstChild("Glider") and not Character:FindFirstChild("Glider") then
	print("Instant Bus Jump")
	while Character.Ragdolled.Value or getgenv().busJumpLegitMode and LocalPlr.PlayerGui:FindFirstChild("JumpPrompt") do
		task.wait()
	end
	
	Events.BusJumping:FireServer()

	if getgenv().instantLand then
		local rayParam = RaycastParams.new()
		rayParam.FilterDescendantsInstances = {workspace.Terrain}
		rayParam.FilterType = Enum.RaycastFilterType.Include

		local rayCast
		for i = 1, 10 do
			rayCast = workspace:Raycast(HumanoidRootPart.Position, Vector3.new(0,-500,0), rayParam)
			if rayCast then break end
			task.wait(0.01)
		end

		local landingPos
		if rayCast then
			landingPos = CFrame.new(rayCast.Position + Vector3.new(0,2.5,0))
		else
			warn("Failed to get landing spot, falling back to setPos")
			landingPos = HumanoidRootPart.CFrame - Vector3.new(0,300,0)
		end

		local jumpTimeoutStart = os.clock()
		while landingPos and (os.clock()-jumpTimeoutStart < 3 or Character.Ragdolled.Value) and not Character:FindFirstChild(gloveName) and not LocalPlr.Backpack:FindFirstChild(gloveName) do
			pivotModelTo(Character, landingPos, true)
			task.wait()
		end
		pivotModelTo(Character, landingPos, true)
		task.wait(getDataPing())
		pivotModelTo(Character, landingPos, true)
	end

	task.spawn(function()
		repeat task.wait() until LocalPlr.PlayerGui:FindFirstChild("JumpPrompt")
		LocalPlr.PlayerGui.JumpPrompt:Destroy()
	end)
end

-- Kill All
if not getgenv().killAll then return end

local function canHitChar(char:Model)
	if not char or not char.Parent then return false end

	local charHRM:BasePart = char:FindFirstChild("HumanoidRootPart")
	-- Instance sanity
	if not charHRM or not char:FindFirstChild("Humanoid") or not char:FindFirstChild("Head") or not char:FindFirstChild("inMatch") or not char:FindFirstChild("Ragdolled") or not char:FindFirstChild("Vulnerable") then 
		return false 
	end

	-- Check if they're dead
	if not char.inMatch.Value or char.Humanoid.Health <= 0 or char:FindFirstChild("Dead") then
		return false
	end

	-- Additional checks
	if char.Ragdolled.Value or not char.Vulnerable.Value or getgenv().killAllIgnoreGliders and char:FindFirstChild("Glider") or char.Head.Transparency == 1 and not char:FindFirstChildWhichIsA("Tool") and not Players:GetPlayerFromCharacter(char).Backpack:FindFirstChildWhichIsA("Tool") then 
		return false 
	end

	-- Position sanity
	local CHRMPOS = charHRM.Position
	if math.abs(CHRMPOS.X) > 2000 or math.abs(CHRMPOS.Z) > 2000 or CHRMPOS.Y < -180 or CHRMPOS.Y > 600 then
		return false
	end

	return true
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

local ignores = {}
local function getClosestHittableCharacter(position:Vector3):(Model, number)
	local closest, closestMagnitude = nil, nil

	for _,plr in Players:GetPlayers() do
		if plr == LocalPlr or table.find(ignores, plr.Character) or not canHitChar(plr.Character) then continue end

		local magnitude = (plr.Character.HumanoidRootPart.Position-position).Magnitude
		if not closest or magnitude < closestMagnitude then
			closest = plr.Character
			closestMagnitude = magnitude
		end
	end

	return closest, closestMagnitude
end

task.wait(getgenv().killAllInitDelay)
print("Initialize kill all")

-- Additional stuff
Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
Humanoid.PlatformStand = true

-- Disable Player Collisions
for _,v in Character:GetDescendants() do
	if v:IsA("BasePart") then
		v.CanCollide = false
		v.CanTouch = false
		v.Massless = true
	end
end

local lagAdjust = getgenv().killAllLagAdjustmentEnabled

local lastPositions = {}
local lastDelta = 1
RunService.Heartbeat:Connect(function(dT)
	lastDelta = dT
	
	for _,plr in Players:GetPlayers() do
		if plr == LocalPlr then continue end
		
		local char = plr.Character
		if not char or not char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Dead") then continue end

		if (char.HumanoidRootPart.Position-HumanoidRootPart.Position).Magnitude < 20 then
			Events.Slap:FireServer(getModelClosestChild(char, HumanoidRootPart.Position))
			Events.Slap:FireServer(char.HumanoidRootPart)
		end

		if lagAdjust then
			if not lastPositions[char] then
				lastPositions[char] = {
					posBuffer = char.HumanoidRootPart.Position,
				}
				plr.Character.AncestryChanged:Once(function()
					lastPositions[char] = nil
				end)
			end
			
			lastPositions[char].old = lastPositions[char].posBuffer
			lastPositions[char].posBuffer = char.HumanoidRootPart.Position
		end
	end
	
	if HumanoidRootPart.Position.Y < -180 then
		pivotModelTo(Character, HumanoidRootPart.CFrame - Vector3.new(0, HumanoidRootPart.Position.Y + 100, 0), true)
	end
end)

local lOSParams = RaycastParams.new()
lOSParams.FilterType = Enum.RaycastFilterType.Exclude
lOSParams.IgnoreWater = true
lOSParams.FilterDescendantsInstances = {}

local studsPerSecond = getgenv().killAllStudsPerSecond
local optimizationEnabled = getgenv().killAllHitOptimizationEnabled
local gliderAdjustOnly = getgenv().killAllGliderLagAdjustmentOnly
local studsAheadActivation = getgenv().killAllLagAdjustmentStudsAheadActivation

local Vect3_XZ = Vector3.new(1,0,1)

local yZeroTick = os.clock()

local target, distance
local function refreshTarget()
	target, distance = getClosestHittableCharacter(HumanoidRootPart.Position)
end

local function ignoreTarget(target:Model)
	table.insert(ignores, target)
	task.delay(getDataPing()+0.2, function()
		table.remove(ignores, table.find(ignores, target))
	end)
	yZeroTick = os.clock()
end

while task.wait() and not Character:FindFirstChild("Dead") do
	refreshTarget()
	
	if not target then
		pivotModelTo(
			Character,
			CFrame.new(
				HumanoidRootPart.Position:Lerp(HumanoidRootPart.Position*Vect3_XZ, math.min(studsPerSecond/math.abs(HumanoidRootPart.Position.Y)*(os.clock()-yZeroTick), 1))
			)*CFrame.Angles(math.rad(180), 0, 0),
			true
		)
		yZeroTick = os.clock()
		continue
	end
	yZeroTick = os.clock()
	
	print(target.Name, distance)

	local moveToStart = os.clock()
	local moveToTick = os.clock()
	while canHitChar(target) and not Character:FindFirstChild("Dead") do
		local tHumanoidRootPart:Part = target.HumanoidRootPart
		
		if os.clock()-moveToStart > distance/studsPerSecond+1 or os.clock()-moveToStart > 8 then
			warn("Target timed out!")
			ignoreTarget(target)
			break
		end
		
		local targetPosition = tHumanoidRootPart.Position
		if lagAdjust then
			local lagAhead:Vector3 = (targetPosition-lastPositions[target].old)/lastDelta*(getDataPing()+0.02)

			if lagAhead.Magnitude > studsAheadActivation then
				if gliderAdjustOnly and target:FindFirstChild("Glider") or not gliderAdjustOnly then
					targetPosition += Vector3.new(lagAhead.X, math.clamp(lagAhead.Y, -6, 8), lagAhead.Z)
				end
			end
		end
		
		if not Character:FindFirstChild(gloveName) then
			if not LocalPlr.Backpack:FindFirstChild(gloveName) then
				warn("Glove Missing!")
				task.wait(0.5)
				break
			end
			Humanoid:EquipTool(LocalPlr.Backpack[gloveName])
		end
		
		pivotModelTo(
			Character, 
			CFrame.new(
				HumanoidRootPart.Position:Lerp(
					targetPosition,
					math.min(studsPerSecond/(targetPosition-HumanoidRootPart.Position).Magnitude*(os.clock()-moveToTick),1.05)
				)
			)*CFrame.Angles(math.rad(180), 0, 0),
			true
		)
		
		if optimizationEnabled and (HumanoidRootPart.Position-targetPosition).Magnitude < getgenv().killAllOptimizationActivationDistance then
			if not target:FindFirstChild("Glider") then
				lOSParams.FilterDescendantsInstances = {Character}
				local losTo = workspace:Raycast(HumanoidRootPart.Position, (tHumanoidRootPart.Position-HumanoidRootPart.Position), lOSParams)
				lOSParams.FilterDescendantsInstances = {target, workspace.Terrain}
				local losFrom = workspace:Raycast(tHumanoidRootPart.Position, (HumanoidRootPart.Position-tHumanoidRootPart.Position), lOSParams)
				
				if losTo and losTo.Instance:IsDescendantOf(target) and losFrom and losFrom.Instance:IsDescendantOf(Character) then
					break
				end
			end
			
			local elapsedStart = os.clock()
			while task.wait() and os.clock()-elapsedStart < 0.08 and canHitChar(target) do
				pivotModelTo(
					Character,
					CFrame.new(targetPosition)*CFrame.Angles(math.rad(180), 0, 0),
					true
				)
				Events.Slap:FireServer(getModelClosestChild(target, HumanoidRootPart.Position))
				Events.Slap:FireServer(tHumanoidRootPart)
			end
			
			ignoreTarget(target)
			break
		end

		moveToTick = os.clock()
		yZeroTick = os.clock()
		task.wait()
	end
end
