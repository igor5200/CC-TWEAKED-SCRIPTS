local top   = peripheral.wrap("Create_RotationSpeedController_0")
local front = peripheral.wrap("front")
local back  = peripheral.wrap("back")
local left  = peripheral.wrap("left")
local right = peripheral.wrap("right")
local nav   = peripheral.wrap("navigation_table_0")

if not top then error("Brak top") end
if not front then error("Brak front") end
if not back then error("Brak back") end
if not left then error("Brak left") end
if not right then error("Brak right") end
if not nav then error("Brak navigation_table_0") end

--------------------------------------------------
-- USTAWIENIA
--------------------------------------------------

local HOVER_RPM = 111

-- P
local KP = 8

-- D
local KD = 4

-- Maksymalny RPM pojedynczego propelera
local MAX_RPM = 50

-- Odległość od celu uznawana za osiągnięcie
local POSITION_TOLERANCE = 0.25

-- Czas pomiędzy próbkami
local DT = 0.1

--------------------------------------------------
-- FUNKCJE
--------------------------------------------------

local function stopSidePropellers()
    front.setTargetSpeed(0)
    back.setTargetSpeed(0)
    left.setTargetSpeed(0)
    right.setTargetSpeed(0)
end


-- Ustawienie siły w lokalnym kierunku FRONT/BACK
local function setFrontForce(force)

    if force > 0 then
        front.setTargetSpeed(
            math.min(force, MAX_RPM)
        )

        back.setTargetSpeed(0)

    else
        back.setTargetSpeed(
            math.max(force, -MAX_RPM)
        )

        front.setTargetSpeed(0)
    end
end


-- Ustawienie siły w lokalnym kierunku LEFT/RIGHT
local function setRightForce(force)

    if force > 0 then
        right.setTargetSpeed(
            math.min(force, MAX_RPM)
        )

        left.setTargetSpeed(0)

    else
        left.setTargetSpeed(
            math.max(force, -MAX_RPM)
        )

        right.setTargetSpeed(0)
    end
end


--------------------------------------------------
-- START
--------------------------------------------------

stopSidePropellers()

top.setTargetSpeed(HOVER_RPM)

print("Start zawisu...")
sleep(3)

--------------------------------------------------
-- POZYCJA STARTOWA
--------------------------------------------------

local startX, startY, startZ = gps.locate(2)

if not startX then
    error("Nie znaleziono GPS")
end

--------------------------------------------------
-- CEL
--------------------------------------------------

local targetX = startX + 5
local targetZ = startZ

print("Start:")
print("X = " .. startX)
print("Z = " .. startZ)

print()

print("Cel:")
print("X = " .. targetX)
print("Z = " .. targetZ)

sleep(2)

--------------------------------------------------
-- PD
--------------------------------------------------

while true do

    local x, y, z = gps.locate(2)

    if not x then
        print("Brak GPS!")

        stopSidePropellers()

        sleep(DT)

    else

        --------------------------------------------------
        -- BŁĄD POZYCJI
        --------------------------------------------------

        local errorX = targetX - x
        local errorZ = targetZ - z


        --------------------------------------------------
        -- PRĘDKOŚĆ
        --------------------------------------------------

        -- Zapamiętujemy poprzednią pozycję
        -- i liczymy prędkość z GPS.

        if not previousX then
            previousX = x
            previousZ = z
        end

        local velocityX = (x - previousX) / DT
        local velocityZ = (z - previousZ) / DT

        previousX = x
        previousZ = z


        --------------------------------------------------
        -- P + D
        --------------------------------------------------

        local forceX =
            KP * errorX
            - KD * velocityX

        local forceZ =
            KP * errorZ
            - KD * velocityZ


        --------------------------------------------------
        -- TRANSFORMACJA WORLD → DRONE
        --------------------------------------------------

        local heading = nav.getHeadingRad()

        -- FRONT drona w świecie
        local frontX = math.sin(heading)
        local frontZ = math.cos(heading)

        -- RIGHT drona w świecie
        local rightX = math.cos(heading)
        local rightZ = -math.sin(heading)


        --------------------------------------------------
        -- WORLD FORCE → LOCAL FORCE
        --------------------------------------------------

        local localFront =
            forceX * frontX
            + forceZ * frontZ

        local localRight =
            forceX * rightX
            + forceZ * rightZ


        --------------------------------------------------
        -- PROPELLERY
        --------------------------------------------------

        setFrontForce(localFront)
        setRightForce(localRight)


        --------------------------------------------------
        -- INFORMACJE
        --------------------------------------------------

        term.clear()
        term.setCursorPos(1, 1)

        print("=== PD POSITION CONTROLLER ===")
        print()

        print(string.format(
            "POS X: %.2f",
            x
        ))

        print(string.format(
            "POS Z: %.2f",
            z
        ))

        print()

        print(string.format(
            "TARGET X: %.2f",
            targetX
        ))

        print(string.format(
            "TARGET Z: %.2f",
            targetZ
        ))

        print()

        print(string.format(
            "ERROR X: %+.2f",
            errorX
        ))

        print(string.format(
            "ERROR Z: %+.2f",
            errorZ
        ))

        print()

        print(string.format(
            "VEL X: %+.2f",
            velocityX
        ))

        print(string.format(
            "VEL Z: %+.2f",
            velocityZ
        ))

        print()

        print(string.format(
            "WORLD FX: %+.2f",
            forceX
        ))

        print(string.format(
            "WORLD FZ: %+.2f",
            forceZ
        ))

        print()

        print(string.format(
            "LOCAL FRONT: %+.2f",
            localFront
        ))

        print(string.format(
            "LOCAL RIGHT: %+.2f",
            localRight
        ))

        --------------------------------------------------
        -- CEL
        --------------------------------------------------

        if math.abs(errorX) < POSITION_TOLERANCE
        and math.abs(errorZ) < POSITION_TOLERANCE
        and math.abs(velocityX) < 0.2
        and math.abs(velocityZ) < 0.2 then

            stopSidePropellers()

            print()
            print("CEL OSIAGNIETY!")

            break
        end

        sleep(DT)
    end
end

stopSidePropellers()

print("Dron zatrzymany.")
