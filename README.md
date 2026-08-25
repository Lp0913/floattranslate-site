# FloatTranslate

FloatTranslate 是一个 macOS 原生划词翻译工具。启动后它在后台和菜单栏运行，你在 Word、PDF、网页、聊天软件等任意应用中选中文字，按下快捷键，翻译、词典解释和朗读面板会直接出现在当前内容旁边。

这个仓库用于放 FloatTranslate 软件源码、构建脚本、安装说明和使用说明。旧的 IELTS 点读器网页内容已经不作为本项目内容使用。

## 适合谁使用

- 经常阅读英文网页、PDF、论文、产品文档的人
- 需要处理中英文消息、邮件、Word/PPT 内容的办公用户
- 需要查单词、短语、句子含义和发音的学习者
- 需要中译英表达参考的写作者、老师、内容创作者

## 核心功能

- 跨应用选中文字后翻译，不需要复制粘贴到网页
- 支持英文单词、英文短语、英文句子和中文到英文
- 支持词典释义、词性、音标、例句
- 支持英音和美音朗读按钮
- 支持菜单栏后台运行，没有主窗口打扰
- 支持快捷键唤起浮动面板，默认快捷键为 `⌥ Space`
- 使用 macOS 原生界面和系统能力

## 适配电脑和系统

当前版本面向：

- macOS 15.0 或更高版本
- Apple 芯片 Mac，M1/M2/M3/M4 系列优先
- 主要支持中文和英文互译

说明：应用使用 Apple 系统翻译能力和本地朗读能力。首次使用某些语言时，系统可能需要下载语言模型。

## 如何安装

如果你拿到的是打包好的 `FloatTranslate.app` 或 `.zip`：

1. 解压下载包
2. 把 `FloatTranslate.app` 拖到 `应用程序` 文件夹
3. 双击启动
4. 如果 macOS 提示“无法验证开发者”，到 `系统设置` → `隐私与安全性` 中允许打开
5. 首次启动后，按提示开启：
   - `辅助功能` 权限：用于读取当前选中的文字
   - `输入监控` 权限：用于监听全局快捷键 `⌥ Space`
6. 重新启动 FloatTranslate

启动成功后，它会出现在 macOS 菜单栏中，不会显示 Dock 图标。

## 如何使用

1. 打开 Word、PDF、网页、微信、邮件或其他应用
2. 用鼠标选中一个英文单词、短语、句子，或者一段中文
3. 按 `⌥ Space`
4. FloatTranslate 会在选中文字旁边弹出翻译面板
5. 点击扬声器可以朗读原文
6. 对英文单词，可分别点击英音和美音按钮
7. 点击关闭按钮或按 `Esc` 可以关闭面板

## 从源码构建

需要当前版本 Xcode 或 Command Line Tools。

```bash
chmod +x scripts/build-app.sh
chmod +x scripts/setup-local-signing.sh
./scripts/setup-local-signing.sh
./scripts/build-app.sh
open dist/FloatTranslate.app
```

构建产物会输出到：

```text
dist/FloatTranslate.app
```

## 运行测试

```bash
swift test
```

或者运行项目内自检脚本：

```bash
./scripts/run-self-tests.sh
```

## 源码结构

```text
Package.swift
Resources/Info.plist
Sources/FloatTranslate/
Tests/FloatTranslateTests/
scripts/
```

主要模块：

- `TextCaptureService`：跨应用获取选中文字
- `HotKeyManager`：全局快捷键
- `TranslationPanelController`：浮动面板控制
- `TranslationCardView`：翻译卡片界面
- `DictionaryService`：词典和释义
- `SpeechService`：英音、美音朗读
- `AppSettings` / `SettingsView`：用户设置

## 隐私说明

FloatTranslate 的目标是尽量使用 macOS 本地能力完成翻译和朗读。当前版本不存储用户选中的文本，也不保存翻译历史。

## 后续计划

- 增加正式签名和公证版本
- 增加官网下载包和版本发布页
- 增加本地生词收藏
- 增加云端账户和知识库能力
- 优化更多词典释义和短语覆盖
