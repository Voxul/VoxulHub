local unsecureEXEC = {
  "krnl",
  "delta"
}

local thisExecutor = identifyexecutor and string.lower(identifyexecutor())
if not thisExecutor then
  game:GetService("Players").LocalPlayer:Kick("Your executor is not supported!")
  return
end

for _, exec in unsecureEXEC do
  if string.match(thisExecutor, exec) then
    game:GetService("Players").LocalPlayer:Kick("Your executor is UNSAFE/DETECTED!!! Please use a different executor!")
    return
  end
end

local games = loadstring(game:HttpGet('https://raw.githubusercontent.com/Voxul/VoxulHub/main/games.lua'))()
if games[game.PlaceId] then
  local getgenv = getgenv or getfenv
  getgenv().VoxulLib = 'https://raw.githubusercontent.com/Voxul/VoxulHub/main/Orion.lua'
  getgenv().VoxulWindowCONF = {Name = "Voxul Hub", HidePremium = false, SaveConfig = true, ConfigFolder = "Voxul_ORIONLIB", IntroEnabled = false, IntroText = "Voxul Hub", IntroIcon = "http://www.roblox.com/asset/?id=6035039429"}
  loadstring(game:HttpGet(games.bURL .. games[game.PlaceId]))() 
else 
  warn("Voxul currently does not support this experience!")
end
