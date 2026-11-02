-- login.lua — Màn hình đăng nhập
-- UI khớp với web version (testuimap/index.html + login.css)
-- Màu sắc, layout lấy thẳng từ CSS gốc.

local Login = {}

local FADE_SPEED = 2.5   -- alpha/giây fade-in

-- Màu từ CSS gốc
local C = {
    modalBg     = {16/255, 13/255, 20/255, 0.88},   -- rgba(16,13,20,0.88)
    modalBorder = {220/255, 185/255, 115/255, 0.55}, -- rgba(220,185,115,0.55)
    fieldBg     = {0, 0, 0, 0.65},
    fieldBorder = {200/255, 170/255, 100/255, 0.45},
    white       = {1, 1, 1},
    gold        = {251/255, 206/255, 16/255},         -- #fbce10
    versionGold = {229/255, 185/255, 85/255},         -- #e5b955
    divider     = {201/255, 167/255, 100/255, 0.35},
}

local assets  = {}
local alpha   = 0
local loaded  = false
local bgm, sndClick

local function loadAssets()
    if loaded then return end
    loaded = true

    assets.bg  = love.graphics.newImage("assets/mainlogin/loginbackground.png")
    assets.btn = love.graphics.newImage("assets/mainlogin/btnConfirm1.png")

    -- Font Saira — hỗ trợ tiếng Việt
    local ok
    ok, assets.fontTitle = pcall(love.graphics.newFont, "assets/fonts/Saira-Variable.ttf", 22)
    if not ok then assets.fontTitle = love.graphics.newFont(22) end

    ok, assets.fontLabel = pcall(love.graphics.newFont, "assets/fonts/Saira-Variable.ttf", 13)
    if not ok then assets.fontLabel = love.graphics.newFont(13) end

    ok, assets.fontField = pcall(love.graphics.newFont, "assets/fonts/Saira-Variable.ttf", 14)
    if not ok then assets.fontField = love.graphics.newFont(14) end

    ok, assets.fontBtn = pcall(love.graphics.newFont, "assets/fonts/Saira-Variable.ttf", 15)
    if not ok then assets.fontBtn = love.graphics.newFont(15) end

    ok, assets.fontVer = pcall(love.graphics.newFont, "assets/fonts/Saira-Variable.ttf", 12)
    if not ok then assets.fontVer = love.graphics.newFont(12) end

    local ok2, s = pcall(love.audio.newSource, "assets/audio/login_bgm.mp3", "stream")
    if ok2 then bgm = s; bgm:setLooping(true); bgm:setVolume(0.6); bgm:play() end

    local ok3, c = pcall(love.audio.newSource, "assets/audio/click.mp3", "static")
    if ok3 then sndClick = c end
end

-- Vẽ hình chữ nhật bo góc (Love2D dùng rectangle + mode)
local function roundRect(mode, x, y, w, h, r)
    love.graphics.rectangle(mode, x, y, w, h, r, r)
end

function Login.enter()
    loadAssets()
    alpha = 0
end

function Login.update(dt)
    alpha = math.min(1, alpha + FADE_SPEED * dt)
end

