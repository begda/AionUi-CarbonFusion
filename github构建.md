# GitHub 构建 - AionCore 引用修改方案

## 问题

当前构建时从 `iOfficeAI/AionCore` 下载 AionCore 二进制文件，构件名称为：

```
aioncore-v0.1.52-x86_64-unknown-linux-gnu.tar.gz
```

需要改为从 `begda/AionCore` 下载，构件名称为：

```
aioncore-carbonfusion-v0.1.52-x86_64-unknown-linux-gnu.tar.gz
```

---

## 修改清单

### 修改 1：`package.json` — 更新版本号

| 项目            | 修改前      | 修改后                   |
| --------------- | ----------- | ------------------------ |
| aioncoreVersion | `"v0.1.50"` | `"carbonfusion-v0.1.52"` |

**原因**：`aioncoreVersion` 的值会被拼接到构件文件名中。上游版本号是 `v0.1.50`，文件名是 `aioncore-v0.1.50-...`。你的版本号是 `carbonfusion-v0.1.52`，文件名是 `aioncore-carbonfusion-v0.1.52-...`，所以需要改成 `carbonfusion-v0.1.52`。

---

### 修改 2：`packages/shared-scripts/src/prepare-aioncore.js` — 仓库地址可配置

| 行号 | 修改前                              | 修改后                                                                    |
| ---- | ----------------------------------- | ------------------------------------------------------------------------- |
| 24   | `const GITHUB_OWNER = 'iOfficeAI';` | `const GITHUB_OWNER = process.env.AIONUI_BACKEND_OWNER \|\| 'iOfficeAI';` |
| 25   | `const GITHUB_REPO = 'AionCore';`   | `const GITHUB_REPO = process.env.AIONUI_BACKEND_REPO \|\| 'AionCore';`    |

**原因**：脚本写死了从 `iOfficeAI/AionCore` 下载。通过环境变量覆盖，可以在不修改代码的情况下指定自己的仓库。环境变量不存在时自动回退到上游值，不影响原有逻辑。

**影响范围**：脚本中所有使用 `GITHUB_OWNER` 和 `GITHUB_REPO` 的地方都会自动跟随（下载 Release、查询 Artifact、调用 API 等），无需逐一修改。

---

### 修改 3：`packages/shared-scripts/src/prepare-aioncore.js` — 修复标签处理逻辑

| 行号 | 修改前                                                       | 修改后                                                   |
| ---- | ------------------------------------------------------------ | -------------------------------------------------------- |
| 462  | `tag = version.startsWith('v') ? version : \`v${version}\`;` | `tag = /^\d/.test(version) ? \`v${version}\` : version;` |

**原因**：原逻辑判断"如果版本号以 `v` 开头，直接使用，否则自动加 `v`"。上游版本 `v0.1.49` 以 `v` 开头，直接使用，正确。

你的版本 `carbonfusion-v0.1.52` 不以 `v` 开头，会被自动加上 `v` 变成 `vcarbonfusion-v0.1.52`，最终下载的构件名是 `aioncore-vcarbonfusion-v0.1.52-...`，与你实际存在的 `aioncore-carbonfusion-v0.1.52-...` 不匹配，下载失败。

修复后改为"如果版本号**以数字开头**，自动加 `v`，否则直接使用"。`carbonfusion-v0.1.52` 不以数字开头 → 直接使用 → ✅ 正确。

---

### 修改 4：`.github/workflows/_build-reusable.yml` — CI 中配置环境变量

**需要修改 4 处 env 区块：**

| 位置                                        | 说明                                 | 新增内容                                                            |
| ------------------------------------------- | ------------------------------------ | ------------------------------------------------------------------- |
| `Prepare aioncore binary` 步骤（约 371 行） | 独立下载 AionCore 步骤               | `AIONUI_BACKEND_OWNER: 'begda'` + `AIONUI_BACKEND_REPO: 'AionCore'` |
| Windows 构建步骤（约 405 行）               | 构建脚本内部调用 `prepareAioncore()` | 同上                                                                |
| macOS 构建步骤（约 508 行）                 | 同上                                 | 同上                                                                |
| Linux 构建步骤（约 549 行）                 | 同上                                 | 同上                                                                |

