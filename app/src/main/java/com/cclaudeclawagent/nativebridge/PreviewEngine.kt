package com.cclaudeclawagent.nativebridge

import com.cclaudeclawagent.data.model.ApprovalOperationUiModel
import com.cclaudeclawagent.data.model.ApprovalUiModel
import com.cclaudeclawagent.data.model.WorkflowStageUiModel
import com.cclaudeclawagent.data.model.WorkflowUiModel
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

internal class PreviewEngine {
    private val json = Json { prettyPrint = false }
    private var canUndo = false
    private var canRedo = false
    private var pendingBatch: ApprovalUiModel? = null
    private var workflow = WorkflowUiModel(
        runId = "preview-run",
        workflowType = "coding",
        state = "idle",
        currentStage = "clarify",
        stages = listOf(
            WorkflowStageUiModel("clarify", "todo"),
            WorkflowStageUiModel("gather_context", "todo"),
            WorkflowStageUiModel("plan", "todo"),
            WorkflowStageUiModel("execute", "todo"),
            WorkflowStageUiModel("evaluate", "todo"),
            WorkflowStageUiModel("summarize", "todo"),
        ),
    )

    fun send(text: String): String {
        val lower = text.lowercase()
        if (listOf("edit", "write", "修改", "写入", "创建文件").any(lower::contains)) {
            pendingBatch = ApprovalUiModel(
                batchId = "batch-preview-1",
                summary = "Agent 计划执行 2 个变更操作",
                riskLevel = "MODERATE",
                reversible = true,
                operations = listOf(
                    ApprovalOperationUiModel(
                        id = "op-1",
                        type = "file_write",
                        target = "/workspace/demo.txt",
                        preview = "create or overwrite demo.txt",
                        riskLevel = "MODERATE",
                        reversible = true,
                    ),
                    ApprovalOperationUiModel(
                        id = "op-2",
                        type = "workflow_transition",
                        target = "execute",
                        preview = "advance workflow to execute",
                        riskLevel = "SAFE",
                        reversible = true,
                    )
                )
            )
        }
        workflow = workflow.copy(
            state = if (lower.contains("research") || lower.contains("论文")) "running" else "planning",
            workflowType = if (lower.contains("research") || lower.contains("论文")) "research" else "coding",
            currentStage = "plan",
            stages = workflow.stages.map {
                when (it.kind) {
                    "clarify" -> it.copy(status = "done", score = 1.0)
                    "plan" -> it.copy(status = "doing")
                    else -> it
                }
            },
            latestLesson = if (lower.contains("bug") || lower.contains("修复")) "优先执行最小可逆补丁，再进入评估阶段" else null,
        )
        return snapshot(
            assistantReply = when {
                lower.contains("research") || lower.contains("论文") -> "已切换为 AutoResearchClaw 风格研究工作流：先澄清目标，再进行文献/上下文发现、假设计划、执行、评估与回滚。"
                pendingBatch != null -> "我已把潜在副作用动作冻结为一个原子批次，请你审批后再提交。"
                else -> "已进入规划阶段。你可以继续补充约束，或让我开始生成可审批的操作批次。"
            }
        )
    }

    fun approve(batchId: String, scope: String): String {
        if (pendingBatch?.batchId == batchId) {
            canUndo = true
            canRedo = false
            workflow = workflow.copy(
                state = "running",
                currentStage = "execute",
                stages = workflow.stages.map {
                    when (it.kind) {
                        "plan" -> it.copy(status = "done", score = 0.9)
                        "execute" -> it.copy(status = "doing")
                        else -> it
                    }
                },
                latestLesson = "已使用授权范围 `$scope` 提交批次；后续优先复用相同工作区权限。"
            )
            pendingBatch = null
        }
        return snapshot("批次已批准并提交，所有操作已进入可撤销账本。")
    }

    fun reject(batchId: String, reason: String): String {
        if (pendingBatch?.batchId == batchId) {
            pendingBatch = null
            workflow = workflow.copy(
                state = "planning",
                currentStage = "plan",
                latestLesson = "审批被拒绝：$reason。已回到计划阶段重新求解。"
            )
        }
        return snapshot("批次已拒绝，系统已回退到计划阶段。")
    }

    fun undo(): String {
        if (canUndo) {
            canUndo = false
            canRedo = true
            workflow = workflow.copy(
                state = "revised",
                currentStage = "revise",
                latestLesson = "最近一次提交已回滚；可在确认后执行 redo 或重新规划。"
            )
        }
        return snapshot("最近一次已提交批次已撤回。")
    }

    fun redo(): String {
        if (canRedo) {
            canRedo = false
            canUndo = true
            workflow = workflow.copy(
                state = "running",
                currentStage = "execute",
                latestLesson = "已对上一个回滚批次执行 redo。"
            )
        }
        return snapshot("已重做上一条回滚批次。")
    }

    private fun snapshot(assistantReply: String): String = json.encodeToString(
        NativeSnapshot(
            assistantReply = assistantReply,
            pendingApproval = pendingBatch,
            workflow = workflow,
            canUndo = canUndo,
            canRedo = canRedo,
        )
    )
}
