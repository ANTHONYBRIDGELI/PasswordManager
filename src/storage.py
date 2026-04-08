import json
import base64
import flet as ft

PASSWORD_STORAGE_KEY = "passwords_data"
KEY_STORAGE_KEY = "encryption_key"

def get_key(page: ft.Page):
    try:
        key_b64 = page.client_storage.get(KEY_STORAGE_KEY)
        if key_b64:
            from cryptography.fernet import Fernet
            try:
                key = base64.b64decode(key_b64)
                Fernet(key)
                return key
            except:
                pass
        from cryptography.fernet import Fernet
        key = Fernet.generate_key()
        page.client_storage.set(KEY_STORAGE_KEY, base64.b64encode(key).decode())
        return key
    except Exception as e:
        print(f"Get key error: {e}")
        return None

def get_fernet(key):
    if key is None:
        return None
    from cryptography.fernet import Fernet
    return Fernet(key)

def load_passwords(page: ft.Page):
    from models import PasswordEntry
    try:
        encrypted_data = page.client_storage.get(PASSWORD_STORAGE_KEY)
        if encrypted_data:
            key = get_key(page)
            fernet = get_fernet(key)
            if fernet is None:
                return []
            decrypted_data = fernet.decrypt(encrypted_data.encode())
            data = json.loads(decrypted_data)
            return [PasswordEntry.from_dict(item) for item in data]
    except Exception as e:
        print(f"Load error: {e}")
    return []

def save_passwords(page: ft.Page, passwords):
    from models import PasswordEntry
    try:
        key = get_key(page)
        fernet = get_fernet(key)
        if fernet is None:
            return
        data = json.dumps([p.to_dict() for p in passwords], ensure_ascii=False, indent=2)
        encrypted_data = fernet.encrypt(data.encode())
        page.client_storage.set(PASSWORD_STORAGE_KEY, encrypted_data.decode())
    except Exception as e:
        print(f"Save error: {e}")