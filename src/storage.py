import json
import os
import base64
import flet as ft

APP_FOLDER = "PasswordManager"
PASSWORD_FILE = ".passwords.dat"
KEY_FILE = ".encryption_key"
SETTINGS_FILE = "settings.json"
COLOR_THEMES_FILE = "color_themes.json"
LANG_FILE = "language.json"

URI_PERMISSION_KEY = "documents_uri"
_storage_path = None

def get_documents_base_path(page=None):
    global _storage_path
    if _storage_path:
        return _storage_path
    
    if page:
        try:
            saved = page.client_storage.get(URI_PERMISSION_KEY)
            if saved and os.path.exists(saved):
                _storage_path = saved
                return saved
        except:
            pass
    
    default_path = "/storage/emulated/0/Documents"
    if os.path.exists(default_path) and os.access(default_path, os.W_OK):
        return default_path
    
    for alt in ["/sdcard/Documents", "/storage/self/primary/Documents"]:
        if os.path.exists(alt) and os.access(alt, os.W_OK):
            return alt
    
    return None

def get_app_folder_path(page=None):
    base = get_documents_base_path(page)
    if base:
        return os.path.join(base, APP_FOLDER)
    return None

def ensure_app_folder(page=None):
    path = get_app_folder_path(page)
    if path:
        try:
            if not os.path.exists(path):
                os.makedirs(path, exist_ok=True)
            if os.path.exists(path) and os.access(path, os.W_OK):
                test_file = os.path.join(path, ".write_test")
                try:
                    with open(test_file, "w") as f:
                        f.write("test")
                    os.remove(test_file)
                    return path
                except:
                    pass
        except:
            pass
    return None

def save_documents_base(page, base_path):
    global _storage_path
    if base_path and os.path.exists(base_path) and os.access(base_path, os.W_OK):
        full_path = os.path.join(base_path, APP_FOLDER)
        try:
            if not os.path.exists(full_path):
                os.makedirs(full_path, exist_ok=True)
            if os.path.exists(full_path) and os.access(full_path, os.W_OK):
                _storage_path = full_path
                try:
                    page.client_storage.set(URI_PERMISSION_KEY, base_path)
                except:
                    pass
                return full_path
        except:
            pass
    return None

def get_key(page=None):
    path = ensure_app_folder(page)
    if not path:
        return None, None
    
    key_path = os.path.join(path, KEY_FILE)
    key_data = None
    
    if os.path.exists(key_path):
        try:
            with open(key_path, "r") as f:
                key_data = f.read().strip()
        except:
            pass
    
    if key_data:
        try:
            key_bytes = base64.b64decode(key_data)
            from cryptography.fernet import Fernet
            f = Fernet(key_bytes)
            return key_bytes, path
        except:
            pass
    
    from cryptography.fernet import Fernet
    key = Fernet.generate_key()
    
    try:
        with open(key_path, "w") as f:
            f.write(base64.b64encode(key).decode())
    except:
        return None, None
    
    return key, path

def get_fernet(key):
    if key is None:
        return None
    from cryptography.fernet import Fernet
    return Fernet(key)

def load_passwords(page=None):
    from models import PasswordEntry
    path = ensure_app_folder(page)
    if not path:
        return []
    
    data_path = os.path.join(path, PASSWORD_FILE)
    if not os.path.exists(data_path):
        return []
    
    try:
        with open(data_path, "r", encoding="utf-8") as f:
            encrypted = f.read()
        if not encrypted:
            return []
        
        key, _ = get_key(page)
        fernet = get_fernet(key)
        if fernet is None:
            return []
        
        decrypted = fernet.decrypt(encrypted.encode())
        data = json.loads(decrypted)
        return [PasswordEntry.from_dict(item) for item in data]
    except Exception as e:
        print(f"Load error: {e}")
        return []

