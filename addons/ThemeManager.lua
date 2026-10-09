local cloneref = (cloneref or clonereference or function(instance: any)
    return instance
end)
local clonefunction = (clonefunction or copyfunction or function(func) 
    return func 
end)

local HttpService: HttpService = cloneref(game:GetService("HttpService"))

--// Fix is_____ functions for shitsploits, those functions should never error, only return a boolean. (why is this still a problem in the big 2026)
local isfolder, isfile, listfiles = isfolder, isfile, listfiles
local isfolder_copy, isfile_copy, listfiles_copy = clonefunction(isfolder), clonefunction(isfile), clonefunction(listfiles)
local isfolder_success, isfolder_error = pcall(function() return isfolder_copy("test" .. tostring(math.random(1000000, 9999999))) end)

if isfolder_success == false or typeof(isfolder_error) ~= "boolean" then
    isfolder = function(folder)
        local success, data = pcall(isfolder_copy, folder)
        return (if success then data else false)
    end

    isfile = function(file)
        local success, data = pcall(isfile_copy, file)
        return (if success then data else false)
    end

    listfiles = function(folder)
        local success, data = pcall(listfiles_copy, folder)
        return (if success then data else {})
    end
end

--// WCAG21 constants (https://www.w3.org/TR/WCAG21/#dfn-relative-luminance)
local ContrastWarnThreshold = 4.5 --// Accessibility: minimum WCAG AA contrast ratio for normal text
local SrgbLinearThreshold = 0.03928 --// sRGB channel value below which the linear conversion is a simple divide
local SrgbLinearDivisor = 12.92 --// Divisor used for channel values below SrgbLinearThreshold
local SrgbGammaOffset = 0.055 --// Offset applied before the gamma expansion power curve
local SrgbGammaScale = 1.055 --// Scale applied before the gamma expansion power curve
local SrgbGammaExponent = 2.4 --// Exponent for the gamma expansion power curve
local LuminanceRedWeight,
      LuminanceGreenWeight,
      LuminanceBlueWeight = 0.2126, 0.7152, 0.0722 --// R, G, B channel weights in the relative luminance formula
local ContrastRatioOffset = 0.05 --// Offset added to both luminances when computing a contrast ratio

--// Theme Manager
local SchemeIndexes = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }

