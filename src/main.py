import flet as ft
import json
import os
import re
import subprocess
import platform
from constants import (
    APP_NAME,
    APP_VERSION,
    DEFAULT_COLOR_THEMES,
    DEFAULT_LIGHT_COLORS,
    DEFAULT_DARK_COLORS,
)
from themes import load_settings, save_settings, load_color_themes, get_color_theme_colors, is_color_theme
from languages import load_languages, DEFAULT_LANGUAGES
from models import PasswordEntry
from storage import load_passwords, save_passwords

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
        self.passwords = load_passwords()
        self.filtered_passwords = self.passwords.copy()
        self.search_query = ""
        self.file_picker = None
        self.file_picker_initialized = False
        self.color_themes = load_color_themes()
        self.languages = load_languages()
        self.settings = load_settings()
        self.theme_setting = self.settings.get("theme", "dark")
        self.lang_setting = self.settings.get("lang", "zh")
        
        self.update_theme_mode()
        
        self.page.title = self.t("app_name")
        self.setup_colors()
        self.build_ui()
        self.update_password_list()
        self.page.update()
    
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
        save_settings(self.settings)
        self.update_theme_mode()
        self.setup_colors()
        self.page.controls.clear()
        self.build_ui()
        self.show_settings_dialog(e)
        self.page.update()
    
    def change_language(self, e):
        self.lang_setting = e.control.value
        self.settings["lang"] = self.lang_setting
        save_settings(self.settings)
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
        theme_options = [
            ft.dropdown.Option("system", self.t("follow_system")),
            ft.dropdown.Option("dark", self.t("dark")),
            ft.dropdown.Option("light", self.t("light")),
        ]
        for theme_id in DEFAULT_COLOR_THEMES.keys():
            theme_data = DEFAULT_COLOR_THEMES[theme_id]
            theme_options.append(ft.dropdown.Option(theme_id, self.t(theme_data.get("name_key", theme_id))))
        
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
                ft.Text(f"{self.t('version')}: {APP_VERSION}", size=12, color=self.subtext_color, text_align=ft.TextAlign.CENTER),
            ], spacing=10, tight=True),
            bgcolor=self.card_color,
            shape=ft.RoundedRectangleBorder(radius=16),
            on_dismiss=lambda _: self.page.pop_dialog(),
        )
        self.page.show_dialog(dialog)
    
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
            
            save_passwords(self.passwords)
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
            save_passwords(self.passwords)
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