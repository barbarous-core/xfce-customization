-- =============================================================================
-- panel_right.lua
-- Mono Player — GBA-style Conky Theme
-- https://github.com/YOUR_USERNAME/mono-player
--
-- Right panel: clock, date, CPU temperatures, system stats, top processes.
-- Requires: gba_core.lua in the same directory.
-- License:  MIT
-- =============================================================================

require 'cairo'

-- Load shared library (adjust path if needed)
local core = dofile(os.getenv("HOME") .. "/.conky/MonoPlayer/lua/gba_core.lua")

local _draw_count_r = 0

-- ---------------------------------------------------------------------------
-- PANEL GEOMETRY
-- Adjust these values to match your conkyrc gap_x / gap_y / minimum_width
-- ---------------------------------------------------------------------------

local PX       = 0      -- relativo alla finestra Conky (gap_x/gap_y gestiscono la posizione assoluta)
local PY       = 0      -- relativo alla finestra Conky
local PW       = 340    -- panel width
local PH       = 1020   -- panel height
local PAD      = 14     -- inner horizontal padding
local NOTCH    = 7      -- corner notch size

-- Derived inner geometry
local IX  = PX + PAD          -- inner content left
local IW  = PW - PAD * 2      -- inner content width
local CX  = PX + PW / 2       -- panel horizontal centre

-- ---------------------------------------------------------------------------
-- COLOUR ALIASES (right panel = brick orange family)
-- ---------------------------------------------------------------------------

local C     = core.color
local BG    = C.bg_right
local ACC   = C.accent_right
local T_HI  = C.text_right_hi
local T_MID = C.text_right_mid
local T_LO  = C.text_right_lo
local HDR   = C.bg_header_r

-- ---------------------------------------------------------------------------
-- HELPERS
-- ---------------------------------------------------------------------------

-- Centre a string horizontally within the panel using Cairo text extents.
local function draw_centered(cr, text, y, col, font_name, font_size, alpha)
    alpha     = alpha or 1.0
    font_name = font_name or core.font.mono
    font_size = font_size or core.font.size_md
    cairo_select_font_face(cr, font_name, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD)
    cairo_set_font_size(cr, font_size)
    core.set_color(cr, col, alpha)
    local te = cairo_text_extents(cr, text)
    cairo_move_to(cr, CX - te.width / 2 - te.x_bearing, y)
    cairo_show_text(cr, text)
end

-- Draw a labelled HP bar with percentage label on the right.
local function stat_bar(cr, y, label, value, max_val, segments)
    local label_w = 62
    local bar_x   = IX + label_w
    local bar_w   = IW - label_w - 36   -- leave room for % label
    local bar_h   = 10
    local pct     = math.max(0, math.min(100, value / max_val * 100))
    local pct_str = string.format("%d%%", math.floor(pct))

    -- Row label
    cairo_select_font_face(cr, core.font.mono, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr, core.font.size_sm)
    core.set_color(cr, T_LO, 0.9)
    cairo_move_to(cr, IX, y + bar_h - 1)
    cairo_show_text(cr, label)

    -- Bar
    core.hp_bar(cr, bar_x, y, bar_w, bar_h,
        value, max_val, ACC, C.bar_bg, segments, pct_str, T_LO)
end

-- Draw a temperature row: label + value with dynamic colour.
local function temp_row(cr, y, label, temp_str, temp_val, max_temp)
    max_temp  = max_temp or 90
    local norm = core.clamp((temp_val - 30) / (max_temp - 30), 0, 1)
    local tcol = core.temp_color(norm)

    cairo_select_font_face(cr, core.font.mono, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr, core.font.size_sm)

    -- Label
    core.set_color(cr, T_LO, 0.8)
    cairo_move_to(cr, IX, y)
    cairo_show_text(cr, label)

    -- Value (right-aligned, heat-coloured)
    core.set_color(cr, tcol, 1.0)
    local te = cairo_text_extents(cr, temp_str)
    cairo_move_to(cr, IX + IW - te.width - te.x_bearing, y)
    cairo_show_text(cr, temp_str)
