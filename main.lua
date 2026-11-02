-- Hiệu ứng viết tay "qhun22" — Love2D 11.x
-- Mỗi ký tự vẽ theo thứ tự q → h → u → n → 2 → 2
-- có nhấc bút giữa các nét, nội suy Catmull-Rom cho đường cong mượt.

--============================================================
-- CẤU HÌNH (chỉnh tại đây, không cần sửa code bên dưới)
--============================================================
local CONFIG = {
    drawSpeed     = 400,   -- pixel/giây — tăng = vẽ nhanh hơn
    strokeWidth   = 3.5,   -- độ dày nét bút (px)
    fadeDuration  = 0.8,   -- fade-in từ đen (giây)
    holdDuration  = 1.0,   -- giữ chữ sau khi vẽ xong (giây)
    gapDuration   = 0.06,  -- nhấc bút giữa 2 nét (giây)
    safePaddingX  = 47,    -- lề X — tránh tai thỏ iPhone (px)
    safePaddingY  = 0,     -- lề Y (px)
    scale         = 1.5,   -- phóng to chữ (1.0 = gốc ~270px rộng)
    subdivisions  = 16,    -- điểm nội suy Catmull-Rom mỗi đoạn
    penGlow       = true,  -- hiệu ứng sáng đầu bút
    penGlowSize   = 8,     -- bán kính sáng (px)
}

--============================================================
-- TRẠNG THÁI (State Machine)
--============================================================
local PHASE = { FADE_IN = 1, DRAWING = 2, HOLD = 3, DONE = 4 }
local phase         = PHASE.FADE_IN
local fadeTimer      = 0
local holdTimer      = 0
local introComplete  = false

local strokes      = {}    -- mảng nét đã subdivide
local strokeLens   = {}    -- chiều dài mỗi nét
local strokeStarts = {}    -- chiều dài tích lũy tại ĐẦU mỗi nét
local totalLen     = 0
local drawnLen     = 0
local gapLen       = 0

--============================================================
-- NỘI SUY CATMULL-ROM
--============================================================
local function catmullRom(p0, p1, p2, p3, t)
    local t2, t3 = t * t, t * t * t
    return {
        0.5 * ((2*p1[1]) + (-p0[1]+p2[1])*t
            + (2*p0[1]-5*p1[1]+4*p2[1]-p3[1])*t2
            + (-p0[1]+3*p1[1]-3*p2[1]+p3[1])*t3),
        0.5 * ((2*p1[2]) + (-p0[2]+p2[2])*t
            + (2*p0[2]-5*p1[2]+4*p2[2]-p3[2])*t2
            + (-p0[2]+3*p1[2]-3*p2[2]+p3[2])*t3),
    }
end

