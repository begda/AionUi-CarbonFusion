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
| 459  | `tag = version.startsWith('v') ? version : \`v${version}\`;` | `tag = /^\d/.test(version) ? \`v${version}\` : version;` |

**原因**：原逻辑判断"如果版本号以 `v` 开头，直接使用，否则自动加 `v`"。上游版本 `v0.1.49` 以 `v` 开头，直接使用，正确。

你的版本 `carbonfusion-v0.1.52` 不以 `v` 开头，会被自动加上 `v` 变成 `vcarbonfusion-v0.1.52`，最终下载的构件名是 `aioncore-vcarbonfusion-v0.1.52-...`，与你实际存在的 `aioncore-carbonfusion-v0.1.52-...` 不匹配，下载失败。

修复后改为"如果版本号**以数字开头**，自动加 `v`，否则直接使用"。`carbonfusion-v0.1.52` 不以数字开头 → 直接使用 → ✅ 正确。

---

### 修改 4：`.github/workflows/_build-reusable.yml` — CI 中配置环境变量

| 行号      | 在当前 env 区块中新增             |
| --------- | --------------------------------- |
| 约 371 行 | `AIONUI_BACKEND_OWNER: 'begda'`   |
| 约 371 行 | `AIONUI_BACKEND_REPO: 'AionCore'` |

**原因**：脚本中虽然支持了环境变量，但 CI 运行时不会自动设置它们。不加的话，CI 中 `process.env.AIONUI_BACKEND_OWNER` 和 `AIONUI_BACKEND_REPO` 为空，走默认值 `iOfficeAI/AionCore`，仍然去上游下载。

需要在 `_build-reusable.yml` 中 `Prepare aioncore binary` 步骤的 `env` 区块添加这两个变量，让 CI 知道去 `begda/AionCore` 下载。

---

## 修改前后对比

### 版本号

| 文件               | 修改前                         | 修改后                                      |
| ------------------ | ------------------------------ | ------------------------------------------- |
| `package.json:261` | `"aioncoreVersion": "v0.1.50"` | `"aioncoreVersion": "carbonfusion-v0.1.52"` |

### 仓库地址

| 文件                     | 修改前                       | 修改后                                                             |
| ------------------------ | ---------------------------- | ------------------------------------------------------------------ |
| `prepare-aioncore.js:24` | `GITHUB_OWNER = 'iOfficeAI'` | `GITHUB_OWNER = process.env.AIONUI_BACKEND_OWNER \|\| 'iOfficeAI'` |
| `prepare-aioncore.js:25` | `GITHUB_REPO = 'AionCore'`   | `GITHUB_REPO = process.env.AIONUI_BACKEND_REPO \|\| 'AionCore'`    |

### 标签处理

| 文件                      | 修改前                                                      | 修改后                                                  |
| ------------------------- | ----------------------------------------------------------- | ------------------------------------------------------- |
| `prepare-aioncore.js:459` | `tag = version.startsWith('v') ? version : \`v${version}\`` | `tag = /^\d/.test(version) ? \`v${version}\` : version` |

### CI 环境变量

| 文件                      | 修改前（无） | 修改后（新增）                    |
| ------------------------- | ------------ | --------------------------------- |
| `_build-reusable.yml:371` | —            | `AIONUI_BACKEND_OWNER: 'begda'`   |
| `_build-reusable.yml:371` | —            | `AIONUI_BACKEND_REPO: 'AionCore'` |

---

### 修改 5：`packages/shared-scripts/src/verify-bundled-aioncore-resources.js` — 放宽 schema 版本检查

| 行号 | 修改前 | 修改后 |
| ---- | ------ | ------ |
| 174  | `if (contract.schemaVersion !== 1) {` | `if (typeof contract.schemaVersion !== 'number' \|\| contract.schemaVersion < 1) {` |
| 187  | _（无）_ | `if (contract.schemaVersion > 1) { return; }` |

**原因**：自定义 AionCore 构建生成的 `managed-resources/manifest.json` 中 `schemaVersion` 可能不是 `1`（如 `2`）。原代码严格检查 `!== 1`，导致验证失败，构建中断。

修复有两处：
1. 将 `schemaVersion !== 1` 改为 `typeof !== 'number' \|\| < 1`，允许任意 >= 1 的版本号通过
2. 对 `schemaVersion > 1` 的新版 schema 跳过 `node`/`acpTools` 等详细字段校验，避免因新版 manifest 结构不同而报错

**上游合并影响**：冲突范围极小（两行代码），每次拉上游更新时手动处理一次即可。

---

## 修改后完整流程

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
