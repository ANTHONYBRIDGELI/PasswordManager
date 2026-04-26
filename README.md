# Password Manager

A local password manager Android app built with Flutter.

## Features

- **密码管理** - 添加、编辑、删除密码记录
- **搜索功能** - 支持按名称、账号、密码、备注搜索
- **数据安全** - AES-256 加密存储本地数据
- **主题切换** - 支持暗黑、亮色及多种彩色主题（绿色、蓝色、红色、紫色）
- **多语言** - 支持中文、英文
- **导入/导出** - JSON 格式备份与恢复，支持多种导入模式（直接添加、更新添加、差异添加、完全覆盖）

## Technical Stack

| Category | Technology |
|----------|------------|
| Framework | Flutter |
| Language | Dart |
| Encryption | encrypt (AES-256-CBC) |
| Storage | path_provider + 本地文件 |
| Settings | shared_preferences |
| File Picker | file_picker |

## Project Structure

```
lib/
├── main.dart                 # 主入口，UI 实现
├── constants/
│   └── app_constants.dart    # 常量定义（主题、语言）
├── models/
│   └── password_entry.dart   # 密码数据模型
└── services/
    └── storage_service.dart  # 加密存储服务
```

## Build & Release

### 环境要求

- Flutter SDK >= 3.11.5
- Android SDK

### Debug Build

```bash
flutter build apk --debug
```

### Release Build

**1. 配置签名**

创建密钥库：
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

创建 `android/key.properties`：
```properties
storePassword=你的密钥库密码
keyPassword=你的私钥密码
keyAlias=upload
storeFile=/path/to/upload-keystore.jks
```

**2. 执行打包**

```bash
flutter build apk --release
```

输出文件位于 `build/app/outputs/flutter-apk/`，默认命名为 `PasswordManager_{版本号}.apk`。

## Data Storage

- 加密密钥：自动生成并存储在应用目录
- 密码数据：`Documents/PasswordManager/.passwords.dat`（加密）
- 设置文件：`Documents/PasswordManager/settings.json`
- 主题配置：`Documents/PasswordManager/color_themes.json`
- 语言配置：`Documents/PasswordManager/language.json`

## Version

Current version: 0.8.7
