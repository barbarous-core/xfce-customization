-- =============================================================================
-- panel_left.lua
-- Mono Player — GBA-style Conky Theme
--
-- Left panel: vnstat network monitor — driven by vnstat_data.py
-- Requires: gba_core.lua, vnstat_data.py in the theme directory.
-- License:  MIT
-- =============================================================================

require 'cairo'

local core = dofile(os.getenv("HOME") .. "/.conky/MonoPlayer/lua/gba_core.lua")

local _draw_count_l = 0

-- ---------------------------------------------------------------------------
-- PANEL GEOMETRY
-- ---------------------------------------------------------------------------

local PX    = 0
local PY    = 0
local PW    = 340
local PH    = 1020
local PAD   = 14
local NOTCH = 7

local IX = PX + PAD
local IW = PW - PAD * 2
local CX = PX + PW / 2

-- ---------------------------------------------------------------------------
-- COLOUR ALIASES (left panel = moss green family)
-- ---------------------------------------------------------------------------

local C     = core.color
local BG    = C.bg_left
local ACC   = C.accent_left
local T_HI  = C.text_left_hi
local T_MID = C.text_left_mid
local T_LO  = C.text_left_lo
local HDR   = C.bg_header

-- ---------------------------------------------------------------------------
-- HELPERS
-- ---------------------------------------------------------------------------

local SCRIPT = os.getenv("HOME") .. "/.conky/MonoPlayer/vnstat_data.py"

local function draw_centered(cr, text, y, col, font_size, alpha)
    alpha     = alpha or 1.0
    font_size = font_size or core.font.size_md
    cairo_select_font_face(cr, core.font.mono, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr, font_size)
    core.set_color(cr, col, alpha)
    local te = cairo_text_extents(cr, text)
    cairo_move_to(cr, CX - te.width / 2 - te.x_bearing, y)
    cairo_show_text(cr, text)
end

-- Parse key=value output from vnstat_data.py
local function parse_kv(raw)
    local t = {}
    for line in (raw .. "\n"):gmatch("([^\n]*)\n") do
        local k, v = line:match("^([^=]+)=(.*)$")
        if k then t[k] = v end
    end
    return t
end

-- Draw a labelled data row
local function row(cr, cy, label, value, lcol, vcol, fsize)
    fsize = fsize or core.font.size_sm
    cairo_select_font_face(cr, core.font.mono, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr, fsize)
    core.set_color(cr, lcol, 0.7)
    cairo_move_to(cr, IX, cy)
    cairo_show_text(cr, label)
    core.set_color(cr, vcol, 1.0)
    local te = cairo_text_extents(cr, value)
    cairo_move_to(cr, IX + IW - te.width - te.x_bearing, cy)
    cairo_show_text(cr, value)
end

-- ---------------------------------------------------------------------------
-- MAIN DRAW FUNCTION
-- ---------------------------------------------------------------------------

