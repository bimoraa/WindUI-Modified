

--[[

    Junkie Development API   |   

]]

local JunkieDevelopment = {}

function JunkieDevelopment.New(ServiceId, ApiKey, Provider)
    -- JunkieProtected is injected by an external loader; if that loader did not run,
    -- indexing it here would crash the key path and hang window creation. Degrade gracefully.
    if not JunkieProtected then
        return {
            Verify = function()
                return false, "JunkieProtected loader not present"
            end,
            Copy = function() end,
        }
    end
    JunkieProtected.API_KEY = ApiKey
    JunkieProtected.PROVIDER = Provider
    JunkieProtected.SERVICE_ID = ServiceId

    local function ValidateKey(key)
        if not key or key == "" then
            print("No key provided!")
            --game.Players.LocalPlayer:Kick("No key provided. Please get a key.")
            return false, "No key provided. Please get a key."
        end

        local keylessCheck = JunkieProtected.IsKeylessMode()
        if keylessCheck and keylessCheck.keyless_mode then
            print("Keyless mode enabled. Starting script...")
            return true, "Keyless mode enabled. Starting script..."
        end

        local result = JunkieProtected.ValidateKey({ Key = key })
        if result == "valid" then
            print("Key is valid! Starting script...")
            if load then pcall(load) end
            if _G.JD_IsPremium then                       
                print("Premium user detected!")
            else
                print("Standard user")
            end

            return true, "Key is valid!"
        else
            local keyLink = JunkieProtected.GetKeyLink()
            print("Invalid key!")
            --game.Players.LocalPlayer:Kick("Invalid key. Get one from: " .. keyLink)
            return false, "Invalid key. Get one from:" .. keyLink
        end                                                                                                            
    end

    local function copyLink()
        local link = JunkieProtected.GetKeyLink()                                                                                        
        --print("Get your key: " .. link)                                                                                                
        if setclipboard then
            setclipboard(link)
        end
    end                                                                                                                                                                                                                                                                       
    return {
        Verify = ValidateKey,
        Copy = copyLink
    }
end

return JunkieDevelopment