local ThemeManager = {
    Library = nil,

    Folder = "Marden-Themes",

    AppliedToTab = false,
    DefaultThemeName = nil,

    --// Accessibility: contrast warning state
    ContrastLabel = nil,
    ContrastWasPoor = false,
    
    BuiltInThemes = {
        ["Marden"] = {
            1,
            { FontColor = "ffffff", MainColor = "191919", AccentColor = "7d55ff", BackgroundColor = "0f0f0f", OutlineColor = "282828", BackgroundImage = "" },
        },
        ["Minty"] = {
            2,
            { FontColor = "ffffff", MainColor = "282828", AccentColor = "3db488", BackgroundColor = "252525", OutlineColor = "323232", BackgroundImage = "" },
        },
        ["Dracula"] = {
            3,
            { FontColor = "f8eefb", MainColor = "211a28", AccentColor = "ee9bd8", BackgroundColor = "1f1926", OutlineColor = "2d2238", BackgroundImage = "" },
        },
        ["Monochrome"] = {
            4,
            { FontColor = "c7c7c7", MainColor = "161616", AccentColor = "8a8a8a", BackgroundColor = "161616", OutlineColor = "1b1b1b", BackgroundImage = "" },
        },
                ["Midnight Ocean"] = {
            5,
            { FontColor = "e6f1f7", MainColor = "0a1118", AccentColor = "4cc9f0", BackgroundColor = "080e14", OutlineColor = "111c26", BackgroundImage = "" },
        },
        ["Forest Mist"] = {
            6,
            { FontColor = "e8f3ec", MainColor = "0f1a15", AccentColor = "7ddba3", BackgroundColor = "0c1511", OutlineColor = "17271f", BackgroundImage = "" },
        },
        ["Ember"] = {
            7,
            { FontColor = "f7ebe4", MainColor = "1a100d", AccentColor = "ff7a45", BackgroundColor = "150c0a", OutlineColor = "2a1a15", BackgroundImage = "" },
        },
        ["Violet Noir"] = {
            8,
            { FontColor = "ece6f7", MainColor = "0d0a14", AccentColor = "8b5cf6", BackgroundColor = "0a0710", OutlineColor = "191325", BackgroundImage = "" },
        },
        ["Crimson Night"] = {
            9,
            { FontColor = "f6e9ec", MainColor = "140a0d", AccentColor = "e11d48", BackgroundColor = "100608", OutlineColor = "22121a", BackgroundImage = "" },
        },
        ["Teal Void"] = {
            10,
            { FontColor = "e3f4f3", MainColor = "081415", AccentColor = "2dd4bf", BackgroundColor = "060f10", OutlineColor = "0f2224", BackgroundImage = "" },
        },
        ["Slate Gold"] = {
            11,
            { FontColor = "ecebe6", MainColor = "16181d", AccentColor = "e0b84c", BackgroundColor = "12141a", OutlineColor = "22252c", BackgroundImage = "" },
        },
        ["Mocha"] = {
            12,
            { FontColor = "f1e6dc", MainColor = "1e1714", AccentColor = "d4a373", BackgroundColor = "19130f", OutlineColor = "2b211c", BackgroundImage = "" },
        },
        ["Sunset Dusk"] = {
            13,
            { FontColor = "fbeaf0", MainColor = "1f1424", AccentColor = "ff9e7a", BackgroundColor = "1a101e", OutlineColor = "2d1b33", BackgroundImage = "" },
        },
        ["Lavender Haze"] = {
            14,
            { FontColor = "f1ecfb", MainColor = "252033", AccentColor = "b9a2ff", BackgroundColor = "211c2e", OutlineColor = "322b45", BackgroundImage = "" },
        },
        ["Nord Frost"] = {
            15,
            { FontColor = "eceff4", MainColor = "2e3440", AccentColor = "88c0d0", BackgroundColor = "2b303b", OutlineColor = "3b4252", BackgroundImage = "" },
        },
        ["Rose Quartz"] = {
            16,
            { FontColor = "3a2a2f", MainColor = "f7eef0", AccentColor = "d45d79", BackgroundColor = "fbf5f6", OutlineColor = "ecdde1", BackgroundImage = "" },
        },
        ["Mint Light"] = {
            17,
            { FontColor = "1f3a2e", MainColor = "eef7f3", AccentColor = "2fa57a", BackgroundColor = "f6fbf8", OutlineColor = "dcece4", BackgroundImage = "" },
        },
        ["Arctic Light"] = {
            18,
            { FontColor = "1c2733", MainColor = "f4f7fa", AccentColor = "3b82f6", BackgroundColor = "ffffff", OutlineColor = "e3e9ef", BackgroundImage = "" },
        },
		        ["Tokyo Night"] = {
            19,
            { FontColor = "c0caf5", MainColor = "1a1b26", AccentColor = "7aa2f7", BackgroundColor = "16161e", OutlineColor = "24283b", BackgroundImage = "" },
        },
        ["Catppuccin Mocha"] = {
            20,
            { FontColor = "cdd6f4", MainColor = "1e1e2e", AccentColor = "cba6f7", BackgroundColor = "181825", OutlineColor = "313244", BackgroundImage = "" },
        },
        ["Rosé Pine"] = {
            21,
            { FontColor = "e0def4", MainColor = "191724", AccentColor = "ebbcba", BackgroundColor = "14121f", OutlineColor = "26233a", BackgroundImage = "" },
        },
        ["Gruvbox"] = {
            22,
            { FontColor = "ebdbb2", MainColor = "282828", AccentColor = "fabd2f", BackgroundColor = "1d2021", OutlineColor = "3c3836", BackgroundImage = "" },
        },
        ["Solarized Dark"] = {
            23,
            { FontColor = "93a1a1", MainColor = "002b36", AccentColor = "2aa198", BackgroundColor = "00212b", OutlineColor = "073642", BackgroundImage = "" },
        },
        ["Monokai"] = {
            24,
            { FontColor = "f8f8f2", MainColor = "272822", AccentColor = "a6e22e", BackgroundColor = "1e1f1c", OutlineColor = "3e3d32", BackgroundImage = "" },
        },
        ["One Dark"] = {
            25,
            { FontColor = "abb2bf", MainColor = "282c34", AccentColor = "61afef", BackgroundColor = "21252b", OutlineColor = "353b45", BackgroundImage = "" },
        },
        ["Everforest"] = {
            26,
            { FontColor = "d3c6aa", MainColor = "2d353b", AccentColor = "a7c080", BackgroundColor = "272e33", OutlineColor = "3d484d", BackgroundImage = "" },
        },
        ["Kanagawa"] = {
            27,
            { FontColor = "dcd7ba", MainColor = "1f1f28", AccentColor = "7e9cd8", BackgroundColor = "16161d", OutlineColor = "2a2a37", BackgroundImage = "" },
        },
        ["Ayu Mirage"] = {
            28,
            { FontColor = "cccac2", MainColor = "1f2430", AccentColor = "ffcc66", BackgroundColor = "1a1f29", OutlineColor = "2d3340", BackgroundImage = "" },
        },
        ["Synthwave"] = {
            29,
            { FontColor = "f5e9ff", MainColor = "1a1033", AccentColor = "ff4fd8", BackgroundColor = "140c28", OutlineColor = "2a1b4d", BackgroundImage = "" },
        },
        ["Cyberpunk"] = {
            30,
            { FontColor = "f0f0ff", MainColor = "0d0d14", AccentColor = "fcee0a", BackgroundColor = "08080d", OutlineColor = "1a1a26", BackgroundImage = "" },
        },
        ["Neon Mint"] = {
            31,
            { FontColor = "e8fff6", MainColor = "0a0f0d", AccentColor = "00ffa3", BackgroundColor = "070b0a", OutlineColor = "131c19", BackgroundImage = "" },
        },
        ["Midnight Blue"] = {
            32,
            { FontColor = "e4ebff", MainColor = "0c1226", AccentColor = "5b8cff", BackgroundColor = "090e1e", OutlineColor = "151d3a", BackgroundImage = "" },
        },
        ["Deep Space"] = {
            33,
            { FontColor = "e8e8ff", MainColor = "0b0b1a", AccentColor = "7c7cff", BackgroundColor = "07070f", OutlineColor = "16162b", BackgroundImage = "" },
        },
        ["Obsidian"] = {
            34,
            { FontColor = "e0e0e0", MainColor = "101010", AccentColor = "e5e5e5", BackgroundColor = "0b0b0b", OutlineColor = "1a1a1a", BackgroundImage = "" },
        },
        ["Graphite"] = {
            35,
            { FontColor = "f2f2f7", MainColor = "1c1c1e", AccentColor = "0a84ff", BackgroundColor = "161618", OutlineColor = "2c2c2e", BackgroundImage = "" },
        },
        ["Coffee Bean"] = {
            36,
            { FontColor = "efe3d8", MainColor = "17110e", AccentColor = "c68b59", BackgroundColor = "120c0a", OutlineColor = "261c17", BackgroundImage = "" },
        },
        ["Merlot"] = {
            37,
            { FontColor = "f5e6ec", MainColor = "1c0d14", AccentColor = "b83a6b", BackgroundColor = "16090f", OutlineColor = "2d1621", BackgroundImage = "" },
        },
        ["Peach Fuzz"] = {
            38,
            { FontColor = "fbece6", MainColor = "211716", AccentColor = "ffb199", BackgroundColor = "1b1211", OutlineColor = "31221f", BackgroundImage = "" },
        },
        ["Matcha"] = {
            39,
            { FontColor = "e9f1e2", MainColor = "141a12", AccentColor = "a3c96a", BackgroundColor = "0f140d", OutlineColor = "202a1c", BackgroundImage = "" },
        },
        ["Aurora"] = {
            40,
            { FontColor = "e3f2f8", MainColor = "0f1c26", AccentColor = "7af0c0", BackgroundColor = "0a141c", OutlineColor = "1a2b38", BackgroundImage = "" },
        },
        ["Bubblegum"] = {
            41,
            { FontColor = "fdeaf6", MainColor = "1d1520", AccentColor = "ff80bf", BackgroundColor = "17101a", OutlineColor = "2c2030", BackgroundImage = "" },
        },
        ["Amethyst"] = {
            42,
            { FontColor = "f0e8fb", MainColor = "1a1226", AccentColor = "c084fc", BackgroundColor = "140d1f", OutlineColor = "291d3d", BackgroundImage = "" },
        },
        ["Sapphire"] = {
            43,
            { FontColor = "e5edfb", MainColor = "0b1220", AccentColor = "3b82f6", BackgroundColor = "070d18", OutlineColor = "14203a", BackgroundImage = "" },
        },
        ["Emerald"] = {
            44,
            { FontColor = "e4f5ec", MainColor = "0a1612", AccentColor = "10b981", BackgroundColor = "07110d", OutlineColor = "12261e", BackgroundImage = "" },
        },
        ["Ruby"] = {
            45,
            { FontColor = "f8e8ea", MainColor = "1a0b0e", AccentColor = "ef4444", BackgroundColor = "140709", OutlineColor = "2b1317", BackgroundImage = "" },
        },
        ["Citrus"] = {
            46,
            { FontColor = "f3f4de", MainColor = "15160c", AccentColor = "d9f24a", BackgroundColor = "101108", OutlineColor = "232512", BackgroundImage = "" },
        },
        ["Ice"] = {
            47,
            { FontColor = "eaf6ff", MainColor = "101820", AccentColor = "a5e3ff", BackgroundColor = "0b1219", OutlineColor = "1b2833", BackgroundImage = "" },
        },
        ["Smoke"] = {
            48,
            { FontColor = "e8e9ea", MainColor = "202225", AccentColor = "9aa5b1", BackgroundColor = "1a1b1e", OutlineColor = "2f3237", BackgroundImage = "" },
        },
		        ["Nightfox"] = {
            49,
            { FontColor = "cdcecf", MainColor = "192330", AccentColor = "719cd6", BackgroundColor = "131a24", OutlineColor = "29394f", BackgroundImage = "" },
        },
        ["Palenight"] = {
            50,
            { FontColor = "a6accd", MainColor = "292d3e", AccentColor = "c792ea", BackgroundColor = "232635", OutlineColor = "343b51", BackgroundImage = "" },
        },
        ["Material Ocean"] = {
            51,
            { FontColor = "a6accd", MainColor = "0f111a", AccentColor = "84ffff", BackgroundColor = "090b10", OutlineColor = "1a1c25", BackgroundImage = "" },
        },
        ["Night Owl"] = {
            52,
            { FontColor = "d6deeb", MainColor = "011627", AccentColor = "82aaff", BackgroundColor = "010f1d", OutlineColor = "0b2942", BackgroundImage = "" },
        },
        ["Poimandres"] = {
            53,
            { FontColor = "e4f0fb", MainColor = "1b1e28", AccentColor = "5de4c7", BackgroundColor = "171922", OutlineColor = "303340", BackgroundImage = "" },
        },
        ["Horizon"] = {
            54,
            { FontColor = "fdf0ed", MainColor = "1c1e26", AccentColor = "e95678", BackgroundColor = "16161c", OutlineColor = "2e303e", BackgroundImage = "" },
        },
        ["Oceanic Next"] = {
            55,
            { FontColor = "d8dee9", MainColor = "1b2b34", AccentColor = "5fb3b3", BackgroundColor = "16232a", OutlineColor = "2a3d48", BackgroundImage = "" },
        },
        ["Cobalt"] = {
            56,
            { FontColor = "e8f1ff", MainColor = "15232d", AccentColor = "ffc600", BackgroundColor = "0f1a22", OutlineColor = "213646", BackgroundImage = "" },
        },
        ["Moonlight"] = {
            57,
            { FontColor = "c8d3f5", MainColor = "222436", AccentColor = "c099ff", BackgroundColor = "1e2030", OutlineColor = "2f334d", BackgroundImage = "" },
        },
        ["Vesper"] = {
            58,
            { FontColor = "e8e8e8", MainColor = "141414", AccentColor = "ffc799", BackgroundColor = "0e0e0e", OutlineColor = "232323", BackgroundImage = "" },
        },
        ["Zenburn"] = {
            59,
            { FontColor = "dcdccc", MainColor = "2b2b2b", AccentColor = "f0dfaf", BackgroundColor = "232323", OutlineColor = "3a3a3a", BackgroundImage = "" },
        },
        ["Carbon"] = {
            60,
            { FontColor = "f4f4f4", MainColor = "161616", AccentColor = "78a9ff", BackgroundColor = "0f0f0f", OutlineColor = "262626", BackgroundImage = "" },
        },
        ["Cherry Blossom"] = {
            61,
            { FontColor = "fbe9f0", MainColor = "1e1217", AccentColor = "f4a9c4", BackgroundColor = "170d12", OutlineColor = "2f1d26", BackgroundImage = "" },
        },
        ["Blood Orange"] = {
            62,
            { FontColor = "f9ebe3", MainColor = "1b0f0b", AccentColor = "ff5f2e", BackgroundColor = "150b08", OutlineColor = "2c1912", BackgroundImage = "" },
        },
        ["Rosewood"] = {
            63,
            { FontColor = "f3e4e4", MainColor = "1a1112", AccentColor = "c4686e", BackgroundColor = "140c0d", OutlineColor = "2a1b1d", BackgroundImage = "" },
        },
        ["Raspberry"] = {
            64,
            { FontColor = "fbe6ee", MainColor = "1a0e15", AccentColor = "d6336c", BackgroundColor = "14090f", OutlineColor = "2c1824", BackgroundImage = "" },
        },
        ["Hibiscus"] = {
            65,
            { FontColor = "fde8f1", MainColor = "1b0d16", AccentColor = "ff3d81", BackgroundColor = "150911", OutlineColor = "2c1626", BackgroundImage = "" },
        },
        ["Salmon"] = {
            66,
            { FontColor = "fceae4", MainColor = "1e1310", AccentColor = "fa8a73", BackgroundColor = "180e0b", OutlineColor = "30211c", BackgroundImage = "" },
        },
        ["Amber Glow"] = {
            67,
            { FontColor = "fbf0dc", MainColor = "1a140a", AccentColor = "ffb02e", BackgroundColor = "140f07", OutlineColor = "2c2212", BackgroundImage = "" },
        },
        ["Pumpkin Spice"] = {
            68,
            { FontColor = "f8ebdd", MainColor = "1c110a", AccentColor = "ff8c42", BackgroundColor = "160d07", OutlineColor = "2e1d12", BackgroundImage = "" },
        },
        ["Honey"] = {
            69,
            { FontColor = "faf0d7", MainColor = "1b1608", AccentColor = "f2c14e", BackgroundColor = "151106", OutlineColor = "2d2510", BackgroundImage = "" },
        },
        ["Saffron"] = {
            70,
            { FontColor = "f7eed8", MainColor = "1d1508", AccentColor = "e8a317", BackgroundColor = "171006", OutlineColor = "302210", BackgroundImage = "" },
        },
        ["Butterscotch"] = {
            71,
            { FontColor = "f6e9d5", MainColor = "1e160f", AccentColor = "e0a96d", BackgroundColor = "18110b", OutlineColor = "31251a", BackgroundImage = "" },
        },
        ["Desert Sand"] = {
            72,
            { FontColor = "efe5d4", MainColor = "1f1b15", AccentColor = "d1b27d", BackgroundColor = "19150f", OutlineColor = "322c22", BackgroundImage = "" },
        },
        ["Copper"] = {
            73,
            { FontColor = "f4e6dc", MainColor = "1c1311", AccentColor = "b87333", BackgroundColor = "160e0c", OutlineColor = "2e211d", BackgroundImage = "" },
        },
        ["Pine"] = {
            74,
            { FontColor = "e2efe8", MainColor = "0c1713", AccentColor = "3fae7f", BackgroundColor = "08110e", OutlineColor = "17291f", BackgroundImage = "" },
        },
        ["Moss"] = {
            75,
            { FontColor = "e6ecd9", MainColor = "14180e", AccentColor = "8aa855", BackgroundColor = "0f130a", OutlineColor = "232a18", BackgroundImage = "" },
        },
        ["Jade"] = {
            76,
            { FontColor = "dff5ea", MainColor = "08150f", AccentColor = "3ddc97", BackgroundColor = "050f0a", OutlineColor = "112519", BackgroundImage = "" },
        },
        ["Sage"] = {
            77,
            { FontColor = "e8eee4", MainColor = "1a1f19", AccentColor = "9cb894", BackgroundColor = "141813", OutlineColor = "2a3128", BackgroundImage = "" },
        },
        ["Lime Zest"] = {
            78,
            { FontColor = "f0f9d9", MainColor = "12170a", AccentColor = "b5e61d", BackgroundColor = "0d1107", OutlineColor = "212a10", BackgroundImage = "" },
        },
        ["Fern"] = {
            79,
            { FontColor = "e3f0e0", MainColor = "101a10", AccentColor = "5fbf5f", BackgroundColor = "0b130b", OutlineColor = "1d2c1d", BackgroundImage = "" },
        },
        ["Seafoam"] = {
            80,
            { FontColor = "e0f5ef", MainColor = "0d1a18", AccentColor = "6fe3c1", BackgroundColor = "08130f", OutlineColor = "1b2e2a", BackgroundImage = "" },
        },
        ["Olive Grove"] = {
            81,
            { FontColor = "ebebd6", MainColor = "191a0f", AccentColor = "a3a847", BackgroundColor = "131409", OutlineColor = "2b2d18", BackgroundImage = "" },
        },
        ["Clover"] = {
            82,
            { FontColor = "e4f4e6", MainColor = "0e1a10", AccentColor = "4ade80", BackgroundColor = "09130b", OutlineColor = "1a2e1e", BackgroundImage = "" },
        },
        ["Absinthe"] = {
            83,
            { FontColor = "eaf5dc", MainColor = "131a0d", AccentColor = "9fe870", BackgroundColor = "0e1409", OutlineColor = "233018", BackgroundImage = "" },
        },
        ["Lagoon"] = {
            84,
            { FontColor = "ddf4f5", MainColor = "08171b", AccentColor = "22d3ee", BackgroundColor = "050f12", OutlineColor = "11282f", BackgroundImage = "" },
        },
        ["Glacier"] = {
            85,
            { FontColor = "e6f4fa", MainColor = "101c24", AccentColor = "7dd3fc", BackgroundColor = "0a141b", OutlineColor = "1c2e3b", BackgroundImage = "" },
        },
        ["Deep Sea"] = {
            86,
            { FontColor = "dcebf2", MainColor = "07121a", AccentColor = "38a3c9", BackgroundColor = "040b11", OutlineColor = "0f2230", BackgroundImage = "" },
        },
        ["Turquoise"] = {
            87,
            { FontColor = "e0f7f4", MainColor = "0a1a1a", AccentColor = "40e0d0", BackgroundColor = "061212", OutlineColor = "143030", BackgroundImage = "" },
        },
        ["Cyan Pulse"] = {
            88,
            { FontColor = "e0fbff", MainColor = "0a1519", AccentColor = "00e5ff", BackgroundColor = "060e11", OutlineColor = "142830", BackgroundImage = "" },
        },
        ["Abyss"] = {
            89,
            { FontColor = "d8e6f0", MainColor = "050b12", AccentColor = "3e7cb1", BackgroundColor = "03070c", OutlineColor = "0d1a28", BackgroundImage = "" },
        },
        ["Tidepool"] = {
            90,
            { FontColor = "e2f1ee", MainColor = "0f1b1c", AccentColor = "5bbfb0", BackgroundColor = "0a1314", OutlineColor = "1d3033", BackgroundImage = "" },
        },
        ["Arctic Night"] = {
            91,
            { FontColor = "eef5ff", MainColor = "0d141f", AccentColor = "9ecbff", BackgroundColor = "080d15", OutlineColor = "1b2738", BackgroundImage = "" },
        },
        ["Navy"] = {
            92,
            { FontColor = "e1e8f5", MainColor = "0a1429", AccentColor = "4a7bd9", BackgroundColor = "060d1d", OutlineColor = "15234a", BackgroundImage = "" },
        },
        ["Cornflower"] = {
            93,
            { FontColor = "e8ecfb", MainColor = "151a2e", AccentColor = "6e8bf0", BackgroundColor = "0f1323", OutlineColor = "262e50", BackgroundImage = "" },
        },
        ["Denim"] = {
            94,
            { FontColor = "dfe7f2", MainColor = "141c28", AccentColor = "5f8ac2", BackgroundColor = "0e141d", OutlineColor = "25303f", BackgroundImage = "" },
        },
        ["Indigo Ink"] = {
            95,
            { FontColor = "e6e6fb", MainColor = "0f0f26", AccentColor = "6366f1", BackgroundColor = "0a0a1b", OutlineColor = "1e1e44", BackgroundImage = "" },
        },
        ["Periwinkle"] = {
            96,
            { FontColor = "eceefc", MainColor = "1b1d33", AccentColor = "9aa5f5", BackgroundColor = "15172a", OutlineColor = "2d3052", BackgroundImage = "" },
        },
        ["Stormy"] = {
            97,
            { FontColor = "dce3ea", MainColor = "1a2028", AccentColor = "7b92ad", BackgroundColor = "14191f", OutlineColor = "2b343f", BackgroundImage = "" },
        },
        ["Steel"] = {
            98,
            { FontColor = "e2e6eb", MainColor = "1b1f25", AccentColor = "8da2bd", BackgroundColor = "15181d", OutlineColor = "2c323b", BackgroundImage = "" },
        },
        ["Grape"] = {
            99,
            { FontColor = "f0e6fa", MainColor = "1a0f26", AccentColor = "a855f7", BackgroundColor = "130a1e", OutlineColor = "2b1a40", BackgroundImage = "" },
        },
        ["Plum"] = {
            100,
            { FontColor = "f3e5f0", MainColor = "1e1019", AccentColor = "9c4a8a", BackgroundColor = "170b14", OutlineColor = "321c2c", BackgroundImage = "" },
        },
        ["Orchid"] = {
            101,
            { FontColor = "f8e8f8", MainColor = "1f1124", AccentColor = "d672e8", BackgroundColor = "180b1c", OutlineColor = "331c3b", BackgroundImage = "" },
        },
        ["Mulberry"] = {
            102,
            { FontColor = "f2e4ee", MainColor = "1c0f1a", AccentColor = "8e3b72", BackgroundColor = "150914", OutlineColor = "301a2b", BackgroundImage = "" },
        },
        ["Wisteria"] = {
            103,
            { FontColor = "efe7fa", MainColor = "1c1728", AccentColor = "b79df0", BackgroundColor = "161220", OutlineColor = "2e2742", BackgroundImage = "" },
        },
        ["Nebula"] = {
            104,
            { FontColor = "ece4fb", MainColor = "120d22", AccentColor = "9b6dff", BackgroundColor = "0c0818", OutlineColor = "261d44", BackgroundImage = "" },
        },
        ["Velvet"] = {
            105,
            { FontColor = "f1e6f5", MainColor = "160c1c", AccentColor = "7e3fa8", BackgroundColor = "100816", OutlineColor = "2a1736", BackgroundImage = "" },
        },
        ["Iris"] = {
            106,
            { FontColor = "e9e8fc", MainColor = "17142b", AccentColor = "7c6cf5", BackgroundColor = "110f22", OutlineColor = "2a2550", BackgroundImage = "" },
        },
        ["Ultraviolet"] = {
            107,
            { FontColor = "f0e4ff", MainColor = "0f0820", AccentColor = "b44cff", BackgroundColor = "0a0516", OutlineColor = "2a1250", BackgroundImage = "" },
        },
        ["Charcoal"] = {
            108,
            { FontColor = "e6e6e6", MainColor = "1f1f1f", AccentColor = "c9b79c", BackgroundColor = "181818", OutlineColor = "2d2d2d", BackgroundImage = "" },
        },
        ["Espresso"] = {
            109,
            { FontColor = "f0e2d6", MainColor = "120d0b", AccentColor = "a8785a", BackgroundColor = "0c0807", OutlineColor = "241a16", BackgroundImage = "" },
        },
        ["Mushroom"] = {
            110,
            { FontColor = "e8e0d8", MainColor = "1f1c1a", AccentColor = "a89886", BackgroundColor = "191716", OutlineColor = "322e2b", BackgroundImage = "" },
        },
        ["Stone"] = {
            111,
            { FontColor = "e5e3df", MainColor = "1d1d1c", AccentColor = "9b9a94", BackgroundColor = "171716", OutlineColor = "2e2e2c", BackgroundImage = "" },
        },
        ["Ash"] = {
            112,
            { FontColor = "e9e9ea", MainColor = "191a1c", AccentColor = "8c9096", BackgroundColor = "121315", OutlineColor = "2a2c2f", BackgroundImage = "" },
        },
        ["Midnight Sepia"] = {
            113,
            { FontColor = "ecdfc8", MainColor = "1a150f", AccentColor = "c9a66b", BackgroundColor = "140f0a", OutlineColor = "2c241a", BackgroundImage = "" },
        },
        ["Noir Red"] = {
            114,
            { FontColor = "f2f2f2", MainColor = "080808", AccentColor = "ff4040", BackgroundColor = "040404", OutlineColor = "151515", BackgroundImage = "" },
        },
        ["Void"] = {
            115,
            { FontColor = "f5f5f5", MainColor = "050505", AccentColor = "ffffff", BackgroundColor = "000000", OutlineColor = "141414", BackgroundImage = "" },
        },
        ["Dusk Rose"] = {
            116,
            { FontColor = "f3e6ec", MainColor = "211820", AccentColor = "d98fb0", BackgroundColor = "1a1219", OutlineColor = "342631", BackgroundImage = "" },
        },
        ["Tangerine"] = {
            117,
            { FontColor = "ffeedd", MainColor = "1d130b", AccentColor = "ff9500", BackgroundColor = "170e07", OutlineColor = "33220f", BackgroundImage = "" },
        },
        ["Lemonade"] = {
            118,
            { FontColor = "fbf8d9", MainColor = "191808", AccentColor = "f7e33f", BackgroundColor = "131206", OutlineColor = "2c2a0f", BackgroundImage = "" },
        },
        ["Pistachio"] = {
            119,
            { FontColor = "eef5da", MainColor = "171b10", AccentColor = "c3dc7a", BackgroundColor = "11150a", OutlineColor = "28301b", BackgroundImage = "" },
        },
        ["Mint Chip"] = {
            120,
            { FontColor = "e3f7ee", MainColor = "121c18", AccentColor = "8fe3be", BackgroundColor = "0c1511", OutlineColor = "22332c", BackgroundImage = "" },
        },
        ["Ocean Mist"] = {
            121,
            { FontColor = "e0eef2", MainColor = "12191d", AccentColor = "8fb8c7", BackgroundColor = "0c1215", OutlineColor = "233039", BackgroundImage = "" },
        },
        ["Blueberry"] = {
            122,
            { FontColor = "e4e8fa", MainColor = "141730", AccentColor = "5b6ee1", BackgroundColor = "0e1024", OutlineColor = "252a58", BackgroundImage = "" },
        },
        ["Lilac Smoke"] = {
            123,
            { FontColor = "ece6f2", MainColor = "1d1a24", AccentColor = "b4a3c9", BackgroundColor = "17141d", OutlineColor = "322d3d", BackgroundImage = "" },
        },
        ["Dragonfruit"] = {
            124,
            { FontColor = "fde6f3", MainColor = "1f0d1a", AccentColor = "e83e8c", BackgroundColor = "180915", OutlineColor = "351a2e", BackgroundImage = "" },
        },
        ["Rust"] = {
            125,
            { FontColor = "f3e3da", MainColor = "1b0f0a", AccentColor = "c1502e", BackgroundColor = "150a06", OutlineColor = "2f1a12", BackgroundImage = "" },
        },
        ["Terracotta"] = {
            126,
            { FontColor = "f5e6dd", MainColor = "1e1311", AccentColor = "d9825b", BackgroundColor = "180d0b", OutlineColor = "33221d", BackgroundImage = "" },
        },
        ["Petrol"] = {
            127,
            { FontColor = "d9ecee", MainColor = "0c1a1f", AccentColor = "2f8f9d", BackgroundColor = "071216", OutlineColor = "163039", BackgroundImage = "" },
        },
        ["Gunmetal"] = {
            128,
            { FontColor = "e6e9ec", MainColor = "1b1f23", AccentColor = "f2a65a", BackgroundColor = "15181c", OutlineColor = "2c3238", BackgroundImage = "" },
        },
    }
}

