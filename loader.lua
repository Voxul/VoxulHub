local games = loadstring(game:HttpGetAsync(('https://raw.githubusercontent.com/Voxul/VoxulHub/main/games.lua')))()
if games[game.PlaceId] then loadstring(game:HttpGetAsync(games[game.PlaceId]))() else warn("Voxul currently does not support this experience!") end
