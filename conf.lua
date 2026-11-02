function love.conf(t)
    t.identity = "DotaTruyenKy"
    t.version  = "11.4"

    t.window.title      = "DotaTruyenKy"
    t.window.icon       = "logo.jpg"    -- Icon app (447x447)
    t.window.width      = 844           -- iPhone 12 Pro logic width  (landscape)
    t.window.height     = 390           -- iPhone 12 Pro logic height (landscape)
    t.window.resizable  = false
    t.window.fullscreen = false
    t.window.highdpi    = true
    t.window.vsync      = 1
    t.window.msaa       = 4

    -- iOS: khóa landscape (xoay ngang)
    t.window.orientation = "landscape"

    t.modules.joystick  = false
    t.modules.physics   = false
    t.console           = false
end
