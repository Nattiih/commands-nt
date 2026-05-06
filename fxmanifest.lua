fx_version "bodacious"
game "gta5"
lua54 "yes"

author "Natti"
description "Sistema de Punição - Modo punição para jogadores que descumprem regras"
version "1.0.0"

client_scripts {
	"@vrp/lib/Utils.lua",
	"client-side/*"
}

server_scripts {
	"@vrp/lib/Utils.lua",
	"server-side/*"
}