function conky_draw_left()
    if conky_window == nil then return end
    _draw_count_l = _draw_count_l + 1
    if _draw_count_l < 3 then return end
    if conky_window.width <= 0 or conky_window.height <= 0 then return end

    -- Detect surface creation function
    local cs = nil
    if cairo_xlib_surface_create ~= nil then
        cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height)
    end

    if cs == nil then return end
    local cr = cairo_create(cs)
    if cr == nil then 
        cairo_surface_destroy(cs)
        return 
    end

    -- -----------------------------------------------------------------------
    -- 1. PANEL FRAME
    -- -----------------------------------------------------------------------

    core.pixel_box(cr, PX, PY, PW, PH, NOTCH, BG, ACC, 0.82)
    core.corner_accents(cr, PX, PY, PW, PH, NOTCH, ACC, 1.0)

    -- -----------------------------------------------------------------------
    -- 2. DATA  (from vnstat_data.py via execi)
    -- -----------------------------------------------------------------------

    local raw  = conky_parse("${execi 60 python3 " .. SCRIPT .. " 2>/dev/null}")
    local d    = parse_kv(raw)

    local iface     = d["IFACE"]     or "---"
    local daily_rx  = d["DAILY_RX"]  or "---"
    local daily_tx  = d["DAILY_TX"]  or "---"
    local daily_tot = d["DAILY_TOT"] or "---"
    local h_avg     = d["HOURLY_AVG"]   or "---"
    local h_max_h   = d["HOURLY_MAX_H"] or "--"
    local h_max     = d["HOURLY_MAX"]   or "---"
    local h_min_h   = d["HOURLY_MIN_H"] or "--"
    local h_min     = d["HOURLY_MIN"]   or "---"
    local n_hours   = tonumber(d["N_HOURS"])  or 0
    local n_window  = tonumber(d["N_WINDOW"]) or 0
    local scroll    = tonumber(d["SCROLL"])   or 0

    local m_rx   = d["MONTH_RX"]  or "---"
    local m_tx   = d["MONTH_TX"]  or "---"
    local m_tot  = d["MONTH_TOT"] or "---"
    local m_avg  = d["MONTH_AVG"] or "---"
    local m_max  = d["MONTH_MAX"] or "---"
    local m_min  = d["MONTH_MIN"] or "---"
    local m_days = d["N_MONTH_DAYS"] or "0"

    -- -----------------------------------------------------------------------
    -- 3. HEADER  — VNSTAT
    -- -----------------------------------------------------------------------

    local cy = PY + 22
    core.section_header(cr, IX, cy, IW, "-- VNSTAT --",
        HDR, ACC, core.font.mono, core.font.size_xs)
    cy = cy + 36

    row(cr, cy, "INTERFACE", iface,     T_LO, T_HI,  core.font.size_sm) cy = cy + 22
    row(cr, cy, "RX",        daily_rx,  T_LO, T_MID, core.font.size_sm) cy = cy + 22
    row(cr, cy, "TX",        daily_tx,  T_LO, T_MID, core.font.size_sm) cy = cy + 22
    row(cr, cy, "DAILY TOT", daily_tot, T_LO, T_HI,  core.font.size_md) cy = cy + 26

    -- -----------------------------------------------------------------------
    -- 4. HOURLY STATS
    -- -----------------------------------------------------------------------

    core.divider(cr, IX, cy, IW, ACC, 0.2) cy = cy + 10
    core.section_header(cr, IX, cy, IW, "-- HOURLY STATS --",
        HDR, ACC, core.font.mono, core.font.size_xs)
    cy = cy + 36

    row(cr, cy, "AVG",           h_avg,               T_LO, T_MID, core.font.size_sm) cy = cy + 22
    row(cr, cy, "MAX  H"..h_max_h, h_max,             T_LO, T_HI,  core.font.size_sm) cy = cy + 22
    row(cr, cy, "MIN  H"..h_min_h, h_min,             T_LO, T_MID, core.font.size_sm) cy = cy + 22
    row(cr, cy, "HOURS",         n_hours.." recorded", T_LO, T_LO,  core.font.size_xs) cy = cy + 22

    -- -----------------------------------------------------------------------
    -- 5. SPARKLINE  (10-hour scrolling window)
    -- -----------------------------------------------------------------------

    core.divider(cr, IX, cy, IW, ACC, 0.2) cy = cy + 10
    core.section_header(cr, IX, cy, IW, "-- GROWTH  [@"..scroll.."] --",
        HDR, ACC, core.font.mono, core.font.size_xs)
    cy = cy + 36

    -- Build spark values and labels from parsed data
    local spark_vals  = {}
    local spark_hours = {}
    local spark_flags = {}
    for i = 0, n_window - 1 do
        local raw_v = tonumber(d["H"..i.."_RAW"]) or 0
        table.insert(spark_vals,  raw_v)
        table.insert(spark_hours, d["H"..i.."_H"] or "??")
        table.insert(spark_flags, d["H"..i.."_FLAG"] or "")
    end

    if #spark_vals > 0 then
        local bar_h_spark = 52
        core.spark_bars(cr, IX, cy, IW, bar_h_spark, spark_vals, nil, ACC)

        -- hour labels below bars
        local bar_count = #spark_vals
        local bar_w = math.floor((IW - (bar_count - 1) * 2) / bar_count)
        local label_y = cy + bar_h_spark + 8

        cairo_select_font_face(cr, core.font.mono, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
        cairo_set_font_size(cr, core.font.size_xs)

        for i, hh in ipairs(spark_hours) do
            local lx = IX + (i-1) * (bar_w + 2) + bar_w / 2
            local lbl = "H" .. hh
            local flag = spark_flags[i]
            -- highlight max/min/current
            local lcol = T_LO
            local la   = 0.4
            if flag:find("M")  then lcol = T_HI;  la = 0.9 end
            if flag:find("m")  then lcol = T_MID; la = 0.7 end
            if flag:find(">")  then lcol = C.white; la = 1.0 end
            core.set_color(cr, lcol, la)
            local te = cairo_text_extents(cr, lbl)
            cairo_move_to(cr, lx - te.width / 2 - te.x_bearing, label_y)
            cairo_show_text(cr, lbl)
        end
        cy = label_y + 18
    else
        draw_centered(cr, "no data yet", cy + 26, T_LO, core.font.size_xs, 0.5)
        cy = cy + 72
    end

    -- -----------------------------------------------------------------------
    -- 6. HOURLY LOG TABLE
    -- -----------------------------------------------------------------------

    core.divider(cr, IX, cy, IW, ACC, 0.2) cy = cy + 10
    core.section_header(cr, IX, cy, IW, "-- HOURLY LOG --",
        HDR, ACC, core.font.mono, core.font.size_xs)
    cy = cy + 36

    -- Column header
    cairo_select_font_face(cr, core.font.mono, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr, core.font.size_xs)
    core.set_color(cr, T_LO, 0.4)
    cairo_move_to(cr, IX, cy)
    cairo_show_text(cr, "  H    RX         TX         TOT")
    cy = cy + 6
    core.divider(cr, IX, cy, IW, ACC, 0.12)
    cy = cy + 14

    for i = 0, n_window - 1 do
        local hh   = d["H"..i.."_H"]   or "--"
        local hrx  = d["H"..i.."_RX"]  or "---"
        local htx  = d["H"..i.."_TX"]  or "---"
        local htot = d["H"..i.."_TOT"] or "---"
        local flag = d["H"..i.."_FLAG"] or ""

        local marker = flag:find(">") and ">" or (flag:find("M") and "^" or (flag:find("m") and "v" or " "))
        local txt = string.format("%s H%s  %-9s  %-9s  %s", marker, hh, hrx, htx, htot)

        local col   = T_LO
        local alpha = 0.65
        if flag:find(">") then col = T_HI;  alpha = 0.95
        elseif flag:find("M") then col = ACC; alpha = 0.85
        elseif flag:find("m") then col = T_MID; alpha = 0.75
        end

        cairo_select_font_face(cr, core.font.mono, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
        cairo_set_font_size(cr, core.font.size_xs)
        core.set_color(cr, col, alpha)
        cairo_move_to(cr, IX, cy)
        cairo_show_text(cr, txt)
        cy = cy + 18
    end

    -- -----------------------------------------------------------------------
    -- 7. MONTHLY
    -- -----------------------------------------------------------------------

    cy = cy + 6
    core.divider(cr, IX, cy, IW, ACC, 0.2) cy = cy + 10
    core.section_header(cr, IX, cy, IW, "-- MONTHLY  ("..m_days.." days) --",
        HDR, ACC, core.font.mono, core.font.size_xs)
    cy = cy + 36

    row(cr, cy, "RX",  m_rx,  T_LO, T_MID, core.font.size_sm) cy = cy + 22
    row(cr, cy, "TX",  m_tx,  T_LO, T_MID, core.font.size_sm) cy = cy + 22
    row(cr, cy, "TOT", m_tot, T_LO, T_HI,  core.font.size_md) cy = cy + 26
    row(cr, cy, "AVG", m_avg, T_LO, T_MID, core.font.size_sm) cy = cy + 22
    row(cr, cy, "MAX", m_max, T_LO, T_HI,  core.font.size_sm) cy = cy + 22
    row(cr, cy, "MIN", m_min, T_LO, T_LO,  core.font.size_sm) cy = cy + 24

    -- -----------------------------------------------------------------------
    -- 8. LIVE SPEED
    -- -----------------------------------------------------------------------

    local IFACE_VAR = d["IFACE"] or "wlo1"
    core.divider(cr, IX, cy, IW, ACC, 0.2) cy = cy + 10
    core.section_header(cr, IX, cy, IW, "-- LIVE --",
        HDR, ACC, core.font.mono, core.font.size_xs)
    cy = cy + 36

    local dl_val = tonumber(conky_parse("${downspeedf " .. IFACE_VAR .. "}")) or 0
    local ul_val = tonumber(conky_parse("${upspeedf "   .. IFACE_VAR .. "}")) or 0
    local bar_max = 10240
    local bar_h   = 14
    local bar_x   = IX + 30
    local bar_w   = IW - 30 - 70

    cairo_select_font_face(cr, core.font.mono, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr, core.font.size_sm)

    core.set_color(cr, T_LO, 0.7)
    cairo_move_to(cr, IX, cy)
    cairo_show_text(cr, "DL")
    core.hp_bar(cr, bar_x, cy - bar_h + 2, bar_w, bar_h, dl_val, bar_max, ACC, C.bar_bg, 0, nil, nil)
    local dl_str = string.format("%7.1f KB/s", dl_val)
    core.set_color(cr, T_MID, 0.9)
    local te = cairo_text_extents(cr, dl_str)
    cairo_move_to(cr, IX + IW - te.width - te.x_bearing, cy)
    cairo_show_text(cr, dl_str)
    cy = cy + 24

    core.set_color(cr, T_LO, 0.7)
    cairo_move_to(cr, IX, cy)
    cairo_show_text(cr, "UL")
    core.hp_bar(cr, bar_x, cy - bar_h + 2, bar_w, bar_h, ul_val, bar_max, T_MID, C.bar_bg, 0, nil, nil)
    local ul_str = string.format("%7.1f KB/s", ul_val)
    core.set_color(cr, T_MID, 0.7)
    te = cairo_text_extents(cr, ul_str)
    cairo_move_to(cr, IX + IW - te.width - te.x_bearing, cy)
    cairo_show_text(cr, ul_str)
    cy = cy + 24

    local ip = conky_parse("${addr " .. IFACE_VAR .. "}")
    row(cr, cy, "IP",      ip,                          T_LO, T_MID, core.font.size_sm) cy = cy + 22
    row(cr, cy, "REFRESH", conky_parse("${time %H:%M:%S}"), T_LO, T_LO, core.font.size_xs)

    -- -----------------------------------------------------------------------
    -- 9. FOOTER
    -- -----------------------------------------------------------------------

    local footer_y = PY + PH - 24
    core.divider(cr, IX, footer_y - 8, IW, ACC, 0.2)
    draw_centered(cr, "[ NET MONITOR ONLINE ]", footer_y, T_LO,
        core.font.size_xs, 0.5)

    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end
