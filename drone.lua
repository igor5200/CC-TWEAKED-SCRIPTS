local top   = peripheral.wrap("Create_RotationSpeedController_0")
local left  = peripheral.wrap("left")
local right = peripheral.wrap("right")

local HOVER_RPM = 111

-- Siła sterowania
local KP = 8

-- Maksymalna moc bocznego propelera
local MAX_RPM = 50

-- Tolerancja pozycji
local TOLERANCE = 0.2

-- Wszystko boczne zatrzymane
left.setTargetSpeed(0)
right.setTargetSpeed(0)

-- Rozpocznij zawis
top.setTargetSpeed(HOVER_RPM)

print("Stabilizacja zawisu...")
sleep(3)

-- Pobierz pozycję początkową
local x, y, z = gps.locate(2)

if not x then
    error("Brak GPS")
end

-- Lecimy 5 bloków w prawo
local targetX = x + 5

print("Start X: " .. x)
print("Cel X:   " .. targetX)

while true do

    local currentX = select(1, gps.locate(2))

    if not currentX then
        left.setTargetSpeed(0)
        right.setTargetSpeed(0)
        sleep(0.1)
    else

        local errorX = targetX - currentX

        -- Dotarliśmy do celu
        if math.abs(errorX) <= TOLERANCE then
            right.setTargetSpeed(0)
            left.setTargetSpeed(0)

            print("CEL OSIAGNIETY!")
            print("X = " .. currentX)

            break
        end

        -- Im dalej od celu, tym większy ciąg
        local rpm = errorX * KP

        -- Ograniczenie
        rpm = math.max(-MAX_RPM, math.min(MAX_RPM, rpm))

        if rpm > 0 then
            -- Ruch X+
            right.setTargetSpeed(rpm)
            left.setTargetSpeed(0)

        else
            -- Ruch X-
            left.setTargetSpeed(rpm)
            right.setTargetSpeed(0)
        end

        print(string.format(
            "X: %.2f | Cel: %.2f | Blad: %.2f | RPM: %.2f",
            currentX,
            targetX,
            errorX,
            rpm
        ))

        sleep(0.1)
    end
end

left.setTargetSpeed(0)
right.setTargetSpeed(0)

print("Zakonczono.")
