-- login.lua — Màn hình đăng nhập
-- UI khớp với web: login.css (font-size/weight/spacing lấy từ CSS gốc)

local Login = {}

local FADE_SPEED = 2.5

-- Màu từ CSS gốc (không đổi)
local C = {
    modalBg     = {16/255, 13/255, 20/255, 0.88},
    modalBorder = {220/255, 185/255, 115/255, 0.55},
    fieldBg     = {0, 0, 0, 0.65},
    fieldBorder = {200/255, 170/255, 100/255, 0.45},
    white       = {1, 1, 1},
    gold        = {251/255, 206/255, 16/255},        -- #fbce10
    versionGold = {229/255, 185/255, 85/255},         -- #e5b955
    divider     = {201/255, 167/255, 100/255, 0.35},
}

local assets = {}
local alpha  = 0
local loaded = false
local bgm, sndClick

-- ── UTF-8 character iterator ─────────────────────────────────
local function utf8chars(str)
    local i, n = 1, #str
    return function()
        if i > n then return nil end
        local b = str:byte(i)
        local len = b < 0x80 and 1 or b < 0xE0 and 2 or b < 0xF0 and 3 or 4
        local ch = str:sub(i, i + len - 1)
        i = i + len
        return ch
    end
end

-- Tổng chiều rộng text với letter-spacing
local function spacedWidth(font, text, spacing)
    local w, count = 0, 0
    for ch in utf8chars(text) do
        w = w + font:getWidth(ch)
        count = count + 1
    end
    return w + spacing * math.max(0, count - 1)
end

-- In text với letter-spacing (căn trái)
local function printSpaced(font, text, x, y, spacing)
    local cx = x
    for ch in utf8chars(text) do
        love.graphics.print(ch, cx, y)
        cx = cx + font:getWidth(ch) + spacing
    end
end

-- In text bold + letter-spacing (weight 800 simulation: vẽ 2 lần offset ±0.5px)
local function printBoldSpaced(font, text, x, y, spacing)
    local cx = x
    for ch in utf8chars(text) do
        love.graphics.print(ch, cx - 0.5, y)
        love.graphics.print(ch, cx + 0.5, y)
        love.graphics.print(ch, cx,       y)
        cx = cx + font:getWidth(ch) + spacing
    end
end

-- In text bold (weight 700: vẽ 2 lần offset x ±0.4px)
local function printBold(text, x, y)
    love.graphics.print(text, x - 0.4, y)
    love.graphics.print(text, x + 0.4, y)
    love.graphics.print(text, x,       y)
end

local function loadAssets()
    if loaded then return end
    loaded = true

    assets.bg  = love.graphics.newImage("assets/mainlogin/loginbackground.png")
    assets.btn = love.graphics.newImage("assets/mainlogin/btnConfirm1.png")

    local function sairaFont(size)
        local ok, f = pcall(love.graphics.newFont, "assets/fonts/Saira-Variable.ttf", size)
        return ok and f or love.graphics.newFont(size)
    end

    -- Kích thước khớp CSS: 24 / 14 / 15 / 16 / 13
    assets.fontTitle = sairaFont(24)
    assets.fontLabel = sairaFont(14)
    assets.fontField = sairaFont(15)
    assets.fontBtn   = sairaFont(16)
    assets.fontVer   = sairaFont(13)

    local ok2, s = pcall(love.audio.newSource, "assets/audio/login_bgm.mp3", "stream")
    if ok2 then bgm = s; bgm:setLooping(true); bgm:setVolume(0.6); bgm:play() end

    local ok3, c = pcall(love.audio.newSource, "assets/audio/click.mp3", "static")
    if ok3 then sndClick = c end