end

-- ---------------------------------------------------------------------------
-- MAIN DRAW FUNCTION
-- Called by Conky on every update cycle via conky_draw_right().
-- ---------------------------------------------------------------------------

function conky_draw_right()
    -- Guard: wait until Conky internals are ready
    if conky_window == nil then return end
    _draw_count_r = _draw_count_r + 1
    if _draw_count_r < 3 then return end
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
    -- 2. CLOCK
    -- -----------------------------------------------------------------------

    local clock_y = PY + 58
    local time_str = conky_parse("${time %H:%M:%S}")
    draw_centered(cr, time_str, clock_y, ACC, core.font.mono, core.font.size_xl)

    -- Thin underline below clock
    core.divider(cr, IX, clock_y + 10, IW, ACC, 0.3)

    -- Date row
    local date_str = conky_parse("${time %A %d %B %Y}")
    draw_centered(cr, date_str, clock_y + 32, T_LO, core.font.mono, core.font.size_xs)

    -- -----------------------------------------------------------------------
    -- 3. CPU TEMPERATURES
    -- -----------------------------------------------------------------------

    local temp_top = PY + 118
    core.section_header(cr, IX, temp_top, IW, "-- CPU TEMPERATURE --",
        HDR, ACC, core.font.mono, core.font.size_xs)

    local function parse_temp(raw)
        local n = tonumber(raw:match("[%d%.]+")) or 0
        return n, string.format("+%.1f°C", n)
    end

    local t_pkg_raw  = conky_parse("${hwmon 3 temp 1}")
    local t_c0_raw   = conky_parse("${hwmon 3 temp 2}")
    local t_c1_raw   = conky_parse("${hwmon 3 temp 3}")
    local t_c2_raw   = conky_parse("${hwmon 3 temp 4}")
    local t_c3_raw   = conky_parse("${hwmon 3 temp 5}")

    local t_pkg_val, t_pkg_str = parse_temp(t_pkg_raw)
    local t_c0_val,  t_c0_str  = parse_temp(t_c0_raw)
    local t_c1_val,  t_c1_str  = parse_temp(t_c1_raw)
    local t_c2_val,  t_c2_str  = parse_temp(t_c2_raw)
    local t_c3_val,  t_c3_str  = parse_temp(t_c3_raw)

    local tr = temp_top + 26
    local row_h = 26

    temp_row(cr, tr,           "Package   ", t_pkg_str, t_pkg_val)
    temp_row(cr, tr + row_h,   "Core 0    ", t_c0_str,  t_c0_val)
    temp_row(cr, tr + row_h*2, "Core 1    ", t_c1_str,  t_c1_val)
    temp_row(cr, tr + row_h*3, "Core 2    ", t_c2_str,  t_c2_val)
    temp_row(cr, tr + row_h*4, "Core 3    ", t_c3_str,  t_c3_val)

    core.divider(cr, IX, tr + row_h * 5 + 4, IW, ACC, 0.2)

    -- -----------------------------------------------------------------------
    -- 4. TOP PROCESSES
    -- -----------------------------------------------------------------------

    local proc_top = tr + row_h * 5 + 14
    core.section_header(cr, IX, proc_top, IW, "-- PROCESSES --",
        HDR, ACC, core.font.mono, core.font.size_xs)

    -- Column headers
    local pr = proc_top + 22
    cairo_select_font_face(cr, core.font.mono, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr, core.font.size_xs)
    core.set_color(cr, T_LO, 0.5)
    cairo_move_to(cr, IX, pr)
    cairo_show_text(cr, "Name")
    local pid_te = cairo_text_extents(cr, "PID")
    cairo_move_to(cr, IX + IW - pid_te.width - pid_te.x_bearing, pr)
    cairo_show_text(cr, "PID")

    core.divider(cr, IX, pr + 4, IW, ACC, 0.15)
    pr = pr + 22

    -- Top 5 processes by CPU
    for i = 1, 5 do
        local name = conky_parse(string.format("${top name %d}", i))
        local pid  = conky_parse(string.format("${top pid %d}",  i))
        local cpu  = tonumber(conky_parse(string.format("${top cpu %d}", i))) or 0

        -- Row background tint on hover-relevant rows (alternating alpha)
        local row_alpha = (i % 2 == 0) and 0.04 or 0.0
        if row_alpha > 0 then
            core.set_color(cr, ACC, row_alpha)
            cairo_rectangle(cr, IX - 2, pr - 10, IW + 4, 12)
            cairo_fill(cr)
        end

        -- Name (truncate at 16 chars to avoid overflow)
        name = name:gsub("^%s+", ""):gsub("%s+$", "")
        if #name > 16 then name = name:sub(1, 15) .. "~" end

        -- Colour by CPU load
        local load_col = core.temp_color(core.clamp(cpu / 50, 0, 1))

        cairo_select_font_face(cr, core.font.mono, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
        cairo_set_font_size(cr, core.font.size_sm)
        core.set_color(cr, load_col, 0.9)
        cairo_move_to(cr, IX, pr)
        cairo_show_text(cr, name)

        -- PID right-aligned
        pid = pid:gsub("%s+", "")
        core.set_color(cr, T_LO, 0.6)
        local te = cairo_text_extents(cr, pid)
        cairo_move_to(cr, IX + IW - te.width - te.x_bearing, pr)
        cairo_show_text(cr, pid)

        pr = pr + row_h
    end

    core.divider(cr, IX, pr + 2, IW, ACC, 0.2)

    -- -----------------------------------------------------------------------
    -- 5. SYSTEM STATS (uptime, frequency, RAM, SWAP, CPU bars)
    -- -----------------------------------------------------------------------

    local stats_top = pr + 22
    core.section_header(cr, IX, stats_top, IW, "-- SYSTEM --",
        HDR, ACC, core.font.mono, core.font.size_xs)

    local sy = stats_top + 28

    -- Uptime
    local uptime = conky_parse("${uptime}")
    core.data_row(cr, IX, sy, IW, "Uptime", uptime, T_LO, T_MID,
        core.font.mono, core.font.size_sm)
    sy = sy + row_h

    -- CPU frequency
    local freq = conky_parse("${freq_g cpu0}") .. " GHz"
    core.data_row(cr, IX, sy, IW, "Freq", freq, T_LO, T_MID,
        core.font.mono, core.font.size_sm)
    sy = sy + row_h + 4

    -- RAM bar  (value in MiB)
    local ram_used = tonumber(conky_parse("${memused_s}")) or 0
    local ram_max  = tonumber(conky_parse("${memmax_s}"))  or 1
    local ram_lbl  = conky_parse("${mem}") .. "/" .. conky_parse("${memmax}")
    stat_bar(cr, sy, "RAM  ", ram_used, ram_max, 20)
    sy = sy + row_h + 4

    -- SWAP bar
    local swp_used = tonumber(conky_parse("${swapused_s}")) or 0
    local swp_max  = tonumber(conky_parse("${swapmax_s}"))  or 1
    stat_bar(cr, sy, "SWAP ", swp_used, swp_max, 20)
    sy = sy + row_h + 4

    -- CPU usage bar
    local cpu_val = tonumber(conky_parse("${cpu cpu0}")) or 0
    stat_bar(cr, sy, "CPU  ", cpu_val, 100, 20)
    sy = sy + row_h + 8

    -- Process count
    local procs = conky_parse("${processes}")
    core.data_row(cr, IX, sy, IW, "Processes", procs, T_LO, T_MID,
        core.font.mono, core.font.size_sm)

    -- -----------------------------------------------------------------------
    -- 6. FOOTER
    -- -----------------------------------------------------------------------

    local footer_y = PY + PH - 24
    core.divider(cr, IX, footer_y - 6, IW, ACC, 0.2)
    draw_centered(cr, "[ STATUS OK ]", footer_y, T_LO,
        core.font.mono, core.font.size_xs, 0.6)

    -- Cleanup Cairo resources
    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end
