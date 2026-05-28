# 开发环境总览 (macOS arm64)

> 供所有 AI 工具参考 — Reasonix / Codex / Cline / OpenClaw 通用

## 系统
- macOS 26.5, Darwin arm64, Apple Silicon
- 用户: wuxin

## 项目目录
所有项目在 `/Users/wuxin/Developer/` 下

| 项目 | 类型 | 技术栈 |
|------|------|--------|
| chess-park | Flutter App | Flutter 3.44 / Dart 3.12 |
| coffee-notes | Android App | Kotlin 1.9.22 / AGP 8.2.2 / KSP |
| ccswitch-bridge | AI 翻译代理 | Node.js (ESM) |
| ccswitch-deepseek-main | — | — |

## JDK
- JDK 21.0.11 LTS (Temurin) at `/Users/wuxin/dev-jdk21`
- 兼容 Java 17 目标

## Android SDK
- SDK: `/Users/wuxin/Library/Android/sdk`
- Platform: android-36 / Build-Tools: 36.0.0
- adb / NDK / CMake 已安装
- 构建: `ANDROID_HOME=/Users/wuxin/Library/Android/sdk flutter build apk --debug`

## Flutter
- Flutter 3.44.0 at `/Users/wuxin/flutter`
- `flutter config --jdk-dir /Users/wuxin/dev-jdk21`

## Node.js
- Node v25.8.0 / npm 11.11.0

## 环境变量
```
JAVA_HOME=/Users/wuxin/dev-jdk21
ANDROID_HOME=/Users/wuxin/Library/Android/sdk
```

## 已知坑
- local.properties 中 sdk.dir 需用全路径，`~` 不会被 Gradle 展开
- 未安装: Xcode.app, Go, Rust, Chrome
