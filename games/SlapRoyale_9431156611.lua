-- Slap Royale (PID 9431156611)
if not game:IsLoaded() then game.Loaded:Wait() end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatsService = game:GetService("Stats")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Events = ReplicatedStorage.Events
local MatchInfo = ReplicatedStorage.MatchInfo

local LocalPlr = Players.LocalPlayer
local Character = LocalPlr.Character or LocalPlr.CharacterAdded:Wait()
local HumanoidRootPart:BasePart = Character:WaitForChild("HumanoidRootPart")
local Humanoid:Humanoid = Character:WaitForChild("Humanoid")
Character.PrimaryPart = HumanoidRootPart

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

local function lerpVector3WithSpeed(a:Vector3, goal:Vector3, speed:number, moveTick:number, maxAlpha:number?)
	return a:Lerp(goal, math.min(speed/(a-goal).Magnitude * (os.clock()-moveTick), maxAlpha or 1))
end

-- lib
local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Orion/main/source'))()
local Window = OrionLib:MakeWindow({Name = "Voxul", HidePremium = false, SaveConfig = false, ConfigFolder = "Voxul_ORIONLIB", IntroEnabled = true, IntroText = "Voxul", IntroIcon = "http://www.roblox.com/asset/?id=6035039429"})

-- Home
local Tab_Home = Window:MakeTab({
	Name = "Home",
	Icon = "http://www.roblox.com/asset/?id=6035145364",
	PremiumOnly = false
})
	Tab_Home:AddLabel("Developed by Voxul")
	Tab_Home:AddLabel("i gave up writing my own gui lib")

-- Items
local Tab_Items = Window:MakeTab({
	Name = "Items",
	Icon = "http://www.roblox.com/asset/?id=6034767621"
})
	Tab_Items:AddLabel("All features below will activate when the match starts")
	Tab_Items:AddDropdown({
		Name = "Item Vacuum",
		Default = "Disabled",
		Options = {"Disabled", "Tween", "Teleport", "Pick Up"},
		Callback = function(Value)
			print("Item Vacuum "..Value)
		end,
		Save = true,
		Flag = "ItemVacuumMode"
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
		AutoItemSection:AddToggle({
			Name = "Cube of Ice",
			Default = false,
			Save = true,
			Flag = "AutoIceCube"
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

	local SlapAura = Tab_Combat:AddSection({
		Name = "Slap Aura"
	})
		local SlapAuraToggle = SlapAura:AddToggle({
			Name = "Enabled",
			Default = false,
			Save = true,
			Flag = "SlapAura"
		})
		SlapAura:AddBind({
			Name = "Quick Toggle Bind",
			Default = Enum.KeyCode.Q,
			Hold = false,
			Callback = function()
				SlapAuraToggle:Set(not SlapAuraToggle.Value)
			end,
			Save = true,
			Flag = "SlapAuraBind"
		})
		SlapAura:AddSlider({
			Name = "Activation Range",
			Min = 0,
			Max = 30,
			Default = 25,
			Color = Color3.fromRGB(255,255,255),
			Increment = 0.5,
			ValueName = "Studs",
			Save = true,
			Flag = "SlapAuraRange"
		})
		SlapAura:AddToggle({
			Name = "Show Range Radius",
			Default = false,
			Save = true,
			Flag = "SlapAuraVisual"
		})
		SlapAura:AddToggle({
			Name = "Slap Animation",
			Default = false,
			Save = true,
			Flag = "SlapAuraAnim"
		})

-- Init
OrionLib:Init()
