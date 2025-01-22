local formatDisplayedName = Config.FormatDisplayName;
local ignorePlayerNameDistance = false
local playerNamesDist = Config.PlayerNamesDist
local playerNamesDist2 = playerNamesDist * playerNamesDist
local displayIDHeight = Config.DisplayHeight
local isMenuOpen = false
local searchQuery = ""
local showTags = true;
Prefixes = {}
local hidePrefix = {}
local hideTags = {}
local activeTagTracker = {}
local hideAll = false
local red = 255
local green = 255
local blue = 255
local noclip = {}

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if not onScreen then return end

    local dist = #(GetGameplayCamCoords() - vector3(x, y, z))
    local scale = (1/dist) * 2 * (1/GetGameplayCamFov()) * 100

    SetTextScale(0.0*scale, 0.55*scale)
    SetTextFont(0)
    SetTextProportional(true)
    SetTextColour(red, green, blue, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(_x, _y)
end



RegisterNetEvent("jd-headtags:client:hideTag")
AddEventHandler("jd-headtags:client:hideTag", function(arr, error)
	hideTags = arr
end)

RegisterNetEvent("jd-headtags:client:toggleAllTags")
AddEventHandler("jd-headtags:client:toggleAllTags", function(val, error)
	hideAll = val
end)

RegisterNetEvent("jd-headtags:client:toggleTag")
AddEventHandler("jd-headtags:client:toggleTag", function(arr, error)
	hidePrefix = arr
end)

RegisterNetEvent("jd-headtags:client:updateTags")
AddEventHandler("jd-headtags:client:updateTags", function(arr, activeTagTrack, error)
	Prefixes = arr
	activeTagTracker = activeTagTrack
end)

RegisterNetEvent("jd-headtags:client:noclip")
AddEventHandler("jd-headtags:client:noclip", function(player)
    noclip[player] = not noclip[player]
    Debug("Noclip toggled for player " .. player .. ": " .. tostring(noclip[player]))
end)


Citizen.CreateThread(function()
	Wait(1000);
	TriggerServerEvent('jd-headtags:server:getTags');
end)

local function TriggerTagUpdate()
    if hideAll then return end

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local activePlayers = GetActivePlayers()

    for i = 0, #activePlayers do
        local targetPed = GetPlayerPed(activePlayers[i])
        if NetworkIsPlayerActive(activePlayers[i]) then
            local serverId = GetPlayerServerId(activePlayers[i])
            if noclip[serverId] then goto continue end

            local activeTag = activeTagTracker[GetPlayerServerId(activePlayers[i])] or ''
            local targetCoords = GetEntityCoords(targetPed)
            local dx, dy, dz = playerCoords.x - targetCoords.x, playerCoords.y - targetCoords.y, playerCoords.z - targetCoords.z
            local distance2 = dx*dx + dy*dy + dz*dz

            if distance2 < playerNamesDist2 and (not ignorePlayerNameDistance) then
                local playName = GetPlayerName(activePlayers[i])

                if targetPed == playerPed and not Config.ShowOwnTag then
                    goto continue
                end

                if HasValue(hideTags, playName) then goto continue end

                if HasValue(hidePrefix, playName) then
                    if targetPed ~= playerPed or Config.ShowOwnTag then
                        DrawText3D(targetCoords.x, targetCoords.y, targetCoords.z + displayIDHeight, "~w~[" .. serverId .. "]")
                    end
                    goto continue
                end

                if targetPed ~= playerPed and not HasEntityClearLosToEntity(playerPed, targetPed, 17) then
                    goto continue
                end

                local displayName = formatDisplayedName
                local color = NetworkIsPlayerTalking(activePlayers[i]) and "~b~" or "~w~"

                displayName = displayName:gsub("{HEADTAG}", activeTag):gsub("{SERVER_ID}", serverId):gsub("{SPEAKING}", color)

                red = NetworkIsPlayerTalking(activePlayers[i]) and 0 or 255
                green = NetworkIsPlayerTalking(activePlayers[i]) and 0 or 255
                blue = NetworkIsPlayerTalking(activePlayers[i]) and 255 or 255

                DrawText3D(targetCoords.x, targetCoords.y, targetCoords.z + displayIDHeight, color .. displayName)
            end
            ::continue::
        end
    end
end

Citizen.CreateThread(function()
    local Wait = Citizen.Wait
    local IsControlPressed = IsControlPressed
    local IsControlJustReleased = IsControlJustReleased

    while true do
        local maxPlayers = #GetActivePlayers()
        for i = 0, maxPlayers do
            ---@diagnostic disable-next-line: undefined-global
            N_0x31698aa80e0223f8(i)
        end

        if showTags then
            TriggerTagUpdate()
        end
        Wait(0)
    end
end)

local isMenuOpen = false

RegisterCommand('headtags', function()
    if isMenuOpen then
        isMenuOpen = false
        lib.hideContext()
    else
        OpenHeadtagMenu()
    end
end, false)

function OpenHeadtagMenu()
    if isMenuOpen then return end
    isMenuOpen = true
    local headtags = lib.callback.await('jd-headtags:return-tags')
    local searchQuery = ""

    local options = {
        {
            title = "Toggle Headtag",
            description = "Toggle your personal headtag",
            event = 'jd-headtags:server:toggleTag'
        },
        {
            title = "Toggle All Headtags",
            description = "Toggle all headtags on/off",
            event = 'jd-headtags:server:toggleAllTags'
        }
    }

    if Config.EnableSearch then
        table.insert(options, {
            title = "Search Tags",
            description = "Search for specific headtags",
            onSelect = function()
                local input = lib.inputDialog('Headtag Search', {
                    { type = 'input', label = 'Search Query', description = 'Enter text to filter tags' }
                })
                if input and input[1] then
                    searchQuery = input[1]:lower()
                    OpenHeadtagMenuWithSearch(headtags, searchQuery)
                end
            end
        })
    end

    for i, tag in ipairs(headtags) do
        if not Config.EnableSearch or searchQuery == "" or string.find(string.lower(tag), searchQuery) then
            table.insert(options, {
                title = '~y~[' .. i .. ']~s~ ' .. tag,
                description = 'Select headtag: ' .. tag,
                event = 'jd-headtags:server:setTag',
                args = i
            })
        end
    end

    if Config.EnableSearch and searchQuery ~= "" then
        table.insert(options, {
            title = "Clear Search",
            description = "Clear the current search filter",
            onSelect = function()
                searchQuery = ""
                OpenHeadtagMenu()
            end
        })
    end

    lib.registerContext({
        id = 'headtag_menu',
        title = 'Headtag Menu',
        options = options
    })

    lib.showContext('headtag_menu')
end

function OpenHeadtagMenuWithSearch(headtags, searchQuery)
    isMenuOpen = false
    OpenHeadtagMenu() -- Reopen menu with filtered options
end
