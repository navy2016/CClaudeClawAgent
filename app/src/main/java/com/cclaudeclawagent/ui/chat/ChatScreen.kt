package com.cclaudeclawagent.ui.chat

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.cclaudeclawagent.ui.components.ApprovalSheet
import com.cclaudeclawagent.ui.components.MessageCard
import com.cclaudeclawagent.ui.components.WorkflowPanel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatScreen(viewModel: ChatViewModel) {
    var workflowVisible by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text("CClaudeClawAgent")
                        Text(
                            "Atomic control · Undo/Redo · Research loop",
                            style = MaterialTheme.typography.bodySmall,
                        )
                    }
                },
                actions = {
                    TextButton(onClick = { if (viewModel.canUndo) viewModel.undo() }) { Text("撤回") }
                    TextButton(onClick = { if (viewModel.canRedo) viewModel.redo() }) { Text("重做") }
                    TextButton(onClick = { workflowVisible = true }) { Text("工作流") }
                }
            )
        },
        floatingActionButton = {
            FloatingActionButton(onClick = { workflowVisible = true }) {
                Text("WF")
            }
        }
    ) { padding ->
        Box(modifier = Modifier.fillMaxSize().padding(padding)) {
            Column(modifier = Modifier.fillMaxSize()) {
                LazyColumn(
                    modifier = Modifier.weight(1f).fillMaxWidth().padding(horizontal = 12.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    items(viewModel.messages) { message ->
                        MessageCard(message)
                    }
                }
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .navigationBarsPadding()
                        .padding(12.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedTextField(
                        value = viewModel.input,
                        onValueChange = viewModel::onInputChange,
                        placeholder = { Text("描述你的任务、研究目标或代码修改需求…") },
                        modifier = Modifier.weight(1f),
                    )
                    TextButton(onClick = viewModel::send) {
                        Text("发送")
                    }
                }
            }

            WorkflowPanel(
                visible = workflowVisible,
                workflow = viewModel.workflow,
                onDismiss = { workflowVisible = false },
            )
        }
    }

    viewModel.pendingApproval?.let { approval ->
        ApprovalSheet(
            approval = approval,
            onApproveOnce = viewModel::approveOnce,
            onApproveStage = viewModel::approveStage,
            onReject = viewModel::reject,
            onDismiss = {},
        )
    }
}
