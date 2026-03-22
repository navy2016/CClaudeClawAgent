# CClaudeClawAgent

Android 原生 Agent 应用脚手架：
- Zig 编写逻辑推理核心
- Jetpack Compose UI，交互风格借鉴 Rikkahub 的多段消息、工具轨迹、工作流面板
- 吸收 001/002/003.txt 的长期记忆、原子授权、Undo/Redo、AutoResearchClaw 闭环工作流设计
- 在适当设计点参考 nullclaw 的 Zig 模块化思路，但未直接照搬实现

## 当前交付内容

这是一个可继续开发的第一版源码骨架，重点先落下四条主干：
1. **Zig Core**：OperationBatch、Authorization、Undo/Redo、Workflow、ContextStore
2. **Android UI**：聊天页、工具/审批卡片、工作流浮层、原子控制入口
3. **Native Bridge**：JNI/JSON 事件桥接接口
4. **Persistence Schema**：Room 实体骨架 + Markdown Context 约定

## 目录

```text
app/                 Android App
native/zig/          Zig 核心运行时
```

## 设计摘要

### 1. 原子控制模型
所有有副作用的动作都先变成 `Operation`，多个操作组合成 `OperationBatch`。
批次必须先通过授权，再提交；提交后进入可撤销账本。

### 2. Undo / Redo
Undo/Redo 针对 **批次** 而不是聊天文本：
- 文件修改
- 上下文变更
- 记忆追加
- 工作流阶段推进

### 3. AutoResearchClaw 集成方式
不是机械复刻论文工厂，而是复用它的闭环模式：
- Clarify
- Gather Context
- Plan
- Execute
- Evaluate
- Revise
- Summarize

同时保留 lesson / skill / 30 天衰减的接口。

### 4. Context Files
延续 001.txt 的设计：
- `SOUL.md`
- `USER.md`
- `MEMORY.md`
- `LESSONS.md`
- `POLICY.md`
- `BOOTSTRAP.md`

## 构建说明

当前容器未提供 Android / Zig 构建链，因此本次交付聚焦源码与结构落地。
本项目默认通过 Zig 构建 `libcclaudeclaw.so`，再由 Android 以 `jniLibs` 方式加载。

### Zig 目标
建议产物：
- `app/src/main/jniLibs/arm64-v8a/libcclaudeclaw.so`

### Android 侧加载
```kotlin
System.loadLibrary("cclaudeclaw")
```

## 下一步建议

1. 安装 Zig 与 Android SDK/NDK
2. 先打通 `cclaude_session_*` JNI 生命周期
3. 接入真实 provider / streaming
4. 把 `OperationBatch` 与 Compose 审批面板联动
5. 为 Zig core 增加文件工具、shell host、上下文文件落盘