function ThemeManager:SetLibrary(Library)
    ThemeManager.Library = Library
end

--// Helpers \\--
local function Trim(Text: string)
    return Text:match("^%s*(.-)%s*$")
end

local function IsStringEmpty(String: string): boolean
    return if typeof(String) == "string" then Trim(String) == "" else true
end

local function IsValidFolderPath(Name: string): boolean
    return typeof(Name) == "string" and (
        Trim(Name) ~= "" and 
        not Name:match("^%s*$") and 
        not Name:find('[<>:"|%?%*%z]')
    )
end

--// Contrast helpers \\--
local function LinearizeChannel(Channel: number): number
    if Channel <= SrgbLinearThreshold then
        return Channel / SrgbLinearDivisor
    end

    return ((Channel + SrgbGammaOffset) / SrgbGammaScale) ^ SrgbGammaExponent
end

local function GetRelativeLuminance(Color: Color3): number
    local R = LinearizeChannel(Color.R)
    local G = LinearizeChannel(Color.G)
    local B = LinearizeChannel(Color.B)

    return LuminanceRedWeight * R + LuminanceGreenWeight * G + LuminanceBlueWeight * B
end

local function GetContrastRatio(ColorA: Color3, ColorB: Color3): number
    local LuminanceA = GetRelativeLuminance(ColorA)
    local LuminanceB = GetRelativeLuminance(ColorB)

    local Lighter = math.max(LuminanceA, LuminanceB)
    local Darker = math.min(LuminanceA, LuminanceB)

    return (Lighter + ContrastRatioOffset) / (Darker + ContrastRatioOffset)
