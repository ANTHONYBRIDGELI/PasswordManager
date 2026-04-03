import json
import os
import platform
from cryptography.fernet import Fernet
from constants import get_data_path, get_key_path
from models import PasswordEntry

def get_key():
    key_file = get_key_path()
    try:
        if os.path.exists(key_file):
            with open(key_file, "r") as f:
                key = f.read().strip()
            try:
                Fernet(key)
                return key
            except:
                pass
        key = Fernet.generate_key().decode()
        with open(key_file, "w") as f:
            f.write(key)
        if platform.system() != "Android":
            os.chmod(key_file, 0o600)
        return key
    except:
        key = Fernet.generate_key().decode()
        return key

def get_fernet():
    key = get_key()
    return Fernet(key)

def load_passwords():
    data_path = get_data_path()
    if os.path.exists(data_path):
        try:
            with open(data_path, "r", encoding="utf-8") as f:
                encrypted_data = f.read()
                if encrypted_data:
                    fernet = get_fernet()
                    decrypted_data = fernet.decrypt(encrypted_data.encode())
                    data = json.loads(decrypted_data)
                    return [PasswordEntry.from_dict(item) for item in data]
        except Exception as e:
            print(f"Load error: {e}")
            return []
    return []

def save_passwords(passwords):
    fernet = get_fernet()
    data = json.dumps([p.to_dict() for p in passwords], ensure_ascii=False, indent=2)
    encrypted_data = fernet.encrypt(data.encode())
    data_path = get_data_path()
    with open(data_path, "w", encoding="utf-8") as f:
        f.write(encrypted_data.decode())