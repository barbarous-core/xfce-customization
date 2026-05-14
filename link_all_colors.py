import re, os

def link_colors(file_path, is_dark=False):
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        return
    with open(file_path, 'r') as f:
        content = f.read()

    # 1. Replace rgba() patterns
    def replace_rgba(match):
        r, g, b, a = match.groups()
        alpha_val = float(a)
        alpha_str = f"{int(alpha_val * 100):02d}"
        
        supported = [3, 5, 6, 7, 8, 10, 12, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95]
        closest = min(supported, key=lambda x: abs(x - int(alpha_val * 100)))
        closest_str = f"{closest:02d}"

        r_int, g_int, b_int = int(r), int(g), int(b)
        
        if r_int < 50 and g_int < 50 and b_int < 50: # Close to black
            return f"var(--theme-bg-alpha-{closest_str})"
        elif r_int > 200 and g_int > 200 and b_int > 200: # Close to white
            return f"var(--theme-fg-alpha-{closest_str})"
        else:
            return f"var(--theme-sel-alpha-{closest_str})"

    content = re.sub(r'rgba\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*([\d.]+)\s*\)', replace_rgba, content)

    # 2. Replace common Hex patterns
    def replace_hex(match):
        hex_val = match.group(0).lower()
        if hex_val in ['#ffffff', '#fff', '#fdfdfe', '#f6f6fb']:
            return "var(--theme-selected-fg-color)" if is_dark else "var(--theme-bg-color)"
        if hex_val in ['#000000', '#000', '#1a1b26', '#282828', '#2d353b']:
            return "var(--theme-bg-color)" if is_dark else "var(--theme-fg-color)"
        if hex_val in ['#68a2e6', '#7eafe9', '#2679db', '#3c86de']:
            return "var(--theme-selected-bg-color)"
        if hex_val in ['#fc4138', '#f04a50', '#ec1b22']:
            return "var(--error-color)"
        if hex_val in ['#f27835', '#f08437', '#ffea00']:
            return "var(--warning-color)"
        return "var(--theme-base-color)"

    content = re.sub(r'#[0-9a-fA-F]{3,6}', replace_hex, content)

    # 3. Replace named colors in property values
    content = re.sub(r':\s*white\s*;', ': var(--theme-selected-fg-color);', content)
    content = re.sub(r':\s*black\s*;', ': var(--theme-bg-color);', content)

    with open(file_path, 'w') as f:
        f.write(content)

base_path = '/home/mohamed/Linux_Data/Git_Projects/xfce-customization/polythemes/.themes/polythemes/gtk-3.0'
link_colors(f'{base_path}/gtk.css', is_dark=False)
link_colors(f'{base_path}/gtk-dark.css', is_dark=True)
print("All colors linked successfully.")
