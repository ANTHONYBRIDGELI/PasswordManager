import json
import os
from constants import (
    DEFAULT_COLOR_THEMES,
    DEFAULT_LIGHT_COLORS,
    DEFAULT_DARK_COLORS,
)

_settings_cache = None
_color_themes_cache = None

def load_settings(page=None):
    from storage import load_settings_from_file
    file_settings = None
    if page:
        try:
            file_settings = load_settings_from_file(page)
        except:
            pass
    
    if file_settings:
        return file_settings
    
    from constants import DEFAULT_SETTINGS
    return DEFAULT_SETTINGS.copy()

def save_settings(settings, page=None):
    from storage import save_settings_to_file
    
    try:
        save_settings_to_file(page, settings)
    except:
        pass

def load_color_themes(page=None):
    from storage import load_color_themes_from_file
    
    if page:
        try:
            file_themes = load_color_themes_from_file(page)
            if file_themes:
                return file_themes
        except:
            pass
    
    return DEFAULT_COLOR_THEMES.copy()

def save_color_themes(themes, page=None):
    from storage import save_color_themes_to_file
    
    try:
        save_color_themes_to_file(page, themes)
    except:
        pass

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