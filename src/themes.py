import json
import os
from constants import (
    DEFAULT_COLOR_THEMES,
    DEFAULT_LIGHT_COLORS,
    DEFAULT_DARK_COLORS,
    get_color_themes_path,
    get_settings_path,
)

def load_settings():
    path = get_settings_path()
    if os.path.exists(path):
        try:
            with open(path, "r", encoding="utf-8") as f:
                return json.load(f)
        except:
            pass
    return {"theme": "dark", "lang": "zh"}

def save_settings(settings):
    path = get_settings_path()
    try:
        with open(path, "w", encoding="utf-8") as f:
            json.dump(settings, f, ensure_ascii=False, indent=2)
    except:
        pass

def load_color_themes():
    path = get_color_themes_path()
    if os.path.exists(path):
        try:
            with open(path, "r", encoding="utf-8") as f:
                return json.load(f)
        except:
            pass
    themes = {}
    try:
        with open(path, "w", encoding="utf-8") as f:
            json.dump(DEFAULT_COLOR_THEMES, f, ensure_ascii=False, indent=2)
    except:
        pass
    return DEFAULT_COLOR_THEMES

def get_color_theme_colors(theme_id, is_dark):
    if theme_id in DEFAULT_COLOR_THEMES:
        theme_data = DEFAULT_COLOR_THEMES[theme_id]
        return theme_data["dark"] if is_dark else theme_data["light"]
    
    if is_dark:
        return DEFAULT_DARK_COLORS
    else:
        return DEFAULT_LIGHT_COLORS

def is_color_theme(theme_id):
    return theme_id in DEFAULT_COLOR_THEMES