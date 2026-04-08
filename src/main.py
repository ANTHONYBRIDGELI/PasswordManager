import flet as ft
import json
import os
import re
import subprocess
import platform
from datetime import datetime

from constants import (
    APP_NAME,
    APP_VERSION,
    DEFAULT_COLOR_THEMES,
    DEFAULT_LIGHT_COLORS,
    DEFAULT_DARK_COLORS,
)
from themes import load_settings, save_settings, load_color_themes, save_color_themes, get_color_theme_colors, is_color_theme
from languages import load_languages, save_languages, DEFAULT_LANGUAGES
from models import PasswordEntry
from storage import (
    load_passwords, save_passwords,
    load_settings_from_file, save_settings_to_file,
    load_color_themes_from_file, save_color_themes_to_file,
    load_languages_from_file,
    ensure_app_folder, pick_documents_folder, has_storage
)

def fuzzy_match(text, query):
    if not query:
        return True
    text = text.lower()
    query = query.lower()
    pattern = ".*".join(re.escape(c) for c in query)
    return bool(re.search(pattern, text))

class PasswordManagerApp:
    def __init__(self, page: ft.Page):
        self.page = page
        self.page.theme_mode = ft.ThemeMode.DARK
        self.page.padding = 0
        self.search_query = ""
        self.file_picker = None
        self.file_picker_initialized = False
        
        storage_path = ensure_app_folder(self.page)
        
        file_settings = load_settings_from_file(self.page)
        self.settings = file_settings if file_settings else load_settings()
        
        file_themes = load_color_themes_from_file(self.page)
        if file_themes:
            self.color_themes = file_themes
        else:
            self.color_themes = load_color_themes()
            if storage_path:
                save_color_themes(self.color_themes, self.page)
        
        self.languages = load_languages(self.page)
        if storage_path:
            from languages import DEFAULT_LANGUAGES
            if not load_languages_from_file(self.page):
                save_languages(DEFAULT_LANGUAGES, self.page)
        
        self.theme_setting = self.settings.get("theme", "dark")
        self.lang_setting = self.settings.get("lang", "zh")
        
        self.passwords = load_passwords(self.page)
        self.filtered_passwords = self.passwords.copy()
        
        self.update_theme_mode()
        
        self.page.title = self.t("app_name")
        self.setup_colors()
        self.build_ui()
        self.update_password_list()
        self.page.update()
        
        if not storage_path:
            self.show_storage_setup_dialog()
    
    def show_storage_setup_dialog(self):
        async def on_pick(e):
            result = await pick_documents_folder(self.page)
            if result and has_storage(self.page):
                self.page.pop_dialog()
                self.passwords = load_passwords(self.page)
                self.filtered_passwords = self.passwords.copy()
                self.update_password_list()
                self.page.update()
            else:
                self.page.show_dialog(ft.AlertDialog(
                    modal=True,
                    open=True,
                    title=ft.Text("错误"),
                    content=ft.Text("无法访问所选文件夹，请选择其他位置"),
                    bgcolor=self.card_color,
                    shape=ft.RoundedRectangleBorder(radius=16),
                ))
        
        dialog = ft.AlertDialog(
            modal=False,
            open=True,
            title=ft.Text("存储设置"),
            content=ft.Column([
                ft.Text("请选择 Documents 文件夹以保存密码数据"),
                ft.Text("您的数据将保存在: Documents/PasswordManager/", size=12, color=self.subtext_color),
            ], spacing=10),
            actions=[
                ft.TextButton("选择文件夹", on_click=on_pick),
            ],
            bgcolor=self.card_color,
            shape=ft.RoundedRectangleBorder(radius=16),
        )
        self.page.show_dialog(dialog)
    
    def detect_system_theme(self):
        if platform.system() == "Android":
            try:
                result = subprocess.run(
                    ["powershell", "-Command", "(Get-ItemProperty -Path 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize').AppsUseLightTheme"],
                    capture_output=True, text=True
                )
                return "light" if "0" not in result.stdout else "dark"
            except:
                return "dark"
        elif platform.system() == "Darwin":
            try:
                result = subprocess.run(
                    ["defaults", "read", "-g", "AppleInterfaceStyle"],
                    capture_output=True, text=True
                )
                return "dark" if "Dark" in result.stdout else "light"
            except:
                return "light"
        else:
            return "dark"
    
    def update_theme_mode(self):
        theme = self.theme_setting
        if theme == "system":
            theme = self.detect_system_theme()
        
        is_dark = theme in ("dark", "green", "blue", "red", "purple")
        self.is_dark_mode = is_dark
    
    def get_base_theme(self):
        theme = self.theme_setting
        if theme == "system":
            theme = self.detect_system_theme()
        if theme in ("green", "blue", "red", "purple"):
            return "dark"
        return theme
    
    def change_theme(self, e):
        self.theme_setting = e.control.value
        self.settings["theme"] = self.theme_setting
        save_settings(self.settings, self.page)
        self.update_theme_mode()
        self.setup_colors()
        self.page.controls.clear()
        self.build_ui()
        self.show_settings_dialog(e)
        self.page.update()
    
    def change_language(self, e):
        self.lang_setting = e.control.value
        self.settings["lang"] = self.lang_setting
        save_settings(self.settings, self.page)
        self.page.controls.clear()
        self.build_ui()
        self.show_settings_dialog(e)
        self.page.update()
    
    def t(self, key):
        return self.languages.get(self.lang_setting, DEFAULT_LANGUAGES["zh"]).get(key, key)

    def setup_colors(self):
        colors = get_color_theme_colors(self.theme_setting, self.is_dark_mode)
        
        self.bg_color = colors["bg_color"]
        self.card_color = colors["card_color"]
        self.primary_color = colors["primary_color"]
        self.accent_color = colors["accent_color"]
        self.danger_color = colors["danger_color"]
        self.text_color = colors["text_color"]
        self.subtext_color = colors["subtext_color"]
        self.page.theme_mode = ft.ThemeMode.DARK if self.is_dark_mode else ft.ThemeMode.LIGHT

    def build_ui(self):
        self.search_field = ft.TextField(
            hint_text=self.t("search_hint"),
            prefix_icon=ft.Icons.SEARCH,
            on_change=self.on_search_change,
            on_submit=self.on_search_change,
            filled=True,
            fill_color=self.card_color,
            border_color="transparent",
            hint_style=ft.TextStyle(color=self.subtext_color),
            expand=True,
        )

        self.password_list = ft.ListView(
            expand=True,
            spacing=8,
            padding=15,
            auto_scroll=False,
        )

        self.empty_state = ft.Container(
            content=ft.Column([
                ft.Icon(ft.Icons.KEY, size=64, color=self.subtext_color),
                ft.Text(self.t("no_passwords"), size=18, color=self.subtext_color),
                ft.Text(self.t("add_hint"), size=14, color=self.subtext_color),
            ], alignment=ft.MainAxisAlignment.CENTER, horizontal_alignment=ft.CrossAxisAlignment.CENTER),
            alignment=ft.alignment.Alignment(0, 0),
            expand=True,
            visible=False,
        )

        self.content_container = ft.ListView(
            expand=True,
            spacing=8,
            padding=15,
        )

        self.page.add(
            ft.SafeArea(
                content=ft.Container(
                    content=ft.Column([
                        ft.Container(
                            content=ft.Text(self.t("app_name"), size=24, weight=ft.FontWeight.W_700, color=self.text_color),
                            padding=ft.padding.only(left=20, top=50, bottom=10),
                        ),
                        ft.Container(
                            content=self.search_field,
                            padding=ft.padding.symmetric(horizontal=15, vertical=10),
                        ),
                        ft.Container(
                            content=self.content_container,
                            expand=True,
                            bgcolor=self.card_color,
                            border_radius=12,
                            padding=ft.padding.only(left=0, right=0, top=8, bottom=8),
                        ),
                    ]),
                    expand=True,
                    bgcolor=self.bg_color,
                ),
                expand=True,
            ),
        )
        self.page.floating_action_button = ft.FloatingActionButton(
            icon=ft.Icons.ADD,
            on_click=self.show_add_dialog,
            bgcolor=self.primary_color,
        )
        self.page.add(ft.Container(
            content=ft.IconButton(
                icon=ft.Icons.SETTINGS,
                icon_color=self.subtext_color,
                on_click=self.show_settings_dialog,
            ),
            padding=10,
        ))
        
        self.update_password_list()
    
    def show_settings_dialog(self, e):
        def handle_export(e):
            import asyncio
            asyncio.create_task(self.async_export_passwords())
        
        def handle_import(e):
            import asyncio
            asyncio.create_task(self.async_show_import_dialog())
        
        theme_options = [
            ft.dropdown.Option("system", self.t("follow_system")),
            ft.dropdown.Option("dark", self.t("dark")),
            ft.dropdown.Option("light", self.t("light")),
        ]
        for theme_id in self.color_themes.keys():
            theme_data = self.color_themes[theme_id]
            theme_name = theme_data.get("name", theme_id)
            theme_options.append(ft.dropdown.Option(theme_id, theme_name))
        
        lang_options = []
        for lang_id, lang_data in self.languages.items():
            lang_options.append(ft.dropdown.Option(lang_id, lang_data.get("name", lang_id)))
        
        dialog = ft.AlertDialog(
            modal=False,
            open=True,
            title=ft.Text(self.t("settings"), size=20, weight=ft.FontWeight.W_600),
            content=ft.Column([
                ft.Container(height=1),
                ft.Row([
                    ft.Text(self.t("theme"), size=16),
                    ft.Container(expand=True),
                    ft.Dropdown(
                        value=self.theme_setting,
                        on_select=self.change_theme,
                        options=theme_options,
                        width=180,
                    ),
                ]),
                ft.Container(height=5),
                ft.Row([
                    ft.Text(self.t("language"), size=16),
                    ft.Container(expand=True),
                    ft.Dropdown(
                        value=self.lang_setting,
                        on_select=self.change_language,
                        options=lang_options,
                        width=180,
                    ),
                ]),
                ft.Container(height=10),
                ft.TextButton(
                    content=ft.Text(self.t("export")),
                    on_click=handle_export,
                ),
                ft.TextButton(
                    content=ft.Text(self.t("import")),
                    on_click=handle_import,
                ),
                ft.Container(height=5),
                ft.Text(f"{self.t('version')}: {APP_VERSION}", size=12, color=self.subtext_color, text_align=ft.TextAlign.CENTER),
            ], spacing=10, tight=True),
            bgcolor=self.card_color,
            shape=ft.RoundedRectangleBorder(radius=16),
            on_dismiss=lambda _: self.page.pop_dialog(),
        )
        self.page.show_dialog(dialog)
    
    def get_downloads_dir(self):
        if platform.system() == "Android":
            app_dir = os.path.join(os.getcwd(), "exports")
            if not os.path.exists(app_dir):
                os.makedirs(app_dir, exist_ok=True)
            return app_dir
        elif platform.system() == "Darwin":
            downloads = os.path.join(os.path.expanduser("~"), "Downloads")
            if os.path.exists(downloads):
                return downloads
            return os.path.expanduser("~")
        else:
            downloads = os.path.join(os.path.expanduser("~"), "Downloads")
            if os.path.exists(downloads):
                return downloads
            xdg_download = os.path.expanduser("~/下载")
            if os.path.exists(xdg_download):
                return xdg_download
            return os.path.expanduser("~")
    
    async def async_export_passwords(self):
        if not self.passwords:
            self.page.show_dialog(ft.AlertDialog(
                modal=False,
                open=True,
                title=ft.Text("提示"),
                content=ft.Text("没有密码可导出"),
                bgcolor=self.card_color,
            ))
            return
        
        try:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            default_filename = f"passwords_export_{timestamp}.json"
            
            export_data = {
                "version": "1.0",
                "exported_at": datetime.now().isoformat(),
                "password_count": len(self.passwords),
                "passwords": [p.to_dict() for p in self.passwords]
            }
            file_content_bytes = json.dumps(export_data, ensure_ascii=False, indent=2).encode("utf-8")
            
            if self.file_picker is None or not self.file_picker_initialized:
                self.file_picker = ft.FilePicker()
                self.file_picker_initialized = True
            
            result = await self.file_picker.save_file(
                dialog_title=self.t("export"),
                file_name=default_filename,
                allowed_extensions=["json"],
                src_bytes=file_content_bytes
            )
            
            if result:
                self.page.show_dialog(ft.AlertDialog(
                    modal=False,
                    open=True,
                    title=ft.Text(self.t("export_success")),
                    content=ft.Text(f"{self.t('export_success')}"),
                    bgcolor=self.card_color,
                ))
        except Exception as ex:
            self.page.show_dialog(ft.AlertDialog(
                modal=False,
                open=True,
                title=ft.Text(self.t("export_failed")),
                content=ft.Text(f"{self.t('export_error')}:\n{str(ex)}"),
                bgcolor=self.card_color,
            ))
    
    async def async_show_import_dialog(self):
        try:
            if self.file_picker is None or not self.file_picker_initialized:
                self.file_picker = ft.FilePicker()
                self.file_picker_initialized = True
            
            result = await self.file_picker.pick_files(
                dialog_title=self.t("select_file"),
                file_type=ft.FilePickerFileType.CUSTOM,
                allowed_extensions=["json"],
                allow_multiple=False
            )
            
            if result and len(result) > 0:
                filepath = result[0].path
                if not filepath:
                    return
                try:
                    with open(filepath, "r", encoding="utf-8") as f:
                        data = json.load(f)
                    
                    if "passwords" in data:
                        imported = data["passwords"]
                    elif isinstance(data, list):
                        imported = data
                    else:
                        raise ValueError("Invalid file format")
                    
                    imported_entries = []
                    for item in imported:
                        if isinstance(item, dict) and "name" in item and "password" in item:
                            entry = PasswordEntry(
                                name=item.get("name", ""),
                                account=item.get("account", ""),
                                password=item.get("password", ""),
                                notes=item.get("notes", ""),
                            )
                            imported_entries.append(entry)
                    
                    existing_names = set(p.name for p in self.passwords)
                    duplicate_count = sum(1 for e in imported_entries if e.name in existing_names)
                    
                    if duplicate_count > 0:
                        self.pending_import_entries = imported_entries
                        self.show_import_mode_dialog(duplicate_count)
                    else:
                        self.do_import(imported_entries, "direct_add")
                except Exception as ex:
                    self.page.show_dialog(ft.AlertDialog(
                        modal=False,
                        open=True,
                        title=ft.Text(self.t("import_failed")),
                        content=ft.Text(f"{self.t('import_error')}:\n{str(ex)}"),
                        bgcolor=self.card_color,
                    ))
        except Exception as e:
            self.page.show_dialog(ft.AlertDialog(
                modal=False,
                open=True,
                title=ft.Text("错误"),
                content=ft.Text(f"文件选择器不可用:\n{str(e)}"),
                bgcolor=self.card_color,
            ))
        self.page.update()
    
    def show_import_mode_dialog(self, duplicate_count):
        self.selected_import_mode = None
        
        def on_radio_change(e):
            self.selected_import_mode = e.control.value
        
        def on_confirm(e):
            if self.selected_import_mode is None:
                self.page.show_dialog(ft.AlertDialog(
                    modal=True,
                    open=True,
                    title=ft.Text("警告"),
                    content=ft.Text(self.t("select_import_mode")),
                    bgcolor=self.card_color,
                    shape=ft.RoundedRectangleBorder(radius=16),
                ))
                return
            self.page.pop_dialog()
            self.do_import(self.pending_import_entries, self.selected_import_mode)
        
        mode_selection = ft.RadioGroup(
            content=ft.Column([
                ft.Radio(value="direct_add", label=self.t("direct_add")),
                ft.Container(
                    content=ft.Text(self.t("direct_add_desc"), size=12, color=self.subtext_color),
                    padding=ft.padding.only(left=30, bottom=10)
                ),
                ft.Radio(value="update_add", label=self.t("update_add")),
                ft.Container(
                    content=ft.Text(self.t("update_add_desc"), size=12, color=self.subtext_color),
                    padding=ft.padding.only(left=30, bottom=10)
                ),
                ft.Radio(value="diff_add", label=self.t("diff_add")),
                ft.Container(
                    content=ft.Text(self.t("diff_add_desc"), size=12, color=self.subtext_color),
                    padding=ft.padding.only(left=30, bottom=10)
                ),
                ft.Radio(value="overwrite_add", label=self.t("overwrite_add")),
                ft.Container(
                    content=ft.Text(self.t("overwrite_add_desc"), size=12, color=self.subtext_color),
                    padding=ft.padding.only(left=30, bottom=10)
                ),
            ], spacing=0),
            on_change=on_radio_change,
        )
        
        dialog = ft.AlertDialog(
            modal=True,
            open=True,
            title=ft.Text(self.t("select_import_mode"), size=20, weight=ft.FontWeight.W_600),
            content=ft.Column([
                ft.Text(self.t("duplicates_found") + " " + str(duplicate_count) + " " + self.t("import_mode_desc"), size=14, color=self.subtext_color),
                ft.Container(height=10),
                mode_selection,
                ft.Container(height=10),
                ft.Row([
                    ft.TextButton(self.t("cancel"), on_click=lambda _: self.page.pop_dialog()),
                    ft.Container(expand=True),
                    ft.ElevatedButton(self.t("confirm"), on_click=on_confirm, bgcolor=self.primary_color),
                ]),
            ], spacing=5),
            bgcolor=self.card_color,
            shape=ft.RoundedRectangleBorder(radius=16),
        )
        self.page.show_dialog(dialog)
    
    def do_import(self, imported_entries, mode):
        existing_names = {p.name for p in self.passwords}
        count = 0
        
        if mode == "overwrite_add":
            self.passwords.clear()
            for entry in imported_entries:
                self.passwords.append(entry)
                count += 1
        elif mode == "direct_add":
            for entry in imported_entries:
                self.passwords.append(entry)
                count += 1
        elif mode == "update_add":
            for entry in imported_entries:
                existing = next((p for p in self.passwords if p.name == entry.name), None)
                if existing:
                    existing.account = entry.account
                    existing.password = entry.password
                    existing.notes = entry.notes
                else:
                    self.passwords.append(entry)
                count += 1
        elif mode == "diff_add":
            for entry in imported_entries:
                if entry.name not in existing_names:
                    self.passwords.append(entry)
                    count += 1
        
        save_passwords(self.page, self.passwords)
        self.update_password_list()
        
        self.page.show_dialog(ft.AlertDialog(
            modal=False,
            open=True,
            title=ft.Text(self.t("import_success")),
            content=ft.Text(f"{self.t('import_success')}: {count}"),
            bgcolor=self.card_color,
        ))

    def update_password_list(self):
        self.content_container.controls.clear()
        
        if self.search_query:
            self.filtered_passwords = [
                p for p in self.passwords
                if fuzzy_match(p.name, self.search_query) or
                   fuzzy_match(p.account, self.search_query) or
                   fuzzy_match(p.password, self.search_query) or
                   fuzzy_match(p.notes, self.search_query)
            ]
        else:
            self.filtered_passwords = self.passwords.copy()

        if not self.filtered_passwords:
            self.content_container.controls.append(self.empty_state)
        else:
            for p in self.filtered_passwords:
                self.content_container.controls.append(self.create_password_card(p))

        self.page.update()

    def create_password_card(self, password: PasswordEntry):
        return ft.Container(
            content=ft.Column([
                ft.Row([
                    ft.Container(
                        content=ft.Text(password.name[0].upper() if password.name else "?", size=20, weight=ft.FontWeight.W_700, color="#FFFFFF"),
                        width=44, height=44,
                        shape=ft.CircleBorder(),
                        bgcolor=self.primary_color,
                    ),
                    ft.Column([
                        ft.Text(password.name, size=16, weight=ft.FontWeight.W_600, color=self.text_color),
                        ft.Text(password.account if password.account else "No account", size=13, color=self.subtext_color),
                    ], spacing=2, expand=True),
                    ft.IconButton(ft.Icons.EDIT, icon_color=self.subtext_color, on_click=lambda _, p=password: self.show_edit_dialog(p)),
                    ft.IconButton(ft.Icons.DELETE, icon_color=self.danger_color, on_click=lambda _, p=password: self.show_delete_dialog(p)),
                ], spacing=12),
                ft.Container(height=1, bgcolor="#21262D", margin=ft.margin.only(top=10)),
            ], spacing=8),
            padding=15,
            border_radius=12,
            bgcolor=self.card_color,
            margin=ft.margin.symmetric(horizontal=0),
            on_click=lambda _, p=password: self.show_detail_dialog(p),
        )

    def on_search_change(self, e):
        self.search_query = e.control.value
        self.update_password_list()

    def show_add_dialog(self, e):
        self.show_entry_dialog(None)

    def show_edit_dialog(self, password: PasswordEntry):
        self.show_entry_dialog(password)

    def show_entry_dialog(self, password):
        is_edit = password is not None
        
        name_field = ft.TextField(
            label=self.t("name_field"),
            value=password.name if password else "",
            filled=True,
            fill_color="#21262D",
            border_color="transparent",
        )
        account_field = ft.TextField(
            label=self.t("account_field"),
            value=password.account if password else "",
            filled=True,
            fill_color="#21262D",
            border_color="transparent",
        )
        password_field = ft.TextField(
            label=self.t("password_field"),
            value=password.password if password else "",
            filled=True,
            fill_color="#21262D",
            border_color="transparent",
            password=True,
            can_reveal_password=True,
        )
        notes_field = ft.TextField(
            label=self.t("notes_field"),
            value=password.notes if password else "",
            filled=True,
            fill_color="#21262D",
            border_color="transparent",
            multiline=True,
            min_lines=2,
            max_lines=4,
        )

        def validate_and_save(e):
            name = name_field.value.strip()
            pwd = password_field.value.strip()
            
            if not name:
                name_field.error_text = "Name is required"
                self.page.update()
                return

            if is_edit:
                password.name = name
                password.account = account_field.value.strip()
                password.password = pwd
                password.notes = notes_field.value.strip()
            else:
                new_entry = PasswordEntry(
                    name=name,
                    account=account_field.value.strip(),
                    password=pwd,
                    notes=notes_field.value.strip(),
                )
                self.passwords.insert(0, new_entry)
            
            save_passwords(self.page, self.passwords)
            self.update_password_list()
            self.page.pop_dialog()

        dialog = ft.AlertDialog(
            modal=True,
            open=True,
            title=ft.Text(self.t("edit_password") if is_edit else self.t("add_password"), size=20, weight=ft.FontWeight.W_600),
            content=ft.Column([
                name_field,
                account_field,
                password_field,
                notes_field,
            ], spacing=12, tight=True),
            actions=[
                ft.TextButton(self.t("cancel"), on_click=lambda _: self.page.pop_dialog()),
                ft.TextButton(self.t("save"), on_click=validate_and_save),
            ],
            bgcolor=self.card_color,
            shape=ft.RoundedRectangleBorder(radius=16),
        )
        self.page.show_dialog(dialog)

    def show_delete_dialog(self, password: PasswordEntry):
        def confirm_delete(e):
            self.passwords.remove(password)
            save_passwords(self.page, self.passwords)
            self.update_password_list()
            self.page.pop_dialog()

        dialog = ft.AlertDialog(
            modal=True,
            open=True,
            title=ft.Text(self.t("confirm_delete"), size=20, weight=ft.FontWeight.W_600),
            content=ft.Text(self.t("delete_message"), size=15),
            actions=[
                ft.TextButton(self.t("cancel"), on_click=lambda _: self.page.pop_dialog()),
                ft.TextButton(self.t("delete"), on_click=confirm_delete),
            ],
            bgcolor=self.card_color,
            shape=ft.RoundedRectangleBorder(radius=16),
        )
        self.page.show_dialog(dialog)

    def show_detail_dialog(self, password: PasswordEntry):
        dialog = ft.AlertDialog(
            modal=False,
            open=True,
            title=ft.Row([
                ft.Container(
                    content=ft.Text(password.name[0].upper() if password.name else "?", size=18, weight=ft.FontWeight.W_700, color="#FFFFFF"),
                    width=36, height=36,
                    shape=ft.CircleBorder(),
                    bgcolor=self.primary_color,
                ),
                ft.Text(password.name, size=20, weight=ft.FontWeight.W_600),
            ], spacing=12),
            content=ft.Column([
                self._detail_row(self.t("account"), password.account, "ACCOUNT"),
                self._detail_row(self.t("password"), password.password, "PASSWORD"),
                self._detail_row(self.t("notes"), password.notes, "NOTES") if password.notes else ft.Container(),
            ], spacing=16, tight=True),
            actions=[
                ft.TextButton(self.t("close"), on_click=lambda _: self.page.pop_dialog()),
                ft.TextButton(self.t("edit"), on_click=lambda _: (self.page.pop_dialog(), self.show_edit_dialog(password))),
            ],
            bgcolor=self.card_color,
            shape=ft.RoundedRectangleBorder(radius=16),
        )
        self.page.show_dialog(dialog)

    def _detail_row(self, label, value, copy_type):
        return ft.Row([
            ft.Column([
                ft.Text(label, size=12, color=self.subtext_color),
                ft.Text(value if value else "-", size=15, color=self.text_color),
            ], spacing=2),
            ft.Container(expand=True),
            ft.IconButton(ft.Icons.COPY, icon_color=self.subtext_color, on_click=lambda _, v=value, l=label: self.copy_to_clipboard(v, l)),
        ], spacing=8)

    async def async_copy_to_clipboard(self, text, label):
        try:
            clipboard = ft.Clipboard()
            await clipboard.set(text)
        except Exception as e:
            print(f"Clipboard error: {e}")
        
        self.page.show_dialog(ft.AlertDialog(
            modal=False,
            open=True,
            content=ft.Text(f"{label} {self.t('copied')}"),
            bgcolor=self.card_color,
        ))
    
    def copy_to_clipboard(self, text, label):
        import asyncio
        asyncio.create_task(self.async_copy_to_clipboard(text, label))

def main(page: ft.Page):
    PasswordManagerApp(page)

ft.run(main)