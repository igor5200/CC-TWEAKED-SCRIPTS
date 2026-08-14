local TARGET_X = 100
local TARGET_Z = 200

local nav = peripheral.wrap("navigation_table_0")

while true do

    local x, y, z = gps.locate(1)
    local heading = nav.getHeadingRad()

    if not x then
        print("GPS ERROR")
        sleep(1)
    else

        -- Wektor od drona do celu
        local vx = TARGET_X - x
        local vz = TARGET_Z - z

        -- Odległość pozioma
        local distance = math.sqrt(vx * vx + vz * vz)

        if distance > 0 then

            -- Znormalizowany wektor świata
            local worldX = vx / distance
            local worldZ = vz / distance

            -- Przeliczenie na układ drona
            local forward =
                worldX * math.sin(heading) +
                worldZ * math.cos(heading)

            local right =
                worldX * math.cos(heading) -
                worldZ * math.sin(heading)

            term.clear()
            term.setCursorPos(1, 1)

            print("=== DIRECTION TEST ===")
            print()

            print("DRONE")
            print("X:", x)
            print("Z:", z)

            print()

            print("TARGET")
            print("X:", TARGET_X)
            print("Z:", TARGET_Z)

            print()

            print("WORLD VECTOR")
            print("VX:", vx)
            print("VZ:", vz)

            print()

            print("HEADING")
            print("RAD:", heading)
            print("DEG:", math.deg(heading))

            print()

            print("LOCAL VECTOR")
            print("FORWARD:", forward)
            print("RIGHT:", right)

            print()

            if math.abs(forward) > math.abs(right) then

                if forward > 0 then
                    print(">>> PRZOD <<<")
                else
                    print(">>> TYL <<<")
                end

            else

                if right > 0 then
                    print(">>> PRAWO <<<")
                else
                    print(">>> LEWO <<<")
                end

            end

        end

        sleep(0.1)
    end
end
