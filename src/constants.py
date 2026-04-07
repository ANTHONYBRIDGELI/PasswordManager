import os

APP_NAME = "password_manager"
APP_VERSION = "0.8.2"
DATA_FILE = "passwords.json"
KEY_FILE = ".encryption_key"
SETTINGS_FILE = "settings.json"
COLOR_THEMES_FILE = "color_themes.json"
LANG_FILE = "languages.json"

DEFAULT_SETTINGS = {
    "theme": "dark",
    "lang": "zh"
}

DEFAULT_COLOR_THEMES = {
    "green": {
        "name_key": "green",
        "dark": {
            "bg_color": "#0D1117",
            "card_color": "#1A2E1F",
            "primary_color": "#238636",
            "accent_color": "#58A6FF",
            "danger_color": "#F85149",
            "text_color": "#C9D1D9",
            "subtext_color": "#8B949E"
        },
        "light": {
            "bg_color": "#F0F5F0",
            "card_color": "#E8F5E9",
            "primary_color": "#4CAF50",
            "accent_color": "#388E3C",
            "danger_color": "#D32F2F",
            "text_color": "#212121",
            "subtext_color": "#757575"
        }
    },
    "blue": {
        "name_key": "blue",
        "dark": {
            "bg_color": "#0D1117",
            "card_color": "#1A2533",
            "primary_color": "#58A6FF",
            "accent_color": "#238636",
            "danger_color": "#F85149",
            "text_color": "#C9D1D9",
            "subtext_color": "#8B949E"
        },
        "light": {
            "bg_color": "#F0F5FF",
            "card_color": "#E3F2FD",
            "primary_color": "#2196F3",
            "accent_color": "#1976D2",
            "danger_color": "#D32F2F",
            "text_color": "#212121",
            "subtext_color": "#757575"
        }
    },
    "red": {
        "name_key": "red",
        "dark": {
            "bg_color": "#0D1117",
            "card_color": "#331A1A",
            "primary_color": "#F85149",
            "accent_color": "#58A6FF",
            "danger_color": "#DA3633",
            "text_color": "#C9D1D9",
            "subtext_color": "#8B949E"
        },
        "light": {
            "bg_color": "#FFF5F5",
            "card_color": "#FFEBEE",
            "primary_color": "#F44336",
            "accent_color": "#D32F2F",
            "danger_color": "#B71C1C",
            "text_color": "#212121",
            "subtext_color": "#757575"
        }
    },
    "purple": {
        "name_key": "purple",
        "dark": {
            "bg_color": "#0D1117",
            "card_color": "#2D1A33",
            "primary_color": "#A371F7",
            "accent_color": "#238636",
            "danger_color": "#F85149",
            "text_color": "#C9D1D9",
            "subtext_color": "#8B949E"
        },
        "light": {
            "bg_color": "#F5F0FF",
            "card_color": "#EDE7F6",
            "primary_color": "#9C27B0",
            "accent_color": "#7B1FA2",
            "danger_color": "#D32F2F",
            "text_color": "#212121",
            "subtext_color": "#757575"
        }
    }
}

DEFAULT_LIGHT_COLORS = {
    "bg_color": "#F5F5F5",
    "card_color": "#FFFFFF",
    "primary_color": "#1976D2",
    "accent_color": "#388E3C",
    "danger_color": "#D32F2F",
    "text_color": "#212121",
    "subtext_color": "#757575"
}

DEFAULT_DARK_COLORS = {
    "bg_color": "#0D1117",
    "card_color": "#161B22",
    "primary_color": "#58A6FF",
    "accent_color": "#238636",
    "danger_color": "#F85149",
    "text_color": "#C9D1D9",
    "subtext_color": "#8B949E"
}

def get_app_dir():
    app_dir = os.path.join(os.getcwd(), APP_NAME)
    if not os.path.exists(app_dir):
        os.makedirs(app_dir, exist_ok=True)
    return app_dir

def get_data_path():
    return os.path.join(get_app_dir(), DATA_FILE)

def get_key_path():
    return os.path.join(get_app_dir(), KEY_FILE)

def get_settings_path():
    return os.path.join(get_app_dir(), SETTINGS_FILE)

def get_color_themes_path():
    return os.path.join(get_app_dir(), COLOR_THEMES_FILE)

def get_lang_path():
    return os.path.join(get_app_dir(), LANG_FILE)