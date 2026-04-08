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
        "language": "语言",
        "export": "导出密码本",
        "import": "导入密码本",
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
        "export_success": "导出成功",
        "export_failed": "导出失败",
        "import_success": "导入成功",
        "import_failed": "导入失败",
        "select_file": "选择文件",
        "import_mode": "导入模式",
        "direct_add": "直接添加",
        "direct_add_desc": "将JSON中的所有密码直接添加到现有密码中",
        "update_add": "更新添加",
        "update_add_desc": "对于重名密码使用JSON中的数据更新",
        "diff_add": "差异添加",
        "diff_add_desc": "只导入JSON中与现有密码不重名的项目",
        "overwrite_add": "完全覆盖",
        "overwrite_add_desc": "删除所有现有密码，完全使用JSON中的密码",
        "select_import_mode": "选择导入模式",
        "duplicates_found": "发现",
        "confirm": "确认",
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
        "language": "Language",
        "export": "Export Passwords",
        "import": "Import Passwords",
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
        "export_success": "Export Success",
        "export_failed": "Export Failed",
        "import_success": "Import Success",
        "import_failed": "Import Failed",
        "select_file": "Select File",
        "import_mode": "Import Mode",
        "direct_add": "Direct Add",
        "direct_add_desc": "Add all passwords from JSON to existing passwords",
        "update_add": "Update Add",
        "update_add_desc": "Update existing passwords with same names from JSON",
        "diff_add": "Difference Add",
        "diff_add_desc": "Only import passwords from JSON that don't conflict",
        "overwrite_add": "Overwrite All",
        "overwrite_add_desc": "Delete all existing passwords and use only passwords from JSON",
        "select_import_mode": "Select Import Mode",
        "duplicates_found": "Found",
        "confirm": "Confirm",
    }
}

def load_languages(page=None):
    from storage import load_languages_from_file
    if page:
        try:
            file_langs = load_languages_from_file(page)
            if file_langs:
                return file_langs
        except:
            pass
    return DEFAULT_LANGUAGES

def save_languages(languages, page=None):
    from storage import save_languages_to_file
    if page:
        try:
            save_languages_to_file(page, languages)
        except:
            pass