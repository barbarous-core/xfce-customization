-- =============================================================================
-- gba_core.lua
-- Shared drawing library for the GBA Conky Theme
-- https://github.com/YOUR_USERNAME/conky-gba-theme
--
-- Requires: Conky compiled with Lua + Cairo support
-- License:  MIT
-- =============================================================================

local M = {}

-- ---------------------------------------------------------------------------
-- COMPATIBILITY: cairo_text_extents in Conky 1.12.2 (tolua++ binding)
-- Note: Commented out for modern Conky (1.19+) compatibility.
-- ---------------------------------------------------------------------------
-- do
--     local _orig = cairo_text_extents
--     cairo_text_extents = function(cr, text)
--         local te = cairo_text_extents_t:create()
--         _orig(cr, text, te)
--         return te
--     end
-- end

-- ---------------------------------------------------------------------------
-- PALETTE
-- Three panel identities + shared neutrals.
-- All values are {r, g, b} in 0..1 range for Cairo.
-- ---------------------------------------------------------------------------

M.color = {
    -- Background layers
    bg_root      = {0.098, 0.098, 0.118},   -- #191919 desktop near-black
    bg_left      = {0.051, 0.102, 0.051},   -- #0D1A0D green-tinted dark
    bg_center    = {0.051, 0.051, 0.102},   -- #0D0D1A violet-tinted dark
    bg_right     = {0.102, 0.051, 0.051},   -- #1A0D0D red-tinted dark
    bg_header    = {0.102, 0.224, 0.102},   -- #1A3A1A header strip left
    bg_header_c  = {0.102, 0.102, 0.224},   -- #1A1A3A header strip center
    bg_header_r  = {0.165, 0.051, 0.051},   -- #2A0D0D header strip right

    -- Panel accent colours (borders, highlights, titles)
    accent_left   = {0.353, 0.478, 0.290},  -- #5A7A4A  moss green
    accent_center = {0.545, 0.482, 0.671},  -- #8B7BAB  dusty violet
    accent_right  = {0.784, 0.376, 0.251},  -- #C86040  brick orange

    -- Text colours per panel
    text_left_hi  = {0.478, 0.667, 0.416},  -- #7AAA6A  bright green text
    text_left_mid = {0.353, 0.478, 0.290},  -- #5A7A4A  mid green
    text_left_lo  = {0.290, 0.416, 0.290},  -- #4A6A4A  dim green

    text_center_hi  = {0.659, 0.722, 0.808}, -- #A8B8CE bright violet-white
    text_center_mid = {0.545, 0.482, 0.671}, -- #8B7BAB mid violet
    text_center_lo  = {0.416, 0.353, 0.541}, -- #6A5A8A dim violet

    text_right_hi  = {0.910, 0.627, 0.502},  -- #E8A080 bright orange-white
    text_right_mid = {0.784, 0.502, 0.376},  -- #C88060 mid orange
    text_right_lo  = {0.659, 0.353, 0.251},  -- #A86050 dim orange

    -- Shared bar background
    bar_bg  = {0.118, 0.059, 0.059},        -- #1E0F0F  dark bar trough
    bar_dim = {0.200, 0.100, 0.100},        -- #331A1A  slightly lighter

    -- Pure white for critical highlights
    white   = {1.0, 1.0, 1.0},
}

-- ---------------------------------------------------------------------------
-- TYPOGRAPHY CONSTANTS
--
-- The theme uses fonts that are native to Ubuntu and present in all
-- standard installations — no extra packages required.
--
-- PRIMARY:  "DejaVu Sans Mono"  — default on all Ubuntu releases,
--           compact and readable at small sizes, bold variant is solid.
-- FALLBACK: "Ubuntu Mono"       — more modern, slightly wider.
--
-- OPTIONAL PIXEL FONT (for enthusiasts):
--   Set USE_PIXEL_FONT = true and install Press Start 2P manually:
--   1. Download PressStart2P-Regular.ttf from Google Fonts
--   2. cp PressStart2P-Regular.ttf ~/.local/share/fonts/
--   3. fc-cache -fv
--   The theme will fall back to DejaVu Sans Mono if the font is missing.
-- ---------------------------------------------------------------------------

