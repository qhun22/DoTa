-- Màn hình đăng nhập — hiển thị sau khi intro kết thúc.
-- Giai đoạn 1 của project: chỉ render UI, chưa xử lý login thật.

local Login = {}

-- ─── Tham số ─────────────────────────────────────────────────
local FADE_SPEED = 2.0   -- tốc độ fade-in màn hình (alpha/giây)

-- ─── State nội bộ ────────────────────────────────────────────
local assets   = {}      -- textures đã load
local bgm      = nil     -- nhạc nền
local sndClick = nil     -- tiếng click
local alpha    = 0       -- fade-in 0→1
local loaded   = false

-- Vùng input giả (chỉ hiển thị, không nhập thật)
local USERNAME_PLACEHOLDER = "1"
local PASSWORD_PLACEHOLDER = "1"

-- ─── Hàm nội bộ ──────────────────────────────────────────────

-- Tính tọa độ căn giữa safe area (tránh notch)
local function safeCenter()
    local W, H = love.graphics.getDimensions()
    return W / 2, H / 2
end

local function loadAssets()
    if loaded then return end
    loaded = true

    assets.bg     = love.graphics.newImage("assets/mainlogin/loginbackground.png")
    assets.dialog = love.graphics.newImage("assets/mainlogin/dialogBg.png")
    assets.btn    = love.graphics.newImage("assets/mainlogin/btnConfirm1.png")
    assets.user   = love.graphics.newImage("assets/mainlogin/user.png")

    -- Nhạc nền loop
    local ok, src = pcall(love.audio.newSource, "assets/audio/login_bgm.mp3", "stream")
    if ok then
        bgm = src
        bgm:setLooping(true)
        bgm:setVolume(0.6)
        bgm:play()
    end

    -- Tiếng click
    local ok2, s = pcall(love.audio.newSource, "assets/audio/click.mp3", "static")
    if ok2 then sndClick = s end
end

-- ─── Public API ───────────────────────────────────────────────

function Login.enter()
    loadAssets()
    alpha = 0
end

function Login.update(dt)
    alpha = math.min(1, alpha + FADE_SPEED * dt)
end

function Login.draw()
    local W, H   = love.graphics.getDimensions()
    local cx, cy = safeCenter()

    -- ── 1. Ảnh nền (letterbox giữ tỉ lệ, che kín màn hình) ──
    local bgW, bgH   = assets.bg:getDimensions()
    local scaleX     = W / bgW
    local scaleY     = H / bgH
    local bgScale    = math.max(scaleX, scaleY)
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.draw(
        assets.bg, cx, cy,
        0, bgScale, bgScale,
        bgW / 2, bgH / 2
    )

    -- ── 2. Hộp dialog ──
    local dlgW, dlgH = assets.dialog:getDimensions()
    -- scale dialog vừa khéo ~55% chiều cao màn hình
    local dlgScale   = (H * 0.72) / dlgH
    local dlgX       = cx - dlgW * dlgScale / 2
    local dlgY       = cy - dlgH * dlgScale / 2

    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.draw(assets.dialog, cx, cy, 0, dlgScale, dlgScale, dlgW/2, dlgH/2)

    -- ── 3. Tiêu đề "ĐĂNG NHẬP" ──
    local font = love.graphics.getFont()
    love.graphics.setColor(1, 0.92, 0.65, alpha)  -- vàng nhạt
    local title = "DANG NHAP"
    local tw    = font:getWidth(title)
    love.graphics.print(title, cx - tw/2, dlgY + dlgH * dlgScale * 0.06)

    -- ── 4. Field "Tài khoản" ──
    local fieldW  = dlgW * dlgScale * 0.78
    local fieldH  = 36
    local fieldX  = cx - fieldW / 2
    local field1Y = dlgY + dlgH * dlgScale * 0.25

    -- Label
    love.graphics.setColor(0.9, 0.9, 0.9, alpha)
    love.graphics.print("Tai khoan", fieldX, field1Y - 18)

    -- Box
    love.graphics.setColor(0.1, 0.1, 0.1, alpha * 0.85)
    love.graphics.rectangle("fill", fieldX, field1Y, fieldW, fieldH, 4, 4)
    love.graphics.setColor(0.4, 0.35, 0.25, alpha)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", fieldX, field1Y, fieldW, fieldH, 4, 4)

    -- Icon user
    local uW, uH   = assets.user:getDimensions()
    local uScale   = (fieldH * 0.6) / uH
    love.graphics.setColor(0.7, 0.7, 0.7, alpha)
    love.graphics.draw(assets.user, fieldX + 10, field1Y + fieldH/2, 0, uScale, uScale, 0, uH/2)

    -- Placeholder text
    love.graphics.setColor(0.8, 0.8, 0.8, alpha)
    love.graphics.print(USERNAME_PLACEHOLDER, fieldX + 14 + uW*uScale + 4, field1Y + (fieldH - font:getHeight())/2)

    -- ── 5. Field "Mật khẩu" ──
    local field2Y = field1Y + fieldH + 28

    love.graphics.setColor(0.9, 0.9, 0.9, alpha)
    love.graphics.print("Mat khau", fieldX, field2Y - 18)

    love.graphics.setColor(0.1, 0.1, 0.1, alpha * 0.85)
    love.graphics.rectangle("fill", fieldX, field2Y, fieldW, fieldH, 4, 4)
    love.graphics.setColor(0.4, 0.35, 0.25, alpha)
    love.graphics.rectangle("line", fieldX, field2Y, fieldW, fieldH, 4, 4)

    -- Dấu chấm mật khẩu
    love.graphics.setColor(0.8, 0.8, 0.8, alpha)
    love.graphics.print("*", fieldX + 14, field2Y + (fieldH - font:getHeight())/2)

    -- ── 6. Nút "ĐĂNG NHẬP" ──
    local btnW, btnH  = assets.btn:getDimensions()
    local btnScale    = (fieldW * 0.55) / btnW
    local btnX        = cx
    local btnY        = field2Y + fieldH + 22

    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.draw(assets.btn, btnX, btnY, 0, btnScale, btnScale, btnW/2, 0)

    -- Text trên nút
    love.graphics.setColor(0.15, 0.08, 0.02, alpha)
    local btnLabel = "DANG NHAP"
    local blW      = font:getWidth(btnLabel)
    local blH      = font:getHeight()
    love.graphics.print(
        btnLabel,
        btnX - blW/2,
        btnY + (btnH * btnScale - blH) / 2
    )

    -- ── 7. Version tag ──
    love.graphics.setColor(1, 0.85, 0.2, alpha * 0.8)
    love.graphics.print("Phien ban: 1.0.0.124", W - 150, H - 22)

    love.graphics.setColor(1, 1, 1, 1)
end

function Login.exit()
    if bgm then bgm:stop() end
end

function Login.mousepressed(x, y, button)
    if button == 1 and sndClick then
        sndClick:stop()
        sndClick:play()
    end
end

return Login