end

local function IsValidThemeData(Data: any): boolean
    if typeof(Data) ~= "table" then
        return false
    end

    --// Require the color scheme to be present; font/background image are optional and fall back to current values
    for _, SchemeIndex in SchemeIndexes do
        if typeof(Data[SchemeIndex]) ~= "string" then
            return false
        end
    end

    return true
end

--// Folder helper \\--
local function SplitPath(Path: string): {string}
	local Result = {}
	local Current = ""

	for Part in string.gmatch(Path, "[^/]+") do
		Current = if Current == "" then Part else (Current .. "/" .. Part)
		table.insert(Result, Current)
	end

	return Result
end

local function GetFolderPath(): false | string
    if IsStringEmpty(ThemeManager.Folder) then
        return false
    end

    return string.format("%s/themes", ThemeManager.Folder)
end

local GetCurrentThemesPath = GetFolderPath

--// Files helper \\--
local function GetThemePath(ThemeName: string): false | string
    local CurrentThemesPath = GetCurrentThemesPath()
    return if CurrentThemesPath == false then false else string.format("%s/%s.json", CurrentThemesPath, ThemeName)
end

local function DoesThemeExist(ThemeName: string, IncludeBuiltIn: boolean): boolean
    if ThemeManager.BuiltInThemes[ThemeName] then
        return true
    end

    local ThemePath = GetThemePath(ThemeName)
    return if ThemePath == false then false else isfile(ThemePath)
