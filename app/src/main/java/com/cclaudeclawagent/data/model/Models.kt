package com.cclaudeclawagent.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
sealed interface MessagePart {
    @Serializable
    @SerialName("text")
    data class Text(val text: String) : MessagePart

    @Serializable
    @SerialName("reasoning")
    data class Reasoning(val content: String) : MessagePart

    @Serializable
    @SerialName("tool_call")
    data class ToolCall(
        val name: String,
        val arguments: String,
        val status: String,
    ) : MessagePart

    @Serializable
    @SerialName("tool_result")
    data class ToolResult(
        val name: String,
        val content: String,
    ) : MessagePart

    @Serializable
    @SerialName("checkpoint")
    data class WorkflowCheckpoint(
        val stage: String,
        val summary: String,
    ) : MessagePart
}

@Serializable
data class ChatMessage(
    val id: String,
    val role: Role,
    val parts: List<MessagePart>,
    val createdAtMillis: Long,
)

@Serializable
enum class Role {
    USER,
    ASSISTANT,
    SYSTEM,
    TOOL,
}

@Serializable
data class ApprovalUiModel(
    val batchId: String,
    val summary: String,
    val riskLevel: String,
    val reversible: Boolean,
    val operations: List<ApprovalOperationUiModel>,
)

@Serializable
data class ApprovalOperationUiModel(
    val id: String,
    val type: String,
    val target: String,
    val preview: String,
    val riskLevel: String,
    val reversible: Boolean,
)

@Serializable
data class WorkflowUiModel(
    val runId: String,
    val workflowType: String,
    val state: String,
    val currentStage: String,
    val stages: List<WorkflowStageUiModel>,
    val latestLesson: String? = null,
)

@Serializable
data class WorkflowStageUiModel(
    val kind: String,
    val status: String,
    val score: Double? = null,
)
