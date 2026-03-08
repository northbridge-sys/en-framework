--!strict

local enMarker = {}

--- Write marker data to name. 63 bytes printable ASCII, except pipe (|).
-- @param link Link number. Typically LINK_THIS.
-- @param text Text to write.
-- @return Unwritten overflow, or empty string.
function enMarker.WriteName(link: number, text: string): string
    if #text <= 63 then
        ll.SetLinkPrimitiveParamsFast(link, {PRIM_NAME, text})
        return ""
    end
    ll.SetLinkPrimitiveParamsFast(link, {PRIM_NAME, string.sub(text, 1, 63)})
    return string.sub(text, 64)
end

--- Write marker data to description. 127 bytes printable ASCII, except pipe (|).
-- @param link Link number. Typically LINK_THIS.
-- @param text Text to write.
-- @return Unwritten overflow, or empty string.
function enMarker.WriteDescription(link: number, text: string): string
    if #text <= 127 then
        ll.SetLinkPrimitiveParamsFast(link, {PRIM_DESC, text})
        return ""
    end
    ll.SetLinkPrimitiveParamsFast(link, {PRIM_DESC, string.sub(text, 1, 127)})
    return string.sub(text, 128)
end

--- Write marker data to hovertext. 254 UTF-8 bytes.
-- @param link Link number. Typically LINK_THIS.
-- @param text Text to write.
-- @return Unwritten overflow, or empty string.
function enMarker.WriteHovertext(link: number, text: string): string
    if #text <= 254 then
        ll.SetLinkPrimitiveParamsFast(link, {PRIM_TEXT, text, vector(0, 0, 0), 0.0})
        return ""
    end
    ll.SetLinkPrimitiveParamsFast(link, {PRIM_TEXT, string.sub(text, 1, 254), vector(0, 0, 0), 0.0})
    return string.sub(text, 255)
end

--- Recommended method of writing marker data to description & hovertext. 381 bytes printable ASCII, except pipe (|).
-- @param link Link number. Typically LINK_THIS.
-- @param text Text to write.
-- @return Unwritten overflow, or empty string.
function enMarker.WriteBoth(link: number, text: string): string
    return enMarker.WriteHovertext(link, enMarker.WriteDescription(link, text))
end

--- Recommended method of writing marker data to all fields. 444 bytes printable ASCII, except pipe (|).
-- @param link Link number. Typically LINK_THIS.
-- @param text Text to write.
-- @return Unwritten overflow, or empty string.
function enMarker.WriteAll(link: number, text: string)
    return enMarker.WriteName(link, enMarker.WriteHovertext(link, enMarker.WriteDescription(link, text)))
end

--- Read marker data from name.
-- WARNING: This has no validation. You should always add a few identifiable header characters to identify a marker.
-- @param link Link number. Typically LINK_THIS.
-- @return Prim name, or empty string if the link does not exist.
function enMarker.ReadName(link: number): string
    local value = ll.GetLinkPrimitiveParams(link, {PRIM_NAME})[1]
    if not value then return "" end
    return tostring(value)
end

--- Read marker data from description.
-- WARNING: This has no validation. You should always add a few identifiable header characters to identify a marker.
-- @param link Link number. Typically LINK_THIS.
-- @return Prim description, or empty string if the link does not exist.
function enMarker.ReadDescription(link: number): string
    local value = ll.GetLinkPrimitiveParams(link, {PRIM_DESC})[1]
    if not value then return "" end
    return tostring(value)
end

--- Read marker data from hovertext.
-- WARNING: This has no validation. You should always add a few identifiable header characters to identify a marker.
-- @param link Link number. Typically LINK_THIS.
-- @return Prim hovertext, or empty string if the link does not exist.
function enMarker.ReadHovertext(link: number): string
    local value = ll.GetLinkPrimitiveParams(link, {PRIM_TEXT})[1]
    if not value then return "" end
    return tostring(value)
end

--- Read marker data from both description and hovertext, when written with enMarker.WriteBoth().
-- WARNING: This has no validation. You should always add a few identifiable header characters to identify a marker.
-- @param link Link number. Typically LINK_THIS.
-- @return Marker data, or empty string if the link does not exist.
function enMarker.ReadBoth(link: number): string
    return enMarker.ReadDescription(link) .. enMarker.ReadHovertext(link)
end

--- Read marker data from all fields, when written with enMarker.WriteAll().
-- WARNING: This has no validation. You should always add a few identifiable header characters to identify a marker.
-- @param link Link number. Typically LINK_THIS.
-- @return Marker data, or empty string if the link does not exist.
function enMarker.ReadAll(link: number): string
    return enMarker.ReadDescription(link) .. enMarker.ReadHovertext(link) .. enMarker.ReadName(link)
end

return enMarker