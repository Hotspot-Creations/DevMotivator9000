--====================================================
-- RESOURCE STATS
--====================================================

local function getResourceStats()
    local total = GetNumResources()
    local started = 0
    local stopped = 0

    for i = 0, total - 1 do
        local res = GetResourceByFindIndex(i)
        local state = GetResourceState(res)

        if state == "started" then
            started = started + 1
        else
            stopped = stopped + 1
        end
    end

    return total, started, stopped
end

--====================================================
-- CLIENT / SERVER RATIO
--====================================================

local function getClientServerRatio()
    local clientCount = 0
    local serverCount = 0

    local total = GetNumResources()

    for i = 0, total - 1 do
        local res = GetResourceByFindIndex(i)

        local numClient = GetNumResourceMetadata(res, "client_script") or 0
        local numServer = GetNumResourceMetadata(res, "server_script") or 0

        clientCount = clientCount + numClient
        serverCount = serverCount + numServer
    end

    return clientCount, serverCount
end

--====================================================
-- SECURITY FLAGS
--====================================================

local function getSecurityFlags()
    local scriptHook = GetConvar("sv_scriptHookAllowed", "false")
    local onesync = GetConvar("onesync", "off")

    return scriptHook, onesync
end

--====================================================
-- FRAMEWORK DETECTION
--====================================================

local function analyzeQBCore()
    if GetResourceState("qb-core") ~= "started" then return nil end

    local QBCore = exports["qb-core"]:GetCoreObject()

    local itemCount = 0
    for _ in pairs(QBCore.Shared.Items or {}) do
        itemCount = itemCount + 1
    end

    local jobCount = 0
    for _ in pairs(QBCore.Shared.Jobs or {}) do
        jobCount = jobCount + 1
    end

    local maxPlayers = tonumber(GetConvar("sv_maxclients", "32"))
    local density = 0

    if maxPlayers > 0 then
        density = math.floor(itemCount / maxPlayers)
    end

    return {
        name = "QBCore",
        items = itemCount,
        jobs = jobCount,
        density = density
    }
end

local function analyzeESX()
    if GetResourceState("es_extended") ~= "started" then return nil end

    local ESX = exports["es_extended"]:getSharedObject()

    local jobCount = 0
    for _ in pairs(ESX.GetJobs() or {}) do
        jobCount = jobCount + 1
    end

    local itemCount = 0
    for _ in pairs(ESX.GetItems() or {}) do
        itemCount = itemCount + 1
    end

    return {
        name = "ESX",
        items = itemCount,
        jobs = jobCount
    }
end

--====================================================
-- DEPENDENCY COMPLEXITY
--====================================================

local function buildDependencyGraph()
    local graph = {}
    local total = GetNumResources()

    for i = 0, total - 1 do
        local res = GetResourceByFindIndex(i)
        graph[res] = {}

        local depCount = GetNumResourceMetadata(res, "dependency") or 0

        for j = 0, depCount - 1 do
            local dep = GetResourceMetadata(res, "dependency", j)
            table.insert(graph[res], dep)
        end
    end

    return graph
end

local function calculateDepth(graph, node, visited)
    visited = visited or {}

    if visited[node] then return 0 end
    visited[node] = true

    local maxDepth = 0

    for _, dep in ipairs(graph[node] or {}) do
        local depth = calculateDepth(graph, dep, visited)
        if depth > maxDepth then
            maxDepth = depth
        end
    end

    visited[node] = nil

    return maxDepth + 1
end

local function analyzeDependencies()
    local graph = buildDependencyGraph()

    local maxDepth = 0
    local totalLinks = 0

    for res, deps in pairs(graph) do
        totalLinks = totalLinks + #deps
        local depth = calculateDepth(graph, res)
        if depth > maxDepth then
            maxDepth = depth
        end
    end

    local complexity = math.min(10, (maxDepth * 1.5) + (totalLinks / 25))

    return {
        depth = maxDepth,
        links = totalLinks,
        score = tonumber(string.format("%.1f", complexity))
    }
end

--====================================================
-- BLOAT DETECTOR
--====================================================

