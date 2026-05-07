function conky_main()
    require 'cairo'
    print("--- WINDOW CHECK ---")
    if conky_window then
        for k,v in pairs(conky_window) do
            print("window." .. k .. " = " .. tostring(v))
        end
    else
        print("conky_window is NIL")
    end
    os.exit()
end