end

local function GetDefaultThemePath(): false | string
    local CurrentThemesPath = GetCurrentThemesPath()
    return if CurrentThemesPath == false then false else string.format("%s/default.txt", CurrentThemesPath)
end

--// Folders \\--
function ThemeManager:GetPaths(): {string}
    local FolderPath = GetFolderPath()
    return if FolderPath == false then {} else SplitPath(FolderPath)
end

function ThemeManager:BuildFolderTree(SkipWhenCreated: boolean?)
    local Paths = ThemeManager:GetPaths()
    if #Paths == 0 then
        return false
    end

    if SkipWhenCreated == true then
        if isfolder(Paths[1]) then
            return true
        end
    end

    for _, Path in Paths do
        if isfolder(Path) then continue end
        
        makefolder(Path)
    end

    return true
end

function ThemeManager:CheckFolderTree()
    return ThemeManager:BuildFolderTree(true)
end

function ThemeManager:SetFolder(Folder: string)
    assert(IsValidFolderPath(Folder), "Invalid path provided")

    ThemeManager.Folder = Folder
    ThemeManager:BuildFolderTree()
end

--// Theme Management \\--
function ThemeManager:ReloadCustomThemes()
    local SettingsPath = GetCurrentThemesPath()
    if SettingsPath == false then
        return {}
    end

    pcall(makefolder, SettingsPath)
    local SuccessList, Files = pcall(listfiles, SettingsPath)
    if not (SuccessList and typeof(Files) == "table") then
        ThemeManager.Library:Notify(string.format("Failed to load theme list: %s", tostring(Files)))
        return {}
    end

    local FileNames = {}
    for _, FilePath in Files do
        local RawFileName = FilePath:match("(.+)%..+$")
        if not RawFileName then continue end

        local Position = RawFileName:gsub("\\", "/"):find("/[^/]*$")
        local FileName = Position and RawFileName:sub(Position + 1) or RawFileName
        if not FileName or FileName == "default" then continue end

        table.insert(FileNames, FileName)
    end

    return FileNames
end

function ThemeManager:GetCustomTheme(ThemeName: string): any
    if IsStringEmpty(ThemeName) then
        return nil
    end

    local ThemePath = GetThemePath(ThemeName)
    if ThemePath == false or not isfile(ThemePath) then
        return nil
    end

    local SuccessRead, Content = pcall(readfile, ThemePath)
    if not SuccessRead then
        return nil
    end

    local SuccessDecode, Decoded = pcall(HttpService.JSONDecode, HttpService, Content)
    if not SuccessDecode or typeof(Decoded) ~= "table" then
        return nil
    end

    return Decoded
end

local function BuildCurrentThemeData(): {[string]: any}
    local Library = ThemeManager.Library
    local ThemeData = {
        FontFace = Library.Options.FontFace.Value,
        BackgroundImage = Library.Options.BackgroundImage.Value
    }

    for _, SchemeIndex in SchemeIndexes do
        ThemeData[SchemeIndex] = Library.Options[SchemeIndex].Value:ToHex()
    end

    return ThemeData
end

function ThemeManager:SaveCustomTheme(ThemeName: string): any
    if IsStringEmpty(ThemeName) then
        return false, "Invalid theme name provided"
    end

    if string.lower(ThemeName) == "default" then
        return false, "Invalid theme name provided"
    end

    local ThemePath = GetThemePath(ThemeName)
    if ThemePath == false then
        return false, "Invalid theme name provided"
    end

    ThemeManager:CheckFolderTree()

    --// Custom theme files use the same flat shape as an exported theme JSON, so reuse the encoder
    local EncodedData, SuccessEncode, EncodeErrorMessage = ThemeManager:SaveJSON()
    if not SuccessEncode then
        return false, EncodeErrorMessage
    end

    local SuccessWrite, ErrorMessage = pcall(writefile, ThemePath, EncodedData)
    if not SuccessWrite then
        return false, "Failed to write theme file: " .. tostring(ErrorMessage)
    end

    return true
end

function ThemeManager:Delete(ThemeName: string): (boolean | string?)
    if IsStringEmpty(ThemeName) then
        return false, "No theme is selected"
    end

    local ThemePath = GetThemePath(ThemeName)
    if ThemePath == false or not isfile(ThemePath) then
        return false, "Theme file does not exist"
    end

    local SuccessDelete, ErrorMessage = pcall(delfile, ThemePath)
    if not SuccessDelete then
        return false, "Failed to delete theme file: " .. tostring(ErrorMessage)
    end

    if ThemeName == ThemeManager.DefaultThemeName then
        ThemeManager:DeleteDefaultTheme()
    end

    return true
