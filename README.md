# 象棋乐园 (Chess Park)

一款 Flutter 中国象棋 App，支持人机对弈。

## 功能特性

- 🎮 人机对弈 — Minimax + Alpha-Beta 剪枝 AI，三档难度可选
- ♟️ 完整象棋规则 — 将帅照面、蹩马腿、塞象眼、炮架等规则完整实现
- 🔄 悔棋 — 基于棋盘快照的完整悔棋功能
- 🔀 换边 — 支持红/黑方切换，AI 先手时自动走棋
- 📊 胜负统计 — 实时记录对局胜负
- ✨ 走棋动画 — 棋子平滑滑动，清晰展示落子轨迹

## 技术栈

- Flutter 3.44 / Dart 3.12
- 状态管理：Provider
- AI：Minimax 搜索 + Alpha-Beta 剪枝 + 位置评分表 + 走法排序

## 项目结构

```
lib/
├── main.dart                      # App 入口
├── domain/
│   ├── board.dart                 # 棋盘与位置定义
│   ├── piece.dart                 # 棋子枚举与显示
│   └── rules.dart                 # 象棋规则引擎
├── data/
│   └── ai_engine.dart             # AI 引擎（Minimax）
└── presentation/
    ├── main_screen.dart           # 主界面
    ├── chess_board_widget.dart    # 棋盘渲染与交互
    └── game_state.dart            # 游戏状态管理
```

## 开发环境

- Flutter 3.44.0 / Dart 3.12.0
- Android SDK 36 / JDK 21

## 构建运行

```bash
# 调试模式
flutter run

# Release APK
flutter build apk --release
```
