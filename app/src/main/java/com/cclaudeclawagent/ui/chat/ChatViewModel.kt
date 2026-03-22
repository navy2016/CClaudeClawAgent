package com.cclaudeclawagent.ui.chat

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import com.cclaudeclawagent.data.model.ChatMessage
import com.cclaudeclawagent.data.model.MessagePart
import com.cclaudeclawagent.data.model.Role
import com.cclaudeclawagent.nativebridge.NativeSession
import java.util.UUID

class ChatViewModel(
    private val session: NativeSession,
) : ViewModel() {
    var input by mutableStateOf("")
        private set

    var messages by mutableStateOf(emptyList<ChatMessage>())
        private set

    var pendingApproval by mutableStateOf<com.cclaudeclawagent.data.model.ApprovalUiModel?>(null)
        private set

    var workflow by mutableStateOf<com.cclaudeclawagent.data.model.WorkflowUiModel?>(null)
        private set

    var canUndo by mutableStateOf(false)
        private set

    var canRedo by mutableStateOf(false)
        private set

    init {
        // 演示模式：初始化后自动展示一个待审批批次，让用户可以测试审批功能
        loadDemoPendingBatch()
    }

    fun onInputChange(value: String) {
        input = value
    }

    fun send() {
        val prompt = input.trim()
        if (prompt.isEmpty()) return
        append(Role.USER, MessagePart.Text(prompt))
        input = ""
        reduce(session.send(prompt))
    }

    fun approveOnce() {
        val batch = pendingApproval ?: return
        reduce(session.approve(batch.batchId, "once"))
    }

    fun approveStage() {
        val batch = pendingApproval ?: return
        reduce(session.approve(batch.batchId, "for_stage"))
    }

    fun reject() {
        val batch = pendingApproval ?: return
        reduce(session.reject(batch.batchId, "user rejected"))
    }

    fun dismissApproval() {
        pendingApproval = null
    }

    fun undo() = reduce(session.undo())
    fun redo() = reduce(session.redo())

    private fun loadDemoPendingBatch() {
        // 演示数据：让用户体验审批流程
        pendingApproval = com.cclaudeclawagent.data.model.ApprovalUiModel(
            batchId = "demo-batch-001",
            summary = "Demo: 初始化演示批次，测试原子授权与撤回重做",
            riskLevel = "MODERATE",
            reversible = true,
            operations = listOf(
                com.cclaudeclawagent.data.model.ApprovalOperationUiModel(
                    id = "demo-op-1",
                    type = "context_update",
                    target = "USER.md",
                    preview = "Append: 用户偏好测试条目",
                    riskLevel = "SAFE",
                    reversible = true
                ),
                com.cclaudeclawagent.data.model.ApprovalOperationUiModel(
                    id = "demo-op-2",
                    type = "workflow_transition",
                    target = "execute",
                    preview = "Advance to execute stage",
                    riskLevel = "MODERATE",
                    reversible = true
                )
            )
        )
        workflow = com.cclaudeclawagent.data.model.WorkflowUiModel(
            runId = "demo-run-001",
            workflowType = "coding",
            state = "planning",
            currentStage = "plan",
            stages = listOf(
                com.cclaudeclawagent.data.model.WorkflowStageUiModel("clarify", "done", 1.0),
                com.cclaudeclawagent.data.model.WorkflowStageUiModel("gather_context", "done"),
                com.cclaudeclawagent.data.model.WorkflowStageUiModel("plan", "doing"),
                com.cclaudeclawagent.data.model.WorkflowStageUiModel("execute", "todo"),
                com.cclaudeclawagent.data.model.WorkflowStageUiModel("evaluate", "todo"),
                com.cclaudeclawagent.data.model.WorkflowStageUiModel("summarize", "todo")
            ),
            latestLesson = "首次启动演示：请点击下方按钮体验原子授权、撤回与重做"
        )
    }

    private fun reduce(snapshot: com.cclaudeclawagent.nativebridge.NativeSnapshot) {
        pendingApproval = snapshot.pendingApproval
        workflow = snapshot.workflow
        canUndo = snapshot.canUndo
        canRedo = snapshot.canRedo
        append(
            Role.ASSISTANT,
            MessagePart.Text(snapshot.assistantReply),
            snapshot.workflow?.let { MessagePart.WorkflowCheckpoint(it.currentStage, it.state) },
            snapshot.pendingApproval?.let {
                MessagePart.ToolCall(
                    name = "authorization_batch",
                    arguments = it.summary,
                    status = "pending"
                )
            }
        )
    }

    private fun append(role: Role, vararg parts: MessagePart?) {
        messages = messages + ChatMessage(
            id = UUID.randomUUID().toString(),
            role = role,
            parts = parts.filterNotNull(),
            createdAtMillis = System.currentTimeMillis(),
        )
    }
}
