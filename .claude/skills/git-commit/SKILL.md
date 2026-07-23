---
name: "git-commit"
description: "Use this skill when the user asks to commit code, stage changes, or create a Git commit. Triggers include: \"提交代码\", \"commit\", \"git commit\", \"提交\", \"我要提交\", \"帮我提交\". This skill guides the workflow of reviewing changes, extracting context from the conversation, generating a Chinese Conventional Commit message, confirming with the user, and executing the commit safely."
---

---
name: git-commit
description: "使用此技能处理 Git 提交相关请求。触发词：提交代码、commit、git commit、提交、我要提交、帮我提交。工作流：查看改动 → 结合对话上下文生成中文提交信息 → 用户确认 → 执行提交。"
---

# Git 提交技能

## 核心原则

提交信息必须**从对话中提取改动的背景和原因**，而不仅仅是描述 diff 的字面内容。用户在上一次对话中已经说明了为什么要做这些改动，提交信息应该体现这个"为什么"。

## 工作流

### 1. 查看改动

当用户要求提交代码时，依次执行以下命令查看当前状态和改动：

```bash
git status --short
git diff --cached
git diff
```

### 2. 结合对话上下文生成中文提交信息

**这一步是关键：** 不要只看 diff 的代码变化。回看本轮对话中用户之前说过的话，从中提取：

- **改了什么** — 用户描述的新功能、修复的 bug、调整的逻辑
- **为什么改** — 用户的动机、背景、业务需求、问题原因

将这些信息融入提交信息中，让提交信息说明"做了什么事、为什么这么做"，而不仅仅是"改了什么文件"。

使用 Conventional Commit 格式，语言为**中文**：

```
<type>(<scope>): <说明>
```

**格式示例：**
- `feat(user): 新增头像上传` — 这种短提交适合改动简单的情况
- 如果改动有明确背景，写更详细：
  `fix(order): 修复订单金额精度丢失问题` 然后 body 写 `原因是浮点数相乘未做四舍五入，导致部分订单少收 0.01 元`
- 或者：
  `refactor(api): 拆分用户查询接口` 然后 body 写 `原接口承载过多职责，按 CQRS 模式拆分为 Query 和 Command 两个接口`

**提交信息结构：**
- **标题行（subject）：** `<type>(<scope>): <说明>` — 说明"做了什么"
- **正文（body，可选）：** 说明"为什么这么做"，从对话中提取用户的原意或背景
- **尾部（footer，可选）：** 关联的 issue、任务单号等

**提交信息中不要包含：**
- 具体的文件名列表（这些在 `git log --stat` 里看）
- 代码实现细节（如"把 `==` 改为 `===`"）
- 对话中的客套话或无关内容

**常用类型（type）：**

| 类型 | 用途 |
|------|------|
| `feat` | 新功能 |
| `fix` | 修复 bug |
| `refactor` | 重构（既不是修 bug 也不是加功能） |
| `docs` | 文档更新 |
| `test` | 添加或修改测试 |
| `chore` | 构建、依赖、工具等杂项 |
| `style` | 代码格式调整（不影响逻辑） |
| `perf` | 性能优化 |
| `ci` | CI/CD 配置变更 |

**范围（scope）：** 根据改动文件所在的模块/目录确定，如 `user`、`auth`、`api`、`deps` 等。如果不确定范围，可以省略。

### 3. 提交前确认

在告知用户以下信息后，等待用户明确确认（回复"确认"、"可以"、"好的"、"yes"、"y" 等）：

- **改动的文件列表**
- **改动摘要**（新增/修改/删除了什么）
- **对话中提取的改动原因**（引用用户之前说的话，让用户确认你的理解是正确的）
- **生成的提交信息**

### 4. 执行提交

用户确认后执行：

```bash
git add <指定文件>
git commit -m "<提交信息>"
```

如果提交信息包含正文（body），使用：

```bash
git commit -m "<标题行>" -m "<正文>"
```

提交完成后，执行 `git status --short` 并报告结果。

## 规则

### 必须遵守
- 提交信息必须使用**中文**
- 必须从对话中提取改动背景和原因，不能只依赖 diff
- 必须等待用户明确确认后再执行 `git add` 和 `git commit`
- 提交后必须执行 `git status --short` 并报告结果

### 禁止行为
- **不使用 `git add .`**，除非用户明确要求
- **不提交 `.env`、密钥、证书等敏感文件** — 如果发现这些文件在改动列表中，提醒用户并排除它们
- **不执行 `--amend`、`reset`、强制推送（`--force` / `-f`）**，除非用户明确授权
- **不修改或删除远端历史**

### 提示
- 如果 `git status` 显示没有改动，告知用户工作区是干净的
- 如果改动包含大量文件，帮用户归类并按模块组织提交，询问是否要分多次提交
- 对于大型提交（>10 个文件或涉及多个模块），建议用户拆分为多个独立的提交
- 如果对话中没有明确提到改动原因，在确认时主动询问用户："这次改动的背景是什么？我好在提交信息中体现。"

## 触发条件

当用户说出以下任一内容时触发此技能：
- "提交代码" / "commit" / "git commit"
- "提交" / "我要提交" / "帮我提交"
- 任何涉及 Git 提交的意图