end

--// Default Theme \\--
function ThemeManager:GetDefaultTheme(): (string, boolean, string?)
    ThemeManager:CheckFolderTree()

    local DefaultThemePath = GetDefaultThemePath()
    if DefaultThemePath == false then
        return "none", false, "Invalid path provided"
    end

    if not isfile(DefaultThemePath) then
        return "none", false, "Default theme is not set"
    end

    local SuccessRead, DefaultThemeName = pcall(readfile, DefaultThemePath)
    if not (SuccessRead and typeof(DefaultThemeName) == "string") then
        return "none", false, DefaultThemeName
    end

    local ConfigExists = DoesThemeExist(DefaultThemeName, true)
    if not ConfigExists then
        return "none", false, "Theme file not found"
    end

    ThemeManager.DefaultThemeName = DefaultThemeName
    return DefaultThemeName, true
end

function ThemeManager:SetDefaultTheme(Theme: any)
    assert(ThemeManager.Library, "Library is not set, call ThemeManager:SetLibrary(Library) first.")
    assert(not ThemeManager.AppliedToTab, "Cannot set default theme after applying ThemeManager to a tab!")

    local Library = ThemeManager.Library
    local DefaultThemeData = ThemeManager.BuiltInThemes["Marden"][2]

    local LibraryScheme = {}
    local FinalTheme = {}

    for _, SchemeIndex in SchemeIndexes do
        local IndexData = Theme[SchemeIndex]
        local IndexType = typeof(IndexData)
        
        if IndexType == "Color3" then
            LibraryScheme[SchemeIndex] = IndexData
            FinalTheme[SchemeIndex] = string.format("#%s", IndexData:ToHex())

        elseif IndexType == "string" then
            LibraryScheme[SchemeIndex] = Color3.fromHex(IndexData)
            FinalTheme[SchemeIndex] = if IndexData:sub(1, 1) == "#" then IndexData else string.format("#%s", IndexData)
        
        else
            local Value = DefaultThemeData[SchemeIndex]
            LibraryScheme[SchemeIndex] = Color3.fromHex(Value)
            FinalTheme[SchemeIndex] = Value
        end
    end

    --// Font
    local FontFace = Theme["FontFace"]
    local FontFaceType = typeof(FontFace)
    
    if FontFaceType == "EnumItem" then
        LibraryScheme.Font = Font.fromEnum(FontFace)
        FinalTheme.FontFace = FontFace.Name

    elseif FontFaceType == "string" then
        LibraryScheme.Font = Font.fromEnum(Enum.Font[FontFace] :: Enum.Font)
        FinalTheme.FontFace = FontFace
    
    else
        LibraryScheme.Font = Font.fromEnum(Enum.Font.Code)
        FinalTheme.FontFace = "Code"
    end

    --// Default Scheme Colors
    for _, DefaultSchemeColor in { "RedColor", "DestructiveColor", "DarkColor", "WhiteColor" } do
        LibraryScheme[DefaultSchemeColor] = Library.Scheme[DefaultSchemeColor]
    end

    --// Apply
    Library.Scheme = LibraryScheme
    ThemeManager.BuiltInThemes["Marden"] = { 1, FinalTheme }

    Library:UpdateColorsUsingRegistry()
end

function ThemeManager:SaveDefault(ThemeName: string): (boolean, string?)
    if IsStringEmpty(ThemeName) then
        return false, "No theme is selected"
    end

    ThemeManager:CheckFolderTree()

    local DefaultThemePath = GetDefaultThemePath()
    if DefaultThemePath == false then
        return false, "Invalid path provided"
    end

    if not DoesThemeExist(ThemeName, true) then
        return false, "Theme does not exist"
    end

    local SuccessWrite, ErrorMessage = pcall(writefile, DefaultThemePath, ThemeName)
    if not SuccessWrite then
        return false, ErrorMessage
    end

    ThemeManager.DefaultThemeName = ThemeName
    return true
end

function ThemeManager:LoadDefault()
    local ThemeName, Success, FetchErrorMessage = ThemeManager:GetDefaultTheme()
    if not Success or FetchErrorMessage then
        if FetchErrorMessage ~= "Default theme is not set" then
            ThemeManager.Library:Notify(string.format("Failed to apply default theme: %s", FetchErrorMessage))
        end

        return
    end

    if not ThemeManager:GetCustomTheme(ThemeName) then
        ThemeManager.Library.Options.ThemeManager_ThemeList:SetValue(ThemeName)
        return
    end

    local SuccessLoad, LoadErrorMessage = ThemeManager:ApplyTheme(ThemeName)
    if not SuccessLoad then
        ThemeManager.Library:Notify(string.format("Failed to apply default theme: %s", LoadErrorMessage))
        return
    end

    ThemeManager.Library:Notify(string.format("Successfully applied default theme %q", ThemeName))
end

function ThemeManager:DeleteDefaultTheme(): (boolean, string?)
    ThemeManager:CheckFolderTree()

    local DefaultThemePath = GetDefaultThemePath()
    if DefaultThemePath == false then
        return false, "Invalid path provided"
    end

    if not isfile(DefaultThemePath) then
        return false, "Default theme is not set"
    end

    local SuccessDelete, ErrorMessage = pcall(delfile, DefaultThemePath)
    if not SuccessDelete then
        return false, ErrorMessage
    end

    ThemeManager.DefaultThemeName = nil
    return true
end

--// Accessibility: contrast checking \\--
function ThemeManager:GetContrastReport(): { Ratio: number, PairName: string, Passes: boolean }
    local Library = ThemeManager.Library
    local FontColorOption = Library.Options.FontColor
    local BackgroundColorOption = Library.Options.BackgroundColor
    local MainColorOption = Library.Options.MainColor

    if not (FontColorOption and BackgroundColorOption and MainColorOption) then
        return { Ratio = math.huge, PairName = "", Passes = true }
    end

    local FontColor = FontColorOption.Value
    local Surfaces = {
        { Name = "font color vs. background color", Color = BackgroundColorOption.Value },
        { Name = "font color vs. main color", Color = MainColorOption.Value },
    }

    local WorstRatio, WorstName = math.huge, ""
    for _, Surface in Surfaces do
        local Ratio = GetContrastRatio(FontColor, Surface.Color)
        if Ratio < WorstRatio then
            WorstRatio = Ratio
            WorstName = Surface.Name
        end
    end

    return {
        Ratio = WorstRatio,
        PairName = WorstName,
        Passes = WorstRatio >= ContrastWarnThreshold,
    }
end

function ThemeManager:UpdateContrastWarning()
    local ContrastLabel = ThemeManager.ContrastLabel
    if not ContrastLabel or ContrastLabel.Destroyed then
        return
    end

    local Library = ThemeManager.Library
    local Report = ThemeManager:GetContrastReport()
    local TextLabel = ContrastLabel.TextLabel

    if not Library.Registry[TextLabel] then
        Library:AddToRegistry(TextLabel, {})
    end

    if Report.Passes then
        ContrastLabel:SetText(string.format("Contrast check: good (%.1f:1)", Report.Ratio))

        TextLabel.TextColor3 = Library.Scheme.FontColor
        Library.Registry[TextLabel].TextColor3 = "FontColor"
    else
        ContrastLabel:SetText(string.format(
            "Low contrast (%.1f:1) between %s. Aim for at least %.1f:1 so text stays readable.",
            Report.Ratio, Report.PairName, ContrastWarnThreshold
        ))

        TextLabel.TextColor3 = Library.Scheme.RedColor
        Library.Registry[TextLabel].TextColor3 = "RedColor"

        if not ThemeManager.ContrastWasPoor then
            Library:Notify({
                Title = "Low contrast theme",
                Description = string.format(
                    "Your %s has a contrast ratio of %.1f:1, below the recommended %.1f:1. Text may be hard to read.",
                    Report.PairName, Report.Ratio, ContrastWarnThreshold
                ),
                Time = 10,
            })
        end
    end

    ThemeManager.ContrastWasPoor = not Report.Passes
end

