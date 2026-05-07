-- =============================================================================
-- panel_center.lua
-- Mono Player — GBA-style Conky Theme
-- https://github.com/YOUR_USERNAME/mono-player
--
-- Center panel: calendar, MOCP player (title, artist, album, progress).
-- Requires: gba_core.lua in the same directory.
-- License:  MIT
-- =============================================================================

require 'cairo'

local core = dofile(os.getenv("HOME") .. "/.conky/MonoPlayer/lua/gba_core.lua")

local _draw_count_c = 0

-- ---------------------------------------------------------------------------
-- PANEL GEOMETRY
-- Centered horizontally. Adjust PX to taste.
-- ---------------------------------------------------------------------------

local PX    = 0      -- relativo alla finestra Conky (gap_x/gap_y gestiscono la posizione assoluta)
local PY    = 0      -- relativo alla finestra Conky
local PW    = 320    -- panel width
local PH    = 1020   -- panel height
local PAD   = 14     -- inner horizontal padding
local NOTCH = 7

local IX = PX + PAD
local IW = PW - PAD * 2
local CX = PX + PW / 2

-- ---------------------------------------------------------------------------
-- COLOUR ALIASES (center panel = dusty violet family)
-- ---------------------------------------------------------------------------

local C     = core.color
local BG    = C.bg_center
local ACC   = C.accent_center
local T_HI  = C.text_center_hi
local T_MID = C.text_center_mid
local T_LO  = C.text_center_lo
local HDR   = C.bg_header_c

-- ---------------------------------------------------------------------------
-- CALENDAR DATA
-- Returns a table describing the current month for rendering.
-- ---------------------------------------------------------------------------

local function build_calendar()
    local now     = os.time()
    local today   = tonumber(os.date("%d", now))
    local month   = tonumber(os.date("%m", now))
    local year    = tonumber(os.date("%Y", now))

    -- First weekday of the month (0=Sun..6=Sat → remap to Mon-based 1..7)
    local first_t  = os.time({ year=year, month=month, day=1 })
    local first_wd = tonumber(os.date("%w", first_t))   -- 0=Sun
    -- Convert to Monday-first (Mon=1 … Sun=7)
    local offset = (first_wd == 0) and 7 or first_wd

    -- Days in month
    local next_month = os.time({ year=year, month=month+1, day=1 })
    local days_in_month = os.date("%d", next_month - 86400)

    return {
        today         = today,
        month         = month,
        year          = year,
        month_name    = os.date("%B %Y", now):upper(),
        offset        = offset,   -- 1=Mon … 7=Sun (how many cells to skip)
        days          = tonumber(days_in_month),
    }
end

-- ---------------------------------------------------------------------------
-- MOCP HELPERS
-- Data is fetched via mocp_data.py (single call, key=value output).
-- ---------------------------------------------------------------------------

local MOCP_SCRIPT = os.getenv("HOME") .. "/.conky/MonoPlayer/mocp_data.py"

-- Parse key=value block → table
local function parse_kv(raw)
    local t = {}
    for line in (raw .. "\n"):gmatch("([^\n]*)\n") do
        local k, v = line:match("^([^=]+)=(.*)$")
        if k then t[k] = v end
    end
    return t
end

-- Format seconds → "mm:ss"
local function fmt_time(secs)
    secs = math.max(0, math.floor(secs))
    return string.format("%d:%02d", math.floor(secs / 60), secs % 60)
end

-- Format seconds → "mm:ss"
local function fmt_time(secs)
    secs = math.max(0, math.floor(secs))
    return string.format("%d:%02d", math.floor(secs / 60), secs % 60)
end

-- ---------------------------------------------------------------------------
-- DRAW HELPERS
-- ---------------------------------------------------------------------------