local USE_PIXEL_FONT = false   -- set true if Press Start 2P is installed

M.font = {
    pixel   = USE_PIXEL_FONT and "Press Start 2P" or "DejaVu Sans Mono",
    mono    = "DejaVu Sans Mono",  -- always native, used for dense data rows
    fallback = "Ubuntu Mono",      -- alternative if DejaVu is somehow missing
    size_xl = 42,                  -- clock display
    size_lg = 18,                  -- section titles / panel headers
    size_md = 15,                  -- standard data rows
    size_sm = 14,                  -- dense / secondary rows
    size_xs = 12,                   -- labels, footer, bar annotations
}

-- ---------------------------------------------------------------------------
-- HELPERS: colour application
-- ---------------------------------------------------------------------------

-- Apply a palette colour table {r,g,b} with optional alpha (default 1.0)
function M.set_color(cr, col, alpha)
    alpha = alpha or 1.0
    cairo_set_source_rgba(cr, col[1], col[2], col[3], alpha)
end

-- ---------------------------------------------------------------------------
-- PRIMITIVE: pixel-corner box
-- Draws a filled + stroked rectangle whose four corners have a square
-- pixel-art notch instead of rounded corners.
--   x, y        top-left origin
--   w, h        dimensions
--   notch       size of the corner square in pixels (default 6)
--   fill_col    {r,g,b} fill colour
--   stroke_col  {r,g,b} stroke colour
--   alpha       global alpha (default 1.0)
-- ---------------------------------------------------------------------------

function M.pixel_box(cr, x, y, w, h, notch, fill_col, stroke_col, alpha)
    notch = notch or 6
    alpha = alpha or 1.0

    -- Build notched path (clockwise, top-left notch first)
    cairo_new_path(cr)
    cairo_move_to(cr,  x + notch,  y)
    cairo_line_to(cr,  x + w - notch, y)
    cairo_line_to(cr,  x + w - notch, y + notch)
    cairo_line_to(cr,  x + w,         y + notch)
    cairo_line_to(cr,  x + w,         y + h - notch)
    cairo_line_to(cr,  x + w - notch, y + h - notch)
    cairo_line_to(cr,  x + w - notch, y + h)
    cairo_line_to(cr,  x + notch,     y + h)
    cairo_line_to(cr,  x + notch,     y + h - notch)
    cairo_line_to(cr,  x,             y + h - notch)
    cairo_line_to(cr,  x,             y + notch)
    cairo_line_to(cr,  x + notch,     y + notch)
    cairo_close_path(cr)

    -- Fill
    M.set_color(cr, fill_col, alpha)
    cairo_fill_preserve(cr)

    -- Stroke
    M.set_color(cr, stroke_col, alpha)
    cairo_set_line_width(cr, 0.8)
    cairo_stroke(cr)
end

-- ---------------------------------------------------------------------------
-- PRIMITIVE: corner accent squares
-- Draws the four filled corner squares that give the arcade-frame look.
-- Call AFTER pixel_box so accents sit on top.
-- ---------------------------------------------------------------------------

function M.corner_accents(cr, x, y, w, h, notch, col, alpha)
    notch = notch or 6
    alpha = alpha or 1.0
    M.set_color(cr, col, alpha)

    local corners = {
        {x,             y},
        {x + w - notch, y},
        {x,             y + h - notch},
        {x + w - notch, y + h - notch},
    }
    for _, c in ipairs(corners) do
        cairo_rectangle(cr, c[1], c[2], notch, notch)
        cairo_fill(cr)
    end
end

-- ---------------------------------------------------------------------------
-- PRIMITIVE: section divider (1px horizontal rule)
-- ---------------------------------------------------------------------------