function Login.draw()
    local W, H = love.graphics.getDimensions()

    -- ── 1. Ảnh nền cover toàn màn hình ──
    local bW, bH = assets.bg:getDimensions()
    local sc     = math.max(W / bW, H / bH)
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.draw(assets.bg, W/2, H/2, 0, sc, sc, bW/2, bH/2)

    -- ── 2. Modal box — giống .login-center-modal ──
    -- max-width 480px, padding 26px 36px, scale xuống nếu màn hình nhỏ
    local modalW  = math.min(480, W * 0.88)
    local padX    = 36 * (modalW / 480)
    local innerW  = modalW - padX * 2

    -- Chiều cao ước tính: title+divider 54 + gap + label+field×2 + gap + btn + padding
    local fieldH  = 40
    local labelH  = 18
    local btnH    = assets.btn:getHeight() * (160 / assets.btn:getWidth())
    local modalH  = 26 + 54 + 18 + (labelH+8+fieldH) + 18 + (labelH+8+fieldH) + 16 + btnH + 30
    modalH        = math.min(modalH, H * 0.92)

    local mx = (W - modalW) / 2
    local my = (H - modalH) / 2

    -- Shadow nhẹ (vẽ rect tối offset)
    love.graphics.setColor(0, 0, 0, alpha * 0.45)
    roundRect("fill", mx+3, my+4, modalW, modalH, 5)

    -- Fill
    local bg = C.modalBg
    love.graphics.setColor(bg[1], bg[2], bg[3], bg[4] * alpha)
    roundRect("fill", mx, my, modalW, modalH, 5)

    -- Border vàng
    local bo = C.modalBorder
    love.graphics.setColor(bo[1], bo[2], bo[3], bo[4] * alpha)
    love.graphics.setLineWidth(1.5)
    roundRect("line", mx, my, modalW, modalH, 5)

    -- ── 3. Tiêu đề "ĐĂNG NHẬP" ──
    local titleY = my + 26
    love.graphics.setFont(assets.fontTitle)
    local title  = "ĐĂNG NHẬP"
    -- setColor white, weight 800 simulated bằng font variable (đã load)
    love.graphics.setColor(1, 1, 1, alpha)
    local tw = assets.fontTitle:getWidth(title)
    love.graphics.print(title, math.floor(W/2 - tw/2), titleY)

    -- Đường kẻ dưới tiêu đề
    local divY = titleY + assets.fontTitle:getHeight() + 10
    local d    = C.divider
    love.graphics.setColor(d[1], d[2], d[3], d[4] * alpha)
    love.graphics.setLineWidth(1)
    love.graphics.line(mx + padX, divY, mx + modalW - padX, divY)

    -- ── 4. Field "Tài khoản" ──
    local curY  = divY + 16
    local fieldX = mx + padX
    local fieldW = innerW

    love.graphics.setFont(assets.fontLabel)
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.print("Tài khoản", fieldX, curY)
    curY = curY + labelH + 6

    -- Box input
    love.graphics.setColor(C.fieldBg[1], C.fieldBg[2], C.fieldBg[3], C.fieldBg[4] * alpha)
    roundRect("fill", fieldX, curY, fieldW, fieldH, 5)
    local fb = C.fieldBorder
    love.graphics.setColor(fb[1], fb[2], fb[3], fb[4] * alpha)
    love.graphics.setLineWidth(1.5)
    roundRect("line", fieldX, curY, fieldW, fieldH, 5)

    -- Text trong field
    love.graphics.setFont(assets.fontField)
    love.graphics.setColor(1, 1, 1, alpha)
    local fh = assets.fontField:getHeight()
    love.graphics.print("1", fieldX + 13, curY + (fieldH - fh) / 2)

    curY = curY + fieldH + 16

    -- ── 5. Field "Mật khẩu" ──
    love.graphics.setFont(assets.fontLabel)
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.print("Mật khẩu", fieldX, curY)
    curY = curY + labelH + 6

    love.graphics.setColor(C.fieldBg[1], C.fieldBg[2], C.fieldBg[3], C.fieldBg[4] * alpha)
    roundRect("fill", fieldX, curY, fieldW, fieldH, 5)
    love.graphics.setColor(fb[1], fb[2], fb[3], fb[4] * alpha)
    love.graphics.setLineWidth(1.5)
    roundRect("line", fieldX, curY, fieldW, fieldH, 5)

    love.graphics.setFont(assets.fontField)
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.print("•", fieldX + 13, curY + (fieldH - fh) / 2)

    curY = curY + fieldH + 14

    -- ── 6. Nút ĐĂNG NHẬP ──
    local btnW  = 160
    local btnSc = btnH / assets.btn:getHeight()
    -- btnSc tính từ chiều rộng 160px
    local bsc   = btnW / assets.btn:getWidth()
    local bh    = assets.btn:getHeight() * bsc
    local btnX  = W / 2 - btnW / 2
    local btnY  = curY + 8

    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.draw(assets.btn, btnX, btnY, 0, bsc, bsc)

    -- Text trên nút — vàng, Saira bold
    love.graphics.setFont(assets.fontBtn)
    love.graphics.setColor(C.gold[1], C.gold[2], C.gold[3], alpha)
    local lblTxt = "ĐĂNG NHẬP"
    local lw     = assets.fontBtn:getWidth(lblTxt)
    local lh     = assets.fontBtn:getHeight()
    love.graphics.print(lblTxt, W/2 - lw/2, btnY + (bh - lh)/2)

    -- ── 7. Version tag — góc dưới phải ──
    love.graphics.setFont(assets.fontVer)
    love.graphics.setColor(C.versionGold[1], C.versionGold[2], C.versionGold[3], alpha)
    local ver = "Phiên bản: 1.0.0.124"
    local vw  = assets.fontVer:getWidth(ver)
    love.graphics.print(ver, W - vw - 14, H - assets.fontVer:getHeight() - 12)

    love.graphics.setColor(1, 1, 1, 1)
end

function Login.exit()
    if bgm then bgm:stop() end
end

function Login.mousepressed(x, y, button)
    if button == 1 and sndClick then
        sndClick:stop(); sndClick:play()
    end
end

return Login
