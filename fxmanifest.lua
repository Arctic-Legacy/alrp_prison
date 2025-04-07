author 'NotSomething <hello@notsomething.net>'
description 'Arctic Legacy prison system'
version '0.0.1 alpha'

fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

dependency 'ND_Core'

files {
	'source/ui/index.html',
	'source/ui/script.js',
	'source/ui/style.css'
}

ui_page 'source/ui/index.html'

shared_scripts {
	'@ND_Core/init.lua',
	'@ox_lib/init.lua',
	'config_client.lua',
	'shared/classes/*.lua',
	'shared/sh_*.lua'
}

client_scripts {
	'client/classes/*.lua',
	'client/cl_processingPoints.lua'
}

server_scripts {
	'server/classes/*.lua',
	'server/sv_*.lua'
}

client_script 'client/cl_main.lua'