local function subdivide(pts, n)
    if #pts < 2 then return pts end
    local out = {}
    for i = 1, #pts - 1 do
        local p0 = pts[math.max(1, i - 1)]
        local p1 = pts[i]
        local p2 = pts[math.min(#pts, i + 1)]
        local p3 = pts[math.min(#pts, i + 2)]
        for j = 0, n - 1 do
            out[#out + 1] = catmullRom(p0, p1, p2, p3, j / n)
        end
    end
    out[#out + 1] = pts[#pts]
    return out
end

local function pathLength(pts)
    local len = 0
    for i = 2, #pts do
        local dx, dy = pts[i][1] - pts[i-1][1], pts[i][2] - pts[i-1][2]
        len = len + math.sqrt(dx * dx + dy * dy)
    end
    return len
end

--============================================================
-- TỌA ĐỘ MẪU CHỮ "qhun22"
--
-- Hệ toạ độ nội bộ:  x = 0 → 270,  y = -17 → 58
-- Mỗi bảng {} bên trong = một nét liền (nhấc bút → bảng mới).
-- Thêm/bớt điểm {x, y} để chỉnh hình dáng — Catmull-Rom tự bo cong.
--============================================================
local TEMPLATE = {
    -- ═══ q ═══
    -- Nét 1: vòng tròn thân chữ (ngược kim đồng hồ từ phải)
    { {27,13},{23,2},{13,-2},{3,2},{0,13},
      {0,23},{5,32},{15,35},{25,32},{30,23},{27,13} },
    -- Nét 2: đuôi descender
    { {28,-2},{28,25},{28,53},{33,58} },

    -- ═══ h ═══
    -- Nét 3: thanh dọc (ascender → baseline)
    { {57,-17},{57,15},{57,33} },
    -- Nét 4: vòm sang phải
    { {57,17},{63,5},{70,1},{80,5},{85,20},{85,33} },

    -- ═══ u ═══
    -- Nét 5: xuống — cong đáy — lên
    { {105,0},{105,23},{108,32},{115,35},{125,32},{130,23},{130,0} },

    -- ═══ n ═══
    -- Nét 6: thanh dọc
    { {150,0},{150,20},{150,33} },
    -- Nét 7: vòm sang phải
    { {150,17},{155,7},{165,2},{175,7},{180,20},{180,33} },

    -- ═══ 2 (lần 1) ═══
    -- Nét 8: cong trên → chéo xuống → gạch ngang
    { {197,5},{203,-2},{213,-4},{220,1},{222,9},
      {219,17},{209,27},{197,35},{225,35} },

    -- ═══ 2 (lần 2) ═══
    -- Nét 9: dịch sang phải
    { {242,5},{248,-2},{258,-4},{265,1},{267,9},
      {264,17},{254,27},{242,35},{270,35} },
}

--============================================================
-- Xây dựng nét vẽ từ TEMPLATE → toạ độ màn hình
--============================================================
local function buildStrokes()
    local W, H = love.graphics.getDimensions()
    local cx = CONFIG.safePaddingX + (W - CONFIG.safePaddingX * 2) / 2
    local cy = CONFIG.safePaddingY + (H - CONFIG.safePaddingY * 2) / 2
    local s  = CONFIG.scale
    local ox = cx - 135 * s    -- 135 = nửa chiều rộng mẫu
    local oy = cy - 18 * s     -- 18 ≈ tâm Y thị giác

    gapLen = CONFIG.drawSpeed * CONFIG.gapDuration

    strokes      = {}
    strokeLens   = {}
    strokeStarts = {}
    totalLen     = 0

    for i, tmpl in ipairs(TEMPLATE) do
        local ctrl = {}
        for j, p in ipairs(tmpl) do
            ctrl[j] = { ox + p[1] * s, oy + p[2] * s }
        end
        local smooth = subdivide(ctrl, CONFIG.subdivisions)
        strokes[i]      = smooth
        strokeLens[i]   = pathLength(smooth)
        if i > 1 then totalLen = totalLen + gapLen end
        strokeStarts[i] = totalLen
        totalLen        = totalLen + strokeLens[i]
    end
end

--============================================================
-- LOVE CALLBACKS
--============================================================
function love.load()
    love.graphics.setBackgroundColor(0, 0, 0)
    love.graphics.setLineJoin("bevel")
    love.graphics.setLineStyle("smooth")
    buildStrokes()
end

function love.resize()
    buildStrokes()
end

function love.update(dt)
    if phase == PHASE.FADE_IN then
        fadeTimer = fadeTimer + dt
        if fadeTimer >= CONFIG.fadeDuration then
            phase = PHASE.DRAWING
        end
    elseif phase == PHASE.DRAWING then
        drawnLen = drawnLen + CONFIG.drawSpeed * dt
        if drawnLen >= totalLen then
            drawnLen = totalLen
            phase = PHASE.HOLD
        end
    elseif phase == PHASE.HOLD then
        holdTimer = holdTimer + dt
        if holdTimer >= CONFIG.holdDuration then
            phase = PHASE.DONE
            introComplete = true
        end
    end
end

function love.draw()
    love.graphics.clear(0, 0, 0)

    local penX, penY

    -- ── Fade-in: chấm sáng nhỏ tại điểm bắt đầu ──
    if phase == PHASE.FADE_IN then
        local t = math.min(fadeTimer / CONFIG.fadeDuration, 1)
        local pt = strokes[1] and strokes[1][1]
        if pt and CONFIG.penGlow then
            love.graphics.setColor(1, 1, 1, t * 0.6)
            love.graphics.circle("fill", pt[1], pt[2], CONFIG.strokeWidth * 0.7)
            love.graphics.setColor(1, 1, 1, t * 0.1)
            love.graphics.circle("fill", pt[1], pt[2], CONFIG.penGlowSize * 1.5)
        end
        return
    end

    -- ── Vẽ nét chữ ──
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(CONFIG.strokeWidth)

    local lastIdx = 0
    for i, pts in ipairs(strokes) do
        if drawnLen < strokeStarts[i] then break end
        lastIdx = i

        local dist = math.min(drawnLen - strokeStarts[i], strokeLens[i])
        local flat = { pts[1][1], pts[1][2] }
        penX, penY = pts[1][1], pts[1][2]
        local acc = 0

        for j = 2, #pts do
            local dx = pts[j][1] - pts[j-1][1]
            local dy = pts[j][2] - pts[j-1][2]
            local seg = math.sqrt(dx * dx + dy * dy)
            if acc + seg > dist then
                local t = (dist - acc) / seg
                local ex = pts[j-1][1] + dx * t
                local ey = pts[j-1][2] + dy * t
                flat[#flat + 1] = ex
                flat[#flat + 1] = ey
                penX, penY = ex, ey
                break
            end
            acc = acc + seg
            flat[#flat + 1] = pts[j][1]
            flat[#flat + 1] = pts[j][2]
            penX, penY = pts[j][1], pts[j][2]
        end

        if #flat >= 4 then
            love.graphics.line(flat)
        elseif #flat == 2 then
            love.graphics.circle("fill", flat[1], flat[2], CONFIG.strokeWidth / 2)
        end
    end

    -- ── Pen glow ──
    if CONFIG.penGlow and penX and phase == PHASE.DRAWING then
        if lastIdx > 0 and lastIdx < #strokes then
            local sEnd   = strokeStarts[lastIdx] + strokeLens[lastIdx]
            local nStart = strokeStarts[lastIdx + 1]
            if drawnLen > sEnd and drawnLen < nStart and nStart > sEnd then
                local t    = (drawnLen - sEnd) / (nStart - sEnd)
                local from = strokes[lastIdx][#strokes[lastIdx]]
                local to   = strokes[lastIdx + 1][1]
                penX = from[1] + (to[1] - from[1]) * t
                penY = from[2] + (to[2] - from[2]) * t
            end
        end
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.circle("fill", penX, penY, CONFIG.penGlowSize * 0.5)
        love.graphics.setColor(1, 1, 1, 0.1)
        love.graphics.circle("fill", penX, penY, CONFIG.penGlowSize)
    end

    if introComplete then
        love.graphics.setColor(1, 1, 1, 0.2)
        love.graphics.print("[Space = replay · Esc = quit]", 10, love.graphics.getHeight() - 18)
    end
end

--============================================================
-- PHÍM TẮT
--============================================================
function love.keypressed(key)
    if key == "escape" then love.event.quit() end
    if key == "space" then
        if introComplete then
            phase = PHASE.FADE_IN
            fadeTimer    = 0
            holdTimer    = 0
            drawnLen     = 0
            introComplete = false
        else
            drawnLen     = totalLen
            phase        = PHASE.DONE
            introComplete = true
        end
    end
end

-- Màn hình chính gọi hàm này để kiểm tra intro đã xong chưa
function isIntroComplete()
    return introComplete
end