--// Apply Theme \\--
function ThemeManager:ThemeUpdate()
    local Library = ThemeManager.Library

    for _, SchemeIndex in SchemeIndexes do
        local Element = Library.Options[SchemeIndex]
        if not Element then continue end

        Library.Scheme[SchemeIndex] = Element.Value
    end

    Library:UpdateColorsUsingRegistry()
    ThemeManager:UpdateContrastWarning()
end

--// Applies a flat theme data table (either a parsed theme file or an imported JSON blob) to the library.
--// Split out of ApplyTheme so imported JSON can go through the same path as themes loaded from disk.
function ThemeManager:ApplyThemeData(ThemeData: any): (boolean, string?)
    if typeof(ThemeData) ~= "table" then
        return false, "Invalid theme data"
    end

    local Library = ThemeManager.Library

    for Index, Value in ThemeData do
        if Index == "VideoLink" then
            continue
        end

        local Element = Library.Options[Index]
        local FinalValue = Value

        if Index == "FontFace" then
            if typeof(Value) ~= "string" or not Enum.Font[Value] then continue end
            ThemeManager.Library:SetFont(Enum.Font[Value])

        elseif Index == "BackgroundImage" then
            if typeof(Value) ~= "string" then continue end
            ThemeManager.Library:SetBackgroundImage(Value)

        elseif table.find(SchemeIndexes, Index) then
            local SuccessColor, Color = pcall(Color3.fromHex, Value)
            if not SuccessColor then continue end

            FinalValue = Color
            Library.Scheme[Index] = FinalValue

        else
            continue --// Unrecognized field, ignore it
        end

        if Element then
            Element:SetValue(FinalValue)
        end
    end

    ThemeManager:ThemeUpdate()
    return true
end

function ThemeManager:ApplyTheme(ThemeName: string)
    if IsStringEmpty(ThemeName) then
        return false, "No theme is selected"
    end

    local CustomThemeData = ThemeManager:GetCustomTheme(ThemeName)
    local Data = CustomThemeData or ThemeManager.BuiltInThemes[ThemeName]
    
    if not Data then
        return false, "Theme not found"
    end
    
    local ThemeData = CustomThemeData or Data[2]
    return ThemeManager:ApplyThemeData(ThemeData)
end

--// JSON Import & Export \\--
function ThemeManager:SaveJSON(): (string, boolean, string?)
    local ThemeData = BuildCurrentThemeData()

    local SuccessEncode, EncodedData = pcall(HttpService.JSONEncode, HttpService, ThemeData)
    if not SuccessEncode then
        return "", false, "Failed to encode data"
    end

    return EncodedData, true
end

function ThemeManager:LoadJSON(Content: string): (boolean, string?)
    if IsStringEmpty(Content) then
        return false, "No JSON provided"
    end

    local SuccessDecode, Decoded = pcall(HttpService.JSONDecode, HttpService, Content)
    if not SuccessDecode or not IsValidThemeData(Decoded) then
        return false, "Failed to decode theme data"
    end

    return ThemeManager:ApplyThemeData(Decoded)
end

--// GUI \\--
local function ShowDialog(
    Condition: () -> boolean,

    Index: string, 
    Title: string, 
    Description: string,

    DestructiveText: string,
    DestructiveAction: () -> nil
)
    if Condition() == false then
        return DestructiveAction()
    end

    return ThemeManager.Library.Window:AddDialog(Index, {
        Title = Title,
        Description = Description,
        AutoDismiss = false,

        FooterButtons = {
            Cancel = {
                Title = "Cancel",
                Variant = "Ghost",
                Order = 1,
                Callback = function(Dialog)
                    Dialog:Dismiss()
                end
            },

            DestructiveAction = {
                Title = DestructiveText,
                Variant = "Destructive",
                Order = 2,
                Callback = function(Dialog)
                    Dialog:Dismiss()
                    DestructiveAction()
                end
            }
        }
    })
end

