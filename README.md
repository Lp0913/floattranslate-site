# FloatTranslate

FloatTranslate 是一个面向 macOS 的划词翻译工具：在 Word、PDF、网页、聊天软件等场景中选中文字，按下快捷键，翻译、词典解释和朗读面板会直接出现在当前内容旁边。

这个仓库现在已经作为 FloatTranslate 的主展示项目使用，原来的 IELTS 点读器页面已被覆盖。

## 核心体验

- 选中文字后快速翻译，不离开当前软件
- 支持英文单词、英文短语、英文句子和中文到英文
- 支持词典解释、音标、英音和美音朗读
- 适合阅读英文网页、PDF、论文、产品文档、聊天消息、Word/PPT 内容
- 面向学生、办公用户、研究者、老师、内容创作者，以及所有需要处理中英文内容的人

## 主页面

根目录文件已经改成 FloatTranslate 展示页：

- `index.html`：官网/落地页结构
- `styles.css`：页面样式
- `app.js`：页面交互
- `manifest.webmanifest`：应用名称和主题信息

## 宣传视频源码

宣传视频源码和分镜说明保留在：

[查看 promo/floattranslate](promo/floattranslate)

包含：

- `index.html`：视频画面、动效、字幕和场景脚本
- `hyperframes.json`：HyperFrames 入口配置
- `design.md`：设计方向说明
- `docs/*.svg`：GitHub 可直接预览的场景示例图

## 后续建议

- 在仓库 Settings 里把仓库名从 `ielts-click-reader-frontend` 改成 `floattranslate` 或 `floattranslate-site`
- 开启 GitHub Pages，让 `index.html` 变成可访问官网
- 上传最终 `.mp4` 到 GitHub Releases 或官网
- 增加正式下载包、安装说明和权限说明
