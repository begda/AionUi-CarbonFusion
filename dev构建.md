# Dev 分支构建 - 平台适配修改

## 问题

当前 `dev` 分支使用 `build-and-release.yml` 构建 6 个平台，但 AionCore 只有 4 个构件：
- 缺少 `macOS x64`（`x86_64-apple-darwin`）
- 缺少 `Linux ARM64`（`aarch64-unknown-linux-gnu`）

导致构建失败，Release 无法创建。

---

## 修改清单

### 修改 1：`.github/workflows/build-and-release.yml` — 缩减构建矩阵

| 行号 | 修改前 | 修改后 |
| ---- | ------ | ------ |
| 64-72 | 6 平台矩阵 | 4 平台矩阵 |

**当前矩阵（6 平台）：**
```yaml
matrix: >-
  {"include":[
    {"platform":"macos-arm64","os":"macos-14",...},
    {"platform":"macos-x64","os":"macos-14",...},      # 删除
    {"platform":"windows-x64","os":"windows-2022",...},
    {"platform":"windows-arm64","os":"windows-11-arm",...},
    {"platform":"linux-x64","os":"ubuntu-latest",...},
    {"platform":"linux-arm64","os":"ubuntu-24.04-arm",...}  # 删除
  ]}
```

**修改后（4 平台）：**
```yaml
matrix: >-
  {"include":[
    {"platform":"macos-arm64","os":"macos-14","command":"node scripts/build-with-builder.js arm64 --mac --arm64","artifact-name":"macos-build-arm64","arch":"arm64"},
    {"platform":"windows-x64","os":"windows-2022","command":"node scripts/build-with-builder.js x64 --win --x64","artifact-name":"windows-build-x64","arch":"x64"},
    {"platform":"windows-arm64","os":"windows-11-arm","command":"node scripts/build-with-builder.js arm64 --win --arm64","artifact-name":"windows-build-arm64","arch":"arm64"},
    {"platform":"linux-x64","os":"ubuntu-latest","command":"node scripts/build-with-builder.js x64 --linux --x64","artifact-name":"linux-build-x64","arch":"x64"}
  ]}
```

---

### 修改 2：`scripts/prepare-release-assets.sh` — 放宽资产验证

| 行号 | 修改前 | 修改后 |
| ---- | ------ | ------ |
| 122  | `latest-mac.yml latest-linux-arm64.yml` 在必选列表中 | 从必选列表移除 |
| 134-146 | 循环验证 `mac-x64` 和 `mac-arm64` 的 DMG/ZIP | 只验证 `mac-arm64` |

**原因**：不构建 `macos-x64` 和 `linux-arm64` 后，这些产物不会生成。Release 资产验证脚本会检查所有平台产物是否齐全，不修改的话会报错退出。

---

## 修改前后对比

### 构建平台

| 平台 | 修改前 | 修改后 |
|------|--------|--------|
| macOS ARM64 | ✅ | ✅ |
| macOS x64 | ✅ | ❌ |
| Windows x64 | ✅ | ✅ |
| Windows ARM64 | ✅ | ✅ |
| Linux x64 | ✅ | ✅ |
| Linux ARM64 | ✅ | ❌ |

---

## 修改后完整流程

```
dev 分支 push
  → build-and-release.yml 触发
  → code-quality 检查
  → 4 平台并行构建（macos-arm64 + windows-x64 + windows-arm64 + linux-x64）
  → 每个平台分别从 begda/AionCore 下载对应 AionCore 构件
  → 验证 Release 资产（只检查 4 个平台的产物）
  → 创建 tag（v{VERSION}-dev-{COMMIT_SHORT}）
  → 创建并发布 Release（draft: false）
```