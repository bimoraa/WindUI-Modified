

--[[

    Luarmor API   |   https://luarmor.net
    
]]

-- HttpService was referenced below but never declared (a guaranteed crash on the
-- non-HttpGetAsync fallback path); cloneref it once like every other service module.
local cloneref = (cloneref or clonereference or function(instance) return instance end)
local HttpService = cloneref(game:GetService("HttpService"))

local Luarmor = {}


function Luarmor.New(scriptId, discord)
    local APIURL = "https://sdkapi-public.luarmor.net/library.lua"

    local fsetclipboard = setclipboard or toclipboard

    -- Fetch + load the Luarmor SDK defensively. A network/HTTP failure, a non-Lua
    -- response, or a runtime error inside the SDK must degrade to a graceful "invalid"
    -- verifier instead of crashing the key path (which would hang window creation forever).
    local API
    local fetchOk, body = pcall(function()
        return (game.HttpGetAsync and game:HttpGetAsync(APIURL)) or HttpService:GetAsync(APIURL)
    end)
    if fetchOk and type(body) == "string" then
        local chunk = loadstring(body)
        if chunk then
            local runOk, result = pcall(chunk)
            if runOk then
                API = result
            end
        end
    end

    if type(API) ~= "table" then
        return {
            Verify = function()
                return false, "Luarmor SDK failed to load (network/HTTP error)"
            end,
            Copy = function()
                if fsetclipboard then fsetclipboard(tostring(discord)) end
            end,
        }
    end

    API.script_id = scriptId

    local function ValidateKey(key)
        local checkOk, status = pcall(API.check_key, key)
        if not checkOk or type(status) ~= "table" then
            return false, "Key check request failed. Please try again."
        end
        --print(status)

        if (status.code == "KEY_VALID") then
            return true, "Whitelisted!"

        elseif (status.code == "KEY_HWID_LOCKED") then
            return false, "Key linked to a different HWID. Please reset it using our bot"

        elseif (status.code == "KEY_INCORRECT") then
            return false, "Key is wrong or deleted!"
        else
            return false, "Key check failed:" .. tostring(status.message) .. " Code: " .. tostring(status.code)
        end
    end

    local function CopyLink()
        if fsetclipboard then
            fsetclipboard(tostring(discord))
        end
    end

    return {
        Verify = ValidateKey,
        Copy = CopyLink
    }
end


return Luarmor