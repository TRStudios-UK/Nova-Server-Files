fx_version 'cerulean'
game 'gta5'

dependency "vrp"

client_scripts {
	"client.lua",
}

server_scripts{
	"@vrp/lib/utils.lua",
	"server.lua"
}