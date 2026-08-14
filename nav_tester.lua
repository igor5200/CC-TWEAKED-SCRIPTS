local TARGET_X = -232
local TARGET_Z = -59

local nav = peripheral.wrap("navigation_table_0")

while true do

    local droneX, _, droneZ = gps.locate(1)

    if droneX then

        -- Wektor do celu
        local vx = TARGET_X - droneX
        local vz = TARGET_Z - droneZ

        -- Heading
        local heading = nav.getHeadingRad()

        -- Normalizacja headingu do -pi ... +pi
        heading = (heading + math.pi) % (2 * math.pi) - math.pi

        -- Odległość
        local distance =
            math.sqrt(vx * vx + vz * vz)

        if distance > 0 then

            -- Wektor jednostkowy świata
            local worldX = vx / distance
            local worldZ = vz / distance

            -- WORLD -> DRONE
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

            print("POSITION")
            print(string.format(
                "X: %.2f",
                droneX
            ))

            print(string.format(
                "Z: %.2f",
                droneZ
            ))

            print()

            print("TARGET")
            print("X:", TARGET_X)
            print("Z:", TARGET_Z)

            print()

            print("WORLD VECTOR")
            print(string.format(
                "VX: %.2f",
                vx
            ))

            print(string.format(
                "VZ: %.2f",
                vz
            ))

            print()

            print("HEADING")
            print(string.format(
                "RAD: %.4f",
                heading
            ))

            print(string.format(
                "DEG: %.2f",
                math.deg(heading)
            ))

            print()

            print("LOCAL VECTOR")
            print(string.format(
                "FORWARD: %.4f",
                forward
            ))

            print(string.format(
                "RIGHT: %.4f",
                right
            ))

            print()

            if math.abs(forward) > math.abs(right) then

                if forward > 0 then
                    print(">>> FRONT <<<")
                else
                    print(">>> BACK <<<")
                end

            else

                if right > 0 then
                    print(">>> RIGHT <<<")
                else
                    print(">>> LEFT <<<")
                end

            end

        end

    else

        term.clear()
        term.setCursorPos(1, 1)

        print("GPS ERROR")

    end

    sleep(0.2)

end
