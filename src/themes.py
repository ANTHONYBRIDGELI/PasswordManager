from constants import (
    DEFAULT_COLOR_THEMES,
    DEFAULT_LIGHT_COLORS,
    DEFAULT_DARK_COLORS,
)

_color_themes = None

def load_settings(page=None):
    from storage import load_settings_from_file
    if page:
        try:
            file_settings = load_settings_from_file(page)
            if file_settings:
                return file_settings
        except:
            pass
    
    from constants import DEFAULT_SETTINGS
    return DEFAULT_SETTINGS.copy()

def save_settings(settings, page=None):
    from storage import save_settings_to_file
    if page:
        try:
            save_settings_to_file(page, settings)
        except:
            pass

def load_color_themes(page=None):
    global _color_themes
    from storage import load_color_themes_from_file
    
    if page:
        try:
            file_themes = load_color_themes_from_file(page)
            if file_themes:
                _color_themes = file_themes
                return file_themes
        except:
            pass
    
    _color_themes = DEFAULT_COLOR_THEMES.copy()
    return _color_themes

def save_color_themes(themes, page=None):
    global _color_themes
    from storage import save_color_themes_to_file
    if page:
        try:
            save_color_themes_to_file(page, themes)
            _color_themes = themes
        except:
            pass

def get_color_theme_colors(theme_id, is_dark=True):
    global _color_themes
    
    themes = _color_themes if _color_themes else DEFAULT_COLOR_THEMES
    
    if theme_id in themes:
        return themes[theme_id]
    
    if is_dark:
        return DEFAULT_DARK_COLORS
    else:
        return DEFAULT_LIGHT_COLORS

def is_color_theme(theme_id):
    global _color_themes
    themes = _color_themes if _color_themes else DEFAULT_COLOR_THEMES
    return theme_id in themes