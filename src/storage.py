import json
import os
import base64
import flet as ft

PASSWORD_KEY = "passwords_final"
KEY_KEY = "key_final"
PASSWORD_FILE = "passwords.dat"
KEY_FILE = ".key"

def get_storage_dir(page):
    try:
        path = page._platform.storage_dir
        if path and os.path.exists(path):
            return path
    except:
        pass
    
    for base in [os.getcwd(), "/data/user/0/com.passwordmanager/files"]:
        if os.path.exists(base):
            return base
    
    try:
        path = os.path.join(os.getcwd(), "pm_data")
        os.makedirs(path, exist_ok=True)
        return path
    except:
        pass
    
    return os.getcwd()

def get_key(page):
    storage_dir = get_storage_dir(page)
    key_path = os.path.join(storage_dir, KEY_FILE)
    
    key_data = None
    if os.path.exists(key_path):
        try:
            with open(key_path, "r") as f:
                key_data = f.read().strip()
        except:
            pass
    
    if not key_data:
        try:
            key_data = page.client_storage.get(KEY_KEY)
        except:
            pass
    
    if key_data:
        try:
            key_bytes = base64.b64decode(key_data.encode('utf-8'))
            from cryptography.fernet import Fernet
            Fernet(key_bytes)
            return key_bytes
        except:
            pass
    
    from cryptography.fernet import Fernet
    key = Fernet.generate_key()
    key_b64 = base64.b64encode(key).decode('utf-8')
    
    try:
        with open(key_path, "w") as f:
            f.write(key_b64)
    except:
        pass
    
    try:
        page.client_storage.set(KEY_KEY, key_b64)
    except:
        pass
    
    return key

def get_fernet(key):
    if key is None:
        return None
    from cryptography.fernet import Fernet
    return Fernet(key)

def load_passwords(page):
    from models import PasswordEntry
    storage_dir = get_storage_dir(page)
    data_path = os.path.join(storage_dir, PASSWORD_FILE)
    
    encrypted = None
    
    if os.path.exists(data_path):
        try:
            with open(data_path, "r", encoding="utf-8") as f:
                encrypted = f.read()
        except:
            pass
    
    if not encrypted:
        try:
            encrypted = page.client_storage.get(PASSWORD_KEY)
        except:
            pass
    
    if not encrypted:
        return []
    
    try:
        key = get_key(page)
        fernet = get_fernet(key)
        if fernet:
            decrypted = fernet.decrypt(encrypted.encode('utf-8'))
            data = json.loads(decrypted.decode('utf-8'))
            return [PasswordEntry.from_dict(item) for item in data]
    except Exception as e:
        print(f"Load error: {e}")
    
    return []

def save_passwords(page, passwords):
    storage_dir = get_storage_dir(page)
    
    try:
        key = get_key(page)
        fernet = get_fernet(key)
        if fernet is None:
            return
        
        data = json.dumps([p.to_dict() for p in passwords], ensure_ascii=False, indent=2)
        encrypted = fernet.encrypt(data.encode('utf-8')).decode('utf-8')
        
        data_path = os.path.join(storage_dir, PASSWORD_FILE)
        with open(data_path, "w", encoding="utf-8") as f:
            f.write(encrypted)
        
        page.client_storage.set(PASSWORD_KEY, encrypted)
    except Exception as e:
        print(f"Save error: {e}")