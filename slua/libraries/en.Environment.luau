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

local Environment = {}

--- Gets the ambient light at a position in the region.
-- @param region_position Region-scope position at which to get the light level.
-- @return Light level as a range from 0.0 to 1.0.
function Environment.AmbientLight(region_position: vector)
    local light_level = tovector(ll.GetEnvironment(region_position, {SKY_LIGHT})[3])
    return ll.VecMag(light_level) *  0.57735026918
end

--- Gets the ambient light here.
-- Do not use in attachments; ll.GetPos() may act weird?
-- @return Light level as a range from 0.0 to 1.0.
function Environment.AmbientLightHere()
    return Environment.AmbientLight(ll.GetPos())
end

--- Quick method to determine if it is roughly "daytime", as tested via ambient light.
-- @param region_position Region-scope position at which to check the light level.
-- @param ambient_light_threshold Optional. A number between 0.0 and 1.0, over which it is deemed daytime. By default this is 0.85 (rough estimate of "daytime" light in testing).
-- @return true if daytime, false otherwise.
function Environment.IsDaytime(region_position: vector, ambient_light_threshold: number?)
    if Environment.AmbientLight(region_position) > ambient_light_threshold or 0.85 then
        return true
    end
    return false
end

--- Quick method to determine if it is roughly "daytime" here.
-- @param ambient_light_threshold Optional. A number between 0.0 and 1.0, over which it is deemed daytime. By default this is 0.85 (rough estimate of "daytime" light in testing).
-- @return true if daytime, false otherwise.
function Environment.IsDaytimeHere(ambient_light_threshold: number?)
    if Environment.AmbientLightHere() > (ambient_light_threshold or 0.85) then
        return true
    end
    return false
end

--- Gets the height of the sun at a position in the region.
-- This is used to determine "environment time".
-- @param region_position Region-scope position at which to get the sun height.
-- @return Height of sun as a range from -1.0 to 1.0.
function Environment.SunHeight(region_position: vector)
    local environment = ll.GetEnvironment(region_position, {SKY_SUN})
    local sun_position = tovector(environment[5])
    return sun_position.z
end

--- Gets the height of the sun here.
-- This is used to determine "environment time".
-- Do not use in attachments; ll.GetPos() may act weird?
-- @return Height of sun as a range from -1.0 to 1.0.
function Environment.SunHeightHere()
    return Environment.SunHeight(ll.GetPos())
end

return Environment
