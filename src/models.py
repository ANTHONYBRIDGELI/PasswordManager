from datetime import datetime

class PasswordEntry:
    def __init__(self, id=None, name="", account="", password="", notes="", created_at=None):
        self.id = id or datetime.now().timestamp()
        self.name = name
        self.account = account
        self.password = password
        self.notes = notes
        self.created_at = created_at or datetime.now().isoformat()

    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "account": self.account,
            "password": self.password,
            "notes": self.notes,
            "created_at": self.created_at
        }

    @staticmethod
    def from_dict(d):
        return PasswordEntry(
            id=d.get("id"),
            name=d.get("name", ""),
            account=d.get("account", ""),
            password=d.get("password", ""),
            notes=d.get("notes", ""),
            created_at=d.get("created_at")
        )