function ThemeManager:CreateThemeManager(Themesbox: any)
    assert(ThemeManager.Library, "Library is not set, call ThemeManager:SetLibrary(Library) first.")

    local BuiltInThemesNames = {}
    for Name, _ThemeData in ThemeManager.BuiltInThemes do
        table.insert(BuiltInThemesNames, Name)
    end

    local CustomThemeList, CustomThemeName, ThemeList, FontFace, BackgroundImage, DefaultThemeLabel, ThemeJSONInput
    local function RefreshList()
        CustomThemeList:SetValues(ThemeManager:ReloadCustomThemes())
        CustomThemeList:SetValue(nil)

        ThemeList:SetValues(BuiltInThemesNames)
    end

    local function RefreshDefaultThemeLabel()
        local DefaultThemeName, _Success, _ErrorMessage = ThemeManager:GetDefaultTheme()

        DefaultThemeLabel:SetText(string.format("Current default theme: %s", DefaultThemeName))
        if CustomThemeList then RefreshList() end
    end

    table.sort(BuiltInThemesNames, function(IndexA, IndexB)
        return ThemeManager.BuiltInThemes[IndexA][1] < ThemeManager.BuiltInThemes[IndexB][1]
    end)

    local function CreateColorOption(Text, SchemeIndex)
        Themesbox:AddLabel(Text):AddColorPicker(SchemeIndex, {
            Default = ThemeManager.Library.Scheme[SchemeIndex]
        })

        return ThemeManager.Library.Options[SchemeIndex]
    end

    local BackgroundColor = CreateColorOption("Background color", "BackgroundColor")
    local MainColor = CreateColorOption("Main color", "MainColor")
    local AccentColor = CreateColorOption("Accent color", "AccentColor")
    local OutlineColor = CreateColorOption("Outline color", "OutlineColor")
    local FontColor = CreateColorOption("Font color", "FontColor")

    --// Accessibility: live contrast readout for the colors above
    ThemeManager.ContrastLabel = Themesbox:AddLabel({
        Text = "Contrast check: n/a",
        DoesWrap = true,
    })

    Themesbox:AddDropdown("FontFace", {
        Text = "Font Face",
        Default = "Code",
        
        Values = { "BuilderSans", "Code", "Fantasy", "Gotham", "Jura", "Roboto", "RobotoMono", "SourceSans" },
        AllowNull = false,
        Multi = false
    })
    
    Themesbox:AddInput("BackgroundImage", { 
        Text = "Background Image",

        Default = "",
        Finished = true,
        ClearTextOnFocus = false,
        ClearTextOnBlur = false
    })

    Themesbox:AddDivider()

    Themesbox:AddDropdown("ThemeManager_ThemeList", { 
        Text = "Theme list", 

        Values = BuiltInThemesNames,
        AllowNull = true,
        Multi = false,

        FormatDisplayValue = function(Value: any)
            if Value ~= "Marden" and Value == ThemeManager.DefaultThemeName then
                return string.format("%s (default)", Value)
            end

            return Value
        end,
        FormatListValue = function(Value: any)
            if Value ~= "Marden" and Value == ThemeManager.DefaultThemeName then
                return string.format("%s (default)", Value)
            end

            return Value
        end
    })

    Themesbox:AddButton("Set as default", function()
        local ThemeName = ThemeList.Value
        ThemeManager:SaveDefault(ThemeName)

        ThemeManager.Library:Notify(string.format("Successfully set default theme to %q", ThemeName))
        RefreshDefaultThemeLabel()
    end)

    Themesbox:AddDivider()

    CustomThemeName = Themesbox:AddInput("ThemeManager_CustomThemeName", { 
        Text = "Custom theme name" 
    })

    local function SaveThemeWithContrastCheck(Name: string, SuccessMessage: string, OnSaved: (() -> nil)?)
        local function DoSave()
            local Success, ErrorMessage = ThemeManager:SaveCustomTheme(Name)
            if not Success then
                ThemeManager.Library:Notify(string.format("Failed to save theme %q: %s", Name, ErrorMessage))
                return
            end

            ThemeManager.Library:Notify(string.format(SuccessMessage, Name))
            if OnSaved then OnSaved() end
        end

        local Report = ThemeManager:GetContrastReport()
        if Report.Passes then
            DoSave()
            return
        end

        ShowDialog(
            function(): boolean
                return true
            end,

            "ThemeManager_LowContrastSave",
            "Low contrast theme",
            string.format(
                "This theme has a contrast ratio of %.1f:1 between %s, below the recommended %.1f:1. Text may be hard to read. Save anyway?",
                Report.Ratio, Report.PairName, ContrastWarnThreshold
            ),

            "Save Anyway",
            DoSave
        )
    end

    Themesbox:AddButton("Create theme", function()
        local Name = CustomThemeName.Value
        if IsStringEmpty(Name) then
            ThemeManager.Library:Notify("Theme name cannot be empty.")
            return
        end

        if string.lower(Name) == "default" then
            ThemeManager.Library:Notify("Invalid theme name provided.")
            return
        end

        ShowDialog(
            function(): boolean
                return ThemeManager:GetCustomTheme(Name) ~= nil
            end,

            "ThemeManager_CreateTheme",
            "Theme already exists",
            string.format("A custom theme named %q already exists. Overwriting it will replace it with your current colors.", Name),

            "Overwrite",
            function()
                SaveThemeWithContrastCheck(Name, "Successfully created theme %q", RefreshList)
            end
        )
    end)

    Themesbox:AddDivider()

    CustomThemeList = Themesbox:AddDropdown("ThemeManager_CustomThemeList", { 
        Text = "Custom themes",

        Values = ThemeManager:ReloadCustomThemes(), 
        AllowNull = true,
        Multi = false,

        FormatDisplayValue = function(Value: any)
            if Value == ThemeManager.DefaultThemeName then
                return string.format("%s (default)", Value)
            end

            return Value
        end,
        FormatListValue = function(Value: any)
            if Value == ThemeManager.DefaultThemeName then
                return string.format("%s (default)", Value)
            end

            return Value
        end
    })

    Themesbox:AddButton("Load theme", function()
        local Name = CustomThemeList.Value
        if IsStringEmpty(Name) then
            ThemeManager.Library:Notify("Please select a theme first.")
            return
        end

        ThemeManager:ApplyTheme(Name)
        ThemeManager.Library:Notify(string.format("Successfully loaded theme %q", Name))
    end)

    Themesbox:AddButton("Overwrite theme", function()
        local Name = CustomThemeList.Value
        if IsStringEmpty(Name) then
            ThemeManager.Library:Notify("Please select a theme first.")
            return
        end

        ShowDialog(
            function(): boolean
                return true
            end,

            "ThemeManager_OverwriteTheme",
            "Overwrite theme",
            string.format("Are you sure you want to overwrite %q with your current colors?", Name),

            "Overwrite",
            function()
                SaveThemeWithContrastCheck(Name, "Successfully overwrote theme %q")
            end
        )
    end)

    Themesbox:AddButton("Delete theme", function()
        local Name = CustomThemeList.Value
        if IsStringEmpty(Name) then
            ThemeManager.Library:Notify("Please select a theme first.")
            return
        end

        ShowDialog(
            function(): boolean
                return true
            end,

            "ThemeManager_DeleteTheme",
            "Delete theme",
            string.format("Are you sure you want to delete %q? This cannot be undone.", Name),
            
            "Delete",
            function()
                local Success, ErrorMessage = ThemeManager:Delete(Name)
                if not Success then
                    ThemeManager.Library:Notify(string.format("Failed to delete theme: %s", ErrorMessage))
                    return
                end

                ThemeManager.Library:Notify(string.format("Successfully deleted theme %q", Name))
                RefreshDefaultThemeLabel()
            end
        )
    end)

    Themesbox:AddButton("Refresh list", RefreshList)

    Themesbox:AddButton("Set as default", function()
        local Name = CustomThemeList.Value
        if IsStringEmpty(Name) then
            ThemeManager.Library:Notify("Please select a theme first.")
            return
        end

        ThemeManager:SaveDefault(Name)
        ThemeManager.Library:Notify(string.format("Successfully set default theme to %q", Name))
        RefreshDefaultThemeLabel()
    end)

    Themesbox:AddButton("Reset default", function()
        ShowDialog(
            function(): boolean
                return true
            end,

            "ThemeManager_ResetDefault",
            "Reset default theme",
            "Are you sure you want to clear the default theme? The library will revert to its built-in default on next load.",
            
            "Reset",
            function()
                local Success, ErrorMessage = ThemeManager:DeleteDefaultTheme()
                if not Success then
                    ThemeManager.Library:Notify(string.format("Failed to reset default theme: %s", ErrorMessage))
                    return
                end

                ThemeManager.Library:Notify("Successfully reset default theme.")
                RefreshDefaultThemeLabel()
            end
        )
    end)

    DefaultThemeLabel = Themesbox:AddLabel("Current default theme: ...", true);

    Themesbox:AddDivider()

    --// Import & Export
    Themesbox:AddInput("ThemeManager_ThemeJSON", {
        Text = "Theme JSON"
    })

    Themesbox:AddButton("Import theme", function()
        local ThemeJSON = ThemeJSONInput.Value
        if IsStringEmpty(ThemeJSON) then
            ThemeManager.Library:Notify("Theme JSON cannot be empty")
            return
        end

        ShowDialog(
            function(): boolean
                return true
            end,

            "ThemeManager_ImportTheme",
            "Import theme",
            "Are you sure you want to import this theme? Your current colors will be overwritten.",

            "Import",
            function()
                local Success, ErrorMessage = ThemeManager:LoadJSON(ThemeJSON)
                if not Success then
                    ThemeManager.Library:Notify(string.format("Failed to import theme: %s", ErrorMessage))
                    return
                end

                ThemeManager.Library:Notify("Successfully imported theme")
            end
        )
    end)

    Themesbox:AddButton("Export current theme", function()
        local EncodedData, Success, ErrorMessage = ThemeManager:SaveJSON()
        if not Success then
            ThemeManager.Library:Notify(ErrorMessage)
            return
        end

        ThemeJSONInput:SetValue(EncodedData)
        if setclipboard then
            setclipboard(EncodedData)
            ThemeManager.Library:Notify("Copied theme to the clipboard")
        end
    end)

    --// Set Variables
    CustomThemeList, CustomThemeName, ThemeList, FontFace, BackgroundImage, ThemeJSONInput =
        ThemeManager.Library.Options.ThemeManager_CustomThemeList,
        ThemeManager.Library.Options.ThemeManager_CustomThemeName,
        ThemeManager.Library.Options.ThemeManager_ThemeList,
        ThemeManager.Library.Options.FontFace,
        ThemeManager.Library.Options.BackgroundImage,
        ThemeManager.Library.Options.ThemeManager_ThemeJSON;

    --// Handlers
    ThemeList:OnChanged(function()
        ThemeManager:ApplyTheme(ThemeList.Value)
    end)

    local function UpdateTheme()
        ThemeManager:ThemeUpdate()
    end

    BackgroundColor:OnChanged(UpdateTheme)
    MainColor:OnChanged(UpdateTheme)
    AccentColor:OnChanged(UpdateTheme)
    OutlineColor:OnChanged(UpdateTheme)
    FontColor:OnChanged(UpdateTheme)
    FontFace:OnChanged(function(Value) ThemeManager.Library:SetFont(Enum.Font[Value]) end)
    BackgroundImage:OnChanged(function(Value) ThemeManager.Library:SetBackgroundImage(Value) end)

    --// Load default
    ThemeManager:LoadDefault()
    ThemeManager:UpdateContrastWarning()
    ThemeManager.AppliedToTab = true
    RefreshDefaultThemeLabel()

    if ThemeManager.DefaultThemeName == nil then
        ThemeList:SetValue("Marden")
    end

    return Themesbox
end

function ThemeManager:CreateGroupBox(Tab: any, IconName: string)
    return Tab:AddGroupbox({
        Side = "Left",
        Name = "General Themes",
        IconName = IconName or "paintbrush",
    })
end

function ThemeManager:ApplyToTab(Tab: any, IconName: string)
    local Groupbox = ThemeManager:CreateGroupBox(Tab, IconName)
    return ThemeManager:CreateThemeManager(Groupbox)
end

function ThemeManager:ApplyToGroupbox(Groupbox: any)
    return ThemeManager:CreateThemeManager(Groupbox)
end

getgenv().ObsidianThemeManager = ThemeManager
return ThemeManager