function M.divider(cr, x, y, w, col, alpha)
    alpha = alpha or 0.4
    M.set_color(cr, col, alpha)
    cairo_set_line_width(cr, 0.5)
    cairo_move_to(cr, x, y)
    cairo_line_to(cr, x + w, y)
    cairo_stroke(cr)
end

-- ---------------------------------------------------------------------------
-- PRIMITIVE: section header strip
-- A thin filled rectangle with centred label text.
-- ---------------------------------------------------------------------------

function M.section_header(cr, x, y, w, label, bg_col, text_col, font_name, font_size)
    font_name = font_name or M.font.mono
    font_size = font_size or M.font.size_xs
    local h = font_size + 6

    -- Background strip
    M.set_color(cr, bg_col, 1.0)
    cairo_rectangle(cr, x, y, w, h)
    cairo_fill(cr)

    -- Centred label
    cairo_select_font_face(cr, font_name, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr, font_size)
    M.set_color(cr, text_col, 0.9)

    local te = cairo_text_extents(cr, label)
    local tx = x + (w - te.width) / 2 - te.x_bearing
    local ty = y + h / 2 - te.height / 2 - te.y_bearing
    cairo_move_to(cr, tx, ty)
    cairo_show_text(cr, label)
end

-- ---------------------------------------------------------------------------
-- PRIMITIVE: HP bar  (retro RPG style)
-- Draws a segmented progress bar with optional label.
--   x, y         top-left of bar
--   w, h         dimensions
--   value        current value (0..max)
--   max_val      maximum value
--   fill_col     {r,g,b} filled segment colour
--   bg_col       {r,g,b} empty trough colour
--   segments     number of discrete blocks (0 = continuous)
--   label        optional string drawn to the right of the bar
--   text_col     colour for label text
-- ---------------------------------------------------------------------------

