--!strict

local enAgent = {}

-- Note: an "agent" is the user controlling an "avatar", its physical representation in-world.

--- Gets the active group of an agent in the same region.
-- Requires agent's avatar to have at least one worn attachment.
-- @param agent_uuid agent UUID
-- @return group UUID, or NULL_KEY cast as a UUID
function enAgent.GetGroup(agent_uuid: uuid): uuid
    local attaches = ll.GetAttachedList(agent_uuid)
    if #attaches == 0 or attaches[1] == "NOT ON REGION" or attaches[1] == "NOT FOUND" then
        return NULL_KEY
    end
    local attachment_uuid = touuid(attaches[1])
    local details = ll.GetObjectDetails(attachment_uuid, {OBJECT_GROUP})
    local uuid = touuid(details[1])
    if not uuid then return NULL_KEY end
    return uuid
end

return enAgent
