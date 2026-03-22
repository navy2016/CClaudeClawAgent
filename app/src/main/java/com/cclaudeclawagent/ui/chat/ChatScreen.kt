package com.cclaudeclawagent.ui.chat

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.unit.dp
import com.cclaudeclawagent.ui.components.ApprovalSheet
import com.cclaudeclawagent.ui.components.MessageCard
import com.cclaudeclawagent.ui.components.WorkflowPanel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatScreen(viewModel: ChatViewModel) {
    var workflowVisible by remember { mutableStateOf(false) }
    val scrollBehavior = TopAppBarDefaults.pinnedScrollBehavior()

    Scaffold(
        modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        topBar = {
            TopAppBar(
                title = {
                    Column(modifier = Modifier.padding(vertical = 4.dp)) {
                        Text(
                            text = "CClaudeClawAgent",
                            style = MaterialTheme.typography.titleMedium
                        )
                        Text(
                            text = "Atomic control · Undo/Redo · Research loop",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                },
                actions = {
                    TextButton(
                        onClick = { viewModel.undo() },
                        enabled = viewModel.canUndo
                    ) { Text("撤回") }
                    TextButton(
                        onClick = { viewModel.redo() },
                        enabled = viewModel.canRedo
                    ) { Text("重做") }
                    TextButton(onClick = { workflowVisible = true }) { Text("工作流") }
                },
                scrollBehavior = scrollBehavior,
                expandedHeight = TopAppBarDefaults.LargeAppBarExpandedHeight
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
                        placeholder = { Text("描述任务、研究目标或代码修改需求…") },
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

    // 审批面板 - 使用独立的模态状态
    viewModel.pendingApproval?.let { approval ->
        ApprovalSheet(
            approval = approval,
            onApproveOnce = viewModel::approveOnce,
            onApproveStage = viewModel::approveStage,
            onReject = viewModel::reject,
            onDismiss = viewModel::dismissApproval,
        )
    }
}