def save_passwords(page=None, passwords=None):
    if passwords is None:
        return
    
    path = ensure_app_folder(page)
    if not path:
        print("No storage path available")
        return
    
    try:
        key, _ = get_key(page)
        fernet = get_fernet(key)
        if fernet is None:
            print("No fernet available")
            return
        
        data = json.dumps([p.to_dict() for p in passwords], ensure_ascii=False, indent=2)
        encrypted = fernet.encrypt(data.encode())
        
        data_path = os.path.join(path, PASSWORD_FILE)
        with open(data_path, "w", encoding="utf-8") as f:
            f.write(encrypted.decode())
    except Exception as e:
        print(f"Save error: {e}")

def load_settings_from_file(page=None):
    path = ensure_app_folder(page)
    if not path:
        return None
    
    settings_path = os.path.join(path, SETTINGS_FILE)
    if not os.path.exists(settings_path):
        return None
    
    try:
        with open(settings_path, "r", encoding="utf-8") as f:
            return json.load(f)
    except:
        return None

def save_settings_to_file(page=None, settings=None):
    if settings is None:
        return
    
    path = ensure_app_folder(page)
    if not path:
        return
    
    settings_path = os.path.join(path, SETTINGS_FILE)
    try:
        with open(settings_path, "w", encoding="utf-8") as f:
            json.dump(settings, f, ensure_ascii=False, indent=2)
    except Exception as e:
        print(f"Save settings error: {e}")

def load_color_themes_from_file(page=None):
    path = ensure_app_folder(page)
    if not path:
        return None
    
    themes_path = os.path.join(path, COLOR_THEMES_FILE)
    if not os.path.exists(themes_path):
        return None
    
    try:
        with open(themes_path, "r", encoding="utf-8") as f:
            return json.load(f)
    except:
        return None

def save_color_themes_to_file(page=None, themes=None):
    if themes is None:
        return
    
    path = ensure_app_folder(page)
    if not path:
        return
    
    themes_path = os.path.join(path, COLOR_THEMES_FILE)
    try:
        with open(themes_path, "w", encoding="utf-8") as f:
            json.dump(themes, f, ensure_ascii=False, indent=2)
    except Exception as e:
        print(f"Save themes error: {e}")

def load_languages_from_file(page=None):
    path = ensure_app_folder(page)
    if not path:
        return None
    
    lang_path = os.path.join(path, LANG_FILE)
    if not os.path.exists(lang_path):
        return None
    
    try:
        with open(lang_path, "r", encoding="utf-8") as f:
            return json.load(f)
    except:
        return None

def save_languages_to_file(page=None, languages=None):
    if languages is None:
        return
    
    path = ensure_app_folder(page)
    if not path:
        return
    
    lang_path = os.path.join(path, LANG_FILE)
    try:
        with open(lang_path, "w", encoding="utf-8") as f:
            json.dump(languages, f, ensure_ascii=False, indent=2)
    except Exception as e:
        print(f"Save languages error: {e}")

def has_storage(page=None):
    path = ensure_app_folder(page)
    return path is not None

async def pick_documents_folder(page):
    picker = ft.FilePicker()
    page.overlay.append(picker)
    page.update()

    try:
        result = await picker.get_directory_path(dialog_title="选择 Documents 文件夹")
        if result and os.path.exists(result) and os.access(result, os.W_OK):
            result_path = save_documents_base(page, result)
            if result_path:
                return result_path
    except Exception as e:
        print(f"get_directory_path failed: {e}")

    result = await picker.pick_files(
        dialog_title="选择 Documents 文件夹（请选择任意文件）",
        initial_directory="/storage/emulated/0/Documents",
        allow_multiple=False
    )

    if result and len(result) > 0:
        file_path = result[0].path
        if file_path:
            base = os.path.dirname(file_path)
            if os.path.exists(base) and os.access(base, os.W_OK):
                result_path = save_documents_base(page, base)
                if result_path:
                    return result_path

    return None