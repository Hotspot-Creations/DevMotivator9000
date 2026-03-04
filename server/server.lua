local function pickRandom(t)
    return t[math.random(1, #t)]
end

CreateThread(function()
    math.randomseed(os.time())

    local quote = pickRandom(Config.Quotes)

    print("^5[Motivation]^7 Your Server has started!")
    print("^5[Motivation]^7 " .. quote)
end)