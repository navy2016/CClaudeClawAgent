package com.cclaudeclawagent.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.cclaudeclawagent.data.model.ChatMessage
import com.cclaudeclawagent.data.model.MessagePart
import com.cclaudeclawagent.data.model.Role

@Composable
fun MessageCard(message: ChatMessage) {
    val isUser = message.role == Role.USER
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = if (isUser) Arrangement.End else Arrangement.Start,
    ) {
        Surface(
            shape = RoundedCornerShape(20.dp),
            color = if (isUser) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceVariant,
            modifier = Modifier
                .fillMaxWidth(0.92f)
        ) {
            Column(modifier = Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    text = message.role.name,
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.primary,
                )
                message.parts.forEach { part ->
                    when (part) {
                        is MessagePart.Text -> Text(part.text, style = MaterialTheme.typography.bodyLarge)
                        is MessagePart.Reasoning -> Text(
                            text = "Reasoning · ${part.content}",
                            style = MaterialTheme.typography.bodyMedium,
                            modifier = Modifier
                                .background(MaterialTheme.colorScheme.surface, RoundedCornerShape(14.dp))
                                .padding(10.dp)
                        )
                        is MessagePart.ToolCall -> Text(
                            text = "Tool → ${part.name} (${part.status})\n${part.arguments}",
                            style = MaterialTheme.typography.bodyMedium,
                        )
                        is MessagePart.ToolResult -> Text(
                            text = "Result ← ${part.name}\n${part.content}",
                            style = MaterialTheme.typography.bodyMedium,
                        )
                        is MessagePart.WorkflowCheckpoint -> Text(
                            text = "Workflow · ${part.stage}\n${part.summary}",
                            style = MaterialTheme.typography.bodyMedium,
                        )
                    }
                }
            }
        }
    }
}
