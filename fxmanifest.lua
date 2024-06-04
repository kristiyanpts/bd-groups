fx_version "cerulean"

description "FiveM Player Groups System that supports both just the ui itself or integrated into a phone system of yours."
author "Bulgar Development"
version '1.0.0'
repository 'https://github.com/kristiyanpts/bd-groups'

lua54 'yes'

games {
  "gta5",
  "rdr3"
}

ui_page 'web/build/index.html'

shared_scripts {
  '@ox_lib/init.lua',
  "shared/*.lua"
}

client_script "client/**/*"
server_script "server/**/*"

files {
  'web/build/index.html',
  'web/build/**/*',
}

escrow_ignore {
  "client/**/*",
  "server/**/*",
  "shared/*.lua",
}
