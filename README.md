# FloatTranslate

FloatTranslate 是一个面向 macOS 的划词翻译工具：在 Word、PDF、网页、聊天软件等场景中选中文字，按下快捷键，翻译、词典解释和朗读面板会直接出现在当前内容旁边。

它想解决的不是“能不能翻译”，而是翻译时经常被打断的问题：复制、切窗口、粘贴、再切回来。FloatTranslate 把这个流程压缩成一次选中和一次快捷键。

## 核心体验

- 选中文字后快速翻译，不离开当前软件
- 支持英文单词、英文短语、英文句子和中文到英文
- 支持词典解释、音标、英音和美音朗读
- 适合阅读英文网页、PDF、论文、产品文档、聊天消息、Word/PPT 内容
- 面向学生、办公用户、研究者、老师、内容创作者，以及所有需要处理中英文内容的人

## 场景示例

### 网页、PDF、文档里遇到英文

![英文阅读查词](promo/floattranslate/docs/scene-reading.svg)

选中 `on tour`，按下 `⌥ Space`，翻译面板直接出现在原文旁边。

### 单词发音和词典解释

![单词英美发音](promo/floattranslate/docs/scene-pronunciation.svg)

查看音标后，可以分别播放英音和美音，适合跟读和确认发音。

### 聊天、资料、Word 里随手翻

![聊天资料翻译](promo/floattranslate/docs/scene-chat.svg)

英文出现在聊天软件、办公资料或文档里时，不需要复制到网页翻译。

## 宣传视频源码

当前仓库中已放入 FloatTranslate 的宣传视频源码和说明：

[查看宣传视频源码与分镜说明](promo/floattranslate)

包含内容：

- `index.html`：视频画面、动效、字幕和场景脚本
- `hyperframes.json`：HyperFrames 入口配置
- `design.md`：设计方向说明
- `package.json`：本地渲染脚本
- `docs/*.svg`：GitHub 可直接预览的场景示例图

## 本地预览宣传视频

```bash
cd promo/floattranslate
npx hyperframes preview
```

## 本地渲染宣传视频

```bash
cd promo/floattranslate
npx hyperframes render
```

## 后续计划

- 补充正式下载页和安装说明
- 上传最终 `.mp4` 到 GitHub Releases 或官网
- 增加竖屏短视频版本，适配抖音、小红书、视频号
- 继续完善 macOS 客户端的词典准确度、朗读体验和用户设置
