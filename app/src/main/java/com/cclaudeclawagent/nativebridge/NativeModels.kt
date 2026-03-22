package com.cclaudeclawagent.nativebridge

import com.cclaudeclawagent.data.model.ApprovalUiModel
import com.cclaudeclawagent.data.model.WorkflowUiModel
import kotlinx.serialization.Serializable

@Serializable
data class NativeSnapshot(
    val assistantReply: String,
    val pendingApproval: ApprovalUiModel? = null,
    val workflow: WorkflowUiModel? = null,
    val canUndo: Boolean = false,
    val canRedo: Boolean = false,
)
