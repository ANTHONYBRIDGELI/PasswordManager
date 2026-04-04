import json
import os
from constants import get_lang_path

DEFAULT_LANGUAGES = {
    "zh": {
        "name": "中文",
        "app_name": "密码管理器",
        "search_hint": "搜索密码...",
        "no_passwords": "暂无密码记录",
        "add_hint": "点击下方按钮添加",
        "settings": "设置",
        "theme": "主题",
        "dark": "暗黑",
        "light": "明亮",
        "follow_system": "跟随系统",
        "color_theme": "配色",
        "language": "语言",
        "name_required": "名称不能为空",
        "add_password": "添加密码",
        "edit_password": "编辑密码",
        "cancel": "取消",
        "save": "保存",
        "delete": "删除",
        "confirm_delete": "确认删除",
        "delete_message": "确定要删除吗？此操作不可恢复。",
        "close": "关闭",
        "edit": "编辑",
        "account": "账号",
        "password": "密码",
        "notes": "备注",
        "name_field": "名称 *",
        "account_field": "账号",
        "password_field": "密码",
        "notes_field": "备注",
        "version": "版本",
        "copied": "已复制",
        "custom": "自定义",
        "green": "绿色",
        "blue": "蓝色",
        "red": "红色",
        "purple": "紫色",
    },
    "en": {
        "name": "English",
        "app_name": "Password Manager",
        "search_hint": "Search passwords...",
        "no_passwords": "No password records",
        "add_hint": "Tap the button below to add",
        "settings": "Settings",
        "theme": "Theme",
        "dark": "Dark",
        "light": "Light",
        "follow_system": "Follow System",
        "color_theme": "Color Theme",
        "language": "Language",
        "name_required": "Name is required",
        "add_password": "Add Password",
        "edit_password": "Edit Password",
        "cancel": "Cancel",
        "save": "Save",
        "delete": "Delete",
        "confirm_delete": "Confirm Delete",
        "delete_message": "Are you sure you want to delete? This cannot be undone.",
        "close": "Close",
        "edit": "Edit",
        "account": "Account",
        "password": "Password",
        "notes": "Notes",
        "name_field": "Name *",
        "account_field": "Account",
        "password_field": "Password",
        "notes_field": "Notes",
        "version": "Version",
        "copied": "Copied",
        "custom": "Custom",
        "green": "Green",
        "blue": "Blue",
        "red": "Red",
        "purple": "Purple",
    }
}

def load_languages():
    path = get_lang_path()
    if os.path.exists(path):
        try:
            with open(path, "r", encoding="utf-8") as f:
                return json.load(f)
        except:
            pass
    return DEFAULT_LANGUAGES