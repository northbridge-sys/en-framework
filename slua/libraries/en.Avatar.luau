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

local Avatar = {}

--- Avatar UUID prettifier.
-- @param avatar_uuid avatar UUID
-- @return avatar_uuid, quoted with a parenthetical link to their profile
function Avatar.Elem(avatar_uuid: string)
    return `"{avatar_uuid}" (secondlife:///app/agent/{avatar_uuid}/username)`
end

--- Gets the active group of an avatar in the same region.
-- Requires avatar to have at least one worn attachment.
-- @param avatar_uuid avatar UUID
-- @return group UUID, or NULL_KEY cast as a UUID
function Avatar.GetGroup(avatar_uuid: string)
    local attaches = ll.GetAttachedList(uuid(avatar_uuid) or uuid(NULL_KEY))
    if #attaches == 0 or attaches[1] == "NOT ON REGION" or attaches[1] == "NOT FOUND" then
        return uuid(NULL_KEY)
    end
    local attachment_uuid = uuid(attaches[1])
    local details = ll.GetObjectDetails(attachment_uuid, {OBJECT_GROUP})
    return uuid(details[1])
end

return Avatar
