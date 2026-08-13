local controllers = {
    front = peripheral.wrap("front"),
    back  = peripheral.wrap("back"),
    left  = peripheral.wrap("left"),
    right = peripheral.wrap("right")
}

local TEST_SPEED = 20
local TEST_TIME = 2

local function stopAll()
    for _, controller in pairs(controllers) do
        if controller then
            controller.setTargetSpeed(0)
        end
    end
end

local function getPosition()
    local x, y, z = gps.locate(3)

    if not x then
        return nil
    end

    return {
        x = x,
        y = y,
        z = z
    }
end

print("================================")
print("     DRONE MOTOR CALIBRATION")
print("================================")
print("")

for name, controller in pairs(controllers) do

    if not controller then
        print(name .. ": BRAK KONTROLERA")
    else

        print("")
        print("--------------------------------")
        print("TEST: " .. string.upper(name))
        print("--------------------------------")

        stopAll()

        print("Pobieranie pozycji poczatkowej...")

        local start = getPosition()

        if not start then
            print("BLAD: brak GPS!")
            stopAll()
            return
        end

        print(string.format(
            "START: X %.2f  Y %.2f  Z %.2f",
            start.x,
            start.y,
            start.z
        ))

        print("")
        print("Uruchamiam " .. name .. "...")

        controller.setTargetSpeed(TEST_SPEED)

        sleep(TEST_TIME)

        controller.setTargetSpeed(0)

        print("Silnik zatrzymany.")
        sleep(1)

        local finish = getPosition()

        if not finish then
            print("BLAD: nie mozna odczytac GPS!")
            stopAll()
            return
        end

        local dx = finish.x - start.x
        local dy = finish.y - start.y
        local dz = finish.z - start.z

        print("")
        print("WYNIK:")
        print(string.format(
            "DX = %+8.3f",
            dx
        ))

        print(string.format(
            "DY = %+8.3f",
            dy
        ))

        print(string.format(
            "DZ = %+8.3f",
            dz
        ))

        print("")

        if math.abs(dx) > math.abs(dz) then

            if dx > 0 then
                print("Dominujacy kierunek: +X")
            else
                print("Dominujacy kierunek: -X")
            end

        elseif math.abs(dz) > math.abs(dx) then

            if dz > 0 then
                print("Dominujacy kierunek: +Z")
            else
                print("Dominujacy kierunek: -Z")
            end

        else
            print("Brak wyraznego ruchu X/Z")
        end

        if math.abs(dy) > 0.3 then
            if dy > 0 then
                print("Ruch pionowy: +Y")
            else
                print("Ruch pionowy: -Y")
            end
        end

        print("")
        print("Nacisnij ENTER, aby kontynuowac...")

        read()
    end
end

stopAll()

print("")
print("================================")
print("       KALIBRACJA GOTOWA")
print("================================")