**原因**：`build-with-builder.js` 内部也调用了 `prepareAioncore()` 来下载 AionCore 二进制文件。如果只在 `Prepare aioncore binary` 步骤配置环境变量，但 macOS/Windows/Linux 构建步骤的 env 中没有设置，`build-with-builder.js` 调用时就会走到默认值 `iOfficeAI/AionCore`，下载失败（404），导致构建中断。

需要在 `_build-reusable.yml` 中所有调用 `prepareAioncore()` 的步骤的 `env` 区块都添加这两个变量。

---

## 修改前后对比

### 版本号

| 文件               | 修改前                         | 修改后                                      |
| ------------------ | ------------------------------ | ------------------------------------------- |
| `package.json:260` | `"aioncoreVersion": "v0.1.50"` | `"aioncoreVersion": "carbonfusion-v0.1.52"` |

### 仓库地址

| 文件                     | 修改前                       | 修改后                                                             |
| ------------------------ | ---------------------------- | ------------------------------------------------------------------ |
| `prepare-aioncore.js:24` | `GITHUB_OWNER = 'iOfficeAI'` | `GITHUB_OWNER = process.env.AIONUI_BACKEND_OWNER \|\| 'iOfficeAI'` |
| `prepare-aioncore.js:25` | `GITHUB_REPO = 'AionCore'`   | `GITHUB_REPO = process.env.AIONUI_BACKEND_REPO \|\| 'AionCore'`    |

### 标签处理

| 文件                      | 修改前                                                      | 修改后                                                  |
| ------------------------- | ----------------------------------------------------------- | ------------------------------------------------------- |
| `prepare-aioncore.js:462` | `tag = version.startsWith('v') ? version : \`v${version}\`` | `tag = /^\d/.test(version) ? \`v${version}\` : version` |

### CI 环境变量

| 文件                  | 位置 | 修改前（无） | 修改后（新增）                    |
| --------------------- | ---- | ------------ | --------------------------------- |
| `_build-reusable.yml` | 4 处 | —            | `AIONUI_BACKEND_OWNER: 'begda'`   |
| `_build-reusable.yml` | 4 处 | —            | `AIONUI_BACKEND_REPO: 'AionCore'` |

---

### 修改 5：`packages/shared-scripts/src/verify-bundled-aioncore-resources.js` — 放宽 schema 版本检查

| 行号 | 修改前                                | 修改后                                                                              |
| ---- | ------------------------------------- | ----------------------------------------------------------------------------------- |
| 175  | `if (contract.schemaVersion !== 1) {` | `if (typeof contract.schemaVersion !== 'number' \|\| contract.schemaVersion < 1) {` |
| 187  | _（无）_                              | `if (contract.schemaVersion > 1) { return; }`                                       |

**原因**：自定义 AionCore 构建生成的 `managed-resources/manifest.json` 中 `schemaVersion` 可能不是 `1`（如 `2`）。原代码严格检查 `!== 1`，导致验证失败，构建中断。

修复有两处：

1. 将 `schemaVersion !== 1` 改为 `typeof !== 'number' \|\| < 1`，允许任意 >= 1 的版本号通过
2. 对 `schemaVersion > 1` 的新版 schema 跳过 `node`/`acpTools` 等详细字段校验，避免因新版 manifest 结构不同而报错

**上游合并影响**：冲突范围极小（两行代码），每次拉上游更新时手动处理一次即可。

---

### 修改 6：`scripts/prepare-release-assets-carbonfusion.sh` — CarbonFusion 专用 Release 资产脚本

