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

    fun undo() = reduce(session.undo())
    fun redo() = reduce(session.redo())

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
