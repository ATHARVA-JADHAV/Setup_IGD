-- RPG Schema - Update this with your actual model name
return {
    ["BasicRPG"] = {
        Class = "BasicRPG",
        Name = "Basic RPG",
        Damage = 100,
        MaxAmmo = 1,
        ReloadTime = 3.5,
        ModelName = "BasicRPG"  -- CHANGE THIS to match your model in Assets/Tools/RPGs/
    },
    
    -- You can keep these for future use or remove them
    ["HeavyRPG"] = {
        Class = "HeavyRPG", 
        Name = "Heavy RPG",
        Damage = 175,
        MaxAmmo = 1,
        ReloadTime = 5.0,
        ModelName = "HeavyRPG"
    },
    
    ["QuadRPG"] = {
        Class = "QuadRPG",
        Name = "Quad Launcher", 
        Damage = 80,
        MaxAmmo = 4,
        ReloadTime = 6.0,
        ModelName = "QuadRPG"
    }
}