-- gmaDummy.lua
-- Simuliert grandMA2 Lua API für Testzwecke außerhalb der grandMA2 Umgebung

---@diagnostic disable-next-line: lowercase-global (Intellisense :D)
gma = {
    -- Cmd
    cmd = function(text)
        print("GMA_CMD >> " .. text)
    end,

    -- Feedback Window
    echo = function(text)
        print("GMA_ECHO: " .. tostring(text))
    end,

    -- Feedback with colors/types
    feedback = function(text)
        print("GMA_FEEDBACK: " .. tostring(text))
    end,

    -- User Input Simulator
    textinput = function(title, default)
        print("GMA_INPUT_PROMPT [" .. title .. "]: Default is '" .. default .. "'")
        return default -- Simulates user just pressing 'Please'
    end,

    -- Timers
    timer = function(func, delay, count)
        print("GMA_TIMER: Scheduled function to run every " .. delay .. "s")
    end,

    -- Sleep (Fake Lua Sleep)
    sleep = function(seconds)
        print("GMA_SLEEP: Waiting " .. seconds .. "s...")
    end,

    -- Get System Time
    gettime = function()
        return os.clock() -- Uses your PC's CPU clock as a substitute
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
            return "1" -- Mock return value
        end,
        setvar = function(varname, value)
            print("GMA_SETVAR: $" .. varname .. " set to " .. value)
        end
    }
}

print("--- GMA DUMMY CLASS LOADED ---")