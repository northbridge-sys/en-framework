--[[
En Framework
Copyright (C) 2024-26  Northbridge Business Systems
https://docs.northbridgesys.com/en-framework

This script is free software: you can redistribute it and/or modify it under the
terms of the GNU Lesser General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This script is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License along
with this script.  If not, see <https://www.gnu.org/licenses/>.
]]

-- master script for testing

local en = require("./en")

function main()
    print("ready")
    local group = en.Avatar.GetGroup(tostring(ll.GetOwner()))
    print(`group: {group}`)
    local ambient = en.Environment.AmbientLightHere()
    print(`ambient: {ambient}`)
    local daytime = en.Environment.IsDaytimeHere()
    print(`daytime: {daytime}`)
    local sun = en.Environment.SunHeightHere()
    print(`sun: {sun}`)
end

main()
