local games = loadstring(game:HttpGet('https://raw.githubusercontent.com/Voxul/VoxulHub/main/games.lua'))()
if games[game.PlaceId] then
  local getgenv = getgenv or getfenv
  getgenv().VoxulLib = 'https://raw.githubusercontent.com/Voxul/VoxulHub/main/Orion.lua'
  getgenv().VoxulWindowCONF = {Name = "Voxul Hub", HidePremium = false, SaveConfig = true, ConfigFolder = "Voxul_ORIONLIB", IntroEnabled = false, IntroText = "Voxul Hub", IntroIcon = "http://www.roblox.com/asset/?id=6035039429"}
  loadstring(game:HttpGetAsync(games[game.PlaceId]))() 
else 
  warn("Voxul currently does not support this experience!") 
end
