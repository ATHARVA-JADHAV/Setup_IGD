--!strict

--[=[
    DebugManager - Centralized debug output management
    
    Features:
    - Toggle debug flags on/off for different systems
    - Conditional print and warn functions
    - Easy flag management
    
    Usage:
    local Debug = require(ReplicatedStorage.Modules.DebugManager)
    Debug.print('ENTITY', 'Entity initialized successfully')
    Debug.warn('DATA', 'Player data failed to load')
]=]

local DebugManager = {}

-- Debug message storage
local DEBUG_MESSAGES = {}
local MAX_MESSAGES = 1000  -- Maximum number of messages to store

-- Debug flags - set to true to enable debug output for that system
local DEBUG_FLAGS = {
    -- Core Systems
    ENTITY = true,
    DATA = true,
    REPLICATOR = false,
    
    -- Server Systems
    SERVER = true,
    COMPONENTS = false,
    SYSTEMS = true,
    
    -- Client Systems
    CLIENT = true,
    CONTROLLERS = true,
    INTERFACES = false,
    UI = false,
    MANAGER = false,
    
    -- Specific Features

    INVENTORY = true,
    WEAPONS = true,
    RPGs = true,
    
    -- Development
    LOADER = false,
    TESTING = false,
    
    -- Global debug (overrides all flags when true)
    ALL = false,
}

-- Internal function to check if a flag is enabled
local function isEnabled(flag: string): boolean
    -- If ALL flag is true, enable everything
    if DEBUG_FLAGS.ALL then
        return true
    end
    
    -- Check if specific flag exists and is enabled
    if DEBUG_FLAGS[flag] ~= nil then
        return DEBUG_FLAGS[flag]
    end
    
    -- Unknown flag defaults to false
    return false
end

-- Internal function to store debug message
local function storeMessage(messageType: string, flag: string, message: string)
    local timestamp = os.date("%H:%M:%S")
    local formattedMessage = `[{timestamp}] [{messageType}:{flag}] {message}`
    
    -- Add to storage
    table.insert(DEBUG_MESSAGES, formattedMessage)
    
    -- Remove old messages if we exceed the limit
    if #DEBUG_MESSAGES > MAX_MESSAGES then
        table.remove(DEBUG_MESSAGES, 1)
    end
end

-- Print function that respects debug flags
function DebugManager.print(flag: string, ...: any)
    if isEnabled(flag) then
        local message = table.concat({...}, " ")
        print(`[DEBUG:{flag}]`, message)
        storeMessage("DEBUG", flag, message)
    end
end

-- Warn function that respects debug flags
function DebugManager.warn(flag: string, ...: any)
    if isEnabled(flag) then
        local message = table.concat({...}, " ")
        warn(`[DEBUG:{flag}]`, message)
        storeMessage("WARN", flag, message)
    end
end

-- Function to enable a debug flag
function DebugManager.enableFlag(flag: string)
    DEBUG_FLAGS[flag] = true
end

-- Function to disable a debug flag
function DebugManager.disableFlag(flag: string)
    DEBUG_FLAGS[flag] = false
end

-- Function to toggle a debug flag
function DebugManager.toggleFlag(flag: string)
    if DEBUG_FLAGS[flag] ~= nil then
        DEBUG_FLAGS[flag] = not DEBUG_FLAGS[flag]
    end
end

-- Function to check if a flag is enabled
function DebugManager.isEnabled(flag: string): boolean
    return isEnabled(flag)
end

-- Function to get all flags and their states
function DebugManager.getFlags(): {[string]: boolean}
    local flags = {}
    for flag, enabled in DEBUG_FLAGS do
        flags[flag] = enabled
    end
    return flags
end

-- Function to enable all debug output
function DebugManager.enableAll()
    DEBUG_FLAGS.ALL = true
end

-- Function to disable all debug output
function DebugManager.disableAll()
    DEBUG_FLAGS.ALL = false
    for flag, _ in DEBUG_FLAGS do
        if flag ~= 'ALL' then
            DEBUG_FLAGS[flag] = false
        end
    end
end

-- Function to add a new debug flag
function DebugManager.addFlag(flag: string, enabled: boolean?)
    DEBUG_FLAGS[flag] = enabled or false
end

-- Function to remove a debug flag
function DebugManager.removeFlag(flag: string)
    if flag ~= 'ALL' then
        DEBUG_FLAGS[flag] = nil
    end
end

-- Utility function to print available flags
function DebugManager.listFlags()
    print("Available Debug Flags:")
    for flag, enabled in DEBUG_FLAGS do
        local status = enabled and "✓" or "✗"
        print(`  {status} {flag}`)
    end
end

-- Function to get stored debug messages for GUI
function DebugManager.getMessages(): {string}
    return DEBUG_MESSAGES
end

-- Function to clear stored messages
function DebugManager.clearMessages()
    DEBUG_MESSAGES = {}
end

return DebugManager
