# FloatTranslate

FloatTranslate 是一个 macOS 原生划词翻译工具。启动后它在后台和菜单栏运行，你在 Word、PDF、网页、聊天软件等任意应用中选中文字，按下快捷键，翻译、词典解释和朗读面板会直接出现在当前内容旁边。

![FloatTranslate 产品预览](docs/images/product-overview-v2.svg)

## 演示视频

https://github.com/user-attachments/assets/3af9335e-c56f-4d53-8ccd-713473d8ea7b

## 下载体验版

打包好的 Mac 体验版建议放在 GitHub Releases 中，避免把二进制安装包直接混进源码目录。

- 下载入口：[GitHub Releases](https://github.com/Lp0913/floattranslate-site/releases)
- 推荐安装包命名：`FloatTranslate-macOS.zip`
- 后续正式一点可以命名为：`FloatTranslate-macOS-v0.1.0.zip`

如果你是普通用户，只需要下载 `.zip`，解压后把 `FloatTranslate.app` 拖到 `应用程序` 文件夹即可。

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

如果 Swift 在本机缓存目录报权限问题，可以把模块缓存放到临时目录：

```bash
CLANG_MODULE_CACHE_PATH=/private/tmp/floattranslate-clang-cache \
SWIFT_MODULECACHE_PATH=/private/tmp/floattranslate-swift-cache \
swift build --disable-sandbox -c release --product FloatTranslate
```

## 运行测试

```bash
swift test
./scripts/run-self-tests.sh
```

如果 `swift test` 提示找不到 `XCTest`，通常是 Xcode 或 Command Line Tools 没有正确安装或选择。可以先运行：

```bash
xcode-select -p
```

确认当前使用的是可用的 Xcode/Command Line Tools。

## 源码结构

```text
Sources/FloatTranslate/
  FloatTranslateApp.swift              应用入口
  AppDelegate.swift                     菜单栏、权限、快捷键协调
  TextCaptureService.swift              跨应用读取选中文字
  HotKeyManager.swift                   全局快捷键
  TranslationViewModel.swift            翻译流程、状态、超时处理
  TranslationCardView.swift             浮动翻译面板
  TranslationPanelController.swift      NSPanel 展示和定位
  DictionaryService.swift               macOS 系统词典查询
  DefinitionFormatter.swift             词典释义、词性、音标格式化
  SpeechService.swift                   系统朗读、英音/美音/中文语音
  SettingsView.swift                    设置界面
Resources/
  Info.plist                            macOS App 配置
scripts/
  build-app.sh                          构建 .app
  package-for-sharing.sh                打包分享版
  setup-local-signing.sh                本地签名身份
  run-self-tests.sh                     自测脚本
```

## 权限说明

FloatTranslate 需要两个 macOS 权限：

- 辅助功能：用于读取当前应用中的选中文字
- 输入监控：用于监听全局快捷键

这些权限只用于本机读取选择文本和响应快捷键。当前版本不包含用户账户、云端同步或付费知识库功能。

## 隐私说明

当前版本优先使用 macOS 系统翻译、系统词典和系统朗读能力。选中的文本主要在本机处理。后续如果加入云端账户、生词本、知识库或在线翻译服务，应在应用和官网中单独说明数据上传范围、保存方式和删除方式。

## 后续计划

- 本地生词收藏
- 云端账号和同步
- 生词复习、单词总结
- 更完整的安装引导页
- 正式签名和公证下载包
- 官网下载页和更新日志