local function analyzeBloat()
    local suspicious = 0
    local total = GetNumResources()

    for i = 0, total - 1 do
        local res = string.lower(GetResourceByFindIndex(i))

        if string.find(res, "old")
        or string.find(res, "backup")
        or string.find(res, "test")
        or string.find(res, "final")
        or string.find(res, "v2")
        or string.find(res, "copy")
        then
            suspicious = suspicious + 1
        end
    end

    return suspicious
end

--====================================================
-- HEALTH SCORE
--====================================================

local function calculateHealthScore(resourceTotal, stopped, clientRatio, scriptHook, depScore, bloatCount)
    local score = 100

    if resourceTotal > 200 then score = score - 10 end
    if stopped > 0 then score = score - 10 end
    if clientRatio > 0.75 then score = score - 15 end
    if scriptHook == "true" then score = score - 20 end
    if depScore > 7 then score = score - 15 end
    if bloatCount > 5 then score = score - 10 end

    return math.max(0, math.floor(score))
end

--====================================================
-- MAIN BOOT THREAD
--====================================================

CreateThread(function()
    math.randomseed(os.time())
    Wait(2000)

    local total, started, stopped = getResourceStats()
    local clientCount, serverCount = getClientServerRatio()
    local scriptHook, onesync = getSecurityFlags()
    local dep = analyzeDependencies()
    local bloat = analyzeBloat()

    local ratio = 0
    if (clientCount + serverCount) > 0 then
        ratio = clientCount / (clientCount + serverCount)
    end

    local health = calculateHealthScore(total, stopped, ratio, scriptHook, dep.score, bloat)

    print("^5[DevMotivator9000]^7 Boot Analysis Complete")
    print("^5[DevMotivator9000]^7 Resources: " .. started .. "/" .. total .. " started")

    if stopped > 0 then
        print("^1[DevMotivator9000]^7 " .. stopped .. " resources are not started. We do not speak of them.")
    end

    -- BLOAT
    if bloat > 0 then
        print("^3[DevMotivator9000]^7 Suspiciously Named Resources: " .. bloat)
        print("^3[DevMotivator9000]^7 Fear-driven development detected.")
    end

    -- CLIENT TRUST
    if ratio > 0.75 then
        print("^3[DevMotivator9000]^7 Client Trust Ratio: " .. math.floor(ratio * 100) .. "%")
        print("^3[DevMotivator9000]^7 Conclusion: You trust the client. Bold.")
    end

    -- DEPENDENCIES
    print("^5[DevMotivator9000]^7 Dependency Complexity Score: " .. dep.score .. " / 10")
    print("^5[DevMotivator9000]^7 Longest Chain: " .. dep.depth .. " resources deep")

    if dep.score > 7 then
        print("^3[DevMotivator9000]^7 This may explain the random restart ritual.")
    end

    -- SECURITY
    print("^5[DevMotivator9000]^7 Security Configuration Review:")
    print("^5[DevMotivator9000]^7 sv_scriptHookAllowed = " .. scriptHook)

    if scriptHook == "true" then
        print("^1[DevMotivator9000]^7 This is brave.")
    end

    -- FRAMEWORK
    local qb = analyzeQBCore()
    local esx = analyzeESX()

    if qb then
        print("^5[DevMotivator9000]^7 Framework Detected: QBCore")
        print("^5[DevMotivator9000]^7 Usable Items: " .. qb.items)
        print("^5[DevMotivator9000]^7 Jobs Registered: " .. qb.jobs)
        print("^5[DevMotivator9000]^7 Inventory Density Index: " .. qb.density .. " items/player")

        if qb.density > 75 then
            print("^3[DevMotivator9000]^7 You built an Amazon warehouse.")
        end
    elseif esx then
        print("^5[DevMotivator9000]^7 Framework Detected: ESX")
        print("^5[DevMotivator9000]^7 Items: " .. esx.items)
        print("^5[DevMotivator9000]^7 Jobs: " .. esx.jobs)
    end

    -- HEALTH
    local healthBracket = math.floor(health / 10) * 10
    local healthQuote = Config.HealthQuotes[healthBracket] or ""
    print("^5[DevMotivator9000]^7 Server Health Index: " .. health .. "%")
    if healthQuote ~= "" then
        print("^5[DevMotivator9000]^7 " .. healthQuote)
    end

    print("^5[DevMotivator9000]^7 ------------------------------")
end)