function M.hp_bar(cr, x, y, w, h, value, max_val, fill_col, bg_col, segments, label, text_col)
    segments = segments or 0
    local pct = math.max(0, math.min(1, value / max_val))

    -- Trough
    M.set_color(cr, bg_col, 1.0)
    cairo_rectangle(cr, x, y, w, h)
    cairo_fill(cr)

    -- Thin border
    M.set_color(cr, fill_col, 0.4)
    cairo_set_line_width(cr, 0.5)
    cairo_rectangle(cr, x, y, w, h)
    cairo_stroke(cr)

    if segments > 0 then
        -- Segmented (pixel-block) style
        local gap     = 2
        local seg_w   = (w - (segments - 1) * gap) / segments
        local filled  = math.floor(pct * segments)
        for i = 0, segments - 1 do
            local sx = x + i * (seg_w + gap)
            local alpha = (i < filled) and 0.85 or 0.12
            M.set_color(cr, fill_col, alpha)
            cairo_rectangle(cr, sx, y, seg_w, h)
            cairo_fill(cr)
        end
    else
        -- Continuous fill
        M.set_color(cr, fill_col, 0.75)
        cairo_rectangle(cr, x, y, w * pct, h)
        cairo_fill(cr)
    end

    -- Optional right-hand label
    if label and text_col then
        cairo_select_font_face(cr, M.font.mono, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
        cairo_set_font_size(cr, M.font.size_xs)
        M.set_color(cr, text_col, 0.8)
        local te = cairo_text_extents(cr, label)
        cairo_move_to(cr, x + w + 6, y + h / 2 - te.height / 2 - te.y_bearing)
        cairo_show_text(cr, label)
    end
end

-- ---------------------------------------------------------------------------
-- PRIMITIVE: pixel bar chart (sparkline histogram)
-- values   table of numbers
-- max_val  reference maximum (nil = auto from table)
-- col      fill colour
-- ---------------------------------------------------------------------------

function M.spark_bars(cr, x, y, w, h, values, max_val, col)
    local n = #values
    if n == 0 then return end

    if not max_val then
        max_val = 0
        for _, v in ipairs(values) do
            if v > max_val then max_val = v end
        end
    end
    if max_val == 0 then max_val = 1 end

    local gap   = 2
    local bar_w = math.floor((w - (n - 1) * gap) / n)

    for i, v in ipairs(values) do
        local bar_h = math.max(2, math.floor((v / max_val) * h))
        local bx    = x + (i - 1) * (bar_w + gap)
        local by    = y + h - bar_h
        local alpha = 0.5 + 0.4 * (v / max_val)
        M.set_color(cr, col, alpha)
        cairo_rectangle(cr, bx, by, bar_w, bar_h)
        cairo_fill(cr)
    end
end

-- ---------------------------------------------------------------------------
-- PRIMITIVE: data row  (label + value on the same baseline)
-- Draws "label" left-aligned and "value" right-aligned within width w.
-- ---------------------------------------------------------------------------

function M.data_row(cr, x, y, w, label, value, label_col, value_col, font_name, font_size)
    font_name = font_name or M.font.mono
    font_size = font_size or M.font.size_md

    cairo_select_font_face(cr, font_name, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr, font_size)

    -- Label left
    M.set_color(cr, label_col, 0.8)
    cairo_move_to(cr, x, y)
    cairo_show_text(cr, label)

    -- Value right
    M.set_color(cr, value_col, 1.0)
    local te = cairo_text_extents(cr, value)
    cairo_move_to(cr, x + w - te.width - te.x_bearing, y)
    cairo_show_text(cr, value)
end

-- ---------------------------------------------------------------------------
-- HELPER: render multi-line text block
-- lines = { {text, col, font_size}, ... }
-- Returns the y position after the last line.
-- ---------------------------------------------------------------------------

function M.text_block(cr, x, y, lines, line_height)
    line_height = line_height or 12
    local cy = y
    for _, row in ipairs(lines) do
        local txt   = row[1] or ""
        local col   = row[2] or M.color.white
        local fsize = row[3] or M.font.size_md
        cairo_select_font_face(cr, M.font.mono, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
        cairo_set_font_size(cr, fsize)
        M.set_color(cr, col, 0.9)
        cairo_move_to(cr, x, cy)
        cairo_show_text(cr, txt)
        cy = cy + line_height
    end
    return cy
end

-- ---------------------------------------------------------------------------
-- HELPER: temperature colour
-- Returns a colour interpolated from cool (teal) → warm (orange) → hot (red)
-- based on a 0..100 normalised value.
-- ---------------------------------------------------------------------------

function M.temp_color(norm)
    norm = math.max(0, math.min(1, norm))
    if norm < 0.5 then
        -- teal → orange
        local t = norm * 2
        return {
            0.290 + t * (0.784 - 0.290),
            0.478 - t * (0.478 - 0.376),
            0.353 - t * (0.353 - 0.251),
        }
    else
        -- orange → red
        local t = (norm - 0.5) * 2
        return {
            0.784 + t * (0.900 - 0.784),
            0.376 - t * (0.376 - 0.100),
            0.251 - t * (0.251 - 0.100),
        }
    end
end

-- ---------------------------------------------------------------------------
-- HELPER: format bytes to human-readable string
-- ---------------------------------------------------------------------------

function M.fmt_bytes(bytes)
    if bytes >= 1073741824 then
        return string.format("%.1fG", bytes / 1073741824)
    elseif bytes >= 1048576 then
        return string.format("%.1fM", bytes / 1048576)
    elseif bytes >= 1024 then
        return string.format("%.1fK", bytes / 1024)
    else
        return string.format("%dB", bytes)
    end
end

-- ---------------------------------------------------------------------------
-- HELPER: clamp a number between min and max
-- ---------------------------------------------------------------------------

function M.clamp(val, min_val, max_val)
    return math.max(min_val, math.min(max_val, val))
end

-- ---------------------------------------------------------------------------
-- MODULE EXPORT
-- ---------------------------------------------------------------------------

return M