local function draw_centered(cr, text, y, col, bold, font_size, alpha)
    alpha     = alpha or 1.0
    font_size = font_size or core.font.size_md
    local weight = bold and CAIRO_FONT_WEIGHT_BOLD or CAIRO_FONT_WEIGHT_NORMAL
    cairo_select_font_face(cr, core.font.mono, CAIRO_FONT_SLANT_NORMAL, weight)
    cairo_set_font_size(cr, font_size)
    core.set_color(cr, col, alpha)
    local te = cairo_text_extents(cr, text)
    cairo_move_to(cr, CX - te.width / 2 - te.x_bearing, y)
    cairo_show_text(cr, text)
end

local function draw_left(cr, text, y, col, font_size, alpha)
    alpha     = alpha or 1.0
    font_size = font_size or core.font.size_sm
    cairo_select_font_face(cr, core.font.mono, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr, font_size)
    core.set_color(cr, col, alpha)
    cairo_move_to(cr, IX, y)
    cairo_show_text(cr, text)
end

-- ---------------------------------------------------------------------------
-- MAIN DRAW FUNCTION
-- ---------------------------------------------------------------------------

function conky_draw_center()
    if conky_window == nil then return end
    _draw_count_c = _draw_count_c + 1
    if _draw_count_c < 3 then return end
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
    -- 2. CALENDAR
    -- -----------------------------------------------------------------------

    local cal_header_y = PY + 22
    core.section_header(cr, IX, cal_header_y, IW, "-- CALENDAR --",
        HDR, ACC, core.font.mono, core.font.size_xs)

    -- Month + year centred
    local cal = build_calendar()
    draw_centered(cr, cal.month_name, cal_header_y + 42, T_MID, true, core.font.size_sm)

    -- Day-of-week header row
    local days_short = {"MO", "TU", "WE", "TH", "FR", "SA", "SU"}
    local cell_w  = math.floor(IW / 7)
    local cell_h  = 22
    local grid_x  = IX
    local grid_y  = cal_header_y + 60

    cairo_select_font_face(cr, core.font.mono, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr, core.font.size_xs)

    for i, d in ipairs(days_short) do
        local cx = grid_x + (i - 1) * cell_w + cell_w / 2
        core.set_color(cr, T_LO, 0.5)
        local te = cairo_text_extents(cr, d)
        cairo_move_to(cr, cx - te.width / 2 - te.x_bearing, grid_y)
        cairo_show_text(cr, d)
    end

    -- Thin rule under day headers
    core.divider(cr, IX, grid_y + 4, IW, ACC, 0.2)

    -- Day numbers grid
    local day_y   = grid_y + cell_h
    local cell_n  = 1                      -- cell counter (1..42)
    local day_num = 1

    -- Fill leading empty cells
    cell_n = cal.offset

    cairo_set_font_size(cr, core.font.size_sm)

    while day_num <= cal.days do
        local col_idx = (cell_n - 1) % 7   -- 0..6
        local row_idx = math.floor((cell_n - 1) / 7)
        local cx = grid_x + col_idx * cell_w + cell_w / 2
        local cy = day_y + row_idx * cell_h

        local day_str = tostring(day_num)

        if day_num == cal.today then
            -- Highlight today: filled accent square behind the number
            local sq = cell_w - 2
            core.set_color(cr, ACC, 0.35)
            cairo_rectangle(cr,
                cx - sq / 2, cy - cell_h + 3,
                sq, cell_h - 1)
            cairo_fill(cr)
            core.set_color(cr, C.white, 1.0)
        elseif col_idx == 5 or col_idx == 6 then
            -- Weekend: slightly dimmer violet
            core.set_color(cr, T_LO, 0.6)
        else
            core.set_color(cr, T_MID, 0.85)
        end

        local te = cairo_text_extents(cr, day_str)
        cairo_move_to(cr, cx - te.width / 2 - te.x_bearing, cy)
        cairo_show_text(cr, day_str)

        day_num = day_num + 1
        cell_n  = cell_n  + 1
    end

    local cal_bottom = day_y + math.ceil((cal.offset - 1 + cal.days) / 7) * cell_h + 6
    core.divider(cr, IX, cal_bottom, IW, ACC, 0.2)

    -- -----------------------------------------------------------------------
    -- 3. MOCP PLAYER
    -- -----------------------------------------------------------------------

    local pl_y = cal_bottom + 24
    core.section_header(cr, IX, pl_y, IW, "-- MOCP PLAYER --",
        HDR, ACC, core.font.mono, core.font.size_xs)
    pl_y = pl_y + 36

    -- Fetch all MOCP data in a single script call
    local raw_mocp = conky_parse("${execi 2 python3 " .. MOCP_SCRIPT .. " 2>/dev/null}")
    local md       = parse_kv(raw_mocp)

    local state  = (md["STATE"]  or "STOP"):gsub("%s+", "")
    local title  = md["TITLE"]  or ""
    local artist = md["ARTIST"] or ""
    local album  = md["ALBUM"]  or ""
    local cur_secs = tonumber(md["CURRSEC"]) or 0
    local tot_secs = tonumber(md["TOTSEC"])  or 0
    local progress = (tot_secs > 0) and (cur_secs / tot_secs) or 0

    title  = (title  ~= "" and title  or "No title")
    artist = (artist ~= "" and artist or "Unknown" )
    album  = (album  ~= "" and album  or "---"     )

    -- State indicator
    local state_glyph = "[ STOP ]"
    local state_col   = T_LO
    if state == "PLAY" then
        state_glyph = "[ PLAY ]"
        state_col   = ACC
    elseif state == "PAUSE" then
        state_glyph = "[ PAUSE ]"
        state_col   = T_MID
    end
    draw_centered(cr, state_glyph, pl_y, state_col, true, core.font.size_sm)
    pl_y = pl_y + 30

    core.divider(cr, IX, pl_y, IW, ACC, 0.12)
    pl_y = pl_y + 22

    -- Helper: label left (xs), value right of it (sm), truncated to fit
    local function player_row(label, value, y)
        cairo_select_font_face(cr, core.font.mono, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
        cairo_set_font_size(cr, core.font.size_xs)
        core.set_color(cr, T_LO, 0.6)
        cairo_move_to(cr, IX, y)
        cairo_show_text(cr, label)
        local lw = cairo_text_extents(cr, label).width + 6
        cairo_set_font_size(cr, core.font.size_sm)
        core.set_color(cr, T_HI, 0.9)
        local max_c = math.floor((IW - lw) / 7)
        local v = value:gsub("^%s+", ""):gsub("%s+$", "")
        if #v > max_c then v = v:sub(1, max_c - 1) .. "~" end
        cairo_move_to(cr, IX + lw, y)
        cairo_show_text(cr, v)
    end

    player_row("TTL  ", title,  pl_y) pl_y = pl_y + 26
    player_row("ART  ", artist, pl_y) pl_y = pl_y + 26
    player_row("ALB  ", album,  pl_y) pl_y = pl_y + 30

    -- Progress bar
    local bar_h = 14
    core.hp_bar(cr, IX, pl_y, IW, bar_h,
        progress, 1.0, ACC, C.bar_bg, 28, nil, nil)

    -- Pixel cursor
    if progress > 0 and progress < 1 then
        local cursor_x = IX + progress * IW - 1
        core.set_color(cr, C.white, 0.9)
        cairo_rectangle(cr, cursor_x, pl_y, 2, bar_h)
        cairo_fill(cr)
    end

    pl_y = pl_y + bar_h + 8

    -- Time display
    local time_str = fmt_time(cur_secs) .. " / " .. fmt_time(tot_secs)
    draw_centered(cr, time_str, pl_y, T_LO, false, core.font.size_xs)
    pl_y = pl_y + 22

    -- -----------------------------------------------------------------------
    -- 4. BATTERY
    -- -----------------------------------------------------------------------

    core.divider(cr, IX, pl_y, IW, ACC, 0.2) pl_y = pl_y + 10
    core.section_header(cr, IX, pl_y, IW, "-- BATTERY --",
        HDR, ACC, core.font.mono, core.font.size_xs)
    pl_y = pl_y + 36

    local bat_pct    = tonumber(conky_parse("${battery_percent BAT1}")) or 0
    local bat_status = conky_parse("${battery_status BAT1}"):gsub("%s+","")
    local bat_time   = conky_parse("${battery_time BAT1}"):gsub("^%s+",""):gsub("%s+$","")

    -- Health from sysfs
    local bat_health = 0
    do
        local ef  = io.open("/sys/class/power_supply/BAT1/energy_full")
        local efd = io.open("/sys/class/power_supply/BAT1/energy_full_design")
        if ef and efd then
            local full        = tonumber(ef:read("*n"))  or 1
            local full_design = tonumber(efd:read("*n")) or 1
            bat_health = math.floor(full / full_design * 100)
            ef:close(); efd:close()
        end
    end

    -- Charge bar (colour shifts green→orange→red by remaining %)
    local charge_col = bat_pct > 50 and ACC or (bat_pct > 20 and T_MID or C.white)
    core.hp_bar(cr, IX, pl_y, IW, 10, bat_pct, 100, charge_col, C.bar_bg, 20, nil, nil)
    pl_y = pl_y + 26

    -- Status + percentage
    local status_str = bat_status
    if bat_time ~= "" and bat_time ~= "unknown" then
        status_str = bat_status .. "  " .. bat_time
    end
    core.data_row(cr, IX, pl_y, IW, "STATUS", status_str, T_LO, T_MID,
        core.font.mono, core.font.size_sm)
    pl_y = pl_y + 22

    local health_col = bat_health >= 80 and T_MID or (bat_health >= 60 and T_LO or C.white)
    core.data_row(cr, IX, pl_y, IW,
        string.format("CHARGE  %d%%", bat_pct),
        string.format("HEALTH  %d%%", bat_health),
        T_LO, health_col, core.font.mono, core.font.size_sm)
    pl_y = pl_y + 24

    -- -----------------------------------------------------------------------
    -- 5. DISK
    -- -----------------------------------------------------------------------

    core.divider(cr, IX, pl_y, IW, ACC, 0.2) pl_y = pl_y + 10
    core.section_header(cr, IX, pl_y, IW, "-- DISK --",
        HDR, ACC, core.font.mono, core.font.size_xs)
    pl_y = pl_y + 36

    local disk_pct  = tonumber(conky_parse("${fs_used_perc /}")) or 0
    local disk_used = conky_parse("${fs_used /}"):gsub("%s+","")
    local disk_size = conky_parse("${fs_size /}"):gsub("%s+","")
    local disk_free = conky_parse("${fs_free /}"):gsub("%s+","")

    local disk_col = disk_pct < 75 and ACC or (disk_pct < 90 and T_MID or C.white)
    core.hp_bar(cr, IX, pl_y, IW, 10, disk_pct, 100, disk_col, C.bar_bg, 20, nil, nil)
    pl_y = pl_y + 26

    core.data_row(cr, IX, pl_y, IW, "USED", disk_used .. " / " .. disk_size,
        T_LO, T_MID, core.font.mono, core.font.size_sm)
    pl_y = pl_y + 22
    core.data_row(cr, IX, pl_y, IW, "FREE", disk_free,
        T_LO, disk_col, core.font.mono, core.font.size_sm)
    pl_y = pl_y + 24

    -- -----------------------------------------------------------------------
    -- 6. FAN + NVMe
    -- -----------------------------------------------------------------------

    core.divider(cr, IX, pl_y, IW, ACC, 0.2) pl_y = pl_y + 10
    core.section_header(cr, IX, pl_y, IW, "-- HARDWARE --",
        HDR, ACC, core.font.mono, core.font.size_xs)
    pl_y = pl_y + 36

    local fan1 = tonumber(conky_parse("${hwmon 5 fan 1}")) or 0
    local fan2 = tonumber(conky_parse("${hwmon 5 fan 2}")) or 0
    local nvme_raw = conky_parse("${hwmon 3 temp 1}")
    local nvme_val = tonumber(nvme_raw:match("[%d%.]+")) or 0
    local nvme_str = string.format("+%.1f°C", nvme_val)

    local fan1_str = fan1 > 0 and string.format("%d RPM", fan1) or "idle"
    local fan2_str = fan2 > 0 and string.format("%d RPM", fan2) or "idle"

    core.data_row(cr, IX, pl_y, IW, "FAN 1", fan1_str, T_LO, T_MID,
        core.font.mono, core.font.size_sm) pl_y = pl_y + 22
    core.data_row(cr, IX, pl_y, IW, "FAN 2", fan2_str, T_LO, T_MID,
        core.font.mono, core.font.size_sm) pl_y = pl_y + 22

    local nvme_norm = core.clamp((nvme_val - 20) / (70 - 20), 0, 1)
    local nvme_col  = core.temp_color(nvme_norm)
    core.data_row(cr, IX, pl_y, IW, "NVMe", nvme_str, T_LO, nvme_col,
        core.font.mono, core.font.size_sm) pl_y = pl_y + 24

    -- -----------------------------------------------------------------------
    -- 7. TOP PROCESSES (by RAM)
    -- -----------------------------------------------------------------------

    core.divider(cr, IX, pl_y, IW, ACC, 0.2) pl_y = pl_y + 10
    core.section_header(cr, IX, pl_y, IW, "-- TOP RAM --",
        HDR, ACC, core.font.mono, core.font.size_xs)
    pl_y = pl_y + 36

    -- Column header
    cairo_select_font_face(cr, core.font.mono, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr, core.font.size_xs)
    core.set_color(cr, T_LO, 0.4)
    cairo_move_to(cr, IX, pl_y)
    cairo_show_text(cr, "Name")
    local mem_te = cairo_text_extents(cr, "RSS")
    cairo_move_to(cr, IX + IW - mem_te.width - mem_te.x_bearing, pl_y)
    cairo_show_text(cr, "RSS")
    pl_y = pl_y + 6
    core.divider(cr, IX, pl_y, IW, ACC, 0.12)
    pl_y = pl_y + 14

    -- Colour fades from T_HI (rank 1) to T_LO (rank 5)
    local rank_cols = { T_HI, T_MID, T_MID, T_LO, T_LO }
    local rank_alpha = { 0.95, 0.85, 0.75, 0.65, 0.55 }

    for i = 1, 5 do
        local name    = conky_parse(string.format("${top_mem name %d}", i))
        local mem_res = conky_parse(string.format("${top_mem mem_res %d}", i))

        name    = name:gsub("^%s+",""):gsub("%s+$","")
        mem_res = mem_res:gsub("^%s+",""):gsub("%s+$","")
        if #name > 16 then name = name:sub(1,15) .. "~" end

        cairo_select_font_face(cr, core.font.mono, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
        cairo_set_font_size(cr, core.font.size_sm)
        core.set_color(cr, rank_cols[i], rank_alpha[i])
        cairo_move_to(cr, IX, pl_y)
        cairo_show_text(cr, name)

        core.set_color(cr, T_LO, rank_alpha[i])
        local te = cairo_text_extents(cr, mem_res)
        cairo_move_to(cr, IX + IW - te.width - te.x_bearing, pl_y)
        cairo_show_text(cr, mem_res)

        pl_y = pl_y + 18
    end

    -- -----------------------------------------------------------------------
    -- 8. FOOTER
    -- -----------------------------------------------------------------------

    local footer_y = PY + PH - 24
    core.divider(cr, IX, footer_y - 6, IW, ACC, 0.2)
    draw_centered(cr, "[ MONO PLAYER ]", footer_y, T_LO,
        false, core.font.size_xs, 0.5)

    -- Cleanup
    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end
