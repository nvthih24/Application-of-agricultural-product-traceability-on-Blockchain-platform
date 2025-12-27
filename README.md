# 🌾 AgriTrace Mobile - Blockchain Traceability App

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android%20|%20iOS-green?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)

## 📖 Introduction

**AgriTrace Mobile** is a decentralized application (dApp) client built with **Flutter**. It empowers farmers, transporters, retailers, and consumers to track the journey of agricultural products from farm to table using **Blockchain Technology**.

This app connects to the **AgriTrace Backend** to interact with Smart Contracts, ensuring data transparency, immutability, and trust across the supply chain.

> **Related Repository:**
>
> - 🔗 **Backend Server (Node.js & Smart Contracts):** [https://github.com/Baozxje/dAppServer3TML](https://github.com/Baozxje/dAppServer3TML)

## 📱 Key Features

### 👨‍🌾 For Farmers

- **Secure Login:** Role-based authentication.
- **Dashboard:** Overview of crops, planting status, and harvest statistics.
- **Add Crop (Start Season):** Register new planting batches on Blockchain.
  - 📸 **Evidence:** Capture real-time photos via **Camera** or select from **Gallery**.
  - ☁️ **Storage:** Automatic image upload to Cloudinary.
- **Harvest Management:** Update harvest quantity, quality, and status.

### 🚚 For Transporters & Retailers

- **Shipment Tracking:** Update location and transport status (Pickup/Delivery).
- **Retail Management:** Update selling price and shelf status.

### 🛒 For Consumers (Guest)

- **Smart Filtering:** Filter products by categories (Fruits, Vegetables, Rice, Seeds...) directly on the Home Screen.
- **Traceability Timeline:** View the full history of a product with a visual timeline:
  - 🌱 Planting Origin (Seed source, Farmer info).
  - 💧 Care Log (Watering, Fertilizing).
  - 🚜 Harvest details.
  - 🚛 Transportation path.
  - 🏪 Retailer info & Price.
- **Blockchain Verification:** Direct link to verify transaction hash on the blockchain explorer.

## 🛠️ Tech Stack & Architecture

- **Framework:** Flutter (Dart)
- **Architecture:** MVC / Provider Pattern
- **Networking:** HTTP (REST API integration)
- **Media:** Image Picker (Camera/Gallery), Multipart Upload
- **UI Components:** Material Design 3, Custom Timeline Views, Shimmer Loading.

## 📸 Screenshots

|                       Farmer Dashboard                       |                      Add Crop (Camera)                      |                    Home & Filtering                     |                   Product Traceability                   |
| :----------------------------------------------------------: | :---------------------------------------------------------: | :-----------------------------------------------------: | :------------------------------------------------------: |
| <img src="app/assets/screenshots/dashboard.png" width="200"> | <img src="app/assets/screenshots/add_crop.png" width="200"> | <img src="app/assets/screenshots/home.png" width="200"> | <img src="app/assets/screenshots/trace.png" width="200"> |

## 📂 Project Structure

```bash
AgriTrace-Mobile/
├── 📁 app
│   ├── 📁 android
│   │   ├── 📁 .gradle
│   │   │   ├── 📁 8.14
│   │   │   │   ├── 📁 checksums
│   │   │   │   │   ├── 📄 checksums.lock
│   │   │   │   │   ├── ⚙️ md5-checksums.bin
│   │   │   │   │   └── ⚙️ sha1-checksums.bin
│   │   │   │   ├── 📁 executionHistory
│   │   │   │   │   ├── ⚙️ executionHistory.bin
│   │   │   │   │   └── 📄 executionHistory.lock
│   │   │   │   ├── 📁 expanded
│   │   │   │   ├── 📁 fileChanges
│   │   │   │   │   └── ⚙️ last-build.bin
│   │   │   │   ├── 📁 fileHashes
│   │   │   │   │   ├── ⚙️ fileHashes.bin
│   │   │   │   │   ├── 📄 fileHashes.lock
│   │   │   │   │   └── ⚙️ resourceHashesCache.bin
│   │   │   │   ├── 📁 vcsMetadata
│   │   │   │   └── 📄 gc.properties
│   │   │   ├── 📁 buildOutputCleanup
│   │   │   │   ├── 📄 buildOutputCleanup.lock
│   │   │   │   ├── 📄 cache.properties
│   │   │   │   └── ⚙️ outputFiles.bin
│   │   │   ├── 📁 kotlin
│   │   │   │   └── 📁 errors
│   │   │   ├── 📁 noVersion
│   │   │   │   └── 📄 buildLogic.lock
│   │   │   ├── 📁 vcs-1
│   │   │   │   └── 📄 gc.properties
│   │   │   └── 📄 file-system.probe
│   │   ├── 📁 .kotlin
│   │   │   ├── 📁 errors
│   │   │   └── 📁 sessions
│   │   ├── 📁 app
│   │   │   ├── 📁 src
│   │   │   │   ├── 📁 debug
│   │   │   │   │   └── ⚙️ AndroidManifest.xml
│   │   │   │   ├── 📁 main
│   │   │   │   │   ├── 📁 java
│   │   │   │   │   │   └── 📁 io
│   │   │   │   │   │       └── 📁 flutter
│   │   │   │   │   │           └── 📁 plugins
│   │   │   │   │   │               └── ☕ GeneratedPluginRegistrant.java
│   │   │   │   │   ├── 📁 kotlin
│   │   │   │   │   │   └── 📁 com
│   │   │   │   │   │       └── 📁 example
│   │   │   │   │   │           └── 📁 flutter_app_agricultural_products
│   │   │   │   │   │               └── ☕ MainActivity.kt
│   │   │   │   │   ├── 📁 res
│   │   │   │   │   │   ├── 📁 drawable
│   │   │   │   │   │   │   └── ⚙️ launch_background.xml
│   │   │   │   │   │   ├── 📁 drawable-v21
│   │   │   │   │   │   │   └── ⚙️ launch_background.xml
│   │   │   │   │   │   ├── 📁 mipmap-hdpi
│   │   │   │   │   │   │   └── 🖼️ ic_launcher.png
│   │   │   │   │   │   ├── 📁 mipmap-mdpi
│   │   │   │   │   │   │   └── 🖼️ ic_launcher.png
│   │   │   │   │   │   ├── 📁 mipmap-xhdpi
│   │   │   │   │   │   │   └── 🖼️ ic_launcher.png
│   │   │   │   │   │   ├── 📁 mipmap-xxhdpi
│   │   │   │   │   │   │   └── 🖼️ ic_launcher.png
│   │   │   │   │   │   ├── 📁 mipmap-xxxhdpi
│   │   │   │   │   │   │   └── 🖼️ ic_launcher.png
│   │   │   │   │   │   ├── 📁 values
│   │   │   │   │   │   │   └── ⚙️ styles.xml
│   │   │   │   │   │   └── 📁 values-night
│   │   │   │   │   │       └── ⚙️ styles.xml
│   │   │   │   │   └── ⚙️ AndroidManifest.xml
│   │   │   │   └── 📁 profile
│   │   │   │       └── ⚙️ AndroidManifest.xml
│   │   │   └── 📄 build.gradle.kts
│   │   ├── 📁 gradle
│   │   │   └── 📁 wrapper
│   │   │       ├── 📄 gradle-wrapper.jar
│   │   │       └── 📄 gradle-wrapper.properties
│   │   ├── ⚙️ .gitignore
│   │   ├── 📄 build.gradle.kts
│   │   ├── 📄 flutter_app_agricultural_products_android.iml
│   │   ├── 📄 gradle.properties
│   │   ├── 📄 gradlew
│   │   ├── 📄 gradlew.bat
│   │   ├── 📄 local.properties
│   │   └── 📄 settings.gradle.kts
│   ├── 📁 assets
│   │   └── 📁 images
│   │       ├── 📄 3TMLNS.ico
│   │       ├── 🖼️ banner-2.jpg
│   │       ├── 🖼️ cai_thia.jpg
│   │       ├── 🖼️ farm_1.jpg
│   │       ├── 🖼️ fruit.png
│   │       └── 🖼️ lua.jpg
│   ├── 📁 ios
│   │   ├── 📁 Flutter
│   │   │   ├── 📁 ephemeral
│   │   │   │   ├── 🐍 flutter_lldb_helper.py
│   │   │   │   └── 📄 flutter_lldbinit
│   │   │   ├── 📄 AppFrameworkInfo.plist
│   │   │   ├── 📄 Debug.xcconfig
│   │   │   ├── 📄 Generated.xcconfig
│   │   │   ├── 📄 Release.xcconfig
│   │   │   └── 📄 flutter_export_environment.sh
│   │   ├── 📁 Runner
│   │   │   ├── 📁 Assets.xcassets
│   │   │   │   ├── 📁 AppIcon.appiconset
│   │   │   │   │   ├── ⚙️ Contents.json
│   │   │   │   │   ├── 🖼️ Icon-App-1024x1024@1x.png
│   │   │   │   │   ├── 🖼️ Icon-App-20x20@1x.png
│   │   │   │   │   ├── 🖼️ Icon-App-20x20@2x.png
│   │   │   │   │   ├── 🖼️ Icon-App-20x20@3x.png
│   │   │   │   │   ├── 🖼️ Icon-App-29x29@1x.png
│   │   │   │   │   ├── 🖼️ Icon-App-29x29@2x.png
│   │   │   │   │   ├── 🖼️ Icon-App-29x29@3x.png
│   │   │   │   │   ├── 🖼️ Icon-App-40x40@1x.png
│   │   │   │   │   ├── 🖼️ Icon-App-40x40@2x.png
│   │   │   │   │   ├── 🖼️ Icon-App-40x40@3x.png
│   │   │   │   │   ├── 🖼️ Icon-App-50x50@1x.png
│   │   │   │   │   ├── 🖼️ Icon-App-50x50@2x.png
│   │   │   │   │   ├── 🖼️ Icon-App-57x57@1x.png
│   │   │   │   │   ├── 🖼️ Icon-App-57x57@2x.png
│   │   │   │   │   ├── 🖼️ Icon-App-60x60@2x.png
│   │   │   │   │   ├── 🖼️ Icon-App-60x60@3x.png
│   │   │   │   │   ├── 🖼️ Icon-App-72x72@1x.png
│   │   │   │   │   ├── 🖼️ Icon-App-72x72@2x.png
│   │   │   │   │   ├── 🖼️ Icon-App-76x76@1x.png
│   │   │   │   │   ├── 🖼️ Icon-App-76x76@2x.png
│   │   │   │   │   └── 🖼️ Icon-App-83.5x83.5@2x.png
│   │   │   │   └── 📁 LaunchImage.imageset
│   │   │   │       ├── ⚙️ Contents.json
│   │   │   │       ├── 🖼️ LaunchImage.png
│   │   │   │       ├── 🖼️ LaunchImage@2x.png
│   │   │   │       ├── 🖼️ LaunchImage@3x.png
│   │   │   │       └── 📝 README.md
│   │   │   ├── 📁 Base.lproj
│   │   │   │   ├── 📄 LaunchScreen.storyboard
│   │   │   │   └── 📄 Main.storyboard
│   │   │   ├── 🍎 AppDelegate.swift
│   │   │   ├── ⚡ GeneratedPluginRegistrant.h
│   │   │   ├── 📄 GeneratedPluginRegistrant.m
│   │   │   ├── 📄 Info.plist
│   │   │   └── ⚡ Runner-Bridging-Header.h
│   │   ├── 📁 Runner.xcodeproj
│   │   │   ├── 📁 project.xcworkspace
│   │   │   │   ├── 📁 xcshareddata
│   │   │   │   │   ├── 📄 IDEWorkspaceChecks.plist
│   │   │   │   │   └── 📄 WorkspaceSettings.xcsettings
│   │   │   │   └── 📄 contents.xcworkspacedata
│   │   │   ├── 📁 xcshareddata
│   │   │   │   └── 📁 xcschemes
│   │   │   │       └── 📄 Runner.xcscheme
│   │   │   └── 📄 project.pbxproj
│   │   ├── 📁 Runner.xcworkspace
│   │   │   ├── 📁 xcshareddata
│   │   │   │   ├── 📄 IDEWorkspaceChecks.plist
│   │   │   │   └── 📄 WorkspaceSettings.xcsettings
│   │   │   └── 📄 contents.xcworkspacedata
│   │   ├── 📁 RunnerTests
│   │   │   └── 🍎 RunnerTests.swift
│   │   └── ⚙️ .gitignore
│   ├── 📁 lib
│   │   ├── 📁 configs
│   │   │   └── 📄 constants.dart
│   │   ├── 📁 screen
│   │   │   ├── 📄 add_crop_screen.dart
│   │   │   ├── 📄 care_diary_screen.dart
│   │   │   ├── 📄 distributor_main_screen.dart
│   │   │   ├── 📄 farm_detail_screen.dart
│   │   │   ├── 📄 farmer_main_screen.dart
│   │   │   ├── 📄 forgot_password_screen.dart
│   │   │   ├── 📄 harvest_product_screen.dart
│   │   │   ├── 📄 home_screen.dart
│   │   │   ├── 📄 inspector_main_screen.dart
│   │   │   ├── 📄 login_screen.dart
│   │   │   ├── 📄 notification_screen.dart
│   │   │   ├── 📄 product_trace_screen.dart
│   │   │   ├── 📄 profile_screen.dart
│   │   │   ├── 📄 qr_scanner_screen.dart
│   │   │   ├── 📄 retailer_main_screen.dart
│   │   │   ├── 📄 signup_screen.dart
│   │   │   └── 📄 transporter_main_screen.dart
│   │   └── 📄 main.dart
│   ├── 📁 linux
│   │   ├── 📁 flutter
│   │   │   ├── 📁 ephemeral
│   │   │   │   └── 📁 .plugin_symlinks
│   │   │   │       ├── 📄 file_selector_linux
│   │   │   │       ├── 📄 image_picker_linux
│   │   │   │       ├── 📄 path_provider_linux
│   │   │   │       ├── 📄 shared_preferences_linux
│   │   │   │       └── 📄 url_launcher_linux
│   │   │   ├── 📄 CMakeLists.txt
│   │   │   ├── ⚡ generated_plugin_registrant.cc
│   │   │   ├── ⚡ generated_plugin_registrant.h
│   │   │   └── 📄 generated_plugins.cmake
│   │   ├── 📁 runner
│   │   │   ├── 📄 CMakeLists.txt
│   │   │   ├── ⚡ main.cc
│   │   │   ├── ⚡ my_application.cc
│   │   │   └── ⚡ my_application.h
│   │   ├── ⚙️ .gitignore
│   │   └── 📄 CMakeLists.txt
│   ├── 📁 macos
│   │   ├── 📁 Flutter
│   │   │   ├── 📁 ephemeral
│   │   │   │   ├── 📄 Flutter-Generated.xcconfig
│   │   │   │   └── 📄 flutter_export_environment.sh
│   │   │   ├── 📄 Flutter-Debug.xcconfig
│   │   │   ├── 📄 Flutter-Release.xcconfig
│   │   │   └── 🍎 GeneratedPluginRegistrant.swift
│   │   ├── 📁 Runner
│   │   │   ├── 📁 Assets.xcassets
│   │   │   │   └── 📁 AppIcon.appiconset
│   │   │   │       ├── ⚙️ Contents.json
│   │   │   │       ├── 🖼️ app_icon_1024.png
│   │   │   │       ├── 🖼️ app_icon_128.png
│   │   │   │       ├── 🖼️ app_icon_16.png
│   │   │   │       ├── 🖼️ app_icon_256.png
│   │   │   │       ├── 🖼️ app_icon_32.png
│   │   │   │       ├── 🖼️ app_icon_512.png
│   │   │   │       └── 🖼️ app_icon_64.png
│   │   │   ├── 📁 Base.lproj
│   │   │   │   └── 📄 MainMenu.xib
│   │   │   ├── 📁 Configs
│   │   │   │   ├── 📄 AppInfo.xcconfig
│   │   │   │   ├── 📄 Debug.xcconfig
│   │   │   │   ├── 📄 Release.xcconfig
│   │   │   │   └── 📄 Warnings.xcconfig
│   │   │   ├── 🍎 AppDelegate.swift
│   │   │   ├── 📄 Info.plist
│   │   │   └── 🍎 MainFlutterWindow.swift
│   │   ├── 📁 Runner.xcodeproj
│   │   │   ├── 📁 project.xcworkspace
│   │   │   │   └── 📁 xcshareddata
│   │   │   │       └── 📄 IDEWorkspaceChecks.plist
│   │   │   ├── 📁 xcshareddata
│   │   │   │   └── 📁 xcschemes
│   │   │   │       └── 📄 Runner.xcscheme
│   │   │   └── 📄 project.pbxproj
│   │   ├── 📁 Runner.xcworkspace
│   │   │   ├── 📁 xcshareddata
│   │   │   │   └── 📄 IDEWorkspaceChecks.plist
│   │   │   └── 📄 contents.xcworkspacedata
│   │   ├── 📁 RunnerTests
│   │   │   └── 🍎 RunnerTests.swift
│   │   └── ⚙️ .gitignore
│   ├── 📁 test
│   │   └── 📄 widget_test.dart
│   ├── 📁 web
│   │   ├── 📁 icons
│   │   │   ├── 🖼️ Icon-192.png
│   │   │   ├── 🖼️ Icon-512.png
│   │   │   ├── 🖼️ Icon-maskable-192.png
│   │   │   └── 🖼️ Icon-maskable-512.png
│   │   ├── 🖼️ favicon.png
│   │   ├── 🌐 index.html
│   │   └── ⚙️ manifest.json
│   ├── 📁 windows
│   │   ├── 📁 flutter
│   │   │   ├── 📁 ephemeral
│   │   │   │   ├── 📁 .plugin_symlinks
│   │   │   │   │   ├── 📄 file_selector_windows
│   │   │   │   │   ├── 📄 image_picker_windows
│   │   │   │   │   ├── 📄 path_provider_windows
│   │   │   │   │   ├── 📄 shared_preferences_windows
│   │   │   │   │   └── 📄 url_launcher_windows
│   │   │   │   └── 📄 generated_config.cmake
│   │   │   ├── 📄 CMakeLists.txt
│   │   │   ├── ⚡ generated_plugin_registrant.cc
│   │   │   ├── ⚡ generated_plugin_registrant.h
│   │   │   └── 📄 generated_plugins.cmake
│   │   ├── 📁 runner
│   │   │   ├── 📁 resources
│   │   │   │   └── 📄 app_icon.ico
│   │   │   ├── 📄 CMakeLists.txt
│   │   │   ├── 📄 Runner.rc
│   │   │   ├── ⚡ flutter_window.cpp
│   │   │   ├── ⚡ flutter_window.h
│   │   │   ├── ⚡ main.cpp
│   │   │   ├── ⚡ resource.h
│   │   │   ├── 📄 runner.exe.manifest
│   │   │   ├── ⚡ utils.cpp
│   │   │   ├── ⚡ utils.h
│   │   │   ├── ⚡ win32_window.cpp
│   │   │   └── ⚡ win32_window.h
│   │   ├── ⚙️ .gitignore
│   │   └── 📄 CMakeLists.txt
│   ├── ⚙️ .gitignore
│   ├── ⚙️ .metadata
│   ├── 📝 README.md
│   ├── ⚙️ analysis_options.yaml
│   ├── ⚙️ devtools_options.yaml
│   ├── 🖼️ flutter_01.png
│   ├── 📄 flutter_app_agricultural_products.iml
│   └── ⚙️ pubspec.yaml
├── ⚙️ .gitignore
└── 📝 README.md
```

## 🚀 Getting Started

To run this application locally, you need to have the **Backend Server** running first.

### Prerequisites

- Flutter SDK (Latest Stable)
- Android Studio / VS Code
- AgriTrace Backend running (Localhost or Render URL)

### Installation

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/nvthih24/AgriTrace-Mobile.git
    ```

2.  **Navigate to the project directory:**

    ```bash
    cd AgriTrace-Mobile/app
    ```

3.  **Install dependencies:**

    ```bash
    flutter pub get
    ```

4.  **Configure API URL:**
    Open `lib/configs/constants.dart` and update your backend URL:

    ```dart
    class Constants {
      static const String baseUrl = "https://your-backend-url.onrender.com/api";
    }
    ```

5.  **Run the app:**

    ```bash
    flutter run
    ```

## 🤝 Contributing

Contributions are welcome\! If you have suggestions for improvements, please open an issue or submit a pull request.

## 📄 License

This project is licensed under the MIT License.
