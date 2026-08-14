local top   = peripheral.wrap("Create_RotationSpeedController_0")
local left  = peripheral.wrap("left")
local right = peripheral.wrap("right")

local HOVER_RPM = 111

-- Jak mocno reagujemy na błąd pozycji
local KP = 8

-- Maksymalna prędkość bocznych propellerów
local MAX_RPM = 50

-- Jak blisko celu uznajemy, że jesteśmy
local POSITION_TOLERANCE = 0.3

-- ==================================================
-- START
-- ==================================================

top.setTargetSpeed(HOVER_RPM)

left.setTargetSpeed(0)
right.setTargetSpeed(0)

print("Stabilizacja...")
sleep(3)

-- Pobierz aktualną pozycję
local x, y, z = gps.locate(2)

if not x then
    error("Nie znaleziono pozycji GPS")
end

-- CEL: 5 bloków w osi X
local targetX = x + 5

print("Start X: " .. x)
print("Cel X:   " .. targetX)

-- ==================================================
-- KONTROLER
-- ==================================================

while true do

    local currentX = select(1, gps.locate(2))

    if not currentX then
        left.setTargetSpeed(0)
        right.setTargetSpeed(0)

        print("Brak GPS!")

        sleep(0.1)
    else

        local errorX = targetX - currentX

        -- Jesteśmy wystarczająco blisko
        if math.abs(errorX) < POSITION_TOLERANCE then

            left.setTargetSpeed(0)
            right.setTargetSpeed(0)

            print("CEL OSIAGNIETY!")
            break
        end

        -- P controller
        local rpm = errorX * KP

        -- Ograniczenie RPM
        rpm = math.max(-MAX_RPM, math.min(MAX_RPM, rpm))

        -- ==================================================
        -- X+
        -- RIGHT = dodatnie
        -- LEFT  = ujemne
        -- ==================================================

        if rpm > 0 then

            right.setTargetSpeed(rpm)
            left.setTargetSpeed(-rpm)

        else

            right.setTargetSpeed(rpm)
            left.setTargetSpeed(-rpm)

        end

        print(
            string.format(
                "X: %.2f | Target: %.2f | Error: %.2f | RPM: %.2f",
                currentX,
                targetX,
                errorX,
                rpm
            )
        )

        sleep(0.1)
    end
end

-- Zatrzymanie bocznych
left.setTargetSpeed(0)
right.setTargetSpeed(0)

print("Dron zatrzymany nad celem.")
