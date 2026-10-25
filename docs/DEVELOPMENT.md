# 开发与发布

[返回项目介绍](../README.md)

## 环境

- macOS 与完整 Xcode，选择对应的 Command Line Tools。
- Python 3.10+；GitHub Actions 使用 Python 3.13。
- 发布时需要 Git 和已登录的 GitHub CLI（`gh auth login`）。

如安装了多套 Xcode，可通过 `DEVELOPER_DIR` 选择。打包与测试使用的 Python 可通过 `LANGUAGE_SWITCHER_PYTHON` 指定；Xcode DerivedData 路径可通过 `LANGUAGE_SWITCHER_DERIVED_DATA` 指定。

## 验证与构建

在项目根目录运行：

```bash
# Shell 语法、全部图标尺寸、语言排序及启动失败处理。
bash scripts/test.sh

# 仅构建双架构应用。
bash scripts/build.sh

# 构建应用，生成并验证 DMG。
bash build_universal.sh
```

产物：

| 路径 | 内容 |
| --- | --- |
| `build/LanguageSwitcher.app` | ad-hoc 签名的 Universal 应用 |
| `dist/LanguageSwitcher.dmg` | 拖拽安装包 |
| `dist/LanguageSwitcher.dmg.sha256` | 安装包 SHA-256 |
| `build/build.log` | Xcode 完整构建日志 |
| `build/dmg/background@2x.png` | 安装背景预览 |

打包依赖仅安装到 `build/dmg-venv`，版本以 `Tools/dmg-requirements.txt` 为准。应用运行时不依赖 Python。

## 复用现有应用

```bash
# 打包 build/LanguageSwitcher.app，不重新编译应用。
bash create_dmg.sh

# 指定应用与输出路径。
bash create_dmg.sh build/LanguageSwitcher.app dist/LanguageSwitcher-custom.dmg

# 等价的底层入口。
bash scripts/package-dmg.sh --skip-build
bash scripts/package-dmg.sh --help
```

相对路径基于当前工作目录；应用必须名为 `LanguageSwitcher.app`，版本必须与当前工程一致。

打包时会检查应用标识、版本、arm64 / x86_64 架构、签名和编译后的图标，再验证 DMG 完整性、挂载后的应用与 Applications 快捷方式。所有检查通过后才替换最终安装包。

```bash
cd dist
shasum -a 256 -c LanguageSwitcher.dmg.sha256
```

Xcode 构建使用增量缓存，DMG 背景工具仅在源码变化时重新编译。图标缺失或生成源码更新时会自动重建；打包临时目录会在结束后清理。

## 图标

图标由 `GenerateIcon.swift` 使用 AppKit 与系统字体绘制，分别渲染全部 10 档 16–1024px macOS 资产。小尺寸减少描边细节，无需图片生成服务。

```bash
bash generate_icon.sh
```

输出目录为 `LanguageSwitcher/Assets.xcassets/AppIcon.appiconset`。安装背景读取所打包应用中的图标，保证自定义应用路径也使用对应资产。

## GitHub Actions

工作流位于 [`.github/workflows/release.yml`](../.github/workflows/release.yml)，共用上述本地脚本。

| 触发方式 | 行为 |
| --- | --- |
| 推送 `main` / `master`、提交 PR | 测试 → 双架构构建 → DMG 验证 → 上传 artifact |
| Actions 页面手动运行 | 同上，方便下载验证包 |
| 推送 `v*` 标签 | 校验版本 → 同上 → 发布 GitHub Release |

构建使用 `macos-26`，缓存 Xcode 数据与 pip 下载。安装包 artifact 保留 14 天，日志保留 7 天；失败时同样上传日志并显示错误注解。构建 job 只有仓库读取权限，独立的发布 job 才有 Release 写入权限。

工作流使用 GitHub 自动提供的 `github.token`，无需额外 secret。同一个标签重新运行会更新对应 Release 的附件。

## 发布版本

版本唯一来源为 Xcode 工程的 `MARKETING_VERSION`；修改时同步更新 Debug 和 Release 配置。标签必须与 Release 配置完全一致，例如 `1.0` 对应 `v1.0`。

从干净的 `main` 分支执行：

```bash
bash scripts/release.sh
```

脚本先运行测试，再原子推送 `main` 和版本标签。也可手动创建并推送标签：

```bash
git tag v1.0
git push origin v1.0
```

推送普通提交只生成 Actions artifact；推送版本标签才会发布 Release。安装包采用 ad-hoc 签名，未经 Developer ID 签名或 Apple 公证。

## 项目结构

```text
LanguageSwitcher/              SwiftUI 界面与语言扫描 / 启动逻辑
LanguageSwitcher.xcodeproj/    Xcode 工程与共享 scheme
GenerateIcon.swift             图标矢量源文件
generate_icon.sh               图标生成入口
scripts/                      构建、验证、打包与发布脚本
Tools/                        DMG 背景、布局与固定依赖
Tests/                        图标资产与语言扫描测试
.github/workflows/            GitHub Actions
```
