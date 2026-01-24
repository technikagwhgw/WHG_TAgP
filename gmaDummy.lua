-- gmaDummy.lua
-- Simuliert grandMA2 Lua API für Testzwecke außerhalb der grandMA2 Umgebung

---@diagnostic disable-next-line: lowercase-global
gma = {
    --_tasks = {}, -siehe Timer Beta status
    -- Cmd
    cmd = function(text)
        print("CMD >> " .. text)
    end,
    -- Feedback Window
    echo = function(text)
        print("ECHO: " .. tostring(text))
    end,
    -- Feedback with colors/types
    feedback = function(text)
        print("FEED: " .. tostring(text))
    end,
    -- User Input Simulator
    textinput = function(title, default)
        print("GMA_INPUT_PROMPT [" .. title .. "]: Default is '" .. default .. "'")
        return default -- Simulatiert 'Please'
    end,
    -- Sleep (Fake Lua Sleep)
    sleep = function(seconds)
        print("GMA_SLEEP: Waiting " .. seconds .. "s...")
    end,
    -- Get System Time
    gettime = function()
        return os.clock()
    end,
    -- GUI Popups
    gui = {
        msgbox = function(title, text)
            print("GMA_MSGBOX [" .. title .. "]: " .. text)
        end,
        confirm = function(title, text)
            print("GMA_CONFIRM [" .. title .. "]: " .. text)
            return true
        end
    },
    -- Variables
    show = {
        getvar = function(varname)
            print("GMA_GETVAR: Requesting $" .. varname)
            return "3"
        end,
        setvar = function(varname, value)
            print("GMA_SETVAR: $" .. varname .. " set to " .. value)
        end,
        getobj = {
            handle = function(name)
                -- Fake Objects
                local existing_objects = {
                    --Beispielobjekte
                    ["Group 1"] = 1001,
                    ["Macro 1"] = 2001,
                    ["Preset 1.1"] = 3001,
                    ["Executor 100.101"] = 10101,
                    ["Executor 100.102"] = 10102,
                    ["Executor 100.103"] = 10103,
                    ["Executor 100.106"] = 10106
                }
                if existing_objects[name] then
                    print("GMA_HANDLE: Found object '" .. name .. "'")
                    return existing_objects[name]
                else
                    print("GMA_HANDLE: Object '" .. name .. "' NOT FOUND")
                    return nil
                end
            end,
            label = function(handle)
                return "Mock_Label_for_" .. tostring(handle)
            end
        },
        property = {
            get = function(handle, prop_name)
                print("GMA_PROPERTY_GET: Getting property '" .. prop_name .. "' for handle " .. tostring(handle))
                if prop_name == "isFading" then
                    return "No"
                end
                return nil
            end
        }
    }
}

-- NO Error Load --
print("--- GMA DUMMY CLASS LOADED ---")