CreateThread(function()
    Wait(2500)
    math.randomseed(os.time())

    local function roll(percent)
        return math.random(1, 100) <= percent
    end

    local function pickRandom(t)
        if not t or #t == 0 then return nil end
        return t[math.random(1, #t)]
    end

    local function getMotivationQuote()
        local quotes = Config.Quotes
        local chances = Config.QuoteChances

        local roll = math.random(1, 100)
        local category = "wholesome"  -- default

        local cumulative = 0

        cumulative = cumulative + (chances.legendary or 1)
        if roll <= cumulative then
            category = "legendary"
        elseif roll <= cumulative + (chances.ultraChaos or 4) then
            category = "ultraChaos"
        elseif roll <= cumulative + (chances.chaos or 15) then
            category = "chaos"
        elseif roll <= cumulative + (chances.balanced or 30) then
            category = "balanced"
        end

        return pickRandom(quotes[category] or {})
    end

    local quote = getMotivationQuote()

    if quote then
        print("^5[Motivation?]^7 " .. quote)
    end
end)