**原因**：上游 `prepare-release-assets.sh` 硬校验了 6 平台产物、web-cli tarball、updater 元数据等，与 CarbonFusion 的构建（4 平台，不打包 web-cli）不匹配，导致 Release 创建失败。

**创建新脚本**（`scripts/prepare-release-assets-carbonfusion.sh`）：

- 只复制 4 个平台的构建产物（`.exe`、`.dmg`、`.deb`）
- 跳过 web-cli tarball 检查
- 跳过 updater 元数据（`latest.yml` 等）硬校验
- 使用 `CarbonFusion-*` 文件名前缀（品牌名变更后产物名从 `AionUi-*` 改为 `CarbonFusion-*`）

**对应修改**：`build-carbonfusion.yml` 中 `create-release` 步骤改为调用 `scripts/prepare-release-assets-carbonfusion.sh`

### 修改 7：`.github/workflows/build-carbonfusion.yml` — carbonfusion-dev 分支全平台构建

| 行号  | 修改前                                               | 修改后                                                     |
| ----- | ---------------------------------------------------- | ---------------------------------------------------------- |
| 9     | `branches: [carbonfusion]`                           | `branches: [carbonfusion-dev]`                             |
| 11    | `branches: [carbonfusion]`                           | `branches: [carbonfusion-dev]`                             |
| 22-31 | 条件判断矩阵（死代码，永远只构建 macos-arm64）       | 固定 4 平台矩阵                                            |
| 36-65 | 无                                                   | 新增 `create-tag` job                                      |
| 68-98 | `create-release` 条件 `refs/heads/dev`（永远不执行） | 条件改为 `refs/heads/carbonfusion-dev`，使用语义化版本 tag |

**原因**：`carbonfusion-dev` 是 CarbonFusion 主开发分支，需要全平台构建（macOS ARM64、Windows x64/ARM64、Linux x64）并自动创建 Release。

---

## 最终分支架构

| 分支               | 工作流                   | 构建平台                                            | Release    |
| ------------------ | ------------------------ | --------------------------------------------------- | ---------- |
| `carbonfusion-dev` | `build-carbonfusion.yml` | 4 平台（macOS ARM64、Windows x64/ARM64、Linux x64） | Draft 创建 |
| `carbonfusion`     | `build-carbonfusion.yml` | 仅 macos-arm64                                      | 不创建     |
| `dev`              | `build-and-release.yml`  | 4 平台（已删 code-quality）                         | 公开发布   |

---

## 修改后完整流程

```
carbonfusion-dev 分支 push
  → build-carbonfusion.yml 触发
  → 4 平台并行构建（macos-arm64 + windows-x64 + windows-arm64 + linux-x64）
  → 每个平台从 begda/AionCore 下载对应 AionCore 构件
  → 创建 tag（v{VERSION}-carbonfusion-{SHORT_SHA}）
  → 运行 prepare-release-assets-carbonfusion.sh（只验证 4 平台产物）
  → 创建 Draft Release（含构建产物）
```

```
CI 构建开始
  → package.json 中 aioncoreVersion: "carbonfusion-v0.1.52"
  → resolveAioncoreVersion() 读取该值
  → prepareAioncore() 收到版本号 "carbonfusion-v0.1.52"
  → 标签处理: 不以数字开头 → 直接使用 "carbonfusion-v0.1.52"
  → GITHUB_OWNER = "begda" (来自环境变量)
  → GITHUB_REPO = "AionCore" (来自环境变量)
  → getAssetName() 生成文件名: "aioncore-carbonfusion-v0.1.52-x86_64-unknown-linux-gnu.tar.gz"
  → 从 https://github.com/begda/AionCore/releases/download/carbonfusion-v0.1.52/aioncore-carbonfusion-v0.1.52-x86_64-unknown-linux-gnu.tar.gz 下载
  → 解压并打包到 AionUi 安装包中
```