end

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

    -- ── 1. Ảnh nền cover ──────────────────────────────────────
    local bW, bH = assets.bg:getDimensions()
    local sc = math.max(W / bW, H / bH)
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.draw(assets.bg, W/2, H/2, 0, sc, sc, bW/2, bH/2)

    -- ── 2. Modal ──────────────────────────────────────────────
    -- CSS: max-width 480px, width 92%, padding 26px 36px 30px, gap 18px
    local modalW = math.min(480, W * 0.92)
    local padX   = 36 * (modalW / 480)
    local innerW = modalW - padX * 2

    -- Kích thước cố định từ CSS
    local TITLE_SPACING = 3    -- letter-spacing: 3px
    local BTN_SPACING   = 1.5  -- letter-spacing: 1.5px
    local fieldH        = 44   -- padding 11px*2 + ~22px line-height
    local labelH        = math.ceil(assets.fontLabel:getHeight())
    local labelGap      = 7    -- gap: 7px giữa label và field
    local sectionGap    = 18   -- gap: 18px giữa các section
    local titleH        = math.ceil(assets.fontTitle:getHeight())
    local headerH       = titleH + 12 + 1  -- title + padding-bottom 12px + divider 1px
    local bsc           = 160 / assets.btn:getWidth()
    local btnH          = math.ceil(assets.btn:getHeight() * bsc)
    local btnMarginTop  = 10   -- margin: 10px auto 0 từ CSS

    local modalH = 26 + headerH + sectionGap
                 + (labelH + labelGap + fieldH) + sectionGap
                 + (labelH + labelGap + fieldH)
                 + btnMarginTop + sectionGap + btnH + 30
    modalH = math.min(modalH, H * 0.95)

    local mx = math.floor((W - modalW) / 2)
    local my = math.floor((H - modalH) / 2)

    -- Shadow
    love.graphics.setColor(0, 0, 0, alpha * 0.45)
    roundRect("fill", mx+3, my+4, modalW, modalH, 5)

    -- Fill
    local bg = C.modalBg
    love.graphics.setColor(bg[1], bg[2], bg[3], bg[4] * alpha)
    roundRect("fill", mx, my, modalW, modalH, 5)

    -- Border
    local bo = C.modalBorder
    love.graphics.setColor(bo[1], bo[2], bo[3], bo[4] * alpha)
    love.graphics.setLineWidth(1.5)
    roundRect("line", mx, my, modalW, modalH, 5)

    -- ── 3. Tiêu đề "ĐĂNG NHẬP" ───────────────────────────────
    -- CSS: font-size 24px, font-weight 800, letter-spacing 3px
    local titleText = "ĐĂNG NHẬP"
    local titleY    = my + 26
    local tW        = spacedWidth(assets.fontTitle, titleText, TITLE_SPACING)

    love.graphics.setFont(assets.fontTitle)
    love.graphics.setColor(1, 1, 1, alpha)
    printBoldSpaced(assets.fontTitle, titleText,
                    math.floor(W/2 - tW/2), titleY, TITLE_SPACING)

    -- Divider dưới header (padding-bottom 12px + border-bottom)
    local divY = titleY + titleH + 12
    local d    = C.divider
    love.graphics.setColor(d[1], d[2], d[3], d[4] * alpha)
    love.graphics.setLineWidth(1)
    love.graphics.line(mx + padX, divY, mx + modalW - padX, divY)

    -- ── 4. Field "Tài khoản" ──────────────────────────────────
    local curY  = divY + 1 + sectionGap
    local fieldX = mx + padX
    local fieldW = innerW

    -- Label: font-weight 700
    love.graphics.setFont(assets.fontLabel)
    love.graphics.setColor(1, 1, 1, alpha)
    printBold("Tài khoản", fieldX, curY)
    curY = curY + labelH + labelGap

    -- Input box
    love.graphics.setColor(C.fieldBg[1], C.fieldBg[2], C.fieldBg[3], C.fieldBg[4] * alpha)
    roundRect("fill", fieldX, curY, fieldW, fieldH, 5)
    love.graphics.setColor(C.fieldBorder[1], C.fieldBorder[2], C.fieldBorder[3], C.fieldBorder[4] * alpha)
    love.graphics.setLineWidth(1.5)
    roundRect("line", fieldX, curY, fieldW, fieldH, 5)

    love.graphics.setFont(assets.fontField)
    love.graphics.setColor(1, 1, 1, alpha)
    local fh = assets.fontField:getHeight()
    love.graphics.print("1", fieldX + 14, math.floor(curY + (fieldH - fh) / 2))

    curY = curY + fieldH + sectionGap

    -- ── 5. Field "Mật khẩu" ───────────────────────────────────
    love.graphics.setFont(assets.fontLabel)
    love.graphics.setColor(1, 1, 1, alpha)
    printBold("Mật khẩu", fieldX, curY)
    curY = curY + labelH + labelGap

    love.graphics.setColor(C.fieldBg[1], C.fieldBg[2], C.fieldBg[3], C.fieldBg[4] * alpha)
    roundRect("fill", fieldX, curY, fieldW, fieldH, 5)
    love.graphics.setColor(C.fieldBorder[1], C.fieldBorder[2], C.fieldBorder[3], C.fieldBorder[4] * alpha)
    love.graphics.setLineWidth(1.5)
    roundRect("line", fieldX, curY, fieldW, fieldH, 5)

    love.graphics.setFont(assets.fontField)
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.print("•", fieldX + 14, math.floor(curY + (fieldH - fh) / 2))

    curY = curY + fieldH + btnMarginTop + sectionGap

    -- ── 6. Nút ĐĂNG NHẬP ──────────────────────────────────────
    -- CSS: font-size 16px, font-weight 800, letter-spacing 1.5px, color #fbce10
    local btnW  = 160
    local btnX  = math.floor(W/2 - btnW/2)
    local btnY  = curY

    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.draw(assets.btn, btnX, btnY, 0, bsc, bsc)

    -- Text trên nút: bold + letter-spacing 1.5px
    local btnLabel = "ĐĂNG NHẬP"
    love.graphics.setFont(assets.fontBtn)
    local bfh = assets.fontBtn:getHeight()
    local blW = spacedWidth(assets.fontBtn, btnLabel, BTN_SPACING)
    love.graphics.setColor(C.gold[1], C.gold[2], C.gold[3], alpha)
    printBoldSpaced(assets.fontBtn, btnLabel,
                    math.floor(W/2 - blW/2),
                    math.floor(btnY + (btnH - bfh) / 2),
                    BTN_SPACING)

    -- ── 7. Version tag ────────────────────────────────────────
    -- CSS: font-size 13px, font-weight 700, color #e5b955
    love.graphics.setFont(assets.fontVer)
    love.graphics.setColor(C.versionGold[1], C.versionGold[2], C.versionGold[3], alpha)
    local verText = "Phiên bản: 1.0.0.124"
    local vW = assets.fontVer:getWidth(verText)
    love.graphics.print(verText, W - vW - 14, H - assets.fontVer:getHeight() - 12)

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
