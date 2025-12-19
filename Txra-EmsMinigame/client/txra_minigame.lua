-- <!-- --[[
-- https://discord.gg/8nCR8H3se2

-- ████████╗██╗░░██╗██████╗░░█████╗░  ░██████╗████████╗░█████╗░██████╗░███████╗
-- ╚══██╔══╝╚██╗██╔╝██╔══██╗██╔══██╗  ██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██╔════╝
-- ░░░██║░░░░╚███╔╝░██████╔╝███████║  ╚█████╗░░░░██║░░░██║░░██║██████╔╝█████╗░░
-- ░░░██║░░░░██╔██╗░██╔══██╗██╔══██║  ░╚═══██╗░░░██║░░░██║░░██║██╔══██╗██╔══╝░░
-- ░░░██║░░░██╔╝╚██╗██║░░██║██║░░██║  ██████╔╝░░░██║░░░╚█████╔╝██║░░██║███████╗
-- ░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝  ╚═════╝░░░░╚═╝░░░░╚════╝░╚═╝░░╚═╝╚══════╝
-- ]] -->


local isPlaying = false
local currentSequence = {}
local currentIndex = 1
local totalArrows = 5
local timeLimit = 5 -- وقت المني قيم
local timerStart = 0
local success = false

local directions = {
    { dir = "top", key = 172, label = "↑" },
    { dir = "right", key = 175, label = "→" },
    { dir = "down", key = 173, label = "↓" },
    { dir = "left", key = 174, label = "←" },
}

function DisableMovement()
    DisableAllControlActions(0)
    EnableControlAction(0, 172, true) -- Up
    EnableControlAction(0, 175, true) -- Right
    EnableControlAction(0, 173, true) -- Down
    EnableControlAction(0, 174, true) -- Left
    EnableControlAction(0, 200, true) -- ESC
end

function PlaySound(soundName)
    SendNUIMessage({
        action = "playSound",
        sound = soundName
    })
end

function StartArrowMinigame(callback)
    if isPlaying then return end

    isPlaying = true
    success = false
    currentSequence = {}
    currentIndex = 1
    timerStart = GetGameTimer()

    for i = 1, totalArrows do
        table.insert(currentSequence, directions[math.random(1, #directions)])
    end

    SendNUIMessage({
        action = "showMinigame",
        sequence = currentSequence,
        timeLimit = timeLimit
    })
    SetNuiFocus(false, false)

    CreateThread(function()
        while isPlaying do
            DisableMovement() 
            Wait(0)
        end
    end)

    CreateThread(function()
        while isPlaying do
            Wait(0)

            local timeElapsed = (GetGameTimer() - timerStart) / 1000
            if timeElapsed >= timeLimit then
                PlaySound("fail")
                EndMinigame(false)
                break
            end

            for _, dir in pairs(directions) do
                if IsDisabledControlJustPressed(0, dir.key) then
                    CheckInput(dir.dir)
                end
            end
        end
    end)

    CreateThread(function()
        while isPlaying do
            local elapsed = (GetGameTimer() - timerStart) / 1000
            local remaining = math.max(0, timeLimit - elapsed)
            local percentage = (remaining / timeLimit) * 100

            SendNUIMessage({
                action = "updateTimer",
                timeLeft = remaining,
                percentage = percentage
            })

            if remaining <= 0 then
                break
            end

            Wait(100)
        end
    end)

    CreateThread(function()
        while isPlaying do Wait(100) end
        if callback then callback(success) end
    end)
end

function CheckInput(pressedDir)
    if not isPlaying then return end

    local correctDir = currentSequence[currentIndex].dir

    if pressedDir == correctDir then
        PlaySound("correct")
        currentIndex = currentIndex + 1
        SendNUIMessage({
            action = "correctInput",
            currentCount = currentIndex - 1,
            totalArrows = totalArrows
        })

        if currentIndex > totalArrows then
            success = true
            EndMinigame(true)
        end
    else
        PlaySound("fail")
        EndMinigame(false)
    end
end

function EndMinigame(success)
    if not isPlaying then return end

    isPlaying = false
    SendNUIMessage({
        action = "finishMinigame",
        success = success
    })

    if not success then
        Wait(500)
    end

    SendNUIMessage({ action = "hideMinigame" })
end

RegisterNUICallback('minigameEnded', function(data, cb)
    isPlaying = false
    cb({})
end)

exports('StartTxraMinigame', StartArrowMinigame)

RegisterCommand('testminigame', function()
    exports[GetCurrentResourceName()]:StartTxraMinigame(function(success)
        print(success and "Success!" or "Failed!")
    end)
end)


-- <!-- --[[
-- https://discord.gg/8nCR8H3se2

-- ████████╗██╗░░██╗██████╗░░█████╗░  ░██████╗████████╗░█████╗░██████╗░███████╗
-- ╚══██╔══╝╚██╗██╔╝██╔══██╗██╔══██╗  ██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██╔════╝
-- ░░░██║░░░░╚███╔╝░██████╔╝███████║  ╚█████╗░░░░██║░░░██║░░██║██████╔╝█████╗░░
-- ░░░██║░░░░██╔██╗░██╔══██╗██╔══██║  ░╚═══██╗░░░██║░░░██║░░██║██╔══██╗██╔══╝░░
-- ░░░██║░░░██╔╝╚██╗██║░░██║██║░░██║  ██████╔╝░░░██║░░░╚█████╔╝██║░░██║███████╗
-- ░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝  ╚═════╝░░░░╚═╝░░░░╚════╝░╚═╝░░╚═╝╚══════╝
-- ]] -->